from datetime import datetime, timezone

from app.domains.clash_resolver.schemas import ConcertOption, RecommendationRequest
from app.domains.clash_resolver.service import ClashResolverService


def test_manual_preferences_work_without_spotify() -> None:
    service = ClashResolverService()
    now = datetime.now(timezone.utc)
    result = service.recommend(
        RecommendationRequest(
            squad_id="squad-1",
            manual_genres=["indie", "rock"],
            options=[
                ConcertOption(artist="DJ Norte", stage="A", starts_at=now, ends_at=now, genres=["edm"]),
                ConcertOption(artist="Las Luces", stage="B", starts_at=now, ends_at=now, genres=["indie"]),
            ],
        )
    )

    assert result.selected_artist == "Las Luces"
    assert "manual" in result.reason

