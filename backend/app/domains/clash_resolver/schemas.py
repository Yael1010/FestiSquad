from datetime import datetime

from pydantic import BaseModel, Field


class ConcertOption(BaseModel):
    artist: str
    stage: str
    starts_at: datetime
    ends_at: datetime
    genres: list[str] = Field(default_factory=list)


class RecommendationRequest(BaseModel):
    squad_id: str
    options: list[ConcertOption] = Field(min_length=2)
    manual_genres: list[str] = Field(default_factory=list)
    spotify_genres: list[str] = Field(default_factory=list)
    favorite_artists: list[str] = Field(default_factory=list)


class RecommendationResponse(BaseModel):
    selected_artist: str
    selected_stage: str
    score: int
    reason: str

