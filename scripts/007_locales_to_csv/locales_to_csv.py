#!/usr/bin/env python3
"""
Script to convert JSON i18n files to CSV format compatible with phrase.csv
"""

import json
import csv
import os
from pathlib import Path
from collections import OrderedDict


def flatten_dict(d, parent_key='', sep='.'):
    """
    Flatten a nested dictionary structure to a single level with dot-separated keys
    """
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)


def read_locales(locales_dir):
    """
    Read all JSON files from locales directory and return flattened data
    """
    locales = {}
    locales_path = Path(locales_dir)
    
    for file_path in locales_path.glob("*.json"):
        locale_code = file_path.stem  # Get filename without extension
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            # Flatten the nested structure
            locales[locale_code] = flatten_dict(data)
    
    return locales


def convert_to_csv(locales, output_file):
    """
    Convert locales data to CSV format with columns: language, tags, source_type, collection_id
    """
    # Get all unique keys from all locales
    all_keys = set()
    for locale_data in locales.values():
        all_keys.update(locale_data.keys())
    
    # Sort keys for consistent output
    sorted_keys = sorted(all_keys)
    
    # Get locale codes and sort them
    locale_codes = sorted(locales.keys())
    
    # Prepare CSV header - for each language we need language, tags, source_type, collection_id
    header = []
    for code in locale_codes:
        header.extend([
            code,
            f"{code}_tags",
            f"{code}_source_type", 
            f"{code}_collection_id"
        ])
    
    # Write to CSV
    with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        
        # Write header
        writer.writerow(header)
        
        # Write data rows
        for key in sorted_keys:
            row = []
            for code in locale_codes:
                # Add the translation
                translation = locales[code].get(key, '')
                row.append(translation)
                
                # Add tags (the key itself)
                row.append(key)
                
                # Add source_type (fixed as "ai")
                row.append("ai")
                
                # Add collection_id (fixed as "1000000")
                row.append("1000000")
                
            writer.writerow(row)


def main():
    # Define paths
    script_dir = Path(__file__).parent
    project_root = script_dir.parent.parent
    locales_dir = project_root / "web" / "src" / "locales"
    output_file = script_dir / "locales_output.csv"
    
    print(f"Reading locales from: {locales_dir}")
    
    # Read locales data
    locales = read_locales(locales_dir)
    
    print(f"Found {len(locales)} locale files:")
    for code in sorted(locales.keys()):
        print(f"  - {code}")
    
    # Convert to CSV
    convert_to_csv(locales, output_file)
    
    print(f"CSV file created: {output_file}")


if __name__ == "__main__":
    main()