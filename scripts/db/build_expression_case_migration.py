#!/usr/bin/env python3
"""Build the data-independent production expression case migration.

The generated SQL deliberately contains no production rows or IDs.  It uses
small primary-key ranges to materialize a temporary case key/map inside D1;
the production dispatcher adds the same explicit batch boundaries when it
executes the split artifact.
"""

from __future__ import annotations

import argparse
from pathlib import Path


RUN = "20260910"
PREFIX = f"_lm_case_{RUN}"
KEYS = f"{PREFIX}_keys"
MAP = f"{PREFIX}_map"
POLICY = f"{PREFIX}_policy"
EDGE = f"{PREFIX}_edge_targets"
FORM = f"{PREFIX}_form_targets"
STEP = 100_000
MAX_EXPRESSION_ID = 8_000_000
RANGES_PER_BATCH = 4


def _case_eligible(alias: str = "e") -> str:
    text = f"trim({alias}.text)"
    return " AND ".join(
        [
            f"{text} GLOB '[A-Za-z]*'",
            f"{text} NOT GLOB '*[^ -~]*'",
            f"NOT ({text} GLOB '*[A-Z]*' AND {text} NOT GLOB '*[a-z]*')",
            f"EXISTS (SELECT 1 FROM expression_locale_links ell "
            f"JOIN language_locales ll ON ll.id = ell.locale_id "
            f"WHERE ell.expression_id = {alias}.id "
            f"AND NOT EXISTS (SELECT 1 FROM {POLICY} p "
            f"WHERE ll.code LIKE p.prefix || '%'))",
        ]
    )


def _normalized(alias: str = "e") -> str:
    text = f"lower(trim({alias}.text))"
    return f"upper(substr({text}, 1, 1)) || substr({text}, 2)"


def _add(lines: list[str], statement: str, *, batch: bool = False) -> None:
    if batch:
        lines.append("-- langmap:batch")
    lines.append(statement.rstrip(";") + ";")


def _add_ranges(
    lines: list[str],
    statement_factory,
) -> None:
    for index, start in enumerate(range(1, MAX_EXPRESSION_ID + 1, STEP)):
        end = min(start + STEP, MAX_EXPRESSION_ID + 1)
        _add(lines, statement_factory(start, end), batch=index % RANGES_PER_BATCH == 0)


