from fastapi import HTTPException, status

from app.schemas.log import EntryExitLog, EntryExitType
from app.schemas.parking import (
    ParkingEntryRequest,
    ParkingExitRequest,
    ParkingLot,
    ParkingSlot,
    ParkingStatusUpdateRequest,
)
from app.services.repository import InMemoryRepository, repository


class ParkingService:
    def __init__(self, repo: InMemoryRepository = repository) -> None:
        self.repo = repo

    def list_lots(self) -> list[ParkingLot]:
        for lot_id in list(self.repo.parking_lots):
            self.repo.recalculate_lot_availability(lot_id)
        return list(self.repo.parking_lots.values())

    def get_lot(self, lot_id: str) -> ParkingLot:
        lot = self.repo.parking_lots.get(lot_id)
        if lot is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parking lot not found")
        return lot

    def list_slots(self, lot_id: str) -> list[ParkingSlot]:
        self.get_lot(lot_id)
        slots = [slot for slot in self.repo.parking_slots.values() if slot.lot_id == lot_id]
        return sorted(slots, key=lambda slot: (slot.row or "", slot.column or 0, slot.label))

    def update_slot_status(self, lot_id: str, request: ParkingStatusUpdateRequest) -> ParkingSlot:
        self.get_lot(lot_id)
        slot = self.repo.parking_slots.get(request.slot_id)
        if slot is None or slot.lot_id != lot_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parking slot not found")

        updated = slot.model_copy(update={"status": request.status})
        self.repo.parking_slots[slot.id] = updated
        self.repo.recalculate_lot_availability(lot_id)
        return updated

    def record_entry(self, request: ParkingEntryRequest) -> EntryExitLog:
        self.get_lot(request.lot_id)
        return self.repo.record_parking_event(
            lot_id=request.lot_id,
            plate_number=request.plate_number,
            event_type=EntryExitType.entry,
        )

    def record_exit(self, request: ParkingExitRequest) -> EntryExitLog:
        self.get_lot(request.lot_id)
        return self.repo.record_parking_event(
            lot_id=request.lot_id,
            plate_number=request.plate_number,
            event_type=EntryExitType.exit,
        )


parking_service = ParkingService()
