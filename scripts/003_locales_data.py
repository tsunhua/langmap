#!/usr/bin/env python3
"""
Script to generate SQL insert statements from locale JSON files.
Populates expressions, meanings, and expression_versions tables.
"""

import json
import os
import sqlite3
import hashlib
from typing import Dict, List, Any, Tuple


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


def get_language_region_info() -> Dict[str, Dict[str, Any]]:
    """
    Get region information for languages from the language data.
    This information is manually extracted from 002_d1_populate_languages.sql.
    
    Returns:
        Dictionary mapping language codes to their region information
    """
    return {}
    # return {
    #     'en-US': {
    #         'region_code': 'US',
    #         'region_name': 'New York, United States',
    #         'region_latitude': 40.7128,
    #         'region_longitude': -74.0060
    #     },
    #     'en-GB': {
    #         'region_code': 'GB',
    #         'region_name': 'London, United Kingdom',
    #         'region_latitude': 51.5074,
    #         'region_longitude': -0.1278
    #     },
    #     'zh-CN': {
    #         'region_code': 'CN',
    #         'region_name': '北京，中国',
    #         'region_latitude': 39.9042,
    #         'region_longitude': 116.4074
    #     },
    #     'zh-TW': {
    #         'region_code': 'TW',
    #         'region_name': '台北，台灣',
    #         'region_latitude': 25.0330,
    #         'region_longitude': 121.5654
    #     },
    #     'es': {
    #         'region_code': 'ES',
    #         'region_name': 'Madrid, España',
    #         'region_latitude': 40.4168,
    #         'region_longitude': -3.7038
    #     },
    #     'fr': {
    #         'region_code': 'FR',
    #         'region_name': 'Paris, France',
    #         'region_latitude': 48.8566,
    #         'region_longitude': 2.3522
    #     },
    #     'ja': {
    #         'region_code': 'JP',
    #         'region_name': '東京、日本',
    #         'region_latitude': 35.6762,
    #         'region_longitude': 139.6503
    #     },
    #     'ko': {
    #         'region_code': 'KR',
    #         'region_name': '서울, 대한민국',
    #         'region_latitude': 37.5665,
    #         'region_longitude': 126.9780
    #     },
    #     'ar': {
    #         'region_code': 'EG',
    #         'region_name': 'القاهرة، مصر',
    #         'region_latitude': 30.0444,
    #         'region_longitude': 31.2357
    #     },
    #     'pt': {
    #         'region_code': 'PT',
    #         'region_name': 'Lisboa, Portugal',
    #         'region_latitude': 38.7223,
    #         'region_longitude': -9.1393
    #     },
    #     'ru': {
    #         'region_code': 'RU',
    #         'region_name': 'Москва, Россия',
    #         'region_latitude': 55.7558,
    #         'region_longitude': 37.6176
    #     },
    #     'de': {
    #         'region_code': 'DE',
    #         'region_name': 'Berlin, Deutschland',
    #         'region_latitude': 52.5200,
    #         'region_longitude': 13.4050
    #     },
    #     'hi': {
    #         'region_code': 'IN',
    #         'region_name': 'नई दिल्ली, भारत',
    #         'region_latitude': 28.6139,
    #         'region_longitude': 77.2090
    #     },
    #     'it': {
    #         'region_code': 'IT',
    #         'region_name': 'Roma, Italia',
    #         'region_latitude': 41.9028,
    #         'region_longitude': 12.4964
    #     },
    #     'yue-HK': {
    #         'region_code': 'HK',
    #         'region_name': '香港，中国',
    #         'region_latitude': 22.3964,
    #         'region_longitude': 114.1095
    #     },
    #     'nan-TW': {
    #         'region_code': 'TW',
    #         'region_name': '台北，台灣',
    #         'region_latitude': 25.0330,
    #         'region_longitude': 121.5654
    #     }
    # }


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


def stable_hash_id(content: str) -> int:
    """
    Generate a stable ID based on the content using FNV-1a 32-bit hash.
    This ensures that the same content always produces the same ID.
    
    Args:
        content: String content to hash
        
    Returns:
        Stable integer ID derived from the content hash
    """
    # Using FNV-1a 32-bit algorithm
    h = 0x811c9dc5  # FNV offset basis
    for char in content:
        h ^= ord(char)
        h = (h * 0x01000193) & 0xFFFFFFFF  # FNV prime and limit to 32 bits
    # Ensure we don't get 0 as ID (minimum ID should be 1)
    return (h % (2**31 - 1)) + 1


