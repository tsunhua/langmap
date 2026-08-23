"""Freeze and validate a completed Structured JSONL v2 corpus manifest."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


class CorpusDriftError(ValueError):
    """Raised when the input directory changes while a manifest is frozen."""


@dataclass(frozen=True)
class CorpusFile:
    path: str
    dictionary_key: str
    input_sha256: str
    output_sha256: str
    entry_count: int
    schema_version: int

    def to_dict(self) -> dict[str, Any]:
        return {
            "path": self.path,
            "dictionary_key": self.dictionary_key,
            "input_sha256": self.input_sha256,
            "output_sha256": self.output_sha256,
            "entry_count": self.entry_count,
            "schema_version": self.schema_version,
        }


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _header(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8-sig") as handle:
            value = json.loads(handle.readline())
    except (OSError, json.JSONDecodeError) as exc:
        raise CorpusDriftError(f"invalid JSONL header: {path}") from exc
    if not isinstance(value, dict) or value.get("record_type") != "dictionary" or value.get("schema_version") != 2:
        raise CorpusDriftError(f"{path.name}: only Structured JSONL v2 is admissible")
    required = ("dictionary_key", "input_sha256", "entry_count", "exporter_version")
    if any(key not in value for key in required):
        raise CorpusDriftError(f"{path.name}: incomplete v2 header")
    if not isinstance(value["dictionary_key"], str) or not value["dictionary_key"].strip():
        raise CorpusDriftError(f"{path.name}: dictionary_key is empty")
    entries = 0
    with path.open("r", encoding="utf-8-sig") as handle:
        next(handle, None)
        for line in handle:
            if line.strip():
                entries += 1
    if entries != int(value["entry_count"]):
        raise CorpusDriftError(f"{path.name}: header entry_count {value['entry_count']} != body {entries}")
    return value


def scan_corpus(directory: Path) -> tuple[CorpusFile, ...]:
    directory = Path(directory)
    files: list[CorpusFile] = []
    for path in sorted(directory.glob("*.jsonl")):
        header = _header(path)
        files.append(CorpusFile(path.name, str(header["dictionary_key"]), str(header["input_sha256"]), _sha256(path), int(header["entry_count"]), 2))
    if not files:
        raise CorpusDriftError(f"no v2 JSONL files found: {directory}")
    keys = [item.dictionary_key for item in files]
    if len(keys) != len(set(keys)):
        raise CorpusDriftError("duplicate dictionary_key in corpus")
    return tuple(sorted(files, key=lambda item: item.dictionary_key))


def manifest_payload(files: Iterable[CorpusFile]) -> dict[str, Any]:
    rows = [item.to_dict() for item in sorted(files, key=lambda item: item.dictionary_key)]
    encoded = json.dumps(rows, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return {"manifest_version": 1, "files": rows, "corpus_hash": hashlib.sha256(encoded).hexdigest()}


def freeze_corpus(first: tuple[CorpusFile, ...], second: tuple[CorpusFile, ...]) -> dict[str, Any]:
    if first != second:
        raise CorpusDriftError("corpus changed between freeze scans")
    return manifest_payload(first)
