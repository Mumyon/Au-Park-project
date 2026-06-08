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

    payment_method = client.post(
        "/api/v1/payments/methods",
        json={
            "user_id": user_id,
            "method_name": "테스트 카드",
            "billing_key": "billing-key-123",
        },
    )
    assert payment_method.status_code == 201

    lots = client.get("/api/v1/parking/lots")
    assert lots.status_code == 200
    assert lots.json()[0]["id"] == "lot-main"

    entry = client.post(
        "/api/v1/lpr/entry",
        json={"plate_number": "12가3456", "lot_id": "lot-main"},
    )
    assert entry.status_code == 201
    entry_body = entry.json()
    assert entry_body["registered"] is True
    assert entry_body["log"]["event_type"] == "entry"
    assert entry_body["session"]["status"] == "active"

    exit_event = client.post(
        "/api/v1/lpr/exit",
        json={"plate_number": "12가3456", "lot_id": "lot-main"},
    )
    assert exit_event.status_code == 201
    exit_body = exit_event.json()
    assert exit_body["registered"] is True
    assert exit_body["log"]["event_type"] == "exit"
    assert exit_body["session"]["status"] == "completed"
    assert exit_body["payment"]["status"] == "paid"
    assert exit_body["payment"]["amount"] == 1000
    assert exit_body["payment"]["method_name"] == "테스트 카드"


def test_lpr_entry_ignores_unregistered_vehicle_for_auto_session() -> None:
    response = client.post(
        "/api/v1/lpr/entry",
        json={"plate_number": "99가9999", "lot_id": "lot-main"},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["registered"] is False
    assert body["log"]["event_type"] == "entry"
    assert body["session"] is None
    assert body["payment"] is None


def test_lpr_exit_uses_prepaid_payment_without_surcharge() -> None:
    signup = client.post(
        "/api/v1/auth/signup",
        json={"email": "prepaid-ok@example.com", "password": "password123", "name": "Prepaid OK"},
    )
    user_id = signup.json()["id"]
    vehicle = client.post(
        "/api/v1/vehicles",
        json={"user_id": user_id, "plate_number": "22가2222"},
    ).json()

    entry = client.post(
        "/api/v1/lpr/entry",
        json={"plate_number": "22가2222", "lot_id": "lot-main"},
    ).json()
    prepaid = client.post(
        "/api/v1/payments/request",
        json={
            "user_id": user_id,
            "vehicle_id": vehicle["id"],
            "plate_number": "22가2222",
            "amount": 1000,
            "description": "사전 정산",
            "lot_id": "lot-main",
            "entry_at": entry["session"]["entry_at"],
            "exit_at": "2999-01-01T00:00:00Z",
        },
    )
    assert prepaid.status_code == 201

    exit_event = client.post(
        "/api/v1/lpr/exit",
        json={"plate_number": "22가2222", "lot_id": "lot-main"},
    )

    assert exit_event.status_code == 201
    body = exit_event.json()
    assert body["message"] == "사전 정산 내역으로 출차가 처리되었습니다."
    assert body["payment"]["id"] == prepaid.json()["id"]
    assert body["session"]["payment_id"] == prepaid.json()["id"]


def test_lpr_exit_charges_surcharge_when_prepaid_exit_time_is_exceeded() -> None:
    signup = client.post(
        "/api/v1/auth/signup",
        json={"email": "prepaid-late@example.com", "password": "password123", "name": "Prepaid Late"},
    )
    user_id = signup.json()["id"]
    vehicle = client.post(
        "/api/v1/vehicles",
        json={"user_id": user_id, "plate_number": "33가3333"},
    ).json()

    entry = client.post(
        "/api/v1/lpr/entry",
        json={"plate_number": "33가3333", "lot_id": "lot-main"},
    ).json()
    prepaid = client.post(
        "/api/v1/payments/request",
        json={
            "user_id": user_id,
            "vehicle_id": vehicle["id"],
            "plate_number": "33가3333",
            "amount": 1000,
            "description": "사전 정산",
            "lot_id": "lot-main",
            "entry_at": entry["session"]["entry_at"],
            "exit_at": entry["session"]["entry_at"],
        },
    )
    assert prepaid.status_code == 201

    exit_event = client.post(
        "/api/v1/lpr/exit",
        json={"plate_number": "33가3333", "lot_id": "lot-main"},
    )

    assert exit_event.status_code == 201
    body = exit_event.json()
    assert body["message"] == "사전 정산 시간을 초과하여 추가 요금이 자동 결제되었습니다."
    assert body["payment"]["id"] != prepaid.json()["id"]
    assert body["payment"]["amount"] == 1000
    assert body["payment"]["description"].endswith("사전 정산 초과 추가 결제")
