#!/usr/bin/env python3
"""Audit Structured JSONL expression surfaces without mutating any source."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts"))

from dictionary.langmap_dictionary.source_surface_audit import audit_directory  # noqa: E402


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--sample-limit", type=int, default=5)
    parser.add_argument(
        "--sample-entries",
        type=int,
        help="read only a deterministic head/middle/tail sample per file",
    )
    parser.add_argument("--only", action="append", default=[])
    parser.add_argument("--output", type=Path)
    args = parser.parse_args(argv)
    if args.sample_limit < 1:
        parser.error("--sample-limit must be positive")
    if args.sample_entries is not None and args.sample_entries < 1:
        parser.error("--sample-entries must be positive")
    report = audit_directory(
        args.directory,
        sample_limit=args.sample_limit,
        sample_entries=args.sample_entries,
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
