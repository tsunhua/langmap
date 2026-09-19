#!/usr/bin/env python3
"""Normalize expression text to sentence case and merge duplicate nodes.

The command is intentionally dry-run by default.  Use ``--apply`` only after
reviewing the JSON report and making a backup of the SQLite/D1 file.

Usage:
  python3 scripts/db/normalize_expression_case.py --database path/to/local.sqlite
  python3 scripts/db/normalize_expression_case.py --database path/to/local.sqlite --apply
"""

from __future__ import annotations

import argparse
from collections import defaultdict
import json
import sqlite3
from pathlib import Path
import sys
from typing import Any, Iterable

# Direct script execution puts ``scripts/db`` on sys.path rather than the
# repository root; make the shared importer helper available in that mode too.
PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts.dictionary.text_identity import canonicalize_expression_text


def table_exists(connection: sqlite3.Connection, table: str) -> bool:
    return connection.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", (table,)
    ).fetchone() is not None


def _expression_rows(connection: sqlite3.Connection) -> list[sqlite3.Row]:
    return connection.execute(
        "SELECT id,language_id,text,homograph_index,pos_mask,source_id,created_by "
        "FROM expressions ORDER BY id"
    ).fetchall()


def _reference_counts(connection: sqlite3.Connection) -> dict[int, int]:
    counts: defaultdict[int, int] = defaultdict(int)

    def add(table: str, column: str) -> None:
        if not table_exists(connection, table):
            return
        for row in connection.execute(f"SELECT {column},COUNT(*) FROM {table} WHERE {column} IS NOT NULL GROUP BY {column}"):
            counts[int(row[0])] += int(row[1])

    for table, column in (
        ("expression_locale_links", "expression_id"),
        ("expression_readings", "expression_id"),
        ("expression_edges", "expression_a_id"),
        ("expression_edges", "expression_b_id"),
        ("expression_sources", "expression_id"),
        ("handbook_section_items", "expression_id"),
        ("morphological_dimensions", "name_expression_id"),
        ("morphological_features", "name_expression_id"),
        ("expression_form_edges", "form_id"),
        ("expression_form_edges", "lemma_id"),
        ("expression_splits", "source_expression_id"),
        ("expression_splits", "target_expression_id"),
        ("ui_messages", "source_expression_id"),
        ("languages", "name_expression_id"),
        ("language_locales", "name_expression_id"),
        ("scripts", "name_expression_id"),
        ("regions", "name_expression_id"),
    ):
        add(table, column)
    return dict(counts)


def _build_groups(
    rows: Iterable[sqlite3.Row], reference_counts: dict[int, int]
) -> tuple[dict[int, int], dict[int, str], dict[tuple[int, str, int], list[int]]]:
    groups: dict[tuple[int, str, int], list[int]] = defaultdict(list)
    texts: dict[int, str] = {}
    for row in rows:
        expression_id = int(row["id"])
        normalized = canonicalize_expression_text(str(row["text"]))
        texts[expression_id] = normalized
        groups[(int(row["language_id"]), normalized, int(row["homograph_index"]))].append(expression_id)

    duplicate_to_survivor: dict[int, int] = {}
    for group_ids in groups.values():
        if len(group_ids) < 2:
            continue
        target_text = texts[group_ids[0]]
        winner = min(
            group_ids,
            key=lambda expression_id: (
                0 if next(
                    row["text"]
                    for row in rows
                    if int(row["id"]) == expression_id
                ) == target_text else 1,
                -reference_counts.get(expression_id, 0),
                expression_id,
            ),
        )
        for expression_id in group_ids:
            if expression_id != winner:
                duplicate_to_survivor[expression_id] = winner
    return duplicate_to_survivor, texts, groups


def _merge_scalar_references(
    connection: sqlite3.Connection, mapping: dict[int, int], table: str, column: str
) -> None:
    if not mapping or not table_exists(connection, table):
        return
    for old_id, survivor_id in mapping.items():
        connection.execute(
            f"UPDATE {table} SET {column}=? WHERE {column}=?", (survivor_id, old_id)
        )


