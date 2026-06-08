import { C, base, footer, tableRow, title } from "./shared.mjs";

export async function slide04(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx);
  title(slide, ctx, "STACK", "개발 스택은 현장 테스트 가능한 조합으로 구성", "로컬 MacBook 서버와 실제 iPhone 앱, 카메라 워커를 빠르게 연결할 수 있는 기술을 선택했습니다.");
  const widths = [172, 430, 606];
  tableRow(slide, ctx, 220, ["영역", "기술", "역할"], widths, { fill: "#EDF3F9", bold: true, color: C.ink, h: 48 });
  tableRow(slide, ctx, 268, ["모바일 앱", "Flutter, Dart, Provider, SharedPreferences, http", "로그인, 차량 등록, 결제수단, 홈 현황판, 주차 내역 화면"], widths, { h: 58 });
  tableRow(slide, ctx, 326, ["소셜 인증", "google_sign_in, Kakao SDK, flutter_naver_login", "앱에서 토큰 획득 후 FastAPI 서버에서 검증"], widths, { h: 58 });
  tableRow(slide, ctx, 384, ["백엔드", "FastAPI, Uvicorn, Pydantic, httpx", "REST API, 인증, 주차 세션, 요금 계산, 결제 내역"], widths, { h: 58 });
  tableRow(slide, ctx, 442, ["저장소", "Firebase Realtime Database, InMemory Repository", "운영/테스트 데이터 저장, 환경변수 없을 때 인메모리 모드"], widths, { h: 58 });
  tableRow(slide, ctx, 500, ["비전 처리", "OpenCV, EasyOCR, NumPy, PyYAML", "카메라 프레임, 번호판 후보 검출, OCR, 주차면 감지"], widths, { h: 58 });
  tableRow(slide, ctx, 558, ["무선 테스트", "Cloudflare Tunnel", "MacBook 로컬 서버를 HTTPS 공개 주소로 임시 노출"], widths, { h: 58 });
  footer(slide, ctx, 4);
  return slide;
}
