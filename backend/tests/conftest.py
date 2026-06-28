import os

import pytest
from fastapi.testclient import TestClient

os.environ.setdefault("DATABASE_URL", "postgresql+psycopg://postgres@localhost:5432/agrishield")
os.environ.setdefault("JWT_SECRET_KEY", "local-dev-secret-for-tests")
os.environ.setdefault("DEMO_PASSWORD", "demo123")

from app.main import app  # noqa: E402


@pytest.fixture()
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture()
def auth_headers(client: TestClient) -> dict[str, str]:
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@agrishield.local", "password": "demo123"},
    )
    response.raise_for_status()
    return {"Authorization": f"Bearer {response.json()['access_token']}"}
