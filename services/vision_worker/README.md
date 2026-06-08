# Au-Park Vision Worker

This worker connects camera streams to the FastAPI server:

- TP-Link VIGI RTSP camera for entry/exit plate events.
- iPhone 13 Pro wide camera stream for parking slot occupancy.

The worker is intentionally separate from FastAPI. FastAPI stores users, vehicles,
parking sessions, and payments. This process only reads video and sends events.

## Install

```bash
cd /Users/jobyeongik/Documents/GitHub/Au-Park-project/services/vision_worker
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

For real plate OCR with EasyOCR:

```bash
.venv/bin/pip install -r requirements-ocr.txt
```

On macOS, EasyOCR model download can fail with a certificate error. If that
happens, run commands with `SSL_CERT_FILE` set to the `certifi` bundle:

```bash
export SSL_CERT_FILE="$(.venv/bin/python -c 'import certifi; print(certifi.where())')"
.venv/bin/python -c "from vision_worker.ocr import create_ocr_engine; create_ocr_engine('easyocr'); print('easyocr ready')"
```

## Camera Sources

Continuity Camera or a directly connected Mac camera can be used by numeric
OpenCV camera index:

```yaml
plate_camera:
  source: 0
```

Find the available indexes:

```bash
.venv/bin/python main.py scan-cameras --max-index 10
```

Save a test image from a camera index:

```bash
.venv/bin/python main.py snapshot --source 0 --output data/camera_0.jpg
.venv/bin/python main.py snapshot --source 1 --output data/camera_1.jpg
```

VIGI RTSP example:

```text
rtsp://username:password@CAMERA_IP:554/stream1
```

iPhone 13 Pro should be exposed as a normal HTTP MJPEG or RTSP stream. A simple
way for testing is to use an iPhone "IP camera" app and paste its `/video` URL
into `occupancy_camera.source`.

## Configure

```bash
cp config.example.yaml config.local.yaml
```

Then edit:

- `api.base_url`
- `plate_camera.source`
  - Use a number like `0` or `1` for Continuity Camera.
  - Keep the RTSP URL form for the VIGI camera later.
- `plate_camera.role`: `auto`, `entry`, or `exit`
  - `auto`: no active session means entry; an active session means exit.
- `occupancy_camera.source`
- `occupancy_camera.reference_image`
- `occupancy_camera.slots[*].polygon`

## Capture Empty Reference

Make sure every target parking slot is empty, then run:

```bash
.venv/bin/python main.py calibrate-occupancy --config config.local.yaml
```

This writes the empty reference image used by the OpenCV difference detector.

## Run

Test OCR on a saved plate/car image:

```bash
.venv/bin/python main.py test-plate-image --config config.local.yaml --image data/sample_plate.jpg
```

Plate camera only:

```bash
.venv/bin/python main.py plate --config config.local.yaml
```

Parking occupancy only:

```bash
.venv/bin/python main.py occupancy --config config.local.yaml
```

Both:

```bash
.venv/bin/python main.py all --config config.local.yaml
```

## OCR Note

The included plate pipeline finds license-plate-like image regions with OpenCV.
Text OCR is pluggable. `easyocr` is configured in `config.example.yaml` and works
as the first test model. It downloads OCR model files on first use. If accuracy is
not enough for your camera angle, replace the OpenCV candidate detector with a
Korean license-plate YOLO/ONNX detector and keep the same OCR/API pipeline.
