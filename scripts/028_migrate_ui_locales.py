#!/usr/bin/env python3
"""
Script to migrate locale JSON files from web/src/locales/ to ui_locales table.
Each language's locale file will be inserted as a single row with the entire JSON object.
"""

import json
import os
from typing import Dict, List
from pathlib import Path


def generate_sql_inserts(locales_dir: str = "../web/src/locales") -> List[str]:
    """
    Generate SQL INSERT OR REPLACE statements for ui_locales table.

    Args:
        locales_dir: Path to the directory containing locale JSON files

    Returns:
        List of SQL INSERT statements
    """
    sql_statements = []

    # Resolve the full path to locales directory
    if not os.path.isabs(locales_dir):
        # Get the directory where this script is located
        script_dir = os.path.dirname(os.path.abspath(__file__))
        locales_dir = os.path.join(script_dir, locales_dir)

    print(f"Looking for locale files in: {locales_dir}")

    # Find all JSON files in the locales directory
    if not os.path.exists(locales_dir):
        print(f"Warning: Locales directory not found at {locales_dir}")
        return sql_statements

    locale_files = sorted([f for f in os.listdir(locales_dir) if f.endswith('.json')])

    print(f"Found {len(locale_files)} locale files")

    for filename in locale_files:
        # Extract language code from filename (e.g., 'en-US.json' -> 'en-US')
        language_code = filename[:-5]  # Remove '.json' extension

        # Read the JSON file
        filepath = os.path.join(locales_dir, filename)
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                locale_data = json.load(f)
        except json.JSONDecodeError as e:
            print(f"Error parsing {filename}: {e}")
            continue
        except Exception as e:
            print(f"Error reading {filename}: {e}")
            continue

        # Verify it's a flattened JSON object (key-value pairs)
        if not isinstance(locale_data, dict):
            print(f"Warning: {filename} does not contain a JSON object, skipping")
            continue

        # Check if it's already flattened (no nested objects)
        has_nested = any(isinstance(v, dict) for v in locale_data.values())
        if has_nested:
            print(f"Warning: {filename} contains nested objects. Please flatten before migration.")
            # We'll still insert it as-is, but warn the user

        # Convert to JSON string for storage
        locale_json_str = json.dumps(locale_data, ensure_ascii=False, separators=(',', ':'))

        # Escape single quotes in JSON string for SQL
        escaped_json = locale_json_str.replace("'", "''")

        # Generate INSERT statement
        sql = (
            f"INSERT OR REPLACE INTO ui_locales "
            f"(language_code, locale_json, created_by, created_at, updated_by, updated_at) "
            f"VALUES ('{language_code}', '{escaped_json}', 'migration', datetime('now'), 'migration', datetime('now'));"
        )

        sql_statements.append(sql)
        print(f"  - Added {language_code} with {len(locale_data)} keys")

    return sql_statements


def main():
    """Main function to generate SQL from locale files."""
    output_file = '028_migrate_ui_locales.sql'

    # Generate SQL statements
    print("Generating SQL INSERT statements for ui_locales table...")
    sql_statements = generate_sql_inserts()
    print(f"Generated {len(sql_statements)} SQL statements")

    if not sql_statements:
        print("No SQL statements generated. Please check the locales directory path.")
        return

    # Write to output file
    output_path = os.path.join(os.path.dirname(__file__), output_file)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("-- Auto-generated SQL script for ui_locales table\n")
        f.write("-- Migrates locale JSON files from web/src/locales/\n")
        f.write("-- Each language's locale is stored as a single JSON object\n")
        f.write("-- Uses INSERT OR REPLACE to update existing rows or insert new ones\n\n")
        for statement in sql_statements:
            f.write(statement + '\n')

    print(f"SQL statements written to {output_path}")
    print("\nTo apply this migration:")
    print("1. First run: npx wrangler d1 execute DB --file=scripts/028_create_ui_locales.sql")
    print(f"2. Then run: npx wrangler d1 execute DB --file=scripts/{output_file}")


if __name__ == "__main__":
    main()
