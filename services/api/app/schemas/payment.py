from enum import StrEnum
from datetime import datetime

from pydantic import BaseModel, Field


class PaymentStatus(StrEnum):
    requested = "requested"
    paid = "paid"
    failed = "failed"


class PaymentMethodCreateRequest(BaseModel):
    user_id: str
    method_name: str
    billing_key: str
    pg_provider: str | None = None
    pay_method: str | None = None
    imp_uid: str | None = None
    merchant_uid: str | None = None
    customer_uid: str | None = None
    status: str | None = None


class PaymentRequest(BaseModel):
    user_id: str
    vehicle_id: str | None = None
    plate_number: str | None = None
    amount: int = Field(ge=0)
    description: str = "Parking fee"
    lot_id: str | None = None
    lot_name: str | None = None
    entry_at: datetime | None = None
    exit_at: datetime | None = None
    duration_minutes: int | None = Field(default=None, ge=0)
    method_name: str | None = None


class Payment(BaseModel):
    id: str
    user_id: str
    vehicle_id: str | None = None
    plate_number: str | None = None
    amount: int
    status: PaymentStatus
    description: str
    lot_id: str | None = None
    lot_name: str | None = None
    entry_at: datetime | None = None
    exit_at: datetime | None = None
    duration_minutes: int | None = None
    method_name: str | None = None
    paid_at: datetime | None = None
    paid_date: str | None = None
