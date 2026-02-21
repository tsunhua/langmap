#!/usr/bin/env python3
"""Convert nested locale files to flat format matching zh-TW.json structure."""

import json
from pathlib import Path
from typing import Dict, Set


def analyze_namespace_conversion(
    old_nested: dict, new_flat: dict, namespace: str
) -> tuple:
    """Analyze which keys from a namespace moved to flat vs kept with prefix."""
    old_keys = set(old_nested.keys())
    new_keys_with_prefix = set(
        k for k in new_flat.keys() if k.startswith(namespace.lower() + "_")
    )
    new_keys_flat = set(new_flat.keys()) - new_keys_with_prefix

    # Find which old keys are in new_flat (moved)
    moved = old_keys & new_keys_flat

    # Find which old keys are in new with prefix (kept)
    kept_prefix = old_keys & {
        k.replace(namespace.lower() + "_", "") for k in new_keys_with_prefix
    }

    return moved, kept_prefix, new_keys_with_prefix


def build_key_mapping(old_file: Path, ref_file: Path) -> Dict[str, str]:
    """Build mapping from old nested keys to new flat keys."""
    with open(old_file, "r", encoding="utf-8") as f:
        old_nested = json.load(f)
    with open(ref_file, "r", encoding="utf-8") as f:
        ref_flat = json.load(f)

    # Build reverse mapping: value -> key in ref
    # But careful: values may duplicate
    # Instead, analyze each namespace

    mapping = {}

    for namespace in old_nested.keys():
        if not isinstance(old_nested[namespace], dict):
            # Top-level value (like footer.copyright)
            # Check if it exists in ref with same key
            if namespace in ref_flat:
                mapping[f"{namespace}"] = namespace
            continue

        moved, kept, with_prefix_keys = analyze_namespace_conversion(
            old_nested[namespace], ref_flat, namespace
        )

        # Map moved keys
        for key in moved:
            mapping[f"{namespace}/{key}"] = key

        # Map kept keys
        for key in kept:
            mapping[f"{namespace}/{key}"] = f"{namespace.lower()}_{key}"

    return mapping


def convert_locale_file(lang: str, old_file: Path, new_file: Path, ref_file: Path):
    """Convert one locale file."""
    print(f"\n{'=' * 60}")
    print(f"Converting {lang}")
    print(f"{'=' * 60}")

    # Build key mapping from analysis of zh-TW
    # Use zh-TW old and zh-TW new to understand the pattern
    zh_tw_old_file = ref_file.parent.parent / "locales_old" / "zh-TW.json"
    mapping = build_key_mapping(zh_tw_old_file, ref_file)

    # Load old nested data
    with open(old_file, "r", encoding="utf-8") as f:
        old_nested = json.load(f)

    # Load reference to get all target keys
    with open(ref_file, "r", encoding="utf-8") as f:
        ref_flat = json.load(f)

    # Build new locale data
    new_data = {}
    used_old = 0
    used_ref = 0

    for ref_key in ref_flat.keys():
        found_in_old = False

        # Try to find translation in old file
        for namespace in old_nested.keys():
            if not isinstance(old_nested[namespace], dict):
                continue

            # Check if ref_key matches a key in this namespace
            if ref_key in old_nested[namespace]:
                new_data[ref_key] = old_nested[namespace][ref_key]
                used_old += 1
                found_in_old = True
                break

        # Check if ref_key matches a namespaced key
        # This handles cases where new has "home_title" from "home.title"
        if not found_in_old:
            for namespace in old_nested.keys():
                if not isinstance(old_nested[namespace], dict):
                    continue

                for old_key in old_nested[namespace]:
                    potential_new_key = f"{namespace.lower()}_{old_key}"
                    if ref_key == potential_new_key:
                        new_data[ref_key] = old_nested[namespace][old_key]
                        used_old += 1
                        found_in_old = True
                        break
                if found_in_old:
                    break

        # If not found in old, use reference
        if not found_in_old:
            new_data[ref_key] = ref_flat[ref_key]
            used_ref += 1

    # Sort and write
    sorted_data = dict(sorted(new_data.items(), key=lambda x: x[0]))

    with open(new_file, "w", encoding="utf-8") as f:
        json.dump(sorted_data, f, ensure_ascii=False, indent=2)
        f.write("\n")

    print(f"  Total keys: {len(sorted_data)}")
    print(f"  From old: {used_old}")
    print(f"  From reference: {used_ref}")

    # Check for missing
    missing = set(ref_flat.keys()) - set(sorted_data.keys())
    if missing:
        print(f"  Missing: {len(missing)}")


def main():
    """Main conversion."""
    script_dir = Path(__file__).parent
    locales_dir = script_dir.parent / "web" / "src" / "locales"
    old_locales_dir = locales_dir.parent / "locales_old"

    ref_file = locales_dir / "zh-TW.json"

    files = [
        ("cieh-tc", old_locales_dir / "cieh-tc.json", locales_dir / "cieh-tc.json"),
        (
            "nan-x-cha",
            old_locales_dir / "nan-x-cha.json",
            locales_dir / "nan-x-cha.json",
        ),
    ]

    for lang, old, new in files:
        convert_locale_file(lang, old, new, ref_file)

    print(f"\n{'=' * 60}")
    print("Done!")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