def _merge_links(connection: sqlite3.Connection, mapping: dict[int, int]) -> None:
    if not mapping:
        return
    if table_exists(connection, "expression_locale_links"):
        for old_id, survivor_id in mapping.items():
            connection.execute(
                "INSERT OR IGNORE INTO expression_locale_links(expression_id,locale_id) "
                "SELECT ?,locale_id FROM expression_locale_links WHERE expression_id=?",
                (survivor_id, old_id),
            )
            connection.execute(
                "DELETE FROM expression_locale_links WHERE expression_id=?", (old_id,)
            )
    if table_exists(connection, "expression_readings"):
        for old_id, survivor_id in mapping.items():
            rows = connection.execute(
                "SELECT locale_id,scheme,value,source_id FROM expression_readings WHERE expression_id=?",
                (old_id,),
            ).fetchall()
            for row in rows:
                connection.execute(
                    "INSERT OR IGNORE INTO expression_readings(expression_id,locale_id,scheme,value,source_id) "
                    "VALUES(?,?,?,?,?)",
                    (survivor_id, row["locale_id"], row["scheme"], row["value"], row["source_id"]),
                )
                if row["source_id"] is not None:
                    connection.execute(
                        "UPDATE expression_readings SET source_id=COALESCE(source_id,?) "
                        "WHERE expression_id=? AND locale_id=? AND scheme=? AND value=?",
                        (row["source_id"], survivor_id, row["locale_id"], row["scheme"], row["value"]),
                    )
            connection.execute("DELETE FROM expression_readings WHERE expression_id=?", (old_id,))
    if table_exists(connection, "expression_sources"):
        for old_id, survivor_id in mapping.items():
            connection.execute(
                "INSERT OR IGNORE INTO expression_sources(expression_id,source_id,source_marker) "
                "SELECT ?,source_id,source_marker FROM expression_sources WHERE expression_id=?",
                (survivor_id, old_id),
            )
            connection.execute("DELETE FROM expression_sources WHERE expression_id=?", (old_id,))


def _merge_handbook_items(connection: sqlite3.Connection, mapping: dict[int, int]) -> None:
    if not mapping or not table_exists(connection, "handbook_section_items"):
        return
    for old_id, survivor_id in mapping.items():
        rows = connection.execute(
            "SELECT section_id,position FROM handbook_section_items WHERE expression_id=?",
            (old_id,),
        ).fetchall()
        for row in rows:
            existing = connection.execute(
                "SELECT 1 FROM handbook_section_items WHERE section_id=? AND expression_id=?",
                (row["section_id"], survivor_id),
            ).fetchone()
            if existing is not None:
                connection.execute(
                    "DELETE FROM handbook_section_items WHERE section_id=? AND position=?",
                    (row["section_id"], row["position"]),
                )
            else:
                connection.execute(
                    "UPDATE handbook_section_items SET expression_id=? WHERE section_id=? AND position=?",
                    (survivor_id, row["section_id"], row["position"]),
                )


def _merge_edge_children(
    connection: sqlite3.Connection, old_edge_id: int, new_edge_id: int | None
) -> None:
    if new_edge_id is None:
        if table_exists(connection, "expression_split_moves"):
            connection.execute("DELETE FROM expression_split_moves WHERE edge_id=?", (old_edge_id,))
        if table_exists(connection, "expression_edge_sources"):
            connection.execute("DELETE FROM expression_edge_sources WHERE edge_id=?", (old_edge_id,))
        if table_exists(connection, "edge_votes"):
            connection.execute("DELETE FROM edge_votes WHERE edge_id=?", (old_edge_id,))
        return
    if table_exists(connection, "expression_edge_sources"):
        connection.execute(
            "INSERT OR IGNORE INTO expression_edge_sources(edge_id,source_id,source_marker) "
            "SELECT ?,source_id,source_marker FROM expression_edge_sources WHERE edge_id=?",
            (new_edge_id, old_edge_id),
        )
    if table_exists(connection, "edge_votes"):
        connection.execute(
            "INSERT OR IGNORE INTO edge_votes(user_id,edge_id,vote) "
            "SELECT user_id,?,vote FROM edge_votes WHERE edge_id=?",
            (new_edge_id, old_edge_id),
        )
    if table_exists(connection, "expression_split_moves"):
        connection.execute(
            "INSERT OR IGNORE INTO expression_split_moves(split_id,edge_id) "
            "SELECT split_id,? FROM expression_split_moves WHERE edge_id=?",
            (new_edge_id, old_edge_id),
        )
    if table_exists(connection, "expression_edge_sources"):
        connection.execute("DELETE FROM expression_edge_sources WHERE edge_id=?", (old_edge_id,))
    if table_exists(connection, "edge_votes"):
        connection.execute("DELETE FROM edge_votes WHERE edge_id=?", (old_edge_id,))


