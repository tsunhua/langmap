#!/usr/bin/env python3
"""
Migration script to add region_name, region_latitude, region_longitude, country_code, and country_name columns to expressions and expression_versions tables.
"""

import sys
import os

# Add the app directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'app'))

from sqlalchemy import create_engine, text
from app.db.session import DATABASE_URL

def upgrade():
    """Add region_name, region_latitude, region_longitude, country_code, and country_name columns to expressions and expression_versions tables"""
    engine = create_engine(DATABASE_URL)
    
    with engine.connect() as conn:
        # Add columns to expressions table
        conn.execute(text("ALTER TABLE expressions ADD COLUMN region_name VARCHAR(100)"))
        conn.execute(text("ALTER TABLE expressions ADD COLUMN region_latitude VARCHAR(20)"))
        conn.execute(text("ALTER TABLE expressions ADD COLUMN region_longitude VARCHAR(20)"))
        conn.execute(text("ALTER TABLE expressions ADD COLUMN country_code VARCHAR(10)"))
        conn.execute(text("ALTER TABLE expressions ADD COLUMN country_name VARCHAR(100)"))
        
        # Add columns to expression_versions table
        conn.execute(text("ALTER TABLE expression_versions ADD COLUMN region_name VARCHAR(100)"))
        conn.execute(text("ALTER TABLE expression_versions ADD COLUMN region_latitude VARCHAR(20)"))
        conn.execute(text("ALTER TABLE expression_versions ADD COLUMN region_longitude VARCHAR(20)"))
        conn.execute(text("ALTER TABLE expression_versions ADD COLUMN country_code VARCHAR(10)"))
        conn.execute(text("ALTER TABLE expression_versions ADD COLUMN country_name VARCHAR(100)"))
        
        # Commit the transaction
        conn.commit()
        
    print("Successfully added region and country fields to expressions and expression_versions tables")

def downgrade():
    """Remove region_name, region_latitude, region_longitude, country_code, and country_name columns from expressions and expression_versions tables"""
    engine = create_engine(DATABASE_URL)
    
    with engine.connect() as conn:
        # Remove columns from expression_versions table
        conn.execute(text("ALTER TABLE expression_versions DROP COLUMN country_name"))
        conn.execute(text("ALTER TABLE expression_versions DROP COLUMN country_code"))
        conn.execute(text("ALTER TABLE expression_versions DROP COLUMN region_longitude"))
        conn.execute(text("ALTER TABLE expression_versions DROP COLUMN region_latitude"))
        conn.execute(text("ALTER TABLE expression_versions DROP COLUMN region_name"))
        
        # Remove columns from expressions table
        conn.execute(text("ALTER TABLE expressions DROP COLUMN country_name"))
        conn.execute(text("ALTER TABLE expressions DROP COLUMN country_code"))
        conn.execute(text("ALTER TABLE expressions DROP COLUMN region_longitude"))
        conn.execute(text("ALTER TABLE expressions DROP COLUMN region_latitude"))
        conn.execute(text("ALTER TABLE expressions DROP COLUMN region_name"))
        
        # Commit the transaction
        conn.commit()
        
    print("Successfully removed region and country fields from expressions and expression_versions tables")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "downgrade":
        downgrade()
    else:
        upgrade()