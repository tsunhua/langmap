#!/usr/bin/env python3
"""Import the LangMap V1 system-authored expression graph into the current database.

The V1 database kept user- and handbook-authored expressions alongside retired
``publication`` sources.  Those sources do not exist here, so the rows have to
be re-claimed by the V1 recovery source and matched by expression identity
``(language_id, text, homograph_index)`` rather than by primary key.

Scope is the expressions the recovery source claims plus their direct edge
neighbours, restricted to a configurable set of writing-system profiles.  The
legacy database is only ever read.

Usage::

    export DATABASE_URL=postgresql://langmap@127.0.0.1/langmap_fresh
    python scripts/postgres/import_v1_system_graph.py \\
        --legacy-database-url postgresql://langmap@127.0.0.1/langmap \\
        --check
    python scripts/postgres/import_v1_system_graph.py \\
        --legacy-database-url postgresql://langmap@127.0.0.1/langmap \\
        --apply
"""

from __future__ import annotations

import argparse
import json
import os
from dataclasses import asdict, dataclass, field
from typing import Any, Iterable, Sequence

DEFAULT_SOURCE_ID = 127
DEFAULT_SCOPE_LOCALES = "cmn-Hant-TW,eng-Latn-US,eng-Latn-GB"
_STAGING_TABLES = (
    "stage_expressions",
    "stage_locale_links",
    "stage_readings",
    "stage_edges",
    "stage_expression_markers",
    "stage_edge_markers",
)

_SCOPE_CTE = """
WITH scope_jiazi AS (
    SELECT DISTINCT es.expression_id
    FROM expression_sources es
    WHERE es.source_id = %(source_id)s
),
scope_hop AS (
    SELECT DISTINCT CASE WHEN ed.expression_a_id = j.expression_id
                         THEN ed.expression_b_id
                         ELSE ed.expression_a_id END AS expression_id
    FROM scope_jiazi j
    JOIN expression_edges ed
      ON ed.expression_a_id = j.expression_id OR ed.expression_b_id = j.expression_id
),
scope_profiles AS (
    SELECT DISTINCT ll.expression_id
    FROM expression_locale_links ll
    JOIN language_locales l ON l.id = ll.locale_id
    WHERE l.code = ANY(%(locale_codes)s)
),
scope_target AS (
    SELECT expression_id FROM scope_jiazi WHERE expression_id IN (SELECT expression_id FROM scope_profiles)
    UNION
    SELECT expression_id FROM scope_hop  WHERE expression_id IN (SELECT expression_id FROM scope_profiles)
),
scope_edges AS (
    -- IN, not a two-predicate JOIN: PostgreSQL 16 merges equality predicates that
    -- reference the same single outer column and silently folds this into
    -- "expression_a_id = expression_b_id", which returns nothing.
    SELECT ed.id, ed.expression_a_id, ed.expression_b_id, ed.relation_mask, ed.score, ed.annotations_json
    FROM expression_edges ed
    WHERE ed.expression_a_id IN (SELECT expression_id FROM scope_target)
      AND ed.expression_b_id IN (SELECT expression_id FROM scope_target)
)
"""

# One statement keeps the legacy side read-only: no DDL, and the scope CTEs are
# evaluated once instead of per table.
_LEGACY_SCAN_SQL = (
    _SCOPE_CTE
    + """
, collected AS (
    SELECT 'expression' AS kind, e.id::text AS c1, e.language_id::text AS c2, e.homograph_index::text AS c3,
           e.text AS c4, e.pos_mask::text AS c5, e.created_at AS c6
    FROM scope_target t JOIN expressions e ON e.id = t.expression_id
    UNION ALL
    SELECT 'edge', ed.id::text, ed.expression_a_id::text, ed.expression_b_id::text,
           ed.relation_mask::text, ed.score::text, ed.annotations_json
    FROM scope_edges ed
    UNION ALL
    SELECT 'locale_link', ll.expression_id::text, l.code, NULL, NULL, NULL, NULL
    FROM scope_target t
    JOIN expression_locale_links ll ON ll.expression_id = t.expression_id
    JOIN language_locales l ON l.id = ll.locale_id
    UNION ALL
    SELECT 'reading', r.expression_id::text, l.code, r.scheme, r.value, NULL, NULL
    FROM scope_target t
    JOIN expression_readings r ON r.expression_id = t.expression_id
    JOIN language_locales l ON l.id = r.locale_id
    UNION ALL
    SELECT 'expression_marker', es.expression_id::text, es.source_marker, es.pos_mask::text, NULL, NULL, NULL
    FROM scope_target t
    JOIN expression_sources es ON es.expression_id = t.expression_id AND es.source_id = %(source_id)s
    UNION ALL
    SELECT 'edge_marker', ees.edge_id::text, ees.source_marker, NULL, NULL, NULL, NULL
    FROM scope_edges e
    JOIN expression_edge_sources ees ON ees.edge_id = e.id AND ees.source_id = %(source_id)s
)
SELECT kind, c1, c2, c3, c4, c5, c6 FROM collected
"""
)


