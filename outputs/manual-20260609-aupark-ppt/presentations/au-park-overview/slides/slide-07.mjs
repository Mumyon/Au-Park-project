import { C, arrowText, base, footer, label, metric, node, title } from "./shared.mjs";

export async function slide07(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx);
  title(slide, ctx, "FEE LOGIC", "사전정산 직후 미정산 금액은 0원이 되어야 함", "현황판은 총요금에서 이미 낸 금액을 뺀 outstanding_fee를 보여주고, 출차 시에는 남은 차액만 자동결제합니다.");
  metric(slide, ctx, 70, 220, 240, 104, "0원", "입차 후 30분 이내", { color: C.green });
  metric(slide, ctx, 340, 220, 240, 104, "1,500원", "31~60분 기본요금", { color: C.brand });
  metric(slide, ctx, 610, 220, 240, 104, "+500원", "61분부터 10분마다", { color: C.warn });
  metric(slide, ctx, 880, 220, 240, 104, "15,000원", "일일 최대 요금", { color: C.ink });
  node(slide, ctx, "현재 총요금\ncalculate_parking_fee", 92, 420, 220, 82, { fill: "#FFFFFF", line: C.brand, color: C.brand });
  arrowText(slide, ctx, "-", 327, 443, 40);
  node(slide, ctx, "사전정산 합계\nprepaid_amount", 384, 420, 220, 82, { fill: "#EDF9F6", line: C.green, color: C.green });
  arrowText(slide, ctx, "=", 619, 443, 40);
  node(slide, ctx, "현재 내야 할 돈\noutstanding_fee", 676, 420, 220, 82, { fill: "#FFF8E6", line: "#E7D39A", color: C.warn });
  label(slide, ctx, "예시: 61분 주차 총요금 2,000원 → 사전정산 2,000원 → 직후 미정산 0원 → 71분이 되면 추가 500원만 발생", 92, 548, 965, 52, {
    fontSize: 20,
    bold: true,
    color: C.ink,
  });
  label(slide, ctx, "이번 수정으로 결제 기록과 활성 세션을 공통 매칭 로직으로 연결해 번호판 공백 차이에도 정산 금액이 즉시 반영됩니다.", 92, 616, 1000, 32, {
    fontSize: 15,
    color: C.muted,
  });
  footer(slide, ctx, 7);
  return slide;
}
