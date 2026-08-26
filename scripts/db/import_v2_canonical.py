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
    args = parser.parse_args()
    db = sqlite3.connect(args.source)
    db.row_factory = sqlite3.Row
    users = db.execute("SELECT DISTINCT u.* FROM users u JOIN expressions e ON e.created_by=u.id WHERE e.created_by IS NOT NULL ORDER BY u.id").fetchall()
    expressions = db.execute("SELECT * FROM expressions WHERE created_by IS NOT NULL ORDER BY id").fetchall()
    edges = db.execute("SELECT ed.* FROM expression_edges ed JOIN expressions a ON a.id=ed.expression_a_id JOIN expressions b ON b.id=ed.expression_b_id WHERE a.created_by IS NOT NULL AND b.created_by IS NOT NULL ORDER BY ed.id").fetchall()
    handbooks = db.execute("SELECT * FROM handbooks ORDER BY id").fetchall()
    sections = db.execute("SELECT * FROM handbook_sections ORDER BY id").fetchall()
    items = db.execute("SELECT * FROM handbook_section_items ORDER BY section_id,position").fetchall()
    attestations = db.execute("SELECT DISTINCT e.lang_code,e.text,e.homograph_index,a.language_locale_code FROM expressions e JOIN expression_locale_attestations a ON a.expression_id=e.id WHERE e.created_by IS NOT NULL ORDER BY e.id,a.language_locale_code").fetchall()
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
