from fastapi import APIRouter

from app.schemas.log import EntryExitLog
from app.services.log_service import log_service


router = APIRouter()


@router.get("", response_model=list[EntryExitLog])
async def list_logs(plate_number: str | None = None) -> list[EntryExitLog]:
    return log_service.list_logs(plate_number)
