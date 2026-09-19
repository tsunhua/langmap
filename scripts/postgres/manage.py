#!/usr/bin/env python3
"""Apply the PostgreSQL baseline and checksum-locked migrations."""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def connect(url: str):
    try:
        import psycopg
    except ImportError as exc:
        raise SystemExit("install psycopg[binary] before using the PostgreSQL manager") from exc
    return psycopg.connect(url)


def execute_file(connection, path: Path) -> None:
    connection.execute(path.read_text(encoding="utf-8"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("init", "migrate"))
    parser.add_argument("--database-url", default=os.environ.get("DATABASE_URL"))
    parser.add_argument("--schema", type=Path, default=Path("backend/postgres/schema.sql"))
    parser.add_argument("--seed", type=Path, default=Path("backend/postgres/seed.sql"))
    parser.add_argument("--migration-dir", type=Path, default=Path("backend/postgres/migrations"))
    args = parser.parse_args(argv)
    if not args.database_url:
        parser.error("--database-url or DATABASE_URL is required")
    with connect(args.database_url) as connection:
        if args.action == "init":
            execute_file(connection, args.schema)
            execute_file(connection, args.seed)
            connection.execute("CREATE TABLE IF NOT EXISTS schema_migrations (filename text PRIMARY KEY, sha256 text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now())")
        else:
            connection.execute("CREATE TABLE IF NOT EXISTS schema_migrations (filename text PRIMARY KEY, sha256 text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now())")
            for path in sorted(args.migration_dir.glob("*.sql")):
                digest = sha256(path)
                row = connection.execute("SELECT sha256 FROM schema_migrations WHERE filename=%s", (path.name,)).fetchone()
                if row and row[0] != digest:
                    raise SystemExit(f"migration checksum changed: {path.name}")
                if row:
                    continue
                execute_file(connection, path)
                connection.execute("INSERT INTO schema_migrations(filename, sha256) VALUES (%s,%s)", (path.name, digest))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
