from fastapi import APIRouter

from app.schemas.auth import LoginRequest, SignUpRequest, TokenResponse
from app.schemas.user import User
from app.services.auth_service import auth_service


router = APIRouter()


@router.post("/signup", response_model=User, status_code=201)
async def sign_up(request: SignUpRequest) -> User:
    return auth_service.sign_up(request)


@router.post("/login", response_model=TokenResponse)
async def login(request: LoginRequest) -> TokenResponse:
    return auth_service.login(request)
