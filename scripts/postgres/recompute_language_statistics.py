#!/usr/bin/env python3
"""Recompute the derived ``language_statistics`` rows from the current data.

The per-language counters are counts over the live ``expressions``,
``language_locales`` and ``ui_locales`` tables, so this script is the last
step of a data release — after every expression-adding import and handbook
rebuild.  It is idempotent: rows are upserted by ``language_id``.

Usage::

    export DATABASE_URL=postgresql://langmap@127.0.0.1/langmap_fresh
    python scripts/postgres/recompute_language_statistics.py
"""

from __future__ import annotations

import argparse
import os
from typing import Any

_RECOMPUTE_SQL = """
    INSERT INTO language_statistics (language_id, expression_count, locale_count, active_ui_locale_count, updated_at)
    SELECT l.id,
           (SELECT count(*) FROM expressions e WHERE e.language_id = l.id),
           (SELECT count(*) FROM language_locales ll WHERE ll.language_id = l.id),
           (SELECT count(*) FROM ui_locales ul JOIN language_locales ll ON ll.id = ul.locale_id WHERE ll.language_id = l.id),
           CURRENT_TIMESTAMP::text
    FROM languages l
    ON CONFLICT (language_id) DO UPDATE SET
      expression_count = excluded.expression_count,
      locale_count = excluded.locale_count,
      active_ui_locale_count = excluded.active_ui_locale_count,
      updated_at = excluded.updated_at
"""


def connect(database_url: str):
    try:
        import psycopg
    except ImportError as exc:  # pragma: no cover - CLI environment
        raise RuntimeError("install psycopg[binary] to recompute language statistics") from exc
    return psycopg.connect(database_url)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--database-url", default=os.environ.get("DATABASE_URL"),
                        help="target database; defaults to DATABASE_URL")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if not args.database_url:
        raise SystemExit("--database-url or DATABASE_URL is required")
    with connect(args.database_url) as target:
        with target.transaction():
            updated: int = target.execute(_RECOMPUTE_SQL).rowcount or 0
            total: Any = target.execute("SELECT count(*) FROM language_statistics").fetchone()[0]
        print(f"language_statistics upserted rows = {updated}; total rows = {total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())