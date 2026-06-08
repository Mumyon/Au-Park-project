from __future__ import annotations

import re
from dataclasses import dataclass

import cv2


@dataclass(frozen=True)
class OcrResult:
    text: str
    confidence: float


class OcrEngine:
    def read_text(self, image) -> OcrResult | None:
        raise NotImplementedError


class NoopOcrEngine(OcrEngine):
    def read_text(self, image) -> OcrResult | None:
        return None


class EasyOcrEngine(OcrEngine):
    def __init__(self, max_image_width: int = 900) -> None:
        try:
            import easyocr
        except ImportError as exc:
            raise RuntimeError("Install easyocr to use provider=easyocr") from exc
        self.max_image_width = max_image_width
        self.reader = easyocr.Reader(["ko", "en"], gpu=False)

    def read_text(self, image) -> OcrResult | None:
        candidates: list[OcrResult] = []
        for variant in preprocess_for_ocr(image, self.max_image_width):
            results = self.reader.readtext(variant, detail=1, paragraph=False)
            for item in results:
                candidates.append(OcrResult(text=str(item[1]), confidence=float(item[2])))
        if not candidates:
            return None
        combined_text = " ".join(item.text for item in candidates)
        best_confidence = max(item.confidence for item in candidates)
        return OcrResult(text=combined_text, confidence=best_confidence)


class TesseractOcrEngine(OcrEngine):
    def __init__(self) -> None:
        try:
            import pytesseract
        except ImportError as exc:
            raise RuntimeError("Install pytesseract and tesseract binary to use provider=tesseract") from exc
        self.pytesseract = pytesseract

    def read_text(self, image) -> OcrResult | None:
        text = self.pytesseract.image_to_string(image, lang="kor+eng")
        clean = " ".join(text.split())
        if not clean:
            return None
        return OcrResult(text=clean, confidence=0.5)


def create_ocr_engine(provider: str, max_image_width: int = 900) -> OcrEngine:
    if provider == "noop":
        return NoopOcrEngine()
    if provider == "easyocr":
        return EasyOcrEngine(max_image_width=max_image_width)
    if provider == "tesseract":
        return TesseractOcrEngine()
    raise ValueError(f"Unsupported OCR provider: {provider}")


def preprocess_for_ocr(image, max_image_width: int = 900) -> list:
    prepared = add_margin(resize_for_ocr(image, max_image_width))
    gray = cv2.cvtColor(prepared, cv2.COLOR_BGR2GRAY)
    denoised = cv2.bilateralFilter(gray, 7, 50, 50)
    return [denoised]


def resize_for_ocr(image, max_image_width: int):
    height, width = image.shape[:2]
    if width <= 0 or height <= 0:
        return image
    if width > max_image_width:
        scale = max_image_width / width
        return cv2.resize(image, None, fx=scale, fy=scale, interpolation=cv2.INTER_AREA)
    if width < 320:
        scale = 320 / width
        return cv2.resize(image, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)
    return image


def add_margin(image, ratio: float = 0.06):
    height, width = image.shape[:2]
    x_margin = max(16, int(width * ratio))
    y_margin = max(8, int(height * ratio))
    return cv2.copyMakeBorder(
        image,
        y_margin,
        y_margin,
        x_margin,
        x_margin,
        cv2.BORDER_CONSTANT,
        value=(255, 255, 255),
    )


def normalize_plate_text(text: str, allowlist_regex: str) -> str | None:
    compact = re.sub(r"[^0-9A-Za-z가-힣]", "", text).upper()
    match = re.search(allowlist_regex, compact)
    if match:
        return match.group(0)
    return None
