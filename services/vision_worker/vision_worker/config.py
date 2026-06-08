from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml


@dataclass(frozen=True)
class ApiConfig:
    base_url: str
    timeout_seconds: float = 10


@dataclass(frozen=True)
class LotConfig:
    id: str


@dataclass(frozen=True)
class PolygonRoiConfig:
    enabled: bool
    polygon: list[list[int]]


@dataclass(frozen=True)
class OcrConfig:
    provider: str
    allowlist_regex: str
    min_confidence: float
    max_image_width: int


@dataclass(frozen=True)
class PlateCameraConfig:
    enabled: bool
    role: str
    source: str
    frame_interval_seconds: float
    min_repeat_count: int
    cooldown_seconds: float
    crop_output_dir: str
    debug_save_crops: bool
    max_candidate_count: int
    auto_rearm_absent_frames: int
    roi: PolygonRoiConfig
    ocr: OcrConfig


@dataclass(frozen=True)
class SlotRoiConfig:
    slot_id: str
    polygon: list[list[int]]


@dataclass(frozen=True)
class OccupancyCameraConfig:
    enabled: bool
    source: str
    frame_interval_seconds: float
    reference_image: str
    change_threshold: float
    min_state_seconds: float
    slots: list[SlotRoiConfig]


@dataclass(frozen=True)
class VisionConfig:
    api: ApiConfig
    lot: LotConfig
    plate_camera: PlateCameraConfig
    occupancy_camera: OccupancyCameraConfig


def load_config(path: Path) -> VisionConfig:
    with path.open("r", encoding="utf-8") as file:
        data = yaml.safe_load(file) or {}

    return VisionConfig(
        api=ApiConfig(**data["api"]),
        lot=LotConfig(**data["lot"]),
        plate_camera=_plate_config(data["plate_camera"]),
        occupancy_camera=_occupancy_config(data["occupancy_camera"]),
    )


def _plate_config(data: dict[str, Any]) -> PlateCameraConfig:
    roi = data.get("roi") or {}
    ocr = data.get("ocr") or {}
    return PlateCameraConfig(
        enabled=bool(data.get("enabled", True)),
        role=str(data.get("role", "entry")),
        source=str(data["source"]),
        frame_interval_seconds=float(data.get("frame_interval_seconds", 1)),
        min_repeat_count=int(data.get("min_repeat_count", 3)),
        cooldown_seconds=float(data.get("cooldown_seconds", 30)),
        crop_output_dir=str(data.get("crop_output_dir", "data/plate_crops")),
        debug_save_crops=bool(data.get("debug_save_crops", False)),
        max_candidate_count=int(data.get("max_candidate_count", 3)),
        auto_rearm_absent_frames=max(
            1,
            int(data.get("auto_rearm_absent_frames", 1)),
        ),
        roi=PolygonRoiConfig(
            enabled=bool(roi.get("enabled", False)),
            polygon=roi.get("polygon") or [],
        ),
        ocr=OcrConfig(
            provider=str(ocr.get("provider", "noop")),
            allowlist_regex=str(ocr.get("allowlist_regex", r"[0-9]{2,3}[가-힣][0-9]{4}")),
            min_confidence=float(ocr.get("min_confidence", 0.35)),
            max_image_width=int(ocr.get("max_image_width", 900)),
        ),
    )


def _occupancy_config(data: dict[str, Any]) -> OccupancyCameraConfig:
    slots = [
        SlotRoiConfig(slot_id=str(item["slot_id"]), polygon=item["polygon"])
        for item in data.get("slots", [])
    ]
    return OccupancyCameraConfig(
        enabled=bool(data.get("enabled", True)),
        source=str(data["source"]),
        frame_interval_seconds=float(data.get("frame_interval_seconds", 2)),
        reference_image=str(data["reference_image"]),
        change_threshold=float(data.get("change_threshold", 28)),
        min_state_seconds=float(data.get("min_state_seconds", 6)),
        slots=slots,
    )
