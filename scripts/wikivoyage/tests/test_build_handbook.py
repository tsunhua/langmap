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
