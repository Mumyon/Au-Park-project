# Au-Park FastAPI Server

FastAPI server for the Au-Park parking system.

## Run

```powershell
cd E:\Au-Park\services\api
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

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
