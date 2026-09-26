from datetime import datetime, timedelta, timezone

import pytest
import httpx
from pydantic import ValidationError

from app.core.settings import Settings
from app.domains.clash_resolver.schemas import ConcertOption, RecommendationRequest
from app.domains.clash_resolver.service import ClashResolverService, group_conflicts
from app.domains.clash_resolver.spotify_service import SpotifyOAuthService


def test_manual_preferences_work_without_spotify() -> None:
    service = ClashResolverService()
    now = datetime.now(timezone.utc)
    later = now + timedelta(hours=1)
    result = service.recommend(
        RecommendationRequest(
            squad_id="squad-1",
            manual_genres=["indie", "rock"],
            options=[
                ConcertOption(artist="DJ Norte", stage="A", starts_at=now, ends_at=later, genres=["edm"]),
                ConcertOption(artist="Las Luces", stage="B", starts_at=now, ends_at=later, genres=["indie"]),
            ],
        )
    )

    assert result.selected_artist == "Las Luces"
    assert result.matched_genres == ["indie"]
    assert "indie" in result.reason


def test_artist_match_has_priority_and_explains_result() -> None:
    service = ClashResolverService()
    now = datetime.now(timezone.utc)
    later = now + timedelta(hours=1)
    result = service.recommend(
        RecommendationRequest(
            squad_id="squad-1",
            favorite_artists=["Artista B"],
            options=[
                ConcertOption(artist="Artista A", stage="A", starts_at=now, ends_at=later),
                ConcertOption(artist="Artista B", stage="B", starts_at=now, ends_at=later),
            ],
        )
    )
    assert result.selected_artist == "Artista B"
    assert result.matched_artist


def test_invalid_concert_interval_is_rejected() -> None:
    now = datetime.now(timezone.utc)
    with pytest.raises(ValidationError):
        ConcertOption(artist="A", stage="A", starts_at=now, ends_at=now)


def test_conflicts_keep_only_maximal_simultaneous_groups() -> None:
    now = datetime.now(timezone.utc)
    options = [
        ConcertOption(id="00000000-0000-0000-0000-000000000001", artist="A", stage="1",
                      starts_at=now, ends_at=now + timedelta(minutes=60)),
        ConcertOption(id="00000000-0000-0000-0000-000000000002", artist="B", stage="2",
                      starts_at=now + timedelta(minutes=10), ends_at=now + timedelta(minutes=70)),
        ConcertOption(id="00000000-0000-0000-0000-000000000003", artist="C", stage="3",
                      starts_at=now + timedelta(minutes=20), ends_at=now + timedelta(minutes=50)),
    ]

    groups = group_conflicts(options)

    assert len(groups) == 1
    assert {option.artist for option in groups[0].options} == {"A", "B", "C"}


def test_spotify_credentials_must_be_configured_together() -> None:
    with pytest.raises(ValidationError):
        Settings(
            _env_file=None,
            spotify_client_id="client-id",
            spotify_client_secret="",
        )


def test_spotify_403_explains_development_mode_requirements() -> None:
    service = SpotifyOAuthService(ClashResolverService())
    response = httpx.Response(
        403,
        json={"error": {"status": 403, "reason": "FORBIDDEN"}},
        request=httpx.Request("GET", service.top_artists_url),
    )

    error = service._provider_error("artists", response)

    assert "Users Management" in str(error)
    assert "Premium" in str(error)
