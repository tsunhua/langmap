import sqlite3
from pathlib import Path

from scripts.db.normalize_expression_case import normalize_database


def _fixture() -> sqlite3.Connection:
    connection = sqlite3.connect(":memory:")
    connection.row_factory = sqlite3.Row
    schema = Path(__file__).resolve().parents[3] / "backend" / "schema.sql"
    connection.executescript(schema.read_text(encoding="utf-8"))
    connection.execute(
        "INSERT INTO users(id,username,email,password_hash,role) VALUES(1,'test','test@example.com','x','user')"
    )
    connection.execute("INSERT INTO languages(id,code,name_en) VALUES(1,'eng','English')")
    connection.execute("INSERT INTO languages(id,code,name_en) VALUES(2,'spa','Spanish')")
    connection.execute("INSERT INTO scripts(code,name_en,direction) VALUES('Latn','Latin','ltr')")
    connection.execute("INSERT INTO regions(code,name_en) VALUES('US','United States')")
    connection.execute(
        "INSERT INTO language_locales(id,code,language_id,script_code,region_code,name,name_en) "
        "VALUES(1,'eng-Latn-US',1,'Latn','US','English','English')"
    )
    connection.execute(
        "INSERT INTO sources(id,type,name) VALUES(1,'publication','fixture')"
    )
    connection.execute(
        "INSERT INTO expressions(id,language_id,text,homograph_index,pos_mask,source_id) "
        "VALUES(1,1,'Closed',1,1,1),(2,1,'CLOSED',1,2,NULL),(3,2,'Hola',1,1,1)"
    )
    connection.execute("UPDATE languages SET name_expression_id=2 WHERE id=1")
    connection.execute("INSERT INTO expression_locale_links VALUES(2,1)")
    connection.execute(
        "INSERT INTO expression_readings(expression_id,locale_id,scheme,value,source_id) VALUES(2,1,'ipa','kloʊzd',1)"
    )
    connection.execute("INSERT INTO expression_sources VALUES(2,1,'fixture:closed')")
    connection.execute(
        "INSERT INTO expression_edges(expression_a_id,expression_b_id,relation_mask,score) VALUES(2,3,1,2)"
    )
    edge_id = connection.execute("SELECT id FROM expression_edges").fetchone()[0]
    connection.execute("INSERT INTO expression_edge_sources VALUES(?,1,'edge')", (edge_id,))
    connection.execute("INSERT INTO edge_votes(user_id,edge_id,vote) VALUES(1,?,1)", (edge_id,))
    connection.execute("INSERT INTO handbooks(id,user_id,title) VALUES(1,1,'Fixture')")
    connection.execute("INSERT INTO handbook_sections(id,handbook_id,title,position) VALUES(1,1,'Basics',1)")
    connection.execute("INSERT INTO handbook_section_items VALUES(1,1,2)")
    connection.execute(
        "INSERT INTO ui_messages(project_id,message_key,source_expression_id,source_text) "
        "VALUES('fixture','closed',2,'CLOSED')"
    )
    connection.commit()
    return connection


def test_normalization_merges_nodes_and_moves_references():
    connection = _fixture()
    report = normalize_database(connection, apply=True)

    assert report["candidate_merges"] == 1
    assert report["expressions_after"] == 2
    assert tuple(connection.execute("SELECT text,pos_mask FROM expressions WHERE id=1").fetchone()) == ("Closed", 3)
    assert connection.execute("SELECT name_expression_id FROM languages WHERE id=1").fetchone()[0] == 1
    assert connection.execute("SELECT expression_id FROM expression_locale_links").fetchone()[0] == 1
    assert connection.execute("SELECT expression_id FROM expression_readings").fetchone()[0] == 1
    assert connection.execute("SELECT expression_id FROM expression_sources").fetchone()[0] == 1
    assert connection.execute("SELECT expression_id FROM handbook_section_items").fetchone()[0] == 1
    assert tuple(connection.execute("SELECT source_expression_id,source_text FROM ui_messages").fetchone()) == (1, "Closed")
    assert tuple(connection.execute("SELECT expression_a_id,expression_b_id FROM expression_edges").fetchone()) == (1, 3)
    assert connection.execute("PRAGMA foreign_key_check").fetchall() == []
    connection.close()
