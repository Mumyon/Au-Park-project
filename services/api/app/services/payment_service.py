from app.schemas.payment import Payment, PaymentMethodCreateRequest, PaymentRequest, PaymentStatus
from app.services.repository import InMemoryRepository, repository
from app.services.vehicle_service import vehicle_service


class PaymentService:
    def __init__(self, repo: InMemoryRepository = repository) -> None:
        self.repo = repo
        self.payment_methods: dict[str, list[PaymentMethodCreateRequest]] = {}

    def register_method(self, request: PaymentMethodCreateRequest) -> dict[str, str]:
        self.payment_methods.setdefault(request.user_id, []).append(request)
        return {"message": "Payment method registered"}

    def request_payment(self, request: PaymentRequest) -> Payment:
        vehicle_service.get(request.vehicle_id)
        payment = Payment(
            id=self.repo.next_id("payment"),
            user_id=request.user_id,
            vehicle_id=request.vehicle_id,
            amount=request.amount,
            description=request.description,
            status=PaymentStatus.paid,
        )
        self.repo.payments[payment.id] = payment
        return payment

    def list_by_user(self, user_id: str) -> list[Payment]:
        return [payment for payment in self.repo.payments.values() if payment.user_id == user_id]


payment_service = PaymentService()
