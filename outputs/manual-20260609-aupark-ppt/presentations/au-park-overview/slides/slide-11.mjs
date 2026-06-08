import { C, base, bullets, card, footer, label, title } from "./shared.mjs";

export async function slide11(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx);
  title(slide, ctx, "NEXT STEPS", "현재는 실험 가능한 골격, 다음은 운영 안정성", "지금 구조는 학습/테스트에 충분하고, 운영 단계에서는 결제 승인, 고정 도메인, 인식 모델, 관리자 화면을 보강하면 됩니다.");
  card(slide, ctx, 70, 232, 320, 140, "1. 실제 결제 승인", "현재는 서버 결제 내역 모델 중심입니다. PortOne 빌링키 결제 API를 서버에 연결하면 실제 자동 출금까지 이어집니다.", ["PortOne", "billing"]);
  card(slide, ctx, 430, 232, 320, 140, "2. 배포 안정화", "Quick Tunnel은 주소가 바뀝니다. named tunnel 또는 Cloud Run으로 고정 주소와 운영 환경을 만들 수 있습니다.", ["named tunnel", "Cloud Run"]);
  card(slide, ctx, 790, 232, 320, 140, "3. 번호판 인식 고도화", "EasyOCR 기반 테스트 이후 YOLO/ONNX 번호판 검출 모델로 정확도와 속도를 개선합니다.", ["YOLO", "ONNX"]);
  card(slide, ctx, 70, 420, 320, 140, "4. 주차면 인식", "빈 주차장 기준 이미지 또는 차량 검출 + 주차면 ROI 교차 판정 방식으로 확장합니다.", ["ROI", "occupancy"]);
  card(slide, ctx, 430, 420, 320, 140, "5. 관리자 대시보드", "apps/admin_dashboard 영역에 입출차 로그, 정산 내역, 주차면 상태 관리 화면을 구현합니다.", ["admin", "logs"]);
  label(slide, ctx, "발표 결론", 814, 432, 230, 28, { fontSize: 20, bold: true, color: C.brand });
  bullets(slide, ctx, ["앱은 사용자 경험", "서버는 신뢰 가능한 판단", "비전 워커는 현실 이벤트 입력", "DB는 상태의 단일 기준"], 814, 474, 320, { gap: 29, fontSize: 15, dot: C.green });
  footer(slide, ctx, 11);
  return slide;
}
