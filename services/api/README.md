# Au-Park FastAPI Server

FastAPI server for the Au-Park parking system.

## Run on My MacBook

```bash
cd /Users/jobyeongik/Documents/GitHub/Au-Park-project/services/api
.venv-conda/bin/python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

## Firebase Realtime Database

The API stores users, vehicles, entry/exit logs, parking lots, parking slots,
payment requests, and payment methods in Firebase Realtime Database when
`FIREBASE_DATABASE_URL` is set.

Create `/Users/jobyeongik/Documents/GitHub/Au-Park-project/services/api/.env`:

```env
FIREBASE_DATABASE_URL=https://your-project-id-default-rtdb.firebaseio.com
FIREBASE_CREDENTIALS_PATH=/Users/jobyeongik/Downloads/firebase-service-account.json
GOOGLE_OAUTH_CLIENT_IDS=google-ios-client-id.apps.googleusercontent.com,google-android-client-id.apps.googleusercontent.com
```

`FIREBASE_CREDENTIALS_PATH` must point to the Firebase service account JSON file
downloaded on this MacBook. Do not save `.env` as `.rtf`; it must be a plain text
file named exactly `.env`.

If `FIREBASE_DATABASE_URL` is not set, the server falls back to the in-memory
repository used by tests and local demos.

## Social Login

The mobile app should send provider tokens to FastAPI:

```http
POST /api/v1/auth/social-login
```

```json
{
  "provider": "google",
  "token": "google-id-token"
}
```

Supported providers:

- `google`: send the Google ID token. Configure allowed client IDs in `GOOGLE_OAUTH_CLIENT_IDS`.
- `kakao`: send the Kakao access token. The server verifies it with `https://kapi.kakao.com/v2/user/me`.
- `naver`: send the Naver access token. The server verifies it with `https://openapi.naver.com/v1/nid/me`.

OpenAPI docs:

- `http://127.0.0.1:8000/docs`
- `http://127.0.0.1:8000/health`

## Main API Groups

- `POST /api/v1/auth/signup`
- `POST /api/v1/auth/login`
- `GET /api/v1/users/{user_id}`
- `GET /api/v1/vehicles?user_id=...`
- `GET /api/v1/parking/lots`
- `GET /api/v1/parking/lots/{lot_id}/slots`
- `POST /api/v1/payments/request`
- `GET /api/v1/logs`
- `POST /api/v1/lpr/entry`
- `POST /api/v1/lpr/exit`

## 백엔드 서버 구조

```text
Au-Park-project
├── main.py
│   └── FastAPI 앱 실행 진입점
│
├── services
│   ├── api
│   │   └── FastAPI 백엔드 서버
│   │
│   │   ├── app
│   │   │   ├── main.py
│   │   │   │   └── FastAPI 객체 생성, CORS 설정, 라우터 등록
│   │   │   │
│   │   │   ├── core
│   │   │   │   └── config.py
│   │   │   │       └── 환경 변수 및 서버 설정 관리
│   │   │   │
│   │   │   ├── api
│   │   │   │   └── routes
│   │   │   │       ├── auth
│   │   │   │       ├── users
│   │   │   │       ├── vehicles
│   │   │   │       ├── parking
│   │   │   │       ├── payments
│   │   │   │       ├── logs
│   │   │   │       └── lpr
│   │   │   │
│   │   │   ├── schemas
│   │   │   │   └── 요청 및 응답 데이터 모델
│   │   │   │
│   │   │   └── services
│   │   │       ├── 비즈니스 로직 처리
│   │   │       └── repository.py
│   │   │           └── InMemory 저장소 또는 Firebase Realtime DB 연동
│   │   │
│   │   ├── tests
│   │   │   └── 백엔드 테스트 코드
│   │   │
│   │   ├── requirements.txt
│   │   │   └── FastAPI 서버 실행에 필요한 Python 패키지 목록
│   │   │
│   │   └── .env.example
│   │       └── 환경 변수 예시 파일
│   │
│   └── vision
│       └── 차량 번호판 인식 및 LPR 관련 기능 영역
│
└── apps
    ├── mobile_flutter
    │   └── 사용자용 Flutter 모바일 앱
    │
    │   ├── lib
    │   │   └── 화면, Provider, 테마 등 Flutter 핵심 코드
    │   │
    │   ├── android
    │   │   └── Android 빌드 관련 파일
    │   │
    │   ├── ios
    │   │   └── iOS 빌드 관련 파일
    │   │
    │   ├── macos
    │   │   └── macOS 빌드 관련 파일
    │   │
    │   ├── assets
    │   │   └── images
    │   │       └── 앱에서 사용하는 이미지 리소스
    │   │
    │   └── Backup
    │       └── 임시 백업 폴더
    │           └── 추후 정리 권장
    │
    └── admin_dashboard
        └── 관리자 대시보드 개발 예정 영역
```

## 주요 구성 요소 설명

### 1. FastAPI 백엔드 서버

`services/api` 폴더는 Au-Park 시스템의 백엔드 서버 영역입니다.

주요 역할은 다음과 같습니다.

