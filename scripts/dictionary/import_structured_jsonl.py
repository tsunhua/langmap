#!/usr/bin/env python3
"""Generate re-runnable SQL for a structured dictionary JSONL export.

The current LangMap model stores dictionary entries as expressions and
cross-language mappings.  A JSONL entry therefore becomes one Traditional
Chinese expression, one English expression per equivalent, a mapping edge for
each pair, and readings for the Chinese expression.
"""

from __future__ import annotations

import argparse
import json
import hashlib
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

from import_mappings import generated_expression_id, sql_quote


DEFAULT_CMN_LOCALE = "cmn-Hant-TW"
DEFAULT_ENG_LOCALE = "eng-Latn-US"
DEFAULT_SOURCE_ID = "dictionary-traditional-chinese-english-idioms"
DEFAULT_SOURCE_NAME = "Traditional Chinese - English Idioms"
DEFAULT_CREATOR_EMAIL = "dev@example.com"
DEFAULT_CHUNK_SIZE = 2000
SOURCE_TYPE = "publication"
EDGE_SOURCE = "dictionary"


@dataclass(frozen=True)
class Entry:
    entry_id: str
    source_row: int
    headword: str
    pronunciations: tuple[dict[str, str], ...]
    equivalents: tuple[tuple[int, int, str], ...]


@dataclass
class ImportData:
    expressions: dict[tuple[str, str], str] = field(default_factory=dict)
    expression_refs: dict[tuple[str, str], str] = field(default_factory=dict)
    attestations: list[tuple[str, str, str, str]] = field(default_factory=list)
    readings: list[tuple[str, str, str, str, str]] = field(default_factory=list)
    edges: set[tuple[str, str]] = field(default_factory=set)
    entries: int = 0
    pronunciation_count: int = 0
    equivalent_count: int = 0
    bullet_prefix_count: int = 0


def canonicalize_text(value: str) -> str:
    return unicodedata.normalize("NFC", value.strip())


def clean_equivalent(value: str) -> tuple[str, bool]:
    """Remove a leading list bullet and normalize surrounding whitespace."""

    text = canonicalize_text(value)
    had_bullet = text.startswith("•")
    if had_bullet:
        text = text[1:].lstrip()
    return text, had_bullet


