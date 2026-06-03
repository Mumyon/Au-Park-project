from enum import StrEnum

from pydantic import BaseModel, EmailStr, Field


class SignUpRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    name: str = Field(min_length=1, max_length=50)
    phone: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class SocialAuthProvider(StrEnum):
    google = "google"
    kakao = "kakao"
    naver = "naver"


class SocialLoginRequest(BaseModel):
    provider: SocialAuthProvider
    token: str = Field(min_length=1)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
