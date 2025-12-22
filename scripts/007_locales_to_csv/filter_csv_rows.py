#!/usr/bin/env python3
"""
Script to filter rows from locales_output.csv based on keys in amend.csv
"""

import csv
from pathlib import Path


def read_amend_keys(amend_file):
    """Read the first column values from amend.csv"""
    keys = set()
    with open(amend_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)  # Skip header row
        for row in reader:
            if row:  # Make sure row is not empty
                keys.add(row[0])
    return keys


def filter_locales_output(locales_file, keys, output_file):
    """Filter rows from locales_output.csv that match keys and write to output.csv"""
    matched_rows = []
    
    with open(locales_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)  # Read header
        matched_rows.append(header)
        
        for row in reader:
            if row and len(row) > 0 and row[0] in keys:  # Check if first column is in our keys set
                matched_rows.append(row)
    
    # Write matched rows to output file
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerows(matched_rows)
    
    return len(matched_rows) - 1  # Subtract 1 for header


def main():
    # Define file paths relative to the script location
    script_dir = Path(__file__).parent
    amend_file = script_dir / "007_locales_to_csv" / "amend.csv"
    locales_file = script_dir / "007_locales_to_csv" / "locales_output.csv"
    output_file = script_dir / "007_locales_to_csv" / "output.csv"
    
    # Verify files exist
    if not amend_file.exists():
        print(f"Error: {amend_file} does not exist")
        return
    
    if not locales_file.exists():
        print(f"Error: {locales_file} does not exist")
        return
    
    # Read keys from amend.csv
    keys = read_amend_keys(amend_file)
    print(f"Found {len(keys)} unique keys in amend.csv")
    print("Keys:", list(keys)[:5], "..." if len(keys) > 5 else "")
    
    # Filter locales_output.csv based on these keys
    matched_count = filter_locales_output(locales_file, keys, output_file)
    
    print(f"Matched {matched_count} rows from locales_output.csv")
    print(f"Output written to {output_file}")


if __name__ == "__main__":
    main()