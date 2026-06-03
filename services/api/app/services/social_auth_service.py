from dataclasses import dataclass

import httpx
from fastapi import HTTPException, status

from app.core.config import settings
from app.schemas.auth import SocialAuthProvider


@dataclass(frozen=True)
class SocialProfile:
    provider: SocialAuthProvider
    provider_user_id: str
    email: str
    name: str


class SocialAuthService:
    def verify(self, provider: SocialAuthProvider, token: str) -> SocialProfile:
        if provider == SocialAuthProvider.google:
            return self._verify_google(token)
        if provider == SocialAuthProvider.kakao:
            return self._verify_kakao(token)
        if provider == SocialAuthProvider.naver:
            return self._verify_naver(token)

        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unsupported auth provider")

    def _verify_google(self, id_token: str) -> SocialProfile:
        try:
            from google.auth.transport import requests
            from google.oauth2 import id_token as google_id_token
        except ImportError as exc:
            raise RuntimeError("google-auth is required for Google social login") from exc

        audiences = self._google_audiences()
        request = requests.Request()
        payload = None

        try:
            if audiences:
                for audience in audiences:
                    try:
                        payload = google_id_token.verify_oauth2_token(id_token, request, audience)
                        break
                    except ValueError:
                        continue
                if payload is None:
                    raise ValueError("Invalid Google token audience")
            else:
                payload = google_id_token.verify_oauth2_token(id_token, request)
        except ValueError as exc:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Google token") from exc

        email = payload.get("email")
        subject = payload.get("sub")
        if not email or not subject:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Google profile is incomplete")

        return SocialProfile(
            provider=SocialAuthProvider.google,
            provider_user_id=subject,
            email=email,
            name=payload.get("name") or email.split("@", 1)[0],
        )

    def _verify_kakao(self, access_token: str) -> SocialProfile:
        data = self._get_json(
            "https://kapi.kakao.com/v2/user/me",
            access_token,
            "Invalid Kakao token",
        )
        kakao_account = data.get("kakao_account") or {}
        profile = kakao_account.get("profile") or {}
        provider_user_id = str(data.get("id") or "")
        email = kakao_account.get("email") or f"kakao-{provider_user_id}@social.au-park.local"
        name = profile.get("nickname") or email.split("@", 1)[0]

        if not provider_user_id:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Kakao profile is incomplete")

        return SocialProfile(SocialAuthProvider.kakao, provider_user_id, email, name)

    def _verify_naver(self, access_token: str) -> SocialProfile:
        data = self._get_json(
            "https://openapi.naver.com/v1/nid/me",
            access_token,
            "Invalid Naver token",
        )
        response = data.get("response") or {}
        provider_user_id = str(response.get("id") or "")
        email = response.get("email") or f"naver-{provider_user_id}@social.au-park.local"
        name = response.get("name") or response.get("nickname") or email.split("@", 1)[0]

        if not provider_user_id:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Naver profile is incomplete")

        return SocialProfile(SocialAuthProvider.naver, provider_user_id, email, name)

    @staticmethod
    def _get_json(url: str, access_token: str, error_detail: str) -> dict:
        try:
            response = httpx.get(
                url,
                headers={"Authorization": f"Bearer {access_token}"},
                timeout=10,
            )
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=error_detail) from exc

        if response.status_code >= 400:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=error_detail)
        return response.json()

    @staticmethod
    def _google_audiences() -> list[str]:
        if not settings.google_oauth_client_ids:
            return []
        return [
            client_id.strip()
            for client_id in settings.google_oauth_client_ids.split(",")
            if client_id.strip()
        ]


social_auth_service = SocialAuthService()
