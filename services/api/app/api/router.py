from fastapi import APIRouter

from app.api.auth.routes import router as auth_router
from app.api.lpr.routes import router as lpr_router
from app.api.logs.routes import router as log_router
from app.api.parking.routes import router as parking_router
from app.api.payments.routes import router as payment_router
from app.api.users.routes import router as user_router
from app.api.vehicles.routes import router as vehicle_router


api_router = APIRouter()
api_router.include_router(auth_router, prefix="/auth", tags=["auth"])
api_router.include_router(user_router, prefix="/users", tags=["users"])
api_router.include_router(vehicle_router, prefix="/vehicles", tags=["vehicles"])
api_router.include_router(parking_router, prefix="/parking", tags=["parking"])
api_router.include_router(payment_router, prefix="/payments", tags=["payments"])
api_router.include_router(log_router, prefix="/logs", tags=["logs"])
api_router.include_router(lpr_router, prefix="/lpr", tags=["lpr"])
