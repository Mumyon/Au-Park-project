import { C, base, code, footer, label, node, title } from "./shared.mjs";

export async function slide10(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx);
  title(slide, ctx, "RUNBOOK", "MacBook 로컬 서버를 Cloudflare Tunnel로 외부 iPhone에 연결", "테스트 단계에서는 클라우드 배포 전에도 HTTPS 공개 주소로 실제 기기 앱과 서버 통신을 검증할 수 있습니다.");
  node(slide, ctx, "1\nFastAPI 서버", 74, 230, 190, 78, { fill: "#EDF3F9", line: C.brand, color: C.brand });
  node(slide, ctx, "2\nCloudflare Tunnel", 300, 230, 210, 78, { fill: "#EDF9F6", line: C.green, color: C.green });
  node(slide, ctx, "3\nFlutter release", 546, 230, 190, 78, { fill: "#FFFFFF", line: C.line, color: C.ink });
  node(slide, ctx, "4\nVision Worker", 772, 230, 190, 78, { fill: "#FFFFFF", line: C.line, color: C.ink });
  node(slide, ctx, "5\n실제 입출차 테스트", 998, 230, 190, 78, { fill: "#FFF8E6", line: "#E7D39A", color: C.warn });
  code(slide, ctx, "cd /Users/jobyeongik/Documents/GitHub/Au-Park-project/services/api\n.venv-conda/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000", 76, 365, 520, 112);
  code(slide, ctx, "cd /Users/jobyeongik/Documents/GitHub/Au-Park-project\n./scripts/run_mobile_cloudflare.sh -d 00008110-0011743E2ED1801E", 628, 365, 520, 112);
  label(slide, ctx, "실제 iPhone에서 127.0.0.1은 MacBook이 아니라 iPhone 자기 자신입니다. 그래서 release 실행 때 API_BASE_URL은 Cloudflare Tunnel 주소의 /api/v1까지 포함해야 합니다.", 80, 540, 1040, 52, {
    fontSize: 18,
    bold: true,
    color: C.ink,
  });
  footer(slide, ctx, 10);
  return slide;
}