@dataclass(frozen=True)
class LegacyGraph:
    """Rows read from the legacy database, already narrowed to scope."""

    expressions: tuple[tuple[int, int, int, str, int, str], ...]
    edges: tuple[tuple[int, int, int, int, int, str], ...]
    locale_links: tuple[tuple[int, str], ...]
    readings: tuple[tuple[int, str, str, str], ...]
    expression_markers: tuple[tuple[int, str, int], ...]
    edge_markers: tuple[tuple[int, str], ...]
    jiazi_claimed: int = 0
    hop_claimed: int = 0


@dataclass
class TargetPlan:
    """What the target database is missing before any write happens."""

    expressions: int = 0
    edges: int = 0
    locale_links: int = 0
    readings: int = 0
    expression_markers: int = 0
    edge_markers: int = 0
    missing_locales: tuple[str, ...] = ()


@dataclass
class Report:
    mode: str
    source_id: int
    scope_locales: list[str] = field(default_factory=list)
    legacy: dict[str, Any] = field(default_factory=dict)
    plan: dict[str, Any] = field(default_factory=dict)
    applied: dict[str, Any] = field(default_factory=dict)


def collect_legacy(legacy, source_id: int, locale_codes: Sequence[str]) -> LegacyGraph:
    """Read the in-scope graph out of the legacy database in one statement."""
    buckets: dict[str, list[tuple[Any, ...]]] = {
        "expression": [], "edge": [], "locale_link": [],
        "reading": [], "expression_marker": [], "edge_marker": [],
    }
    with legacy.cursor(name="legacy_scope") as cursor:
        cursor.execute(_LEGACY_SCAN_SQL, {"source_id": source_id, "locale_codes": list(locale_codes)})
        for kind, *cells in cursor:
            buckets[kind].append(tuple(cells))

    expressions = tuple(
        (int(c1), int(c2), int(c3), c4, int(c5), c6) for c1, c2, c3, c4, c5, c6 in buckets["expression"]
    )
    edges = tuple(
        (int(c1), int(c2), int(c3), int(c4), int(c5), c6) for c1, c2, c3, c4, c5, c6 in buckets["edge"]
    )
    locale_links = tuple((int(c1), c2) for c1, c2, *_ in buckets["locale_link"])
    readings = tuple((int(c1), c2, c3, c4) for c1, c2, c3, c4, *_ in buckets["reading"])
    expression_markers = tuple((int(c1), c2, int(c3)) for c1, c2, c3, *_ in buckets["expression_marker"])
    edge_markers = tuple((int(c1), c2) for c1, c2, *_ in buckets["edge_marker"])

    jiazi_ids = {expression_id for expression_id, _, _ in expression_markers}
    scoped = {int(c1) for c1, *_ in buckets["expression"]}
    return LegacyGraph(
        expressions=expressions,
        edges=edges,
        locale_links=locale_links,
        readings=readings,
        expression_markers=expression_markers,
        edge_markers=edge_markers,
        jiazi_claimed=len(jiazi_ids & scoped),
        hop_claimed=len(scoped - jiazi_ids),
    )


