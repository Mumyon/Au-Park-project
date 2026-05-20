from enum import StrEnum

from pydantic import BaseModel, Field


class SlotStatus(StrEnum):
    empty = "empty"
    occupied = "occupied"
    disabled = "disabled"


class ParkingSlot(BaseModel):
    id: str
    lot_id: str
    label: str
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
