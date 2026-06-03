apps/mobile_flutter: Flutter 모바일 앱

apps/admin_dashboard: 선택 구현 관리자 화면

services/api: FastAPI 서버

services/api/app/api/auth, vehicles, parking, payments, lpr: 주요 API 도메인

services/vision: OpenCV, LPR, 주차면 감지 모듈

services/gate_controller: 차단기/게이트 제어부

infra/firebase, infra/portone, infra/docker, infra/deploy: 외부 연동 및 배포

docs: 구조도, API, 흐름, 하드웨어, 운영 문서

tests: 통합/e2e 테스트

assets/samples: 번호판 이미지와 주차장 영상 샘플


Run FastAPI Server in Mac

cd /Users/jobyeongik/Documents/GitHub/Au-Park-project/services/api
.venv-conda/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000

Run flutter 

1. Mac

cd /Users/jobyeongik/Documents/GitHub/Au-Park-project/apps/mobile_flutter
flutter run

2. iphone

ipconfig getifaddr en0

open /Users/jobyeongik/Documents/GitHub/Au-Park-project/apps/mobile_flutter/lib/core/api/api_client.dart

class ApiClient {
  static final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:8000/api/v1'
      : 'http://172.30.1.55:8000/api/v1';   <- your computer's ip

cd /Users/jobyeongik/Documents/GitHub/Au-Park-project/services/api
.venv-conda/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000


cd /Users/jobyeongik/Documents/GitHub/Au-Park-project/apps/mobile_flutter

flutter devices

flutter run -d xxxxxxxx     <- fill the UID


you should download flutter SDK in homebrew