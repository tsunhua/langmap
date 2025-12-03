#!/usr/bin/env python3
"""
Script to generate SQL insert statements for languages table.
Uses stable hash IDs for language_id based on language code.
"""

import json
import os
from typing import Dict, List, Any, Tuple


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


def generate_sql_inserts() -> List[str]:
    """
    Generate SQL INSERT statements for languages table.
    
    Returns:
        List of SQL INSERT statements
    """
    sql_statements = []
    
    # Language data - based on 002_d1_populate_languages.sql
    languages = [
        {
            'code': 'en-US',
            'name': 'English (New York)',
            'direction': 'ltr',
            'is_active': 1,
            'region_code': 'US',
            'region_name': 'New York',
            'region_latitude': 40.7128,
            'region_longitude': -74.0060
        },
        {
            'code': 'en-GB',
            'name': 'English (London)',
            'direction': 'ltr',
            'is_active': 0,
            'region_code': 'GB',
            'region_name': 'London',
            'region_latitude': 51.5074,
            'region_longitude': -0.1278
        },
        {
            'code': 'zh-CN',
            'name': '中文 (北京)',
            'direction': 'ltr',
            'is_active': 1,
            'region_code': 'CN',
            'region_name': '北京',
            'region_latitude': 39.9042,
            'region_longitude': 116.4074
        },
        {
            'code': 'zh-TW',
            'name': '中文 (台北)',
            'direction': 'ltr',
            'is_active': 1,
            'region_code': 'TW',
            'region_name': '台北',
            'region_latitude': 25.0330,
            'region_longitude': 121.5654
        },
        {
            'code': 'es',
            'name': 'Español',
            'direction': 'ltr',
            'is_active': 1,
            'region_code': 'ES',
            'region_name': 'Madrid',
            'region_latitude': 40.4168,
            'region_longitude': -3.7038
        },
        {
            'code': 'fr',
            'name': 'Français',
            'direction': 'ltr',
            'is_active': 1,
            'region_code': 'FR',
            'region_name': 'Paris',
            'region_latitude': 48.8566,
            'region_longitude': 2.3522
        },
        {
            'code': 'ja',
            'name': '日本語',
            'direction': 'ltr',
            'is_active': 1,
            'region_code': 'JP',
            'region_name': '東京',
            'region_latitude': 35.6762,
            'region_longitude': 139.6503
        },
        {
            'code': 'ko',
            'name': '한국어',
            'direction': 'ltr',
            'is_active': 0,
            'region_code': 'KR',
            'region_name': '서울',
            'region_latitude': 37.5665,
            'region_longitude': 126.9780
        },
        {
            'code': 'ar',
            'name': 'العربية',
            'direction': 'rtl',
            'is_active': 0,
            'region_code': 'EG',
            'region_name': 'القاهرة',
            'region_latitude': 30.0444,
            'region_longitude': 31.2357
        },
        {
            'code': 'pt',
            'name': 'Português',
            'direction': 'ltr',
            'is_active': 0,
            'region_code': 'PT',
            'region_name': 'Lisboa',
            'region_latitude': 38.7223,
            'region_longitude': -9.1393
        },
        {
            'code': 'ru',
            'name': 'Русский',
            'direction': 'ltr',
            'is_active': 0,
            'region_code': 'RU',
            'region_name': 'Москва',
            'region_latitude': 55.7558,
            'region_longitude': 37.6176
        },
        {
            'code': 'de',
            'name': 'Deutsch',
            'direction': 'ltr',
            'is_active': 0,
            'region_code': 'DE',
            'region_name': 'Berlin',
            'region_latitude': 52.5200,
            'region_longitude': 13.4050
        },
        {
            'code': 'hi',
            'name': 'हिन्दी',
            'direction': 'ltr',
            'is_active': 0,
            'region_code': 'IN',
            'region_name': 'नई दिल्ली',
            'region_latitude': 28.6139,
            'region_longitude': 77.2090
        },
        {
            'code': 'it',
            'name': 'Italiano',
            'direction': 'ltr',
            'is_active': 0,
            'region_code': 'IT',
            'region_name': 'Roma',
            'region_latitude': 41.9028,
            'region_longitude': 12.4964
        },
        {
            'code': 'nan-TW',
            'name': '閩南語 (台北)',
            'direction': 'ltr',
            'is_active': 1,
            'region_code': 'TW',
            'region_name': '台北',
            'region_latitude': 25.0330,
            'region_longitude': 121.5654
        },
        {
            'code': 'yue-HK',
            'name': '粵語 (香港)',
            'direction': 'ltr',
            'is_active': 1,
            'region_code': 'HK',
            'region_name': '香港',
            'region_latitude': 22.3964,
            'region_longitude': 114.1095
        }
    ]
    
    # Generate INSERT statements with stable hash IDs
    values_list = []
    for lang in languages:
        # Generate stable ID based on language code
        lang_id = stable_hash_id(lang['code'])
        
        # Escape single quotes in string values
        name = lang['name'].replace("'", "''")
        region_name = lang['region_name'].replace("'", "''")
        
        values_list.append(
            f"({lang_id}, '{lang['code']}', '{name}', '{lang['direction']}', {lang['is_active']}, "
            f"'{lang['region_code']}', '{region_name}', {lang['region_latitude']}, {lang['region_longitude']}, "
            f"'langmap', 'langmap', datetime('now'), datetime('now'))"
        )
    
    # Create the full INSERT statement
    values_str = ",\n".join(values_list)
    sql_statement = (
        f"INSERT INTO languages (id, code, name, direction, is_active, region_code, region_name, "
        f"region_latitude, region_longitude, created_by, updated_by, created_at, updated_at) VALUES\n"
        f"{values_str}\n"
        f"ON CONFLICT(code) DO UPDATE SET\n"
        f"    name=excluded.name,\n"
        f"    direction=excluded.direction,\n"
        f"    is_active=excluded.is_active,\n"
        f"    region_code=excluded.region_code,\n"
        f"    region_name=excluded.region_name,\n"
        f"    region_latitude=excluded.region_latitude,\n"
        f"    region_longitude=excluded.region_longitude,\n"
        f"    updated_by=excluded.updated_by,\n"
        f"    updated_at=excluded.updated_at;"
    )
    
    sql_statements.append(sql_statement)
    return sql_statements


def main():
    """Main function to generate SQL from language data."""
    output_file = '002_populate_languages.sql'
    
    # Generate SQL statements
    print("Generating SQL INSERT statements...")
    sql_statements = generate_sql_inserts()
    print(f"Generated {len(sql_statements)} SQL statements")
    
    # Write to output file
    output_path = os.path.join(output_file)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("-- Auto-generated SQL script for languages table\n")
        f.write("-- Uses stable hash IDs for language_id based on language code\n")
        f.write("-- Uses UPSERT (INSERT ... ON CONFLICT ... DO UPDATE) to update existing rows or insert new ones\n\n")
        for statement in sql_statements:
            f.write(statement + '\n')
    
    print(f"SQL statements written to {output_path}")


if __name__ == "__main__":
    main()