def plan_target(target, graph: LegacyGraph, source_id: int) -> TargetPlan:
    """Resolve identity, locales and pairs without writing anything."""
    source = target.execute("SELECT id FROM sources WHERE id = %s AND type = 'system'", (source_id,)).fetchone()
    if source is None:
        raise ValueError(f"source {source_id} is not a system source in the target database")

    with target.transaction():
        _create_staging(target, graph)
        missing_locales = tuple(
            code
            for (code,) in target.execute(
                """
                SELECT code FROM (
                    SELECT locale_code AS code FROM stage_locale_links
                    UNION SELECT locale_code FROM stage_readings
                ) wanted
                WHERE NOT EXISTS (SELECT 1 FROM language_locales l WHERE l.code = wanted.code)
                ORDER BY 1
                """
            ).fetchall()
        )
        missing_expressions = _missing_expressions(target)
        _expression_map(target)
        edges_absent, edges_pending, _ = _edge_gap(target)
        return TargetPlan(
            expressions=len(missing_expressions),
            edges=edges_absent + edges_pending,
            locale_links=len(graph.locale_links),
            readings=len(graph.readings),
            expression_markers=len(graph.expression_markers),
            edge_markers=len(graph.edge_markers),
            missing_locales=missing_locales,
        )


def _create_staging(target, graph: LegacyGraph) -> None:
    for table in _STAGING_TABLES:
        target.execute(f"DROP TABLE IF EXISTS {table}")
    target.execute(
        "CREATE TEMP TABLE stage_expressions("
        " legacy_id BIGINT PRIMARY KEY, language_id BIGINT, homograph_index BIGINT,"
        " text TEXT, pos_mask BIGINT, created_at TEXT) ON COMMIT DROP"
    )
    target.execute("CREATE TEMP TABLE stage_locale_links(legacy_id BIGINT, locale_code TEXT) ON COMMIT DROP")
    target.execute("CREATE TEMP TABLE stage_readings(legacy_id BIGINT, locale_code TEXT, scheme TEXT, value TEXT) ON COMMIT DROP")
    target.execute(
        "CREATE TEMP TABLE stage_edges("
        " legacy_id BIGINT PRIMARY KEY, legacy_a BIGINT, legacy_b BIGINT,"
        " relation_mask BIGINT, score BIGINT, annotations_json TEXT) ON COMMIT DROP"
    )
    target.execute(
        "CREATE TEMP TABLE stage_expression_markers(legacy_id BIGINT, source_marker TEXT, pos_mask BIGINT) ON COMMIT DROP"
    )
    target.execute("CREATE TEMP TABLE stage_edge_markers(legacy_id BIGINT, source_marker TEXT) ON COMMIT DROP")
    with target.cursor() as cursor:
        _copy(cursor, "stage_expressions", graph.expressions)
        _copy(cursor, "stage_locale_links", graph.locale_links)
        _copy(cursor, "stage_readings", graph.readings)
        _copy(cursor, "stage_edges", graph.edges)
        _copy(cursor, "stage_expression_markers", graph.expression_markers)
        _copy(cursor, "stage_edge_markers", graph.edge_markers)


def _copy(cursor, table: str, rows: Iterable[Sequence[Any]]) -> None:
    with cursor.copy(f"COPY {table} FROM STDIN") as copy:
        for row in rows:
            copy.write_row(row)


def _missing_expressions(target) -> tuple[tuple[int], ...]:
    """Staged expressions whose identity is absent on the target."""
    return target.execute(
        """
        SELECT s.legacy_id
        FROM stage_expressions s
        WHERE NOT EXISTS (
            SELECT 1 FROM expressions e
            WHERE e.language_id = s.language_id
              AND e.homograph_index = s.homograph_index
              AND e.text = s.text)
        ORDER BY s.legacy_id
        """
    ).fetchall()


def _expression_map(target) -> tuple[dict[int, int], tuple[int, ...]]:
    target.execute("DROP TABLE IF EXISTS stage_map")
    target.execute(
        """
        CREATE TEMP TABLE stage_map AS
        SELECT s.legacy_id, x.id AS expression_id
        FROM stage_expressions s
        JOIN expressions x
          ON x.language_id = s.language_id
         AND x.homograph_index = s.homograph_index
         AND x.text = s.text
        """
    )
    mapping = {int(legacy): int(new) for legacy, new in target.execute("SELECT legacy_id, expression_id FROM stage_map")}
    unmapped = tuple(
        int(row[0])
        for row in target.execute(
            "SELECT legacy_id FROM stage_expressions WHERE legacy_id NOT IN (SELECT legacy_id FROM stage_map) ORDER BY legacy_id"
        ).fetchall()
    )
    return mapping, unmapped


