from fastapi import HTTPException, status

from app.schemas.vehicle import Vehicle, VehicleCreateRequest, VehicleUpdateRequest
from app.services.auth_service import auth_service
from app.services.repository import InMemoryRepository, repository


class VehicleService:
    def __init__(self, repo: InMemoryRepository = repository) -> None:
        self.repo = repo

    def list_by_user(self, user_id: str) -> list[Vehicle]:
        auth_service.get_user(user_id)
        return [vehicle for vehicle in self.repo.vehicles.values() if vehicle.user_id == user_id]

    def create(self, request: VehicleCreateRequest) -> Vehicle:
        auth_service.get_user(request.user_id)
        vehicle = Vehicle(id=self.repo.next_id("vehicle"), **request.model_dump())
        self.repo.vehicles[vehicle.id] = vehicle
        return vehicle

    def update(self, vehicle_id: str, request: VehicleUpdateRequest) -> Vehicle:
        vehicle = self.get(vehicle_id)
        updated = vehicle.model_copy(update=request.model_dump(exclude_none=True))
        self.repo.vehicles[vehicle_id] = updated
        return updated

    def delete(self, vehicle_id: str) -> None:
        self.get(vehicle_id)
        del self.repo.vehicles[vehicle_id]

    def get(self, vehicle_id: str) -> Vehicle:
        vehicle = self.repo.vehicles.get(vehicle_id)
        if vehicle is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vehicle not found")
        return vehicle


vehicle_service = VehicleService()
