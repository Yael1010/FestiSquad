from datetime import datetime, timedelta, timezone
from uuid import uuid4

from jose import jwt
from passlib.context import CryptContext

from app.core.settings import settings
from app.domains.auth.schemas import AuthResponse, LoginRequest, RegisterRequest

password_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    """In-memory service for the MVP bootstrap; replace with repository-backed storage."""

    def __init__(self) -> None:
        self._users_by_email: dict[str, dict[str, str]] = {}

    def register(self, payload: RegisterRequest) -> AuthResponse:
        normalized_email = payload.email.lower()
        if normalized_email in self._users_by_email:
            raise ValueError("email_already_registered")

        user_id = str(uuid4())
        self._users_by_email[normalized_email] = {
            "id": user_id,
            "name": payload.name,
            "email": normalized_email,
            "password_hash": password_context.hash(payload.password),
        }
        return self._issue_session(user_id)

    def login(self, payload: LoginRequest) -> AuthResponse:
        user = self._users_by_email.get(payload.email.lower())
        if user is None or not password_context.verify(payload.password, user["password_hash"]):
            raise ValueError("invalid_credentials")
        return self._issue_session(user["id"])

    def refresh(self, refresh_token: str) -> AuthResponse:
        claims = jwt.decode(
            refresh_token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
        if claims.get("type") != "refresh":
            raise ValueError("invalid_refresh_token")
        return self._issue_session(str(claims["sub"]))

    def _issue_session(self, user_id: str) -> AuthResponse:
        return AuthResponse(
            user_id=user_id,
            access_token=self._create_token(user_id, "access", settings.access_token_expire_minutes),
            refresh_token=self._create_token(user_id, "refresh", settings.refresh_token_expire_minutes),
        )

    def _create_token(self, user_id: str, token_type: str, minutes: int) -> str:
        now = datetime.now(timezone.utc)
        payload = {
            "sub": user_id,
            "type": token_type,
            "iat": now,
            "exp": now + timedelta(minutes=minutes),
        }
        return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


auth_service = AuthService()

