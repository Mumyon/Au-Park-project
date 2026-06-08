from datetime import UTC, datetime, timedelta

from fastapi.testclient import TestClient

from app.main import app
from app.services.parking_fee import calculate_parking_fee, calculate_parking_fee_breakdown
from app.services.repository import repository


client = TestClient(app)


def test_health_check() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_default_parking_lot_layout() -> None:
    lots = client.get("/api/v1/parking/lots")
    assert lots.status_code == 200
    lot = lots.json()[0]
    assert lot["id"] == "lot-main"
    assert lot["name"] == "진리관 주차장"
    assert lot["total_slots"] == 42
    assert lot["available_slots"] == 42

    slots = client.get("/api/v1/parking/lots/lot-main/slots")
    assert slots.status_code == 200
    body = slots.json()
    front_row = [slot for slot in body if slot["row"] == "A"]
    center_row = [slot for slot in body if slot["row"] == "B"]

    assert len(body) == 42
    assert len(front_row) == 23
    assert len(center_row) == 19
    assert front_row[0]["label"] == "A1"
    assert front_row[-1]["label"] == "A23"
    assert center_row[0]["label"] == "B1"
    assert center_row[-1]["label"] == "B19"
    assert [slot["slot_type"] for slot in front_row[:2]] == ["accessible", "accessible"]
    assert all(slot["slot_type"] == "general" for slot in front_row[2:])
    assert all(slot["slot_type"] == "general" for slot in center_row)


