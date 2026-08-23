from __future__ import annotations

import json
from pathlib import Path

import pytest

from langmap_dictionary.corpus import CorpusDriftError, freeze_corpus, scan_corpus


def _write(path: Path, *, count: int = 1) -> None:
    header = {
        "record_type": "dictionary",
        "schema_version": 2,
        "dictionary_key": "com.example.test",
        "input_file_name": "test.csv",
        "input_sha256": "a" * 64,
        "entry_count": count,
        "exporter_version": "test",
    }
    entry = {
        "record_type": "entry",
        "schema_version": 2,
        "dictionary_key": "com.example.test",
        "entry_key": "e1",
        "record_fingerprint": "b" * 64,
        "csv_row_number": 1,
        "raw_headword": "cod 1",
        "canonical_headword": "cod",
        "forms": [],
        "pronunciations": [],
        "senses": [],
        "diagnostics": [],
    }
    path.write_text(json.dumps(header) + "\n" + "\n".join(json.dumps(entry) for _ in range(count)) + "\n", encoding="utf-8")


def test_scan_and_freeze_is_deterministic(tmp_path: Path) -> None:
    _write(tmp_path / "test.jsonl")
    first = scan_corpus(tmp_path)
    second = scan_corpus(tmp_path)
    payload = freeze_corpus(first, second)
    assert payload["files"][0]["dictionary_key"] == "com.example.test"
    assert len(payload["corpus_hash"]) == 64


def test_scan_rejects_body_count_drift(tmp_path: Path) -> None:
    _write(tmp_path / "test.jsonl", count=2)
    lines = (tmp_path / "test.jsonl").read_text(encoding="utf-8").splitlines()
    (tmp_path / "test.jsonl").write_text("\n".join(lines[:-1]) + "\n", encoding="utf-8")
    with pytest.raises(CorpusDriftError, match="entry_count"):
        scan_corpus(tmp_path)