def _edge_gap(target) -> tuple[int, int, tuple[int, ...]]:
    """Split in-scope edges into the ones --apply must insert and the rest.

    ``stage_map`` only holds expressions that already exist, so edges touching a
    not-yet-inserted expression are missing from it; counting them separately
    keeps the plan honest about what --apply will actually add.
    """
    target.execute("DROP TABLE IF EXISTS stage_edge_pairs")
    target.execute(
        """
        CREATE TEMP TABLE stage_edge_pairs AS
        SELECT e.legacy_id,
               LEAST(a.expression_id, b.expression_id) AS a_id,
               GREATEST(a.expression_id, b.expression_id) AS b_id
        FROM stage_edges e
        JOIN stage_map a ON a.legacy_id = e.legacy_a
        JOIN stage_map b ON b.legacy_id = e.legacy_b
        WHERE a.expression_id <> b.expression_id
        """
    )
    absent_between_present = target.execute(
        """
        SELECT count(*)
        FROM stage_edge_pairs p
        WHERE NOT EXISTS (
            SELECT 1 FROM expression_edges e
            WHERE e.expression_a_id = p.a_id AND e.expression_b_id = p.b_id)
        """
    ).fetchone()[0]
    blocked = int(target.execute(
        """
        SELECT count(*)
        FROM stage_edges e
        LEFT JOIN stage_map a ON a.legacy_id = e.legacy_a
        LEFT JOIN stage_map b ON b.legacy_id = e.legacy_b
        WHERE a.legacy_id IS NULL OR b.legacy_id IS NULL
        """
    ).fetchone()[0])
    self_edges = int(target.execute(
        """
        SELECT count(*) FROM stage_edges e
        JOIN stage_map a ON a.legacy_id = e.legacy_a
        JOIN stage_map b ON b.legacy_id = e.legacy_b
        WHERE a.expression_id = b.expression_id
        """
    ).fetchone()[0])
    unmapped = tuple(
        int(row[0])
        for row in target.execute(
            "SELECT legacy_id FROM stage_edges WHERE legacy_id NOT IN (SELECT legacy_id FROM stage_edge_pairs) ORDER BY legacy_id"
        ).fetchall()
    )
    return absent_between_present, blocked + self_edges, unmapped


def apply_target(target, graph: LegacyGraph, source_id: int) -> dict[str, Any]:
    """Stage, write and reconcile the scoped graph inside one transaction."""
    with target.transaction():
        _create_staging(target, graph)
        inserted_expressions = target.execute(
            """
            INSERT INTO expressions (language_id, text, homograph_index, pos_mask, created_at)
            SELECT s.language_id, s.text, s.homograph_index, s.pos_mask, s.created_at
            FROM stage_expressions s
            WHERE NOT EXISTS (
                SELECT 1 FROM expressions e
                WHERE e.language_id = s.language_id
                  AND e.homograph_index = s.homograph_index
                  AND e.text = s.text)
            ORDER BY s.legacy_id
            """
        ).rowcount
        mapping, unmapped = _expression_map(target)
        if unmapped:
            raise RuntimeError(f"{len(unmapped)} staged expressions could not be resolved after insert")

        inserted_edges = target.execute(
            """
            INSERT INTO expression_edges (expression_a_id, expression_b_id, relation_mask, score, annotations_json)
            SELECT LEAST(a.expression_id, b.expression_id),
                   GREATEST(a.expression_id, b.expression_id),
                   e.relation_mask, e.score, e.annotations_json
            FROM stage_edges e
            JOIN stage_map a ON a.legacy_id = e.legacy_a
            JOIN stage_map b ON b.legacy_id = e.legacy_b
            WHERE a.expression_id <> b.expression_id
            ON CONFLICT (expression_a_id, expression_b_id) DO NOTHING
            """
        ).rowcount
        inserted_expression_markers = target.execute(
            """
            INSERT INTO expression_sources (expression_id, source_id, source_marker, pos_mask)
            SELECT m.expression_id, %(source_id)s, s.source_marker, s.pos_mask
            FROM stage_expression_markers s
            JOIN stage_map m ON m.legacy_id = s.legacy_id
            ON CONFLICT (expression_id, source_id, source_marker) DO NOTHING
            """,
            {"source_id": source_id},
        ).rowcount
        inserted_readings = target.execute(
            """
            INSERT INTO expression_readings (expression_id, locale_id, scheme, value, source_id)
            SELECT m.expression_id, l.id, s.scheme, s.value, %(source_id)s
            FROM stage_readings s
            JOIN stage_map m ON m.legacy_id = s.legacy_id
            JOIN language_locales l ON l.code = s.locale_code
            ON CONFLICT (expression_id, locale_id, scheme, value) DO NOTHING
            """,
            {"source_id": source_id},
        ).rowcount
        inserted_links = target.execute(
            """
            INSERT INTO expression_locale_links (expression_id, locale_id)
            SELECT m.expression_id, l.id
            FROM stage_locale_links s
            JOIN stage_map m ON m.legacy_id = s.legacy_id
            JOIN language_locales l ON l.code = s.locale_code
            ON CONFLICT DO NOTHING
            """
        ).rowcount
        inserted_edge_markers = target.execute(
            """
            INSERT INTO expression_edge_sources (edge_id, source_id, source_marker)
            SELECT e.id, %(source_id)s, s.source_marker
            FROM stage_edge_markers s
            JOIN stage_edges g ON g.legacy_id = s.legacy_id
            JOIN stage_map a ON a.legacy_id = g.legacy_a
            JOIN stage_map b ON b.legacy_id = g.legacy_b
            JOIN expression_edges e
              ON e.expression_a_id = LEAST(a.expression_id, b.expression_id)
             AND e.expression_b_id = GREATEST(a.expression_id, b.expression_id)
            WHERE a.expression_id <> b.expression_id
            ON CONFLICT (edge_id, source_id, source_marker) DO NOTHING
            """,
            {"source_id": source_id},
        ).rowcount
        for table in ("expressions", "expression_edges"):
            target.execute(
                f"SELECT setval(pg_get_serial_sequence('{table}', 'id'),"
                f" GREATEST((SELECT max(id) FROM {table}), 1))"
            )
        return {
            "expressions": int(inserted_expressions or 0),
            "edges": int(inserted_edges or 0),
            "expression_markers": int(inserted_expression_markers or 0),
            "edge_markers": int(inserted_edge_markers or 0),
            "readings": int(inserted_readings or 0),
            "locale_links": int(inserted_links or 0),
        }


