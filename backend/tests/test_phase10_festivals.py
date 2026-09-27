from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.domains.auth.db_models import User
from app.domains.auth.dependencies import get_platform_admin
from app.domains.festivals.schemas import FestivalCreateRequest, GeoJsonPolygon


def polygon() -> dict:
    return {
        "type": "Polygon",
        "coordinates": [
            [
                [-99.18, 19.40],
                [-99.17, 19.40],
                [-99.17, 19.39],
                [-99.18, 19.40],
            ]
        ],
    }


def test_geojson_polygon_requires_closed_ring():
    value = polygon()
    value["coordinates"][0][-1] = [-99.16, 19.39]

    with pytest.raises(ValidationError, match="primera y última"):
        GeoJsonPolygon.model_validate(value)


def test_geojson_polygon_rejects_out_of_range_coordinates():
    value = polygon()
    value["coordinates"][0][1] = [-199.17, 19.40]

    with pytest.raises(ValidationError, match="fuera de rango"):
        GeoJsonPolygon.model_validate(value)


def test_festival_end_must_be_after_start():
    starts_at = datetime.now(timezone.utc) + timedelta(days=30)

    with pytest.raises(ValidationError, match="fecha final"):
        FestivalCreateRequest(
            name="Festival de prueba",
            venue_name="Recinto principal",
            city="Ciudad de México",
            starts_at=starts_at,
            ends_at=starts_at,
            boundary=polygon(),
        )


def test_platform_admin_dependency_rejects_regular_user():
    user = User(
        name="Usuario",
        email="user@example.com",
        password_hash="unused",
        is_platform_admin=False,
    )

    with pytest.raises(HTTPException) as error:
        get_platform_admin(user)

    assert error.value.status_code == 403


def test_platform_admin_dependency_accepts_admin():
    user = User(
        name="Admin",
        email="admin@example.com",
        password_hash="unused",
        is_platform_admin=True,
    )

    assert get_platform_admin(user) is user
