from collections.abc import Generator
from functools import lru_cache

from sqlalchemy import create_engine, event
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.core.database_settings import get_database_settings


@lru_cache
def get_engine() -> Engine:
    engine = create_engine(
        get_database_settings().connection_url(),
        pool_pre_ping=True, pool_size=5, max_overflow=5,
        pool_timeout=5, pool_recycle=1800,
        connect_args={'timeout': 5}, echo=False, hide_parameters=True,
        # Lectura coherente de los movimientos en cada consulta de saldos.
        isolation_level='SERIALIZABLE',
    )

    @event.listens_for(engine, 'connect')
    def configure_connection(connection, _record):
        connection.timeout = 10  # timeout de consultas ODBC, no objetivo de latencia

    return engine


def get_db() -> Generator[Session, None, None]:
    # Una sesión por petición. El servicio confirma explícitamente sus escrituras.
    with Session(get_engine(), expire_on_commit=False) as session:
        try:
            yield session
        except Exception:
            session.rollback()
            raise


def dispose_engine() -> None:
    if get_engine.cache_info().currsize:
        get_engine().dispose()
        get_engine.cache_clear()
