from app.schemas.log import EntryExitLog
from app.services.repository import InMemoryRepository, repository


class LogService:
    def __init__(self, repo: InMemoryRepository = repository) -> None:
        self.repo = repo

    def list_logs(self, plate_number: str | None = None) -> list[EntryExitLog]:
        logs = list(self.repo.entry_exit_logs.values())
        if plate_number is None:
            return logs
        return [log for log in logs if log.plate_number == plate_number]


log_service = LogService()
