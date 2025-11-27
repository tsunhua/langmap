import sys
import os

# Add the app directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'app'))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.db.models import Language
from app.db.session import DATABASE_URL

def test_db_connection():
    """Test database connection and query languages"""
    try:
        # Create database engine and session
        engine = create_engine(DATABASE_URL)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        # Test query
        languages = db.query(Language).all()
        print(f"Found {len(languages)} languages in database:")
        for lang in languages:
            print(f"  - {lang.code}: {lang.name} ({lang.native_name})")
            
        db.close()
        return True
    except Exception as e:
        print(f"Error connecting to database: {e}")
        return False

if __name__ == "__main__":
    print("Testing database connection...")
    test_db_connection()