#!/usr/bin/env python3
"""Export one dictionary source as a baseline-free, natural-key SQL release.

The staging database is used only to describe rows owned by one source. Integer
IDs from staging are temporary join keys inside the generated SQL; production
identities are resolved by source name, locale code, language code, expression
identity, and edge endpoints.

With ``replace=True`` the delta first deletes every row the source owns in the
target, so re-releasing a source whose exporter output changed identity (e.g.
packed glosses split into separate equivalents) does not leave superseded rows
behind.  The delete resolves by natural key, is a no-op on targets that do not
have the source yet, and is refused while staging shows another source using an
expression this source owns.
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


def _literal(value: object) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def _write_cte_batches(
    handle,
    columns: Sequence[str],
    rows: Sequence[Sequence[object]],
    statement: str,
    *,
    batch_size: int,
    force_batch: bool = False,
) -> None:
    names = ", ".join(f'"{column}"' for column in columns)
    for start in range(0, len(rows), batch_size):
        batch = rows[start : start + batch_size]
        if force_batch:
            # Keep hot edge natural-key joins in their own remote command.
            handle.write("-- langmap:batch\n")
        values = ",\n  ".join(
            "(" + ", ".join(_literal(value) for value in row) + ")"
            for row in batch
        )
        handle.write(f"WITH rows({names}) AS (VALUES\n  {values}\n)\n{statement}\n")


def _rows(connection: sqlite3.Connection, sql: str, parameters: Iterable[object]) -> list[tuple[Any, ...]]:
    return [tuple(row) for row in connection.execute(sql, tuple(parameters))]


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _source_edge_annotations(raw_value: object, source_marker: str) -> list[dict[str, object]]:
    """Keep only this source's edge annotations and drop staging IDs.

    ``source_id`` is an integer local to the staging database.  The production
    delta resolves the source by its natural key, so annotations carry the
    source marker and a null ID instead of leaking that temporary integer.
    """

    try:
        parsed = json.loads(str(raw_value or "[]"))
    except (TypeError, ValueError):
        return []
    if not isinstance(parsed, list):
        return []
    result: list[dict[str, object]] = []
    for item in parsed:
        if not isinstance(item, dict):
            continue
        marker = item.get("source_marker")
        if str(marker or "") != source_marker:
            continue
        side = item.get("side")
        text = item.get("text")
        if side not in {"a", "b", "both"} or not isinstance(text, str) or not text.strip():
            continue
        result.append({
            "side": side,
            "source_id": None,
            "source_marker": source_marker or None,
            "text": " ".join(text.split()),
        })
    return result


def _annotation_update_sql(
    *,
    a_identity: tuple[object, object, object],
    b_identity: tuple[object, object, object],
    source_marker: str,
    annotations: Sequence[dict[str, object]],
) -> str:
    """Render a natural-key update that replaces this marker's annotations.

    Existing annotations from other sources remain on a shared edge.  The
    update is idempotent and works when the edge was already present before
    this source-scoped release.
    """

    a_language, a_text, a_homograph = a_identity
    b_language, b_text, b_homograph = b_identity
    existing = (
        "SELECT value AS item FROM json_each("
        "CASE WHEN json_valid(expression_edges.annotations_json) "
        "THEN expression_edges.annotations_json ELSE '[]' END) "
        f"WHERE COALESCE(json_extract(value,'$.source_marker'),'') <> {_literal(source_marker)}"
    )
    items = [existing]
    for annotation in annotations:
        items.append(f"SELECT json({_literal(json.dumps(annotation, ensure_ascii=False, sort_keys=True, separators=(',', ':')))}) AS item")
    merged = " UNION ALL ".join(items)
    endpoint_query = (
        "SELECT edge.id FROM expression_edges edge "
        "JOIN expressions ea ON ea.id=edge.expression_a_id "
        "JOIN languages la ON la.id=ea.language_id "
        "JOIN expressions eb ON eb.id=edge.expression_b_id "
        "JOIN languages lb ON lb.id=eb.language_id "
        f"WHERE la.code={_literal(a_language)} AND ea.text={_literal(a_text)} "
        f"AND ea.homograph_index={_literal(a_homograph)} "
        f"AND lb.code={_literal(b_language)} AND eb.text={_literal(b_text)} "
        f"AND eb.homograph_index={_literal(b_homograph)} LIMIT 1"
    )
    return (
        "UPDATE expression_edges SET annotations_json=("
        f"SELECT COALESCE(json_group_array(json(item)),'[]') FROM ({merged})"
        f") WHERE id=({endpoint_query});\n"
    )


def _handbook_target_sql(*, source_lookup: str, item_alias: str) -> str:
    """Find the newest English endpoint for a source marker.

    An additive repair release may coexist with an older edge carrying the
    same marker.  Newly inserted edges have the larger autoincrement id, so
    choosing the newest edge moves managed handbook items to the repaired
    expression without reading production IDs into the release artifact.
    """

    return (
        "SELECT CASE WHEN la.code='eng' THEN a.id ELSE b.id END "
        "FROM expression_edge_sources current_source "
        "JOIN expression_edges current_edge ON current_edge.id=current_source.edge_id "
        "JOIN expressions a ON a.id=current_edge.expression_a_id "
        "JOIN languages la ON la.id=a.language_id "
        "JOIN expressions b ON b.id=current_edge.expression_b_id "
        "JOIN languages lb ON lb.id=b.language_id "
        f"WHERE current_source.source_id={source_lookup} "
        "AND ((la.code='eng' AND lb.code<>'eng') OR (lb.code='eng' AND la.code<>'eng')) "
        "AND current_source.source_marker IN ("
        "SELECT old_source.source_marker "
        "FROM expression_edge_sources old_source "
        "JOIN expression_edges old_edge ON old_edge.id=old_source.edge_id "
        f"WHERE old_source.source_id={source_lookup} "
        f"AND (old_edge.expression_a_id={item_alias}.expression_id "
        f"OR old_edge.expression_b_id={item_alias}.expression_id)"
        ") ORDER BY current_edge.id DESC, "
        "CASE WHEN la.code='eng' THEN a.id ELSE b.id END ASC LIMIT 1"
    )


def _write_managed_handbook_remap(handle, *, source_type: str, source_name: str) -> None:
    """Move managed handbook items off replaced source-owned expressions.

    The handbook has a restrictive foreign key to expressions.  A source
    repair therefore cannot delete an old expression until its item points at
    the newest expression for the same source marker.  This additive release
    hook performs that remap while keeping all IDs natural-key resolved.
    """

    lookup = (
        f"(SELECT id FROM sources WHERE type={_literal(source_type)}"
        f" AND name={_literal(source_name)})"
    )
    owned = f"(SELECT id FROM expressions WHERE source_id = {lookup})"
    target_for_delete = _handbook_target_sql(source_lookup=lookup, item_alias="old_item")
    target_for_update = _handbook_target_sql(source_lookup=lookup, item_alias="item")
    handle.write("-- Remap managed handbook items to repaired English expressions.\n")
    handle.write(
        "DELETE FROM handbook_section_items AS old_item "
        f"WHERE old_item.expression_id IN {owned} "
        "AND EXISTS (SELECT 1 FROM handbook_section_items existing "
        "WHERE existing.section_id=old_item.section_id "
        f"AND existing.expression_id=({target_for_delete}) "
        "AND existing.position<>old_item.position);\n"
    )
    handle.write(
        "UPDATE handbook_section_items AS item SET expression_id=("
        f"{target_for_update}"
        ") WHERE item.expression_id IN "
        f"{owned} AND ({target_for_update}) IS NOT NULL;\n"
    )


def _write_replace_deletes(handle, *, source_type: str, source_name: str) -> None:
    """Emit child-before-parent deletes so the file also replays on databases
    where foreign-key enforcement is unavailable, not just on cascade-enabled
    ones.  Subqueries resolve to NULL (no-op) on targets that do not have the
    source yet, which keeps a replace delta usable for a first release."""
    lookup = (
        f"(SELECT id FROM sources WHERE type={_literal(source_type)}"
        f" AND name={_literal(source_name)})"
    )
    owned = f"(SELECT id FROM expressions WHERE source_id = {lookup})"
    touching = (
        "SELECT e.id FROM expression_edges e"
        f" WHERE e.expression_a_id IN {owned} OR e.expression_b_id IN {owned}"
    )
    handle.write("-- Replace mode: drop every row this source owns before re-inserting.\n")
    handle.write("-- langmap:batch\n")
    handle.write(f"DELETE FROM expression_edge_sources WHERE source_id = {lookup};\n")
    handle.write("-- langmap:batch\n")
    handle.write(f"DELETE FROM expression_readings WHERE source_id = {lookup};\n")
    handle.write("-- langmap:batch\n")
    handle.write(f"DELETE FROM expression_locale_links WHERE expression_id IN {owned};\n")
    handle.write("-- langmap:batch\n")
    handle.write(f"DELETE FROM expression_edge_sources WHERE edge_id IN ({touching});\n")
    handle.write("-- langmap:batch\n")
    handle.write(
        f"DELETE FROM expression_edges WHERE expression_a_id IN {owned}"
        f" OR expression_b_id IN {owned};\n"
    )
    handle.write("-- langmap:batch\n")
    handle.write(f"DELETE FROM expression_sources WHERE source_id = {lookup};\n")
    handle.write("-- langmap:batch\n")
    handle.write(f"DELETE FROM expressions WHERE source_id = {lookup};\n")


def _write_shared_safe_reconcile(
    handle, *, source_type: str, source_name: str
) -> None:
    """Remove one source's assertions without deleting shared graph data.

    A dictionary source commonly reuses canonical expressions and edges that
    are also attested by other sources.  Strict replace mode must reject that
    shape because its historical delete preamble removes whole expressions and
    edges.  Reconcile mode is deliberately narrower: it removes only this
    source's ownership rows, deletes an edge only when this source was its sole
    source attestation (and no vote protects it), and leaves shared/orphaned
    expressions in place.  Fresh rows emitted later in the delta can then
    re-attach the corrected source facts by natural key.
    """

    lookup = (
        f"(SELECT id FROM sources WHERE type={_literal(source_type)}"
        f" AND name={_literal(source_name)})"
    )
    source_edges = (
        "SELECT edge_id FROM expression_edge_sources "
        f"WHERE source_id = {lookup}"
    )
    owned = f"(SELECT id FROM expressions WHERE source_id = {lookup})"
    # Keep an edge when another source attests it or a user vote protects it.
    # The source-edge subquery is evaluated before its source rows are removed.
    handle.write("-- Shared-safe reconcile: remove only this source's assertions.\n")
    handle.write("-- langmap:batch\n")
    handle.write(
        "DELETE FROM expression_edges "
        f"WHERE id IN ({source_edges}) "
        f"AND NOT EXISTS (SELECT 1 FROM expression_edge_sources other "
        f"WHERE other.edge_id=expression_edges.id AND other.source_id <> {lookup}) "
        "AND NOT EXISTS (SELECT 1 FROM edge_votes vote "
        "WHERE vote.edge_id=expression_edges.id);\n"
    )
    handle.write("-- langmap:batch\n")
    handle.write(f"DELETE FROM expression_edge_sources WHERE source_id = {lookup};\n")
    handle.write("-- langmap:batch\n")
    handle.write(f"DELETE FROM expression_readings WHERE source_id = {lookup};\n")
    handle.write("-- langmap:batch\n")
    handle.write(f"DELETE FROM expression_sources WHERE source_id = {lookup};\n")

    # Drop locale links and expressions only after every source-owned claim has
    # gone, and only when no graph, reading, handbook, or vote can still reach
    # the expression.  Shared expressions are retained and their old source
    # owner is cleared so a later INSERT OR IGNORE cannot inherit stale
    # ownership metadata.
    removable_subquery = (
        f"e.source_id = {lookup} "
        "AND NOT EXISTS (SELECT 1 FROM expression_sources claim "
        "WHERE claim.expression_id=e.id) "
        "AND NOT EXISTS (SELECT 1 FROM expression_edges edge "
        "WHERE edge.expression_a_id=e.id OR edge.expression_b_id=e.id) "
        "AND NOT EXISTS (SELECT 1 FROM expression_readings reading "
        "WHERE reading.expression_id=e.id) "
        "AND NOT EXISTS (SELECT 1 FROM handbook_section_items item "
        "WHERE item.expression_id=e.id)"
    )
    removable_delete = (
        f"source_id = {lookup} "
        "AND NOT EXISTS (SELECT 1 FROM expression_sources claim "
        "WHERE claim.expression_id=expressions.id) "
        "AND NOT EXISTS (SELECT 1 FROM expression_edges edge "
        "WHERE edge.expression_a_id=expressions.id OR edge.expression_b_id=expressions.id) "
        "AND NOT EXISTS (SELECT 1 FROM expression_readings reading "
        "WHERE reading.expression_id=expressions.id) "
        "AND NOT EXISTS (SELECT 1 FROM handbook_section_items item "
        "WHERE item.expression_id=expressions.id)"
    )
    handle.write(
        "-- langmap:batch\n"
        "DELETE FROM expression_locale_links WHERE expression_id IN "
        f"(SELECT e.id FROM expressions e WHERE {removable_subquery});\n"
    )
    handle.write(
        "-- langmap:batch\n"
        "DELETE FROM expressions WHERE "
        f"{removable_delete};\n"
    )
    handle.write(
        "-- langmap:batch\n"
        "UPDATE expressions SET source_id=NULL WHERE source_id = "
        f"{lookup};\n"
    )


def export_source_delta(
    staging: Path,
    output: Path,
    *,
    source_type: str,
    source_name: str,
    locale_codes: Sequence[str],
    manifest: Path | None = None,
    rows_per_insert: int = 100,
    edge_rows_per_insert: int | None = None,
    replace: bool = False,
    reconcile_shared: bool = False,
    skip_edge_annotation_updates: bool = False,
    remap_managed_handbook: bool = False,
) -> dict[str, int]:
    if rows_per_insert < 1:
        raise ValueError("rows_per_insert must be positive")
    edge_batch_size = edge_rows_per_insert or rows_per_insert
    if edge_batch_size < 1:
        raise ValueError("edge_rows_per_insert must be positive")
    if not locale_codes:
        raise ValueError("at least one locale code is required")
    if reconcile_shared and not replace:
        raise ValueError("reconcile_shared requires replace mode")

    connection = sqlite3.connect(staging, timeout=60)
    try:
        source = connection.execute(
            "SELECT id FROM sources WHERE type=? AND name=?",
            (source_type, source_name),
        ).fetchone()
        if source is None:
            raise ValueError(f"source not found in staging: {source_type}/{source_name}")
        source_id = int(source[0])

        if replace and not reconcile_shared:
            shared_claims = connection.execute(
                """
                SELECT COUNT(*) FROM expressions e
                JOIN expression_sources es ON es.expression_id=e.id AND es.source_id<>?
                WHERE e.source_id=?
                """,
                (source_id, source_id),
            ).fetchone()[0]
            shared_attestations = connection.execute(
                """
                SELECT COUNT(*) FROM expression_edges e
                JOIN expression_edge_sources es ON es.edge_id=e.id AND es.source_id<>?
                WHERE e.expression_a_id IN (SELECT id FROM expressions WHERE source_id=?)
                   OR e.expression_b_id IN (SELECT id FROM expressions WHERE source_id=?)
                """,
                (source_id, source_id, source_id),
            ).fetchone()[0]
            foreign_readings = connection.execute(
                """
                SELECT COUNT(*) FROM expression_readings r
                JOIN expressions e ON e.id=r.expression_id
                WHERE e.source_id=? AND (r.source_id IS NULL OR r.source_id<>?)
                """,
                (source_id, source_id),
            ).fetchone()[0]
            # The delete preamble drops every row the source owns; refuse while
            # another source still claims, attests, or reads on an owned
            # expression, because deleting it would damage that source.
            if shared_claims or shared_attestations or foreign_readings:
                raise ValueError(
                    "replace mode requires expressions owned by the source to be used "
                    f"exclusively by it: shared claims={shared_claims}, "
                    f"shared edge attestations={shared_attestations}, "
                    f"foreign readings={foreign_readings}"
                )

        locales = _rows(
            connection,
            """
            SELECT ll.code,l.code,ll.script_code,ll.orthography,ll.region_code,
                   ll.place_path,ll.name,ll.name_en,ll.latitude,ll.longitude
            FROM language_locales ll
            JOIN languages l ON l.id=ll.language_id
            WHERE ll.code IN ({})
            ORDER BY ll.code
            """.format(",".join("?" for _ in locale_codes)),
            locale_codes,
        )
        found_codes = {str(row[0]) for row in locales}
        missing_codes = sorted(set(locale_codes) - found_codes)
        if missing_codes:
            raise ValueError("locale codes not found in staging: " + ", ".join(missing_codes))

        nodes = _rows(
            connection,
            """
            WITH claimed AS (
              SELECT expression_id FROM expression_sources WHERE source_id=?
              UNION
              SELECT e.expression_a_id FROM expression_edges e
              JOIN expression_edge_sources es ON es.edge_id=e.id WHERE es.source_id=?
              UNION
              SELECT e.expression_b_id FROM expression_edges e
              JOIN expression_edge_sources es ON es.edge_id=e.id WHERE es.source_id=?
              UNION
              SELECT expression_id FROM expression_readings WHERE source_id=?
            )
            SELECT e.id,l.code,e.text,e.homograph_index,e.pos_mask,e.created_at
            FROM claimed c JOIN expressions e ON e.id=c.expression_id
            JOIN languages l ON l.id=e.language_id
            ORDER BY e.id
            """,
            (source_id, source_id, source_id, source_id),
        )
        node_ids = {int(row[0]) for row in nodes}

        claims = _rows(
            connection,
            "SELECT expression_id,source_marker FROM expression_sources "
            "WHERE source_id=? ORDER BY expression_id,source_marker",
            (source_id,),
        )
        locale_links = _rows(
            connection,
            """
            SELECT es.expression_id,ll.code
            FROM expression_sources es
            JOIN expression_locale_links x ON x.expression_id=es.expression_id
            JOIN language_locales ll ON ll.id=x.locale_id
            WHERE es.source_id=? AND ll.code IN ({})
            ORDER BY es.expression_id,ll.code
            """.format(",".join("?" for _ in locale_codes)),
            (source_id, *locale_codes),
        )
        readings = _rows(
            connection,
            """
            SELECT r.expression_id,ll.code,r.scheme,r.value
            FROM expression_readings r JOIN language_locales ll ON ll.id=r.locale_id
            WHERE r.source_id=? ORDER BY r.expression_id,ll.code,r.scheme,r.value
            """,
            (source_id,),
        )
        edge_columns_present = {
            str(row[1])
            for row in connection.execute("PRAGMA table_info(expression_edges)")
        }
        edge_annotation_column = (
            ", e.annotations_json" if "annotations_json" in edge_columns_present else ""
        )
        edges = _rows(
            connection,
            f"""
            SELECT e.id,e.expression_a_id,e.expression_b_id,e.relation_mask,e.score,
                   es.source_marker{edge_annotation_column}
            FROM expression_edge_sources es JOIN expression_edges e ON e.id=es.edge_id
            WHERE es.source_id=? ORDER BY e.id,es.source_marker
            """,
            (source_id,),
        )
        referenced_ids = {
            int(value)
            for row in edges
            for value in (row[1], row[2])
        } | {int(row[0]) for row in claims} | {int(row[0]) for row in readings}
        missing_nodes = sorted(referenced_ids - node_ids)
        if missing_nodes:
            raise ValueError(f"source rows reference missing staging expressions: {missing_nodes[:5]}")
        node_by_id = {int(row[0]): row[1:] for row in nodes}
        claim_rows = [(*node_by_id[int(local_id)][:3], marker) for local_id, marker in claims]
        locale_link_rows = [
            (*node_by_id[int(local_id)][:3], locale_code)
            for local_id, locale_code in locale_links
        ]
        reading_rows = [
            (*node_by_id[int(local_id)][:3], locale_code, scheme, value)
            for local_id, locale_code, scheme, value in readings
        ]
        edge_rows: list[tuple[object, ...]] = []
        edge_annotation_updates: list[str] = []
        for edge in edges:
            _edge_id, a_id, b_id, relation_mask, score, marker = edge[:6]
            edge_rows.append(
                (
                    *node_by_id[int(a_id)][:3],
                    *node_by_id[int(b_id)][:3],
                    relation_mask,
                    score,
                    marker,
                )
            )
            if edge_annotation_column:
                raw_annotations = edge[6] if len(edge) > 6 else "[]"
                source_annotations = _source_edge_annotations(raw_annotations, str(marker))
                # Additive releases only need to write non-empty annotations;
                # emitting one expensive natural-key UPDATE for every ordinary
                # edge can exceed D1's per-command CPU budget. Replace mode
                # still emits empty updates so stale marker annotations are
                # removed when a source is rebuilt.
                if source_annotations or (replace and not skip_edge_annotation_updates):
                    edge_annotation_updates.append(
                        _annotation_update_sql(
                            a_identity=tuple(node_by_id[int(a_id)][:3]),
                            b_identity=tuple(node_by_id[int(b_id)][:3]),
                            source_marker=str(marker),
                            annotations=source_annotations,
                        )
                    )

        output.parent.mkdir(parents=True, exist_ok=True)
        with output.open("w", encoding="utf-8") as handle:
            handle.write("PRAGMA defer_foreign_keys=TRUE;\n")
            if replace:
                if reconcile_shared:
                    _write_shared_safe_reconcile(
                        handle, source_type=source_type, source_name=source_name
                    )
                else:
                    _write_replace_deletes(
                        handle, source_type=source_type, source_name=source_name
                    )
            handle.write(
                "INSERT OR IGNORE INTO sources (type,name) VALUES "
                f"({_literal(source_type)},{_literal(source_name)});\n"
            )
            for locale in locales:
                handle.write(
                    "INSERT OR IGNORE INTO language_locales "
                    "(code,language_id,script_code,orthography,region_code,place_path,name,name_en,latitude,longitude) "
                    "SELECT "
                    + ",".join(
                        [
                            _literal(locale[0]),
                            "l.id",
                            *(_literal(value) for value in locale[2:]),
                        ]
                    )
                    + f" FROM languages l WHERE l.code={_literal(locale[1])};\n"
                )

            # Keep the reconcile/delete commands out of the first expression
            # insert batch.  Subsequent CTE batches can still be grouped by
            # the managed runner's byte cap.
            if replace:
                handle.write("-- langmap:batch\n")
            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "pos_mask", "created_at"),
                [row[1:] for row in nodes],
                "INSERT OR IGNORE INTO expressions "
                "(language_id,text,homograph_index,pos_mask,source_id,created_at) "
                "SELECT l.id,r.text,r.homograph_index,r.pos_mask,s.id,r.created_at "
                "FROM rows r JOIN languages l ON l.code=r.language_code "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};",
                batch_size=rows_per_insert,
            )
            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "source_marker"),
                claim_rows,
                "INSERT OR IGNORE INTO expression_sources (expression_id,source_id,source_marker) "
                "SELECT e.id,s.id,r.source_marker FROM rows r "
                "JOIN languages l ON l.code=r.language_code "
                "JOIN expressions e ON e.language_id=l.id AND e.text=r.text AND e.homograph_index=r.homograph_index "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};",
                batch_size=rows_per_insert,
            )
            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "locale_code"),
                locale_link_rows,
                "INSERT OR IGNORE INTO expression_locale_links (expression_id,locale_id) "
                "SELECT e.id,ll.id FROM rows r JOIN languages l ON l.code=r.language_code "
                "JOIN expressions e ON e.language_id=l.id AND e.text=r.text AND e.homograph_index=r.homograph_index "
                "JOIN language_locales ll ON ll.code=r.locale_code;",
                batch_size=rows_per_insert,
            )
            _write_cte_batches(
                handle,
                ("language_code", "text", "homograph_index", "locale_code", "scheme", "value"),
                reading_rows,
                "INSERT OR IGNORE INTO expression_readings (expression_id,locale_id,scheme,value,source_id) "
                "SELECT e.id,ll.id,r.scheme,r.value,s.id FROM rows r "
                "JOIN languages l ON l.code=r.language_code "
                "JOIN expressions e ON e.language_id=l.id AND e.text=r.text AND e.homograph_index=r.homograph_index "
                "JOIN language_locales ll ON ll.code=r.locale_code "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};",
                batch_size=rows_per_insert,
            )
            edge_columns = (
                "a_language_code", "a_text", "a_homograph_index",
                "b_language_code", "b_text", "b_homograph_index",
                "relation_mask", "score", "source_marker",
            )
            edge_joins = (
                "FROM rows r "
                "JOIN languages al ON al.code=r.a_language_code "
                "JOIN expressions a ON a.language_id=al.id AND a.text=r.a_text AND a.homograph_index=r.a_homograph_index "
                "JOIN languages bl ON bl.code=r.b_language_code "
                "JOIN expressions b ON b.language_id=bl.id AND b.text=r.b_text AND b.homograph_index=r.b_homograph_index "
            )
            _write_cte_batches(
                handle,
                edge_columns,
                edge_rows,
                "INSERT OR IGNORE INTO expression_edges (expression_a_id,expression_b_id,relation_mask,score) "
                "SELECT DISTINCT CASE WHEN a.id<b.id THEN a.id ELSE b.id END,"
                "CASE WHEN a.id<b.id THEN b.id ELSE a.id END,r.relation_mask,r.score "
                + edge_joins
                + ";",
                batch_size=edge_batch_size,
                force_batch=replace,
            )
            _write_cte_batches(
                handle,
                edge_columns,
                edge_rows,
                "INSERT OR IGNORE INTO expression_edge_sources (edge_id,source_id,source_marker) "
                "SELECT e.id,s.id,r.source_marker "
                + edge_joins
                + "JOIN expression_edges e ON e.expression_a_id=CASE WHEN a.id<b.id THEN a.id ELSE b.id END "
                "AND e.expression_b_id=CASE WHEN a.id<b.id THEN b.id ELSE a.id END "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};",
                batch_size=edge_batch_size,
                force_batch=replace,
            )
            if edge_annotation_updates:
                handle.write("-- Merge source-scoped edge annotations after edge identity resolution.\n")
                for update in edge_annotation_updates:
                    handle.write("-- langmap:batch\n")
                    handle.write(update)
            if remap_managed_handbook:
                handle.write("-- langmap:batch\n")
                _write_managed_handbook_remap(
                    handle,
                    source_type=source_type,
                    source_name=source_name,
                )
            handle.write("PRAGMA defer_foreign_keys=FALSE;\n")

        counts = {
            "expressions": len(nodes),
            "expression_sources": len(claims),
            "expression_locale_links": len(locale_links),
            "expression_readings": len(readings),
            "expression_edges": len({int(row[0]) for row in edges}),
            "expression_edge_sources": len(edges),
            "language_locales": len(locales),
            "sources": 1,
        }
        if manifest is not None:
            manifest.parent.mkdir(parents=True, exist_ok=True)
            payload = {
                "schema_version": 1,
                "source": {"type": source_type, "name": source_name},
                "locale_codes": sorted(found_codes),
                "expected_counts": counts,
                "replace": replace,
                "reconcile_shared": reconcile_shared,
                "skip_edge_annotation_updates": skip_edge_annotation_updates,
                "delta_sha256": _sha256(output),
            }
            temporary = manifest.with_name(f".{manifest.name}.{os.getpid()}.tmp")
            temporary.write_text(json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
            os.replace(temporary, manifest)
        return counts
    finally:
        connection.close()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--staging", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--source-type", required=True)
    parser.add_argument("--source-name", required=True)
    parser.add_argument("--locale-code", action="append", required=True, dest="locale_codes")
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--rows-per-insert", type=int, default=100)
    parser.add_argument("--edge-rows-per-insert", type=int, default=None)
    parser.add_argument(
        "--replace",
        action="store_true",
        help="emit a source-scoped DELETE preamble so the delta replaces the "
        "source's existing rows instead of only adding to them",
    )
    parser.add_argument(
        "--reconcile-shared",
        action="store_true",
        help="with --replace, remove only this source's assertions while preserving shared expressions and edges",
    )
    parser.add_argument(
        "--skip-edge-annotation-updates",
        action="store_true",
        help="omit source-scoped edge annotation UPDATE statements for a faster lexical repair release",
    )
    parser.add_argument(
        "--remap-managed-handbook",
        action="store_true",
        help="after an additive release, move managed handbook items to the newest "
        "English expression for each source marker",
    )
    args = parser.parse_args(argv)
    if not args.staging.is_file():
        print(f"staging SQLite not found: {args.staging}", file=sys.stderr)
        return 1
    try:
        counts = export_source_delta(
            args.staging,
            args.output,
            source_type=args.source_type,
            source_name=args.source_name,
        locale_codes=args.locale_codes,
        manifest=args.manifest,
        rows_per_insert=args.rows_per_insert,
        edge_rows_per_insert=args.edge_rows_per_insert,
            replace=args.replace,
            reconcile_shared=args.reconcile_shared,
            skip_edge_annotation_updates=args.skip_edge_annotation_updates,
            remap_managed_handbook=args.remap_managed_handbook,
        )
    except (OSError, sqlite3.Error, ValueError) as exc:
        print(f"export failed: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(counts, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
