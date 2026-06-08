from datetime import UTC, datetime, timedelta

from app.schemas.payment import Payment, PaymentMethodCreateRequest, PaymentRequest, PaymentStatus
from app.services.auth_service import auth_service
from app.services.repository import InMemoryRepository, repository
from app.services.vehicle_service import vehicle_service


class PaymentService:
    def __init__(self, repo: InMemoryRepository = repository) -> None:
        self.repo = repo

    def register_method(self, request: PaymentMethodCreateRequest) -> dict[str, str]:
        auth_service.get_user(request.user_id)
        method_id = self.repo.next_id("payment_method")
        self.repo.payment_methods[method_id] = request
        return {"message": "Payment method registered", "id": method_id}

    def request_payment(self, request: PaymentRequest) -> Payment:
        auth_service.get_user(request.user_id)
        vehicle_id = request.vehicle_id
        plate_number = request.plate_number
        paid_at = datetime.now(UTC)
        exit_at = self._as_aware_utc(request.exit_at) or paid_at
        entry_at = self._as_aware_utc(request.entry_at) or exit_at - timedelta(hours=1)
        duration_minutes = request.duration_minutes or self._duration_minutes(entry_at, exit_at)

        if vehicle_id:
            vehicle = vehicle_service.get(vehicle_id)
            plate_number = plate_number or vehicle.plate_number
        elif plate_number:
            matched_vehicle = next(
                (
                    vehicle
                    for vehicle in self.repo.vehicles.values()
                    if vehicle.user_id == request.user_id and vehicle.plate_number == plate_number
                ),
                None,
            )
            vehicle_id = matched_vehicle.id if matched_vehicle else None

        paid_date = self._date_label(paid_at)
        description = request.description
        if not description or description == "Parking fee":
            description = f"{paid_date} 주차 정산"

        payment = Payment(
            id=self.repo.next_id("payment"),
            user_id=request.user_id,
            vehicle_id=vehicle_id,
            plate_number=plate_number,
            amount=request.amount,
            description=description,
            status=PaymentStatus.paid,
            lot_id=request.lot_id,
            lot_name=request.lot_name or "정문 제1주차장",
            entry_at=entry_at,
            exit_at=exit_at,
            duration_minutes=duration_minutes,
            method_name=request.method_name,
            paid_at=paid_at,
            paid_date=paid_date,
        )
        self.repo.payments[payment.id] = payment
        print(f"Payment completed: {payment.model_dump(mode='json')}")
        return payment

    def list_by_user(self, user_id: str) -> list[Payment]:
        payments = [
            self._normalize_payment(payment)
            for payment in self.repo.payments.values()
            if payment.user_id == user_id
        ]
        return sorted(payments, key=lambda payment: payment.paid_at or payment.exit_at or datetime.min.replace(tzinfo=UTC), reverse=True)

    def _normalize_payment(self, payment: Payment) -> Payment:
        paid_at = self._as_aware_utc(payment.paid_at) or self._as_aware_utc(payment.exit_at) or datetime.now(UTC)
        exit_at = paid_at
        entry_at = self._as_aware_utc(payment.entry_at) or exit_at - timedelta(hours=1)
        plate_number = payment.plate_number
        if not plate_number and payment.vehicle_id:
            vehicle = self.repo.vehicles.get(payment.vehicle_id)
            plate_number = vehicle.plate_number if vehicle else None
        duration_minutes = self._duration_minutes(entry_at, paid_at)

        paid_date = payment.paid_date or self._date_label(paid_at)
        description = payment.description
        if not description or description == "Parking fee":
            description = f"{paid_date} 주차 정산"

        updated = payment.model_copy(
            update={
                "description": description,
                "plate_number": plate_number,
                "lot_id": payment.lot_id or "lot-main",
                "lot_name": payment.lot_name or "정문 제1주차장",
                "entry_at": entry_at,
                "exit_at": exit_at,
                "duration_minutes": duration_minutes,
                "paid_at": paid_at,
                "paid_date": paid_date,
            }
        )

        if updated != payment:
            self.repo.payments[updated.id] = updated
        return updated

    @staticmethod
    def _as_aware_utc(value: datetime | None) -> datetime | None:
        if value is None:
            return None
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    @staticmethod
    def _duration_minutes(entry_at: datetime, paid_at: datetime) -> int:
        return max(0, int((paid_at - entry_at).total_seconds() // 60))

    @staticmethod
    def _date_label(value: datetime) -> str:
        local_value = value.astimezone(UTC)
        return f"{local_value.year}.{local_value.month:02d}.{local_value.day:02d}"


payment_service = PaymentService()
