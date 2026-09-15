#!/usr/bin/env python3
"""Rank bounded Structured JSONL source samples by compiled correctness."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

from dictionary.langmap_dictionary.source_surface_audit import (  # noqa: E402
    compiled_audit_directory,
)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--sample-entries", type=int, default=100)
    parser.add_argument("--sample-limit", type=int, default=10)
    parser.add_argument("--only", action="append", default=[])
    parser.add_argument("--output", type=Path)
    args = parser.parse_args(argv)
    if args.sample_entries < 1:
        parser.error("--sample-entries must be positive")
    if args.sample_limit < 1:
        parser.error("--sample-limit must be positive")
    report = compiled_audit_directory(
        args.directory,
        sample_entries=args.sample_entries,
        sample_limit=args.sample_limit,
        only=args.only,
    )
    encoded = json.dumps(report, ensure_ascii=False, sort_keys=True, indent=2) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(encoded, encoding="utf-8")
    else:
        print(encoded, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
