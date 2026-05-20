from enum import StrEnum

from pydantic import BaseModel, Field


class PaymentStatus(StrEnum):
    requested = "requested"
    paid = "paid"
    failed = "failed"


class PaymentMethodCreateRequest(BaseModel):
    user_id: str
    method_name: str
    billing_key: str


class PaymentRequest(BaseModel):
    user_id: str
    vehicle_id: str
    amount: int = Field(ge=0)
    description: str = "Parking fee"


class Payment(BaseModel):
    id: str
    user_id: str
    vehicle_id: str
    amount: int
    status: PaymentStatus
    description: str
