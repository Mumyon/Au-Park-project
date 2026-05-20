from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health_check() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_signup_vehicle_parking_flow() -> None:
    signup = client.post(
        "/api/v1/auth/signup",
        json={"email": "driver@example.com", "password": "password123", "name": "Driver"},
    )
    assert signup.status_code == 201
    user_id = signup.json()["id"]

    vehicle = client.post(
        "/api/v1/vehicles",
        json={"user_id": user_id, "plate_number": "12가3456", "nickname": "main"},
    )
    assert vehicle.status_code == 201

    lots = client.get("/api/v1/parking/lots")
    assert lots.status_code == 200
    assert lots.json()[0]["id"] == "lot-main"

    entry = client.post(
        "/api/v1/lpr/entry",
        json={"plate_number": "12가3456", "lot_id": "lot-main"},
    )
    assert entry.status_code == 201
    assert entry.json()["event_type"] == "entry"
