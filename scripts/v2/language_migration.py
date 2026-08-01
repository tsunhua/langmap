#!/usr/bin/env python3
"""Validate the one-time legacy language-code migration manifest."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

TAG = re.compile(r"^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*(?:-x-[a-z0-9]{8})?$")


def validate_manifest(manifest: dict, observed_codes: set[str] | None = None) -> list[str]:
    errors: list[str] = []
    mappings = manifest.get("mappings")
    if not isinstance(mappings, dict) or not mappings:
        return ["mappings must be a non-empty object"]
    targets: dict[str, str] = {}
    for old, entry in mappings.items():
        if not isinstance(old, str) or not old.strip():
            errors.append("legacy code must be a non-empty string")
            continue
        if not isinstance(entry, dict) or entry.get("action") not in {"keep", "canonicalize", "map-to-glottolog", "manual-review"}:
            errors.append(f"{old}: action must be keep/canonicalize/map-to-glottolog/manual-review")
            continue
        target = entry.get("canonical")
        if entry["action"] == "manual-review":
            if target is not None:
                errors.append(f"{old}: manual-review cannot have canonical target")
            continue
        if not isinstance(target, str) or not TAG.fullmatch(target):
            errors.append(f"{old}: canonical must be a BCP47 tag")
            continue
        if target in targets and targets[target] != old:
            previous = mappings[targets[target]]
            if entry["action"] != "canonicalize" or previous.get("action") != "canonicalize":
                errors.append(f"duplicate canonical target {target}: {targets[target]} and {old}")
        else:
            targets[target] = old
    if observed_codes:
        missing = sorted(observed_codes - set(mappings))
        if missing:
            errors.append("unmapped observed codes: " + ", ".join(missing))
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path)
    parser.add_argument("--codes", type=Path, help="JSON array or newline-separated observed codes")
    args = parser.parse_args(argv)
    try:
        data = json.loads(args.manifest.read_text(encoding="utf-8"))
        observed: set[str] | None = None
        if args.codes:
            raw = args.codes.read_text(encoding="utf-8")
            try:
                parsed = json.loads(raw)
                observed = set(parsed) if isinstance(parsed, list) else set()
            except json.JSONDecodeError:
                observed = {line.strip() for line in raw.splitlines() if line.strip()}
        errors = validate_manifest(data, observed)
        if errors:
            print("\n".join(f"migration-manifest: {error}" for error in errors), file=sys.stderr)
            return 2
        print(json.dumps({"valid": True, "mapping_count": len(data["mappings"])}, ensure_ascii=False))
        return 0
    except (OSError, json.JSONDecodeError, TypeError) as exc:
        print(f"migration-manifest: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
