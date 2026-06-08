from __future__ import annotations

import time
from pathlib import Path
from typing import Any

import cv2


class VideoSource:
    def __init__(self, source: str | int) -> None:
        self.source = self._normalize_source(source)
        self.capture: cv2.VideoCapture | None = None

    @staticmethod
    def _normalize_source(source: str | int) -> str | int:
        if isinstance(source, int):
            return source
        value = str(source).strip()
        if value.isdigit():
            return int(value)
        return value

    def open(self) -> None:
        self.close()
        self.capture = cv2.VideoCapture(self.source)
        if not self.capture.isOpened():
            raise RuntimeError(f"Cannot open video source: {self.source}")

    def read_frame(self):
        if self.capture is None or not self.capture.isOpened():
            self.open()

        assert self.capture is not None
        ok, frame = self.capture.read()
        if ok and frame is not None:
            return frame

        self.open()
        assert self.capture is not None
        ok, frame = self.capture.read()
        if not ok or frame is None:
            raise RuntimeError(f"Cannot read frame from source: {self.source}")
        return frame

    def frames(self, interval_seconds: float):
        while True:
            started_at = time.monotonic()
            try:
                yield self.read_frame()
            except RuntimeError as error:
                print(error)
                time.sleep(max(1.0, interval_seconds))
                continue
            elapsed = time.monotonic() - started_at
            time.sleep(max(0.0, interval_seconds - elapsed))

    def write_image(self, path: Path, frame) -> None:
        ok = cv2.imwrite(str(path), frame)
        if not ok:
            raise RuntimeError(f"Failed to write image: {path}")

    def close(self) -> None:
        if self.capture is not None:
            self.capture.release()
        self.capture = None


def scan_camera_indexes(max_index: int = 10) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    for index in range(max_index):
        capture = cv2.VideoCapture(index)
        opened = capture.isOpened()
        ok, frame = capture.read() if opened else (False, None)
        results.append(
            {
                "index": index,
                "opened": opened,
                "read": ok,
                "shape": None if frame is None else frame.shape,
            }
        )
        capture.release()
    return results
