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
            "native_name": "English",
            "direction": "ltr",
            "region_name": "London",
            "native_region_name": "London",
            "latitude": "51.5074",
            "longitude": "-0.1278"
        },
        {
            "code": "zh-Hans",
            "name": "Simplified Chinese",
            "native_name": "简体中文",
            "direction": "ltr",
            "region_name": "Beijing",
            "native_region_name": "北京",
            "latitude": "39.9042",
            "longitude": "116.4074"
        },
        {
            "code": "zh-Hant",
            "name": "Traditional Chinese",
            "native_name": "繁體中文",
            "direction": "ltr",
            "region_name": "Taipei",
            "native_region_name": "台北",
            "latitude": "25.0330",
            "longitude": "121.5654"
        },
        {
            "code": "es",
            "name": "Spanish",
            "native_name": "Español",
            "direction": "ltr",
            "region_name": "Madrid",
            "native_region_name": "Madrid",
            "latitude": "40.4168",
            "longitude": "-3.7038"
        },
        {
            "code": "fr",
            "name": "French",
            "native_name": "Français",
            "direction": "ltr",
            "region_name": "Paris",
            "native_region_name": "Paris",
            "latitude": "48.8566",
            "longitude": "2.3522"
        },
        {
            "code": "ja",
            "name": "Japanese",
            "native_name": "日本語",
            "direction": "ltr",
            "region_name": "Tokyo",
            "native_region_name": "東京",
            "latitude": "35.6762",
            "longitude": "139.6503"
        },
        {
            "code": "ko",
            "name": "Korean",
            "native_name": "한국어",
            "direction": "ltr",
            "region_name": "Seoul",
            "native_region_name": "서울",
            "latitude": "37.5665",
            "longitude": "126.9780"
        },
        {
            "code": "ar",
            "name": "Arabic",
            "native_name": "العربية",
            "direction": "rtl",
            "region_name": "Cairo",
            "native_region_name": "القاهرة",
            "latitude": "30.0444",
            "longitude": "31.2357"
        },
        {
            "code": "pt",
            "name": "Portuguese",
            "native_name": "Português",
            "direction": "ltr",
            "region_name": "Lisbon",
            "native_region_name": "Lisboa",
            "latitude": "38.7223",
            "longitude": "-9.1393"
        },
        {
            "code": "ru",
            "name": "Russian",
            "native_name": "Русский",
            "direction": "ltr",
            "region_name": "Moscow",
            "native_region_name": "Москва",
            "latitude": "55.7558",
            "longitude": "37.6176"
        },
        {
            "code": "de",
            "name": "German",
            "native_name": "Deutsch",
            "direction": "ltr",
            "region_name": "Berlin",
            "native_region_name": "Berlin",
            "latitude": "52.5200",
            "longitude": "13.4050"
        },
        {
            "code": "hi",
            "name": "Hindi",
            "native_name": "हिन्दी",
            "direction": "ltr",
            "region_name": "New Delhi",
            "native_region_name": "नई दिल्ली",
            "latitude": "28.6139",
            "longitude": "77.2090"
        },
        {
            "code": "it",
            "name": "Italian",
            "native_name": "Italiano",
            "direction": "ltr",
            "region_name": "Rome",
            "native_region_name": "Roma",
            "latitude": "41.9028",
            "longitude": "12.4964"
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