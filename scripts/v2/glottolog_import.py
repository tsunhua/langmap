#!/usr/bin/env python3
"""Validate and import a pinned Glottolog CLDF languoid table.

The importer deliberately has no network capability.  A release archive is
downloaded and reviewed outside this script, then passed as a local CLDF/CSV
directory.  Running the same release twice is idempotent.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import sqlite3
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable

GLOTTOCODE = __import__('re').compile(r"^[a-z0-9]{8}$")
LEVELS = {"family", "language", "dialect"}


@dataclass(frozen=True)
class Languoid:
    id: str
    glottocode: str
    preferred_name: str
    level: str
    iso639_3: str | None
    parent_id: str | None
    latitude: float | None
    longitude: float | None
    source_version: str


def _value(row: dict[str, str], *names: str) -> str | None:
    for name in names:
        value = row.get(name)
        if value is not None and value.strip():
            return value.strip()
    return None


def read_languoids(csv_path: Path, source_version: str) -> list[Languoid]:
    with csv_path.open(newline="", encoding="utf-8-sig") as handle:
        rows = csv.DictReader(handle)
        if not rows.fieldnames:
            raise ValueError("languoid CSV has no header")
        result: list[Languoid] = []
        for number, row in enumerate(rows, 2):
            glottocode = (_value(row, "Glottocode", "glottocode") or "").lower()
            name = _value(row, "Name", "name", "preferred_name") or ""
            level = (_value(row, "Level", "level") or "").lower()
            # CLDF uses ID as a stable languoid identifier; prefer glottocode
            # when the fixture does not provide a separate identifier.
            ident = _value(row, "ID", "id") or f"glotto:{glottocode}"
            parent = _value(row, "Parent_ID", "Parent", "parent_id", "parent")
            if parent and not parent.startswith("glotto:"):
                parent = f"glotto:{parent}"
            iso = _value(row, "ISO639P3code", "iso639_3", "ISO639-3")
            lat = _number(_value(row, "Latitude", "latitude"), number, "latitude")
            lon = _number(_value(row, "Longitude", "longitude"), number, "longitude")
            if not GLOTTOCODE.fullmatch(glottocode):
                raise ValueError(f"row {number}: invalid Glottocode {glottocode!r}")
            if not name or level not in LEVELS:
                raise ValueError(f"row {number}: name and level (family/language/dialect) are required")
            if not ident.startswith("glotto:"):
                ident = f"glotto:{ident}"
            result.append(Languoid(ident, glottocode, name, level, iso, parent, lat, lon, source_version))
    validate_languoids(result)
    by_id = {item.id: item for item in result}

    def depth(item: Languoid) -> int:
        value = 0
        current = item
        while current.parent_id:
            value += 1
            current = by_id[current.parent_id]
        return value

    # Parent-first gives deterministic output and works with SQLite foreign-key
    # enforcement enabled; id is the stable tie-break within one level.
    return sorted(result, key=lambda item: (depth(item), item.id))


def _number(value: str | None, row: int, field: str) -> float | None:
    if value is None:
        return None
    try:
        return float(value)
    except ValueError as exc:
        raise ValueError(f"row {row}: invalid {field} {value!r}") from exc


def validate_languoids(items: Iterable[Languoid]) -> None:
    rows = list(items)
    ids = [item.id for item in rows]
    codes = [item.glottocode for item in rows]
    if len(ids) != len(set(ids)):
        raise ValueError("duplicate languoid id")
    if len(codes) != len(set(codes)):
        raise ValueError("duplicate Glottocode")
    known = set(ids)
    for item in rows:
        if item.parent_id and item.parent_id not in known:
            raise ValueError(f"{item.id}: parent {item.parent_id} is absent")
        if item.parent_id == item.id:
            raise ValueError(f"{item.id}: cannot parent itself")
    # A release must not contain parent cycles.
    for item in rows:
        seen: set[str] = set()
        current = item
        while current.parent_id:
            if current.id in seen:
                raise ValueError(f"parent cycle includes {current.id}")
            seen.add(current.id)
            parent = next(node for node in rows if node.id == current.parent_id)
            current = parent


def release_manifest(
    items: list[Languoid],
    source_version: str,
    source_file: Path,
    source_url: str | None = None,
) -> dict:
    digest = hashlib.sha256(source_file.read_bytes()).hexdigest()
    manifest = {
        "source": "glottolog",
        "source_version": source_version,
        "format": "cldf-languoids-csv",
        "source_file": source_file.name,
        "sha256": digest,
        "row_count": len(items),
        "glottocode_count": len({item.glottocode for item in items}),
    }
    if source_url:
        manifest["source_url"] = source_url
    return manifest


def verify_sha256(source_file: Path, expected: str | None) -> str:
    """Return the digest and fail before parsing if a pinned checksum differs."""
    digest = hashlib.sha256(source_file.read_bytes()).hexdigest()
    if expected and digest.lower() != expected.strip().lower():
        raise ValueError(f"sha256 mismatch: expected {expected}, got {digest}")
    return digest


def release_diff(db: sqlite3.Connection, items: list[Languoid]) -> dict[str, int]:
    """Report identity changes without mutating the database."""
    current = {
        row[0]: (row[1], row[2], row[3], row[4])
        for row in db.execute(
            "SELECT id, glottocode, preferred_name, level, parent_id FROM languoids"
        )
    }
    incoming = {
        item.id: (item.glottocode, item.preferred_name, item.level, item.parent_id)
        for item in items
    }
    return {
        "added": len(set(incoming) - set(current)),
        "updated": sum(1 for key in set(incoming) & set(current) if incoming[key] != current[key]),
        "retired": len(set(current) - set(incoming)),
        "unchanged": sum(1 for key in set(incoming) & set(current) if incoming[key] == current[key]),
    }


def import_sqlite(db: sqlite3.Connection, items: list[Languoid], manifest: dict) -> dict[str, int]:
    """Upsert a release and retire rows missing from it, atomically."""
    diff = release_diff(db, items)
    db.execute("BEGIN")
    try:
        for item in items:
            db.execute(
                """INSERT INTO languoids
                (id, glottocode, preferred_name, level, iso639_3, parent_id,
                 latitude, longitude, status, source_version, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active', ?, CURRENT_TIMESTAMP)
                ON CONFLICT(id) DO UPDATE SET glottocode=excluded.glottocode,
                preferred_name=excluded.preferred_name, level=excluded.level,
                iso639_3=excluded.iso639_3, parent_id=excluded.parent_id,
                latitude=excluded.latitude, longitude=excluded.longitude,
                status='active', source_version=excluded.source_version,
                updated_at=CURRENT_TIMESTAMP""",
                (item.id, item.glottocode, item.preferred_name, item.level, item.iso639_3,
                 item.parent_id, item.latitude, item.longitude, item.source_version),
            )
        placeholders = ",".join("?" for _ in items) or "NULL"
        db.execute(f"UPDATE languoids SET status='retired', updated_at=CURRENT_TIMESTAMP WHERE id NOT IN ({placeholders})", tuple(item.id for item in items))
        db.commit()
    except Exception:
        db.rollback()
        raise
    return {
        **diff,
        "active": len(items),
        "retired_total": db.execute("SELECT COUNT(*) FROM languoids WHERE status='retired'").fetchone()[0],
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", type=Path, help="CLDF languoids.csv")
    parser.add_argument("--source-version", required=True)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--expected-sha256", help="checksum recorded by the pinned release artifact")
    parser.add_argument("--source-url", help="official release URL, recorded in the output manifest")
    parser.add_argument("--database", type=Path, help="SQLite/D1 export to update")
    args = parser.parse_args(argv)
    try:
        digest = verify_sha256(args.csv, args.expected_sha256)
        items = read_languoids(args.csv, args.source_version)
        manifest = release_manifest(items, args.source_version, args.csv, args.source_url)
        # Keep the checksum check visible in output even if the file is empty or
        # the caller only asks for validation.
        assert manifest["sha256"] == digest
        if args.manifest:
            args.manifest.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        if args.database:
            with sqlite3.connect(args.database) as db:
                print(json.dumps(import_sqlite(db, items, manifest), ensure_ascii=False))
        else:
            print(json.dumps(manifest, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, sqlite3.Error) as exc:
        print(f"glottolog-import: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
