from datetime import datetime, timedelta, timezone
from decimal import Decimal
from unittest.mock import MagicMock
from uuid import UUID

import pytest
from pydantic import ValidationError
from sqlalchemy.dialects import mssql
from sqlalchemy.orm import Session

from app.domains.locations.db_models import Location, MeetingPoint
from app.domains.locations.schemas import (
    LocationCreateRequest,
    MeetingPointCreateRequest,
)
from app.domains.locations.service import LocationService


SQUAD_ID = UUID(int=1)
USER_ID = UUID(int=2)


def location_payload():
    return {
        "squad_id": SQUAD_ID,
        "latitude": "19.400000",
        "longitude": "-99.090000",
        "recorded_at": datetime.now(timezone.utc) - timedelta(minutes=1),
    }


def test_location_identity_cannot_be_spoofed():
    with pytest.raises(ValidationError):
        LocationCreateRequest(**location_payload(), user_id=UUID(int=3))


@pytest.mark.parametrize(
    "change",
    [
        {"latitude": "90.000001"},
        {"longitude": "-180.000001"},
        {"accuracy_meters": "-1"},
        {"recorded_at": datetime.now(timezone.utc) + timedelta(days=1)},
        {"recorded_at": datetime.now().replace(tzinfo=None)},
    ],
)
def test_reject_invalid_location(change):
    with pytest.raises(ValidationError):
        LocationCreateRequest(**{**location_payload(), **change})


def test_latest_location_query_partitions_by_user():
    db = MagicMock(spec=Session)
    db.scalars.return_value.all.return_value = []
    LocationService().latest_for_squad(db, SQUAD_ID)
    compiled = str(
        db.scalars.call_args.args[0].compile(
            dialect=mssql.dialect(), compile_kwargs={"literal_binds": False}
        )
    ).lower()
    assert "row_number()" in compiled
    assert "partition by locations.user_id" in compiled
    assert "locations.squad_id" in compiled


def test_meeting_point_title_is_required():
    with pytest.raises(ValidationError):
        MeetingPointCreateRequest(
            squad_id=SQUAD_ID, title=" ", latitude="19.4", longitude="-99.09"
        )


def test_coordinates_use_exact_database_types():
    for model in (Location, MeetingPoint):
        assert model.__table__.c.latitude.type.asdecimal
        assert model.__table__.c.longitude.type.asdecimal
        assert model.__table__.c.latitude.type.precision == 9
        assert model.__table__.c.latitude.type.scale == 6
