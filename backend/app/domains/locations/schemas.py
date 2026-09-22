from datetime import datetime, timezone
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator


class LocationCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    squad_id: UUID
    latitude: Decimal = Field(ge=Decimal("-90"), le=Decimal("90"))
    longitude: Decimal = Field(ge=Decimal("-180"), le=Decimal("180"))
    accuracy_meters: Decimal | None = Field(default=None, ge=0)
    recorded_at: datetime

    @model_validator(mode="after")
    def recorded_at_is_reasonable(self):
        if self.recorded_at.tzinfo is None:
            raise ValueError("recorded_at debe incluir zona horaria")
        if self.recorded_at > datetime.now(timezone.utc):
            raise ValueError("recorded_at no puede estar en el futuro")
        return self


class LocationResponse(LocationCreateRequest):
    id: UUID
    user_id: UUID


class MeetingPointCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    squad_id: UUID
    title: str = Field(min_length=1, max_length=120)
    latitude: Decimal = Field(ge=Decimal("-90"), le=Decimal("90"))
    longitude: Decimal = Field(ge=Decimal("-180"), le=Decimal("180"))


class MeetingPointResponse(MeetingPointCreateRequest):
    id: UUID
    created_by_user_id: UUID
    created_at: datetime
