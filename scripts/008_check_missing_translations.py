#!/usr/bin/env python3
"""
Script to check which keys exist in en-US.json but are missing in other language files.
"""

import os
import json
from pathlib import Path


def flatten_dict(d, parent_key='', sep='.'):
    """
    Flatten a nested dictionary structure to a single level with dot-separated keys.
    """
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)


def load_json_file(filepath):
    """
    Load and parse a JSON file.
    """
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def compare_translations(en_us_filepath, other_filepaths):
    """
    Compare translations and identify missing keys.
    """
    # Load the reference en-US translations
    en_us_data = load_json_file(en_us_filepath)
    en_us_flat = flatten_dict(en_us_data)
    en_us_keys = set(en_us_flat.keys())
    
    print("Keys in en-US:", len(en_us_keys))
    print("=" * 50)
    
    # Summary statistics
    total_missing = 0
    
    # Check each language file
    for filepath in other_filepaths:
        lang_data = load_json_file(filepath)
        lang_flat = flatten_dict(lang_data)
        lang_keys = set(lang_flat.keys())
        
        # Find missing keys
        missing_keys = en_us_keys - lang_keys
        total_missing += len(missing_keys)
        
        # Calculate completion percentage
        completion_pct = (1 - len(missing_keys) / len(en_us_keys)) * 100 if en_us_keys else 100
        
        filename = os.path.basename(filepath)
        print(f"\n{filename}:")
        print(f"  Total keys: {len(lang_keys)}")
        print(f"  Missing keys: {len(missing_keys)}")
        print(f"  Completion: {completion_pct:.1f}%")
        
        if missing_keys:
            print("  Missing translations:")
            for key in sorted(missing_keys):
                print(f"    - {key}")
        else:
            print("  ✓ All translations present")
    
    print("\n" + "=" * 50)
    print(f"Total missing translations across all languages: {total_missing}")


def main():
    locales_dir = Path(__file__).parent.parent / "web" / "src" / "locales"
    
    if not locales_dir.exists():
        print(f"Error: Locales directory not found at {locales_dir}")
        return
    
    en_us_filepath = locales_dir / "en-US.json"
    
    if not en_us_filepath.exists():
        print(f"Error: en-US.json not found at {en_us_filepath}")
        return
    
    # Get all JSON files except en-us.json
    other_filepaths = [
        f for f in locales_dir.iterdir() 
        if f.suffix == '.json' and f.name != 'en-US.json'
    ]
    
    if not other_filepaths:
        print("No other language files found")
        return
    
    compare_translations(en_us_filepath, other_filepaths)


if __name__ == "__main__":
    main()