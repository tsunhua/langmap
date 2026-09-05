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
      [--manifest scripts/db/state/backup/delta/<source>.manifest.json] \
      [--rows-per-insert 100] [--limit N]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sqlite3
import sys
from collections.abc import Iterator
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


def _iter_added_rows(
    connection: sqlite3.Connection,
    table: str,
    pk: list[str],
    columns: list[str],
    *,
    limit: int | None,
) -> Iterator[sqlite3.Row]:
    selected = ", ".join(
        f'current."{column}" AS "{column}"' for column in columns
    )
    same_primary_key = " AND ".join(
        f'previous."{column}" IS current."{column}"' for column in pk
    )
    ordered_primary_key = ", ".join(f'current."{column}"' for column in pk)
    sql = (
        f'SELECT {selected} FROM main."{table}" AS current '
        f'WHERE NOT EXISTS ('
        f'SELECT 1 FROM before_db."{table}" AS previous '
        f'WHERE {same_primary_key}'
        f') ORDER BY {ordered_primary_key}'
    )
    parameters: tuple[int, ...] = ()
    if limit is not None:
        sql += " LIMIT ?"
        parameters = (limit,)
    yield from connection.execute(sql, parameters)


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


def _sample_rows(
    connection: sqlite3.Connection,
    table: str,
    pk: list[str],
    columns: list[str],
    *,
    schema: str = "main",
    limit: int = 3,
) -> list[dict[str, object]]:
    selected = ", ".join(f'"{column}"' for column in columns)
    ordered_primary_key = ", ".join(f'"{column}"' for column in pk)
    rows = connection.execute(
        f'SELECT {selected} FROM {schema}."{table}" '
        f'ORDER BY {ordered_primary_key} LIMIT {limit}'
    )
    return [dict(row) for row in rows]


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def export_delta(
    before: Path,
    after: Path,
    output: Path,
    *,
    limit: int | None = None,
    rows_per_insert: int = 100,
    manifest: Path | None = None,
) -> dict[str, int]:
    if rows_per_insert < 1:
        raise ValueError("rows_per_insert must be positive")
    after_conn = _connect(after)
    before_conn = _connect(before)
    after_conn.execute("ATTACH DATABASE ? AS before_db", (str(before.resolve()),))
    counts: dict[str, int] = {}
    before_counts: dict[str, int] = {}
    after_counts: dict[str, int] = {}
    samples: dict[str, dict[str, list[dict[str, object]]]] = {
        "before": {},
        "after": {},
        "added": {},
    }
    try:
        with output.open("w", encoding="utf-8") as handle:
            handle.write("PRAGMA defer_foreign_keys=TRUE;\n")
            for table, pk in TABLES:
                before_columns = _table_columns(before_conn, table)
                columns = _table_columns(after_conn, table)
                if before_columns != columns:
                    raise ValueError(f"table {table} columns differ between before and after")
                missing_pk = [column for column in pk if column not in columns]
                if missing_pk:
                    raise ValueError(
                        f"table {table} missing pk columns: {', '.join(missing_pk)}"
                    )
                before_counts[table] = int(
                    before_conn.execute(f'SELECT COUNT(*) FROM "{table}"').fetchone()[0]
                )
                after_counts[table] = int(
                    after_conn.execute(f'SELECT COUNT(*) FROM main."{table}"').fetchone()[0]
                )
                samples["before"][table] = _sample_rows(
                    before_conn, table, pk, columns
                )
                samples["after"][table] = _sample_rows(
                    after_conn, table, pk, columns
                )
                count = 0
                batch: list[sqlite3.Row] = []
                added_samples: list[dict[str, object]] = []
                for row in _iter_added_rows(
                    after_conn,
                    table,
                    pk,
                    columns,
                    limit=limit,
                ):
                    batch.append(row)
                    if len(added_samples) < 3:
                        added_samples.append(dict(row))
                    count += 1
                    if len(batch) == rows_per_insert:
                        handle.write(_insert_statement(table, batch, columns) + "\n")
                        batch = []
                if batch:
                    handle.write(_insert_statement(table, batch, columns) + "\n")
                counts[table] = count
                samples["added"][table] = added_samples
            handle.write("PRAGMA defer_foreign_keys=FALSE;\n")
        if manifest is not None:
            manifest.parent.mkdir(parents=True, exist_ok=True)
            payload = {
                "schema_version": 1,
                "before_sha256": _sha256(before),
                "after_sha256": _sha256(after),
                "before_counts": before_counts,
                "after_counts": after_counts,
                "added_counts": counts,
                "samples": samples,
            }
            temporary = manifest.with_name(f".{manifest.name}.{os.getpid()}.tmp")
            temporary.write_text(
                json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
                encoding="utf-8",
            )
            os.replace(temporary, manifest)
    finally:
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
    parser.add_argument("--manifest", type=Path)
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
        manifest=args.manifest,
    )
    print(
        "exported " + ", ".join(f"{k}={v}" for k, v in counts.items()),
        flush=True,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
