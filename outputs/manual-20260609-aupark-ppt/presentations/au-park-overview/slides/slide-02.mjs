import { C, base, bullets, card, footer, label, metric, title } from "./shared.mjs";

export async function slide02(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx);
  title(slide, ctx, "PROJECT THESIS", "사전정산 앱에서 자동 입출차 시스템으로 확장", "사용자가 앱에서 준비한 데이터가 카메라 인식 이벤트와 결합되면, 주차 과정은 자동으로 기록되고 정산됩니다.");
  card(slide, ctx, 56, 230, 350, 295, "기존 문제", "사전정산만 있으면 출차가 늦어졌을 때 추가요금 처리가 어색하고, 카메라 인식 결과가 앱 현황과 즉시 연결되지 않습니다.", ["수동 확인", "요금 불일치"]);
  card(slide, ctx, 464, 230, 350, 295, "개선 방향", "등록 차량이면 번호판 인식 시 입차 세션을 만들고, 다시 인식되면 이미 낸 금액을 뺀 차액만 자동정산합니다.", ["LPR auto", "차액 결제"], { fill: "#EDF9F6", line: "#CBE8E1" });
  card(slide, ctx, 872, 230, 350, 295, "발표 핵심", "앱, 서버, DB, 비전 워커가 어떤 책임을 갖고 통신하는지와 테스트/배포 흐름을 한 번에 설명합니다.", ["구조", "시연 흐름"]);
  metric(slide, ctx, 58, 555, 252, 84, "30분 무료", "기본 정책의 시작점", { color: C.green });
  metric(slide, ctx, 324, 555, 252, 84, "1,500원", "31~60분 기본요금", { color: C.brand });
  metric(slide, ctx, 590, 555, 252, 84, "500원", "이후 10분마다 추가", { color: C.warn });
  bullets(slide, ctx, ["사용자는 차량/카드 등록", "카메라는 번호판 이벤트 전송", "서버는 현재 세션과 결제 차액 계산"], 900, 558, 310, { gap: 28, fontSize: 13 });
  footer(slide, ctx, 2);
  return slide;
}
