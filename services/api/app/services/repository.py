from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Generic, Iterable, Iterator, MutableMapping, TypeVar
from uuid import uuid4

from pydantic import BaseModel

from app.core.config import settings
from app.schemas.log import EntryExitLog, EntryExitType
from app.schemas.parking import ParkingLot, ParkingSlot, SlotStatus
from app.schemas.payment import Payment, PaymentMethodCreateRequest
from app.schemas.user import User
from app.schemas.vehicle import Vehicle

ModelT = TypeVar("ModelT", bound=BaseModel)


def next_id(prefix: str) -> str:
    return f"{prefix}_{uuid4().hex[:12]}"


class FirebaseModelCollection(MutableMapping[str, ModelT], Generic[ModelT]):
    def __init__(self, root_ref: Any, path: str, model_type: type[ModelT]) -> None:
        self.ref = root_ref.child(path)
        self.model_type = model_type

    def __getitem__(self, key: str) -> ModelT:
        value = self.ref.child(key).get()
        if value is None:
            raise KeyError(key)
        return self.model_type.model_validate(value)

    def __setitem__(self, key: str, value: ModelT) -> None:
        self.ref.child(key).set(value.model_dump(mode="json"))

    def __delitem__(self, key: str) -> None:
        if self.ref.child(key).get() is None:
            raise KeyError(key)
        self.ref.child(key).delete()

    def __iter__(self) -> Iterator[str]:
        return iter(self._raw_data())

    def __len__(self) -> int:
        return len(self._raw_data())

    def get(self, key: str, default: ModelT | None = None) -> ModelT | None:
        value = self.ref.child(key).get()
        if value is None:
            return default
        return self.model_type.model_validate(value)

    def items(self) -> Iterable[tuple[str, ModelT]]:  # type: ignore[override]
        return ((key, self.model_type.model_validate(value)) for key, value in self._raw_data().items())

    def values(self) -> Iterable[ModelT]:  # type: ignore[override]
        return (self.model_type.model_validate(value) for value in self._raw_data().values())

    def _raw_data(self) -> dict[str, Any]:
        data = self.ref.get()
        if data is None:
            return {}
        if not isinstance(data, dict):
            return {}
        return data


class FirebaseStringCollection(MutableMapping[str, str]):
    def __init__(self, root_ref: Any, path: str) -> None:
        self.ref = root_ref.child(path)

    def __getitem__(self, key: str) -> str:
        value = self.ref.child(key).get()
        if value is None:
            raise KeyError(key)
        return str(value)

    def __setitem__(self, key: str, value: str) -> None:
        self.ref.child(key).set(value)

    def __delitem__(self, key: str) -> None:
        if self.ref.child(key).get() is None:
            raise KeyError(key)
        self.ref.child(key).delete()

    def __iter__(self) -> Iterator[str]:
        return iter(self._raw_data())

    def __len__(self) -> int:
        return len(self._raw_data())

    def get(self, key: str, default: str | None = None) -> str | None:
        value = self.ref.child(key).get()
        if value is None:
            return default
        return str(value)

    def _raw_data(self) -> dict[str, Any]:
        data = self.ref.get()
        if data is None:
            return {}
        if not isinstance(data, dict):
            return {}
        return data


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
        self.payment_methods: dict[str, PaymentMethodCreateRequest] = {}
        self.entry_exit_logs: dict[str, EntryExitLog] = {}

    @staticmethod
    def next_id(prefix: str) -> str:
        return next_id(prefix)

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


class FirebaseRealtimeRepository(InMemoryRepository):
    def __init__(self) -> None:
        self.root_ref = self._initialize_firebase()
        self.users = FirebaseModelCollection(self.root_ref, "users", User)
        self.user_passwords = FirebaseStringCollection(self.root_ref, "user_passwords")
        self.vehicles = FirebaseModelCollection(self.root_ref, "vehicles", Vehicle)
        self.parking_lots = FirebaseModelCollection(self.root_ref, "parking_lots", ParkingLot)
        self.parking_slots = FirebaseModelCollection(self.root_ref, "parking_slots", ParkingSlot)
        self.payments = FirebaseModelCollection(self.root_ref, "payments", Payment)
        self.payment_methods = FirebaseModelCollection(
            self.root_ref,
            "payment_methods",
            PaymentMethodCreateRequest,
        )
        self.entry_exit_logs = FirebaseModelCollection(self.root_ref, "entry_exit_logs", EntryExitLog)
        self._seed_default_parking_data()

    @staticmethod
    def _initialize_firebase() -> Any:
        try:
            import firebase_admin
            from firebase_admin import credentials, db
        except ImportError as exc:
            raise RuntimeError(
                "firebase-admin is required when FIREBASE_DATABASE_URL is configured"
            ) from exc

        options = {"databaseURL": settings.firebase_database_url}
        try:
            firebase_admin.get_app()
        except ValueError:
            if settings.firebase_credentials_path:
                credential_path = Path(settings.firebase_credentials_path).expanduser()
                cred = credentials.Certificate(str(credential_path))
                firebase_admin.initialize_app(cred, options)
            else:
                firebase_admin.initialize_app(options=options)

        return db.reference("/")

    def _seed_default_parking_data(self) -> None:
        if self.parking_lots:
            return

        self.parking_lots["lot-main"] = ParkingLot(
            id="lot-main",
            name="Au-Park Main",
            address="Demo parking lot",
            total_slots=4,
            available_slots=4,
        )
        for index in range(1, 5):
            slot_id = f"A-{index}"
            self.parking_slots[slot_id] = ParkingSlot(id=slot_id, lot_id="lot-main", label=slot_id)


def create_repository() -> InMemoryRepository:
    if settings.firebase_database_url:
        return FirebaseRealtimeRepository()
    return InMemoryRepository()


repository = create_repository()
