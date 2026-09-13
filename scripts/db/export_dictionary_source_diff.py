#!/usr/bin/env python3
"""Export a bounded natural-key diff for one dictionary source.

Unlike a full source rebuild, this command compares one source in a local
mirror (``--before``) with a freshly imported source-only staging database
(``--after``).  Only source claims, readings, edge attestations, and expression
identities that changed are emitted.  This keeps production D1 commands small
and avoids a source-wide delete that can exceed D1's CPU limit.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import sqlite3
import sys
from pathlib import Path
from typing import Any, Iterable, Sequence

try:
    from .export_dictionary_source_delta import _literal, _sha256, _write_cte_batches
except ImportError:  # pragma: no cover - keeps direct script execution working
    from export_dictionary_source_delta import _literal, _sha256, _write_cte_batches
from scripts.dictionary.langmap_dictionary.text_identity import canonicalize_expression_text


def _write_batch_marker(handle, enabled: bool) -> None:
    if enabled:
        handle.write("-- langmap:batch\n")


def _rows(connection: sqlite3.Connection, sql: str, parameters: Iterable[object] = ()) -> list[tuple[Any, ...]]:
    return [tuple(row) for row in connection.execute(sql, tuple(parameters))]


def _source_id(connection: sqlite3.Connection, source_type: str, source_name: str) -> int | None:
    row = connection.execute(
        "SELECT id FROM sources WHERE type=? AND name=?",
        (source_type, source_name),
    ).fetchone()
    return None if row is None else int(row[0])


def _attach(connection: sqlite3.Connection, path: Path, schema: str) -> None:
    connection.execute(f"ATTACH DATABASE ? AS {schema}", (str(path.resolve()),))


def _source_locales(connection: sqlite3.Connection, source_id: int) -> list[tuple[Any, ...]]:
    return _rows(
        connection,
        """
        SELECT ll.code,l.code,ll.script_code,ll.orthography,ll.region_code,
               ll.place_path,ll.name,ll.name_en,ll.latitude,ll.longitude
        FROM language_locales ll
        JOIN languages l ON l.id=ll.language_id
        WHERE ll.code IN (
          SELECT ll2.code FROM expression_locale_links x
          JOIN language_locales ll2 ON ll2.id=x.locale_id
          JOIN expression_sources es ON es.expression_id=x.expression_id
          WHERE es.source_id=?
          UNION
          SELECT ll3.code FROM expression_readings r
          JOIN language_locales ll3 ON ll3.id=r.locale_id
          WHERE r.source_id=?
        )
        ORDER BY ll.code
        """,
        (source_id, source_id),
    )


def _identity_select(schema: str, table_alias: str = "e") -> str:
    return (
        f"{table_alias}.language_id, {table_alias}.text, "
        f"{table_alias}.homograph_index"
    )


def _claims(connection: sqlite3.Connection, schema: str, source_id: int | None) -> list[tuple[Any, ...]]:
    if source_id is None:
        return []
    return _rows(
        connection,
        f"""
        SELECT l.code,e.text,e.homograph_index,es.source_marker
        FROM {schema}.expression_sources es
        JOIN {schema}.expressions e ON e.id=es.expression_id
        JOIN {schema}.languages l ON l.id=e.language_id
        WHERE es.source_id=?
        ORDER BY l.code,e.text,e.homograph_index,es.source_marker
        """,
        (source_id,),
    )


def _nodes(connection: sqlite3.Connection, schema: str, source_id: int | None) -> list[tuple[Any, ...]]:
    if source_id is None:
        return []
    return _rows(
        connection,
        f"""
        WITH ids AS (
          SELECT expression_id AS id FROM {schema}.expression_sources WHERE source_id=?
          UNION
          SELECT e.expression_a_id FROM {schema}.expression_edges e
          JOIN {schema}.expression_edge_sources es ON es.edge_id=e.id WHERE es.source_id=?
          UNION
          SELECT e.expression_b_id FROM {schema}.expression_edges e
          JOIN {schema}.expression_edge_sources es ON es.edge_id=e.id WHERE es.source_id=?
          UNION
          SELECT expression_id FROM {schema}.expression_readings WHERE source_id=?
        )
        SELECT l.code,e.text,e.homograph_index,e.pos_mask,e.created_at
        FROM ids JOIN {schema}.expressions e ON e.id=ids.id
        JOIN {schema}.languages l ON l.id=e.language_id
        ORDER BY l.code,e.text,e.homograph_index
        """,
        (source_id, source_id, source_id, source_id),
    )


def _readings(connection: sqlite3.Connection, schema: str, source_id: int | None) -> list[tuple[Any, ...]]:
    if source_id is None:
        return []
    return _rows(
        connection,
        f"""
        SELECT l.code,e.text,e.homograph_index,ll.code,r.scheme,r.value
        FROM {schema}.expression_readings r
        JOIN {schema}.expressions e ON e.id=r.expression_id
        JOIN {schema}.languages l ON l.id=e.language_id
        JOIN {schema}.language_locales ll ON ll.id=r.locale_id
        WHERE r.source_id=?
        ORDER BY l.code,e.text,e.homograph_index,ll.code,r.scheme,r.value
        """,
        (source_id,),
    )


def _edges(connection: sqlite3.Connection, schema: str, source_id: int | None) -> list[tuple[Any, ...]]:
    if source_id is None:
        return []
    return _rows(
        connection,
        f"""
        SELECT la.code,ea.text,ea.homograph_index,
               lb.code,eb.text,eb.homograph_index,
               e.relation_mask,e.score,es.source_marker
        FROM {schema}.expression_edge_sources es
        JOIN {schema}.expression_edges e ON e.id=es.edge_id
        JOIN {schema}.expressions ea ON ea.id=e.expression_a_id
        JOIN {schema}.languages la ON la.id=ea.language_id
        JOIN {schema}.expressions eb ON eb.id=e.expression_b_id
        JOIN {schema}.languages lb ON lb.id=eb.language_id
        WHERE es.source_id=?
        ORDER BY la.code,ea.text,ea.homograph_index,lb.code,eb.text,eb.homograph_index,es.source_marker
        """,
        (source_id,),
    )


def _locale_links(connection: sqlite3.Connection, source_id: int) -> list[tuple[Any, ...]]:
    return _rows(
        connection,
        """
        SELECT l.code,e.text,e.homograph_index,ll.code
        FROM expression_sources es
        JOIN expressions e ON e.id=es.expression_id
        JOIN languages l ON l.id=e.language_id
        JOIN expression_locale_links x ON x.expression_id=e.id
        JOIN language_locales ll ON ll.id=x.locale_id
        WHERE es.source_id=?
        ORDER BY l.code,e.text,e.homograph_index,ll.code
        """,
        (source_id,),
    )


def _write_delete_claim_batches(
    handle,
    rows: Sequence[Sequence[object]],
    *,
    source_type: str,
    source_name: str,
    batch_size: int,
    mark_batches: bool,
    casefold: bool = False,
) -> None:
    if not rows:
        return
    lookup = (
        f"(SELECT id FROM sources WHERE type={_literal(source_type)}"
        f" AND name={_literal(source_name)})"
    )
    # Production expressions are sentence-cased by the identity migration. A
    # case-only diff carries both canonical and original old surfaces, so the
    # indexed equality join works before or after normalization without a
    # ``lower(e.text)`` scan over the whole expressions table.
    columns = "language_code,text,homograph_index,source_marker,original_text"
    text_match = "e.text IN (r.text,r.original_text)"
    for start in range(0, len(rows), batch_size):
        batch = rows[start : start + batch_size]
        values = ",\n  ".join(
            "(" + ", ".join(_literal(value) for value in row) + ")"
            for row in batch
        )
        _write_batch_marker(handle, mark_batches)
        handle.write(
            f"WITH rows({columns}) AS (VALUES\n"
            f"  {values}\n)\n"
            "DELETE FROM expression_sources\n"
            f"WHERE source_id={lookup} AND (expression_id,source_marker) IN ("
            "SELECT e.id,r.source_marker FROM rows r JOIN languages l ON l.code=r.language_code "
            f"JOIN expressions e ON e.language_id=l.id AND {text_match} "
            "AND e.homograph_index=r.homograph_index);\n"
        )


def _write_delete_reading_batches(
    handle,
    rows: Sequence[Sequence[object]],
    *,
    source_type: str,
    source_name: str,
    batch_size: int,
    mark_batches: bool,
) -> None:
    if not rows:
        return
    lookup = (
        f"(SELECT id FROM sources WHERE type={_literal(source_type)}"
        f" AND name={_literal(source_name)})"
    )
    for start in range(0, len(rows), batch_size):
        batch = rows[start : start + batch_size]
        values = ",\n  ".join(
            "(" + ", ".join(_literal(value) for value in row) + ")"
            for row in batch
        )
        _write_batch_marker(handle, mark_batches)
        handle.write(
            "WITH rows(language_code,text,homograph_index,locale_code,scheme,value) AS (VALUES\n"
            f"  {values}\n)\n"
            "DELETE FROM expression_readings\n"
            f"WHERE source_id={lookup} AND (expression_id,locale_id,scheme,value) IN ("
            "SELECT e.id,ll.id,r.scheme,r.value FROM rows r JOIN languages l ON l.code=r.language_code "
            "JOIN expressions e ON e.language_id=l.id AND e.text=r.text "
            "AND e.homograph_index=r.homograph_index "
            "JOIN language_locales ll ON ll.code=r.locale_code);\n"
        )


def _write_delete_edge_batches(
    handle,
    rows: Sequence[Sequence[object]],
    *,
    source_type: str,
    source_name: str,
    batch_size: int,
    mark_batches: bool,
    casefold: bool = False,
    delete_edge_sources: bool = True,
) -> None:
    if not rows:
        return
    lookup = (
        f"(SELECT id FROM sources WHERE type={_literal(source_type)}"
        f" AND name={_literal(source_name)})"
    )
    columns = [
        "a_language_code", "a_text", "a_homograph_index",
        "b_language_code", "b_text", "b_homograph_index",
        "relation_mask", "score", "source_marker",
    ]
    columns.extend(("a_original_text", "b_original_text"))
    a_text_match = "a.text IN (r.a_text,r.a_original_text)"
    b_text_match = "b.text IN (r.b_text,r.b_original_text)"
    for start in range(0, len(rows), batch_size):
        batch = rows[start : start + batch_size]
        values = ",\n  ".join(
            "(" + ", ".join(_literal(value) for value in row) + ")"
            for row in batch
        )
        _write_batch_marker(handle, mark_batches)
        target_select = (
            f"WITH rows({','.join(columns)}) AS (VALUES\n  {values}\n)\n"
            "SELECT edge.id,r.source_marker FROM rows r "
            "JOIN languages al ON al.code=r.a_language_code "
            f"JOIN expressions a ON a.language_id=al.id AND {a_text_match} "
            "AND a.homograph_index=r.a_homograph_index "
            "JOIN languages bl ON bl.code=r.b_language_code "
            f"JOIN expressions b ON b.language_id=bl.id AND {b_text_match} "
            "AND b.homograph_index=r.b_homograph_index "
            "JOIN expression_edges edge ON edge.expression_a_id=CASE WHEN a.id<b.id THEN a.id ELSE b.id END "
            "AND edge.expression_b_id=CASE WHEN a.id<b.id THEN b.id ELSE a.id END "
            f"JOIN expression_edge_sources own ON own.edge_id=edge.id AND own.source_id={lookup} "
            "AND own.source_marker=r.source_marker"
        )
        # ``delete_edge_sources=False`` is only used after a source-scoped
        # preflight proves that this source owns every matching edge and no
        # marker/vote protects it. In that mode omit the shared-edge guards so
        # large self-language batches stay within D1's CPU budget.
        if delete_edge_sources:
            target_select += (
                " WHERE NOT EXISTS (SELECT 1 FROM expression_edge_sources same_source "
                f"WHERE same_source.edge_id=edge.id AND same_source.source_id={lookup} "
                "AND same_source.source_marker<>r.source_marker)"
            )
        handle.write(
            target_select.replace(
                "SELECT edge.id,r.source_marker FROM",
                "DELETE FROM expression_edges WHERE id IN (SELECT edge.id FROM",
                1,
            )
            + (
                ") AND NOT EXISTS (SELECT 1 FROM expression_edge_sources other "
                f"WHERE other.edge_id=expression_edges.id AND other.source_id<>{lookup}) "
                "AND NOT EXISTS (SELECT 1 FROM edge_votes vote WHERE vote.edge_id=expression_edges.id);\n"
                if delete_edge_sources
                else ");\n"
            )
        )
        if not delete_edge_sources:
            continue
        # The edge-source table is indexed by edge_id, not source_id. Group
        # each batch by marker and delete through the edge_id list so SQLite
        # can use that index without a correlated marker lookup per row.
        marker_groups: dict[object, list[Sequence[object]]] = {}
        for row in batch:
            marker_groups.setdefault(row[8], []).append(row)
        for marker_rows in marker_groups.values():
            marker_values = ",\n  ".join(
                "(" + ", ".join(_literal(value) for value in row) + ")"
                for row in marker_rows
            )
            marker = marker_rows[0][8]
            _write_batch_marker(handle, mark_batches)
            handle.write(
                f"WITH rows({','.join(columns)}) AS (VALUES\n  {marker_values}\n), targets AS ("
                "SELECT edge.id AS edge_id FROM rows r JOIN languages al ON al.code=r.a_language_code "
                f"JOIN expressions a ON a.language_id=al.id AND {a_text_match} "
                "AND a.homograph_index=r.a_homograph_index "
                "JOIN languages bl ON bl.code=r.b_language_code "
                f"JOIN expressions b ON b.language_id=bl.id AND {b_text_match} "
                "AND b.homograph_index=r.b_homograph_index "
                "JOIN expression_edges edge ON edge.expression_a_id=CASE WHEN a.id<b.id THEN a.id ELSE b.id END "
                "AND edge.expression_b_id=CASE WHEN a.id<b.id THEN b.id ELSE a.id END)\n"
                "DELETE FROM expression_edge_sources\n"
                f"WHERE source_id={lookup} AND source_marker={_literal(marker)} "
                "AND edge_id IN (SELECT edge_id FROM targets);\n"
            )


def _write_delete_orphan_cleanup(
    handle,
    rows: Sequence[Sequence[object]],
    *,
    source_type: str,
    source_name: str,
    batch_size: int,
    mark_batches: bool,
) -> None:
    """Remove old source-only nodes after claims/edges/readings are deleted."""

    if not rows:
        return
    lookup = (
        f"(SELECT id FROM sources WHERE type={_literal(source_type)}"
        f" AND name={_literal(source_name)})"
    )
    for start in range(0, len(rows), batch_size):
        batch = rows[start : start + batch_size]
        values = ",\n  ".join(
            "(" + ", ".join(_literal(value) for value in row[:4]) + ")"
            for row in batch
        )
        _write_batch_marker(handle, mark_batches)
        handle.write(
            "WITH rows(language_code,text,homograph_index,original_text) AS (VALUES\n"
            f"  {values}\n), candidates AS ("
            "SELECT e.id FROM rows r JOIN languages l ON l.code=r.language_code "
            "JOIN expressions e ON e.language_id=l.id AND e.text IN (r.text,r.original_text) "
            "AND e.homograph_index=r.homograph_index "
            f"WHERE e.source_id={lookup})\n"
            "DELETE FROM expression_locale_links WHERE expression_id IN ("
            "SELECT id FROM candidates c WHERE NOT EXISTS (SELECT 1 FROM expression_sources claim WHERE claim.expression_id=c.id) "
            "AND NOT EXISTS (SELECT 1 FROM expression_edges edge WHERE edge.expression_a_id=c.id OR edge.expression_b_id=c.id) "
            "AND NOT EXISTS (SELECT 1 FROM expression_readings reading WHERE reading.expression_id=c.id) "
            "AND NOT EXISTS (SELECT 1 FROM handbook_section_items item WHERE item.expression_id=c.id));\n"
        )
        _write_batch_marker(handle, mark_batches)
        handle.write(
            "WITH rows(language_code,text,homograph_index,original_text) AS (VALUES\n"
            f"  {values}\n), candidates AS ("
            "SELECT e.id FROM rows r JOIN languages l ON l.code=r.language_code "
            "JOIN expressions e ON e.language_id=l.id AND e.text IN (r.text,r.original_text) "
            "AND e.homograph_index=r.homograph_index "
            f"WHERE e.source_id={lookup})\n"
            "DELETE FROM expressions WHERE id IN (SELECT id FROM candidates c "
            "WHERE NOT EXISTS (SELECT 1 FROM expression_sources claim WHERE claim.expression_id=c.id) "
            "AND NOT EXISTS (SELECT 1 FROM expression_edges edge WHERE edge.expression_a_id=c.id OR edge.expression_b_id=c.id) "
            "AND NOT EXISTS (SELECT 1 FROM expression_readings reading WHERE reading.expression_id=c.id) "
            "AND NOT EXISTS (SELECT 1 FROM handbook_section_items item WHERE item.expression_id=c.id));\n"
        )
        _write_batch_marker(handle, mark_batches)
        handle.write(
            "WITH rows(language_code,text,homograph_index,original_text) AS (VALUES\n"
            f"  {values}\n)\n"
            "UPDATE expressions SET source_id=NULL WHERE id IN (SELECT e.id FROM rows r "
            "JOIN languages l ON l.code=r.language_code "
            "JOIN expressions e ON e.language_id=l.id AND e.text IN (r.text,r.original_text) "
            "AND e.homograph_index=r.homograph_index "
            f"WHERE e.source_id={lookup});\n"
        )


def export_source_diff(
    before: Path,
    after: Path,
    output: Path,
    *,
    source_type: str,
    source_name: str,
    locale_codes: Sequence[str],
    manifest: Path | None = None,
    rows_per_insert: int = 500,
    edge_rows_per_insert: int | None = None,
    skip_edge_source_cleanup: bool = False,
    mark_batches: bool = True,
) -> dict[str, int]:
    if rows_per_insert < 1:
        raise ValueError("rows_per_insert must be positive")
    edge_batch_size = edge_rows_per_insert or rows_per_insert
    if edge_batch_size < 1:
        raise ValueError("edge_rows_per_insert must be positive")
    conn = sqlite3.connect(after, timeout=120)
    conn.row_factory = sqlite3.Row
    conn.execute("ATTACH DATABASE ? AS before_db", (str(before.resolve()),))
    try:
        new_sid = _source_id(conn, source_type, source_name)
        if new_sid is None:
            raise ValueError(f"source not found in after staging: {source_type}/{source_name}")
        old_sid = _source_id(conn, source_type, source_name)  # replaced below by before query
        old_sid_row = conn.execute(
            "SELECT id FROM before_db.sources WHERE type=? AND name=?",
            (source_type, source_name),
        ).fetchone()
        old_sid = None if old_sid_row is None else int(old_sid_row[0])

        old_nodes = _nodes(conn, "before_db", old_sid)
        new_nodes = _nodes(conn, "main", new_sid)
        old_node_set = {tuple(row[:3]) for row in old_nodes}
        new_node_set = {tuple(row[:3]) for row in new_nodes}
        new_node_rows = [row for row in new_nodes if tuple(row[:3]) not in old_node_set]
        old_node_rows = [row for row in old_nodes if tuple(row[:3]) not in new_node_set]
        old_node_cleanup_rows = [
            (row[0], canonicalize_expression_text(row[1]), row[2], row[1])
            for row in old_node_rows
        ]

        old_claims = _claims(conn, "before_db", old_sid)
        new_claims = _claims(conn, "main", new_sid)
        old_claim_set = set(old_claims)
        new_claim_set = set(new_claims)
        added_claims = sorted(new_claim_set - old_claim_set)
        removed_claims_all = sorted(old_claim_set - new_claim_set)
        new_claim_casefold_keys = {
            (row[0], row[1].casefold(), row[2], row[3]) for row in new_claim_set
        }
        removed_claims_casefold_original = [
            row
            for row in removed_claims_all
            if (row[0], row[1].casefold(), row[2], row[3]) in new_claim_casefold_keys
        ]
        removed_claims_casefold = [
            (row[0], canonicalize_expression_text(row[1]), row[2], row[3], row[1])
            for row in removed_claims_casefold_original
        ]
        removed_claims_casefold_set = set(removed_claims_casefold_original)
        removed_claims_original = [
            row for row in removed_claims_all if row not in removed_claims_casefold_set
        ]
        removed_claims = [
            (row[0], canonicalize_expression_text(row[1]), row[2], row[3], row[1])
            for row in removed_claims_original
        ]

        old_readings = _readings(conn, "before_db", old_sid)
        new_readings = _readings(conn, "main", new_sid)
        added_readings = sorted(set(new_readings) - set(old_readings))
        removed_readings = sorted(set(old_readings) - set(new_readings))

        old_edges = _edges(conn, "before_db", old_sid)
        new_edges = _edges(conn, "main", new_sid)
        added_edges = sorted(set(new_edges) - set(old_edges))
        removed_edges_all = sorted(set(old_edges) - set(new_edges))
        new_edge_casefold_keys = {
            (row[0], row[1].casefold(), row[2], row[3], row[4].casefold(), row[5], row[8])
            for row in new_edges
        }
        removed_edges_casefold_original = [
            row
            for row in removed_edges_all
            if (row[0], row[1].casefold(), row[2], row[3], row[4].casefold(), row[5], row[8])
            in new_edge_casefold_keys
        ]
        removed_edges_casefold = [
            (
                row[0], canonicalize_expression_text(row[1]), row[2],
                row[3], canonicalize_expression_text(row[4]), row[5],
                row[6], row[7], row[8], row[1], row[4],
            )
            for row in removed_edges_casefold_original
        ]
        removed_edges_casefold_set = set(removed_edges_casefold_original)
        removed_edges_original = [
            row for row in removed_edges_all if row not in removed_edges_casefold_set
        ]
        removed_edges = [
            (
                row[0], canonicalize_expression_text(row[1]), row[2],
                row[3], canonicalize_expression_text(row[4]), row[5],
                row[6], row[7], row[8], row[1], row[4],
            )
            for row in removed_edges_original
        ]

        old_links = set()
        if old_sid is not None:
            old_links = set(_rows(conn, """
                SELECT l.code,e.text,e.homograph_index,ll.code
                FROM before_db.expression_sources es
                JOIN before_db.expressions e ON e.id=es.expression_id
                JOIN before_db.languages l ON l.id=e.language_id
                JOIN before_db.expression_locale_links x ON x.expression_id=e.id
                JOIN before_db.language_locales ll ON ll.id=x.locale_id
                WHERE es.source_id=?
            """, (old_sid,)))
        new_links = set(_locale_links(conn, new_sid))
        added_links = sorted(new_links - old_links)

        locales = _source_locales(conn, new_sid)
        output.parent.mkdir(parents=True, exist_ok=True)
        lookup = (
            f"(SELECT id FROM sources WHERE type={_literal(source_type)}"
            f" AND name={_literal(source_name)})"
        )
        with output.open("w", encoding="utf-8") as handle:
            handle.write("PRAGMA defer_foreign_keys=TRUE;\n")
            handle.write("-- Source-scoped natural-key diff; no full-source delete.\n")
            handle.write(f"INSERT OR IGNORE INTO sources (type,name) VALUES ({_literal(source_type)},{_literal(source_name)});\n")
            for locale in locales:
                handle.write(
                    "INSERT OR IGNORE INTO language_locales "
                    "(code,language_id,script_code,orthography,region_code,place_path,name,name_en,latitude,longitude) SELECT "
                    + ",".join([_literal(locale[0]), "l.id", *(_literal(value) for value in locale[2:])])
                    + f" FROM languages l WHERE l.code={_literal(locale[1])};\n"
                )

            # Edge parent cleanup performs two indexed joins plus shared-edge
            # and vote guards. Keep these statements small and isolated so a
            # single D1 CPU slice cannot reset the whole release.
            _write_delete_edge_batches(handle, removed_edges, source_type=source_type, source_name=source_name, batch_size=edge_batch_size, mark_batches=mark_batches, delete_edge_sources=not skip_edge_source_cleanup)
            _write_delete_edge_batches(handle, removed_edges_casefold, source_type=source_type, source_name=source_name, batch_size=edge_batch_size, mark_batches=mark_batches, casefold=True, delete_edge_sources=not skip_edge_source_cleanup)
            _write_delete_reading_batches(handle, removed_readings, source_type=source_type, source_name=source_name, batch_size=rows_per_insert, mark_batches=mark_batches)
            _write_delete_claim_batches(handle, removed_claims, source_type=source_type, source_name=source_name, batch_size=rows_per_insert, mark_batches=mark_batches)
            _write_delete_claim_batches(handle, removed_claims_casefold, source_type=source_type, source_name=source_name, batch_size=rows_per_insert, mark_batches=mark_batches, casefold=True)
            _write_delete_orphan_cleanup(handle, old_node_cleanup_rows, source_type=source_type, source_name=source_name, batch_size=rows_per_insert, mark_batches=mark_batches)

            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "pos_mask", "created_at"),
                new_node_rows,
                "INSERT OR IGNORE INTO expressions (language_id,text,homograph_index,pos_mask,source_id,created_at) "
                "SELECT l.id,r.text,r.homograph_index,r.pos_mask,s.id,r.created_at FROM rows r "
                "JOIN languages l ON l.code=r.language_code "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};",
                batch_size=rows_per_insert,
                force_batch=mark_batches,
            )
            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "source_marker"),
                added_claims,
                "INSERT OR IGNORE INTO expression_sources (expression_id,source_id,source_marker) "
                "SELECT e.id,s.id,r.source_marker FROM rows r JOIN languages l ON l.code=r.language_code "
                "JOIN expressions e ON e.language_id=l.id AND e.text=r.text AND e.homograph_index=r.homograph_index "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};",
                batch_size=rows_per_insert,
                force_batch=mark_batches,
            )
            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "locale_code"),
                added_links,
                "INSERT OR IGNORE INTO expression_locale_links (expression_id,locale_id) "
                "SELECT e.id,ll.id FROM rows r JOIN languages l ON l.code=r.language_code "
                "JOIN expressions e ON e.language_id=l.id AND e.text=r.text AND e.homograph_index=r.homograph_index "
                "JOIN language_locales ll ON ll.code=r.locale_code;",
                batch_size=rows_per_insert,
                force_batch=mark_batches,
            )
            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "locale_code", "scheme", "value"),
                added_readings,
                "INSERT OR IGNORE INTO expression_readings (expression_id,locale_id,scheme,value,source_id) "
                "SELECT e.id,ll.id,r.scheme,r.value,s.id FROM rows r JOIN languages l ON l.code=r.language_code "
                "JOIN expressions e ON e.language_id=l.id AND e.text=r.text AND e.homograph_index=r.homograph_index "
                "JOIN language_locales ll ON ll.code=r.locale_code "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};",
                batch_size=rows_per_insert,
                force_batch=mark_batches,
            )
            edge_columns = ("a_language_code", "a_text", "a_homograph_index", "b_language_code", "b_text", "b_homograph_index", "relation_mask", "score", "source_marker")
            edge_joins = (
                "FROM rows r JOIN languages al ON al.code=r.a_language_code JOIN expressions a ON a.language_id=al.id AND a.text=r.a_text AND a.homograph_index=r.a_homograph_index "
                "JOIN languages bl ON bl.code=r.b_language_code JOIN expressions b ON b.language_id=bl.id AND b.text=r.b_text AND b.homograph_index=r.b_homograph_index "
            )
            _write_cte_batches(handle, edge_columns, added_edges,
                "INSERT OR IGNORE INTO expression_edges (expression_a_id,expression_b_id,relation_mask,score) SELECT DISTINCT CASE WHEN a.id<b.id THEN a.id ELSE b.id END,CASE WHEN a.id<b.id THEN b.id ELSE a.id END,r.relation_mask,r.score " + edge_joins + ";", batch_size=rows_per_insert, force_batch=mark_batches)
            _write_cte_batches(handle, edge_columns, added_edges,
                "INSERT OR IGNORE INTO expression_edge_sources (edge_id,source_id,source_marker) SELECT e.id,s.id,r.source_marker " + edge_joins + "JOIN expression_edges e ON e.expression_a_id=CASE WHEN a.id<b.id THEN a.id ELSE b.id END AND e.expression_b_id=CASE WHEN a.id<b.id THEN b.id ELSE a.id END " + f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};", batch_size=rows_per_insert, force_batch=mark_batches)
            handle.write("PRAGMA defer_foreign_keys=FALSE;\n")

        counts = {
            "new_expressions": len(new_node_rows),
            "removed_expressions": len(old_node_rows),
            "added_claims": len(added_claims),
            "removed_claims": len(removed_claims) + len(removed_claims_casefold),
            "removed_claims_exact": len(removed_claims),
            "removed_claims_casefold": len(removed_claims_casefold),
            "added_links": len(added_links),
            "added_readings": len(added_readings),
            "removed_readings": len(removed_readings),
            "added_edges": len(added_edges),
            "removed_edges": len(removed_edges) + len(removed_edges_casefold),
            "removed_edges_exact": len(removed_edges),
            "removed_edges_casefold": len(removed_edges_casefold),
            "language_locales": len(locales),
        }
        if manifest is not None:
            manifest.parent.mkdir(parents=True, exist_ok=True)
            payload = {
                "schema_version": 1,
                "mode": "natural-key-diff",
                "source": {"type": source_type, "name": source_name},
                "locale_codes": sorted({str(row[0]) for row in locales}),
                "expected_counts": counts,
                "before_sha256": _sha256(before),
                "after_sha256": _sha256(after),
                "delta_sha256": _sha256(output),
                "mark_batches": mark_batches,
            }
            temporary = manifest.with_name(f".{manifest.name}.{os.getpid()}.tmp")
            temporary.write_text(json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
            os.replace(temporary, manifest)
        return counts
    finally:
        conn.close()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--before", required=True, type=Path)
    parser.add_argument("--after", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--source-type", required=True)
    parser.add_argument("--source-name", required=True)
    parser.add_argument("--locale-code", action="append", required=True, dest="locale_codes")
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--rows-per-insert", type=int, default=500)
    parser.add_argument("--edge-rows-per-insert", type=int, default=None)
    parser.add_argument(
        "--skip-edge-source-cleanup",
        action="store_true",
        help="skip edge-source deletes when a source-scoped shared-edge preflight proves parent cascades are sufficient",
    )
    parser.add_argument(
        "--no-force-batches",
        action="store_true",
        help="allow the managed runner to group safe statements up to its byte cap",
    )
    args = parser.parse_args(argv)
    try:
        counts = export_source_diff(
            args.before,
            args.after,
            args.output,
            source_type=args.source_type,
            source_name=args.source_name,
            locale_codes=args.locale_codes,
            manifest=args.manifest,
            rows_per_insert=args.rows_per_insert,
            edge_rows_per_insert=args.edge_rows_per_insert,
            skip_edge_source_cleanup=args.skip_edge_source_cleanup,
            mark_batches=not args.no_force_batches,
        )
    except (OSError, sqlite3.Error, ValueError) as exc:
        print(f"export failed: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(counts, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