def connect(database_url: str):
    try:
        import psycopg
    except ImportError as exc:  # pragma: no cover - CLI environment
        raise RuntimeError("install psycopg[binary] to run the V1 graph import") from exc
    return psycopg.connect(database_url)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--database-url", default=os.environ.get("DATABASE_URL"),
                        help="target database; defaults to DATABASE_URL")
    parser.add_argument("--legacy-database-url", required=True, help="legacy database, read-only")
    parser.add_argument("--source-id", type=int, default=DEFAULT_SOURCE_ID)
    parser.add_argument("--scope-locales", default=DEFAULT_SCOPE_LOCALES,
                        help=f"comma separated language_locale codes, default {DEFAULT_SCOPE_LOCALES}")
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="report the gap without writing")
    mode.add_argument("--apply", action="store_true", help="write the scoped graph")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if not args.database_url:
        raise SystemExit("--database-url or DATABASE_URL is required")
    locale_codes = [code.strip() for code in args.scope_locales.split(",") if code.strip()]
    if not locale_codes:
        raise SystemExit("--scope-locales needs at least one language_locale code")

    with connect(args.legacy_database_url) as legacy, connect(args.database_url) as target:
        legacy.execute("SET TRANSACTION READ ONLY")
        graph = collect_legacy(legacy, args.source_id, locale_codes)
        plan = plan_target(target, graph, args.source_id)

    if plan.missing_locales:
        raise SystemExit(json.dumps({
            "error": "scope references locales absent from the target database",
            "missing_locales": list(plan.missing_locales),
        }))

    report = Report(
        mode="apply" if args.apply else "check",
        source_id=args.source_id,
        scope_locales=locale_codes,
        legacy={
            "jiazi_expressions": graph.jiazi_claimed,
            "hop_expressions": graph.hop_claimed,
            "expressions": len(graph.expressions),
            "edges": len(graph.edges),
            "locale_links": len(graph.locale_links),
            "readings": len(graph.readings),
            "expression_markers": len(graph.expression_markers),
            "edge_markers": len(graph.edge_markers),
        },
        plan=asdict(plan),
    )
    if args.apply:
        with connect(args.database_url) as target:
            report.applied = apply_target(target, graph, args.source_id)
    print(json.dumps(asdict(report), ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
