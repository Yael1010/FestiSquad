from fastapi.testclient import TestClient

from app.main import create_app


def test_web_client_can_preflight_phase12_put_endpoints():
    response = TestClient(create_app()).options(
        "/api/v1/clash-resolver/votes",
        headers={
            "Origin": "http://localhost:5173",
            "Access-Control-Request-Method": "PUT",
            "Access-Control-Request-Headers": "authorization,content-type",
        },
    )

    assert response.status_code == 200
    assert "PUT" in response.headers["access-control-allow-methods"]


def test_openapi_keeps_the_versioned_contract_in_development():
    response = TestClient(create_app()).get("/openapi.json")

    assert response.status_code == 200
    paths = response.json()["paths"]
    assert "/api/v1/auth/login" in paths
    assert "/api/v1/squads" in paths
    assert "/api/v1/festivals" in paths
    assert "/api/v1/expenses" in paths
    assert "/api/v1/clash-resolver/conflicts" in paths
