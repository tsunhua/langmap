# Region Data Migration Guide

This guide explains the changes made to improve how region data is stored and displayed in the LangMap application.

## Changes Made

1. **Backend Database Schema Updates:**
   - Added `region_name`, `region_latitude`, `region_longitude`, `country_code`, and `country_name` columns to both `expressions` and `expression_versions` tables
   - Removed the old `region` column (no backward compatibility maintained)

2. **Frontend Display Improvements:**
   - Updated ExpressionCard component to show language native names instead of language codes
   - Updated ExpressionCard component to show clean region names instead of JSON structures
   - Added display of country information when available
   - Applied the same improvements to the Detail page

## Migration Steps

To apply these changes to your existing database:

1. Run the database schema migration:
   ```bash
   cd backend
   python migrations/001_add_region_fields.py
   ```

2. Run the data migration script to convert existing JSON region data:
   ```bash
   cd backend
   python scripts/migrate_region_data.py
   ```

## How It Works

1. **Data Storage:**
   - When creating new expressions, the region and country data is stored in separate fields
   - Existing JSON region data is migrated to the new fields

2. **Data Display:**
   - The frontend now displays the language's native name instead of the language code
   - Region information is shown as a clean name instead of a JSON structure
   - Country information is displayed when available

## Benefits

- Cleaner, more user-friendly display of language, region, and country information
- Better separation of concerns in the database schema
- Improved performance when querying region data
- More granular location information with separate country data