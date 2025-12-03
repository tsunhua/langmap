#!/usr/bin/env python3
"""
Script to generate SQL insert statements from locale JSON files.
Populates expressions, meanings, and expression_versions tables.
"""

import json
import os
import sqlite3
from typing import Dict, List, Any


def load_locale_files(locales_dir: str) -> Dict[str, Dict[str, Any]]:
    """
    Load all locale JSON files from the given directory.
    
    Args:
        locales_dir: Path to the locales directory
        
    Returns:
        Dictionary mapping language codes to their JSON content
    """
    locales = {}
    for filename in os.listdir(locales_dir):
        if filename.endswith('.json'):
            lang_code = filename[:-5]  # Remove .json extension
            with open(os.path.join(locales_dir, filename), 'r', encoding='utf-8') as f:
                locales[lang_code] = json.load(f)
    return locales


def flatten_dict(d: Dict[str, Any], parent_key: str = '', sep: str = '.') -> Dict[str, Any]:
    """
    Flatten a nested dictionary.
    
    Args:
        d: Dictionary to flatten
        parent_key: Key prefix for nested keys
        sep: Separator for nested keys
        
    Returns:
        Flattened dictionary
    """
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)


def generate_sql_inserts(locales: Dict[str, Dict[str, Any]]) -> List[str]:
    """
    Generate SQL INSERT statements for expressions, meanings, and expression_versions tables.
    
    Args:
        locales: Dictionary mapping language codes to their JSON content
        
    Returns:
        List of SQL INSERT statements
    """
    sql_statements = []
    
    # Track meanings to avoid duplicates - key is the meaning gloss (key_path)
    meanings_map = {}  # key_path -> meaning_id
    next_meaning_id = 1
    
    # Track expressions to link with versions
    expressions_map = {}  # (text, language_code) -> expression_id
    next_expression_id = 1
    
    # First pass: collect all unique meanings
    for lang_code, content in locales.items():
        # Flatten the nested JSON structure
        flat_content = flatten_dict(content)
        
        # Process each key-value pair
        for key_path, text_value in flat_content.items():
            # Skip non-string values
            if not isinstance(text_value, str):
                continue
            
            # Skip strings with length <= 1
            if len(text_value.strip()) <= 1:
                continue
                
            # Create meaning entry if not exists
            if key_path not in meanings_map:
                meanings_map[key_path] = next_meaning_id
                meaning_id = next_meaning_id
                next_meaning_id += 1
                
                # Insert into meanings table
                meaning_gloss = f"langmap.{key_path}"
                sql_statements.append(
                    f"INSERT INTO meanings (id, gloss, description, created_by, updated_by, created_at, updated_at, tags) "
                    f"VALUES ({meaning_id}, '{meaning_gloss}', '', 'langmap', 'langmap', datetime('now'), datetime('now'), '[\"langmap\"]');"
                )
    
    # Second pass: create expressions and link to meanings
    for lang_code, content in locales.items():
        # Flatten the nested JSON structure
        flat_content = flatten_dict(content)
        
        # Process each key-value pair
        for key_path, text_value in flat_content.items():
            # Skip non-string values
            if not isinstance(text_value, str):
                continue
            
            # Skip strings with length <= 1
            if len(text_value.strip()) <= 1:
                continue
                
            # Get meaning id
            meaning_id = meanings_map[key_path]
            
            # Create expression entry
            expression_id = next_expression_id
            expressions_map[(text_value, lang_code)] = expression_id
            next_expression_id += 1
            
            # Insert into expressions table
            escaped_text = text_value.replace("'", "''")  # Escape single quotes
            sql_statements.append(
                f"INSERT INTO expressions (id, text, language_code, created_by, updated_by, created_at, updated_at, tags, source_type, review_status, auto_approved) "
                f"VALUES ({expression_id}, '{escaped_text}', '{lang_code}', 'langmap', 'langmap', datetime('now'), datetime('now'), '[\"langmap\"]', 'ai', 'approved', 1);"
            )
            
            # Link expression and meaning
            sql_statements.append(
                f"INSERT INTO expression_meanings (expression_id, meaning_id, created_by, updated_by, created_at, updated_at) "
                f"VALUES ({expression_id}, {meaning_id}, 'langmap', 'langmap', datetime('now'), datetime('now'));"
            )
            
            # Create expression version entry
            sql_statements.append(
                f"INSERT INTO expression_versions (expression_id, text, created_by, created_at) "
                f"VALUES ({expression_id}, '{escaped_text}', 'langmap', datetime('now'));"
            )
    
    return sql_statements


def main():
    """Main function to generate SQL from locale files."""
    # Define paths
    web_locales_dir = os.path.join('..', 'web', 'src', 'locales')
    output_file = '003_locales_data.sql'
    
    # Check if locales directory exists
    if not os.path.exists(web_locales_dir):
        print(f"Error: Locales directory not found at {web_locales_dir}")
        return
    
    # Load locale files
    print("Loading locale files...")
    locales = load_locale_files(web_locales_dir)
    print(f"Loaded {len(locales)} locale files")
    
    # Generate SQL statements
    print("Generating SQL INSERT statements...")
    sql_statements = generate_sql_inserts(locales)
    print(f"Generated {len(sql_statements)} SQL statements")
    
    # Write to output file
    output_path = os.path.join(output_file)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("-- Auto-generated SQL script from locale files\n")
        f.write("-- This script populates expressions, meanings, and expression_versions tables\n\n")
        for statement in sql_statements:
            f.write(statement + '\n')
    
    print(f"SQL statements written to {output_path}")


if __name__ == "__main__":
    main()