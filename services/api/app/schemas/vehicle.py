from pydantic import BaseModel, Field


class VehicleCreateRequest(BaseModel):
    user_id: str
    plate_number: str = Field(min_length=2, max_length=20)
    nickname: str | None = None
    model: str | None = None


class VehicleUpdateRequest(BaseModel):
    nickname: str | None = None
    model: str | None = None


class Vehicle(BaseModel):
    id: str
    user_id: str
    plate_number: str
    nickname: str | None = None
    model: str | None = None
