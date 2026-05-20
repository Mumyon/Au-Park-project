import sys
from pathlib import Path


api_root = Path(__file__).parent / "services" / "api"
sys.path.insert(0, str(api_root))

from app.main import app


__all__ = ["app"]
