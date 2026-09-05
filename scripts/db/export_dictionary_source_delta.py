#!/usr/bin/env python3
"""Export one dictionary source as a baseline-free, natural-key SQL release.

The staging database is used only to describe rows owned by one source. Integer
IDs from staging are temporary join keys inside the generated SQL; production
identities are resolved by source name, locale code, language code, expression
identity, and edge endpoints.
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
) -> None:
    names = ", ".join(f'"{column}"' for column in columns)
    for start in range(0, len(rows), batch_size):
        batch = rows[start : start + batch_size]
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


def export_source_delta(
    staging: Path,
    output: Path,
    *,
    source_type: str,
    source_name: str,
    locale_codes: Sequence[str],
    manifest: Path | None = None,
    rows_per_insert: int = 100,
) -> dict[str, int]:
    if rows_per_insert < 1:
        raise ValueError("rows_per_insert must be positive")
    if not locale_codes:
        raise ValueError("at least one locale code is required")

    connection = sqlite3.connect(staging, timeout=60)
    try:
        source = connection.execute(
            "SELECT id FROM sources WHERE type=? AND name=?",
            (source_type, source_name),
        ).fetchone()
        if source is None:
            raise ValueError(f"source not found in staging: {source_type}/{source_name}")
        source_id = int(source[0])

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
        edges = _rows(
            connection,
            """
            SELECT e.id,e.expression_a_id,e.expression_b_id,e.relation_mask,e.score,
                   es.source_marker
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
        edge_rows = [
            (
                *node_by_id[int(a_id)][:3],
                *node_by_id[int(b_id)][:3],
                relation_mask,
                score,
                marker,
            )
            for _edge_id, a_id, b_id, relation_mask, score, marker in edges
        ]

        output.parent.mkdir(parents=True, exist_ok=True)
        with output.open("w", encoding="utf-8") as handle:
            handle.write("PRAGMA defer_foreign_keys=TRUE;\n")
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
                batch_size=rows_per_insert,
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
                batch_size=rows_per_insert,
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
        )
    except (OSError, sqlite3.Error, ValueError) as exc:
        print(f"export failed: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(counts, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
