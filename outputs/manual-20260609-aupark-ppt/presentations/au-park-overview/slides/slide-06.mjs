import { C, arrowText, base, footer, label, node, title } from "./shared.mjs";

export async function slide06(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx);
  title(slide, ctx, "LPR AUTO", "번호판을 한 번 보면 입차, 다시 보면 출차로 판단", "Vision Worker는 번호판 문자열을 서버에 보내고, 서버가 활성 세션 존재 여부로 입출차를 결정합니다.");
  node(slide, ctx, "카메라 프레임\nContinuity Camera / RTSP", 70, 260, 210, 92, { fill: "#FFFFFF", line: C.line });
  arrowText(slide, ctx, "OpenCV", 294, 292, 92);
  node(slide, ctx, "번호판 후보 검출\nROI · crop · OCR", 402, 248, 210, 116, { fill: "#FFFFFF", line: C.green, color: C.green });
  arrowText(slide, ctx, "반복 2회", 628, 292, 94);
  node(slide, ctx, "plate_number\nlot_id", 738, 260, 162, 92, { fill: "#F5F7FA", line: C.line });
  arrowText(slide, ctx, "/lpr/auto", 916, 292, 100);
  node(slide, ctx, "FastAPI 판정", 1034, 260, 170, 92, { fill: "#EDF3F9", line: C.brand, color: C.brand });
  label(slide, ctx, "서버 내부 판정", 92, 430, 270, 28, { fontSize: 19, bold: true, color: C.ink });
  node(slide, ctx, "활성 세션 없음\n→ 입차 세션 생성", 92, 474, 270, 100, { fill: "#EDF9F6", line: C.green, color: C.green });
  node(slide, ctx, "활성 세션 있음\n→ 출차 처리", 390, 474, 270, 100, { fill: "#FFF8E6", line: "#E7D39A", color: C.warn });
  node(slide, ctx, "사전정산 있음\n→ 차액만 결제", 688, 474, 270, 100, { fill: "#FFFFFF", line: C.brand, color: C.brand });
  node(slide, ctx, "세션 완료\n→ 홈 현황판 제거", 986, 474, 210, 100, { fill: "#FFFFFF", line: C.line, color: C.ink });
  label(slide, ctx, "재인식 준비 로그: LPR auto mode rearmed. Ready for the next vehicle event.", 94, 622, 920, 30, { fontSize: 15, color: C.muted });
  footer(slide, ctx, 6);
  return slide;
}
