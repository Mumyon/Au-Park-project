from fastapi import APIRouter

from app.schemas.log import EntryExitLog
from app.schemas.parking import (
    ActiveParkingStatus,
    ParkingEntryRequest,
    ParkingExitRequest,
    ParkingLot,
    ParkingSession,
    ParkingSlot,
    ParkingStatusBulkUpdateRequest,
    ParkingStatusUpdateRequest,
)
from app.services.parking_service import parking_service


router = APIRouter()


@router.get("/lots", response_model=list[ParkingLot])
async def list_parking_lots() -> list[ParkingLot]:
    return parking_service.list_lots()


@router.get("/lots/{lot_id}", response_model=ParkingLot)
async def get_parking_lot(lot_id: str) -> ParkingLot:
    return parking_service.get_lot(lot_id)


@router.get("/lots/{lot_id}/slots", response_model=list[ParkingSlot])
async def list_parking_slots(lot_id: str) -> list[ParkingSlot]:
    return parking_service.list_slots(lot_id)


@router.get("/sessions/active", response_model=ActiveParkingStatus | None)
async def get_active_parking_session(user_id: str) -> ActiveParkingStatus | None:
    return parking_service.get_active_status(user_id)


@router.patch("/lots/{lot_id}/slots/status", response_model=ParkingSlot)
async def update_slot_status(lot_id: str, request: ParkingStatusUpdateRequest) -> ParkingSlot:
    return parking_service.update_slot_status(lot_id, request)


@router.patch("/lots/{lot_id}/slots/statuses", response_model=list[ParkingSlot])
async def update_slot_statuses(lot_id: str, request: ParkingStatusBulkUpdateRequest) -> list[ParkingSlot]:
    return parking_service.update_slot_statuses(lot_id, request)


@router.post("/entry", response_model=EntryExitLog, status_code=201)
async def record_entry(request: ParkingEntryRequest) -> EntryExitLog:
    return parking_service.record_entry(request)


@router.post("/exit", response_model=EntryExitLog, status_code=201)
async def record_exit(request: ParkingExitRequest) -> EntryExitLog:
    return parking_service.record_exit(request)
