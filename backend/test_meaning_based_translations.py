import sys
import os

# Add the app directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'app'))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_ui_translations_by_meaning():
    """Test getting UI translations by meaning"""
    # First, create a meaning with a langmap gloss
    meaning_payload = {
        "gloss": "langmap.home.title",
        "description": "Homepage title"
    }
    
    meaning_response = client.post("/api/v1/meanings", json=meaning_payload)
    print(f"POST /api/v1/meanings - Status: {meaning_response.status_code}")
    
    if meaning_response.status_code != 201:
        print(f"Failed to create meaning: {meaning_response.text}")
        return
        
    meaning = meaning_response.json()
    meaning_id = meaning["id"]
    print(f"Created meaning: {meaning_id} - {meaning['gloss']}")
    
    # Create an expression in a test language
    expression_payload = {
        "language": "test-lang",
        "text": "Test Language Home Title",
        "region": "global"
    }
    
    expression_response = client.post("/api/v1/expressions", json=expression_payload)
    print(f"POST /api/v1/expressions - Status: {expression_response.status_code}")
    
    if expression_response.status_code != 201:
        print(f"Failed to create expression: {expression_response.text}")
        return
        
    expression = expression_response.json()
    expression_id = expression["id"]
    print(f"Created expression: {expression_id} - {expression['text']}")
    
    # Link the expression to the meaning
    link_response = client.post(f"/api/v1/meanings/{meaning_id}/link?expression_id={expression_id}")
    print(f"POST /api/v1/meanings/{meaning_id}/link - Status: {link_response.status_code}")
    
    if link_response.status_code != 201:
        print(f"Failed to link expression to meaning: {link_response.text}")
        return
        
    print(f"Linked expression {expression_id} to meaning {meaning_id}")
    
    # Test fetching UI translations for the test language
    translations_response = client.get("/api/v1/ui-translations/test-lang")
    print(f"GET /api/v1/ui-translations/test-lang - Status: {translations_response.status_code}")
    
    if translations_response.status_code == 200:
        translations = translations_response.json()
        print(f"Found {len(translations)} UI translations:")
        for translation in translations:
            print(f"  - {translation['gloss']}: {translation['text']}")
    else:
        print(f"Error fetching translations: {translations_response.text}")

if __name__ == "__main__":
    print("Testing meaning-based UI translations...")
    test_ui_translations_by_meaning()