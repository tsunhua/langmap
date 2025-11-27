import sys
import os

# Add the app directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'app'))

from sqlalchemy import create_engine, text
from app.db.base import Base
from app.db.models import Language
from app.db.session import DATABASE_URL

def create_languages_table():
    """Create the languages table in the database"""
    engine = create_engine(DATABASE_URL)
    
    # Check if table already exists
    with engine.connect() as connection:
        if engine.dialect.has_table(connection, "languages"):
            print("Languages table already exists")
            return
    
    # Create the languages table
    Base.metadata.create_all(engine, tables=[Language.__table__])
    print("Successfully created languages table")

if __name__ == "__main__":
    create_languages_table()