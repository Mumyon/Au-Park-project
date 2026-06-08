from enum import StrEnum
from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.log import EntryExitLog
from app.schemas.payment import Payment


class SlotStatus(StrEnum):
    empty = "empty"
    occupied = "occupied"
    disabled = "disabled"


class ParkingSessionStatus(StrEnum):
    active = "active"
    completed = "completed"


class ParkingSlot(BaseModel):
    id: str
    lot_id: str
    label: str
    row: str | None = None
    column: int | None = None
    status: SlotStatus = SlotStatus.empty


class ParkingLot(BaseModel):
    id: str
    name: str
    address: str
    total_slots: int
    available_slots: int


class ParkingStatusUpdateRequest(BaseModel):
    slot_id: str
    status: SlotStatus


class ParkingEntryRequest(BaseModel):
    plate_number: str = Field(min_length=2, max_length=20)
    lot_id: str


class ParkingExitRequest(BaseModel):
    plate_number: str = Field(min_length=2, max_length=20)
    lot_id: str


class ParkingSession(BaseModel):
    id: str
    lot_id: str
    user_id: str
    vehicle_id: str
    plate_number: str
    entry_at: datetime
    exit_at: datetime | None = None
    status: ParkingSessionStatus = ParkingSessionStatus.active
    payment_id: str | None = None


class LprParkingEventResult(BaseModel):
    log: EntryExitLog
    registered: bool
    message: str
    session: ParkingSession | None = None
    payment: Payment | None = None
