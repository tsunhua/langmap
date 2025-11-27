import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db.session import SessionLocal
from app.db import models

client = TestClient(app)


def test_create_expression_with_tags():
    """Test creating an expression with tags"""
    response = client.post(
        "/api/v1/expressions",
        json={
            "language": "en",
            "text": "Home",
            "region": "global",
            "tags": ["langmap", "nav.home"]
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["language"] == "en"
    assert data["text"] == "Home"
    assert "tags" in data
    assert "langmap" in data["tags"]


def test_get_expressions_by_tags():
    """Test getting expressions filtered by tags"""
    # First create an expression with tags
    client.post(
        "/api/v1/expressions",
        json={
            "language": "es",
            "text": "Inicio",
            "region": "global",
            "tags": ["langmap", "nav.home"]
        }
    )
    
    # Then retrieve it by tags
    response = client.get("/api/v1/expressions?language=es&tags=langmap")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 1
    assert any("langmap" in expr.get("tags", []) for expr in data)


def test_list_languages():
    """Test listing supported languages"""
    response = client.get("/api/v1/languages")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    assert any(lang["code"] == "en" for lang in data)


if __name__ == "__main__":
    pytest.main([__file__])