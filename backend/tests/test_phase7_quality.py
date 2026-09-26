from time import perf_counter

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core.http_middleware import QualityMiddleware
from app.core.settings import Settings
from app.main import create_app


def production_settings() -> Settings:
    return Settings(
        environment="production",
        jwt_secret_key="a-secure-secret-with-more-than-32-characters",
        cors_origins=["https://app.festisquad.example"],
        _env_file=None,
    )


def test_health_exposes_request_trace_and_security_headers():
    response = TestClient(create_app()).get("/health")

    assert response.status_code == 200
    assert response.headers["x-request-id"]
    assert float(response.headers["x-process-time-ms"]) >= 0
    assert response.headers["server-timing"].startswith("app;dur=")
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["x-frame-options"] == "DENY"
    assert response.headers["cache-control"] == "no-store"


def test_request_id_only_accepts_safe_characters():
    client = TestClient(create_app())

    accepted = client.get("/health", headers={"X-Request-ID": "mobile-123"})
    rejected = client.get("/health", headers={"X-Request-ID": "unsafe value"})

    assert accepted.headers["x-request-id"] == "mobile-123"
    assert rejected.headers["x-request-id"] != "unsafe value"


def test_oversized_request_is_rejected_before_router():
    response = TestClient(create_app()).post(
        "/api/v1/auth/login",
        headers={"Content-Length": "1048577"},
        content=b"{}",
    )

    assert response.status_code == 413
    assert response.json()["detail"] == "request_body_too_large"


def test_production_requires_forwarded_https_and_adds_hsts():
    app = FastAPI()
    app.add_middleware(QualityMiddleware, settings=production_settings())

    @app.get("/probe")
    def probe():
        return {"status": "ok"}

    client = TestClient(app)
    rejected = client.get("/probe", headers={"X-Forwarded-Proto": "http"})
    accepted = client.get("/probe", headers={"X-Forwarded-Proto": "https"})

    assert rejected.status_code == 400
    assert rejected.json()["detail"] == "https_required"
    assert accepted.status_code == 200
    assert accepted.headers["strict-transport-security"].startswith("max-age=")


def test_health_meets_application_latency_target():
    client = TestClient(create_app())
    samples = []
    for _ in range(10):
        started = perf_counter()
        response = client.get("/health")
        samples.append((perf_counter() - started) * 1000)
        assert response.status_code == 200

    assert max(samples) < 1500
