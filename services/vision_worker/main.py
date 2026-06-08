from __future__ import annotations

import argparse
import threading
from pathlib import Path

from vision_worker.api_client import AuParkApiClient
from vision_worker.camera import VideoSource, scan_camera_indexes
from vision_worker.config import load_config
from vision_worker.occupancy import OccupancyWorker
from vision_worker.plate import PlateRecognitionWorker


def run_plate(config_path: Path) -> None:
    config = load_config(config_path)
    api = AuParkApiClient.from_config(config.api)
    source = VideoSource(config.plate_camera.source)
    worker = PlateRecognitionWorker(config=config, source=source, api=api)
    worker.run_forever()


def run_occupancy(config_path: Path) -> None:
    config = load_config(config_path)
    api = AuParkApiClient.from_config(config.api)
    source = VideoSource(config.occupancy_camera.source)
    worker = OccupancyWorker(config=config, source=source, api=api)
    worker.run_forever()


def run_all(config_path: Path) -> None:
    plate_thread = threading.Thread(target=run_plate, args=(config_path,), daemon=True)
    occupancy_thread = threading.Thread(target=run_occupancy, args=(config_path,), daemon=True)
    plate_thread.start()
    occupancy_thread.start()
    plate_thread.join()
    occupancy_thread.join()


def test_plate_image(config_path: Path, image_path: Path) -> None:
    config = load_config(config_path)
    api = AuParkApiClient.from_config(config.api)
    source = VideoSource(config.plate_camera.source)
    worker = PlateRecognitionWorker(config=config, source=source, api=api)
    worker.read_plate_from_image(image_path)


def calibrate_occupancy(config_path: Path) -> None:
    config = load_config(config_path)
    source = VideoSource(config.occupancy_camera.source)
    frame = source.read_frame()
    reference_path = Path(config.occupancy_camera.reference_image)
    reference_path.parent.mkdir(parents=True, exist_ok=True)
    source.write_image(reference_path, frame)
    print(f"Saved empty occupancy reference: {reference_path}")


def scan_cameras(max_index: int) -> None:
    for result in scan_camera_indexes(max_index):
        print(
            f"{result['index']}: opened={result['opened']} "
            f"read={result['read']} shape={result['shape']}"
        )


def snapshot_camera(source_value: str, output_path: Path) -> None:
    source = VideoSource(source_value)
    frame = source.read_frame()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    source.write_image(output_path, frame)
    source.close()
    print(f"Saved camera snapshot: {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Au-Park camera vision worker")
    parser.add_argument(
        "mode",
        choices=[
            "plate",
            "occupancy",
            "all",
            "calibrate-occupancy",
            "test-plate-image",
            "scan-cameras",
            "snapshot",
        ],
    )
    parser.add_argument("--config", default="config.local.yaml")
    parser.add_argument("--image")
    parser.add_argument("--max-index", type=int, default=10)
    parser.add_argument("--source", default="0")
    parser.add_argument("--output", default="data/camera_snapshot.jpg")
    args = parser.parse_args()
    config_path = Path(args.config)

    if args.mode == "scan-cameras":
        scan_cameras(args.max_index)
    elif args.mode == "snapshot":
        snapshot_camera(args.source, Path(args.output))
    elif args.mode == "plate":
        run_plate(config_path)
    elif args.mode == "occupancy":
        run_occupancy(config_path)
    elif args.mode == "all":
        run_all(config_path)
    elif args.mode == "calibrate-occupancy":
        calibrate_occupancy(config_path)
    elif args.mode == "test-plate-image":
        if not args.image:
            raise SystemExit("--image is required for test-plate-image")
        test_plate_image(config_path, Path(args.image))


if __name__ == "__main__":
    main()
