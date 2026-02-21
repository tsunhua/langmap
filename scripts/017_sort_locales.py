#!/usr/bin/env python3
"""Sort locale JSON files alphabetically by key."""

import json
import os
from pathlib import Path


def sort_locale_file(file_path: Path):
    """Sort keys in a locale JSON file and write it back."""
    print(f"Processing {file_path.name}...")

    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Sort keys alphabetically
    sorted_data = dict(sorted(data.items(), key=lambda x: x[0]))

    # Write back with pretty formatting (2-space indentation)
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(sorted_data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"  Sorted {len(sorted_data)} keys")


def main():
    """Process all locale JSON files."""
    # Get the script's directory and navigate to web/src/locales
    script_dir = Path(__file__).parent
    locales_dir = script_dir.parent / "web" / "src" / "locales"

    if not locales_dir.exists():
        print(f"Error: Locales directory not found at {locales_dir}")
        return

    # Find all JSON files
    json_files = sorted(locales_dir.glob("*.json"))

    if not json_files:
        print("No JSON files found in locales directory")
        return

    print(f"Found {len(json_files)} locale files")

    for file_path in json_files:
        sort_locale_file(file_path)

    print("\nDone!")


if __name__ == "__main__":
    main()
