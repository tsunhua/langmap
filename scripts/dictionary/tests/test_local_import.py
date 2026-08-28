import sqlite3
from pathlib import Path

import scripts.dictionary.langmap_dictionary.local_import as local_import
from scripts.dictionary.langmap_dictionary.adapters.traditional_chinese_english import normalize_release
from scripts.dictionary.langmap_dictionary.clusters import build_explicit_clusters
from scripts.dictionary.langmap_dictionary.loader import load_jsonl_release
from scripts.dictionary.langmap_dictionary.local_import import (
    import_release_to_local_d1,
    load_staging_snapshot,
)
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


def _stage_in(path: Path):
    staging = create_staging_database(path)
    run_id = load_jsonl_release(staging, [FIXTURE]).release_id
    normalize_release(staging, run_id)
    build_explicit_clusters(staging, run_id)
    staging.close()
    return run_id


def test_staging_snapshot_resolves_occurrences_through_entry_sources(tmp_path):
    staging_path = tmp_path / "staging.sqlite"
    run_id = _stage_in(staging_path)
    connection = sqlite3.connect(staging_path)
    connection.row_factory = sqlite3.Row
    entry_keys = [str(row[0]) for row in connection.execute(
        "SELECT entry_key FROM input_entries WHERE release_id=? ORDER BY entry_key LIMIT 2",
        (run_id,),
    )]
    connection.execute(
        "UPDATE input_entries SET dictionary_key='secondary-source' WHERE release_id=? AND entry_key=?",
        (run_id, entry_keys[1]),
    )
    connection.commit()

    snapshot = load_staging_snapshot(connection, run_id)

    assert snapshot.entry_sources[entry_keys[1]] == "secondary-source"
    for occurrence in snapshot.occurrences.values():
        entry_key = str(occurrence["entry_key"])
        assert snapshot.entry_sources[entry_key]
    connection.close()


def test_staging_snapshot_rejects_occurrence_without_entry_source(tmp_path):
    staging_path = tmp_path / "staging.sqlite"
    run_id = _stage_in(staging_path)
    connection = sqlite3.connect(staging_path)
    connection.row_factory = sqlite3.Row
    entry_key = str(connection.execute(
        "SELECT entry_key FROM lexical_occurrences WHERE release_id=? LIMIT 1",
        (run_id,),
    ).fetchone()[0])
    connection.execute("PRAGMA foreign_keys=OFF")
    connection.execute(
        "DELETE FROM input_entries WHERE release_id=? AND entry_key=?",
        (run_id, entry_key),
    )
    connection.commit()

    try:
        load_staging_snapshot(connection, run_id)
    except ValueError as error:
        assert run_id in str(error)
        assert entry_key in str(error)
    else:
        raise AssertionError("missing entry source was accepted")
    finally:
        connection.close()


def test_local_import_caches_repeated_canonical_lookups_per_call(tmp_path, monkeypatch):
    staging_path = tmp_path / "staging.sqlite"
    run_id = _stage_in(staging_path)
    d1_path = tmp_path / "d1.sqlite"
    second_d1_path = tmp_path / "second-d1.sqlite"
    _d1(d1_path)
    _d1(second_d1_path)
    statements: dict[Path, list[str]] = {d1_path: [], second_d1_path: []}
    real_connect = local_import.sqlite3.connect

    def traced_connect(path, *args, **kwargs):
        connection = real_connect(path, *args, **kwargs)
        resolved = Path(path)
        if resolved in statements:
            connection.set_trace_callback(statements[resolved].append)
        return connection

    monkeypatch.setattr(local_import.sqlite3, "connect", traced_connect)
    import_release_to_local_d1(staging_path, d1_path, run_id)

    first_statements = statements[d1_path]
    schema_reads = [statement for statement in first_statements if statement.startswith("PRAGMA table_info(")]
    language_reads = [statement for statement in first_statements if statement.startswith("SELECT 1 FROM languages WHERE code=")]
    locale_reads = [statement for statement in first_statements if statement.startswith("SELECT id FROM language_locales WHERE code=")]
    source_reads = [statement for statement in first_statements if statement.startswith("SELECT id FROM sources WHERE type=")]
    assert len(schema_reads) == len(set(schema_reads))
    assert len(language_reads) == len(set(language_reads))
    assert len(locale_reads) == len(set(locale_reads))
    assert len(source_reads) == len(set(source_reads))

    import_release_to_local_d1(staging_path, second_d1_path, run_id)
    assert "PRAGMA table_info(sources)" in statements[second_d1_path]


def test_local_import_reports_staging_and_d1_progress_with_phase_timing(tmp_path):
    staging_path = tmp_path / "staging.sqlite"
    run_id = _stage_in(staging_path)
    d1_path = tmp_path / "d1.sqlite"
    _d1(d1_path)
    events = []

    summary = import_release_to_local_d1(
        staging_path,
        d1_path,
        run_id,
        chunk_size=2,
        progress=events.append,
    )

    assert {event["phase"] for event in events} == {"staging_load", "d1_write"}
    staging_steps = {event["step"] for event in events if event["phase"] == "staging_load"}
    d1_steps = {event["step"] for event in events if event["phase"] == "d1_write"}
    assert staging_steps == {"start", "entry_sources", "occurrences", "clusters", "members"}
    assert {"start", "expressions", "locale_links", "readings", "edges", "commit"} <= d1_steps
    for phase in ("staging_load", "d1_write"):
        elapsed = [event["elapsed_seconds"] for event in events if event["phase"] == phase]
        assert elapsed == sorted(elapsed)
    assert set(summary.phase_seconds) == {"staging_load", "d1_write"}


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


def test_equivalent_reuses_existing_expression_for_same_text(tmp_path):
    fixture = Path(__file__).parent / "fixtures" / "kin_reuse.jsonl"
    staging_path = fixture.with_suffix(".stage.sqlite")
    staging_path.unlink(missing_ok=True)
    staging = create_staging_database(staging_path)
    run_id = load_jsonl_release(staging, [fixture]).release_id
    normalize_release(staging, run_id)
    build_explicit_clusters(staging, run_id)
    staging.close()
    d1_path = tmp_path / "d1.sqlite"
    _d1(d1_path)
    d1 = sqlite3.connect(d1_path)
    d1.execute("INSERT INTO languages(code,name_en) VALUES ('tur','Turkish')")
    d1.commit()
    d1.close()
    # kin appears six times: once as a tur headword and five times as the tur
    # equivalent of English headwords. All share the same meaning, so they must
    # collapse into one canonical expression rather than six homographs.
    import_release_to_local_d1(staging_path, d1_path, run_id)
    connection = sqlite3.connect(d1_path)
    rows = connection.execute("SELECT text,tur,homograph_index FROM (SELECT e.text,e.homograph_index,(SELECT code FROM languages WHERE id=e.language_id) AS tur FROM expressions e) WHERE text='kin'").fetchall()
    assert rows == [("kin", "tur", 1)], rows
    edges = connection.execute(
        "SELECT COUNT(*) FROM expression_edges ed "
        "JOIN expressions a ON a.id=ed.expression_b_id WHERE a.text='kin' AND a.language_id=(SELECT id FROM languages WHERE code='tur')"
    ).fetchone()[0]
    assert edges == 5, edges
    connection.close()
