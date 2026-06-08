import { C, arrowText, base, bullets, card, footer, label, node, title } from "./shared.mjs";

export async function slide05(presentation, ctx) {
  const slide = presentation.slides.add();
  base(slide, ctx);
  title(slide, ctx, "AUTH FLOW", "소셜 로그인은 앱이 토큰을 받고 서버가 검증", "FastAPI 서버는 구글/카카오/네이버가 발급한 토큰을 그대로 믿지 않고, 각 플랫폼 API를 통해 유효성을 확인합니다.");
  node(slide, ctx, "1\nFlutter 앱", 74, 255, 150, 95, { fill: "#FFFFFF", line: C.brand, color: C.brand });
  arrowText(slide, ctx, "SDK 토큰", 238, 287, 94);
  node(slide, ctx, "2\nGoogle ID Token\nKakao/Naver Access Token", 346, 245, 226, 116, { fill: "#F5F7FA", line: C.line, color: C.ink, fontSize: 14 });
  arrowText(slide, ctx, "/auth/social-login", 590, 287, 150);
  node(slide, ctx, "3\nFastAPI 서버", 758, 255, 170, 95, { fill: "#EDF3F9", line: C.brand, color: C.brand });
  arrowText(slide, ctx, "검증", 944, 287, 68);
  node(slide, ctx, "4\n플랫폼 API\n사용자 정보 확인", 1028, 255, 170, 95, { fill: "#EDF9F6", line: C.green, color: C.green });
  card(slide, ctx, 76, 430, 318, 138, "서버가 확인하는 것", "토큰 서명/만료/대상 앱/사용자 식별자. 유효하면 Au-Park 사용자 계정을 조회하거나 생성합니다.", ["검증", "조회/생성"]);
  card(slide, ctx, 432, 430, 318, 138, "DB에 남는 것", "Au-Park 사용자 ID, 이메일/이름 등 서비스에 필요한 최소 프로필과 차량/결제수단 연결 정보입니다.", ["users", "vehicles"]);
  card(slide, ctx, 788, 430, 318, 138, "앱이 받는 것", "서버 기준 사용자 정보와 이후 API 호출에 필요한 Au-Park 인증 상태입니다.", ["user_id", "session"]);
  bullets(slide, ctx, ["Google은 iOS/Android 클라이언트 ID가 같은 Google Cloud 프로젝트에 있어야 합니다.", "Kakao/Naver는 앱에서 받은 access token을 서버가 다시 플랫폼 API로 확인합니다."], 96, 605, 950, { gap: 28, fontSize: 14, dot: C.brand });
  footer(slide, ctx, 5);
  return slide;
}
