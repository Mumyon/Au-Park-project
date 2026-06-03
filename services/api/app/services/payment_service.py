from app.schemas.payment import Payment, PaymentMethodCreateRequest, PaymentRequest, PaymentStatus
from app.services.auth_service import auth_service
from app.services.repository import InMemoryRepository, repository
from app.services.vehicle_service import vehicle_service


class PaymentService:
    def __init__(self, repo: InMemoryRepository = repository) -> None:
        self.repo = repo

    def register_method(self, request: PaymentMethodCreateRequest) -> dict[str, str]:
        auth_service.get_user(request.user_id)
        method_id = self.repo.next_id("payment_method")
        self.repo.payment_methods[method_id] = request
        return {"message": "Payment method registered", "id": method_id}

    def request_payment(self, request: PaymentRequest) -> Payment:
        auth_service.get_user(request.user_id)
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
