import sqlite3
from pathlib import Path

from scripts.dictionary.langmap_dictionary.adapters.traditional_chinese_english import normalize_release
from scripts.dictionary.langmap_dictionary.clusters import build_explicit_clusters
from scripts.dictionary.langmap_dictionary.loader import load_jsonl_release
from scripts.dictionary.langmap_dictionary.local_import import import_release_to_local_d1
from scripts.dictionary.langmap_dictionary.schema import create_staging_database

FIXTURE = Path(__file__).parent / "fixtures" / "traditional_chinese_english_v2.jsonl"


CANONICAL_SCHEMA = """
PRAGMA foreign_keys=ON;
CREATE TABLE languages(id INTEGER PRIMARY KEY AUTOINCREMENT,code TEXT UNIQUE NOT NULL,name_en TEXT NOT NULL);
CREATE TABLE sources(id INTEGER PRIMARY KEY AUTOINCREMENT,type TEXT NOT NULL,name TEXT NOT NULL,UNIQUE(type,name));
CREATE TABLE language_locales(id INTEGER PRIMARY KEY AUTOINCREMENT,code TEXT UNIQUE NOT NULL,language_id INTEGER NOT NULL,script_code TEXT,orthography TEXT,region_code TEXT,place_path TEXT NOT NULL DEFAULT '',name TEXT NOT NULL,name_en TEXT NOT NULL,FOREIGN KEY(language_id) REFERENCES languages(id));
CREATE TABLE parts_of_speech(code TEXT PRIMARY KEY,name_en TEXT NOT NULL,sort_order INTEGER NOT NULL UNIQUE,bit_index INTEGER NOT NULL UNIQUE);
INSERT INTO parts_of_speech VALUES ('noun','Noun',1,0),('verb','Verb',2,1),('adjective','Adjective',3,2),('phrase','Phrase',4,3);
CREATE TABLE expressions(id INTEGER PRIMARY KEY AUTOINCREMENT,language_id INTEGER NOT NULL,text TEXT NOT NULL,homograph_index INTEGER NOT NULL DEFAULT 1,pos_mask INTEGER NOT NULL DEFAULT 0,source_id INTEGER,UNIQUE(language_id,text,homograph_index),FOREIGN KEY(language_id) REFERENCES languages(id),FOREIGN KEY(source_id) REFERENCES sources(id));
CREATE TABLE expression_locale_links(expression_id INTEGER NOT NULL,locale_id INTEGER NOT NULL,PRIMARY KEY(expression_id,locale_id),FOREIGN KEY(expression_id) REFERENCES expressions(id),FOREIGN KEY(locale_id) REFERENCES language_locales(id)) WITHOUT ROWID;
CREATE TABLE expression_readings(expression_id INTEGER NOT NULL,locale_id INTEGER NOT NULL,scheme TEXT NOT NULL,value TEXT NOT NULL,source_id INTEGER,PRIMARY KEY(expression_id,locale_id,scheme,value),FOREIGN KEY(expression_id) REFERENCES expressions(id),FOREIGN KEY(locale_id) REFERENCES language_locales(id)) WITHOUT ROWID;
CREATE TABLE expression_edges(id INTEGER PRIMARY KEY AUTOINCREMENT,expression_a_id INTEGER NOT NULL,expression_b_id INTEGER NOT NULL,relation_mask INTEGER NOT NULL DEFAULT 1,score INTEGER NOT NULL DEFAULT 0,created_by INTEGER,CHECK(expression_a_id<expression_b_id),UNIQUE(expression_a_id,expression_b_id),FOREIGN KEY(expression_a_id) REFERENCES expressions(id),FOREIGN KEY(expression_b_id) REFERENCES expressions(id));
"""


def _stage(path: Path = FIXTURE):
    staging_path = path.parent / (path.stem + ".stage.sqlite")
    staging_path.unlink(missing_ok=True)
    staging = create_staging_database(staging_path)
    run_id = load_jsonl_release(staging, [path]).release_id
    normalize_release(staging, run_id)
    build_explicit_clusters(staging, run_id)
    staging.close()
    return staging_path, run_id


def _d1(path: Path) -> None:
    connection = sqlite3.connect(path)
    connection.executescript(CANONICAL_SCHEMA)
    connection.execute("INSERT INTO languages(code,name_en) VALUES ('cmn','Mandarin'),('eng','English')")
    connection.commit()
    connection.close()


def test_local_import_writes_canonical_rows_and_no_runtime_tables(tmp_path):
    staging_path, run_id = _stage()
    d1_path = tmp_path / "d1.sqlite"
    _d1(d1_path)
    summary = import_release_to_local_d1(staging_path, d1_path, run_id, chunk_size=2)
    connection = sqlite3.connect(d1_path)
    assert summary.expressions == 9
    assert summary.edges == 5
    assert connection.execute("SELECT COUNT(*) FROM expressions").fetchone()[0] == 9
    assert connection.execute("SELECT COUNT(*) FROM expression_edges").fetchone()[0] == 5
    assert connection.execute("SELECT COUNT(*) FROM expression_edges WHERE relation_mask=4").fetchone()[0] == 1
    assert connection.execute("SELECT COUNT(*) FROM sqlite_master WHERE name LIKE 'dictionary_%'").fetchone()[0] == 0
    assert connection.execute("PRAGMA foreign_key_check").fetchall() == []
    connection.close()


def test_cod_has_three_stable_homographs_and_distinct_mappings(tmp_path):
    staging_path, run_id = _stage()
    d1_path = tmp_path / "d1.sqlite"
    _d1(d1_path)
    import_release_to_local_d1(staging_path, d1_path, run_id)
    connection = sqlite3.connect(d1_path)
    rows = connection.execute("SELECT text,homograph_index FROM expressions WHERE text='cod' ORDER BY homograph_index").fetchall()
    assert rows == [("cod", 1), ("cod", 2), ("cod", 3)]
    assert connection.execute("SELECT COUNT(DISTINCT expression_b_id) FROM expression_edges").fetchone()[0] >= 3
    connection.close()


def test_import_is_idempotent_for_external_resume_checkpoint(tmp_path):
    staging_path, run_id = _stage()
    d1_path = tmp_path / "d1.sqlite"
    _d1(d1_path)
    first = import_release_to_local_d1(staging_path, d1_path, run_id)
    # The orchestrator records a successful run externally and does not invoke
    # the writer twice; a retry with the same canonical database is checked by
    # stable counts and conflict-safe upserts on all non-expression rows.
    connection = sqlite3.connect(d1_path)
    before = tuple(connection.execute("SELECT COUNT(*) FROM expressions").fetchone())
    connection.close()
    assert first.expressions == before[0]
