from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, HttpUrl, model_validator


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class GeoJsonPolygon(StrictModel):
    type: Literal["Polygon"]
    coordinates: list[list[tuple[float, float]]]

    @model_validator(mode="after")
    def validate_polygon(self):
        if len(self.coordinates) != 1:
            raise ValueError("Solo se admiten polígonos simples sin huecos.")
        ring = self.coordinates[0]
        if len(ring) < 4:
            raise ValueError("El polígono requiere al menos cuatro coordenadas.")
        if ring[0] != ring[-1]:
            raise ValueError("La primera y última coordenada deben coincidir.")
        for longitude, latitude in ring:
            if not -180 <= longitude <= 180 or not -90 <= latitude <= 90:
                raise ValueError("Las coordenadas GeoJSON están fuera de rango.")
        return self


class StageCreateRequest(StrictModel):
    name: str = Field(min_length=1, max_length=120)
    polygon: GeoJsonPolygon


class StageUpdateRequest(StrictModel):
    name: str | None = Field(default=None, min_length=1, max_length=120)
    polygon: GeoJsonPolygon | None = None


class ScheduleItemCreateRequest(StrictModel):
    stage_name: str = Field(min_length=1, max_length=120)
    artist_name: str = Field(min_length=1, max_length=160)
    starts_at: datetime
    ends_at: datetime
    genres: list[str] = Field(default_factory=list, max_length=12)

    @model_validator(mode="after")
    def validate_dates(self):
        if self.ends_at <= self.starts_at:
            raise ValueError("El horario debe terminar después de comenzar.")
        self.genres = list(
            dict.fromkeys(
                " ".join(value.strip().split()).casefold()
                for value in self.genres
                if value.strip()
            )
        )
        return self


class ScheduleItemAdminRequest(StrictModel):
    stage_id: str
    artist_name: str = Field(min_length=1, max_length=160)
    starts_at: datetime
    ends_at: datetime
    genres: list[str] = Field(default_factory=list, max_length=12)

    @model_validator(mode="after")
    def validate_dates(self):
        if self.ends_at <= self.starts_at:
            raise ValueError("El horario debe terminar después de comenzar.")
        self.genres = list(
            dict.fromkeys(
                " ".join(value.strip().split()).casefold()
                for value in self.genres
                if value.strip()
            )
        )
        return self


class FestivalCreateRequest(StrictModel):
    name: str = Field(min_length=2, max_length=160)
    venue_name: str = Field(min_length=2, max_length=160)
    city: str = Field(min_length=2, max_length=120)
    country_code: str = Field(default="MX", pattern=r"^[A-Z]{2}$")
    timezone: str = Field(default="America/Mexico_City", min_length=3, max_length=64)
    starts_at: datetime
    ends_at: datetime
    boundary: GeoJsonPolygon
    image_url: HttpUrl | None = None
    official_url: HttpUrl | None = None
    status: Literal["draft", "published"] = "draft"
    stages: list[StageCreateRequest] = Field(default_factory=list, max_length=50)
    schedule: list[ScheduleItemCreateRequest] = Field(
        default_factory=list, max_length=500
    )

    @model_validator(mode="after")
    def validate_dates(self):
        if self.ends_at <= self.starts_at:
            raise ValueError("La fecha final debe ser posterior a la inicial.")
        return self


class FestivalUpdateRequest(StrictModel):
    name: str | None = Field(default=None, min_length=2, max_length=160)
    venue_name: str | None = Field(default=None, min_length=2, max_length=160)
    city: str | None = Field(default=None, min_length=2, max_length=120)
    country_code: str | None = Field(default=None, pattern=r"^[A-Z]{2}$")
    timezone: str | None = Field(default=None, min_length=3, max_length=64)
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    boundary: GeoJsonPolygon | None = None
    image_url: HttpUrl | None = None
    official_url: HttpUrl | None = None
    status: Literal["draft", "published", "archived"] | None = None


class FestivalSummaryResponse(BaseModel):
    id: str
    name: str
    venue_name: str
    city: str
    country_code: str
    timezone: str
    starts_at: datetime
    ends_at: datetime
    image_url: str | None
    official_url: str | None
    status: str
    stage_count: int


class StageResponse(BaseModel):
    id: str
    name: str
    polygon: dict


class ScheduleItemResponse(BaseModel):
    id: str
    stage_id: str
    stage_name: str
    artist_name: str
    starts_at: datetime
    ends_at: datetime
    genres: list[str]


class FestivalDetailResponse(FestivalSummaryResponse):
    boundary: dict
    stages: list[StageResponse]


class FestivalAdminAccessResponse(BaseModel):
    is_admin: bool
