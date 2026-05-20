from fastapi import APIRouter

from app.schemas.payment import Payment, PaymentMethodCreateRequest, PaymentRequest
from app.services.payment_service import payment_service


router = APIRouter()


@router.post("/methods", response_model=dict[str, str], status_code=201)
async def register_payment_method(request: PaymentMethodCreateRequest) -> dict[str, str]:
    return payment_service.register_method(request)


@router.post("/request", response_model=Payment, status_code=201)
async def request_payment(request: PaymentRequest) -> Payment:
    return payment_service.request_payment(request)


@router.get("", response_model=list[Payment])
async def list_payments(user_id: str) -> list[Payment]:
    return payment_service.list_by_user(user_id)
