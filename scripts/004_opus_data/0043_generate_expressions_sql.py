#!/usr/bin/env python3
"""
Script to generate SQL INSERT statements for the expressions table from merged CSV file.
"""

import csv
import os
import uuid
import json
from datetime import datetime

# Input file path
INPUT_CSV = "./gnome_pairs/merged_gnome_translations.csv"
OUTPUT_SQL = "./gnome_expressions.sql"

# Language mapping
LANGUAGE_MAPPING = {
    'en_GB': 'en-GB',
    'en_US': 'en-US',
    'es': 'es',
    'ja': 'ja',
    'zh_CN': 'zh-CN',
    'zh_TW': 'zh-TW'
}

# Region information for languages
LANGUAGE_REGIONS = {
    'en-GB': {
        'region_code': 'GB'
    },
    'en-US': {
        'region_code': 'US'
    },
    'es': {
        'region_code': 'ES'
    },
    'ja': {
        'region_code': 'JP'
    },
    'zh-CN': {
        'region_code': 'CN'
    },
    'zh-TW': {
        'region_code': 'TW'
    }
}

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

def escape_sql_string(value):
    """
    Escape single quotes in SQL strings.
    
    Args:
        value: String value to escape
        
    Returns:
        Escaped string
    """
    if value is None:
        return 'NULL'
    return "'" + str(value).replace("'", "''") + "'"

def generate_values_tuple(expression_id, text, language_code, meaning_id=None):
    """
    Generate SQL VALUES tuple for expressions table.
    
    Args:
        expression_id: Expression ID generated from stable_hash_id
        text: Expression text
        language_code: Language code
        region_info: Region information dictionary
        meaning_id: Associated en-US expression ID
        
    Returns:
        SQL VALUES tuple string
    """
    # Basic fields
    values = [
        str(expression_id),
        escape_sql_string(text),
        escape_sql_string(language_code),
        "'opus'",  # source_type
        "'approved'",
        "'system'",
        escape_sql_string("https://opus.nlpl.eu/GNOME/corpus/version/GNOME"),  # source_ref
        escape_sql_string(json.dumps(['opus', 'gnome']))  # tags
    ]
    
    # Add meaning_id if provided
    if meaning_id:
        values.append(str(meaning_id))
    else:
        values.append('NULL')
    
    # Add timestamp fields
    timestamp = datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S')
    values.append(f"'{timestamp}'")  # created_at
    
    # Generate VALUES tuple
    return f"({', '.join(values)})"

def main():
    """Main function to process CSV and generate SQL."""
    print("Processing merged CSV file...")
    
    # Read the CSV file
    with open(INPUT_CSV, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        
        # Open output SQL file
        with open(OUTPUT_SQL, 'w', encoding='utf-8') as sqlfile:
            # Write SQL header
            sqlfile.write("-- Generated SQL INSERT statements for expressions table\n")
            sqlfile.write(f"-- Generated on: {datetime.now().isoformat()}\n\n")
            
            count = 0
            en_us_expressions = {}  # Store en-US expressions with their IDs
            batch_values = []
            batch_size = 500
            base_fields = "id, text, language_code, source_type, review_status, created_by, source_ref, tags, meaning_id, created_at"
            
            # First pass: Process en-US expressions
            csvfile.seek(0)  # Reset file pointer
            next(reader)  # Skip header
            for row in reader:
                if row['en_US'].strip():
                    count += 1
                    # Generate values tuple for en-US
                    en_us_text = row['en_US']
                    expression_id = stable_hash_id(en_us_text)
                    values_tuple = generate_values_tuple(
                        expression_id,
                        en_us_text,
                        'en-US',
                    )
                    batch_values.append(values_tuple)
                    
                    # Write batch if reached batch size
                    if len(batch_values) >= batch_size:
                        sqlfile.write(f"INSERT OR IGNORE INTO expressions ({base_fields}) VALUES\n")
                        sqlfile.write(',\n'.join(batch_values) + ';\n\n')
                        batch_values = []
                        print(f"Written {count} en-US expressions...")
                    
                    # Store the ID and text for reference
                    en_us_expressions[en_us_text] = expression_id
            
            # Write remaining en-US statements
            if batch_values:
                sqlfile.write(f"INSERT OR IGNORE INTO expressions ({base_fields}) VALUES\n")
                sqlfile.write(',\n'.join(batch_values) + ';\n\n')
                batch_values = []
            
            print(f"Processed {count} en-US expressions")
            
            # Second pass: Process all languages
            csvfile.seek(0)  # Reset file pointer
            next(reader)  # Skip header
            total_count = count
            
            for row in reader:
                # Process each language
                for csv_col, lang_code in LANGUAGE_MAPPING.items():
                    text = row[csv_col].strip()
                    if text and lang_code != 'en-US':  # Skip en-US as we already processed it
                        total_count += 1
                        
                        # Find associated en-US meaning ID
                        meaning_id = None
                        en_us_text = row['en_US'].strip()
                        # print(f"Looking up en-US meaning ID for '{en_us_text}'...")
                        if en_us_text and en_us_text in en_us_expressions:
                            meaning_id = en_us_expressions[en_us_text]
                        
                        # Generate expression ID
                        expression_id = stable_hash_id(text)
                        
                        # Generate values tuple
                        values_tuple = generate_values_tuple(
                            expression_id,
                            text,
                            lang_code,
                            meaning_id=meaning_id,
                        )
                        batch_values.append(values_tuple)
                        
                        # Write batch if reached batch size
                        if len(batch_values) >= batch_size:
                            sqlfile.write(f"INSERT OR IGNORE INTO expressions ({base_fields}) VALUES\n")
                            sqlfile.write(',\n'.join(batch_values) + ';\n\n')
                            batch_values = []
                            print(f"Written {total_count} total expressions...")
            
            # Write remaining statements
            if batch_values:
                sqlfile.write(f"INSERT OR IGNORE INTO expressions ({base_fields}) VALUES\n")
                sqlfile.write(',\n'.join(batch_values) + ';\n\n')
            
            print(f"Generated {total_count} INSERT statements")
            print(f"Output written to {OUTPUT_SQL}")

if __name__ == "__main__":
    main()