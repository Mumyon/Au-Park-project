#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_DIR="$ROOT_DIR/services/api"
FLUTTER_DIR="$ROOT_DIR/apps/mobile_flutter"
API_URL="http://127.0.0.1:8000"
TUNNEL_LOG="$(mktemp -t au-park-cloudflared.XXXXXX)"
API_PID=""
TUNNEL_PID=""

cleanup() {
  if [[ -n "$TUNNEL_PID" ]] && kill -0 "$TUNNEL_PID" 2>/dev/null; then
    kill "$TUNNEL_PID" 2>/dev/null || true
  fi
  if [[ -n "$API_PID" ]] && kill -0 "$API_PID" 2>/dev/null; then
    kill "$API_PID" 2>/dev/null || true
  fi
  rm -f "$TUNNEL_LOG"
}
trap cleanup EXIT INT TERM

if ! curl --silent --fail "$API_URL/health" >/dev/null 2>&1; then
  echo "Starting FastAPI..."
  (
    cd "$API_DIR"
    exec .venv-conda/bin/python -m uvicorn app.main:app \
      --host 127.0.0.1 \
      --port 8000
  ) &
  API_PID=$!

  for _ in {1..30}; do
    if curl --silent --fail "$API_URL/health" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
fi

if ! curl --silent --fail "$API_URL/health" >/dev/null 2>&1; then
  echo "FastAPI did not become ready at $API_URL" >&2
  exit 1
fi

echo "Starting Cloudflare quick tunnel..."
cloudflared tunnel --url "$API_URL" --no-autoupdate >"$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!

TUNNEL_URL=""
for _ in {1..30}; do
  TUNNEL_URL="$(grep -Eo 'https://[-a-z0-9]+\.trycloudflare\.com' "$TUNNEL_LOG" | head -1 || true)"
  if [[ -n "$TUNNEL_URL" ]]; then
    break
  fi
  if ! kill -0 "$TUNNEL_PID" 2>/dev/null; then
    cat "$TUNNEL_LOG" >&2
    exit 1
  fi
  sleep 1
done

if [[ -z "$TUNNEL_URL" ]]; then
  cat "$TUNNEL_LOG" >&2
  echo "Cloudflare tunnel URL was not created." >&2
  exit 1
fi

BASE_URL="$TUNNEL_URL/api/v1"
echo
echo "Au-Park API: $BASE_URL"
echo "Keep this terminal running while the phone uses the app."
echo

cd "$FLUTTER_DIR"
flutter run --release \
  --dart-define="API_BASE_URL=$BASE_URL" \
  "$@"
