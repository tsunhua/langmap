#!/usr/bin/env python3
"""Export canonical dictionary INSERT OR IGNORE SQL from a post-import local D1.

Diff the canonical dictionary tables between a pre-import snapshot SQLite and the
current local D1, and emit the newly added rows as explicit-integer-ID
batched ``INSERT OR IGNORE`` statements in foreign-key order. Because the local D1 is
rebuilt from the production export before import, the integer IDs in the delta
are exactly the IDs production will accept without collision.

Table order (FK-safe):
  sources -> language_locales -> expressions -> expression_sources
  -> expression_locale_links -> expression_readings -> expression_edges
  -> expression_edge_sources

Usage:
  python3 scripts/db/export_dictionary_delta.py \
      --before <snapshot.sqlite> --after <local.sqlite> \
      --output scripts/db/state/backup/delta/<source>.sql \
      [--rows-per-insert 100] [--limit N]
"""

from __future__ import annotations

import argparse
import sqlite3
import sys
from pathlib import Path


# (table, pk columns) in FK dependency order; only tables owning immutable,
# auto-assigned identity or composite dictionary data may appear.
TABLES: list[tuple[str, list[str]]] = [
    ("sources", ["id"]),
    ("language_locales", ["id"]),
    ("expressions", ["id"]),
    ("expression_sources", ["expression_id", "source_id", "source_marker"]),
    ("expression_locale_links", ["expression_id", "locale_id"]),
    ("expression_readings", ["expression_id", "locale_id", "scheme", "value"]),
    ("expression_edges", ["id"]),
    ("expression_edge_sources", ["edge_id", "source_id", "source_marker"]),
]


def _connect(path: Path) -> sqlite3.Connection:
    connection = sqlite3.connect(path, timeout=60)
    connection.row_factory = sqlite3.Row
    return connection


def _table_columns(connection: sqlite3.Connection, table: str) -> list[str]:
    return [str(row["name"]) for row in connection.execute(f"PRAGMA table_info({table})")]


def _rows_by_pk(
    connection: sqlite3.Connection, table: str, pk: list[str]
) -> dict[tuple, sqlite3.Row]:
    columns = _table_columns(connection, table)
    ordered = ", ".join(f'"{column}"' for column in columns)
    rows: dict[tuple, sqlite3.Row] = {}
    for row in connection.execute(f'SELECT {ordered} FROM "{table}"'):
        for column in pk:
            if column not in row.keys():
                raise ValueError(f"table {table} missing pk column {column}")
        rows[tuple(row[column] for column in pk)] = row
    return rows


def _literal(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return repr(value)
    return "'" + str(value).replace("'", "''") + "'"


def _splat(row: sqlite3.Row, columns: list[str]) -> str:
    return ", ".join(_literal(row[column]) for column in columns)


def _insert_statement(
    table: str, rows: list[sqlite3.Row], columns: list[str]
) -> str:
    names = ", ".join(f'"{column}"' for column in columns)
    values = ",\n  ".join(f"({_splat(row, columns)})" for row in rows)
    return f'INSERT OR IGNORE INTO "{table}" ({names}) VALUES\n  {values};'


def export_delta(
    before: Path,
    after: Path,
    output: Path,
    *,
    limit: int | None = None,
    rows_per_insert: int = 100,
) -> dict[str, int]:
    if rows_per_insert < 1:
        raise ValueError("rows_per_insert must be positive")
    before_conn = _connect(before)
    after_conn = _connect(after)
    counts: dict[str, int] = {}
    with output.open("w", encoding="utf-8") as handle:
        handle.write("PRAGMA defer_foreign_keys=TRUE;\n")
        for table, pk in TABLES:
            expected = _rows_by_pk(before_conn, table, pk)
            actual = _rows_by_pk(after_conn, table, pk)
            added = [actual[key] for key in sorted(actual) if key not in expected]
            if limit is not None and len(added) > limit:
                added = added[:limit]
            counts[table] = len(added)
            columns = _table_columns(after_conn, table)
            for offset in range(0, len(added), rows_per_insert):
                handle.write(
                    _insert_statement(
                        table, added[offset : offset + rows_per_insert], columns
                    )
                    + "\n"
                )
        handle.write("PRAGMA defer_foreign_keys=FALSE;\n")
    before_conn.close()
    after_conn.close()
    return counts


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before", required=True, type=Path)
    parser.add_argument("--after", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--limit", type=int)
    parser.add_argument("--rows-per-insert", type=int, default=100)
    args = parser.parse_args(argv)
    if not args.before.is_file() or not args.after.is_file():
        print("before/after sqlite files are required", file=sys.stderr)
        return 1
    args.output.parent.mkdir(parents=True, exist_ok=True)
    counts = export_delta(
        args.before,
        args.after,
        args.output,
        limit=args.limit,
        rows_per_insert=args.rows_per_insert,
    )
    print(
        "exported " + ", ".join(f"{k}={v}" for k, v in counts.items()),
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
