import requests
import json

# Test base URL
BASE_URL = "http://localhost:8000"

def test_get_languages():
    """Test getting languages list"""
    try:
        response = requests.get(f"{BASE_URL}/api/v1/languages")
        print(f"GET /api/v1/languages - Status: {response.status_code}")
        if response.status_code == 200:
            languages = response.json()
            print(f"Languages: {json.dumps(languages, indent=2)}")
        else:
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"Exception in GET /api/v1/languages: {e}")

def test_create_language():
    """Test creating a new language"""
    new_language = {
        "code": "test-lang",
        "name": "Test Language",
        "native_name": "Test Language Native",
        "direction": "ltr"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/api/v1/languages", json=new_language)
        print(f"POST /api/v1/languages - Status: {response.status_code}")
        if response.status_code == 200:
            language = response.json()
            print(f"Created language: {json.dumps(language, indent=2)}")
        else:
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"Exception in POST /api/v1/languages: {e}")

if __name__ == "__main__":
    print("Testing Languages API...")
    test_get_languages()
    test_create_language()