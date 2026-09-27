from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from hashlib import sha256
import secrets
from typing import Literal
from urllib.parse import urlencode
from uuid import UUID, uuid4

import httpx
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.settings import settings
from app.domains.auth.db_models import ExternalAccount, SocialAuthFlow, User
from app.domains.auth.schemas import (
    SocialAuthorizationResponse,
    SocialSessionResponse,
)
from app.domains.auth.service import auth_service, password_context

SocialProvider = Literal["google", "spotify"]


class SocialAuthError(RuntimeError):
    pass


@dataclass(frozen=True)
class SocialProfile:
    provider_user_id: str
    email: str
    name: str
    avatar_url: str | None
    email_verified: bool


def utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


class SocialAuthService:
    flow_lifetime = timedelta(minutes=10)

    def start(
        self,
        db: Session,
        provider: SocialProvider,
        requested_user_id: UUID | None = None,
    ) -> SocialAuthorizationResponse:
        self._require_configuration(provider)
        flow_token = secrets.token_urlsafe(48)
        flow = SocialAuthFlow(
            id=uuid4(),
            provider=provider,
            flow_token_hash=self._hash(flow_token),
            status="pending",
            requested_user_id=requested_user_id,
            expires_at=utcnow() + self.flow_lifetime,
        )
        db.add(flow)
        db.commit()

        state = jwt.encode(
            {
                "sub": str(flow.id),
                "type": "social_oauth",
                "provider": provider,
                "iat": datetime.now(timezone.utc),
                "exp": datetime.now(timezone.utc) + self.flow_lifetime,
            },
            settings.jwt_secret_key,
            algorithm=settings.jwt_algorithm,
        )
        return SocialAuthorizationResponse(
            provider=provider,
            authorization_url=self._authorization_url(provider, state),
            flow_token=flow_token,
            expires_in_seconds=int(self.flow_lifetime.total_seconds()),
        )

    async def complete(
        self,
        db: Session,
        provider: SocialProvider,
        state: str,
        code: str | None,
        oauth_error: str | None,
    ) -> None:
        flow = self._flow_from_state(db, provider, state)
        if flow.status != "pending" or flow.expires_at <= utcnow():
            raise SocialAuthError("flow_expired_or_used")
        if oauth_error or not code:
            self._fail(db, flow, "authorization_denied")
            raise SocialAuthError("authorization_denied")

        try:
            profile = await self._profile(provider, code)
            user = self._resolve_user(db, provider, profile, flow.requested_user_id)
            flow.user_id = user.id
            flow.status = "completed"
            db.commit()
        except SocialAuthError as exc:
            self._fail(db, flow, str(exc))
            raise
        except (httpx.HTTPError, KeyError, TypeError, ValueError) as exc:
            self._fail(db, flow, "provider_unavailable")
            raise SocialAuthError("provider_unavailable") from exc

    def consume(self, db: Session, flow_token: str) -> SocialSessionResponse:
        flow = db.scalar(
            select(SocialAuthFlow).where(
                SocialAuthFlow.flow_token_hash == self._hash(flow_token)
            )
        )
        if flow is None or flow.status == "consumed":
            raise SocialAuthError("flow_not_found")
        if flow.expires_at <= utcnow():
            flow.status = "failed"
            flow.error_code = "flow_expired"
            db.commit()
        if flow.status == "pending":
            return SocialSessionResponse(status="pending")
        if flow.status == "failed":
            return SocialSessionResponse(status="failed", error=flow.error_code)
        if flow.user_id is None:
            raise SocialAuthError("invalid_flow_state")

        session = auth_service.issue_session(flow.user_id)
        flow.status = "consumed"
        flow.consumed_at = utcnow()
        db.commit()
        return SocialSessionResponse(status="completed", session=session)

    def _authorization_url(self, provider: SocialProvider, state: str) -> str:
        if provider == "google":
            query = urlencode(
                {
                    "client_id": settings.google_client_id,
                    "redirect_uri": settings.google_redirect_uri,
                    "response_type": "code",
                    "scope": "openid email profile",
                    "state": state,
                    "prompt": "select_account",
                }
            )
            return f"https://accounts.google.com/o/oauth2/v2/auth?{query}"

        query = urlencode(
            {
                "client_id": settings.spotify_client_id,
                "redirect_uri": settings.spotify_login_redirect_uri,
                "response_type": "code",
                "scope": "user-read-email user-read-private",
                "state": state,
            }
        )
        return f"https://accounts.spotify.com/authorize?{query}"

    async def _profile(self, provider: SocialProvider, code: str) -> SocialProfile:
        if provider == "google":
            return await self._google_profile(code)
        return await self._spotify_profile(code)

    async def _google_profile(self, code: str) -> SocialProfile:
        async with httpx.AsyncClient(timeout=10.0) as client:
            token_response = await client.post(
                "https://oauth2.googleapis.com/token",
                data={
                    "client_id": settings.google_client_id,
                    "client_secret": settings.google_client_secret,
                    "code": code,
                    "grant_type": "authorization_code",
                    "redirect_uri": settings.google_redirect_uri,
                },
            )
            token_response.raise_for_status()
            access_token = token_response.json()["access_token"]
            profile_response = await client.get(
                "https://openidconnect.googleapis.com/v1/userinfo",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            profile_response.raise_for_status()
            data = profile_response.json()

        if not data.get("email") or not data.get("sub"):
            raise SocialAuthError("provider_profile_incomplete")
        return SocialProfile(
            provider_user_id=str(data["sub"]),
            email=str(data["email"]).lower().strip(),
            name=str(data.get("name") or data["email"].split("@", 1)[0]),
            avatar_url=data.get("picture"),
            email_verified=bool(data.get("email_verified")),
        )

    async def _spotify_profile(self, code: str) -> SocialProfile:
        async with httpx.AsyncClient(timeout=10.0) as client:
            token_response = await client.post(
                "https://accounts.spotify.com/api/token",
                data={
                    "code": code,
                    "grant_type": "authorization_code",
                    "redirect_uri": settings.spotify_login_redirect_uri,
                },
                auth=(settings.spotify_client_id, settings.spotify_client_secret),
            )
            token_response.raise_for_status()
            access_token = token_response.json()["access_token"]
            profile_response = await client.get(
                "https://api.spotify.com/v1/me",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            profile_response.raise_for_status()
            data = profile_response.json()

        if not data.get("email") or not data.get("id"):
            raise SocialAuthError("provider_profile_incomplete")
        images = data.get("images") or []
        return SocialProfile(
            provider_user_id=str(data["id"]),
            email=str(data["email"]).lower().strip(),
            name=str(data.get("display_name") or data["email"].split("@", 1)[0]),
            avatar_url=images[0].get("url") if images else None,
            email_verified=False,
        )

    def _resolve_user(
        self,
        db: Session,
        provider: SocialProvider,
        profile: SocialProfile,
        requested_user_id: UUID | None,
    ) -> User:
        account = db.scalar(
            select(ExternalAccount).where(
                ExternalAccount.provider == provider,
                ExternalAccount.provider_user_id == profile.provider_user_id,
            )
        )
        if account is not None:
            if requested_user_id is not None and account.user_id != requested_user_id:
                raise SocialAuthError("provider_already_linked")
            user = db.get(User, account.user_id)
            if user is None:
                raise SocialAuthError("linked_user_not_found")
            return user

        if requested_user_id is not None:
            user = db.get(User, requested_user_id)
            if user is None:
                raise SocialAuthError("user_not_found")
            existing_provider = db.scalar(
                select(ExternalAccount).where(
                    ExternalAccount.user_id == requested_user_id,
                    ExternalAccount.provider == provider,
                )
            )
            if existing_provider is not None:
                raise SocialAuthError("provider_already_linked")
        else:
            user = db.scalar(select(User).where(User.email == profile.email))
            if user is not None and not (
                provider == "google" and profile.email_verified
            ):
                raise SocialAuthError("email_requires_account_link")
            if user is None:
                user = User(
                    id=uuid4(),
                    name=profile.name[:120],
                    email=profile.email,
                    password_hash=password_context.hash(secrets.token_urlsafe(32)),
                )
                db.add(user)
                db.flush()

        db.add(
            ExternalAccount(
                id=uuid4(),
                user_id=user.id,
                provider=provider,
                provider_user_id=profile.provider_user_id,
                provider_email=profile.email,
                avatar_url=profile.avatar_url,
            )
        )
        return user

    def _flow_from_state(
        self,
        db: Session,
        provider: SocialProvider,
        state: str,
    ) -> SocialAuthFlow:
        try:
            claims = jwt.decode(
                state,
                settings.jwt_secret_key,
                algorithms=[settings.jwt_algorithm],
            )
            if claims.get("type") != "social_oauth" or claims.get("provider") != provider:
                raise SocialAuthError("invalid_oauth_state")
            flow_id = UUID(str(claims["sub"]))
        except (JWTError, KeyError, TypeError, ValueError) as exc:
            raise SocialAuthError("invalid_oauth_state") from exc
        flow = db.get(SocialAuthFlow, flow_id)
        if flow is None or flow.provider != provider:
            raise SocialAuthError("invalid_oauth_state")
        return flow

    def _require_configuration(self, provider: SocialProvider) -> None:
        configured = (
            settings.google_client_id and settings.google_client_secret
            if provider == "google"
            else settings.spotify_client_id and settings.spotify_client_secret
        )
        if not configured:
            raise SocialAuthError("provider_not_configured")

    @staticmethod
    def _hash(value: str) -> str:
        return sha256(value.encode("utf-8")).hexdigest()

    @staticmethod
    def _fail(db: Session, flow: SocialAuthFlow, error_code: str) -> None:
        flow.status = "failed"
        flow.error_code = error_code[:80]
        db.commit()


social_auth_service = SocialAuthService()
