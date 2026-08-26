import json
from pathlib import Path

import pytest

from scripts.dictionary.langmap_dictionary.loader import iter_staged_entries, load_jsonl_release
from scripts.dictionary.langmap_dictionary.schema import create_staging_database


def _record(entry_key="e1", *, schema_version=2):
    return {"record_type": "entry", "schema_version": schema_version, "dictionary_key": "fixture", "entry_key": entry_key, "record_fingerprint": "a" * 64, "csv_row_number": 1, "raw_headword": "頭", "canonical_headword": "頭", "homograph_marker": None, "direction_hint": "cmn-Hant-to-eng", "forms": [], "pronunciations": [], "diagnostics": [], "senses": [{"sense_key": entry_key + ":s1", "ordinal": 1, "definitions": ["keep offline"], "pos": ["noun"], "equivalents": [{"value": "head", "language": "eng"}], "relations": [{"kind": "synonym", "related_text": "top"}], "examples": [{"text": "頭很痛", "translation": "head hurts"}], "labels": ["body"]}]}


def _write(path: Path, records, *, count=None, version=2):
    header = {"record_type": "dictionary", "schema_version": version, "dictionary_key": "fixture", "input_file_name": "fixture.csv", "input_sha256": "b" * 64, "entry_count": len(records) if count is None else count, "exporter_version": "test"}
    path.write_text("\n".join(json.dumps(item, ensure_ascii=False, sort_keys=True) for item in [header, *records]) + "\n", encoding="utf-8")


def test_loader_preserves_children_and_is_idempotent(tmp_path):
    source = tmp_path / "fixture.jsonl"
    _write(source, [_record()])
    connection = create_staging_database(tmp_path / "stage.sqlite")
    first = load_jsonl_release(connection, [source])
    second = load_jsonl_release(connection, [source])
    assert first == second
    assert connection.execute("PRAGMA foreign_keys").fetchone()[0] == 1
    assert connection.execute("SELECT COUNT(*) FROM input_entries").fetchone()[0] == 1
    assert connection.execute("SELECT definitions_json FROM input_senses").fetchone()[0] == '[\"keep offline\"]'
    assert connection.execute("SELECT COUNT(*) FROM input_relations").fetchone()[0] == 1
    assert connection.execute("SELECT COUNT(*) FROM input_examples").fetchone()[0] == 1
    assert connection.execute("SELECT COUNT(*) FROM input_pos").fetchone()[0] == 1


def test_compact_loader_keeps_all_fields_without_redundant_child_rows(tmp_path):
    source = tmp_path / "fixture.jsonl"
    record = _record()
    _write(source, [record])
    connection = create_staging_database(tmp_path / "stage.sqlite")

    release = load_jsonl_release(connection, [source], compact=True).release_id

    raw = json.loads(connection.execute("SELECT raw_json FROM input_entries").fetchone()[0])
    assert raw["forms"] == record["forms"]
    assert raw["senses"] == record["senses"]
    assert connection.execute("SELECT COUNT(*) FROM input_senses").fetchone()[0] == 1
    for table in ("input_forms", "input_equivalents", "input_relations", "input_examples", "input_pos"):
        assert connection.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0] == 0
    assert [entry.entry_key for entry in iter_staged_entries(connection, release)] == ["e1"]


def test_schema_failure_rolls_back_rows_and_records_failed_release(tmp_path):
    source = tmp_path / "bad.jsonl"
    _write(source, [_record()], version=99)
    connection = create_staging_database(tmp_path / "stage.sqlite")
    with pytest.raises(ValueError, match="unsupported schema_version"):
        load_jsonl_release(connection, [source])
    assert connection.execute("SELECT COUNT(*) FROM input_entries").fetchone()[0] == 0
    assert connection.execute("SELECT status FROM staging_releases").fetchone()[0] == "failed"


def test_entry_count_mismatch_fails_without_partial_rows(tmp_path):
    source = tmp_path / "bad-count.jsonl"
    _write(source, [_record()], count=2)
    connection = create_staging_database(tmp_path / "stage.sqlite")
    with pytest.raises(ValueError, match="entry_count"):
        load_jsonl_release(connection, [source])
    assert connection.execute("SELECT COUNT(*) FROM input_entries").fetchone()[0] == 0


def test_staged_entry_iteration_batches_child_queries(tmp_path):
    source = tmp_path / "batched.jsonl"
    records = []
    for index in range(7):
        record = _record(f"e{index}")
        record["forms"] = [{"value": f"form-{index}"}]
        record["pronunciations"] = [{"value": f"reading-{index}", "scheme": "IPA"}]
        records.append(record)
    _write(source, records)
    connection = create_staging_database(tmp_path / "stage.sqlite")
    release = load_jsonl_release(connection, [source]).release_id
    statements = []
    connection.set_trace_callback(statements.append)
    entries = list(iter_staged_entries(connection, release, batch_size=3))
    connection.set_trace_callback(None)

    assert [entry.entry_key for entry in entries] == [f"e{index}" for index in range(7)]
    child_selects = [
        statement
        for statement in statements
        if any(
            f"FROM {table}" in statement
            for table in ("input_forms", "input_pronunciations", "input_senses")
        )
    ]
    assert len(child_selects) == 3


def test_staged_entry_iteration_keeps_children_with_nonmatching_key_order(tmp_path):
    source = tmp_path / "order.jsonl"
    first = _record("z-entry")
    first["senses"][0]["sense_key"] = "a-sense"
    second = _record("a-entry")
    second["senses"][0]["sense_key"] = "z-sense"
    _write(source, [first, second])
    connection = create_staging_database(tmp_path / "stage.sqlite")
    release = load_jsonl_release(connection, [source]).release_id

    entries = list(iter_staged_entries(connection, release))

    assert [(entry.entry_key, entry.senses[0].sense_key) for entry in entries] == [
        ("z-entry", "a-sense"),
        ("a-entry", "z-sense"),
    ]
