import sqlite3
from pathlib import Path

from scripts.dictionary.incremental_import import order_jsonl_files, run_incremental_import


ROOT = Path(__file__).parents[3]
SCHEMA = ROOT / "backend" / "schema.sql"
REFERENCE = ROOT / "scripts" / "language-reference" / "artifacts" / "language-reference.sql"
FIXTURE = Path(__file__).parent / "fixtures" / "traditional_chinese_english_v2.jsonl"


def test_order_jsonl_files_is_small_first_and_deterministic(tmp_path):
    (tmp_path / "b.jsonl").write_bytes(b"1234")
    (tmp_path / "a.jsonl").write_bytes(b"12")
    (tmp_path / "ignored.txt").write_bytes(b"0")

    assert [path.name for path in order_jsonl_files(tmp_path)] == ["a.jsonl", "b.jsonl"]


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
    events = []
    first = run_incremental_import(input_dir, d1_path, state_path, staging_root, progress=events.append)
    assert first[0]["status"] == "success"
    assert first[0]["expressions"] == 7
    assert first[0]["d1_after"]["terms"] - first[0]["d1_before"]["terms"] == 7
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

    second = run_incremental_import(input_dir, d1_path, state_path, staging_root)
    assert second == [
        {
            "file": "small.jsonl",
            "ordinal": 1,
            "bytes": source.stat().st_size,
            "sha256": first[0]["sha256"],
            "status": "skipped",
            "release_id": first[0]["release_id"],
            "reason": "already_imported",
        }
    ]
