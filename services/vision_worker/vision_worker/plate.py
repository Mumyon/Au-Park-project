from __future__ import annotations

import time
from collections import Counter, deque
from pathlib import Path

import cv2
import numpy as np

from vision_worker.api_client import AuParkApiClient
from vision_worker.camera import VideoSource
from vision_worker.config import VisionConfig
from vision_worker.ocr import create_ocr_engine, normalize_plate_text


class PlateRecognitionWorker:
    def __init__(self, config: VisionConfig, source: VideoSource, api: AuParkApiClient) -> None:
        self.config = config
        self.source = source
        self.api = api
        self.ocr = create_ocr_engine(
            config.plate_camera.ocr.provider,
            max_image_width=config.plate_camera.ocr.max_image_width,
        )
        self.recent: deque[str] = deque(maxlen=max(3, config.plate_camera.min_repeat_count * 2))
        self.last_sent: dict[str, float] = {}
        self.auto_armed = True
        self.absent_frame_count = 0
        self.last_idle_log_at = 0.0
        self.crop_dir = Path(config.plate_camera.crop_output_dir)
        self.crop_dir.mkdir(parents=True, exist_ok=True)

    def run_forever(self) -> None:
        if not self.config.plate_camera.enabled:
            print("Plate camera is disabled.")
            return
        print(
            "Plate worker started: "
            f"source={self.config.plate_camera.source}, "
            f"role={self.config.plate_camera.role}, "
            f"interval={self.config.plate_camera.frame_interval_seconds}s, "
            f"repeat={self.config.plate_camera.min_repeat_count}, "
            f"roi_enabled={self.config.plate_camera.roi.enabled}"
        )
        for frame in self.source.frames(self.config.plate_camera.frame_interval_seconds):
            frame = self._apply_roi(frame)
            if (
                self.config.plate_camera.role == "auto"
                and not self.auto_armed
                and self._is_camera_covered(frame)
            ):
                self._rearm_auto_mode()
                continue
            plate_present = False
            candidates = self._find_plate_candidates(frame)
            if self.config.plate_camera.role == "auto" and not self.auto_armed:
                candidates = candidates[:1]
            for crop in candidates:
                if self._handle_candidate(crop):
                    plate_present = True
                    break
            self._update_auto_rearm(plate_present)
            if not plate_present:
                self._log_idle_status()

    def _handle_candidate(self, crop) -> bool:
        self._save_debug_crop(crop)
        result = self.ocr.read_text(crop)
        if result is None:
            return False
        if result.confidence < self.config.plate_camera.ocr.min_confidence:
            return False
        plate = normalize_plate_text(result.text, self.config.plate_camera.ocr.allowlist_regex)
        if plate is None:
            return False
        if self.config.plate_camera.role == "auto" and not self.auto_armed:
            return True
        self.recent.append(plate)
        winner, count = Counter(self.recent).most_common(1)[0]
        if count < self.config.plate_camera.min_repeat_count:
            return True
        if not self._can_send(winner):
            return True

        response = self.api.send_lpr_event(
            role=self.config.plate_camera.role,
            lot_id=self.config.lot.id,
            plate_number=winner,
        )
        self.last_sent[winner] = time.monotonic()
        if self.config.plate_camera.role == "auto":
            self.auto_armed = False
            self.absent_frame_count = 0
        print(
            f"LPR {self.config.plate_camera.role}: {winner} "
            f"(confidence={result.confidence:.2f}) -> {response.get('message')}"
        )
        return True

    def _update_auto_rearm(self, plate_present: bool) -> None:
        if self.config.plate_camera.role != "auto" or self.auto_armed:
            return
        if plate_present:
            self.absent_frame_count = 0
            return
        self.absent_frame_count += 1
        if (
            self.absent_frame_count
            >= self.config.plate_camera.auto_rearm_absent_frames
        ):
            self._rearm_auto_mode()

    def _rearm_auto_mode(self) -> None:
        self.auto_armed = True
        self.absent_frame_count = 0
        self.recent.clear()
        print("LPR auto mode rearmed. Ready for the next vehicle event.")

    def _log_idle_status(self) -> None:
        now = time.monotonic()
        if now - self.last_idle_log_at < 10:
            return
        self.last_idle_log_at = now
        print("No valid plate detected yet. Check camera source, ROI, focus, and lighting.")

    @staticmethod
    def _is_camera_covered(frame) -> bool:
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        return float(gray.mean()) < 30.0

    def read_plate_from_image(self, image_path: Path) -> str | None:
        frame = cv2.imread(str(image_path))
        if frame is None:
            raise RuntimeError(f"Cannot read image: {image_path}")
        frame = self._apply_roi(frame)
        best_plate = None
        best_confidence = 0.0
        candidates = self._find_plate_candidates(frame)
        print(f"Plate candidate crops: {len(candidates)}")
        for crop in candidates:
            self._save_debug_crop(crop)
            result = self.ocr.read_text(crop)
            if result is None or result.confidence < self.config.plate_camera.ocr.min_confidence:
                continue
            plate = normalize_plate_text(result.text, self.config.plate_camera.ocr.allowlist_regex)
            if plate is not None and result.confidence >= best_confidence:
                best_plate = plate
                best_confidence = result.confidence
        if best_plate:
            print(f"Detected plate: {best_plate} (confidence={best_confidence:.2f})")
        else:
            print("No plate detected.")
            print(f"Saved debug crops in: {self.crop_dir}")
        return best_plate

    def _can_send(self, plate: str) -> bool:
        if self.config.plate_camera.role == "auto":
            return self.auto_armed
        last_sent_at = self.last_sent.get(plate)
        if last_sent_at is None:
            return True
        return time.monotonic() - last_sent_at >= self.config.plate_camera.cooldown_seconds

    def _apply_roi(self, frame):
        roi = self.config.plate_camera.roi
        if not roi.enabled or not roi.polygon:
            return frame
        mask = np.zeros(frame.shape[:2], dtype=np.uint8)
        polygon = np.array(roi.polygon, dtype=np.int32)
        cv2.fillPoly(mask, [polygon], 255)
        masked = cv2.bitwise_and(frame, frame, mask=mask)
        x, y, w, h = cv2.boundingRect(polygon)
        return masked[y : y + h, x : x + w]

    def _find_plate_candidates(self, frame) -> list:
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gray = cv2.bilateralFilter(gray, 9, 75, 75)
        edges = cv2.Canny(gray, 80, 200)
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        contour_candidates = []
        frame_area = frame.shape[0] * frame.shape[1]
        for contour in contours:
            x, y, w, h = cv2.boundingRect(contour)
            if h == 0:
                continue
            ratio = w / h
            area = w * h
            if not 2.0 <= ratio <= 6.5:
                continue
            if not frame_area * 0.001 <= area <= frame_area * 0.08:
                continue
            crop = frame[max(0, y - 4) : y + h + 4, max(0, x - 4) : x + w + 4]
            if crop.size:
                contour_candidates.append((area, crop))
        contour_candidates.sort(key=lambda item: item[0], reverse=True)

        candidates = self._fallback_candidates(frame)
        candidates.extend(crop for _, crop in contour_candidates)
        return candidates[: self.config.plate_camera.max_candidate_count]

    def _fallback_candidates(self, frame) -> list:
        height, width = frame.shape[:2]
        regions = [
            (0, height // 8, width, height * 7 // 10),
            (0, height // 5, width, height * 2 // 3),
        ]
        crops = []
        for x1, y1, x2, y2 in regions:
            crop = frame[y1:y2, x1:x2]
            if crop.size:
                crops.append(crop)
        return crops

    def _save_debug_crop(self, crop) -> None:
        if not self.config.plate_camera.debug_save_crops:
            return
        filename = self.crop_dir / f"plate_{int(time.time() * 1000)}.jpg"
        cv2.imwrite(str(filename), crop)
