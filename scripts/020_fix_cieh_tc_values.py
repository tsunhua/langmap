#!/usr/bin/env python3
"""
Fix incorrect translations in cieh-tc.json by comparing with zh-TW.json

Simple workflow:
1. For each key in cieh-tc.json, find its value
2. Search zh-TW.json for that value to find the key path
3. Use the same key path in old cieh-tc.json to get correct value
4. If values differ, update cieh-tc.json

Example:
  - cieh-tc.json['email_address'] = "電子信箱"
  - Search zh-TW.json for "電子信箱", find it's at "login.email"
  - Get old cieh-tc.json['login.email'] = "郵箱地址"
  - Set cieh-tc.json['email_address'] = "郵箱地址"
"""

import json
from pathlib import Path
from typing import Dict, Optional

# File paths
current_file = Path("web/src/locales/cieh-tc.json")
zh_tw_file = Path("web/src/locales_old/zh-TW.json")
old_file = Path("web/src/locales_old/cieh-tc.json")

# Load JSON files
with open(current_file, "r", encoding="utf-8") as f:
    cieh_tc_data = json.load(f)

with open(zh_tw_file, "r", encoding="utf-8") as f:
    zh_tw_data = json.load(f)

with open(old_file, "r", encoding="utf-8") as f:
    old_cieh_tc_data = json.load(f)


def find_key_by_value(data: Dict, target_value: str) -> Optional[str]:
    """
    Search through all keys in data (including nested) to find where target_value is located.
    Returns the key path as a string like 'login.email'.
    """

    def _search(d, path):
        for key, value in d.items():
            new_path = f"{path}.{key}" if path else key
            if isinstance(value, dict):
                result = _search(value, new_path)
                if result:
                    return result
            elif isinstance(value, str) and value == target_value:
                return new_path
        return None

    return _search(data, "")


def get_value_from_nested(data: Dict, key: str) -> Optional[str]:
    """Get a value from a nested dictionary using a path like 'login.email'."""
    parts = key.split(".")
    current = data

    for part in parts:
        if isinstance(current, dict) and part in current:
            current = current[part]
        else:
            return None

    if isinstance(current, str):
        return current
    return None


# Find keys that match zh-TW.json values exactly
matching_keys = []
replacements = {}

print("Analyzing cieh-tc.json translations...")
print("=" * 80)
print(
    "Workflow: find value in zh-TW.json (by searching), use same key path in old cieh-tc"
)
print("=" * 80)

for key, cieh_value in cieh_tc_data.items():
    if not isinstance(cieh_value, str):
        continue

    print(f"\nKey: {key}")
    print(f"  Current value in cieh-tc: {cieh_value}")

    # Step 1: Find the key in zh-TW.json that has this value (by searching)
    zh_key_path = find_key_by_value(zh_tw_data, cieh_value)

    if not zh_key_path:
        print(f"  Value not found in zh-TW.json")
        continue

    matching_keys.append(key)
    print(f"  Found value in zh-TW.json at: {zh_key_path}")

    # Step 2: Get the value from old cieh-tc.json using the same key path
    old_value = get_value_from_nested(old_cieh_tc_data, zh_key_path)

    if not old_value:
        print(f"  Key path '{zh_key_path}' not found in old cieh-tc.json")
        continue

    print(f"  Value from old cieh-tc at {zh_key_path}: {old_value}")

    # Step 3: If values differ, apply the replacement
    if old_value != cieh_value:
        replacements[key] = {
            "current": cieh_value,
            "correct": old_value,
            "source": zh_key_path,
        }
        print(f"  ✓ Will update to: {old_value}")
    else:
        print(f"  Value is the same, no update needed")

print("\n" + "=" * 80)
if not matching_keys:
    print("No keys found that match zh-TW.json values.")
    print("The cieh-tc.json file appears to be correct.")
else:
    print(f"Found {len(matching_keys)} keys that match zh-TW.json exactly.")
    print(f"Found {len(replacements)} keys with available replacements.")

if replacements:
    print("\n" + "=" * 80)
    print("Applying replacements...")

    # Apply replacements
    for key, value_map in replacements.items():
        cieh_tc_data[key] = value_map["correct"]

    # Save backup
    backup_file = current_file.with_suffix(".json.backup")
    with open(backup_file, "w", encoding="utf-8") as f:
        json.dump(cieh_tc_data, f, ensure_ascii=False, indent=2)

    # Save corrected file
    with open(current_file, "w", encoding="utf-8") as f:
        json.dump(cieh_tc_data, f, ensure_ascii=False, indent=2)

    print(f"\n✓ Backup saved to: {backup_file}")
    print(f"✓ Updated file: {current_file}")
    print(f"\nTotal replacements applied: {len(replacements)}")

# Show a summary of all keys found
print("\n" + "=" * 80)
print(f"Total keys in file: {len(cieh_tc_data)}")
print(f"Keys matching zh-TW.json: {len(matching_keys)}")
print(f"Replacements applied: {len(replacements)}")

if matching_keys:
    print("\nKeys that match zh-TW.json:")
    for key in sorted(matching_keys):
        marker = "✓ FIXED" if key in replacements else "✗ NO REPLACEMENT"
        print(f"  {marker}: {key}")
else:
    print("\nNo keys needed fixing.")
