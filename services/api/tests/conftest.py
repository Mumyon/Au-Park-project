import sys
from pathlib import Path


api_root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(api_root))
