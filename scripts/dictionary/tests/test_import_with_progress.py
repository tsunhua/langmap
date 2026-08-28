import json
from pathlib import Path

import pytest

import scripts.dictionary.import_with_progress as importer
from scripts.dictionary.import_with_progress import status_of
from scripts.dictionary.incremental_import import file_sha256


def test_status_of_reports_empty_file_regardless_of_record(tmp_path):
    empty = tmp_path / "empty.jsonl"
    empty.write_bytes(b"")

    assert status_of(None, empty) == "empty"
    assert status_of({"status": "failed", "sha256": file_sha256(empty)}, empty) == "empty"
    assert status_of({"status": "success", "sha256": file_sha256(empty)}, empty) == "empty"


def test_status_of_requeues_empty_record_after_file_gains_content(tmp_path):
    path = tmp_path / "filled.jsonl"
    path.write_bytes(b"")
    empty_digest = file_sha256(path)

    path.write_bytes('{"record_type": "entry"}\n'.encode("utf-8"))
    assert status_of({"status": "empty", "sha256": empty_digest}, path) == "pending"
    assert status_of(None, path) == "pending"


def test_status_of_keeps_success_and_stale_states(tmp_path):
    path = tmp_path / "ok.jsonl"
    path.write_bytes(b"data")

    assert status_of({"status": "success", "sha256": file_sha256(path)}, path) == "up-to-date"
    assert status_of({"status": "success", "sha256": "stale-hash"}, path) == "stale"


def _configure_cli(tmp_path, monkeypatch):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    source = input_dir / "sample.jsonl"
    source.write_text('{"record_type":"entry"}\n', encoding="utf-8")
    d1 = tmp_path / "d1.sqlite"
    d1.touch()
    monkeypatch.setattr(importer, "INPUT_DIR", input_dir)
    monkeypatch.setattr(importer, "STATE_PATH", tmp_path / "state.json")
    monkeypatch.setattr(importer, "STAGING_ROOT", tmp_path / "staging")
    monkeypatch.setattr(importer, "default_d1", lambda: d1)
    return source, d1


@pytest.mark.parametrize("argv", [[], ["--list"], ["--limit", "1"]])
def test_read_only_cli_modes_never_import(tmp_path, monkeypatch, argv):
    _configure_cli(tmp_path, monkeypatch)

    def unexpected_import(*args, **kwargs):
        raise AssertionError("read-only CLI mode invoked import")

    monkeypatch.setattr(importer, "prepare_and_import", unexpected_import)
    assert importer.main(argv) == 0


def test_read_only_limit_stops_status_scan_after_selected_file(tmp_path, monkeypatch):
    input_dir = tmp_path / "input"
    input_dir.mkdir()
    for name, size in (("a.jsonl", 1), ("b.jsonl", 2), ("c.jsonl", 3)):
        (input_dir / name).write_bytes(b"x" * size)
    d1 = tmp_path / "d1.sqlite"
    d1.touch()
    monkeypatch.setattr(importer, "INPUT_DIR", input_dir)
    monkeypatch.setattr(importer, "STATE_PATH", tmp_path / "state.json")
    monkeypatch.setattr(importer, "STAGING_ROOT", tmp_path / "staging")
    monkeypatch.setattr(importer, "default_d1", lambda: d1)
    checked = []

    def tracked_status(record, path):
        checked.append(path.name)
        return "pending"

    monkeypatch.setattr(importer, "status_of", tracked_status)
    assert importer.main(["--limit", "1"]) == 0
    assert checked == ["a.jsonl"]


def test_cli_rejects_conflicting_actions(tmp_path, monkeypatch):
    _configure_cli(tmp_path, monkeypatch)
    with pytest.raises(SystemExit):
        importer.main(["--next", "--all"])


def test_next_import_prints_progress_and_saves_phase_timing(tmp_path, monkeypatch, capsys):
    source, _ = _configure_cli(tmp_path, monkeypatch)
    monkeypatch.setattr(importer, "d1_counts", lambda path: {"terms": 0, "edges": 0, "dict_terms": 0})

    def successful_import(path, d1, batch, commit, keep, *, progress=None):
        assert path == source
        for phase in ("stage", "normalize", "cluster", "staging_load", "d1_write"):
            progress({"phase": phase, "step": "completed", "processed": 1, "total": 1, "elapsed_seconds": 0.1})
        return {
            "release_id": "release-test",
            "input_records": 1,
            "normalized": 1,
            "expressions": 2,
            "edges": 1,
            "seconds": 0.5,
            "sha256": importer.inc.file_sha256(path),
            "phase_seconds": {
                "stage": 0.1,
                "normalize": 0.1,
                "cluster": 0.1,
                "staging_load": 0.1,
                "d1_write": 0.1,
                "total": 0.5,
            },
        }

    monkeypatch.setattr(importer, "prepare_and_import", successful_import)
    assert importer.main(["--next"]) == 0

    output = capsys.readouterr().out
    assert "[stage/completed]" in output
    assert "[d1_write/completed]" in output
    state = json.loads(importer.STATE_PATH.read_text(encoding="utf-8"))
    assert state["files"][source.name]["phase_seconds"]["staging_load"] == 0.1
