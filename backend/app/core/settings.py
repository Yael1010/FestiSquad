from pathlib import Path
from typing import Literal

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "FestiSquad"
    environment: Literal["development", "test", "staging", "production"] = "development"
    jwt_secret_key: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_minutes: int = 60 * 24 * 7
    spotify_client_id: str = ""
    spotify_client_secret: str = ""
    spotify_redirect_uri: str = "http://127.0.0.1:8000/api/v1/spotify/callback"
    cors_origins: list[str] = []

    model_config = SettingsConfigDict(
        env_file=Path(__file__).resolve().parents[2] / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @model_validator(mode="after")
    def validate_production_secrets(self):
        if bool(self.spotify_client_id) != bool(self.spotify_client_secret):
            raise ValueError(
                "SPOTIFY_CLIENT_ID y SPOTIFY_CLIENT_SECRET deben configurarse juntos"
            )
        if self.environment in ("staging", "production"):
            if self.jwt_secret_key == "change-me-in-production" or len(self.jwt_secret_key) < 32:
                raise ValueError("JWT_SECRET_KEY debe tener al menos 32 caracteres seguros")
            if not self.cors_origins:
                raise ValueError("CORS_ORIGINS es obligatorio fuera de desarrollo")
            if self.spotify_client_id and not self.spotify_redirect_uri.startswith("https://"):
                raise ValueError("SPOTIFY_REDIRECT_URI debe usar HTTPS fuera de desarrollo")
        return self


settings = Settings()