def generate_sql_inserts(locales: Dict[str, Dict[str, Any]]) -> List[str]:
    """
    Generate SQL INSERT statements for expressions, meanings, and expression_versions tables.
    
    Args:
        locales: Dictionary mapping language codes to their JSON content
        
    Returns:
        List of SQL INSERT statements
    """
    sql_statements = []
    
    # Buffers for batch inserts
    meanings_buffer = []
    expressions_buffer = []
    expression_meanings_buffer = []
    
    # Batch size
    BATCH_SIZE = 500
    
    # Get language region information
    language_region_info = get_language_region_info()
    
    # Track meanings to avoid duplicates - key is the meaning gloss (key_path)
    processed_meanings = set()  # Set of meaning_ids to avoid duplicates
    
    # Track expressions to avoid duplicates
    processed_expressions = set()  # Set of expression_ids to avoid duplicates
    
    # Helper function to flush buffers for meanings
    def flush_meanings_buffer():
        if meanings_buffer:
            values_str = ",\n    ".join(meanings_buffer)
            sql_statements.append(
                f"INSERT INTO meanings (id, gloss, description, created_by, updated_by, created_at, updated_at, tags) VALUES\n    {values_str}\n"
                f"ON CONFLICT(id) DO UPDATE SET\n"
                f"    gloss=excluded.gloss,\n"
                f"    description=excluded.description,\n"
                f"    updated_by=excluded.updated_by,\n"
                f"    updated_at=excluded.updated_at,\n"
                f"    tags=excluded.tags;"
            )
            meanings_buffer.clear()
    
    # Helper function to flush buffers for expressions
    def flush_expressions_buffer():
        if expressions_buffer:
            values_str = ",\n    ".join(expressions_buffer)
            sql_statements.append(
                f"INSERT INTO expressions (id, text, language_code, region_code, region_name, region_latitude, region_longitude, created_by, updated_by, created_at, updated_at, tags, source_type, review_status) VALUES\n    {values_str}\n"
                f"ON CONFLICT(id) DO UPDATE SET\n"
                f"    text=excluded.text,\n"
                f"    language_code=excluded.language_code,\n"
                f"    region_code=excluded.region_code,\n"
                f"    region_name=excluded.region_name,\n"
                f"    region_latitude=excluded.region_latitude,\n"
                f"    region_longitude=excluded.region_longitude,\n"
                f"    updated_by=excluded.updated_by,\n"
                f"    updated_at=excluded.updated_at,\n"
                f"    tags=excluded.tags,\n"
                f"    source_type=excluded.source_type,\n"
                f"    review_status=excluded.review_status;"
            )
            expressions_buffer.clear()
    
    # Helper function to flush buffers for expression_meanings
    def flush_expression_meanings_buffer():
        if expression_meanings_buffer:
            values_str = ",\n    ".join(expression_meanings_buffer)
            sql_statements.append(
                f"INSERT INTO expression_meanings (id, expression_id, meaning_id, created_by, updated_by, created_at, updated_at) VALUES\n    {values_str}\n"
                f"ON CONFLICT(id) DO UPDATE SET\n"
                f"    expression_id=excluded.expression_id,\n"
                f"    meaning_id=excluded.meaning_id,\n"
                f"    updated_by=excluded.updated_by,\n"
                f"    updated_at=excluded.updated_at;"
            )
            expression_meanings_buffer.clear()
    
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
                
            # Create stable meaning ID based on key_path
            meaning_id = stable_hash_id(key_path)
            
            # Create meaning entry if not exists
            if meaning_id not in processed_meanings:
                processed_meanings.add(meaning_id)
                
                # Add to meanings buffer
                meaning_gloss = f"langmap.{key_path}".replace("'", "''")  # Escape single quotes
                meanings_buffer.append(
                    f"({meaning_id}, '{meaning_gloss}', '', 'langmap', 'langmap', datetime('now'), datetime('now'), '[\"langmap\"]')"
                )
                
                # Flush buffer if it reaches batch size
                if len(meanings_buffer) >= BATCH_SIZE:
                    flush_meanings_buffer()
    
    # Flush remaining meanings
    flush_meanings_buffer()
    
    # Second pass: create expressions and link to meanings
    for lang_code, content in locales.items():
        # Get region information for this language
        region_info = language_region_info.get(lang_code, {})
        region_code = region_info.get('region_code', 'NULL')
        region_name = region_info.get('region_name', 'NULL')
        region_latitude = region_info.get('region_latitude', 'NULL')
        region_longitude = region_info.get('region_longitude', 'NULL')
        
        # Format values for SQL
        if region_code != 'NULL':
            region_code = f"'{region_code}'"
        if region_name != 'NULL':
            region_name = f"'{region_name}'"
        if region_latitude != 'NULL':
            region_latitude = str(region_latitude)
        if region_longitude != 'NULL':
            region_longitude = str(region_longitude)
        
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
                
            # Get stable meaning id
            meaning_id = stable_hash_id(key_path)
            
            # Create stable expression ID based on text, language_code and region_code
            expression_id_content = f"{text_value}|{lang_code}|{region_info.get('region_code', '')}"
            expression_id = stable_hash_id(expression_id_content)
            
            # Create expression entry if not exists
            if expression_id not in processed_expressions:
                processed_expressions.add(expression_id)
                
                # Insert into expressions table
                escaped_text = text_value.replace("'", "''")  # Escape single quotes
                expressions_buffer.append(
                    f"({expression_id}, '{escaped_text}', '{lang_code}', {region_code}, {region_name}, {region_latitude}, {region_longitude}, 'langmap', 'langmap', datetime('now'), datetime('now'), '[\"langmap\"]', 'ai', 'approved')"
                )
                
                # Flush buffer if it reaches batch size
                if len(expressions_buffer) >= BATCH_SIZE:
                    flush_expressions_buffer()
            
            
            # We'll let the database handle duplicate link detection through constraints
            em_id_content = f"{expression_id}|{meaning_id}"
            em_id = stable_hash_id(em_id_content)
            expression_meanings_buffer.append(
                f"({em_id}, {expression_id}, {meaning_id}, 'langmap', 'langmap', datetime('now'), datetime('now'))"
            )
            
            # Flush buffer if it reaches batch size
            if len(expression_meanings_buffer) >= BATCH_SIZE:
                flush_expression_meanings_buffer()
    
    # Flush remaining buffers
    flush_expressions_buffer()
    flush_expression_meanings_buffer()
    
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
        f.write("-- This script populates expressions, meanings, and expression_meanings tables\n")
        f.write("-- Uses UPSERT (INSERT ... ON CONFLICT ... DO UPDATE) to update existing rows or insert new ones\n\n")
        for statement in sql_statements:
            f.write(statement + '\n')
    
    print(f"SQL statements written to {output_path}")


if __name__ == "__main__":
    main()