def test_bulk_parking_slot_status_update() -> None:
    response = client.patch(
        "/api/v1/parking/lots/lot-main/slots/statuses",
        json={
            "slots": [
                {"slot_id": "A-01", "status": "occupied"},
                {"slot_id": "A-02", "status": "occupied"},
            ]
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert [slot["id"] for slot in body] == ["A-01", "A-02"]
    assert all(slot["status"] == "occupied" for slot in body)

    lots = client.get("/api/v1/parking/lots")
    assert lots.status_code == 200
    assert lots.json()[0]["available_slots"] == 40


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
    assert exit_body["payment"]["amount"] == 0
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


def test_parking_fee_policy() -> None:
    assert calculate_parking_fee(0) == 0
    assert calculate_parking_fee(30) == 0
    assert calculate_parking_fee(31) == 1500
    assert calculate_parking_fee(60) == 1500
    assert calculate_parking_fee(61) == 2000
    assert calculate_parking_fee(70) == 2000
    assert calculate_parking_fee(71) == 2500
    assert calculate_parking_fee(24 * 60) == 15000
    assert calculate_parking_fee(24 * 60 + 31) == 16500
    assert calculate_parking_fee_breakdown(30) == {
        "base_fee": 0,
        "additional_fee": 0,
        "total_fee": 0,
    }
    assert calculate_parking_fee_breakdown(31) == {
        "base_fee": 1500,
        "additional_fee": 0,
        "total_fee": 1500,
    }
    assert calculate_parking_fee_breakdown(61) == {
        "base_fee": 1500,
        "additional_fee": 500,
        "total_fee": 2000,
    }
    assert calculate_parking_fee_breakdown(71) == {
        "base_fee": 1500,
        "additional_fee": 1000,
        "total_fee": 2500,
    }


def test_lpr_auto_toggles_entry_and_exit() -> None:
    signup = client.post(
        "/api/v1/auth/signup",
        json={
            "email": "auto-lpr@example.com",
            "password": "password123",
            "name": "Auto LPR",
        },
    )
    assert signup.status_code == 201
    user_id = signup.json()["id"]
    vehicle = client.post(
        "/api/v1/vehicles",
        json={"user_id": user_id, "plate_number": "55다5555"},
    )
    assert vehicle.status_code == 201

    entry = client.post(
        "/api/v1/lpr/auto",
        json={"plate_number": "55다5555", "lot_id": "lot-main"},
    )
    assert entry.status_code == 201
    assert entry.json()["session"]["status"] == "active"

    exit_event = client.post(
        "/api/v1/lpr/auto",
        json={"plate_number": "55다5555", "lot_id": "lot-main"},
    )
    assert exit_event.status_code == 201
    assert exit_event.json()["session"]["status"] == "completed"
    assert exit_event.json()["payment"]["amount"] == 0


def test_active_parking_session_tracks_lpr_entry_and_exit() -> None:
    signup = client.post(
        "/api/v1/auth/signup",
        json={
            "email": "active-session@example.com",
            "password": "password123",
            "name": "Active Session",
        },
    )
    assert signup.status_code == 201
    user_id = signup.json()["id"]

    before_entry = client.get(
        "/api/v1/parking/sessions/active",
        params={"user_id": user_id},
    )
    assert before_entry.status_code == 200
    assert before_entry.json() is None

    vehicle = client.post(
        "/api/v1/vehicles",
        json={"user_id": user_id, "plate_number": "44나4444"},
    )
    assert vehicle.status_code == 201

    entry = client.post(
        "/api/v1/lpr/entry",
        json={"plate_number": "44나4444", "lot_id": "lot-main"},
    )
    assert entry.status_code == 201

    active = client.get(
        "/api/v1/parking/sessions/active",
        params={"user_id": user_id},
    )
    assert active.status_code == 200
    assert active.json()["session"]["plate_number"] == "44나4444"
    assert active.json()["session"]["status"] == "active"
    assert active.json()["outstanding_fee"] == 0

    exit_event = client.post(
        "/api/v1/lpr/exit",
        json={"plate_number": "44나4444", "lot_id": "lot-main"},
    )
    assert exit_event.status_code == 201

    after_exit = client.get(
        "/api/v1/parking/sessions/active",
        params={"user_id": user_id},
    )
    assert after_exit.status_code == 200
    assert after_exit.json() is None


def test_prepayment_is_deducted_from_live_outstanding_fee() -> None:
    signup = client.post(
        "/api/v1/auth/signup",
        json={
            "email": "prepay-live@example.com",
            "password": "password123",
            "name": "Prepay Live",
        },
    )
    assert signup.status_code == 201
    user_id = signup.json()["id"]
    vehicle = client.post(
        "/api/v1/vehicles",
        json={"user_id": user_id, "plate_number": "66라6666"},
    ).json()
    entry = client.post(
        "/api/v1/lpr/entry",
        json={"plate_number": "66라6666", "lot_id": "lot-main"},
    ).json()
    session_id = entry["session"]["id"]
    session = repository.parking_sessions[session_id]
    repository.parking_sessions[session_id] = session.model_copy(
        update={"entry_at": datetime.now(UTC) - timedelta(minutes=61)}
    )

    first_status = client.get(
        "/api/v1/parking/sessions/active",
        params={"user_id": user_id},
    ).json()
    assert first_status["total_fee"] == 2000
    assert first_status["base_fee"] == 1500
    assert first_status["additional_fee"] == 500
    assert first_status["prepaid_amount"] == 0
    assert first_status["outstanding_fee"] == 2000

    first_payment = client.post(
        "/api/v1/payments/request",
        json={
            "user_id": user_id,
            "plate_number": "66 라 6666",
            "amount": 2000,
            "description": "사전 정산",
            "lot_id": "lot-main",
            "entry_at": first_status["session"]["entry_at"],
            "exit_at": datetime.now(UTC).isoformat(),
            "duration_minutes": 61,
        },
    )
    assert first_payment.status_code == 201
    assert first_payment.json()["amount"] == 2000

    after_prepay = client.get(
        "/api/v1/parking/sessions/active",
        params={"user_id": user_id},
    ).json()
    assert after_prepay["prepaid_amount"] == 2000
    assert after_prepay["outstanding_fee"] == 0

    current_session = repository.parking_sessions[session_id]
    repository.parking_sessions[session_id] = current_session.model_copy(
        update={"entry_at": datetime.now(UTC) - timedelta(minutes=71)}
    )
    later_status = client.get(
        "/api/v1/parking/sessions/active",
        params={"user_id": user_id},
    ).json()
    assert later_status["total_fee"] == 2500
    assert later_status["base_fee"] == 1500
    assert later_status["additional_fee"] == 1000
    assert later_status["prepaid_amount"] == 2000
    assert later_status["outstanding_fee"] == 500

    second_payment = client.post(
        "/api/v1/payments/request",
        json={
            "user_id": user_id,
            "vehicle_id": vehicle["id"],
            "plate_number": "66라6666",
            "amount": 500,
            "description": "추가 사전 정산",
            "lot_id": "lot-main",
            "entry_at": later_status["session"]["entry_at"],
            "exit_at": datetime.now(UTC).isoformat(),
            "duration_minutes": 71,
        },
    )
    assert second_payment.status_code == 201
    assert second_payment.json()["amount"] == 500


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


def test_lpr_exit_skips_surcharge_when_total_fee_does_not_increase() -> None:
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
    assert body["message"] == "사전 정산 후 추가 요금 없이 출차가 처리되었습니다."
    assert body["payment"]["id"] == prepaid.json()["id"]
