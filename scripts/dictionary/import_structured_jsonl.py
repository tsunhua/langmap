#!/usr/bin/env python3
"""Compatibility shim for the retired flat structured-JSONL importer."""

from __future__ import annotations

import sys

MESSAGE = "flat structured JSONL import is retired; use scripts/dictionary/manage.py stage and preview"


def main(argv: list[str] | None = None) -> int:
    print(MESSAGE, file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