def _merge_edge_annotations(
    connection: sqlite3.Connection, old_edge_id: int, new_edge_id: int
) -> None:
    columns = {
        str(row[1])
        for row in connection.execute("PRAGMA table_info(expression_edges)")
    }
    if "annotations_json" not in columns:
        return
    rows = connection.execute(
        "SELECT id,annotations_json FROM expression_edges WHERE id IN (?,?) ORDER BY id",
        (new_edge_id, old_edge_id),
    ).fetchall()
    annotations: list[dict[str, Any]] = []
    identities: set[tuple[object, ...]] = set()
    for row in rows:
        try:
            values = json.loads(str(row["annotations_json"] or "[]"))
        except (TypeError, ValueError):
            values = []
        if not isinstance(values, list):
            continue
        for value in values:
            if not isinstance(value, dict):
                continue
            text = value.get("text")
            side = value.get("side")
            if not isinstance(text, str) or not text.strip() or side not in {"a", "b", "both"}:
                continue
            source_id = value.get("source_id")
            if not isinstance(source_id, int) and source_id is not None:
                source_id = None
            source_marker = value.get("source_marker")
            if not isinstance(source_marker, str) or not source_marker:
                source_marker = None
            item = {
                "text": text.strip(),
                "side": side,
                "source_id": source_id,
                "source_marker": source_marker,
            }
            identity = (item["text"], item["side"], item["source_id"], item["source_marker"])
            if identity not in identities:
                identities.add(identity)
                annotations.append(item)
    annotations.sort(key=lambda item: (
        str(item["side"]),
        -1 if item["source_id"] is None else int(item["source_id"]),
        str(item["source_marker"] or ""),
        str(item["text"]),
    ))
    connection.execute(
        "UPDATE expression_edges SET annotations_json=? WHERE id=?",
        (json.dumps(annotations[:20], ensure_ascii=False, sort_keys=True, separators=(",", ":")), new_edge_id),
    )


def _merge_expression_edges(connection: sqlite3.Connection, mapping: dict[int, int]) -> dict[str, int]:
    if not mapping or not table_exists(connection, "expression_edges"):
        return {"edge_groups_merged": 0, "edges_removed": 0, "self_edges_removed": 0}
    rows = connection.execute(
        "SELECT id,expression_a_id,expression_b_id,relation_mask,score,created_by "
        "FROM expression_edges ORDER BY id"
    ).fetchall()
    groups: dict[tuple[int, int], list[sqlite3.Row]] = defaultdict(list)
    for row in rows:
        endpoints = sorted((mapping.get(int(row["expression_a_id"]), int(row["expression_a_id"])), mapping.get(int(row["expression_b_id"]), int(row["expression_b_id"]))))
        groups[(endpoints[0], endpoints[1])].append(row)

    survivors: list[tuple[sqlite3.Row, tuple[int, int]]] = []
    edges_removed = 0
    self_edges_removed = 0
    for target_pair, group_rows in groups.items():
        if target_pair[0] == target_pair[1]:
            for row in group_rows:
                _merge_edge_children(connection, int(row["id"]), None)
                connection.execute("DELETE FROM expression_edges WHERE id=?", (row["id"],))
                edges_removed += 1
                self_edges_removed += 1
            continue
        survivor = min(
            group_rows,
            key=lambda row: (
                0 if (int(row["expression_a_id"]), int(row["expression_b_id"])) == target_pair else 1,
                int(row["id"]),
            ),
        )
        survivors.append((survivor, target_pair))
        survivor_id = int(survivor["id"])
        for row in group_rows:
            edge_id = int(row["id"])
            if edge_id == survivor_id:
                continue
            _merge_edge_annotations(connection, edge_id, survivor_id)
            _merge_edge_children(connection, edge_id, survivor_id)
            connection.execute(
                "UPDATE expression_edges SET relation_mask=?,score=?,created_by=COALESCE(created_by,?) WHERE id=?",
                (
                    int(connection.execute("SELECT relation_mask FROM expression_edges WHERE id=?", (survivor_id,)).fetchone()[0])
                    | int(row["relation_mask"]),
                    max(int(connection.execute("SELECT score FROM expression_edges WHERE id=?", (survivor_id,)).fetchone()[0]), int(row["score"])),
                    row["created_by"],
                    survivor_id,
                ),
            )
            if table_exists(connection, "expression_split_moves"):
                connection.execute("DELETE FROM expression_split_moves WHERE edge_id=?", (edge_id,))
            connection.execute("DELETE FROM expression_edges WHERE id=?", (edge_id,))
            edges_removed += 1

    # Use temporary negative endpoints so two survivor pairs can safely swap
    # into each other's old UNIQUE key before the final update.
    for row, _ in survivors:
        edge_id = int(row["id"])
        connection.execute(
            "UPDATE expression_edges SET expression_a_id=?,expression_b_id=? WHERE id=?",
            (-2 * edge_id, -2 * edge_id + 1, edge_id),
        )
    for row, target_pair in survivors:
        connection.execute(
            "UPDATE expression_edges SET expression_a_id=?,expression_b_id=? WHERE id=?",
            (target_pair[0], target_pair[1], row["id"]),
        )
    return {
        "edge_groups_merged": sum(1 for rows_in_group in groups.values() if len(rows_in_group) > 1),
        "edges_removed": edges_removed,
        "self_edges_removed": self_edges_removed,
    }


