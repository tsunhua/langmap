#!/usr/bin/env python3
"""Convert one Hokkien-writing Swatow book CSV to Structured JSONL v2.

The book export stores Swatow romanization in ``puj`` and written forms in
``han``/``han_orig``.  A value without whitespace is treated as a word and
starts with a lowercase letter; a value containing whitespace is treated as a
sentence or phrase and starts with an uppercase letter.  Only the selected
columns become lexical equivalents; the remaining CSV columns are used only
for source location metadata.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import tempfile
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


PUJ_LOCALE = "nan-Latn-CN_Swatow"
HAN_LOCALE = "nan-Hant-CN_Swatow"
EN_LOCALE = "eng-Latn-US"
REQUIRED_COLUMNS = ("puj", "han", "han_orig", "en")


@dataclass(frozen=True)
class ExportSummary:
    input_path: Path
    output_path: Path
    source_key: str
    input_sha256: str
    entry_count: int
    output_sha256: str


def normalize_initial(value: str) -> str:
    """Normalize the initial letter without changing the rest of a value."""

    text = unicodedata.normalize("NFC", value.strip())
    if not text:
        return text
    word = not any(character.isspace() for character in text)
    for index, character in enumerate(text):
        if character.isalpha():
            initial = character.lower() if word else character.upper()
            return text[:index] + initial + text[index + 1:]
    return text


def _clean(value: str | None) -> str:
    return unicodedata.normalize("NFC", (value or "").strip())


def _file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _rows(path: Path, encoding: str) -> Iterable[dict[str, str]]:
    with path.open("r", encoding=encoding, newline="") as handle:
        reader = csv.DictReader(handle)
        fieldnames = tuple(reader.fieldnames or ())
        missing = [column for column in REQUIRED_COLUMNS if column not in fieldnames]
        if missing:
            raise ValueError(f"{path}: missing required CSV columns: {', '.join(missing)}")
        yield from reader


def _locator(row: dict[str, str]) -> str | None:
    source = _clean(row.get("source"))
    page = _clean(row.get("page_num"))
    parts = [part for part in (source, f"page {page}" if page else "") if part]
    return " > ".join(parts) or None


def _equivalents(row: dict[str, str]) -> list[dict[str, str]]:
    candidates = (
        ("han", HAN_LOCALE),
        ("han_orig", HAN_LOCALE),
        ("en", EN_LOCALE),
    )
    equivalents: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for column, locale in candidates:
        raw_value = _clean(row.get(column))
        if not raw_value:
            continue
        value = normalize_initial(raw_value) if column == "en" else raw_value
        key = (locale, value)
        if key in seen:
            continue
        seen.add(key)
        equivalents.append({"value": value, "language_hint": locale})
    return equivalents


def _record(source_key: str, row_number: int, row: dict[str, str]) -> dict[str, Any]:
    raw_puj = _clean(row.get("puj"))
    if not raw_puj:
        raise ValueError(f"CSV row {row_number}: puj is empty")
    equivalents = _equivalents(row)
    if not equivalents:
        raise ValueError(f"CSV row {row_number}: no han, han_orig, or en value")
    locator = _locator(row)
    entry_key = f"row-{row_number:06d}"
    record: dict[str, Any] = {
        "record_type": "entry",
        "schema_version": 2,
        "dictionary_key": source_key,
        "entry_key": entry_key,
        "record_fingerprint": "",
        "csv_row_number": row_number,
        "raw_headword": raw_puj,
        "canonical_headword": normalize_initial(raw_puj),
        "homograph_marker": None,
        "direction_hint": f"{PUJ_LOCALE}-to-eng",
        "native_locator": locator,
        "forms": [],
        "mappings": [],
        "pronunciations": [],
        "senses": [{
            "sense_key": f"{entry_key}-s1",
            "ordinal": 1,
            "native_locator": locator,
            "definitions": [],
            "pos": [],
            "equivalents": equivalents,
            "relations": [],
            "examples": [],
            "labels": [],
        }],
        "diagnostics": [],
    }
    fingerprint_payload = dict(record)
    fingerprint_payload.pop("record_fingerprint")
    record["record_fingerprint"] = hashlib.sha256(
        json.dumps(fingerprint_payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    return record


def _json_line(payload: object) -> bytes:
    return (json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")


def export_book_csv(input_path: Path, output_path: Path, source_key: str, encoding: str = "utf-8-sig") -> ExportSummary:
    """Write one deterministic JSONL artifact and refuse accidental overwrite."""

    input_path = Path(input_path)
    output_path = Path(output_path)
    source_key = source_key.strip()
    if not source_key:
        raise ValueError("source_key must not be empty")
    if not input_path.is_file():
        raise FileNotFoundError(input_path)
    if output_path.exists():
        raise FileExistsError(output_path)

    input_sha256 = _file_sha256(input_path)
    records = _rows(input_path, encoding)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    output_digest = hashlib.sha256()
    temporary_name: str | None = None
    try:
        fd, temporary_name = tempfile.mkstemp(prefix=f".{output_path.name}.", suffix=".tmp", dir=output_path.parent)
        with os.fdopen(fd, "wb") as handle:
            header = {
                "record_type": "dictionary",
                "schema_version": 2,
                "dictionary_key": source_key,
                "input_file_name": input_path.name,
                "input_sha256": input_sha256,
                "entry_count": sum(1 for _ in _rows(input_path, encoding)),
                "exporter_version": "langmap-swatow-csv/1",
            }
            for payload in (header,):
                line = _json_line(payload)
                handle.write(line)
                output_digest.update(line)
            for row_number, row in enumerate(records, 1):
                line = _json_line(_record(source_key, row_number, row))
                handle.write(line)
                output_digest.update(line)
                count += 1
            if count != header["entry_count"]:
                raise ValueError(f"entry count changed while reading {input_path}")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_name, output_path)
        temporary_name = None
    finally:
        if temporary_name is not None:
            os.unlink(temporary_name)
    return ExportSummary(input_path, output_path, source_key, input_sha256, count, output_digest.hexdigest())


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--source-key", required=True)
    parser.add_argument("--encoding", default="utf-8-sig")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    summary = export_book_csv(args.input, args.output, args.source_key, args.encoding)
    print(json.dumps({
        "input_path": str(summary.input_path),
        "output_path": str(summary.output_path),
        "source_key": summary.source_key,
        "input_sha256": summary.input_sha256,
        "entry_count": summary.entry_count,
        "output_sha256": summary.output_sha256,
    }, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
