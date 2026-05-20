from datetime import UTC, datetime
from uuid import uuid4

from app.schemas.log import EntryExitLog, EntryExitType
from app.schemas.parking import ParkingLot, ParkingSlot, SlotStatus
from app.schemas.payment import Payment
from app.schemas.user import User
from app.schemas.vehicle import Vehicle


class InMemoryRepository:
    def __init__(self) -> None:
        self.users: dict[str, User] = {}
        self.user_passwords: dict[str, str] = {}
        self.vehicles: dict[str, Vehicle] = {}
        self.parking_lots: dict[str, ParkingLot] = {
            "lot-main": ParkingLot(
                id="lot-main",
                name="Au-Park Main",
                address="Demo parking lot",
                total_slots=4,
                available_slots=4,
            )
        }
        self.parking_slots: dict[str, ParkingSlot] = {
            f"A-{index}": ParkingSlot(id=f"A-{index}", lot_id="lot-main", label=f"A-{index}")
            for index in range(1, 5)
        }
        self.payments: dict[str, Payment] = {}
        self.entry_exit_logs: dict[str, EntryExitLog] = {}

    @staticmethod
    def next_id(prefix: str) -> str:
        return f"{prefix}_{uuid4().hex[:12]}"

    def record_parking_event(
        self,
        lot_id: str,
        plate_number: str,
        event_type: EntryExitType,
    ) -> EntryExitLog:
        log = EntryExitLog(
            id=self.next_id("log"),
            lot_id=lot_id,
            plate_number=plate_number,
            event_type=event_type,
            occurred_at=datetime.now(UTC),
        )
        self.entry_exit_logs[log.id] = log
        return log

    def recalculate_lot_availability(self, lot_id: str) -> ParkingLot | None:
        lot = self.parking_lots.get(lot_id)
        if lot is None:
            return None

        slots = [slot for slot in self.parking_slots.values() if slot.lot_id == lot_id]
        available = sum(1 for slot in slots if slot.status == SlotStatus.empty)
        updated = lot.model_copy(update={"total_slots": len(slots), "available_slots": available})
        self.parking_lots[lot_id] = updated
        return updated


repository = InMemoryRepository()
