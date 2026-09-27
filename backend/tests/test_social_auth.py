from datetime import timedelta
from unittest.mock import MagicMock
from urllib.parse import parse_qs, urlparse
from uuid import UUID

import pytest
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.core.settings import Settings, settings
from app.domains.auth.db_models import ExternalAccount, SocialAuthFlow, User
from app.domains.auth.social_service import (
    SocialAuthError,
    SocialAuthService,
    SocialProfile,
    utcnow,
)


def configure_google(monkeypatch) -> None:
    monkeypatch.setattr(settings, "google_client_id", "google-client")
    monkeypatch.setattr(settings, "google_client_secret", "google-secret")
    monkeypatch.setattr(
        settings,
        "google_redirect_uri",
        "http://127.0.0.1:8000/api/v1/auth/social/google/callback",
    )


def test_google_credentials_must_be_configured_together():
    with pytest.raises(ValidationError):
        Settings(
            _env_file=None,
            google_client_id="client-id",
            google_client_secret="",
        )


def test_start_creates_hashed_one_time_flow_and_signed_state(monkeypatch):
    configure_google(monkeypatch)
    db = MagicMock(spec=Session)

    result = SocialAuthService().start(db, "google")

    flow = db.add.call_args.args[0]
    query = parse_qs(urlparse(result.authorization_url).query)
    assert isinstance(flow, SocialAuthFlow)
    assert flow.flow_token_hash != result.flow_token
    assert len(flow.flow_token_hash) == 64
    assert query["state"][0]
    assert query["scope"] == ["openid email profile"]
    assert query["redirect_uri"] == [settings.google_redirect_uri]
    db.commit.assert_called_once()


def test_pending_flow_does_not_issue_tokens():
    flow = SocialAuthFlow(
        id=UUID("00000000-0000-0000-0000-000000000001"),
        provider="google",
        flow_token_hash=SocialAuthService._hash("x" * 48),
        status="pending",
        expires_at=utcnow() + timedelta(minutes=5),
    )
    db = MagicMock(spec=Session)
    db.scalar.return_value = flow

    result = SocialAuthService().consume(db, "x" * 48)

    assert result.status == "pending"
    assert result.session is None
    db.commit.assert_not_called()


def test_consumed_flow_cannot_be_reused():
    flow = SocialAuthFlow(
        id=UUID("00000000-0000-0000-0000-000000000001"),
        provider="spotify",
        flow_token_hash=SocialAuthService._hash("x" * 48),
        status="consumed",
        expires_at=utcnow() + timedelta(minutes=5),
    )
    db = MagicMock(spec=Session)
    db.scalar.return_value = flow

    with pytest.raises(SocialAuthError, match="flow_not_found"):
        SocialAuthService().consume(db, "x" * 48)


def test_invalid_state_is_rejected_before_provider_request():
    db = MagicMock(spec=Session)

    with pytest.raises(SocialAuthError, match="invalid_oauth_state"):
        SocialAuthService()._flow_from_state(db, "google", "not-a-jwt")


def test_verified_google_email_can_link_existing_local_user():
    user = User(
        id=UUID("00000000-0000-0000-0000-000000000002"),
        name="Yael",
        email="yael@example.com",
        password_hash="hash",
    )
    db = MagicMock(spec=Session)
    db.scalar.side_effect = [None, user]
    profile = SocialProfile(
        provider_user_id="google-user",
        email="yael@example.com",
        name="Yael",
        avatar_url=None,
        email_verified=True,
    )

    result = SocialAuthService()._resolve_user(db, "google", profile, None)

    assert result is user
    assert isinstance(db.add.call_args.args[0], ExternalAccount)


def test_spotify_never_links_an_existing_email_implicitly():
    user = User(
        id=UUID("00000000-0000-0000-0000-000000000002"),
        name="Yael",
        email="yael@example.com",
        password_hash="hash",
    )
    db = MagicMock(spec=Session)
    db.scalar.side_effect = [None, user]
    profile = SocialProfile(
        provider_user_id="spotify-user",
        email="yael@example.com",
        name="Yael",
        avatar_url=None,
        email_verified=False,
    )

    with pytest.raises(SocialAuthError, match="email_requires_account_link"):
        SocialAuthService()._resolve_user(db, "spotify", profile, None)
