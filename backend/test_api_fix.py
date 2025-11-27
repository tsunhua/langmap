import sys
import os

# Add the app directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'app'))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_list_languages():
    """Test listing languages"""
    response = client.get("/api/v1/languages")
    print(f"GET /api/v1/languages - Status: {response.status_code}")
    if response.status_code == 200:
        languages = response.json()
        print(f"Found {len(languages)} languages")
        for lang in languages[:3]:  # Show first 3
            print(f"  - {lang['code']}: {lang['name']}")
    else:
        print(f"Error: {response.text}")

def test_create_language():
    """Test creating a language"""
    new_language = {
        "code": "test-lang-2",
        "name": "Test Language 2",
        "native_name": "Test Language 2 Native",
        "direction": "ltr"
    }
    
    response = client.post("/api/v1/languages", json=new_language)
    print(f"POST /api/v1/languages - Status: {response.status_code}")
    if response.status_code == 200:
        language = response.json()
        print(f"Created language: {language['code']} - {language['name']}")
    else:
        print(f"Error: {response.text}")

def test_get_expressions_with_tags():
    """Test getting expressions with tags"""
    response = client.get("/api/v1/expressions?language=en&tags=langmap")
    print(f"GET /api/v1/expressions?language=en&tags=langmap - Status: {response.status_code}")
    if response.status_code == 200:
        expressions = response.json()
        print(f"Found {len(expressions)} expressions with langmap tag")
    elif response.status_code == 422:
        print(f"Validation error: {response.text}")
    else:
        print(f"Error: {response.text}")

if __name__ == "__main__":
    print("Testing API fixes...")
    test_list_languages()
    test_create_language()
    test_get_expressions_with_tags()