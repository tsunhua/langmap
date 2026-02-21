#!/usr/bin/env python3
"""
Fetch language translations from API and save to locales directory.
"""

import json
import os
from pathlib import Path
from typing import Optional

import requests

API_BASE = "http://localhost:8787/api/v1"
LOCALES_DIR = Path(__file__).parent.parent / "web" / "src" / "locales"


def fetch_languages() -> list:
    """Fetch all active languages from API."""
    try:
        response = requests.get(f"{API_BASE}/languages?is_active=1")
        response.raise_for_status()
        data = response.json()
        if isinstance(data, dict) and "data" in data:
            return data["data"]
        if isinstance(data, list):
            return data
        print(f"Unexpected data format: {type(data)}")
        print(f"Response data: {data}")
        return []
    except requests.RequestException as error:
        print(f"Failed to fetch languages: {error}")
        if hasattr(error, "response") and error.response:
            print(f"Response status: {error.response.status_code}")
            print(f"Response data: {error.response.text}")
        raise


def fetch_translations(language_code: str) -> Optional[dict]:
    """Fetch translations for a specific language."""
    try:
        response = requests.get(f"{API_BASE}/ui-translations/{language_code}")
        response.raise_for_status()
        data = response.json()

        if isinstance(data, dict) and "data" in data:
            data = data["data"]

        if isinstance(data, list):
            translations = {}
            for item in data:
                if "tags" in item and "text" in item:
                    try:
                        tags = (
                            json.loads(item["tags"])
                            if isinstance(item["tags"], str)
                            else item["tags"]
                        )
                        if isinstance(tags, list) and len(tags) > 0:
                            key = None
                            for tag in tags:
                                if not tag.startswith("langmap."):
                                    key = tag
                                    break
                            if key is None and len(tags) > 0:
                                key = tags[0]
                                if key.startswith("langmap."):
                                    key = key[8:]
                            if key:
                                translations[key] = item["text"]
                    except (json.JSONDecodeError, TypeError):
                        continue
            return translations

        return data
    except requests.RequestException as error:
        print(f"Failed to fetch translations for {language_code}: {error}")
        if hasattr(error, "response") and error.response:
            print(f"Response status: {error.response.status_code}")
            print(f"Response data: {error.response.text}")
        return None


def convert_to_nested(flat_dict: dict) -> dict:
    """Convert flat dot-notation keys to nested object structure."""
    result = {}
    for key, value in flat_dict.items():
        parts = key.split(".")
        current = result
        for part in parts[:-1]:
            if part not in current:
                current[part] = {}
            elif not isinstance(current[part], dict):
                current[part] = {}
            current = current[part]
        current[parts[-1]] = value
    return result


def save_locale_file(language_code: str, translations: dict) -> None:
    """Save translations to locale file."""
    LOCALES_DIR.mkdir(parents=True, exist_ok=True)
    file_path = LOCALES_DIR / f"{language_code}.json"

    nested_translations = convert_to_nested(translations)

    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(nested_translations, f, ensure_ascii=False, indent=2)

    print(f"✓ Saved {language_code}.json ({len(translations)} entries)")


def main():
    """Main function to fetch and save all translations."""
    print("Fetching languages from API...")
    languages = fetch_languages()

    if not isinstance(languages, list) or not languages:
        print("No languages found in API response")
        return 1

    print(f"Found {len(languages)} active languages")

    success_count = 0
    fail_count = 0

    for language in languages:
        language_code = language.get("code") or language.get("id")
        print(f"\nFetching translations for {language_code}...")

        translations = fetch_translations(language_code)

        if translations and isinstance(translations, dict):
            save_locale_file(language_code, translations)
            success_count += 1
        else:
            print(f"✗ Failed to fetch valid translations for {language_code}")
            fail_count += 1

    print("\n=== Summary ===")
    print(f"✓ Successfully updated: {success_count} languages")
    print(f"✗ Failed: {fail_count} languages")

    return 0 if fail_count == 0 else 1


if __name__ == "__main__":
    exit(main())
