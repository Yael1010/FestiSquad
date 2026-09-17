from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class LocationCreateRequest(BaseModel):
    squad_id: str
    user_id: str
    latitude: Decimal = Field(ge=Decimal("-90"), le=Decimal("90"))
    longitude: Decimal = Field(ge=Decimal("-180"), le=Decimal("180"))
    accuracy_meters: Decimal | None = Field(default=None, ge=0)
    recorded_at: datetime


class LocationResponse(LocationCreateRequest):
    id: str