def _merge_form_edges(connection: sqlite3.Connection, mapping: dict[int, int]) -> dict[str, int]:
    if not mapping or not table_exists(connection, "expression_form_edges"):
        return {"form_edge_groups_merged": 0, "form_edges_removed": 0}
    rows = connection.execute(
        "SELECT id,form_id,lemma_id,created_by FROM expression_form_edges ORDER BY id"
    ).fetchall()
    groups: dict[tuple[int, int], list[sqlite3.Row]] = defaultdict(list)
    for row in rows:
        pair = (
            mapping.get(int(row["form_id"]), int(row["form_id"])),
            mapping.get(int(row["lemma_id"]), int(row["lemma_id"])),
        )
        groups[pair].append(row)
    survivors: list[tuple[sqlite3.Row, tuple[int, int]]] = []
    removed = 0
    for target_pair, group_rows in groups.items():
        if target_pair[0] == target_pair[1]:
            for row in group_rows:
                if table_exists(connection, "expression_form_edge_features"):
                    connection.execute(
                        "DELETE FROM expression_form_edge_features WHERE edge_id=?", (row["id"],)
                    )
                connection.execute("DELETE FROM expression_form_edges WHERE id=?", (row["id"],))
                removed += 1
            continue
        survivor = min(
            group_rows,
            key=lambda row: (
                0 if (int(row["form_id"]), int(row["lemma_id"])) == target_pair else 1,
                int(row["id"]),
            ),
        )
        survivors.append((survivor, target_pair))
        survivor_id = int(survivor["id"])
        for row in group_rows:
            edge_id = int(row["id"])
            if edge_id == survivor_id:
                continue
            if table_exists(connection, "expression_form_edge_features"):
                connection.execute(
                    "INSERT OR IGNORE INTO expression_form_edge_features(edge_id,feature_code) "
                    "SELECT ?,feature_code FROM expression_form_edge_features WHERE edge_id=?",
                    (survivor_id, edge_id),
                )
                connection.execute(
                    "DELETE FROM expression_form_edge_features WHERE edge_id=?", (edge_id,)
                )
            connection.execute(
                "UPDATE expression_form_edges SET created_by=COALESCE(created_by,?) WHERE id=?",
                (row["created_by"], survivor_id),
            )
            connection.execute("DELETE FROM expression_form_edges WHERE id=?", (edge_id,))
            removed += 1
    for row, _ in survivors:
        edge_id = int(row["id"])
        connection.execute(
            "UPDATE expression_form_edges SET form_id=?,lemma_id=? WHERE id=?",
            (-2 * edge_id, -2 * edge_id + 1, edge_id),
        )
    for row, target_pair in survivors:
        connection.execute(
            "UPDATE expression_form_edges SET form_id=?,lemma_id=? WHERE id=?",
            (target_pair[0], target_pair[1], row["id"]),
        )
    return {
        "form_edge_groups_merged": sum(1 for rows_in_group in groups.values() if len(rows_in_group) > 1),
        "form_edges_removed": removed,
    }


def _refresh_statistics(connection: sqlite3.Connection) -> None:
    if not table_exists(connection, "language_statistics"):
        return
    connection.execute(
        """
        INSERT OR REPLACE INTO language_statistics
          (language_id, expression_count, locale_count, active_ui_locale_count, updated_at)
        SELECT l.id,
          (SELECT COUNT(*) FROM expressions e WHERE e.language_id=l.id),
          (SELECT COUNT(*) FROM language_locales ll WHERE ll.language_id=l.id),
          (SELECT COUNT(*) FROM ui_locales ul JOIN language_locales ll ON ll.id=ul.locale_id
             WHERE ll.language_id=l.id AND ul.status='active'),
          CURRENT_TIMESTAMP
        FROM languages l
        """
    )


