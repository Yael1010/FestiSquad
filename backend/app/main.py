from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import db_probe
from app.api.v1.router import api_router
from app.core.database import dispose_engine
from app.core.http_middleware import QualityMiddleware
from app.core.settings import settings


@asynccontextmanager
async def lifespan(_app: FastAPI):
    yield
    dispose_engine()


def create_app() -> FastAPI:
    app = FastAPI(
        title="FestiSquad API",
        version="0.1.0",
        description="API modular para logística, ubicación, finanzas y recomendaciones musicales.",
        lifespan=lifespan,
        docs_url=None if settings.environment == "production" else "/docs",
        redoc_url=None if settings.environment == "production" else "/redoc",
        openapi_url=None if settings.environment == "production" else "/openapi.json",
    )

    app.add_middleware(QualityMiddleware, settings=settings)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_origin_regex=(
            r"https?://(localhost|127\.0\.0\.1)(:\d+)?"
            if settings.environment in ("development", "test")
            else None
        ),
        allow_credentials=True,
        allow_methods=["GET", "POST"],
        allow_headers=["Authorization", "Content-Type"],
    )

    @app.get("/health", tags=["health"])
    def health() -> dict[str, str]:
        return {"status": "ok", "environment": settings.environment}

    app.include_router(api_router, prefix="/api/v1")
    app.include_router(db_probe.router)
    return app


app = create_app()
