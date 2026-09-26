from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field, computed_field, field_validator, model_validator


def _clean_values(values: list[str], maximum: int) -> list[str]:
    cleaned: list[str] = []
    seen: set[str] = set()
    for raw in values:
        value = " ".join(raw.strip().split())
        key = value.casefold()
        if value and key not in seen:
            if len(value) > maximum:
                raise ValueError(f"Cada valor admite máximo {maximum} caracteres.")
            seen.add(key)
            cleaned.append(value)
    return cleaned


class ConcertOption(BaseModel):
    id: UUID | None = None
    artist: str = Field(min_length=1, max_length=160)
    stage: str = Field(min_length=1, max_length=120)
    starts_at: datetime
    ends_at: datetime
    genres: list[str] = Field(default_factory=list, max_length=12)

    @field_validator("genres")
    @classmethod
    def clean_genres(cls, values: list[str]) -> list[str]:
        return _clean_values(values, 80)

    @model_validator(mode="after")
    def valid_times(self):
        if self.ends_at <= self.starts_at:
            raise ValueError("El concierto debe terminar después de comenzar.")
        return self


class ConflictGroup(BaseModel):
    starts_at: datetime
    ends_at: datetime
    options: list[ConcertOption] = Field(min_length=2)


class ConflictListResponse(BaseModel):
    festival_id: UUID | None
    festival_name: str | None
    conflicts: list[ConflictGroup]


class RecommendationRequest(BaseModel):
    squad_id: UUID | str
    options: list[ConcertOption] = Field(min_length=2, max_length=10)
    # El endpoint reemplaza estos campos con preferencias persistidas del squad.
    manual_genres: list[str] = Field(default_factory=list, exclude=True)
    spotify_genres: list[str] = Field(default_factory=list, exclude=True)
    favorite_artists: list[str] = Field(default_factory=list, exclude=True)
    genre_weights: dict[str, int] = Field(default_factory=dict, exclude=True)
    artist_weights: dict[str, int] = Field(default_factory=dict, exclude=True)


class RecommendationResponse(BaseModel):
    selected_option_id: UUID | None
    selected_artist: str
    selected_stage: str
    score: int
    matched_genres: list[str]
    matched_artist: bool
    reason: str


class ManualMusicPreferencesRequest(BaseModel):
    genres: list[str] = Field(default_factory=list, max_length=12)
    artists: list[str] = Field(default_factory=list, max_length=12)

    @field_validator("genres")
    @classmethod
    def clean_genres(cls, values: list[str]) -> list[str]:
        return _clean_values(values, 80)

    @field_validator("artists")
    @classmethod
    def clean_artists(cls, values: list[str]) -> list[str]:
        return _clean_values(values, 160)

    @model_validator(mode="after")
    def require_one_preference(self):
        if not self.genres and not self.artists:
            raise ValueError("Selecciona al menos un género o artista.")
        return self


class MusicPreferencesResponse(BaseModel):
    manual_genres: list[str]
    manual_artists: list[str]
    spotify_genres: list[str]
    spotify_artists: list[str]

    @computed_field
    @property
    def spotify_connected(self) -> bool:
        return bool(self.spotify_genres or self.spotify_artists)


class SpotifyAuthorizationResponse(BaseModel):
    authorization_url: str


class SpotifyConnectRequest(BaseModel):
    authorization_code: str = Field(min_length=1)
    redirect_uri: str = Field(min_length=1)
    code_verifier: str | None = None
