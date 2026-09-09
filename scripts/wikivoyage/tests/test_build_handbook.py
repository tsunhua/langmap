from __future__ import annotations

import sqlite3
from pathlib import Path

from scripts.wikivoyage.build_handbook import build_managed_handbook
from scripts.wikivoyage.catalog import load_section_catalog


ROOT = Path(__file__).parents[1]


def _database() -> sqlite3.Connection:
    connection = sqlite3.connect(":memory:")
    connection.row_factory = sqlite3.Row
    connection.executescript((ROOT.parents[1] / "backend/schema.sql").read_text(encoding="utf-8"))
    connection.execute("INSERT INTO users(username,email,password_hash,role) VALUES('langmap','langmap@example.invalid','x','system')")
    connection.execute("INSERT INTO languages(code,name_en) VALUES('eng','English')")
    connection.execute("INSERT INTO languages(code,name_en) VALUES('jpn','Japanese')")
    connection.execute("INSERT INTO language_locales(code,language_id,name,name_en) VALUES('eng-Latn-US',1,'English','English (US)')")
    connection.execute("INSERT INTO language_locales(code,language_id,name,name_en) VALUES('jpn-Jpan-JP',2,'日本語','Japanese (Japan)')")
    connection.execute("INSERT INTO sources(type,name) VALUES('url','https://en.wikivoyage.org/wiki/Japanese_phrasebook')")
    connection.execute("INSERT INTO expressions(language_id,text) VALUES(1,'Where is the toilet?')")
    connection.execute("INSERT INTO expressions(language_id,text) VALUES(2,'トイレはどこですか？')")
    connection.execute("INSERT INTO expression_edges(expression_a_id,expression_b_id,relation_mask) VALUES(1,2,1)")
    connection.execute("INSERT INTO expression_edge_sources(edge_id,source_id,source_marker) VALUES(1,1,'oldid:5332510#basics/24')")
    connection.commit()
    return connection


def test_build_managed_handbook_is_idempotent_and_deduplicates_items() -> None:
    connection = _database()
    catalog = load_section_catalog(ROOT / "section-catalog.json")

    first = build_managed_handbook(connection, catalog)
    second = build_managed_handbook(connection, catalog)

    assert first.handbook_id == second.handbook_id
    assert first.reused is False
    assert second.reused is True
    assert first.sections == 1
    assert first.items == 1
    assert connection.execute("SELECT managed_key FROM handbooks").fetchone()[0] == "enwikivoyage-phrasebooks"
    assert connection.execute("SELECT COUNT(*) FROM handbook_section_items").fetchone()[0] == 1


def test_build_managed_handbook_prefers_sentence_case_for_casefold_duplicates() -> None:
    connection = _database()
    connection.execute("INSERT INTO expressions(language_id,text) VALUES(1,'CLOSED')")
    upper_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
    connection.execute("INSERT INTO expressions(language_id,text) VALUES(1,'Closed')")
    title_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
    connection.execute("INSERT INTO expressions(language_id,text) VALUES(2,'閉まっています')")
    target_upper_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
    connection.execute("INSERT INTO expressions(language_id,text) VALUES(2,'閉じています')")
    target_title_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
    connection.execute(
        "INSERT INTO expression_edges(expression_a_id,expression_b_id,relation_mask) VALUES(?,?,1)",
        (min(upper_id, target_upper_id), max(upper_id, target_upper_id)),
    )
    upper_edge_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
    connection.execute(
        "INSERT INTO expression_edge_sources(edge_id,source_id,source_marker) VALUES(?,?,?)",
        (upper_edge_id, 1, "oldid:5332510#basics/1"),
    )
    connection.execute(
        "INSERT INTO expression_edges(expression_a_id,expression_b_id,relation_mask) VALUES(?,?,1)",
        (min(title_id, target_title_id), max(title_id, target_title_id)),
    )
    title_edge_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
    connection.execute(
        "INSERT INTO expression_edge_sources(edge_id,source_id,source_marker) VALUES(?,?,?)",
        (title_edge_id, 1, "oldid:5332510#basics/2"),
    )
    connection.commit()

    report = build_managed_handbook(connection, load_section_catalog(ROOT / "section-catalog.json"))

    assert report.items == 2
    rows = connection.execute(
        "SELECT e.id,e.text FROM handbook_section_items i JOIN expressions e ON e.id=i.expression_id ORDER BY i.position"
    ).fetchall()
    assert [(int(row[0]), row[1]) for row in rows] == [(title_id, "Closed"), (1, "Where is the toilet?")]


def test_build_managed_handbook_keeps_ambiguous_acronym_case_variants() -> None:
    connection = _database()
    connection.execute("INSERT INTO expressions(language_id,text) VALUES(1,'US')")
    upper_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
    connection.execute("INSERT INTO expressions(language_id,text) VALUES(1,'us')")
    lower_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
    connection.execute("INSERT INTO expressions(language_id,text) VALUES(2,'美国')")
    upper_target_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
    connection.execute("INSERT INTO expressions(language_id,text) VALUES(2,'我们')")
    lower_target_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
    for expression_id, target_id, marker in (
        (upper_id, upper_target_id, "oldid:5332510#basics/1"),
        (lower_id, lower_target_id, "oldid:5332510#basics/2"),
    ):
        connection.execute(
            "INSERT INTO expression_edges(expression_a_id,expression_b_id,relation_mask) VALUES(?,?,1)",
            (min(expression_id, target_id), max(expression_id, target_id)),
        )
        edge_id = int(connection.execute("SELECT last_insert_rowid()").fetchone()[0])
        connection.execute(
            "INSERT INTO expression_edge_sources(edge_id,source_id,source_marker) VALUES(?,?,?)",
            (edge_id, 1, marker),
        )
    connection.commit()

    build_managed_handbook(connection, load_section_catalog(ROOT / "section-catalog.json"))

    rows = connection.execute(
        "SELECT e.text FROM handbook_section_items i JOIN expressions e ON e.id=i.expression_id ORDER BY i.position"
    ).fetchall()
    assert [row[0] for row in rows] == ["US", "us", "Where is the toilet?"]
