from datetime import UTC, datetime

from fastapi import HTTPException, status

from app.schemas.log import EntryExitLog, EntryExitType
from app.schemas.parking import (
    ActiveParkingStatus,
    LprParkingEventResult,
    ParkingEntryRequest,
    ParkingExitRequest,
    ParkingLot,
    ParkingSession,
    ParkingSessionStatus,
    ParkingSlot,
    ParkingStatusBulkUpdateRequest,
    ParkingStatusUpdateRequest,
)
from app.schemas.payment import Payment, PaymentStatus
from app.schemas.vehicle import Vehicle
from app.services.parking_fee import calculate_parking_fee, calculate_parking_fee_breakdown
from app.services.parking_payment_matcher import normalize_plate, payment_matches_session
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

    def get_active_session(self, user_id: str) -> ParkingSession | None:
        sessions = [
            session
            for session in self.repo.parking_sessions.values()
            if session.user_id == user_id and session.status == ParkingSessionStatus.active
        ]
        return max(
            sessions,
            key=lambda session: self._as_aware_utc(session.entry_at),
            default=None,
        )

    def get_active_status(self, user_id: str) -> ActiveParkingStatus | None:
        session = self.get_active_session(user_id)
        if session is None:
            return None
        now = datetime.now(UTC)
        duration_minutes = self._duration_minutes(session.entry_at, now)
        fee = calculate_parking_fee_breakdown(duration_minutes)
        total_fee = fee["total_fee"]
        prepaid_amount = sum(
            payment.amount for payment in self._find_prepaid_payments(session)
        )
        return ActiveParkingStatus(
            session=session,
            duration_minutes=duration_minutes,
            base_fee=fee["base_fee"],
            additional_fee=fee["additional_fee"],
            total_fee=total_fee,
            prepaid_amount=prepaid_amount,
            outstanding_fee=max(0, total_fee - prepaid_amount),
        )

    def update_slot_status(self, lot_id: str, request: ParkingStatusUpdateRequest) -> ParkingSlot:
        self.get_lot(lot_id)
        slot = self.repo.parking_slots.get(request.slot_id)
        if slot is None or slot.lot_id != lot_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Parking slot not found")

        updated = slot.model_copy(update={"status": request.status})
        self.repo.parking_slots[slot.id] = updated
        self.repo.recalculate_lot_availability(lot_id)
        return updated

    def update_slot_statuses(self, lot_id: str, request: ParkingStatusBulkUpdateRequest) -> list[ParkingSlot]:
        self.get_lot(lot_id)
        updated_slots: list[ParkingSlot] = []

        for item in request.slots:
            slot = self.repo.parking_slots.get(item.slot_id)
            if slot is None or slot.lot_id != lot_id:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Parking slot not found: {item.slot_id}")
            updated = slot.model_copy(update={"status": item.status})
            self.repo.parking_slots[slot.id] = updated
            updated_slots.append(updated)

        self.repo.recalculate_lot_availability(lot_id)
        return updated_slots

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

    def process_lpr_entry(self, request: ParkingEntryRequest) -> LprParkingEventResult:
        self.get_lot(request.lot_id)
        plate_number = self._normalize_plate(request.plate_number)
        log = self.repo.record_parking_event(
            lot_id=request.lot_id,
            plate_number=plate_number,
            event_type=EntryExitType.entry,
        )
        vehicle = self._find_vehicle_by_plate(plate_number)
        if vehicle is None:
            return LprParkingEventResult(
                log=log,
                registered=False,
                message="등록되지 않은 차량입니다. 자동 입차 처리 대상이 아닙니다.",
            )

        active_session = self._find_active_session(request.lot_id, plate_number)
        if active_session is not None:
            return LprParkingEventResult(
                log=log,
                registered=True,
                session=active_session,
                message="이미 입차 처리된 차량입니다.",
            )

        session = ParkingSession(
            id=self.repo.next_id("parking_session"),
            lot_id=request.lot_id,
            user_id=vehicle.user_id,
            vehicle_id=vehicle.id,
            plate_number=vehicle.plate_number,
            entry_at=log.occurred_at,
        )
        self.repo.parking_sessions[session.id] = session
        return LprParkingEventResult(
            log=log,
            registered=True,
            session=session,
            message="등록 회원 차량 입차가 자동 처리되었습니다.",
        )

    def process_lpr_auto(self, request: ParkingEntryRequest) -> LprParkingEventResult:
        plate_number = self._normalize_plate(request.plate_number)
        active_session = self._find_active_session(request.lot_id, plate_number)
        if active_session is not None:
            return self.process_lpr_exit(
                ParkingExitRequest(
                    lot_id=request.lot_id,
                    plate_number=plate_number,
                )
            )
        return self.process_lpr_entry(
            ParkingEntryRequest(
                lot_id=request.lot_id,
                plate_number=plate_number,
            )
        )

    def process_lpr_exit(self, request: ParkingExitRequest) -> LprParkingEventResult:
        self.get_lot(request.lot_id)
        plate_number = self._normalize_plate(request.plate_number)
        log = self.repo.record_parking_event(
            lot_id=request.lot_id,
            plate_number=plate_number,
            event_type=EntryExitType.exit,
        )
        vehicle = self._find_vehicle_by_plate(plate_number)
        if vehicle is None:
            return LprParkingEventResult(
                log=log,
                registered=False,
                message="등록되지 않은 차량입니다. 자동 결제 대상이 아닙니다.",
            )

        active_session = self._find_active_session(request.lot_id, plate_number)
        if active_session is None:
            return LprParkingEventResult(
                log=log,
                registered=True,
                message="등록 차량이지만 활성 입차 내역이 없어 자동 결제를 생성하지 않았습니다.",
            )

        exit_at = log.occurred_at
        prepaid_payments = self._find_prepaid_payments(active_session)
        if prepaid_payments:
            prepaid_payment = max(
                prepaid_payments,
                key=lambda payment: self._as_aware_utc(payment.exit_at)
                or datetime.min.replace(tzinfo=UTC),
            )
            prepaid_amount = sum(payment.amount for payment in prepaid_payments)
            prepaid_exit_at = self._as_aware_utc(prepaid_payment.exit_at)
            if prepaid_exit_at is not None and exit_at <= prepaid_exit_at:
                completed_session = self._complete_session(active_session, exit_at, prepaid_payment.id)
                return LprParkingEventResult(
                    log=log,
                    registered=True,
                    session=completed_session,
                    payment=prepaid_payment,
                    message="사전 정산 내역으로 출차가 처리되었습니다.",
                )

            surcharge_start_at = prepaid_exit_at or active_session.entry_at
            surcharge_minutes = self._duration_minutes(surcharge_start_at, exit_at)
            total_duration_minutes = self._duration_minutes(active_session.entry_at, exit_at)
            surcharge_amount = max(
                0,
                calculate_parking_fee(total_duration_minutes) - prepaid_amount,
            )
            if surcharge_amount == 0:
                completed_session = self._complete_session(
                    active_session,
                    exit_at,
                    prepaid_payment.id,
                )
                return LprParkingEventResult(
                    log=log,
                    registered=True,
                    session=completed_session,
                    payment=prepaid_payment,
                    message="사전 정산 후 추가 요금 없이 출차가 처리되었습니다.",
                )
            payment = self._create_auto_payment(
                session=active_session,
                entry_at=surcharge_start_at,
                exit_at=exit_at,
                duration_minutes=surcharge_minutes,
                description_suffix="사전 정산 초과 추가 결제",
                amount_override=surcharge_amount,
            )
            completed_session = self._complete_session(active_session, exit_at, payment.id)
            return LprParkingEventResult(
                log=log,
                registered=True,
                session=completed_session,
                payment=payment,
                message="사전 정산 시간을 초과하여 추가 요금이 자동 결제되었습니다.",
            )

        duration_minutes = self._duration_minutes(active_session.entry_at, exit_at)
        payment = self._create_auto_payment(
            session=active_session,
            entry_at=active_session.entry_at,
            exit_at=exit_at,
            duration_minutes=duration_minutes,
            description_suffix="자동 출차 정산",
        )
        completed_session = self._complete_session(active_session, exit_at, payment.id)
        return LprParkingEventResult(
            log=log,
            registered=True,
            session=completed_session,
            payment=payment,
            message="등록 회원 차량 출차와 자동 결제가 처리되었습니다.",
        )

    def _complete_session(
        self,
        session: ParkingSession,
        exit_at: datetime,
        payment_id: str,
    ) -> ParkingSession:
        completed_session = session.model_copy(
            update={
                "exit_at": exit_at,
                "status": ParkingSessionStatus.completed,
                "payment_id": payment_id,
            }
        )
        self.repo.parking_sessions[completed_session.id] = completed_session
        return completed_session

    def _create_auto_payment(
        self,
        session: ParkingSession,
        entry_at: datetime,
        exit_at: datetime,
        duration_minutes: int,
        description_suffix: str,
        amount_override: int | None = None,
    ) -> Payment:
        amount = (
            amount_override
            if amount_override is not None
            else calculate_parking_fee(duration_minutes)
        )
        paid_date = self._date_label(exit_at)
        payment = Payment(
            id=self.repo.next_id("payment"),
            user_id=session.user_id,
            vehicle_id=session.vehicle_id,
            plate_number=session.plate_number,
            amount=amount,
            status=PaymentStatus.paid,
            description=f"{paid_date} {description_suffix}",
            lot_id=session.lot_id,
            lot_name=self.get_lot(session.lot_id).name,
            entry_at=entry_at,
            exit_at=exit_at,
            duration_minutes=duration_minutes,
            method_name=self._auto_payment_method_name(session.user_id),
            paid_at=exit_at,
            paid_date=paid_date,
        )
        self.repo.payments[payment.id] = payment
        return payment

    def _find_prepaid_payments(self, session: ParkingSession) -> list[Payment]:
        return [
            payment
            for payment in self.repo.payments.values()
            if payment_matches_session(payment, session)
        ]

    def _find_vehicle_by_plate(self, plate_number: str) -> Vehicle | None:
        normalized = self._normalize_plate(plate_number)
        return next(
            (
                vehicle
                for vehicle in self.repo.vehicles.values()
                if self._normalize_plate(vehicle.plate_number) == normalized
            ),
            None,
        )

    def _find_active_session(self, lot_id: str, plate_number: str) -> ParkingSession | None:
        normalized = self._normalize_plate(plate_number)
        return next(
            (
                session
                for session in self.repo.parking_sessions.values()
                if session.lot_id == lot_id
                and self._normalize_plate(session.plate_number) == normalized
                and session.status == ParkingSessionStatus.active
            ),
            None,
        )

    def _auto_payment_method_name(self, user_id: str) -> str:
        method = next(
            (
                method
                for method in self.repo.payment_methods.values()
                if method.user_id == user_id
            ),
            None,
        )
        return method.method_name if method else "자동 결제"

    @staticmethod
    def _normalize_plate(plate_number: str) -> str:
        return normalize_plate(plate_number)

    @staticmethod
    def _duration_minutes(entry_at: datetime, exit_at: datetime) -> int:
        entry_at = ParkingService._as_aware_utc(entry_at)
        exit_at = ParkingService._as_aware_utc(exit_at)
        return max(0, int((exit_at - entry_at).total_seconds() // 60))

    @staticmethod
    def _as_aware_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)

    @staticmethod
    def _date_label(value: datetime) -> str:
        local_value = value.astimezone(UTC)
        return f"{local_value.year}.{local_value.month:02d}.{local_value.day:02d}"


parking_service = ParkingService()
