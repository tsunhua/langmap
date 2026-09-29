#!/usr/bin/env python3
"""Import the LangMap V1 application tables into the current database.

The dictionary content of the new database is rebuilt from the 333 registry
sources, so V1's ``expressions``/``expression_edges`` are not copied.  The
tables that carry genuine user and authored content have no such source and are
copied verbatim, preserving primary keys so inbound references stay valid:

- ``users`` and ``user_preferences``
- ``handbooks`` (all rows, ids preserved)
- ``handbook_sections`` and ``handbook_section_items`` for non-managed
  handbooks only — managed handbooks are rebuilt from source markers by
  ``build_wikivoyage_handbook.py``

The Jiazi handbook's 甲子話 vocabulary is not republished by the current
dictionary sources; it is recovered by ``import_v1_system_graph.py`` through its
V1 recovery source, so run that with ``nan-Hant-CN_LufengJiazi`` added to
``--scope-locales`` before rebuilding.  ``language_statistics`` is derived data:
recompute it last with ``recompute_language_statistics.py``.

Handbook section items are stored as ``(language_locale_id, text)`` in the new
database.  The locale comes from the item expression's own locale links, falling
back to the handbook's locale and then to any locale of the expression's
language; the text is the expression text itself.

The legacy database is only ever read.  Usage::

    export DATABASE_URL=postgresql://langmap@127.0.0.1/langmap_fresh
    python scripts/postgres/import_v1_app_tables.py \\
        --legacy-database-url postgresql://langmap@127.0.0.1/langmap \\
        --check
    python scripts/postgres/import_v1_app_tables.py \\
        --legacy-database-url postgresql://langmap@127.0.0.1/langmap \\
        --apply

Run ``build_wikivoyage_handbook.py`` afterwards to regenerate the managed
Wikivoyage handbook.
"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import asdict, dataclass, field
from typing import Any, Iterable, Sequence

_STAGING_TABLES = (
    "stage_users",
    "stage_preferences",
    "stage_handbooks",
    "stage_sections",
    "stage_items",
)

_LEGACY_HANDBOOKS_SQL = """
    SELECT h.id, h.user_id, h.title, h.visibility, h.status,
           l.code AS locale_code, h.score, h.created_at, h.updated_at, h.managed_key
    FROM handbooks h
    LEFT JOIN language_locales l ON l.id = h.language_locale_id
    ORDER BY h.id
"""

_LEGACY_SECTIONS_SQL = """
    SELECT s.id, s.handbook_id, s.title, s.position, s.parent_section_id
    FROM handbook_sections s
    JOIN handbooks h ON h.id = s.handbook_id
    WHERE h.managed_key IS NULL
    ORDER BY s.handbook_id, s.id
"""

# Locale fallback precedence mirrors the handbook_section_items migration: the
# expression's own locale links, then the handbook's locale, then any locale of
# the expression's language.  Subqueries avoid the PostgreSQL join planner bug
# that folds two equality predicates on one outer column into an identity test.
_LEGACY_ITEMS_SQL = """
    SELECT s.handbook_id, i.section_id, i.position,
           COALESCE(
               (SELECT link.locale_id
                  FROM expression_locale_links link
                 WHERE link.expression_id = i.expression_id
                 ORDER BY link.locale_id LIMIT 1),
               (SELECT handbook.language_locale_id
                  FROM handbook_sections sections
                  JOIN handbooks handbook ON handbook.id = sections.handbook_id
                 WHERE sections.id = i.section_id),
               (SELECT locale.id
                  FROM expressions expression
                  JOIN language_locales locale ON locale.language_id = expression.language_id
                 WHERE expression.id = i.expression_id
                 ORDER BY locale.id LIMIT 1)
           ) AS locale_id,
           (SELECT expression.text FROM expressions expression WHERE expression.id = i.expression_id) AS text
    FROM handbook_section_items i
    JOIN handbook_sections s ON s.id = i.section_id
    JOIN handbooks h ON h.id = s.handbook_id
    WHERE h.managed_key IS NULL
    ORDER BY s.handbook_id, i.section_id, i.position
