from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[2]
INITIAL_SCHEMA = (ROOT / "database" / "001_initial_schema.sql").read_text(
    encoding="utf-8"
).lower()
PHASE3_MIGRATION = (
    ROOT / "database" / "003_phase3_normalization_and_indexes.sql"
).read_text(encoding="utf-8").lower()


def test_schedule_genres_are_normalized():
    assert "genres_csv" not in INITIAL_SCHEMA
    assert "create table genres" in INITIAL_SCHEMA
    assert "create table schedule_item_genres" in INITIAL_SCHEMA


def test_schedule_does_not_duplicate_festival_dependency():
    schedule_block = INITIAL_SCHEMA.split("create table schedule_items", 1)[1]
    schedule_block = schedule_block.split("create table schedule_item_genres", 1)[0]
    assert "festival_id" not in schedule_block
    assert "stage_id" in schedule_block


def test_money_columns_use_exact_decimal_types():
    for column in ("amount", "share_amount"):
        assert re.search(rf"{column}\s+decimal\(18,2\)", INITIAL_SCHEMA)
    assert not re.search(r"\b(float|real)\b", INITIAL_SCHEMA)


def test_phase3_migration_contains_required_query_indexes():
    required_indexes = {
        "ix_locations_squad_user_recorded",
        "ix_expenses_squad_created",
        "ix_schedule_items_stage_time",
        "ix_squad_members_user",
        "ix_meeting_points_squad_created",
    }
    assert required_indexes.issubset(set(re.findall(r"ix_[a-z_]+", PHASE3_MIGRATION)))


def test_phase3_migration_is_transactional_and_repeatable():
    assert "set xact_abort on" in PHASE3_MIGRATION
    assert "begin transaction" in PHASE3_MIGRATION
    assert "commit transaction" in PHASE3_MIGRATION
    assert "if not exists" in PHASE3_MIGRATION
