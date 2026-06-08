import { C, arrowText, base, card, footer, node, title } from "./shared.mjs";

export async function slide09(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx);
  title(slide, ctx, "VISION WORKER", "지금은 iPhone 카메라로 테스트하고, 나중에 RTSP 카메라로 교체 가능", "OpenCV로 프레임을 읽고 EasyOCR로 번호판을 읽은 뒤, 반복 확인과 재무장 로직으로 중복 이벤트를 줄입니다.");
  node(slide, ctx, "Camera source\nsource: 0", 76, 250, 180, 82, { fill: "#FFFFFF", line: C.line });
  arrowText(slide, ctx, "0.5초", 270, 275, 78);
  node(slide, ctx, "Frame capture\nOpenCV", 362, 250, 180, 82, { fill: "#FFFFFF", line: C.brand, color: C.brand });
  arrowText(slide, ctx, "ROI", 556, 275, 64);
  node(slide, ctx, "Plate crop\ncandidate", 634, 250, 180, 82, { fill: "#FFFFFF", line: C.green, color: C.green });
  arrowText(slide, ctx, "OCR", 828, 275, 64);
  node(slide, ctx, "EasyOCR\n2회 반복 확인", 906, 250, 200, 82, { fill: "#EDF9F6", line: C.green, color: C.green });
  card(slide, ctx, 84, 412, 310, 150, "현재 테스트 환경", "iPhone Continuity Camera를 카메라 source 0으로 사용합니다. 맥북 내장 카메라와 헷갈릴 때 scan-cameras로 확인합니다.", ["source 0", "Continuity"]);
  card(slide, ctx, 434, 412, 310, 150, "운영 전환", "TP-Link VIGI 같은 IP 카메라는 RTSP URL을 config.local.yaml에 넣어 교체할 수 있습니다.", ["RTSP", "LAN"]);
  card(slide, ctx, 784, 412, 310, 150, "정확도 개선", "EasyOCR 테스트 후 운영 단계에서는 번호판 전용 YOLO/ONNX 검출 모델을 붙이는 방향이 좋습니다.", ["YOLO", "ONNX"], { fill: "#FFF8E6", line: "#E7D39A" });
  footer(slide, ctx, 9);
  return slide;
}