def _validate(connection: sqlite3.Connection) -> dict[str, Any]:
    noncanonical = [
        int(row["id"])
        for row in connection.execute("SELECT id,text FROM expressions ORDER BY id")
        if canonicalize_expression_text(str(row["text"])) != str(row["text"])
    ]
    groups: defaultdict[tuple[int, str, int], int] = defaultdict(int)
    for row in connection.execute("SELECT language_id,text,homograph_index FROM expressions"):
        groups[(int(row["language_id"]), canonicalize_expression_text(str(row["text"])), int(row["homograph_index"]))] += 1
    duplicate_groups = sum(1 for count in groups.values() if count > 1)
    foreign_key_errors = [tuple(row) for row in connection.execute("PRAGMA foreign_key_check")]
    return {
        "noncanonical_expressions": len(noncanonical),
        "normalized_duplicate_groups": duplicate_groups,
        "foreign_key_errors": len(foreign_key_errors),
    }


def normalize_database(connection: sqlite3.Connection, *, apply: bool) -> dict[str, Any]:
    connection.row_factory = sqlite3.Row
    rows = _expression_rows(connection)
    before_count = len(rows)
    reference_counts = _reference_counts(connection)
    mapping, normalized_texts, groups = _build_groups(rows, reference_counts)
    report: dict[str, Any] = {
        "apply": apply,
        "expressions_before": before_count,
        "canonical_text_updates": sum(
            str(row["text"]) != normalized_texts[int(row["id"])] for row in rows
        ),
        "candidate_duplicate_groups": sum(1 for group in groups.values() if len(group) > 1),
        "candidate_merges": len(mapping),
    }
    if not apply or not mapping:
        report["expressions_after"] = before_count
        return report

    # This migration deliberately disables immediate FK checks while moving
    # references and resolving UNIQUE-key collisions. Validation runs with FK
    # enforcement restored before the report is returned.
    connection.execute("PRAGMA foreign_keys=OFF")
    connection.execute("BEGIN IMMEDIATE")
    try:
        by_id = {int(row["id"]): row for row in rows}
        for old_id, survivor_id in mapping.items():
            old_row = by_id[old_id]
            survivor_row = by_id[survivor_id]
            pos_mask = int(survivor_row["pos_mask"]) | int(old_row["pos_mask"])
            source_id = survivor_row["source_id"] or old_row["source_id"]
            created_by = survivor_row["created_by"] or old_row["created_by"]
            connection.execute(
                "UPDATE expressions SET pos_mask=?,source_id=?,created_by=? WHERE id=?",
                (pos_mask, source_id, created_by, survivor_id),
            )
        for expression_id, text in normalized_texts.items():
            if expression_id not in mapping:
                connection.execute("UPDATE expressions SET text=? WHERE id=?", (text, expression_id))

        _merge_scalar_references(connection, mapping, "languages", "name_expression_id")
        _merge_scalar_references(connection, mapping, "language_locales", "name_expression_id")
        _merge_scalar_references(connection, mapping, "scripts", "name_expression_id")
        _merge_scalar_references(connection, mapping, "regions", "name_expression_id")
        _merge_scalar_references(connection, mapping, "morphological_dimensions", "name_expression_id")
        _merge_scalar_references(connection, mapping, "morphological_features", "name_expression_id")
        _merge_scalar_references(connection, mapping, "ui_messages", "source_expression_id")
        _merge_links(connection, mapping)
        _merge_handbook_items(connection, mapping)

        if table_exists(connection, "expression_splits"):
            for old_id, survivor_id in mapping.items():
                connection.execute(
                    "UPDATE expression_splits SET source_expression_id=? WHERE source_expression_id=?",
                    (survivor_id, old_id),
                )
                connection.execute(
                    "UPDATE expression_splits SET target_expression_id=? WHERE target_expression_id=?",
                    (survivor_id, old_id),
                )

        edge_report = _merge_expression_edges(connection, mapping)
        form_report = _merge_form_edges(connection, mapping)

        for old_id in mapping:
            connection.execute("DELETE FROM expressions WHERE id=?", (old_id,))
        if table_exists(connection, "ui_messages"):
            connection.execute(
                "UPDATE ui_messages SET source_text=(SELECT text FROM expressions e WHERE e.id=ui_messages.source_expression_id)"
            )
        _refresh_statistics(connection)
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.execute("PRAGMA foreign_keys=ON")

    report.update(edge_report)
    report.update(form_report)
    report["expressions_after"] = int(connection.execute("SELECT COUNT(*) FROM expressions").fetchone()[0])
    report.update(_validate(connection))
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", type=Path, required=True)
    parser.add_argument("--apply", action="store_true", help="apply changes; default is a dry-run report")
    args = parser.parse_args()
    connection = sqlite3.connect(args.database)
    try:
        report = normalize_database(connection, apply=args.apply)
        print(json.dumps(report, ensure_ascii=False, sort_keys=True))
        return 0 if report.get("foreign_key_errors", 0) == 0 else 1
    finally:
        connection.close()


if __name__ == "__main__":
    raise SystemExit(main())
