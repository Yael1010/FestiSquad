from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, SecretStr, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy import URL


class DatabaseSettings(BaseSettings):
    # Separado de Settings para conservar la configuración existente de JWT/Spotify.
    model_config = SettingsConfigDict(
        env_file=Path(__file__).resolve().parents[2] / '.env',
        env_file_encoding='utf-8', extra='ignore',
    )
    environment: Literal['development', 'test', 'staging', 'production'] = 'development'
    db_host: str = 'localhost'
    db_port: int = Field(default=1433, ge=1, le=65535)
    db_name: str = 'FestiSquad'
    db_user: str = Field(min_length=1)
    db_password: SecretStr = Field(min_length=1)
    db_driver: str = 'ODBC Driver 18 for SQL Server'
    db_trust_server_certificate: bool = False

    @model_validator(mode='after')
    def validate_tls(self):
        if self.environment not in ('development', 'test') and self.db_trust_server_certificate:
            raise ValueError('La validación del certificado es obligatoria fuera de desarrollo/test')
        return self

    def connection_url(self) -> URL:
        return URL.create(
            'mssql+pyodbc', username=self.db_user,
            password=self.db_password.get_secret_value(),
            host=self.db_host, port=self.db_port, database=self.db_name,
            query={'driver': self.db_driver, 'Encrypt': 'yes',
                   'TrustServerCertificate': 'yes' if self.db_trust_server_certificate else 'no'},
        )


@lru_cache
def get_database_settings() -> DatabaseSettings:
    return DatabaseSettings()
