from fastapi import APIRouter

from app.schemas.parking import LprParkingEventResult, ParkingEntryRequest, ParkingExitRequest
from app.services.parking_service import parking_service


router = APIRouter()


@router.post("/entry", response_model=LprParkingEventResult, status_code=201)
async def receive_entry_event(request: ParkingEntryRequest) -> LprParkingEventResult:
    return parking_service.process_lpr_entry(request)


@router.post("/exit", response_model=LprParkingEventResult, status_code=201)
async def receive_exit_event(request: ParkingExitRequest) -> LprParkingEventResult:
    return parking_service.process_lpr_exit(request)