def build_sql() -> str:
    lines: list[str] = [
        "-- Data-independent production expression case normalization.",
        "-- Policy: no-case locale prefixes are untouched; complete ASCII",
        "-- all-uppercase expressions (for example UFO) are untouched.",
    ]

    for table in (FORM, EDGE, MAP, KEYS, POLICY):
        _add(lines, f"DROP TABLE IF EXISTS {table}", batch=True)

    _add(lines, f"CREATE TABLE {POLICY} (prefix TEXT PRIMARY KEY)", batch=True)
    _add(
        lines,
        f"INSERT INTO {POLICY}(prefix) VALUES "
        "('cmn-Hans'),('cmn-Hant'),('jpn'),('kor'),('nan-Hant')",
    )
    _add(
        lines,
        f"CREATE TABLE {KEYS} ("
        "expression_id INTEGER PRIMARY KEY,"
        "language_id INTEGER NOT NULL,"
        "homograph_index INTEGER NOT NULL,"
        "normalized_text TEXT NOT NULL)",
        batch=True,
    )
    _add(
        lines,
        f"CREATE INDEX {KEYS}_identity ON {KEYS}"
        "(language_id, homograph_index, normalized_text, expression_id)",
    )
    _add(
        lines,
        f"CREATE TABLE {MAP} ("
        "old_expression_id INTEGER PRIMARY KEY,"
        "survivor_expression_id INTEGER NOT NULL,"
        "target_text TEXT NOT NULL)",
        batch=True,
    )
    _add(lines, f"CREATE INDEX {MAP}_survivor ON {MAP}(survivor_expression_id)")

    _add_ranges(
        lines,
        lambda start, end: (
            f"INSERT OR IGNORE INTO {KEYS}"
            "(expression_id,language_id,homograph_index,normalized_text) "
            f"SELECT e.id,e.language_id,e.homograph_index,{_normalized('e')} "
            f"FROM expressions e WHERE e.id >= {start} AND e.id < {end} "
            f"AND {_case_eligible('e')}"
        ),
    )

    def map_statement(start: int, end: int) -> str:
        return (
            f"WITH candidates AS ("
            f"SELECT k.expression_id,k.normalized_text,"
            f"COALESCE((SELECT e2.id FROM expressions e2 "
            f"WHERE e2.language_id=k.language_id "
            f"AND e2.homograph_index=k.homograph_index "
            f"AND e2.text=k.normalized_text ORDER BY e2.id LIMIT 1),"
            f"(SELECT k2.expression_id FROM {KEYS} k2 "
            f"WHERE k2.language_id=k.language_id "
            f"AND k2.homograph_index=k.homograph_index "
            f"AND k2.normalized_text=k.normalized_text "
            f"ORDER BY k2.expression_id LIMIT 1)) survivor_id "
            f"FROM {KEYS} k WHERE k.expression_id >= {start} "
            f"AND k.expression_id < {end}) "
            f"INSERT OR IGNORE INTO {MAP}"
            "(old_expression_id,survivor_expression_id,target_text) "
            "SELECT expression_id,survivor_id,normalized_text FROM candidates "
            "WHERE survivor_id <> expression_id"
        )

    _add_ranges(lines, map_statement)

    # Merge expression-owned metadata before any endpoint or row deletion.
    for bit in range(63):
        _add(
            lines,
            f"UPDATE expressions AS survivor SET pos_mask = pos_mask | (1 << {bit}) "
            f"WHERE EXISTS (SELECT 1 FROM {MAP} m JOIN expressions old "
            f"ON old.id=m.old_expression_id WHERE m.survivor_expression_id=survivor.id "
            f"AND (old.pos_mask & (1 << {bit})) <> 0)",
            batch=bit % 8 == 0,
        )
    _add(
        lines,
        f"UPDATE expressions AS survivor SET source_id=COALESCE(source_id,"
        f"(SELECT old.source_id FROM expressions old JOIN {MAP} m "
        f"ON m.old_expression_id=old.id WHERE m.survivor_expression_id=survivor.id "
        f"AND old.source_id IS NOT NULL ORDER BY old.id LIMIT 1)),"
        f"created_by=COALESCE(created_by,(SELECT old.created_by FROM expressions old "
        f"JOIN {MAP} m ON m.old_expression_id=old.id "
        f"WHERE m.survivor_expression_id=survivor.id AND old.created_by IS NOT NULL "
        "ORDER BY old.id LIMIT 1)) WHERE survivor.id IN "
        f"(SELECT survivor_expression_id FROM {MAP})",
        batch=True,
    )
    _add(
        lines,
        f"INSERT OR IGNORE INTO expression_locale_links(expression_id,locale_id) "
        f"SELECT m.survivor_expression_id,l.locale_id FROM expression_locale_links l "
        f"JOIN {MAP} m ON m.old_expression_id=l.expression_id",
        batch=True,
    )
    _add(
        lines,
        f"DELETE FROM expression_locale_links WHERE expression_id IN "
        f"(SELECT old_expression_id FROM {MAP})",
    )
    _add(
        lines,
        f"INSERT OR IGNORE INTO expression_readings"
        "(expression_id,locale_id,scheme,value,source_id) "
        f"SELECT m.survivor_expression_id,r.locale_id,r.scheme,r.value,r.source_id "
        f"FROM expression_readings r JOIN {MAP} m ON m.old_expression_id=r.expression_id",
        batch=True,
    )
    _add(
        lines,
        f"UPDATE expression_readings AS target SET source_id=COALESCE(source_id,"
        f"(SELECT MIN(old.source_id) FROM expression_readings old JOIN {MAP} m "
        f"ON m.old_expression_id=old.expression_id WHERE m.survivor_expression_id=target.expression_id "
        "AND old.locale_id=target.locale_id AND old.scheme=target.scheme "
        "AND old.value=target.value AND old.source_id IS NOT NULL)) "
        f"WHERE target.expression_id IN (SELECT survivor_expression_id FROM {MAP}) "
        "AND target.source_id IS NULL",
    )
    _add(
        lines,
        f"DELETE FROM expression_readings WHERE expression_id IN "
        f"(SELECT old_expression_id FROM {MAP})",
    )
    _add(
        lines,
        f"INSERT OR IGNORE INTO expression_sources(expression_id,source_id,source_marker) "
        f"SELECT m.survivor_expression_id,s.source_id,s.source_marker "
        f"FROM expression_sources s JOIN {MAP} m ON m.old_expression_id=s.expression_id",
        batch=True,
    )
    _add(
        lines,
        f"DELETE FROM expression_sources WHERE expression_id IN "
        f"(SELECT old_expression_id FROM {MAP})",
    )

    for table, column in (
        ("languages", "name_expression_id"),
        ("language_locales", "name_expression_id"),
        ("scripts", "name_expression_id"),
        ("regions", "name_expression_id"),
        ("morphological_dimensions", "name_expression_id"),
        ("morphological_features", "name_expression_id"),
    ):
        _add(
            lines,
            f"UPDATE {table} SET {column}=(SELECT m.survivor_expression_id "
            f"FROM {MAP} m WHERE m.old_expression_id={table}.{column}) "
            f"WHERE {column} IN (SELECT old_expression_id FROM {MAP})",
            batch=True,
        )

    _add(
        lines,
        f"DELETE FROM handbook_section_items AS h WHERE EXISTS "
        f"(SELECT 1 FROM {MAP} m WHERE m.old_expression_id=h.expression_id "
        f"AND EXISTS (SELECT 1 FROM handbook_section_items h2 "
        f"WHERE h2.section_id=h.section_id AND h2.expression_id=m.survivor_expression_id))",
        batch=True,
    )
    _add(
        lines,
        f"DELETE FROM handbook_section_items AS h WHERE EXISTS "
        f"(SELECT 1 FROM {MAP} m WHERE m.old_expression_id=h.expression_id AND EXISTS "
        f"(SELECT 1 FROM handbook_section_items h2 JOIN {MAP} m2 "
        f"ON m2.old_expression_id=h2.expression_id "
        f"WHERE h2.section_id=h.section_id AND m2.survivor_expression_id=m.survivor_expression_id "
        f"AND (h2.position<h.position OR (h2.position=h.position AND h2.expression_id<h.expression_id))))",
    )
    _add(
        lines,
        f"UPDATE handbook_section_items SET expression_id=(SELECT m.survivor_expression_id "
        f"FROM {MAP} m WHERE m.old_expression_id=handbook_section_items.expression_id) "
        f"WHERE expression_id IN (SELECT old_expression_id FROM {MAP})",
    )
    _add(
        lines,
        f"UPDATE ui_messages SET source_expression_id=(SELECT m.survivor_expression_id "
        f"FROM {MAP} m WHERE m.old_expression_id=ui_messages.source_expression_id) "
        f"WHERE source_expression_id IN (SELECT old_expression_id FROM {MAP})",
        batch=True,
    )
    _add(
        lines,
        f"UPDATE expression_splits SET source_expression_id=(SELECT m.survivor_expression_id "
        f"FROM {MAP} m WHERE m.old_expression_id=expression_splits.source_expression_id) "
        f"WHERE source_expression_id IN (SELECT old_expression_id FROM {MAP})",
    )
    _add(
        lines,
        f"UPDATE expression_splits SET target_expression_id=(SELECT m.survivor_expression_id "
        f"FROM {MAP} m WHERE m.old_expression_id=expression_splits.target_expression_id) "
        f"WHERE target_expression_id IN (SELECT old_expression_id FROM {MAP})",
    )

    # Re-key mapping edges, transferring all child rows before duplicate and
    # self edges are removed.  Endpoint mappings are monotonic (survivor is
    # the lowest existing target ID), so the final unique-key update is safe.
    _add(
        lines,
        f"CREATE TABLE {EDGE}(edge_id INTEGER PRIMARY KEY,target_a INTEGER NOT NULL,"
        "target_b INTEGER NOT NULL,survivor_edge_id INTEGER)",
        batch=True,
    )
    _add(
        lines,
        f"CREATE INDEX {EDGE}_target ON {EDGE}(target_a,target_b)",
    )
    _add(
        lines,
        f"WITH mapped AS (SELECT e.id,MIN(COALESCE((SELECT m.survivor_expression_id FROM {MAP} m "
        f"WHERE m.old_expression_id=e.expression_a_id),e.expression_a_id),COALESCE((SELECT m.survivor_expression_id FROM {MAP} m "
        f"WHERE m.old_expression_id=e.expression_b_id),e.expression_b_id)) target_a,MAX(COALESCE((SELECT m.survivor_expression_id FROM {MAP} m "
        f"WHERE m.old_expression_id=e.expression_a_id),e.expression_a_id),COALESCE((SELECT m.survivor_expression_id FROM {MAP} m "
        f"WHERE m.old_expression_id=e.expression_b_id),e.expression_b_id)) target_b FROM expression_edges e "
        f"WHERE e.expression_a_id IN (SELECT old_expression_id FROM {MAP}) OR e.expression_b_id IN (SELECT old_expression_id FROM {MAP})) "
        f"INSERT INTO {EDGE}(edge_id,target_a,target_b) SELECT id,target_a,target_b FROM mapped",
    )
    _add(
        lines,
        f"INSERT OR IGNORE INTO {EDGE}(edge_id,target_a,target_b) SELECT e.id,e.expression_a_id,e.expression_b_id "
        f"FROM expression_edges e WHERE EXISTS (SELECT 1 FROM {EDGE} h WHERE h.target_a=e.expression_a_id AND h.target_b=e.expression_b_id)",
    )
    _add(
        lines,
        f"UPDATE {EDGE} SET survivor_edge_id=(SELECT MIN(h2.edge_id) FROM {EDGE} h2 "
        f"WHERE h2.target_a={EDGE}.target_a AND h2.target_b={EDGE}.target_b)",
    )
    _add(
        lines,
        f"INSERT OR IGNORE INTO expression_edge_sources(edge_id,source_id,source_marker) "
        f"SELECT h.survivor_edge_id,s.source_id,s.source_marker FROM {EDGE} h "
        f"JOIN expression_edge_sources s ON s.edge_id=h.edge_id "
        f"WHERE h.edge_id<>h.survivor_edge_id AND h.target_a<h.target_b",
        batch=True,
    )
    _add(
        lines,
        f"INSERT OR IGNORE INTO edge_votes(user_id,edge_id,vote) SELECT v.user_id,h.survivor_edge_id,v.vote "
        f"FROM {EDGE} h JOIN edge_votes v ON v.edge_id=h.edge_id "
        f"WHERE h.edge_id<>h.survivor_edge_id AND h.target_a<h.target_b",
    )
    _add(
        lines,
        f"INSERT OR IGNORE INTO expression_split_moves(split_id,edge_id) SELECT sm.split_id,h.survivor_edge_id "
        f"FROM {EDGE} h JOIN expression_split_moves sm ON sm.edge_id=h.edge_id "
        f"WHERE h.edge_id<>h.survivor_edge_id AND h.target_a<h.target_b",
    )
    for bit in (1, 2, 4):
        _add(
            lines,
            f"UPDATE expression_edges AS survivor SET relation_mask=relation_mask | {bit} "
            f"WHERE EXISTS (SELECT 1 FROM {EDGE} h JOIN expression_edges old ON old.id=h.edge_id "
            f"WHERE h.survivor_edge_id=survivor.id AND (old.relation_mask & {bit})<>0)",
            batch=bit == 1,
        )
    _add(
        lines,
        f"UPDATE expression_edges AS survivor SET score=MAX(score,COALESCE((SELECT MAX(old.score) "
        f"FROM {EDGE} h JOIN expression_edges old ON old.id=h.edge_id "
        f"WHERE h.survivor_edge_id=survivor.id),score)),created_by=COALESCE(created_by,"
        f"(SELECT old.created_by FROM {EDGE} h JOIN expression_edges old ON old.id=h.edge_id "
        f"WHERE h.survivor_edge_id=survivor.id AND old.created_by IS NOT NULL ORDER BY old.id LIMIT 1)) "
        f"WHERE id IN (SELECT survivor_edge_id FROM {EDGE} WHERE target_a<target_b)",
    )
    _add(
        lines,
        f"DELETE FROM expression_split_moves WHERE edge_id IN (SELECT edge_id FROM {EDGE} WHERE target_a=target_b)",
    )
    _add(
        lines,
        f"DELETE FROM expression_split_moves WHERE edge_id IN (SELECT edge_id FROM {EDGE} WHERE edge_id<>survivor_edge_id)",
    )
    _add(
        lines,
        f"DELETE FROM expression_edges WHERE id IN (SELECT edge_id FROM {EDGE} WHERE target_a=target_b OR edge_id<>survivor_edge_id)",
    )
    _add(
        lines,
        f"UPDATE expression_edges SET expression_a_id=(SELECT target_a FROM {EDGE} h WHERE h.edge_id=expression_edges.id),"
        f"expression_b_id=(SELECT target_b FROM {EDGE} h WHERE h.edge_id=expression_edges.id) "
        f"WHERE id IN (SELECT survivor_edge_id FROM {EDGE} WHERE target_a<target_b)",
    )

    # Form edges have no production rows today, but preserve their feature
    # metadata if a future database contains them.
    _add(
        lines,
        f"CREATE TABLE {FORM}(edge_id INTEGER PRIMARY KEY,target_form INTEGER NOT NULL,"
        "target_lemma INTEGER NOT NULL,survivor_edge_id INTEGER)",
        batch=True,
    )
    _add(lines, f"CREATE INDEX {FORM}_target ON {FORM}(target_form,target_lemma)")
    _add(
        lines,
        f"WITH mapped AS (SELECT e.id,COALESCE((SELECT m.survivor_expression_id FROM {MAP} m WHERE m.old_expression_id=e.form_id),e.form_id) target_form,"
        f"COALESCE((SELECT m.survivor_expression_id FROM {MAP} m WHERE m.old_expression_id=e.lemma_id),e.lemma_id) target_lemma FROM expression_form_edges e "
        f"WHERE e.form_id IN (SELECT old_expression_id FROM {MAP}) OR e.lemma_id IN (SELECT old_expression_id FROM {MAP})) "
        f"INSERT INTO {FORM}(edge_id,target_form,target_lemma) SELECT id,target_form,target_lemma FROM mapped",
    )
    _add(
        lines,
        f"INSERT OR IGNORE INTO {FORM}(edge_id,target_form,target_lemma) SELECT e.id,e.form_id,e.lemma_id FROM expression_form_edges e "
        f"WHERE EXISTS (SELECT 1 FROM {FORM} h WHERE h.target_form=e.form_id AND h.target_lemma=e.lemma_id)",
    )
    _add(
        lines,
        f"UPDATE {FORM} SET survivor_edge_id=(SELECT MIN(h2.edge_id) FROM {FORM} h2 WHERE h2.target_form={FORM}.target_form AND h2.target_lemma={FORM}.target_lemma)",
    )
    _add(
        lines,
        f"INSERT OR IGNORE INTO expression_form_edge_features(edge_id,feature_code) SELECT h.survivor_edge_id,f.feature_code FROM {FORM} h "
        f"JOIN expression_form_edge_features f ON f.edge_id=h.edge_id WHERE h.edge_id<>h.survivor_edge_id AND h.target_form<>h.target_lemma",
        batch=True,
    )
    _add(
        lines,
        f"UPDATE expression_form_edges AS survivor SET created_by=COALESCE(created_by,(SELECT old.created_by FROM {FORM} h JOIN expression_form_edges old ON old.id=h.edge_id "
        f"WHERE h.survivor_edge_id=survivor.id AND old.created_by IS NOT NULL ORDER BY old.id LIMIT 1)) WHERE id IN (SELECT survivor_edge_id FROM {FORM} WHERE target_form<>target_lemma)",
    )
    _add(
        lines,
        f"DELETE FROM expression_form_edges WHERE id IN (SELECT edge_id FROM {FORM} WHERE target_form=target_lemma OR edge_id<>survivor_edge_id)",
    )
    _add(
        lines,
        f"UPDATE expression_form_edges SET form_id=(SELECT target_form FROM {FORM} h WHERE h.edge_id=expression_form_edges.id),lemma_id=(SELECT target_lemma FROM {FORM} h WHERE h.edge_id=expression_form_edges.id) "
        f"WHERE id IN (SELECT survivor_edge_id FROM {FORM} WHERE target_form<>target_lemma)",
    )

    _add(
        lines,
        f"DELETE FROM expressions WHERE id IN (SELECT old_expression_id FROM {MAP})",
        batch=True,
    )
    _add(
        lines,
        f"UPDATE expressions SET text=(SELECT normalized_text FROM {KEYS} k WHERE k.expression_id=expressions.id) "
        f"WHERE id IN (SELECT expression_id FROM {KEYS}) AND text<>(SELECT normalized_text FROM {KEYS} k WHERE k.expression_id=expressions.id)",
    )
    _add(
        lines,
        "UPDATE ui_messages SET source_text=(SELECT text FROM expressions e WHERE e.id=ui_messages.source_expression_id)",
        batch=True,
    )
    for table in (FORM, EDGE, MAP, KEYS, POLICY):
        _add(lines, f"DROP TABLE IF EXISTS {table}", batch=True)

    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(build_sql(), encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
