from pathlib import Path

from app.domains.festivals.schemas import ScheduleItemAdminRequest


ROOT = Path(__file__).resolve().parents[2]
MIGRATION = (ROOT / "database" / "010_phase12_clash_voting.sql").read_text(
    encoding="utf-8"
).lower()


def test_phase12_migration_creates_normalized_vote_and_decision_tables() -> None:
    assert "create table dbo.clash_votes" in MIGRATION
    assert "primary key (squad_id, schedule_item_id, user_id)" in MIGRATION
    assert "create table dbo.clash_decisions" in MIGRATION
    assert "primary key (squad_id, conflict_id)" in MIGRATION


def test_schedule_contract_normalizes_genres() -> None:
    payload = ScheduleItemAdminRequest(
        stage_id="00000000-0000-0000-0000-000000000001",
        artist_name="Artista",
        starts_at="2026-10-01T18:00:00Z",
        ends_at="2026-10-01T19:00:00Z",
        genres=[" Rock ", "rock", "INDIE"],
    )

    assert payload.genres == ["rock", "indie"]
