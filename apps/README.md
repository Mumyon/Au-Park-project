# Apps

Client applications for Au-Park.

- `mobile_flutter`: Flutter mobile app for Android and iOS.
- `admin_dashboard`: Optional admin dashboard.

## iOS Simulator에서 Flutter 앱 실행하기

모바일 앱은 `/Users/jobyeongik/Documents/GitHub/Au-Park-project/apps/mobile_flutter`에서 실행한다.

```bash
cd /Users/jobyeongik/Documents/GitHub/Au-Park-project/apps/mobile_flutter
```

사용 가능한 iOS 시뮬레이터 목록을 확인한다.

```bash
xcrun simctl list devices
flutter devices
```

현재 맥북에서 확인한 iPhone 17 시뮬레이터 UUID는 다음과 같다.

```text
43E18EF1-BB48-463A-89BF-47A3F7064D3E
```

시뮬레이터가 꺼져 있으면 먼저 부팅한다.

```bash
xcrun simctl boot 43E18EF1-BB48-463A-89BF-47A3F7064D3E
open -a Simulator
```

앱을 실행한다.

```bash
flutter run -d 43E18EF1-BB48-463A-89BF-47A3F7064D3E
```

`flutter run -d "iPhone"`처럼 이름만 지정하면 실제로 연결된 iPhone과 시뮬레이터가 헷갈릴 수 있다. 시뮬레이터로 실행할 때는 UUID를 직접 지정하는 것이 가장 안전하다.

FastAPI 서버와 함께 테스트하려면 서버를 먼저 켠다.

```bash
cd /Users/jobyeongik/Documents/GitHub/Au-Park-project/services/api
.venv-conda/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```
