from datetime import datetime, timedelta, timezone
from uuid import UUID, uuid4

from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.settings import settings
from app.domains.auth.db_models import User
from app.domains.auth.schemas import AuthResponse, LoginRequest, RegisterRequest

password_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    def register(self, db: Session, payload: RegisterRequest) -> AuthResponse:
        normalized_email = payload.email.lower().strip()
        if self._by_email(db, normalized_email) is not None:
            raise ValueError("email_already_registered")

        user = User(
            id=uuid4(),
            name=payload.name.strip(),
            email=normalized_email,
            password_hash=password_context.hash(payload.password),
        )
        db.add(user)
        try:
            db.commit()
        except IntegrityError as exc:
            db.rollback()
            raise ValueError("email_already_registered") from exc
        return self._issue_session(str(user.id))

    def login(self, db: Session, payload: LoginRequest) -> AuthResponse:
        user = self._by_email(db, payload.email.lower().strip())
        if user is None or not password_context.verify(
            payload.password,
            user.password_hash,
        ):
            raise ValueError("invalid_credentials")
        return self._issue_session(str(user.id))

    def refresh(self, db: Session, refresh_token: str) -> AuthResponse:
        user_id = self._decode_subject(refresh_token, expected_type="refresh")
        if db.get(User, user_id) is None:
            raise ValueError("user_not_found")
        return self._issue_session(str(user_id))

    def authenticate(self, db: Session, access_token: str) -> User:
        user_id = self._decode_subject(access_token, expected_type="access")
        user = db.get(User, user_id)
        if user is None:
            raise ValueError("user_not_found")
        return user

    def _by_email(self, db: Session, email: str) -> User | None:
        return db.scalar(select(User).where(User.email == email))

    def _decode_subject(self, token: str, expected_type: str) -> UUID:
        claims = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
        if claims.get("type") != expected_type:
            raise ValueError("invalid_token_type")
        try:
            return UUID(str(claims["sub"]))
        except (KeyError, TypeError, ValueError) as exc:
            raise JWTError("invalid_subject") from exc

    def _issue_session(self, user_id: str) -> AuthResponse:
        return AuthResponse(
            user_id=user_id,
            access_token=self._create_token(
                user_id,
                "access",
                settings.access_token_expire_minutes,
            ),
            refresh_token=self._create_token(
                user_id,
                "refresh",
                settings.refresh_token_expire_minutes,
            ),
        )

    def _create_token(self, user_id: str, token_type: str, minutes: int) -> str:
        now = datetime.now(timezone.utc)
        payload = {
            "sub": user_id,
            "type": token_type,
            "iat": now,
            "exp": now + timedelta(minutes=minutes),
        }
        return jwt.encode(
            payload,
            settings.jwt_secret_key,
            algorithm=settings.jwt_algorithm,
        )


auth_service = AuthService()
