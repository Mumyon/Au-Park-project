from fastapi import APIRouter

from app.schemas.payment import Payment
from app.schemas.user import User, UserUpdateRequest
from app.schemas.vehicle import Vehicle
from app.services.auth_service import auth_service
from app.services.payment_service import payment_service
from app.services.vehicle_service import vehicle_service


router = APIRouter()


@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str) -> User:
    return auth_service.get_user(user_id)


@router.patch("/{user_id}", response_model=User)
async def update_user(user_id: str, request: UserUpdateRequest) -> User:
    return auth_service.update_user(user_id, request)


@router.get("/{user_id}/vehicles", response_model=list[Vehicle])
async def get_user_vehicles(user_id: str) -> list[Vehicle]:
    return vehicle_service.list_by_user(user_id)


@router.get("/{user_id}/payments", response_model=list[Payment])
async def get_user_payments(user_id: str) -> list[Payment]:
    return payment_service.list_by_user(user_id)
