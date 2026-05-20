from pydantic import BaseModel, EmailStr


class User(BaseModel):
    id: str
    email: EmailStr
    name: str
    phone: str | None = None


class UserUpdateRequest(BaseModel):
    name: str | None = None
    phone: str | None = None
