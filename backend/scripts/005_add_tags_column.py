#!/usr/bin/env python3
"""
Script to add tags column to existing expressions table.
This script should be run once to update the database schema.
"""

import sys
import os

# Add the backend directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from app.db.session import SessionLocal, engine
from sqlalchemy import text

def add_tags_column():
    db = SessionLocal()
    try:
        # Check if we're using SQLite
        if engine.dialect.name == 'sqlite':
            # SQLite doesn't support IF NOT EXISTS with ALTER TABLE ADD COLUMN
            # Also doesn't support array types, so we'll use a string field and serialize/deserialize
            try:
                db.execute(text("ALTER TABLE expressions ADD COLUMN tags TEXT"))
                db.commit()
                print("Successfully added tags column to expressions table (SQLite)")
            except Exception as e:
                if "duplicate column name" in str(e).lower():
                    print("Tags column already exists (SQLite)")
                else:
                    print(f"Error adding tags column: {e}")
        else:
            # For PostgreSQL and other databases that support arrays
            try:
                db.execute(text("ALTER TABLE expressions ADD COLUMN IF NOT EXISTS tags TEXT[]"))
                db.commit()
                print("Successfully added tags column to expressions table (PostgreSQL)")
            except Exception as e:
                print(f"Error adding tags column: {e}")
    except Exception as e:
        print(f"Error adding tags column: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    add_tags_column()