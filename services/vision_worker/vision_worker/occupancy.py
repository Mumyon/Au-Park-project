from __future__ import annotations

import time

import cv2
import numpy as np

from vision_worker.api_client import AuParkApiClient
from vision_worker.camera import VideoSource
from vision_worker.config import SlotRoiConfig, VisionConfig


class OccupancyWorker:
    def __init__(self, config: VisionConfig, source: VideoSource, api: AuParkApiClient) -> None:
        self.config = config
        self.source = source
        self.api = api
        self.reference = cv2.imread(config.occupancy_camera.reference_image)
        if self.reference is None:
            raise RuntimeError(
                "Missing occupancy reference image. Run calibrate-occupancy first."
            )
        self.last_reported: dict[str, str] = {}
        self.pending: dict[str, tuple[str, float]] = {}

    def run_forever(self) -> None:
        if not self.config.occupancy_camera.enabled:
            print("Occupancy camera is disabled.")
            return
        for frame in self.source.frames(self.config.occupancy_camera.frame_interval_seconds):
            statuses = self._detect_statuses(frame)
            stable_changes = self._stable_changes(statuses)
            if stable_changes:
                response = self.api.update_slot_statuses(self.config.lot.id, stable_changes)
                self.last_reported.update(stable_changes)
                print(f"Updated slots: {stable_changes} ({len(response)} rows)")

    def _detect_statuses(self, frame) -> dict[str, str]:
        frame = self._resize_like_reference(frame)
        statuses: dict[str, str] = {}
        for slot in self.config.occupancy_camera.slots:
            score = self._slot_change_score(frame, slot)
            statuses[slot.slot_id] = (
                "occupied"
                if score >= self.config.occupancy_camera.change_threshold
                else "empty"
            )
        return statuses

    def _resize_like_reference(self, frame):
        if frame.shape[:2] == self.reference.shape[:2]:
            return frame
        width = self.reference.shape[1]
        height = self.reference.shape[0]
        return cv2.resize(frame, (width, height))

    def _slot_change_score(self, frame, slot: SlotRoiConfig) -> float:
        mask = np.zeros(self.reference.shape[:2], dtype=np.uint8)
        polygon = np.array(slot.polygon, dtype=np.int32)
        cv2.fillPoly(mask, [polygon], 255)

        current_gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        reference_gray = cv2.cvtColor(self.reference, cv2.COLOR_BGR2GRAY)
        diff = cv2.absdiff(current_gray, reference_gray)
        masked = diff[mask == 255]
        if masked.size == 0:
            return 0.0
        return float(np.mean(masked))

    def _stable_changes(self, statuses: dict[str, str]) -> dict[str, str]:
        now = time.monotonic()
        changes: dict[str, str] = {}
        for slot_id, status in statuses.items():
            if self.last_reported.get(slot_id) == status:
                self.pending.pop(slot_id, None)
                continue

            pending_status, pending_since = self.pending.get(slot_id, (status, now))
            if pending_status != status:
                self.pending[slot_id] = (status, now)
                continue
            if now - pending_since >= self.config.occupancy_camera.min_state_seconds:
                changes[slot_id] = status
                self.pending.pop(slot_id, None)
        return changes

