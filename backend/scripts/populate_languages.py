import sys
import os

# Add the app directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'app'))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.models import Language
from app.db.session import DATABASE_URL

# Create database engine and session
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def populate_languages():
    """Populate the database with initial languages"""
    db = SessionLocal()
    
    # Initial languages to populate
    initial_languages = [
        {"code": "en", "name": "English", "native_name": "English", "direction": "ltr"},
        {"code": "zh-CN", "name": "Simplified Chinese", "native_name": "简体中文", "direction": "ltr"},
        {"code": "zh-TW", "name": "Traditional Chinese", "native_name": "傳統中文", "direction": "ltr"},
        {"code": "es", "name": "Spanish", "native_name": "Español", "direction": "ltr"},
        {"code": "fr", "name": "French", "native_name": "Français", "direction": "ltr"},
        {"code": "ja", "name": "Japanese", "native_name": "日本語", "direction": "ltr"},
    ]
    
    try:
        # Check if languages already exist
        existing_count = db.query(Language).count()
        if existing_count > 0:
            print(f"Database already contains {existing_count} languages. Skipping population.")
            return
            
        # Insert initial languages
        for lang_data in initial_languages:
            language = Language(**lang_data)
            db.add(language)
            
        db.commit()
        print(f"Successfully populated {len(initial_languages)} languages into the database")
    except Exception as e:
        print(f"Error populating languages: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    populate_languages()