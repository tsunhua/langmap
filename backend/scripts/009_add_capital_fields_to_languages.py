#!/usr/bin/env python3

"""
Script to add region_name, latitude, and longitude fields to existing languages table
and populate existing language records with region data
"""

import sys
import os

# Add the backend directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from app.db.session import get_db
from app.db.models import Language

def add_region_fields():
    # This script assumes the fields have already been added via database migration
    # Here we just populate the existing records with region data
    
    region_data = {
        'en': {'region_name': 'London', 'latitude': '51.5074', 'longitude': '-0.1278'},
        'zh-Hans': {'region_name': 'Beijing', 'latitude': '39.9042', 'longitude': '116.4074'},
        'zh-Hant': {'region_name': 'Taipei', 'latitude': '25.0330', 'longitude': '121.5654'},
        'es': {'region_name': 'Madrid', 'latitude': '40.4168', 'longitude': '-3.7038'},
        'fr': {'region_name': 'Paris', 'latitude': '48.8566', 'longitude': '2.3522'},
        'ja': {'region_name': 'Tokyo', 'latitude': '35.6762', 'longitude': '139.6503'},
        'ko': {'region_name': 'Seoul', 'latitude': '37.5665', 'longitude': '126.9780'},
        'ar': {'region_name': 'Cairo', 'latitude': '30.0444', 'longitude': '31.2357'},
        'pt': {'region_name': 'Lisbon', 'latitude': '38.7223', 'longitude': '-9.1393'},
        'ru': {'region_name': 'Moscow', 'latitude': '55.7558', 'longitude': '37.6176'},
        'de': {'region_name': 'Berlin', 'latitude': '52.5200', 'longitude': '13.4050'},
        'hi': {'region_name': 'New Delhi', 'latitude': '28.6139', 'longitude': '77.2090'},
        'it': {'region_name': 'Rome', 'latitude': '41.9028', 'longitude': '12.4964'}
    }

    db_gen = get_db()
    db = next(db_gen)  # Get the database session

    try:
        # Update existing languages with region data
        for code, data in region_data.items():
            language = db.query(Language).filter(Language.code == code).first()
            if language:
                language.region_name = data['region_name']
                language.latitude = data['latitude']
                language.longitude = data['longitude']
            else:
                # If language doesn't exist, create it
                language = Language(
                    code=code,
                    name=data.get('name', code),  # This is a minimal name, better to have full names
                    direction='ltr',  # Default direction
                    region_name=data['region_name'],
                    latitude=data['latitude'],
                    longitude=data['longitude']
                )
                db.add(language)

        db.commit()
        print("Successfully updated languages with region data.")

    except Exception as e:
        print(f"Error updating languages: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    add_region_fields()
