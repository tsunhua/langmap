import json
import sqlite3
from pathlib import Path
from unittest import mock

import pytest

from scripts.dictionary.incremental_import import (
    ReadingQualityError,
    _prepare_staging,
    assert_reading_quality,
    file_sha256,
    order_jsonl_files,
    run_incremental_import,
)
from scripts.dictionary.langmap_dictionary.schema import create_staging_database


ROOT = Path(__file__).parents[3]
SCHEMA = ROOT / "backend" / "schema.sql"
REFERENCE = ROOT / "scripts" / "language-reference" / "artifacts" / "language-reference.sql"
FIXTURE = Path(__file__).parent / "fixtures" / "traditional_chinese_english_v2.jsonl"


def test_order_jsonl_files_is_small_first_and_deterministic(tmp_path):
    (tmp_path / "b.jsonl").write_bytes(b"1234")
    (tmp_path / "a.jsonl").write_bytes(b"12")
    (tmp_path / "ignored.txt").write_bytes(b"0")

    assert [path.name for path in order_jsonl_files(tmp_path)] == ["a.jsonl", "b.jsonl"]


@pytest.mark.parametrize(
    "error_code",
    ["reading_script_mismatch", "relation_reading_as_headword"],
)
def test_reading_quality_gate_blocks_source_reading_defects(tmp_path, error_code):
    connection = create_staging_database(tmp_path / "staging.sqlite")
    connection.execute(
        "INSERT INTO staging_releases(id,manifest_hash,schema_version,status) "
        "VALUES ('release-test','hash',1,'staged')"
    )
    connection.execute(
        "INSERT INTO quarantine_items(release_id,error_code,detail) VALUES (?,?,?)",
        ("release-test", error_code, "fixture"),
    )

    with pytest.raises(ReadingQualityError, match=error_code):
        assert_reading_quality(connection, "release-test")


def test_reading_quality_gate_allows_nonblocking_quarantine(tmp_path):
    connection = create_staging_database(tmp_path / "staging.sqlite")
    connection.execute(
        "INSERT INTO staging_releases(id,manifest_hash,schema_version,status) "
        "VALUES ('release-test','hash',1,'staged')"
    )
    connection.execute(
        "INSERT INTO quarantine_items(release_id,error_code,detail) VALUES (?,?,?)",
        ("release-test", "unknown_pos", "fixture"),
    )

    assert_reading_quality(connection, "release-test")


def test_staging_fails_closed_on_mislabeled_ipa_reading(tmp_path):
    source = tmp_path / "bad.jsonl"
    header = {
        "record_type": "dictionary",
        "schema_version": 2,
        "dictionary_key": "com.apple.dictionary.th-en.oup",
        "input_file_name": "bad.csv",
        "input_sha256": "a" * 64,
        "entry_count": 1,
        "exporter_version": "test",
    }
    entry = {
        "record_type": "entry",
        "schema_version": 2,
        "dictionary_key": "com.apple.dictionary.th-en.oup",
        "entry_key": "e1",
        "record_fingerprint": "b" * 64,
        "csv_row_number": 1,
        "raw_headword": "peg",
        "canonical_headword": "peg",
        "homograph_marker": None,
        "direction_hint": "eng-to-tha",
        "forms": [],
        "pronunciations": [{"value": "เพก", "scheme": "UK_IPA"}],
        "senses": [],
        "diagnostics": [],
    }
    source.write_text(
        json.dumps(header, ensure_ascii=False) + "\n"
        + json.dumps(entry, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    with pytest.raises(ReadingQualityError, match="reading_script_mismatch"):
        _prepare_staging(source, tmp_path / "staging.sqlite", batch_size=1, commit_every=1)


def test_incremental_import_commits_one_file_and_resumes(tmp_path):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    source = input_dir / "small.jsonl"
    source.write_bytes(FIXTURE.read_bytes())
    d1_path = tmp_path / "d1.sqlite"
    d1 = sqlite3.connect(d1_path)
    d1.executescript(SCHEMA.read_text(encoding="utf-8"))
    d1.executescript(REFERENCE.read_text(encoding="utf-8"))
    d1.close()

    state_path = tmp_path / "state.json"
    staging_root = tmp_path / "staging"
    snapshot_root = tmp_path / "snapshots"
    events = []
    first = run_incremental_import(
        input_dir,
        d1_path,
        state_path,
        staging_root,
        snapshot_root=snapshot_root,
        progress=events.append,
    )
    assert first[0]["status"] == "success"
    assert first[0]["expressions"] == 7
    assert first[0]["d1_after"]["terms"] - first[0]["d1_before"]["terms"] == 7
    snapshot = Path(first[0]["before_snapshot_path"])
    assert snapshot.parent == snapshot_root
    assert snapshot.is_file()
    assert first[0]["before_snapshot_sha256"] == file_sha256(snapshot)
    snapshot_db = sqlite3.connect(snapshot)
    assert snapshot_db.execute("SELECT COUNT(*) FROM expressions").fetchone()[0] == first[0]["d1_before"]["terms"]
    snapshot_db.close()
    assert set(first[0]["phase_seconds"]) == {
        "stage", "normalize", "normalize_staging_read", "normalize_compute",
        "normalize_sqlite_flush", "normalize_checkpoint_commit",
        "normalize_foreign_key_check", "cluster", "cluster_cleanup",
        "cluster_clusters_insert", "cluster_members_insert", "cluster_foreign_key_check",
        "cluster_index", "cluster_commit", "staging_load", "d1_write", "total",
    }
    assert {event["phase"] for event in events} == {
        "stage", "normalize", "cluster", "staging_load", "d1_write",
    }
    assert list(staging_root.iterdir()) == []

    second = run_incremental_import(
        input_dir,
        d1_path,
        state_path,
        staging_root,
        snapshot_root=snapshot_root,
    )
    assert second == [
        {
            "file": "small.jsonl",
            "ordinal": 1,
            "bytes": source.stat().st_size,
            "sha256": first[0]["sha256"],
            "status": "skipped",
            "release_id": first[0]["release_id"],
            "reason": "already_imported",
            "before_snapshot_path": first[0]["before_snapshot_path"],
            "before_snapshot_sha256": first[0]["before_snapshot_sha256"],
            "snapshot_run_key": first[0]["snapshot_run_key"],
        }
    ]


def test_incremental_import_does_not_snapshot_before_quality_gate(tmp_path):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    (input_dir / "bad.jsonl").write_bytes(FIXTURE.read_bytes())
    d1_path = tmp_path / "d1.sqlite"
    d1 = sqlite3.connect(d1_path)
    d1.executescript(SCHEMA.read_text(encoding="utf-8"))
    d1.executescript(REFERENCE.read_text(encoding="utf-8"))
    d1.close()
    snapshot_root = tmp_path / "snapshots"

    with mock.patch(
        "scripts.dictionary.incremental_import._prepare_staging",
        side_effect=ReadingQualityError("fixture quality failure"),
    ):
        with pytest.raises(ReadingQualityError, match="fixture quality failure"):
            run_incremental_import(
                input_dir,
                d1_path,
                tmp_path / "state.json",
                tmp_path / "staging",
                snapshot_root=snapshot_root,
                stop_on_error=True,
            )

    assert not snapshot_root.exists()
