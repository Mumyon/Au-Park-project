import { C, base, card, footer, label, node, title } from "./shared.mjs";

export async function slide08(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx);
  title(slide, ctx, "MOBILE STATUS", "홈 현황판은 활성 주차 세션의 단일 상태를 따라감", "앱은 active session API를 주기적으로 조회하고, 차량번호·입차시간·요금 분해값을 SharedData에 반영합니다.");
  node(slide, ctx, "/api/v1/parking/sessions/active", 72, 245, 360, 74, { fill: "#0F1B2A", line: "#0F1B2A", color: "#FFFFFF", fontSize: 17 });
  label(slide, ctx, "서버 응답 필드", 72, 365, 240, 28, { fontSize: 18, bold: true });
  card(slide, ctx, 72, 410, 250, 122, "session", "차량번호, 입차시간, 상태, 세션 ID", ["plate", "entry_at"]);
  card(slide, ctx, 348, 410, 250, 122, "fee breakdown", "기본요금, 추가요금, 총요금", ["base", "additional"]);
  card(slide, ctx, 624, 410, 250, 122, "payment state", "정산완료 금액과 현재 미정산 금액", ["prepaid", "outstanding"], { fill: "#EDF9F6", line: "#CBE8E1" });
  card(slide, ctx, 900, 410, 250, 122, "screen state", "주차중 여부와 현황판 표시/해제", ["isParked", "history"]);
  label(slide, ctx, "입차", 524, 247, 90, 28, { fontSize: 15, bold: true, color: C.green, align: "center" });
  ctx.addShape(slide, { x: 544, y: 282, w: 3, h: 80, fill: C.green });
  label(slide, ctx, "정산", 650, 247, 90, 28, { fontSize: 15, bold: true, color: C.brand, align: "center" });
  ctx.addShape(slide, { x: 670, y: 282, w: 3, h: 80, fill: C.brand });
  label(slide, ctx, "출차", 776, 247, 90, 28, { fontSize: 15, bold: true, color: C.warn, align: "center" });
  ctx.addShape(slide, { x: 796, y: 282, w: 3, h: 80, fill: C.warn });
  label(slide, ctx, "앱 화면은 서버의 계산 결과를 표시하는 쪽에 집중하고, 요금/정산의 기준 판단은 FastAPI에 둡니다.", 72, 600, 985, 32, { fontSize: 18, color: C.ink });
  footer(slide, ctx, 8);
  return slide;
}