def _required_string(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{label} must be a non-empty string")
    return canonicalize_text(value)


def read_entries(path: Path, encoding: str = "utf-8-sig") -> Iterable[Entry]:
    """Read entry records and reject malformed rows with line context."""

    with path.open("r", encoding=encoding) as handle:
        for line_number, raw_line in enumerate(handle, start=1):
            if not raw_line.strip():
                continue
            try:
                record = json.loads(raw_line)
            except json.JSONDecodeError as error:
                raise ValueError(f"invalid JSON at line {line_number}: {error}") from error
            if record.get("record_type") != "entry":
                continue

            entry_id = _required_string(record.get("entry_id"), f"entry_id at line {line_number}")
            headword = _required_string(record.get("headword"), f"headword at line {line_number}")
            pronunciations: list[dict[str, str]] = []
            for pronunciation_index, pronunciation in enumerate(record.get("pronunciations") or [], start=1):
                if not isinstance(pronunciation, dict):
                    raise ValueError(f"pronunciation {pronunciation_index} at line {line_number} must be an object")
                value = _required_string(pronunciation.get("value"), f"pronunciation value at line {line_number}")
                scheme = _required_string(pronunciation.get("scheme"), f"pronunciation scheme at line {line_number}")
                pronunciations.append({"value": value, "scheme": scheme})

            equivalents: list[tuple[int, int, str]] = []
            senses = record.get("senses") or []
            if not isinstance(senses, list):
                raise ValueError(f"senses at line {line_number} must be an array")
            for fallback_sense_id, sense in enumerate(senses, start=1):
                if not isinstance(sense, dict):
                    raise ValueError(f"sense at line {line_number} must be an object")
                raw_sense_id = sense.get("sense_id", fallback_sense_id)
                try:
                    sense_id = int(raw_sense_id)
                except (TypeError, ValueError) as error:
                    raise ValueError(f"sense_id at line {line_number} must be an integer") from error
                raw_equivalents = sense.get("equivalents") or []
                if not isinstance(raw_equivalents, list):
                    raise ValueError(f"equivalents at line {line_number} must be an array")
                for equivalent_index, raw_equivalent in enumerate(raw_equivalents, start=1):
                    if not isinstance(raw_equivalent, str):
                        raise ValueError(f"equivalent at line {line_number} must be a string")
                    equivalent = canonicalize_text(raw_equivalent)
                    if equivalent:
                        equivalents.append((sense_id, equivalent_index, equivalent))

            yield Entry(
                entry_id=entry_id,
                source_row=int(record.get("source_row") or line_number),
                headword=headword,
                pronunciations=tuple(pronunciations),
                equivalents=tuple(equivalents),
            )


def collect_data(entries: Iterable[Entry]) -> ImportData:
    data = ImportData()
    for entry in entries:
        data.entries += 1
        chinese_key = ("cmn", entry.headword)
        chinese_id = _ensure_expression(data, chinese_key, f"entry:{entry.entry_id}:headword")
        attestation_ref = f"entry:{entry.entry_id}:headword"
        data.attestations.append((chinese_id, DEFAULT_CMN_LOCALE, attestation_ref, f"att:{entry.entry_id}:cmn"))

        for pronunciation_index, pronunciation in enumerate(entry.pronunciations, start=1):
            reading_ref = attestation_ref
            reading_id = f"reading:{entry.entry_id}:{pronunciation_index}"
            data.readings.append((
                reading_id,
                chinese_id,
                pronunciation["scheme"],
                pronunciation["value"],
                reading_ref,
            ))
            data.pronunciation_count += 1

        for sense_id, equivalent_index, equivalent in entry.equivalents:
            cleaned, had_bullet = clean_equivalent(equivalent)
            if had_bullet:
                data.bullet_prefix_count += 1
            if not cleaned:
                continue
            english_key = ("eng", cleaned)
            english_id = _ensure_expression(
                data,
                english_key,
                f"entry:{entry.entry_id}:sense:{sense_id}:equivalent:{equivalent_index}",
            )
            equivalent_ref = f"entry:{entry.entry_id}:sense:{sense_id}:equivalent:{equivalent_index}"
            data.attestations.append((english_id, DEFAULT_ENG_LOCALE, equivalent_ref, f"att:{entry.entry_id}:eng:{sense_id}:{equivalent_index}"))
            low_id, high_id = sorted((chinese_id, english_id))
            data.edges.add((low_id, high_id))
            data.equivalent_count += 1

    return data


def _ensure_expression(data: ImportData, key: tuple[str, str], source_ref: str) -> str:
    expression_id = data.expressions.get(key)
    if expression_id is None:
        expression_id = generated_expression_id(*key)
        data.expressions[key] = expression_id
        data.expression_refs[key] = source_ref
    return expression_id


def _edge_id(source_id: str, low_id: str, high_id: str) -> str:
    digest = hashlib.sha256(f"{low_id}\0{high_id}".encode("utf-8")).hexdigest()[:24]
    return f"{source_id}:edge:{digest}"


def render_sql(
    data: ImportData,
    *,
    source_id: str,
    source_name: str,
    creator_email: str,
) -> list[str]:
    creator = f"(SELECT id FROM users WHERE email = {sql_quote(creator_email)})"
    lines = [
        "-- Generated by scripts/dictionary/import_structured_jsonl.py; safe to re-run.",
        "PRAGMA foreign_keys = ON;",
        f"INSERT OR IGNORE INTO sources (id, type, name) VALUES ({sql_quote(source_id)}, {sql_quote(SOURCE_TYPE)}, {sql_quote(source_name)});",
    ]

    # The current schema intentionally keeps one attestation per
    # expression/locale. Pick the lexicographically first source reference so
    # repeated dictionary occurrences produce deterministic SQL.
    canonical_attestations: dict[tuple[str, str], tuple[str, str]] = {}
    for expression_id, locale_code, source_ref, attestation_suffix in data.attestations:
        key = (expression_id, locale_code)
        candidate = (source_ref, attestation_suffix)
        if key not in canonical_attestations or candidate < canonical_attestations[key]:
            canonical_attestations[key] = candidate

    for (lang_code, text), expression_id in sorted(data.expressions.items()):
        source_ref = data.expression_refs[(lang_code, text)]
        text_hash = expression_id.split(":", 1)[1].split(".", 1)[0]
        lines.append(
            "INSERT OR IGNORE INTO expressions "
            "(id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by) VALUES "
            f"({sql_quote(expression_id)}, {sql_quote(lang_code)}, {sql_quote(text)}, {sql_quote(text_hash)}, 1, '', '[]', "
            f"{sql_quote(source_id)}, {sql_quote(source_ref)}, 'pending', {creator});"
        )

    for (expression_id, locale_code), (source_ref, attestation_suffix) in sorted(canonical_attestations.items()):
        attestation_id = f"{source_id}:{attestation_suffix}"
        lines.append(
            "INSERT OR IGNORE INTO expression_locale_attestations "
            "(id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES "
            f"({sql_quote(attestation_id)}, {sql_quote(expression_id)}, {sql_quote(locale_code)}, {sql_quote(source_id)}, {sql_quote(source_ref)}, {creator});"
        )

    canonical_readings: dict[tuple[str, str, str, str], tuple[str, str]] = {}
    for reading_id, expression_id, scheme, value, source_ref in data.readings:
        attestation_ref = canonical_attestations[(expression_id, DEFAULT_CMN_LOCALE)][0]
        if source_ref != attestation_ref:
            continue
        key = (expression_id, DEFAULT_CMN_LOCALE, scheme, value)
        candidate = (reading_id, source_ref)
        if key not in canonical_readings or candidate < canonical_readings[key]:
            canonical_readings[key] = candidate

    for (expression_id, locale_code, scheme, value), (reading_id, source_ref) in sorted(canonical_readings.items()):
        lines.append(
            "INSERT OR IGNORE INTO expression_readings "
            "(id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by) VALUES "
            f"({sql_quote(f'{source_id}:{reading_id}')}, {sql_quote(expression_id)}, {sql_quote(locale_code)}, "
            f"{sql_quote(scheme)}, {sql_quote(value)}, {sql_quote(source_id)}, {sql_quote(source_ref)}, {creator});"
        )

    for low_id, high_id in sorted(data.edges):
        lines.append(
            "INSERT OR IGNORE INTO expression_edges "
            "(id, expression_a_id, expression_b_id, score, source, created_by) VALUES "
            f"({sql_quote(_edge_id(source_id, low_id, high_id))}, {sql_quote(low_id)}, {sql_quote(high_id)}, 0, {sql_quote(EDGE_SOURCE)}, {creator});"
        )

    return lines


def unique_reading_count(data: ImportData) -> int:
    canonical_attestations: dict[tuple[str, str], str] = {}
    for expression_id, locale_code, source_ref, _ in data.attestations:
        key = (expression_id, locale_code)
        if key not in canonical_attestations or source_ref < canonical_attestations[key]:
            canonical_attestations[key] = source_ref
    return len({
        (expression_id, DEFAULT_CMN_LOCALE, scheme, value)
        for _, expression_id, scheme, value, source_ref in data.readings
        if source_ref == canonical_attestations.get((expression_id, DEFAULT_CMN_LOCALE))
    })


def write_sql(path: Path, lines: list[str], chunk_size: int) -> list[Path]:
    if chunk_size < 1:
        raise ValueError("chunk size must be at least 1")
    header = lines[:2]
    body = lines[2:]
    # A previous run may have produced more chunks. They are generated files
    # sharing this explicit output basename, so remove only those stale files
    # before writing the current deterministic set.
    chunk_suffix = path.suffix or ".sql"
    for stale_path in path.parent.glob(f"{path.stem}-????{chunk_suffix}"):
        if stale_path.is_file():
            stale_path.unlink()
    output_paths: list[Path] = []
    for chunk_index, start in enumerate(range(0, len(body), chunk_size), start=1):
        output_path = path if len(body) <= chunk_size else path.with_name(f"{path.stem}-{chunk_index:04d}{path.suffix or '.sql'}")
        output_path.write_text("\n".join(header + body[start:start + chunk_size] + [""]), encoding="utf-8")
        output_paths.append(output_path)
    return output_paths


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("jsonl_path", type=Path)
    parser.add_argument("--sql-output", type=Path, required=True)
    parser.add_argument("--source-id", default=DEFAULT_SOURCE_ID)
    parser.add_argument("--source-name", default=DEFAULT_SOURCE_NAME)
    parser.add_argument("--email", default=DEFAULT_CREATOR_EMAIL)
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--max-rows", type=int)
    parser.add_argument("--encoding", default="utf-8-sig")
    parser.add_argument("--sql-chunk-size", type=int, default=DEFAULT_CHUNK_SIZE)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.offset < 0:
        raise SystemExit("--offset must be non-negative")
    if args.max_rows is not None and args.max_rows < 1:
        raise SystemExit("--max-rows must be at least 1")
    if args.sql_chunk_size < 1:
        raise SystemExit("--sql-chunk-size must be at least 1")

    entries = list(read_entries(args.jsonl_path, args.encoding))[args.offset:]
    if args.max_rows is not None:
        entries = entries[:args.max_rows]
    data = collect_data(entries)
    lines = render_sql(data, source_id=args.source_id, source_name=args.source_name, creator_email=args.email)
    args.sql_output.parent.mkdir(parents=True, exist_ok=True)
    output_paths = write_sql(args.sql_output, lines, args.sql_chunk_size)
    print(json.dumps({
        "entries": data.entries,
        "expressions": len(data.expressions),
        "equivalents": data.equivalent_count,
        "edges": len(data.edges),
        "pronunciations": data.pronunciation_count,
        "readings": unique_reading_count(data),
        "attestations": len({(expression_id, locale_code) for expression_id, locale_code, _, _ in data.attestations}),
        "bullet_prefixes_removed": data.bullet_prefix_count,
        "sql_files": [str(path) for path in output_paths],
    }, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
