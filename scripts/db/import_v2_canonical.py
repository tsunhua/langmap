#!/usr/bin/env python3
"""Generate a temporary canonical-D1 import from an exported LangMap v2 SQLite DB.

Usage: python3 scripts/db/import_v2_canonical.py --source /tmp/remote-v2.sqlite --output-dir /tmp/v2-user-import
The generated SQL has transient ID maps and drops them before completion.
"""
from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path


def q(value: object) -> str:
    if value is None:
        return "NULL"
    return "'" + str(value).replace("'", "''") + "'"


def chunks(rows: list[sqlite3.Row], size: int = 100):
    for start in range(0, len(rows), size):
        yield rows[start:start + size]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--locale-links-only", action="store_true")
    parser.add_argument("--only-language", action="append", default=[], help="Import these language codes and their direct edge endpoints")
    parser.add_argument("--expressions-only", action="store_true", help="Skip handbooks and sections")
    args = parser.parse_args()
    db = sqlite3.connect(args.source)
    db.row_factory = sqlite3.Row
    only_languages = sorted(set(args.only_language))
    if only_languages:
        marks = ",".join("?" for _ in only_languages)
        expressions = db.execute(f"""
            SELECT DISTINCT e.* FROM expressions e
            WHERE e.lang_code IN ({marks})
               OR e.id IN (
                 SELECT CASE WHEN a.lang_code IN ({marks}) THEN ed.expression_b_id ELSE ed.expression_a_id END
                 FROM expression_edges ed
                 JOIN expressions a ON a.id=ed.expression_a_id
                 JOIN expressions b ON b.id=ed.expression_b_id
                 WHERE a.lang_code IN ({marks}) OR b.lang_code IN ({marks})
               )
            ORDER BY e.id
        """, only_languages * 4).fetchall()
    else:
        expressions = db.execute("SELECT * FROM expressions WHERE created_by IS NOT NULL ORDER BY id").fetchall()
    expression_ids = [str(row['id']) for row in expressions]
    expression_marks = ",".join("?" for _ in expression_ids)
    creator_ids = sorted({row['created_by'] for row in expressions if row['created_by'] is not None})
    users = db.execute(f"SELECT * FROM users WHERE id IN ({','.join('?' for _ in creator_ids)}) ORDER BY id", creator_ids).fetchall() if creator_ids else []
    if expression_ids and only_languages:
        language_marks = ",".join("?" for _ in only_languages)
        edges = db.execute(
            f"""SELECT ed.* FROM expression_edges ed
                JOIN expressions a ON a.id=ed.expression_a_id
                JOIN expressions b ON b.id=ed.expression_b_id
                WHERE ed.expression_a_id IN ({expression_marks}) AND ed.expression_b_id IN ({expression_marks})
                  AND (a.lang_code IN ({language_marks}) OR b.lang_code IN ({language_marks}))
                ORDER BY ed.id""",
            expression_ids * 2 + only_languages * 2,
        ).fetchall()
    elif expression_ids:
        edges = db.execute(
            f"SELECT * FROM expression_edges WHERE expression_a_id IN ({expression_marks}) AND expression_b_id IN ({expression_marks}) ORDER BY id",
            expression_ids * 2,
        ).fetchall()
    else:
        edges = []
    handbooks = [] if args.expressions_only else db.execute("SELECT * FROM handbooks ORDER BY id").fetchall()
    sections = [] if args.expressions_only else db.execute("SELECT * FROM handbook_sections ORDER BY id").fetchall()
    items = [] if args.expressions_only else db.execute("SELECT * FROM handbook_section_items ORDER BY section_id,position").fetchall()
    attestations = db.execute(f"""
        SELECT DISTINCT e.lang_code,e.text,e.homograph_index,a.language_locale_code
        FROM expressions e JOIN expression_locale_attestations a ON a.expression_id=e.id
        WHERE e.id IN ({expression_marks})
        UNION
        SELECT e.lang_code,e.text,e.homograph_index,
               CASE e.lang_code WHEN 'x-image' THEN 'x-image-Latn-US' ELSE 'x-emoji-Latn-US' END
        FROM expressions e
        WHERE e.id IN ({expression_marks}) AND e.lang_code IN ('x-image','x-emoji')
        ORDER BY 1,2,3,4
    """, expression_ids * 2).fetchall() if expression_ids else []
    if args.locale_links_only:
        lines = [f"INSERT OR IGNORE INTO expression_locale_links(expression_id,locale_id) SELECT e.id,ll.id FROM expressions e JOIN languages l ON l.id=e.language_id JOIN language_locales ll ON ll.code={q(r['language_locale_code'])} WHERE l.code={q(r['lang_code'])} AND e.text={q(r['text'])} AND e.homograph_index={r['homograph_index']};" for r in attestations]
        args.output_dir.mkdir(parents=True, exist_ok=True)
        for existing in args.output_dir.glob("*.sql"): existing.unlink()
        for index, start in enumerate(range(0, len(lines), 700), start=1):
            (args.output_dir / f"{index:04d}.sql").write_text("\n".join(lines[start:start + 700]) + "\n", encoding="utf-8")
        print({"locale_links": len(attestations)})
        return 0
    lines = ["PRAGMA foreign_keys=ON;", "CREATE TABLE v2_expression_map(old_id TEXT PRIMARY KEY, new_id INTEGER NOT NULL);", "CREATE TABLE v2_handbook_map(old_id TEXT PRIMARY KEY, new_id INTEGER NOT NULL);", "CREATE TABLE v2_section_map(old_id TEXT PRIMARY KEY, new_id INTEGER NOT NULL);"]
    for row in users:
        lines.append("INSERT OR IGNORE INTO users(id,username,email,password_hash,role,email_verified,created_at,updated_at) VALUES(" + ",".join(q(row[k]) for k in ('id','username','email','password_hash','role','email_verified','created_at','updated_at')) + ");")
    for batch in chunks(expressions):
        for r in batch:
            lines.append(f"INSERT OR IGNORE INTO expressions(language_id,text,homograph_index,created_by,created_at) SELECT id,{q(r['text'])},{r['homograph_index']},{r['created_by']},{q(r['created_at'])} FROM languages WHERE code={q(r['lang_code'])};")
            lines.append(f"INSERT OR REPLACE INTO v2_expression_map SELECT {q(r['id'])},e.id FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code={q(r['lang_code'])} AND e.text={q(r['text'])} AND e.homograph_index={r['homograph_index']};")
    for r in edges:
        lines.append(f"INSERT OR IGNORE INTO expression_edges(expression_a_id,expression_b_id,score) SELECT MIN(a.new_id,b.new_id),MAX(a.new_id,b.new_id),{r['score']} FROM v2_expression_map a JOIN v2_expression_map b WHERE a.old_id={q(r['expression_a_id'])} AND b.old_id={q(r['expression_b_id'])};")
    for r in handbooks:
        lines.append(f"INSERT INTO handbooks(user_id,title,visibility,status,score,created_at,updated_at) VALUES({r['user_id']},{q(r['title'])},{q(r['visibility'])},{q(r['status'])},{r['score']},{q(r['created_at'])},{q(r['updated_at'])});")
        lines.append(f"INSERT INTO v2_handbook_map VALUES({q(r['id'])},last_insert_rowid());")
    for r in sections:
        lines.append(f"INSERT INTO handbook_sections(handbook_id,title,position,parent_section_id) SELECT h.new_id,{q(r['title'])},{r['position']},NULL FROM v2_handbook_map h WHERE h.old_id={q(r['handbook_id'])};")
        lines.append(f"INSERT INTO v2_section_map VALUES({q(r['id'])},last_insert_rowid());")
    for r in sections:
        if r['parent_section_id']:
            lines.append(f"UPDATE handbook_sections SET parent_section_id=(SELECT new_id FROM v2_section_map WHERE old_id={q(r['parent_section_id'])}) WHERE id=(SELECT new_id FROM v2_section_map WHERE old_id={q(r['id'])});")
    for r in items:
        lines.append(f"INSERT OR IGNORE INTO handbook_section_items(section_id,position,expression_id) SELECT s.new_id,{r['position']},e.new_id FROM v2_section_map s JOIN v2_expression_map e WHERE s.old_id={q(r['section_id'])} AND e.old_id={q(r['expression_id'])};")
    lines += ["DROP TABLE v2_section_map;", "DROP TABLE v2_handbook_map;", "DROP TABLE v2_expression_map;"]
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for existing in args.output_dir.glob("*.sql"):
        existing.unlink()
    statements_per_file = 700
    for index, start in enumerate(range(0, len(lines), statements_per_file), start=1):
        (args.output_dir / f"{index:04d}.sql").write_text("\n".join(lines[start:start + statements_per_file]) + "\n", encoding="utf-8")
    print({"users":len(users),"expressions":len(expressions),"edges":len(edges),"handbooks":len(handbooks),"sections":len(sections),"items":len(items)})
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
