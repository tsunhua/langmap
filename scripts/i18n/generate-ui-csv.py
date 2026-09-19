#!/usr/bin/env python3
"""Validate and checksum the single wide UI-locale CSV source."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import tempfile
from pathlib import Path
from typing import Any


DEFAULT_CSV = Path(__file__).resolve().parent / "ui-locales.csv"
DEFAULT_MANIFEST = Path(__file__).resolve().parent / "ui-locales.manifest.json"


class UiCsvError(ValueError):
    """Raised when the UI locale wide CSV violates the canonical contract."""


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _headers(raw: list[str]) -> tuple[str, ...]:
    if len(raw) < 4 or raw[:2] != ["ENTRY_ID", "NOTE"]:
        raise UiCsvError("UI CSV must start with ENTRY_ID,NOTE and at least two locales")
    locales = tuple(item.removeprefix("LOCALE_") for item in raw[2:])
    if any(not locale or raw[index + 2] != f"LOCALE_{locale}" for index, locale in enumerate(locales)):
        raise UiCsvError("UI CSV columns must use LOCALE_<locale>")
    if len(locales) != len(set(locales)) or tuple(sorted(locales, key=lambda value: value.encode("utf-8"))) != locales:
        raise UiCsvError("UI locale columns must be unique and UTF-8 bytewise sorted")
    return locales


def normalize_csv(input_path: Path, output_path: Path) -> tuple[tuple[str, ...], int]:
    with input_path.open(encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle)
        try:
            header = next(reader)
        except StopIteration as exc:
            raise UiCsvError("UI CSV is empty") from exc
        locales = _headers(header)
        rows: list[tuple[str, str, tuple[str, ...]]] = []
        seen: set[str] = set()
        for line_number, row in enumerate(reader, 2):
            if len(row) != len(header) or not row[0].strip() or row[0] in seen:
                raise UiCsvError(f"row {line_number}: ENTRY_ID must be non-empty and unique")
            values = tuple(value.strip() for value in row[2:])
            if sum(bool(value) for value in values) < 2:
                raise UiCsvError(f"row {line_number}: at least two locale values are required")
            seen.add(row[0])
            rows.append((row[0].strip(), row[1].strip(), values))
    rows.sort(key=lambda item: item[0].encode("utf-8"))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        fd, name = tempfile.mkstemp(prefix=f".{output_path.name}.", suffix=".tmp", dir=output_path.parent)
        temporary = Path(name)
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
            writer = csv.writer(handle, lineterminator="\n")
            writer.writerow(("ENTRY_ID", "NOTE", *(f"LOCALE_{locale}" for locale in locales)))
            writer.writerows((entry_id, note, *values) for entry_id, note, values in rows)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, output_path)
        temporary = None
    finally:
        if temporary is not None:
            try:
                temporary.unlink()
            except FileNotFoundError:
                pass
    return locales, len(rows)


def write_manifest(
    manifest_path: Path,
    csv_path: Path,
    locales: tuple[str, ...],
    entry_count: int,
) -> dict[str, Any]:
    manifest: dict[str, Any] = {
        "manifest_version": 1,
        "source_key": "system-ui",
        "csv": csv_path.name,
        "csv_sha256": _sha256(csv_path),
        "entry_count": entry_count,
        "locales": list(locales),
        "locale_metadata": {},
        "source_type": "ui",
        "source_name": "langmap-web",
        "exporter_version": "langmap-ui-wide-csv/1",
    }
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    temporary: Path | None = None
    try:
        fd, name = tempfile.mkstemp(prefix=f".{manifest_path.name}.", suffix=".tmp", dir=manifest_path.parent)
        temporary = Path(name)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(manifest, handle, ensure_ascii=False, sort_keys=True, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, manifest_path)
        temporary = None
    finally:
        if temporary is not None:
            try:
                temporary.unlink()
            except FileNotFoundError:
                pass
    return manifest


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=DEFAULT_CSV)
    parser.add_argument("--output", type=Path, default=DEFAULT_CSV)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    args = parser.parse_args(argv)
    try:
        locales, entry_count = normalize_csv(args.input, args.output)
        manifest = write_manifest(args.manifest, args.output, locales, entry_count)
    except (OSError, UiCsvError) as exc:
        parser.error(str(exc))
    print(json.dumps(manifest, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
