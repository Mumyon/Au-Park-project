from datetime import UTC, datetime

from app.schemas.parking import ParkingSession
from app.schemas.payment import Payment, PaymentStatus


def normalize_plate(plate_number: str | None) -> str:
    return "".join((plate_number or "").split()).upper()


def as_aware_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def payment_matches_session(payment: Payment, session: ParkingSession) -> bool:
    if payment.status != PaymentStatus.paid:
        return False
    if payment.user_id != session.user_id:
        return False
    if payment.lot_id and payment.lot_id != session.lot_id:
        return False

    matched_by_vehicle = bool(payment.vehicle_id and payment.vehicle_id == session.vehicle_id)
    matched_by_plate = bool(
        payment.plate_number
        and normalize_plate(payment.plate_number) == normalize_plate(session.plate_number)
    )
    if not matched_by_vehicle and not matched_by_plate:
        return False

    covered_at = as_aware_utc(payment.exit_at) or as_aware_utc(payment.paid_at)
    session_entry_at = as_aware_utc(session.entry_at)
    return bool(covered_at and session_entry_at and covered_at >= session_entry_at)
