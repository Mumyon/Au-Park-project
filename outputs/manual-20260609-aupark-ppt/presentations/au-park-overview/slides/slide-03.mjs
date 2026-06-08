import { C, arrowText, base, footer, label, node, title } from "./shared.mjs";

export async function slide03(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx);
  title(slide, ctx, "SYSTEM MAP", "전체 아키텍처는 앱, 서버, 저장소, 비전 워커의 역할 분리", "Flutter는 사용자 경험, FastAPI는 비즈니스 판단, Firebase는 저장, Vision Worker는 카메라 이벤트를 담당합니다.");
  node(slide, ctx, "Flutter 모바일 앱\n로그인 · 차량 등록 · 결제수단 · 홈 현황", 70, 245, 230, 120, { fill: "#FFFFFF", line: C.brand, color: C.brand });
  arrowText(slide, ctx, "REST", 320, 290, 72);
  node(slide, ctx, "FastAPI 서버\n인증 · 세션 · 요금 · 결제 · LPR 판정", 414, 230, 250, 150, { fill: "#EDF3F9", line: C.brand, color: C.ink });
  arrowText(slide, ctx, "저장", 684, 290, 72);
  node(slide, ctx, "Firebase RTDB\nusers · vehicles · parking_sessions · payments", 778, 245, 240, 120, { fill: "#FFFFFF", line: C.green, color: C.green });
  node(slide, ctx, "Vision Worker\nOpenCV · EasyOCR · 카메라 프레임", 244, 475, 270, 110, { fill: "#FFFFFF", line: C.green, color: C.green });
  arrowText(slide, ctx, "/lpr/auto", 544, 511, 116);
  node(slide, ctx, "입출차 이벤트\n활성 세션 없음: 입차\n활성 세션 있음: 출차", 690, 462, 260, 136, { fill: "#FFF8E6", line: "#E7D39A", color: C.warn });
  label(slide, ctx, "핵심 판단은 서버가 수행합니다. 앱과 비전 워커는 토큰/번호판/사용자 입력을 전달하고, 서버가 DB 기준으로 신뢰 가능한 결과를 만듭니다.", 72, 620, 1080, 42, {
    fontSize: 17,
    color: C.ink,
  });
  footer(slide, ctx, 3);
  return slide;
}
