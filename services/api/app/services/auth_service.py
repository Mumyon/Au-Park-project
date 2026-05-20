from fastapi import HTTPException, status

from app.schemas.auth import LoginRequest, SignUpRequest, TokenResponse
from app.schemas.user import User, UserUpdateRequest
from app.services.repository import InMemoryRepository, repository


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


auth_service = AuthService()