* 모바일 앱에서 전달받은 요청 처리
* 사용자, 차량, 주차장, 결제, 로그 데이터 관리
* Firebase Realtime Database와 연동
* 차량 번호판 인식 결과를 서버 로직과 연결
* 관리자 대시보드와 모바일 앱에 필요한 API 제공

### 2. FastAPI 앱 구조

`services/api/app` 폴더는 실제 FastAPI 서버 코드가 들어가는 핵심 영역입니다.

```text
app
├── main.py
├── core
├── api/routes
├── schemas
└── services
```

각 폴더의 역할은 다음과 같습니다.

| 경로               | 역할                                      |
| ---------------- | --------------------------------------- |
| `main.py`        | FastAPI 앱 생성, CORS 설정, 라우터 등록           |
| `core/config.py` | 환경 변수 및 서버 설정 관리                        |
| `api/routes`     | 기능별 API 엔드포인트 관리                        |
| `schemas`        | 요청/응답 데이터 모델 정의                         |
| `services`       | 실제 비즈니스 로직 처리                           |
| `repository.py`  | InMemory 저장소 또는 Firebase Realtime DB 연동 |

### 3. API 라우터 구조

`api/routes` 폴더는 기능별 API를 분리해서 관리합니다.

```text
routes
├── auth       사용자 인증 관련 API
├── users      사용자 정보 관련 API
├── vehicles   차량 정보 관련 API
├── parking    주차장 및 주차 상태 관련 API
├── payments   결제 관련 API
├── logs       입출차 및 시스템 로그 관련 API
└── lpr        차량 번호판 인식 관련 API
```

이렇게 기능별로 라우터를 분리하면 코드 유지보수가 쉬워지고, 이후 기능을 추가할 때도 구조가 깔끔하게 유지됩니다.

### 4. Firebase Realtime Database

백엔드 서버의 `repository.py`는 데이터 저장소 역할을 담당합니다.

초기 개발 단계에서는 InMemory 저장소를 사용할 수 있고, 실제 서비스 단계에서는 Firebase Realtime Database와 연동합니다.

Firebase Realtime Database에서 관리할 주요 데이터는 다음과 같습니다.

```text
Firebase Realtime DB
├── users
├── vehicles
├── logs
├── parking_lots
└── payments
```

각 데이터의 역할은 다음과 같습니다.

| 데이터            | 설명             |
| -------------- | -------------- |
| `users`        | 사용자 정보         |
| `vehicles`     | 사용자 차량 정보      |
| `logs`         | 입차, 출차, 인식 기록  |
| `parking_lots` | 주차장 정보 및 주차 상태 |
| `payments`     | 결제 내역 및 결제 상태  |

### 5. Flutter 모바일 앱

`apps/mobile_flutter` 폴더는 사용자용 모바일 앱 영역입니다.

주요 역할은 다음과 같습니다.

* 사용자 로그인 및 회원가입
* 차량 등록
* 주차장 정보 확인
* 입출차 내역 확인
* 결제 기능 사용
* FastAPI 서버와 API 통신

Flutter 앱의 핵심 코드는 `lib` 폴더에 위치합니다.

```text
mobile_flutter
├── lib
├── android
├── ios
├── macos
├── assets/images
└── Backup
```

`Backup` 폴더는 현재 백업용으로 보이며, 프로젝트 정리 단계에서 삭제하거나 별도 보관하는 것을 권장합니다.

### 6. Vision / LPR 영역

`services/vision` 폴더는 차량 번호판 인식과 관련된 기능을 담당하는 영역입니다.

주요 역할은 다음과 같습니다.

* LPR 카메라 또는 웹캠 연동
* OpenCV 기반 차량 번호판 인식
* 인식된 차량 번호를 FastAPI 서버로 전달
* 입차 및 출차 판단 로직과 연결

### 7. 관리자 대시보드

`apps/admin_dashboard` 폴더는 추후 관리자용 웹 대시보드를 개발하기 위한 영역입니다.

관리자 대시보드에서는 다음 기능을 담당할 수 있습니다.

* 주차장 현황 확인
* 등록 차량 관리
* 사용자 관리
* 입출차 로그 확인
* 결제 내역 확인
* 시스템 상태 모니터링

## 전체 흐름 요약

Au-Park 프로젝트는 사용자용 Flutter 앱, FastAPI 백엔드 서버, Firebase Realtime Database, 차량 번호판 인식 모듈, 관리자 대시보드 영역으로 구성됩니다.

```text
Flutter 모바일 앱
    ↓
FastAPI 백엔드 서버
    ↓
Firebase Realtime Database

LPR / Vision 모듈
    ↓
FastAPI 백엔드 서버
    ↓
입출차 로그 및 주차 상태 갱신
```

모바일 앱은 FastAPI 서버에 요청을 보내고, FastAPI 서버는 Firebase Realtime Database와 연동하여 사용자, 차량, 주차, 결제, 로그 데이터를 관리합니다.

차량 번호판 인식 모듈은 인식된 차량 번호를 서버로 전달하고, 서버는 해당 정보를 바탕으로 입차 및 출차 기록을 저장합니다.
