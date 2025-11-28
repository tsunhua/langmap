import sys
import os

# Add the app directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'app'))

from sqlalchemy import create_engine, text
from app.db.session import DATABASE_URL

def add_tags_column_to_meanings():
    """Add tags column to meanings table"""
    engine = create_engine(DATABASE_URL)
    
    with engine.connect() as db:
        # Check if we're using SQLite
        if engine.dialect.name == 'sqlite':
            # SQLite doesn't support IF NOT EXISTS with ALTER TABLE ADD COLUMN
            # Also doesn't support array types, so we'll use a string field and serialize/deserialize
            try:
                db.execute(text("ALTER TABLE meanings ADD COLUMN tags TEXT"))
                db.commit()
                print("Successfully added tags column to meanings table (SQLite)")
            except Exception as e:
                if "duplicate column name" in str(e).lower():
                    print("Tags column already exists (SQLite)")
                else:
                    print(f"Error adding tags column: {e}")
        else:
            # For PostgreSQL and other databases that support arrays
            try:
                db.execute(text("ALTER TABLE meanings ADD COLUMN IF NOT EXISTS tags TEXT[]"))
                db.commit()
                print("Successfully added tags column to meanings table (PostgreSQL)")
            except Exception as e:
                print(f"Error adding tags column: {e}")

if __name__ == "__main__":
    add_tags_column_to_meanings()