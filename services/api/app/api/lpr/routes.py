from fastapi import APIRouter

from app.schemas.log import EntryExitLog
from app.schemas.parking import ParkingEntryRequest, ParkingExitRequest
from app.services.parking_service import parking_service


router = APIRouter()


@router.post("/entry", response_model=EntryExitLog, status_code=201)
async def receive_entry_event(request: ParkingEntryRequest) -> EntryExitLog:
    return parking_service.record_entry(request)


@router.post("/exit", response_model=EntryExitLog, status_code=201)
async def receive_exit_event(request: ParkingExitRequest) -> EntryExitLog:
    return parking_service.record_exit(request)
