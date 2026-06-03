from fastapi import HTTPException, status

from app.schemas.auth import LoginRequest, SignUpRequest, SocialLoginRequest, TokenResponse
from app.schemas.user import User, UserUpdateRequest
from app.services.repository import InMemoryRepository, repository
from app.services.social_auth_service import SocialProfile, social_auth_service


class AuthService:
    def __init__(self, repo: InMemoryRepository = repository) -> None:
        self.repo = repo

    def sign_up(self, request: SignUpRequest) -> User:
        if any(user.email == request.email for user in self.repo.users.values()):
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")

        user = User(
            id=self.repo.next_id("user"),
            email=request.email,
            name=request.name,
            phone=request.phone,
        )
        self.repo.users[user.id] = user
        self.repo.user_passwords[user.id] = request.password
        return user

    def login(self, request: LoginRequest) -> TokenResponse:
        for user_id, user in self.repo.users.items():
            if user.email == request.email and self.repo.user_passwords.get(user_id) == request.password:
                return TokenResponse(access_token=f"dev-token-{user.id}", user_id=user.id)

        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    def social_login(self, request: SocialLoginRequest) -> TokenResponse:
        profile = social_auth_service.verify(request.provider, request.token)
        user = self._find_social_user(profile) or self._find_user_by_email(profile.email)

        if user is None:
            user = User(
                id=self.repo.next_id("user"),
                email=profile.email,
                name=profile.name,
                auth_provider=profile.provider.value,
                provider_user_id=profile.provider_user_id,
            )
        else:
            user = user.model_copy(
                update={
                    "name": user.name or profile.name,
                    "auth_provider": profile.provider.value,
                    "provider_user_id": profile.provider_user_id,
                }
            )

        self.repo.users[user.id] = user
        return TokenResponse(access_token=f"dev-token-{user.id}", user_id=user.id)

    def get_user(self, user_id: str) -> User:
        user = self.repo.users.get(user_id)
        if user is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        return user

    def update_user(self, user_id: str, request: UserUpdateRequest) -> User:
        user = self.get_user(user_id)
        updated = user.model_copy(update=request.model_dump(exclude_none=True))
        self.repo.users[user_id] = updated
        return updated

    def _find_user_by_email(self, email: str) -> User | None:
        for user in self.repo.users.values():
            if user.email == email:
                return user
        return None

    def _find_social_user(self, profile: SocialProfile) -> User | None:
        for user in self.repo.users.values():
            if user.auth_provider == profile.provider.value and user.provider_user_id == profile.provider_user_id:
                return user
        return None


auth_service = AuthService()
