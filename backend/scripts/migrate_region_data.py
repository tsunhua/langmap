#!/usr/bin/env python3
"""
Script to migrate existing JSON region data to the new separate region and country fields.
"""

import sys
import os
import json

# Add the app directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'app'))

from sqlalchemy import create_engine, text
from app.db.session import DATABASE_URL

def migrate_region_data():
    """Migrate existing JSON region data to the new separate region and country fields"""
    engine = create_engine(DATABASE_URL)
    
    with engine.connect() as conn:
        # Get all expressions with region data
        result = conn.execute(text("SELECT id, region FROM expressions WHERE region IS NOT NULL"))
        expressions = result.fetchall()
        
        migrated_count = 0
        error_count = 0
        
        for expr_id, region in expressions:
            try:
                # Try to parse the region as JSON
                region_data = json.loads(region)
                
                # Extract the fields
                region_name = region_data.get('name')
                region_latitude = region_data.get('latitude')
                region_longitude = region_data.get('longitude')
                country_code = region_data.get('country_code')
                country_name = region_data.get('country_name')
                
                # Update the record with the new fields
                conn.execute(
                    text("""
                        UPDATE expressions 
                        SET region_name = :region_name, 
                            region_latitude = :region_latitude, 
                            region_longitude = :region_longitude,
                            country_code = :country_code,
                            country_name = :country_name
                        WHERE id = :id
                    """),
                    {
                        'id': expr_id,
                        'region_name': region_name,
                        'region_latitude': str(region_latitude) if region_latitude is not None else None,
                        'region_longitude': str(region_longitude) if region_longitude is not None else None,
                        'country_code': country_code,
                        'country_name': country_name
                    }
                )
                
                migrated_count += 1
                
            except (json.JSONDecodeError, TypeError):
                # If it's not valid JSON, skip this record
                print(f"Skipping expression {expr_id} - region is not valid JSON: {region}")
                error_count += 1
                continue
        
        # Commit the transaction
        conn.commit()
        
        print(f"Successfully migrated {migrated_count} expressions")
        if error_count > 0:
            print(f"Skipped {error_count} expressions with invalid region data")

def migrate_region_data_versions():
    """Migrate existing JSON region data to the new separate region and country fields in expression_versions table"""
    engine = create_engine(DATABASE_URL)
    
    with engine.connect() as conn:
        # Get all expression versions with region data
        result = conn.execute(text("SELECT id, region FROM expression_versions WHERE region IS NOT NULL"))
        versions = result.fetchall()
        
        migrated_count = 0
        error_count = 0
        
        for version_id, region in versions:
            try:
                # Try to parse the region as JSON
                region_data = json.loads(region)
                
                # Extract the fields
                region_name = region_data.get('name')
                region_latitude = region_data.get('latitude')
                region_longitude = region_data.get('longitude')
                country_code = region_data.get('country_code')
                country_name = region_data.get('country_name')
                
                # Update the record with the new fields
                conn.execute(
                    text("""
                        UPDATE expression_versions 
                        SET region_name = :region_name, 
                            region_latitude = :region_latitude, 
                            region_longitude = :region_longitude,
                            country_code = :country_code,
                            country_name = :country_name
                        WHERE id = :id
                    """),
                    {
                        'id': version_id,
                        'region_name': region_name,
                        'region_latitude': str(region_latitude) if region_latitude is not None else None,
                        'region_longitude': str(region_longitude) if region_longitude is not None else None,
                        'country_code': country_code,
                        'country_name': country_name
                    }
                )
                
                migrated_count += 1
                
            except (json.JSONDecodeError, TypeError):
                # If it's not valid JSON, skip this record
                print(f"Skipping expression version {version_id} - region is not valid JSON: {region}")
                error_count += 1
                continue
        
        # Commit the transaction
        conn.commit()
        
        print(f"Successfully migrated {migrated_count} expression versions")
        if error_count > 0:
            print(f"Skipped {error_count} expression versions with invalid region data")

if __name__ == "__main__":
    migrate_region_data()
    migrate_region_data_versions()