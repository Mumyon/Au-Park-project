from __future__ import annotations

import httpx

from vision_worker.config import ApiConfig


class AuParkApiClient:
    def __init__(self, base_url: str, timeout_seconds: float) -> None:
        self.base_url = base_url.rstrip("/")
        self.client = httpx.Client(timeout=timeout_seconds)

    @classmethod
    def from_config(cls, config: ApiConfig) -> "AuParkApiClient":
        return cls(base_url=config.base_url, timeout_seconds=config.timeout_seconds)

    def send_lpr_event(self, role: str, lot_id: str, plate_number: str) -> dict:
        if role not in {"auto", "entry", "exit"}:
            raise ValueError("plate_camera.role must be auto, entry or exit")
        response = self.client.post(
            f"{self.base_url}/lpr/{role}",
            json={"lot_id": lot_id, "plate_number": plate_number},
        )
        response.raise_for_status()
        return response.json()

    def update_slot_statuses(self, lot_id: str, statuses: dict[str, str]) -> list[dict]:
        if not statuses:
            return []
        response = self.client.patch(
            f"{self.base_url}/parking/lots/{lot_id}/slots/statuses",
            json={
                "slots": [
                    {"slot_id": slot_id, "status": status}
                    for slot_id, status in statuses.items()
                ]
            },
        )
        response.raise_for_status()
        return response.json()