"""


@dataclass(frozen=True)
class LegacyApp:
    users: tuple[tuple[int, str, str, str, str, int, str, str], ...]
    preferences: tuple[tuple[int, str, str, str], ...]
    handbooks: tuple[tuple[int, int, str, str, str, str | None, int, str, str, str | None], ...]
    sections: tuple[tuple[int, int, str, int, int | None], ...]
    items: tuple[tuple[int, int, int, int | None, str | None], ...]
    handbook_votes: int = 0


@dataclass
class Report:
    mode: str
    legacy: dict[str, Any] = field(default_factory=dict)
    check: dict[str, Any] = field(default_factory=dict)
    applied: dict[str, Any] = field(default_factory=dict)


def collect_legacy(legacy) -> LegacyApp:
    """Read the app tables out of the legacy database, read-only."""
    with legacy.transaction():
        legacy.execute("SET TRANSACTION READ ONLY")
        users = tuple(
            legacy.execute("SELECT id, username, email, password_hash, role, email_verified, created_at, updated_at FROM users ORDER BY id")
        )
        preferences = tuple(
            legacy.execute("SELECT user_id, preference_key, value_json, updated_at FROM user_preferences ORDER BY user_id, preference_key")
        )
        handbooks = tuple(legacy.execute(_LEGACY_HANDBOOKS_SQL))
        sections = tuple(legacy.execute(_LEGACY_SECTIONS_SQL))
        items = tuple(legacy.execute(_LEGACY_ITEMS_SQL))
        votes = int(
            legacy.execute("SELECT count(*) FROM handbook_votes").fetchone()[0]
        )
    return LegacyApp(
        users=users,
        preferences=preferences,
        handbooks=handbooks,
        sections=sections,
        items=items,
        handbook_votes=votes,
    )


def _create_staging(target, app: LegacyApp) -> None:
    for table in _STAGING_TABLES:
        target.execute(f"DROP TABLE IF EXISTS {table}")
    target.execute(
        "CREATE TEMP TABLE stage_users("
        " id BIGINT PRIMARY KEY, username TEXT, email TEXT, password_hash TEXT,"
        " role TEXT, email_verified BIGINT, created_at TEXT, updated_at TEXT) ON COMMIT DROP"
    )
    target.execute(
        "CREATE TEMP TABLE stage_preferences("
        " user_id BIGINT, preference_key TEXT, value_json TEXT, updated_at TEXT) ON COMMIT DROP"
    )
    target.execute(
        "CREATE TEMP TABLE stage_handbooks("
        " id BIGINT PRIMARY KEY, user_id BIGINT, title TEXT, visibility TEXT, status TEXT,"
        " locale_code TEXT, score BIGINT, created_at TEXT, updated_at TEXT, managed_key TEXT) ON COMMIT DROP"
    )
    target.execute(
        "CREATE TEMP TABLE stage_sections("
        " id BIGINT PRIMARY KEY, handbook_id BIGINT, title TEXT, position BIGINT, parent_section_id BIGINT) ON COMMIT DROP"
    )
    target.execute(
        "CREATE TEMP TABLE stage_items("
        " handbook_id BIGINT, section_id BIGINT, position BIGINT, language_locale_id BIGINT, text TEXT) ON COMMIT DROP"
    )
    with target.cursor() as cursor:
        _copy(cursor, "stage_users", app.users)
        _copy(cursor, "stage_preferences", app.preferences)
        _copy(cursor, "stage_handbooks", app.handbooks)
        _copy(cursor, "stage_sections", app.sections)
        _copy(cursor, "stage_items", app.items)


def _copy(cursor, table: str, rows: Iterable[Sequence[Any]]) -> None:
    with cursor.copy(f"COPY {table} FROM STDIN") as copy:
        for row in rows:
            copy.write_row(row)


def plan_target(target, app: LegacyApp) -> dict[str, Any]:
    """Compute the target-side gaps that --apply will close, without writing."""
    plan: dict[str, Any] = {}
    with target.transaction():
        _create_staging(target, app)
        plan["users"] = int(target.execute(
            "SELECT count(*) FROM stage_users s WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = s.id)"
        ).fetchone()[0])
        plan["preferences"] = int(target.execute(
            "SELECT count(*) FROM stage_preferences s"
            " WHERE NOT EXISTS (SELECT 1 FROM user_preferences u WHERE u.user_id = s.user_id AND u.preference_key = s.preference_key)"
        ).fetchone()[0])
        plan["handbooks"] = int(target.execute(
            "SELECT count(*) FROM stage_handbooks s WHERE NOT EXISTS (SELECT 1 FROM handbooks h WHERE h.id = s.id)"
        ).fetchone()[0])
        plan["sections"] = int(target.execute(
            "SELECT count(*) FROM stage_sections s WHERE NOT EXISTS (SELECT 1 FROM handbook_sections x WHERE x.id = s.id)"
        ).fetchone()[0])
        plan["items"] = int(target.execute(
            """
            SELECT count(*) FROM stage_items s
            WHERE NOT EXISTS (
                SELECT 1 FROM handbook_section_items i
                WHERE i.section_id = s.section_id AND i.language_locale_id = s.language_locale_id AND i.text = s.text)
            """
        ).fetchone()[0])
        plan["missing_locales"] = tuple(
            row[0]
            for row in target.execute(
                """
                SELECT DISTINCT s.locale_code
                FROM stage_handbooks s
                WHERE s.locale_code IS NOT NULL
                  AND NOT EXISTS (SELECT 1 FROM language_locales l WHERE l.code = s.locale_code)
                ORDER BY 1
                """
            ).fetchall()
        )
        plan["missing_item_locale_ids"] = tuple(
            row[0]
            for row in target.execute(
                """
                SELECT DISTINCT s.language_locale_id
                FROM stage_items s
                WHERE s.language_locale_id IS NOT NULL
                  AND NOT EXISTS (SELECT 1 FROM language_locales l WHERE l.id = s.language_locale_id)
                ORDER BY 1
                """
            ).fetchall()
        )
        plan["drop_item_locale_null"] = int(target.execute(
            "SELECT count(*) FROM stage_items WHERE language_locale_id IS NULL OR text IS NULL"
        ).fetchone()[0])
        plan["item_text_conflicts"] = int(target.execute(
            """
            SELECT count(*) FROM (
                SELECT section_id, language_locale_id, text
                FROM stage_items
                WHERE language_locale_id IS NOT NULL AND text IS NOT NULL
                GROUP BY section_id, language_locale_id, text
                HAVING count(*) > 1) conflicting
            """
        ).fetchone()[0])
        plan["items_resolvable"] = int(target.execute(
            """
            SELECT count(*) FROM stage_items s
            WHERE s.language_locale_id IS NOT NULL AND s.text IS NOT NULL
              AND EXISTS (
                  SELECT 1 FROM expressions e
                  JOIN expression_locale_links link ON link.expression_id = e.id AND link.locale_id = s.language_locale_id
                  WHERE e.text = s.text)
            """
        ).fetchone()[0])
    plan["items_total"] = int(len(app.items))
    return plan


def apply_target(target, app: LegacyApp) -> dict[str, Any]:
    """Write the staged app tables inside one transaction."""
    applied: dict[str, Any] = {}
    with target.transaction():
        _create_staging(target, app)
        applied["users"] = int(target.execute(
            """
            INSERT INTO users (id, username, email, password_hash, role, email_verified, created_at, updated_at)
            SELECT s.id, s.username, s.email, s.password_hash, s.role, s.email_verified, s.created_at, s.updated_at
            FROM stage_users s
            WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.id = s.id)
            ORDER BY s.id
            """
        ).rowcount or 0)
        applied["preferences"] = int(target.execute(
            """
            INSERT INTO user_preferences (user_id, preference_key, value_json, updated_at)
            SELECT s.user_id, s.preference_key, s.value_json, s.updated_at
            FROM stage_preferences s
            WHERE NOT EXISTS (
                SELECT 1 FROM user_preferences u WHERE u.user_id = s.user_id AND u.preference_key = s.preference_key)
            ORDER BY s.user_id, s.preference_key
            """
        ).rowcount or 0)
        applied["handbooks"] = int(target.execute(
            """
            INSERT INTO handbooks (id, user_id, title, visibility, status, language_locale_id, score, created_at, updated_at, managed_key)
            SELECT s.id, s.user_id, s.title, s.visibility, s.status, l.id, s.score, s.created_at, s.updated_at, s.managed_key
            FROM stage_handbooks s
            LEFT JOIN language_locales l ON l.code = s.locale_code
            WHERE NOT EXISTS (SELECT 1 FROM handbooks h WHERE h.id = s.id)
            ORDER BY s.id
            """
        ).rowcount or 0)
        applied["sections"] = int(target.execute(
            """
            INSERT INTO handbook_sections (id, handbook_id, title, position, parent_section_id)
            SELECT s.id, s.handbook_id, s.title, s.position, s.parent_section_id
            FROM stage_sections s
            WHERE NOT EXISTS (SELECT 1 FROM handbook_sections x WHERE x.id = s.id)
            ORDER BY s.id
            """
        ).rowcount or 0)
        applied["items"] = int(target.execute(
            """
            INSERT INTO handbook_section_items (section_id, position, language_locale_id, text)
            SELECT s.section_id, s.position, s.language_locale_id, s.text
            FROM stage_items s
            WHERE s.language_locale_id IS NOT NULL AND s.text IS NOT NULL
              AND NOT EXISTS (
                  SELECT 1 FROM handbook_section_items i
                  WHERE i.section_id = s.section_id AND i.language_locale_id = s.language_locale_id AND i.text = s.text)
            ORDER BY s.handbook_id, s.section_id, s.position
            """
        ).rowcount or 0)
        applied["statistics_recomputed"] = 0
        for table in ("users", "handbooks", "handbook_sections"):
            target.execute(
                f"SELECT setval(pg_get_serial_sequence('{table}', 'id'),"
                f" GREATEST((SELECT max(id) FROM {table}), 1))"
            )
    return applied


def connect(database_url: str):
    try:
        import psycopg
    except ImportError as exc:  # pragma: no cover - CLI environment
        raise RuntimeError("install psycopg[binary] to import the V1 app tables") from exc
    return psycopg.connect(database_url)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--database-url", default=os.environ.get("DATABASE_URL"),
                        help="target database; defaults to DATABASE_URL")
    parser.add_argument("--legacy-database-url", required=True, help="legacy database, read-only")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="report the gap without writing")
    mode.add_argument("--apply", action="store_true", help="write the app tables")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if not args.database_url:
        raise SystemExit("--database-url or DATABASE_URL is required")
    report = Report(mode="check" if args.check else "apply")
    with connect(args.legacy_database_url) as legacy, connect(args.database_url) as target:
        app = collect_legacy(legacy)
        report.legacy = {
            "users": len(app.users),
            "preferences": len(app.preferences),
            "handbooks": len(app.handbooks),
            "managed_handbooks": sum(1 for _, _, _, _, _, _, _, _, _, managed in app.handbooks if managed),
            "sections": len(app.sections),
            "items": len(app.items),
            "handbook_votes": app.handbook_votes,
        }
        report.check = plan_target(target, app)
    block = list(report.check.get("missing_locales", ())) + list(report.check.get("missing_item_locale_ids", ()))
    if block:
        raise SystemExit(json.dumps({
            "error": "staged handbooks reference locales absent from the target database",
            "missing_locales": report.check["missing_locales"],
            "missing_item_locale_ids": report.check["missing_item_locale_ids"],
        }, ensure_ascii=False))
    if args.apply:
        with connect(args.database_url) as target:
            report.applied = apply_target(target, app)
    print(json.dumps(asdict(report), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())