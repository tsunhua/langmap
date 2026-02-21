#!/usr/bin/env python3
"""
Fix incorrect translations in nan-x-cha.json by comparing with zh-TW.json

Workflow:
1. For each key in nan-x-cha.json, find its value
2. Search zh-TW.json for that value to find the key path
3. Use the same key path in old nan-x-cha.json to get correct value
4. If values differ, update nan-x-cha.json
"""

import json
from pathlib import Path
from typing import Dict, Optional

current_file = Path("web/src/locales/nan-x-cha.json")
zh_tw_file = Path("web/src/locales_old/zh-TW.json")
old_file = Path("web/src/locales_old/nan-x-cha.json")

with open(current_file, "r", encoding="utf-8") as f:
    nan_x_cha_data = json.load(f)

with open(zh_tw_file, "r", encoding="utf-8") as f:
    zh_tw_data = json.load(f)

with open(old_file, "r", encoding="utf-8") as f:
    old_nan_x_cha_data = json.load(f)


def find_key_by_value(data: Dict, target_value: str) -> Optional[str]:
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


matching_keys = []
replacements = {}

print("Analyzing nan-x-cha.json translations...")
print("=" * 80)
print(
    "Workflow: find value in zh-TW.json (by searching), use same key path in old nan-x-cha"
)
print("=" * 80)

for key, nan_value in nan_x_cha_data.items():
    if not isinstance(nan_value, str):
        continue

    print(f"\nKey: {key}")
    print(f"  Current value in nan-x-cha: {nan_value}")

    zh_key_path = find_key_by_value(zh_tw_data, nan_value)

    if not zh_key_path:
        print(f"  Value not found in zh-TW.json")
        continue

    matching_keys.append(key)
    print(f"  Found value in zh-TW.json at: {zh_key_path}")

    old_value = get_value_from_nested(old_nan_x_cha_data, zh_key_path)

    if not old_value:
        print(f"  Key path '{zh_key_path}' not found in old nan-x-cha.json")
        continue

    print(f"  Value from old nan-x-cha at {zh_key_path}: {old_value}")

    if old_value != nan_value:
        replacements[key] = {
            "current": nan_value,
            "correct": old_value,
            "source": zh_key_path,
        }
        print(f"  ✓ Will update to: {old_value}")
    else:
        print(f"  Value is the same, no update needed")

print("\n" + "=" * 80)
if not matching_keys:
    print("No keys found that match zh-TW.json values.")
    print("The nan-x-cha.json file appears to be correct.")
else:
    print(f"Found {len(matching_keys)} keys that match zh-TW.json exactly.")
    print(f"Found {len(replacements)} keys with available replacements.")

if replacements:
    print("\n" + "=" * 80)
    print("Applying replacements...")

    for key, value_map in replacements.items():
        nan_x_cha_data[key] = value_map["correct"]

    backup_file = current_file.with_suffix(".json.backup")
    with open(backup_file, "w", encoding="utf-8") as f:
        json.dump(nan_x_cha_data, f, ensure_ascii=False, indent=2)

    with open(current_file, "w", encoding="utf-8") as f:
        json.dump(nan_x_cha_data, f, ensure_ascii=False, indent=2)

    print(f"\n✓ Backup saved to: {backup_file}")
    print(f"✓ Updated file: {current_file}")
    print(f"\nTotal replacements applied: {len(replacements)}")

print("\n" + "=" * 80)
print(f"Total keys in file: {len(nan_x_cha_data)}")
print(f"Keys matching zh-TW.json: {len(matching_keys)}")
print(f"Replacements applied: {len(replacements)}")

if matching_keys:
    print("\nKeys that match zh-TW.json:")
    for key in sorted(matching_keys):
        marker = "✓ FIXED" if key in replacements else "✗ NO REPLACEMENT"
        print(f"  {marker}: {key}")
else:
    print("\nNo keys needed fixing.")
