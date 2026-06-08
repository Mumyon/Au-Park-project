import { C, base, footer, label, metric, pill } from "./shared.mjs";

export async function slide01(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx, { fill: C.surface });
  ctx.addShape(slide, { x: 0, y: 0, w: 470, h: 720, fill: C.brandDark });
  ctx.addShape(slide, { x: 470, y: 0, w: 120, h: 720, fill: C.brand });
  ctx.addShape(slide, { x: 590, y: 0, w: 46, h: 720, fill: C.green });
  await ctx.addImage(slide, {
    path: "/Users/jobyeongik/Documents/GitHub/Au-Park-project/app_icon_128.jpg",
    x: 64,
    y: 72,
    w: 86,
    h: 86,
    fit: "contain",
    alt: "Au-Park app icon",
  });
  label(slide, ctx, "Au-Park", 64, 196, 360, 70, {
    fontSize: 50,
    bold: true,
    color: "#FFFFFF",
  });
  label(slide, ctx, "스마트 주차 시스템 프로젝트 발표", 66, 270, 335, 32, {
    fontSize: 18,
    color: "rgba(255,255,255,0.86)",
  });
  label(slide, ctx, "Flutter 앱, FastAPI 서버, OpenCV 비전 워커를 연결해 차량 등록부터 번호판 인식 입출차와 자동정산까지 처리하는 테스트 가능한 시스템입니다.", 690, 94, 470, 118, {
    fontSize: 25,
    bold: true,
    color: C.ink,
  });
  metric(slide, ctx, 690, 268, 158, 105, "3", "핵심 구성\nApp / API / Vision", { color: C.brand });
  metric(slide, ctx, 868, 268, 158, 105, "13", "문서 섹션을\n발표 흐름으로 압축", { color: C.green });
  metric(slide, ctx, 1046, 268, 158, 105, "1", "현장 테스트 중심\nMacBook 서버", { color: C.warn });
  pill(slide, ctx, "Flutter", 690, 430, 92);
  pill(slide, ctx, "FastAPI", 792, 430, 94);
  pill(slide, ctx, "Firebase RTDB", 896, 430, 132);
  pill(slide, ctx, "OpenCV / EasyOCR", 1038, 430, 154, { fill: "#E5F4F0", color: C.green, line: "#CBE8E1" });
  label(slide, ctx, "작성일 2026-06-09 · Repository: Au-Park-project", 690, 622, 470, 28, {
    fontSize: 13,
    color: C.muted,
  });
  footer(slide, ctx, 1);
  return slide;
}
