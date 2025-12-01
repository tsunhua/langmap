#!/usr/bin/env python3

"""
Script to populate the database with initial language data
"""

import sys
import os

# Add the backend directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from app.db.session import get_db
from app.db.models import Language

def populate_languages():
    languages_data = [
        {
            "code": "en",
            "name": "English",
            "region_code": "GB",
            "region_name": "London, United Kingdom",
            "region_latitude": 51.5074,
            "region_longitude": -0.1278
        },
        {
            "code": "zh-Hans",
            "name": "简体中文",
            "region_code": "CN",
            "region_name": "北京，中国",
            "region_latitude": 39.9042,
            "region_longitude": 116.4074
        },
        {
            "code": "zh-Hant",
            "name": "繁體中文",
            "region_code": "TW",
            "region_name": "台北，台灣",
            "region_latitude": 25.0330,
            "region_longitude": 121.5654
        },
        {
            "code": "es",
            "name": "Español",
            "region_code": "ES",
            "region_name": "Madrid, España",
            "region_latitude": 40.4168,
            "region_longitude": -3.7038
        },
        {
            "code": "fr",
            "name": "Français",
            "region_code": "FR",
            "region_name": "Paris, France",
            "region_latitude": 48.8566,
            "region_longitude": 2.3522
        },
        {
            "code": "ja",
            "name": "日本語",
            "region_code": "JP",
            "region_name": "東京、日本",
            "region_latitude": 35.6762,
            "region_longitude": 139.6503
        },
        {
            "code": "ko",
            "name": "한국어",
            "region_code": "KR",
            "region_name": "서울, 대한민국",
            "region_latitude": 37.5665,
            "region_longitude": 126.9780
        },
        {
            "code": "ar",
            "name": "العربية",
            "region_code": "EG",
            "region_name": "القاهرة، مصر",
            "region_latitude": 30.0444,
            "region_longitude": 31.2357
        },
        {
            "code": "pt",
            "name": "Português",
            "region_code": "PT",
            "region_name": "Lisboa, Portugal",
            "region_latitude": 38.7223,
            "region_longitude": -9.1393
        },
        {
            "code": "ru",
            "name": "Русский",
            "region_code": "RU",
            "region_name": "Москва, Россия",
            "region_latitude": 55.7558,
            "region_longitude": 37.6176
        },
        {
            "code": "de",
            "name": "Deutsch",
            "region_code": "DE",
            "region_name": "Berlin, Deutschland",
            "region_latitude": 52.5200,
            "region_longitude": 13.4050
        },
        {
            "code": "hi",
            "name": "हिन्दी",
            "region_code": "IN",
            "region_name": "नई दिल्ली, भारत",
            "region_latitude": 28.6139,
            "region_longitude": 77.2090
        },
        {
            "code": "it",
            "name": "Italiano",
            "region_code": "IT",
            "region_name": "Roma, Italia",
            "region_latitude": 41.9028,
            "region_longitude": 12.4964
        }
    ]

    db_gen = get_db()
    db = next(db_gen)  # Get the database session

    try:
        # Check if languages already exist
        existing_count = db.query(Language).count()
        if existing_count > 0:
            print(f"Database already contains {existing_count} languages. Skipping population.")
            return

        # Add languages to the database
        for lang_data in languages_data:
            language = Language(**lang_data)
            db.add(language)

        db.commit()
        print(f"Successfully populated database with {len(languages_data)} languages.")

    except Exception as e:
        print(f"Error populating languages: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    populate_languages()