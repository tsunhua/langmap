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


def _write_values(
    handle,
    table: str,
    columns: Sequence[str],
    rows: Sequence[Sequence[object]],
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
        handle.write(f'INSERT INTO "{table}" ({names}) VALUES\n  {values};\n')


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

            handle.write(
                "CREATE TEMP TABLE _dictionary_nodes ("
                "local_id INTEGER PRIMARY KEY,language_code TEXT NOT NULL,text TEXT NOT NULL,"
                "homograph_index INTEGER NOT NULL,pos_mask INTEGER NOT NULL,created_at TEXT NOT NULL);\n"
            )
            _write_values(
                handle,
                "_dictionary_nodes",
                ("local_id", "language_code", "text", "homograph_index", "pos_mask", "created_at"),
                nodes,
                batch_size=rows_per_insert,
            )
            handle.write(
                "INSERT OR IGNORE INTO expressions "
                "(language_id,text,homograph_index,pos_mask,source_id,created_at) "
                "SELECT l.id,n.text,n.homograph_index,n.pos_mask,s.id,n.created_at "
                "FROM _dictionary_nodes n JOIN languages l ON l.code=n.language_code "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)} "
                "ORDER BY n.local_id;\n"
            )
            handle.write(
                "CREATE TEMP TABLE _dictionary_expression_ids ("
                "local_id INTEGER PRIMARY KEY,expression_id INTEGER NOT NULL UNIQUE);\n"
                "INSERT INTO _dictionary_expression_ids (local_id,expression_id) "
                "SELECT n.local_id,e.id FROM _dictionary_nodes n "
                "JOIN languages l ON l.code=n.language_code "
                "JOIN expressions e ON e.language_id=l.id AND e.text=n.text "
                "AND e.homograph_index=n.homograph_index ORDER BY n.local_id;\n"
            )

            handle.write(
                "CREATE TEMP TABLE _dictionary_claims ("
                "local_id INTEGER NOT NULL,source_marker TEXT NOT NULL);\n"
            )
            _write_values(handle, "_dictionary_claims", ("local_id", "source_marker"), claims, batch_size=rows_per_insert)
            handle.write(
                "INSERT OR IGNORE INTO expression_sources (expression_id,source_id,source_marker) "
                "SELECT m.expression_id,s.id,c.source_marker FROM _dictionary_claims c "
                "JOIN _dictionary_expression_ids m ON m.local_id=c.local_id "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};\n"
            )

            handle.write(
                "CREATE TEMP TABLE _dictionary_locale_links ("
                "local_id INTEGER NOT NULL,locale_code TEXT NOT NULL);\n"
            )
            _write_values(handle, "_dictionary_locale_links", ("local_id", "locale_code"), locale_links, batch_size=rows_per_insert)
            handle.write(
                "INSERT OR IGNORE INTO expression_locale_links (expression_id,locale_id) "
                "SELECT m.expression_id,ll.id FROM _dictionary_locale_links x "
                "JOIN _dictionary_expression_ids m ON m.local_id=x.local_id "
                "JOIN language_locales ll ON ll.code=x.locale_code;\n"
            )

            handle.write(
                "CREATE TEMP TABLE _dictionary_readings ("
                "local_id INTEGER NOT NULL,locale_code TEXT NOT NULL,scheme TEXT NOT NULL,value TEXT NOT NULL);\n"
            )
            _write_values(handle, "_dictionary_readings", ("local_id", "locale_code", "scheme", "value"), readings, batch_size=rows_per_insert)
            handle.write(
                "INSERT OR IGNORE INTO expression_readings (expression_id,locale_id,scheme,value,source_id) "
                "SELECT m.expression_id,ll.id,r.scheme,r.value,s.id FROM _dictionary_readings r "
                "JOIN _dictionary_expression_ids m ON m.local_id=r.local_id "
                "JOIN language_locales ll ON ll.code=r.locale_code "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};\n"
            )

            handle.write(
                "CREATE TEMP TABLE _dictionary_edges ("
                "local_edge_id INTEGER NOT NULL,a_local_id INTEGER NOT NULL,b_local_id INTEGER NOT NULL,"
                "relation_mask INTEGER NOT NULL,score INTEGER NOT NULL,source_marker TEXT NOT NULL);\n"
            )
            _write_values(
                handle,
                "_dictionary_edges",
                ("local_edge_id", "a_local_id", "b_local_id", "relation_mask", "score", "source_marker"),
                edges,
                batch_size=rows_per_insert,
            )
            handle.write(
                "INSERT OR IGNORE INTO expression_edges "
                "(expression_a_id,expression_b_id,relation_mask,score) "
                "SELECT DISTINCT CASE WHEN a.expression_id<b.expression_id THEN a.expression_id ELSE b.expression_id END,"
                "CASE WHEN a.expression_id<b.expression_id THEN b.expression_id ELSE a.expression_id END,"
                "x.relation_mask,x.score FROM _dictionary_edges x "
                "JOIN _dictionary_expression_ids a ON a.local_id=x.a_local_id "
                "JOIN _dictionary_expression_ids b ON b.local_id=x.b_local_id;\n"
                "INSERT OR IGNORE INTO expression_edge_sources (edge_id,source_id,source_marker) "
                "SELECT e.id,s.id,x.source_marker FROM _dictionary_edges x "
                "JOIN _dictionary_expression_ids a ON a.local_id=x.a_local_id "
                "JOIN _dictionary_expression_ids b ON b.local_id=x.b_local_id "
                "JOIN expression_edges e ON e.expression_a_id=CASE WHEN a.expression_id<b.expression_id THEN a.expression_id ELSE b.expression_id END "
                "AND e.expression_b_id=CASE WHEN a.expression_id<b.expression_id THEN b.expression_id ELSE a.expression_id END "
                f"JOIN sources s ON s.type={_literal(source_type)} AND s.name={_literal(source_name)};\n"
            )
            handle.write(
                "DROP TABLE _dictionary_edges;\n"
                "DROP TABLE _dictionary_readings;\n"
                "DROP TABLE _dictionary_locale_links;\n"
                "DROP TABLE _dictionary_claims;\n"
                "DROP TABLE _dictionary_expression_ids;\n"
                "DROP TABLE _dictionary_nodes;\n"
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
