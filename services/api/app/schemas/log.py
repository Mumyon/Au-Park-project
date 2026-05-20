from datetime import datetime
from enum import StrEnum

from pydantic import BaseModel


class EntryExitType(StrEnum):
    entry = "entry"
    exit = "exit"


class EntryExitLog(BaseModel):
    id: str
    lot_id: str
    plate_number: str
    event_type: EntryExitType
    occurred_at: datetime
