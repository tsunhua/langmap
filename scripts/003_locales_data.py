#!/usr/bin/env python3
"""
Script to generate SQL insert statements from locale JSON files.
Populates expressions table.
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
    Generate SQL INSERT statements for expressions table.
    
    Args:
        locales: Dictionary mapping language codes to their JSON content
        
    Returns:
        List of SQL INSERT statements
    """
    sql_statements = []
    
    # Buffers for batch inserts
    expressions_buffer = []
    
    # Batch size
    BATCH_SIZE = 500
    
    # Get language region information
    language_region_info = get_language_region_info()
    
    # Track expressions to avoid duplicates
    processed_expressions = set()  # Set of expression_ids to avoid duplicates
    
    # Helper function to flush buffers for expressions
    def flush_expressions_buffer():
        if expressions_buffer:
            values_str = ",\n    ".join(expressions_buffer)
            sql_statements.append(
                f"INSERT INTO expressions (id, text, meaning_id, language_code, region_code, region_name, region_latitude, region_longitude, created_by, updated_by, created_at, updated_at, tags, source_type, review_status) VALUES\n    {values_str}\n"
                f"ON CONFLICT(id) DO UPDATE SET\n"
                f"    text=excluded.text,\n"
                f"    meaning_id=excluded.meaning_id,\n"
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
    
    # Process expressions for en-US (base language) first to establish expression_ids as meaning_ids
    en_us_content = locales.get('en-US', {})
    en_us_flat_content = flatten_dict(en_us_content)
    
    # Create a map of key_path to en-US expression_id (used as meaning_id for all translations)
    key_path_to_meaning_id = {}
    for key_path, text_value in en_us_flat_content.items():
        # Skip non-string values
        if not isinstance(text_value, str):
            continue
        
        # Skip strings with length <= 1
        if len(text_value.strip()) <= 1:
            continue
            
        # Create stable expression ID for en-US entries
        expression_id_content = f"{text_value}|en-US|{language_region_info.get('en-US', {}).get('region_code', '')}"
        expression_id = stable_hash_id(expression_id_content)
        key_path_to_meaning_id[key_path] = expression_id
    
    # Now process all languages
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
                
            # For en-US entries, meaning_id should be NULL
            # For other languages, use the en-US expression_id as meaning_id
            meaning_id = "NULL"
            if lang_code != 'en-US':
                meaning_id = key_path_to_meaning_id.get(key_path)
                if meaning_id is None:
                    continue
            
            # Create stable expression ID based on text, language_code and region_code
            expression_id_content = f"{text_value}|{lang_code}|{region_info.get('region_code', '')}"
            expression_id = stable_hash_id(expression_id_content)
            
            # Create expression entry if not exists
            if expression_id not in processed_expressions:
                processed_expressions.add(expression_id)
                
                # Insert into expressions table
                escaped_text = text_value.replace("'", "''")  # Escape single quotes
                escaped_key_path = key_path.replace("'", "''")  # Escape single quotes in key_path
                
                # Handle meaning_id for SQL
                meaning_id_str = "NULL" if meaning_id == "NULL" else str(meaning_id)
                
                expressions_buffer.append(
                    f"({expression_id}, '{escaped_text}', {meaning_id_str}, '{lang_code}', {region_code}, {region_name}, {region_latitude}, {region_longitude}, 'langmap', NULL, datetime('now'), NULL, '[\"{escaped_key_path}\"]', 'ai', 'approved')"
                )
                
                # Flush buffer if it reaches batch size
                if len(expressions_buffer) >= BATCH_SIZE:
                    flush_expressions_buffer()
    
    # Flush remaining buffers
    flush_expressions_buffer()
    
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
        f.write("-- This script populates expressions table\n")
        f.write("-- Uses UPSERT (INSERT ... ON CONFLICT ... DO UPDATE) to update existing rows or insert new ones\n\n")
        for statement in sql_statements:
            f.write(statement + '\n')
    
    print(f"SQL statements written to {output_path}")


if __name__ == "__main__":
    main()