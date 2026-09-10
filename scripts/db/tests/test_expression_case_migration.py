import sqlite3
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SQL_PATH = ROOT / "scripts" / "db" / "state" / "backup" / "delta" / "037-expression-case-normalization-20260910.split.sql"


def test_production_sql_merges_references_and_preserves_acronyms():
    connection = sqlite3.connect(":memory:")
    connection.row_factory = sqlite3.Row
    connection.executescript((ROOT / "backend" / "schema.sql").read_text(encoding="utf-8"))
    connection.execute(
        "INSERT INTO users(id,username,email,password_hash) VALUES(1,'fixture','fixture@example.com','x')"
    )
    connection.executemany(
        "INSERT INTO languages(id,code,name_en) VALUES(?,?,?)",
        [(1, "eng", "English"), (2, "cmn", "Chinese"), (3, "nan", "Southern Min"), (4, "jpn", "Japanese")],
    )
    connection.executemany(
        "INSERT INTO scripts(code,name_en,direction) VALUES(?,?,?)",
        [("Latn", "Latin", "ltr"), ("Hans", "Simplified", "ltr"), ("Jpan", "Japanese", "ltr")],
    )
    connection.executemany(
        "INSERT INTO language_locales(id,code,language_id,script_code,name,name_en) VALUES(?,?,?,?,?,?)",
        [
            (1, "eng-Latn-US", 1, "Latn", "English", "English"),
            (2, "cmn-Hans-CN", 2, "Hans", "Mandarin", "Mandarin"),
            (3, "nan-Latn-TW", 3, "Latn", "Southern Min", "Southern Min"),
            (4, "jpn-Jpan-JP", 4, "Jpan", "Japanese", "Japanese"),
        ],
    )
    connection.executemany(
        "INSERT INTO sources(id,type,name) VALUES(?,?,?)",
        [(1, "fixture", "one"), (2, "fixture", "two")],
    )
    connection.executemany(
        "INSERT INTO expressions(id,language_id,text,homograph_index,pos_mask,source_id) VALUES(?,?,?,?,?,?)",
        [
            (1, 1, "Closed", 1, 1, 1),
            (2, 1, "CloSED", 1, 2, None),
            (3, 1, "UFO", 1, 0, None),
            (4, 1, "HELLO", 1, 0, None),
            (5, 1, "hello", 1, 0, None),
            (6, 2, "漢字", 1, 0, None),
            (7, 3, "nan", 1, 0, None),
            (8, 3, "NAN", 1, 0, None),
            (10, 2, "你好", 1, 0, None),
            (11, 2, "再見", 1, 0, None),
        ],
    )
    connection.executemany(
        "INSERT INTO expression_locale_links(expression_id,locale_id) VALUES(?,?)",
        [(1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 2), (7, 3), (8, 3), (10, 2), (11, 2)],
    )
    connection.executemany(
        "INSERT INTO expression_readings(expression_id,locale_id,scheme,value,source_id) VALUES(?,?,?,?,?)",
        [(1, 1, "ipa", "kloʊzd", 1), (2, 1, "ipa", "klozd", 2)],
    )
    connection.executemany(
        "INSERT INTO expression_sources(expression_id,source_id,source_marker) VALUES(?,?,?)",
        [(1, 1, "new"), (2, 2, "old")],
    )
    connection.executemany(
        "INSERT INTO expression_edges(id,expression_a_id,expression_b_id,relation_mask,score,created_by) VALUES(?,?,?,?,?,?)",
        [(1, 1, 10, 1, 2, None), (2, 2, 10, 2, 5, 1), (3, 2, 11, 1, 1, None)],
    )
    connection.execute("INSERT INTO expression_edge_sources VALUES(2,2,'edge-old')")
    connection.execute("INSERT INTO edge_votes VALUES(1,2,1)")
    connection.execute("INSERT INTO expression_splits(id,source_expression_id,target_expression_id) VALUES(1,2,10)")
    connection.execute("INSERT INTO expression_split_moves VALUES(1,2)")
    connection.execute("INSERT INTO expression_form_edges(id,form_id,lemma_id,created_by) VALUES(1,2,10,1)")
    connection.execute("INSERT INTO handbooks(id,user_id,title) VALUES(1,1,'fixture')")
    connection.execute("INSERT INTO handbook_sections(id,handbook_id,title,position) VALUES(1,1,'section',1)")
    connection.executemany("INSERT INTO handbook_section_items VALUES(1,?,?)", [(1, 1), (2, 2)])
    connection.execute("INSERT INTO ui_messages(project_id,message_key,source_expression_id,source_text) VALUES('x','closed',2,'CloSED')")
    connection.execute("UPDATE languages SET name_expression_id=2 WHERE id=1")
    connection.commit()

    connection.executescript(SQL_PATH.read_text(encoding="utf-8"))

    assert connection.execute("SELECT text FROM expressions WHERE id=1").fetchone()[0] == "Closed"
    assert connection.execute("SELECT COUNT(*) FROM expressions WHERE id=2").fetchone()[0] == 0
    assert connection.execute("SELECT text FROM expressions WHERE id=3").fetchone()[0] == "UFO"
    assert connection.execute("SELECT text FROM expressions WHERE id=4").fetchone()[0] == "HELLO"
    assert connection.execute("SELECT text FROM expressions WHERE id=5").fetchone()[0] == "Hello"
    assert connection.execute("SELECT text FROM expressions WHERE id=6").fetchone()[0] == "漢字"
    assert connection.execute("SELECT text FROM expressions WHERE id=7").fetchone()[0] == "Nan"
    assert connection.execute("SELECT text FROM expressions WHERE id=8").fetchone()[0] == "NAN"
    assert connection.execute("SELECT name_expression_id FROM languages WHERE id=1").fetchone()[0] == 1
    assert connection.execute("SELECT COUNT(*) FROM expression_locale_links WHERE expression_id=2").fetchone()[0] == 0
    assert connection.execute("SELECT COUNT(*) FROM expression_readings WHERE expression_id=1").fetchone()[0] == 2
    assert connection.execute("SELECT COUNT(*) FROM expression_sources WHERE expression_id=1").fetchone()[0] == 2
    assert [row[0] for row in connection.execute("SELECT expression_id FROM handbook_section_items")] == [1]
    assert tuple(connection.execute("SELECT source_expression_id,source_text FROM ui_messages").fetchone()) == (1, "Closed")
    assert connection.execute("SELECT COUNT(*) FROM expression_edges").fetchone()[0] == 2
    assert tuple(connection.execute("SELECT relation_mask,score FROM expression_edges WHERE id=1").fetchone()) == (3, 5)
    assert tuple(connection.execute("SELECT expression_a_id,expression_b_id FROM expression_edges WHERE id=3").fetchone()) == (1, 11)
    assert tuple(connection.execute("SELECT form_id,lemma_id FROM expression_form_edges").fetchone()) == (1, 10)
    assert connection.execute("SELECT source_expression_id FROM expression_splits").fetchone()[0] == 1
    assert connection.execute("SELECT edge_id FROM expression_split_moves").fetchone()[0] == 1
    assert connection.execute("PRAGMA foreign_key_check").fetchall() == []
    connection.close()
