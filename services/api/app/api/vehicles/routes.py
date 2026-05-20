from fastapi import APIRouter, Response, status

from app.schemas.vehicle import Vehicle, VehicleCreateRequest, VehicleUpdateRequest
from app.services.vehicle_service import vehicle_service


router = APIRouter()


@router.get("", response_model=list[Vehicle])
async def list_vehicles(user_id: str) -> list[Vehicle]:
    return vehicle_service.list_by_user(user_id)


@router.post("", response_model=Vehicle, status_code=201)
async def create_vehicle(request: VehicleCreateRequest) -> Vehicle:
    return vehicle_service.create(request)


@router.get("/{vehicle_id}", response_model=Vehicle)
async def get_vehicle(vehicle_id: str) -> Vehicle:
    return vehicle_service.get(vehicle_id)


@router.patch("/{vehicle_id}", response_model=Vehicle)
async def update_vehicle(vehicle_id: str, request: VehicleUpdateRequest) -> Vehicle:
    return vehicle_service.update(vehicle_id, request)


@router.delete("/{vehicle_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_vehicle(vehicle_id: str) -> Response:
    vehicle_service.delete(vehicle_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
