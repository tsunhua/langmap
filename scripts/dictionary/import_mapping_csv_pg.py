#!/usr/bin/env python3
"""Validate and synchronize one canonical dictionary CSV snapshot into PostgreSQL."""

from __future__ import annotations

import argparse
import csv
from datetime import datetime, timezone
import hashlib
import json
import os
import re
import subprocess
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Iterator
from uuid import uuid4

try:
    from scripts.dictionary.text_identity import (
        ExpressionTextIdentityError,
        canonicalize_expression_text,
    )
except ModuleNotFoundError:  # pragma: no cover - direct script execution
    from text_identity import ExpressionTextIdentityError, canonicalize_expression_text


LOCALE_HEADER = re.compile(r"^LOCALE_(?P<code>[A-Za-z0-9][A-Za-z0-9_-]*)$")
READING_HEADER = re.compile(
    r"^READING_(?P<locale>[A-Za-z0-9][A-Za-z0-9_-]*)_(?P<scheme>[A-Za-z0-9][A-Za-z0-9_-]*)$"
)
COMPACT_READING_HEADER = re.compile(
    r"^READING_(?P<locale>[A-Za-z0-9]{2,8}-[A-Za-z]{4}_"
    r"(?P<scheme>[A-Za-z0-9]+)-[A-Za-z0-9]{2,8}(?:_[A-Za-z0-9_]+)?)$"
)
COMPACT_READING_LOCALE = re.compile(
    r"^(?P<language>[A-Za-z0-9]{2,8})-(?P<script>[A-Za-z]{4})_"
    r"(?P<scheme>[A-Za-z0-9]+)-[A-Za-z0-9]{2,8}(?:_[A-Za-z0-9_]+)?$"
)
LOCALE_CODE = re.compile(
    r"^(?P<language>[a-z0-9]{2,8})"
    r"(?:-(?P<script>[A-Za-z]{4})(?:_(?P<orthography>[A-Za-z0-9]+))?)?"
    r"(?:-(?P<region>[A-Za-z0-9]{2,8})(?:_(?P<place>[A-Za-z0-9_]+))?)?$"
)
REQUIRED_PREFIX = ("ENTRY_ID",)


class CsvContractError(ValueError):
    """Raised when a manifest or CSV violates the canonical contract."""


@dataclass(frozen=True)
class Locale:
    code: str
    language: str
    script: str | None
    orthography: str | None
    region: str | None
    place: str
    name: str
    name_en: str


@dataclass(frozen=True)
class Cell:
    entry_id: str
    locale: Locale
    text: str


@dataclass(frozen=True)
class Reading:
    entry_id: str
    locale: Locale
    scheme: str
    value: str


@dataclass(frozen=True)
class Row:
    entry_id: str
    notes: tuple[str, ...]
    cells: tuple[Cell, ...]
    readings: tuple[Reading, ...] = ()


@dataclass(frozen=True)
class CsvLayout:
    locales: tuple[Locale, ...]
    reading_locales: tuple[Locale, ...]
    reading_columns: tuple[tuple[str, str], ...]
    note_index: int | None
    locale_start: int
    header_size: int


@dataclass(frozen=True)
class ValidatedManifest:
    path: Path
    manifest: dict[str, Any]
    csv_path: Path
    layout: CsvLayout
    source_key: str
    source_type: str
    source_name: str
    summary: dict[str, Any]


def _reading_header(locale: str, scheme: str) -> str:
    compact_match = COMPACT_READING_LOCALE.fullmatch(locale)
    if compact_match and compact_match.group("scheme").casefold() == scheme.casefold():
        return f"READING_{locale}"
    return f"READING_{locale}_{scheme}"


def _reading_column(header: str) -> tuple[str, str] | None:
    compact_match = COMPACT_READING_HEADER.fullmatch(header)
    if compact_match:
        return compact_match.group("locale"), compact_match.group("scheme").casefold()
    match = READING_HEADER.fullmatch(header)
    return (match.group("locale"), match.group("scheme")) if match else None


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _canonical(value: str) -> str:
    return unicodedata.normalize("NFC", value.strip())


def _manifest(path: Path) -> tuple[dict[str, Any], Path]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise CsvContractError(f"invalid manifest: {path}") from exc
    if not isinstance(payload, dict):
        raise CsvContractError("manifest must be an object")
    source_key = payload.get("source_key")
    if not isinstance(source_key, str) or not source_key.strip():
        raise CsvContractError("manifest.source_key is required")
    csv_name = payload.get("csv", "data.csv")
    if not isinstance(csv_name, str) or Path(csv_name).name != csv_name:
        raise CsvContractError("manifest.csv must be a file name in the manifest directory")
    csv_path = path.parent / csv_name
    if not csv_path.is_file():
        raise CsvContractError(f"CSV does not exist: {csv_path}")
    expected = payload.get("csv_sha256") or payload.get("data_sha256")
    if not isinstance(expected, str) or _sha256(csv_path) != expected:
        raise CsvContractError(f"CSV checksum mismatch: {csv_path}")
    return payload, csv_path


def _locale(code: str, metadata: dict[str, Any]) -> Locale:
    match = LOCALE_CODE.fullmatch(code)
    if not match:
        raise CsvContractError(f"invalid locale code: {code}")
    values = match.groupdict()
    item = metadata.get(code, {}) if isinstance(metadata, dict) else {}
    if not isinstance(item, dict):
        raise CsvContractError(f"locale metadata must be an object: {code}")
    return Locale(
        code=code,
        language=values["language"].lower(),
        script=values["script"],
        orthography=values["orthography"],
        region=values["region"],
        place=values["place"] or "",
        name=str(item.get("name") or code),
        name_en=str(item.get("name_en") or code),
    )


def _read_csv_layout(path: Path, metadata: dict[str, Any]) -> CsvLayout:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle)
        try:
            header = next(reader)
        except StopIteration as exc:
            raise CsvContractError("CSV is empty") from exc
    if not header or header[0].strip() != "ENTRY_ID":
        raise CsvContractError("first CSV column must be ENTRY_ID")
    if len(header) > 1 and header[1].strip() not in {"NOTE", ""}:
        raise CsvContractError("second CSV column must be NOTE when present")
    note_index = 1 if len(header) > 1 and header[1].strip() == "NOTE" else None
    locale_start = 2 if note_index is not None else 1
    locale_matches: list[re.Match[str]] = []
    reading_columns: list[tuple[str, str]] = []
    reading_started = False
    for value in header[locale_start:]:
        normalized = value.strip()
        locale_match = LOCALE_HEADER.fullmatch(normalized)
        reading_column = _reading_column(normalized)
        if locale_match:
            if reading_started:
                raise CsvContractError("locale columns must precede reading columns")
            locale_matches.append(locale_match)
        elif reading_column:
            reading_started = True
            reading_columns.append(reading_column)
        else:
            raise CsvContractError(
                "CSV columns must use LOCALE_<code>, READING_<locale>_<scheme>, or compact READING_<locale>"
            )
    if not locale_matches:
        raise CsvContractError("CSV needs at least two LOCALE_<code> columns")
    codes = [match.group("code") for match in locale_matches]
    if len(codes) < 2 or len(codes) != len(set(codes)):
        raise CsvContractError("CSV locale columns must be unique and contain at least two locales")
    if codes != sorted(codes, key=lambda value: value.encode("utf-8")):
        raise CsvContractError("CSV locale columns must be bytewise sorted")
    locales = tuple(_locale(code, metadata) for code in codes)
    if len(reading_columns) != len(set(reading_columns)):
        raise CsvContractError("CSV reading columns must be unique")
    if reading_columns != sorted(
        reading_columns,
        key=lambda item: _reading_header(*item).encode("utf-8"),
    ):
        raise CsvContractError("CSV reading columns must be bytewise sorted")
    locale_by_code = {locale.code: locale for locale in locales}
    reading_locales: list[Locale] = []
    for reading_locale, _scheme in reading_columns:
        if reading_locale not in locale_by_code:
            locale_by_code[reading_locale] = _locale(reading_locale, metadata)
            reading_locales.append(locale_by_code[reading_locale])
    return CsvLayout(
        locales=locales,
        reading_locales=tuple(reading_locales),
        reading_columns=tuple(reading_columns),
        note_index=note_index,
        locale_start=locale_start,
        header_size=len(header),
    )


def iter_rows(validated: ValidatedManifest) -> Iterator[Row]:
    """Yield normalized rows while retaining only the current row in memory."""
    layout = validated.layout
    locale_by_code = {locale.code: locale for locale in (*layout.locales, *layout.reading_locales)}
    with validated.csv_path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle)
        try:
            next(reader)
        except StopIteration as exc:
            raise CsvContractError("CSV is empty") from exc
        for line_number, values in enumerate(reader, 2):
            if len(values) != layout.header_size:
                raise CsvContractError(f"row {line_number}: column count mismatch")
            entry_id = _canonical(values[0])
            if not entry_id:
                raise CsvContractError(f"row {line_number}: ENTRY_ID must be non-empty and unique")
            note_values = values[layout.note_index].split("|") if layout.note_index is not None else []
            notes = tuple(
                dict.fromkeys(
                    normalized
                    for normalized in (_canonical(value) for value in note_values)
                    if normalized
                )
            )
            cells: list[Cell] = []
            for offset, locale in enumerate(layout.locales, layout.locale_start):
                for raw in values[offset].split("|"):
                    text = _canonical(raw)
                    if not text:
                        continue
                    try:
                        canonical_text = canonicalize_expression_text(text)
                    except ExpressionTextIdentityError as exc:
                        raise CsvContractError(
                            f"row {line_number} locale {locale.code}: {exc.code}"
                        ) from exc
                    if not canonical_text:
                        raise CsvContractError(
                            f"row {line_number} locale {locale.code}: expression is empty after normalization"
                        )
                    cells.append(Cell(entry_id, locale, canonical_text))
            if len(cells) < 2:
                raise CsvContractError(f"row {line_number}: at least two non-empty expressions are required")
            unique = {(cell.locale.code, cell.text): cell for cell in cells}
            readings: list[Reading] = []
            reading_start = layout.locale_start + len(layout.locales)
            for offset, (reading_locale, scheme) in enumerate(layout.reading_columns, reading_start):
                locale = locale_by_code[reading_locale]
                for raw in values[offset].split("|"):
                    value = _canonical(raw)
                    if value:
                        readings.append(Reading(entry_id, locale, scheme, value))
            yield Row(entry_id, notes, tuple(unique.values()), tuple(dict.fromkeys(readings)))


def _validate_manifest_contract(
    manifest: dict[str, Any],
    locales: tuple[Locale, ...],
    row_count: int,
    reading_count: int,
    reading_columns: tuple[tuple[str, str], ...] = (),
) -> None:
    expected_count = manifest.get("entry_count")
    if expected_count is not None:
        if isinstance(expected_count, bool) or not isinstance(expected_count, int) or expected_count != row_count:
            raise CsvContractError(
                f"manifest.entry_count={expected_count!r} does not match CSV rows={row_count}"
            )
    declared_locales = manifest.get("locales")
    if isinstance(declared_locales, list):
        if tuple(declared_locales) != tuple(locale.code for locale in locales):
            raise CsvContractError("manifest.locales does not match canonical CSV locale columns")
    metadata = manifest.get("locale_metadata")
    if isinstance(metadata, dict):
        unknown = sorted(set(metadata) - {locale.code for locale in locales})
        if unknown:
            raise CsvContractError(f"manifest.locale_metadata has unknown locale(s): {', '.join(unknown)}")
    source_type = manifest.get("source_type")
    source_name = manifest.get("source_name")
    if source_type is not None and (not isinstance(source_type, str) or not source_type.strip()):
        raise CsvContractError("manifest.source_type must be a non-empty string when present")
    if source_name is not None and (not isinstance(source_name, str) or not source_name.strip()):
        raise CsvContractError("manifest.source_name must be a non-empty string when present")
    if (source_type is None) != (source_name is None):
        raise CsvContractError("manifest.source_type and source_name must be provided together")
    target_locale = manifest.get("target_locale")
    if target_locale is not None and target_locale not in {locale.code for locale in locales}:
        raise CsvContractError("manifest.target_locale is not a CSV locale")
    expected_readings = manifest.get("reading_count")
    if expected_readings is not None:
        if isinstance(expected_readings, bool) or not isinstance(expected_readings, int) or expected_readings != reading_count:
            raise CsvContractError(
                f"manifest.reading_count={expected_readings!r} does not match CSV readings={reading_count}"
            )
    declared_reading_columns = manifest.get("reading_columns")
    if declared_reading_columns is not None:
        actual = list(reading_columns)
        if not isinstance(declared_reading_columns, list):
            raise CsvContractError("manifest.reading_columns must be an array")
        declared = sorted(
            {
                (str(item.get("locale")), str(item.get("scheme")))
                for item in declared_reading_columns
                if isinstance(item, dict)
            },
            key=lambda item: _reading_header(*item).encode("utf-8"),
        )
        if declared != actual:
            raise CsvContractError("manifest.reading_columns does not match CSV reading columns")


def _validation_summary(
    validated: ValidatedManifest,
    row_count: int,
    reading_count: int,
    expression_claims: int,
    edge_claims: int,
) -> dict[str, Any]:
    return {
        "source_key": validated.source_key,
        "source_type": validated.source_type,
        "source_name": validated.source_name,
        "csv": str(validated.csv_path),
        "csv_sha256": str(
            validated.manifest.get("csv_sha256")
            or validated.manifest.get("data_sha256")
        ),
        "rows": row_count,
        "locales": len(validated.layout.locales),
        "expressions": None,
        "edges": None,
        "distinct_counts": "deferred_to_postgresql",
        "readings": reading_count,
        "expression_claims": expression_claims,
        "edge_claims": edge_claims,
    }


def _prepare_manifest(manifest_path: Path) -> ValidatedManifest:
    manifest, csv_path = _manifest(manifest_path)
    metadata = manifest.get("locale_metadata", manifest.get("locales", {}))
    metadata_map = metadata if isinstance(metadata, dict) else {}
    layout = _read_csv_layout(csv_path, metadata_map)
    source_type = str(manifest.get("source_type") or "dictionary")
    source_name = str(manifest.get("source_name") or manifest["source_key"])
    prepared = ValidatedManifest(
        path=manifest_path,
        manifest=manifest,
        csv_path=csv_path,
        layout=layout,
        source_key=str(manifest["source_key"]),
        source_type=source_type,
        source_name=source_name,
        summary={},
    )
    row_count = 0
    reading_count = 0
    expression_claims = 0
    edge_claims = 0
    for row in iter_rows(prepared):
        row_count += 1
        expression_keys = {(cell.locale.language, cell.text) for cell in row.cells}
        expression_claims += len(expression_keys)
        edge_claims += len(expression_keys) * (len(expression_keys) - 1) // 2
        reading_count += len(row.readings)
    _validate_manifest_contract(
        manifest,
        layout.locales,
        row_count,
        reading_count,
        layout.reading_columns,
    )
    expected_checksum = str(manifest.get("csv_sha256") or manifest.get("data_sha256"))
    if _sha256(csv_path) != expected_checksum:
        raise CsvContractError(f"CSV changed during validation: {csv_path}")
    summary = _validation_summary(
        prepared,
        row_count,
        reading_count,
        expression_claims,
        edge_claims,
    )
    return ValidatedManifest(
        path=prepared.path,
        manifest=prepared.manifest,
        csv_path=prepared.csv_path,
        layout=prepared.layout,
        source_key=prepared.source_key,
        source_type=prepared.source_type,
        source_name=prepared.source_name,
        summary=summary,
    )


def discover_manifests(target: Path) -> tuple[Path, ...]:
    if target.is_file():
        return (target,)
    if not target.is_dir():
        raise CsvContractError(f"import target does not exist: {target}")
    manifests = tuple(
        sorted(
            (path for path in target.rglob("manifest.json") if path.is_file()),
            key=lambda path: path.relative_to(target).as_posix().encode("utf-8"),
        )
    )
    if not manifests:
        raise CsvContractError(f"input directory contains no manifest.json: {target}")
    return manifests


def validate_target(target: Path) -> tuple[ValidatedManifest, ...]:
    prepared = tuple(_prepare_manifest(path) for path in discover_manifests(target))
    source_keys: set[str] = set()
    identities: set[tuple[str, str]] = set()
    for item in prepared:
        if item.source_key in source_keys:
            raise CsvContractError(f"duplicate source_key in import target: {item.source_key}")
        identity = (item.source_type, item.source_name)
        if identity in identities:
            raise CsvContractError(
                "duplicate source identity in import target: "
                f"{item.source_type}:{item.source_name}"
            )
        source_keys.add(item.source_key)
        identities.add(identity)
    return prepared


def validate(manifest_path: Path) -> dict[str, Any]:
    return _prepare_manifest(manifest_path).summary


def _connect(url: str):
    try:
        import psycopg
    except ImportError as exc:  # pragma: no cover - exercised by CLI environments
        raise RuntimeError("install psycopg[binary] to use the PostgreSQL importer") from exc
    return psycopg.connect(url)


def _ensure_registry(cur, locales: Iterable[Locale]) -> dict[str, int]:
    result: dict[str, int] = {}
    for locale in locales:
        cur.execute("INSERT INTO languages(code,name_en) VALUES (%s,%s) ON CONFLICT (code) DO NOTHING", (locale.language, locale.name_en))
        if locale.script:
            cur.execute("INSERT INTO scripts(code,name_en,direction) VALUES (%s,%s,'ltr') ON CONFLICT (code) DO NOTHING", (locale.script, locale.script))
        if locale.region:
            cur.execute("INSERT INTO regions(code,name_en) VALUES (%s,%s) ON CONFLICT (code) DO NOTHING", (locale.region, locale.region))
        cur.execute("SELECT id FROM languages WHERE code=%s", (locale.language,))
        language_id = cur.fetchone()[0]
        cur.execute(
            """INSERT INTO language_locales(code,language_id,script_code,orthography,region_code,place_path,name,name_en)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s) ON CONFLICT (code) DO NOTHING""",
            (locale.code, language_id, locale.script, locale.orthography, locale.region, locale.place, locale.name, locale.name_en),
        )
        cur.execute(
            "SELECT id,language_id,script_code,orthography,region_code,place_path FROM language_locales WHERE code=%s",
            (locale.code,),
        )
        row = cur.fetchone()
        if not row:
            raise CsvContractError(f"could not resolve locale: {locale.code}")
        expected = (language_id, locale.script, locale.orthography, locale.region, locale.place)
        if tuple(row[1:]) != expected:
            raise CsvContractError(f"locale registry conflict: {locale.code}")
        result[locale.code] = row[0]
    return result



def _create_temp_tables(connection: Any) -> None:
    with connection.transaction():
        with connection.cursor() as cur:
            cur.execute(
                """
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_cells (
                    row_number BIGINT NOT NULL,
                    entry_id TEXT NOT NULL,
                    locale_code TEXT NOT NULL,
                    expression_text TEXT NOT NULL
                ) ON COMMIT DELETE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_entry_ids (
                    entry_id TEXT PRIMARY KEY
                ) ON COMMIT DELETE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_notes (
                    entry_id TEXT NOT NULL,
                    note TEXT NOT NULL,
                    PRIMARY KEY (entry_id, note)
                ) ON COMMIT DELETE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_readings (
                    entry_id TEXT NOT NULL,
                    locale_code TEXT NOT NULL,
                    language_code TEXT NOT NULL,
                    scheme TEXT NOT NULL,
                    value TEXT NOT NULL,
                    PRIMARY KEY (entry_id, locale_code, scheme, value)
                ) ON COMMIT DELETE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_expression_ids (
                    entry_id TEXT NOT NULL,
                    locale_code TEXT NOT NULL,
                    expression_text TEXT NOT NULL,
                    expression_id BIGINT NOT NULL,
                    PRIMARY KEY (entry_id, locale_code, expression_text)
                ) ON COMMIT DELETE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_pairs (
                    entry_id TEXT NOT NULL,
                    expression_a_id BIGINT NOT NULL,
                    expression_b_id BIGINT NOT NULL,
                    PRIMARY KEY (entry_id, expression_a_id, expression_b_id)
                ) ON COMMIT DELETE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_edge_pairs (
                    entry_id TEXT NOT NULL,
                    edge_id BIGINT NOT NULL,
                    PRIMARY KEY (entry_id, edge_id)
                ) ON COMMIT DELETE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_current_expressions (
                    expression_id BIGINT PRIMARY KEY
                ) ON COMMIT DELETE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_current_edges (
                    edge_id BIGINT PRIMARY KEY
                ) ON COMMIT DELETE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_orphan_expressions (
                    expression_id BIGINT PRIMARY KEY
                ) ON COMMIT PRESERVE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_orphan_edges (
                    edge_id BIGINT PRIMARY KEY
                ) ON COMMIT PRESERVE ROWS;
                CREATE TEMP TABLE IF NOT EXISTS _dictionary_affected_languages (
                    language_id BIGINT PRIMARY KEY
                ) ON COMMIT PRESERVE ROWS;
                """
            )


def _copy_source_rows(cur: Any, validated: ValidatedManifest) -> None:
    expected_checksum = validated.summary["csv_sha256"]
    current_checksum = _sha256(validated.csv_path)
    if current_checksum != expected_checksum:
        raise CsvContractError(
            f"CSV changed after preflight: {validated.csv_path}"
        )
    cur.execute(
        "TRUNCATE _dictionary_cells, _dictionary_entry_ids, _dictionary_notes, _dictionary_readings, "
        "_dictionary_expression_ids, _dictionary_pairs, _dictionary_edge_pairs, "
        "_dictionary_current_expressions, _dictionary_current_edges"
    )
    with cur.copy(
        "COPY _dictionary_cells(row_number, entry_id, locale_code, expression_text) FROM STDIN"
    ) as copy:
        for row_number, row in enumerate(iter_rows(validated), 1):
            for cell in row.cells:
                copy.write_row((row_number, row.entry_id, cell.locale.code, cell.text))
    cur.execute(
        """
        INSERT INTO _dictionary_entry_ids(entry_id)
        SELECT entry_id
        FROM _dictionary_cells
        GROUP BY entry_id, row_number
        """
    )
    with cur.copy("COPY _dictionary_notes(entry_id, note) FROM STDIN") as copy:
        for row in iter_rows(validated):
            for note in row.notes:
                copy.write_row((row.entry_id, note))
    with cur.copy(
        "COPY _dictionary_readings(entry_id, locale_code, language_code, scheme, value) FROM STDIN"
    ) as copy:
        for row in iter_rows(validated):
            for reading in row.readings:
                copy.write_row(
                    (
                        row.entry_id,
                        reading.locale.code,
                        reading.locale.language,
                        reading.scheme,
                        reading.value,
                    )
                )


def _source_id(cur: Any, validated: ValidatedManifest) -> int:
    cur.execute(
        "INSERT INTO sources(type,name) VALUES (%s,%s) ON CONFLICT (type,name) DO NOTHING",
        (validated.source_type, validated.source_name),
    )
    cur.execute(
        "SELECT id FROM sources WHERE type=%s AND name=%s",
        (validated.source_type, validated.source_name),
    )
    row = cur.fetchone()
    if not row:
        raise CsvContractError(f"could not resolve source: {validated.source_type}:{validated.source_name}")
    return int(row[0])


def _capture_source_candidates(cur: Any, source_id: int) -> None:
    cur.execute(
        """
        INSERT INTO _dictionary_current_expressions(expression_id)
        SELECT expression_id FROM expression_sources WHERE source_id=%s
        ON CONFLICT DO NOTHING
        """,
        (source_id,),
    )
    cur.execute(
        """
        INSERT INTO _dictionary_current_edges(edge_id)
        SELECT edge_id FROM expression_edge_sources WHERE source_id=%s
        ON CONFLICT DO NOTHING
        """,
        (source_id,),
    )
    cur.execute(
        """
        INSERT INTO _dictionary_orphan_expressions(expression_id)
        SELECT expression_id FROM _dictionary_current_expressions
        ON CONFLICT DO NOTHING
        """
    )
    cur.execute(
        """
        INSERT INTO _dictionary_orphan_edges(edge_id)
        SELECT edge_id FROM _dictionary_current_edges
        ON CONFLICT DO NOTHING
        """
    )
    cur.execute(
        """
        INSERT INTO _dictionary_affected_languages(language_id)
        SELECT DISTINCT e.language_id
        FROM expressions e
        JOIN _dictionary_current_expressions current ON current.expression_id=e.id
        ON CONFLICT DO NOTHING
        """
    )


def _remove_source_snapshot(cur: Any, source_id: int, source_key: str) -> None:
    cur.execute(
        """
        UPDATE expression_edges AS e
        SET annotations_json = (
            SELECT COALESCE(
                jsonb_agg(item ORDER BY ordinal) FILTER (
                    WHERE NOT (
                        jsonb_typeof(item)='object'
                        AND item->>'source_key'=%s
                    )
                ),
                '[]'::jsonb
            )::text
            FROM jsonb_array_elements(
                CASE
                    WHEN jsonb_typeof(e.annotations_json::jsonb)='array'
                    THEN e.annotations_json::jsonb
                    ELSE '[]'::jsonb
                END
            ) WITH ORDINALITY AS values(item, ordinal)
        )
        WHERE e.id IN (SELECT edge_id FROM _dictionary_current_edges)
        """,
        (source_key,),
    )
    cur.execute("DELETE FROM expression_edge_sources WHERE source_id=%s", (source_id,))
    cur.execute("DELETE FROM expression_sources WHERE source_id=%s", (source_id,))
    cur.execute("DELETE FROM expression_readings WHERE source_id=%s", (source_id,))


def _merge_staged_source(
    cur: Any,
    source_id: int,
    source_key: str,
) -> None:
    cur.execute(
        """
        INSERT INTO expressions(language_id, text, homograph_index)
        SELECT DISTINCT ll.language_id, cells.expression_text, 1
        FROM _dictionary_cells cells
        JOIN language_locales ll ON ll.code=cells.locale_code
        ON CONFLICT (language_id, text, homograph_index) DO NOTHING
        """
    )
    cur.execute(
        """
        INSERT INTO _dictionary_affected_languages(language_id)
        SELECT DISTINCT ll.language_id
        FROM _dictionary_cells cells
        JOIN language_locales ll ON ll.code=cells.locale_code
        ON CONFLICT DO NOTHING
        """
    )
    cur.execute(
        """
        INSERT INTO _dictionary_expression_ids(entry_id, locale_code, expression_text, expression_id)
        SELECT DISTINCT cells.entry_id, cells.locale_code, cells.expression_text, e.id
        FROM _dictionary_cells cells
        JOIN language_locales ll ON ll.code=cells.locale_code
        JOIN expressions e
          ON e.language_id=ll.language_id
         AND e.text=cells.expression_text
         AND e.homograph_index=1
        ON CONFLICT DO NOTHING
        """
    )
    cur.execute(
        """
        INSERT INTO expression_locale_links(expression_id, locale_id)
        SELECT DISTINCT ids.expression_id, ll.id
        FROM _dictionary_expression_ids ids
        JOIN language_locales ll ON ll.code=ids.locale_code
        ON CONFLICT DO NOTHING
        """
    )
    cur.execute(
        """
        INSERT INTO expression_sources(expression_id, source_id, source_marker)
        SELECT DISTINCT expression_id, %s, entry_id
        FROM _dictionary_expression_ids
        ON CONFLICT DO NOTHING
        """,
        (source_id,),
    )
    cur.execute(
        """
        INSERT INTO expression_readings(expression_id, locale_id, scheme, value, source_id)
        SELECT DISTINCT ids.expression_id, reading_locales.id, readings.scheme, readings.value, %s
        FROM _dictionary_readings readings
        JOIN _dictionary_expression_ids ids
          ON ids.entry_id=readings.entry_id
        JOIN expressions expression_rows ON expression_rows.id=ids.expression_id
        JOIN language_locales reading_locales ON reading_locales.code=readings.locale_code
        WHERE (
            ids.locale_code=readings.locale_code
            OR (
                expression_rows.language_id=reading_locales.language_id
                AND NOT EXISTS (
                    SELECT 1
                    FROM _dictionary_expression_ids exact_ids
                    WHERE exact_ids.entry_id=readings.entry_id
                      AND exact_ids.locale_code=readings.locale_code
                )
            )
        )
        ON CONFLICT DO NOTHING
        """,
        (source_id,),
    )
    cur.execute(
        """
        INSERT INTO _dictionary_pairs(entry_id, expression_a_id, expression_b_id)
        SELECT DISTINCT left_ids.entry_id,
                        left_ids.expression_id,
                        right_ids.expression_id
        FROM _dictionary_expression_ids left_ids
        JOIN _dictionary_expression_ids right_ids
          ON right_ids.entry_id=left_ids.entry_id
         AND left_ids.expression_id < right_ids.expression_id
        ON CONFLICT DO NOTHING
        """
    )
    cur.execute(
        """
        INSERT INTO expression_edges(expression_a_id, expression_b_id, relation_mask)
        SELECT DISTINCT expression_a_id, expression_b_id, 1
        FROM _dictionary_pairs
        ON CONFLICT (expression_a_id, expression_b_id) DO NOTHING
        """
    )
    cur.execute(
        """
        INSERT INTO _dictionary_edge_pairs(entry_id, edge_id)
        SELECT pairs.entry_id, edges.id
        FROM _dictionary_pairs pairs
        JOIN expression_edges edges
          ON edges.expression_a_id=pairs.expression_a_id
         AND edges.expression_b_id=pairs.expression_b_id
        ON CONFLICT DO NOTHING
        """
    )
    cur.execute(
        """
        INSERT INTO expression_edge_sources(edge_id, source_id, source_marker)
        SELECT edge_id, %s, entry_id
        FROM _dictionary_edge_pairs
        ON CONFLICT DO NOTHING
        """,
        (source_id,),
    )
    cur.execute(
        """
        WITH additions AS (
            SELECT pairs.edge_id,
                   jsonb_agg(
                       jsonb_build_object(
                           'source_key', %s::text,
                           'source_marker', notes.entry_id,
                           'text', notes.note
                       )
                       ORDER BY notes.entry_id, notes.note
                   ) AS values
            FROM _dictionary_edge_pairs pairs
            JOIN _dictionary_notes notes ON notes.entry_id=pairs.entry_id
            GROUP BY pairs.edge_id
        )
        UPDATE expression_edges edges
        SET annotations_json = (
            CASE
                WHEN jsonb_typeof(edges.annotations_json::jsonb)='array'
                THEN edges.annotations_json::jsonb
                ELSE '[]'::jsonb
            END || additions.values
        )::text
        FROM additions
        WHERE additions.edge_id=edges.id
        """,
        (source_key,),
    )


def _source_counts(cur: Any, source_id: int) -> dict[str, int]:
    cur.execute(
        "SELECT COUNT(DISTINCT expression_id) FROM expression_sources WHERE source_id=%s",
        (source_id,),
    )
    expressions = int(cur.fetchone()[0])
    cur.execute(
        "SELECT COUNT(DISTINCT edge_id) FROM expression_edge_sources WHERE source_id=%s",
        (source_id,),
    )
    edges = int(cur.fetchone()[0])
    cur.execute(
        "SELECT COUNT(*) FROM expression_sources WHERE source_id=%s",
        (source_id,),
    )
    expression_claims = int(cur.fetchone()[0])
    cur.execute(
        "SELECT COUNT(*) FROM expression_edge_sources WHERE source_id=%s",
        (source_id,),
    )
    edge_claims = int(cur.fetchone()[0])
    cur.execute(
        """
        SELECT COUNT(*)
        FROM (
            SELECT DISTINCT ids.expression_id, ll.id, readings.scheme, readings.value
            FROM _dictionary_readings readings
            JOIN _dictionary_expression_ids ids
              ON ids.entry_id=readings.entry_id
            JOIN expressions expression_rows ON expression_rows.id=ids.expression_id
            JOIN language_locales ll ON ll.code=readings.locale_code
            WHERE (
                ids.locale_code=readings.locale_code
                OR (
                    expression_rows.language_id=ll.language_id
                    AND NOT EXISTS (
                        SELECT 1
                        FROM _dictionary_expression_ids exact_ids
                        WHERE exact_ids.entry_id=readings.entry_id
                          AND exact_ids.locale_code=readings.locale_code
                    )
                )
            )
        ) expected
        """
    )
    expected_readings = int(cur.fetchone()[0])
    cur.execute("SELECT COUNT(*) FROM expression_readings WHERE source_id=%s", (source_id,))
    readings = int(cur.fetchone()[0])
    return {
        "expressions": expressions,
        "edges": edges,
        "readings": readings,
        "expression_claims": expression_claims,
        "edge_claims": edge_claims,
        "expected_readings": expected_readings,
    }


def _staged_source_counts(cur: Any) -> dict[str, int]:
    cur.execute(
        "SELECT COUNT(DISTINCT expression_id) FROM _dictionary_expression_ids"
    )
    expressions = int(cur.fetchone()[0])
    cur.execute(
        "SELECT COUNT(DISTINCT edge_id) FROM _dictionary_edge_pairs"
    )
    edges = int(cur.fetchone()[0])
    cur.execute(
        """
        SELECT COUNT(*)
        FROM (
            SELECT DISTINCT entry_id, expression_id
            FROM _dictionary_expression_ids
        ) expected
        """
    )
    expression_claims = int(cur.fetchone()[0])
    cur.execute("SELECT COUNT(*) FROM _dictionary_edge_pairs")
    edge_claims = int(cur.fetchone()[0])
    return {
        "expressions": expressions,
        "edges": edges,
        "expression_claims": expression_claims,
        "edge_claims": edge_claims,
    }


def _assert_source_counts(cur: Any, validated: ValidatedManifest, source_id: int) -> dict[str, int]:
    actual = _source_counts(cur, source_id)
    staged = _staged_source_counts(cur)
    expected = validated.summary
    checks = {
        "expressions": (actual["expressions"], staged["expressions"]),
        "edges": (actual["edges"], staged["edges"]),
        "expression_claims": (actual["expression_claims"], staged["expression_claims"]),
        "edge_claims": (actual["edge_claims"], staged["edge_claims"]),
        "readings": (actual["readings"], actual["expected_readings"]),
    }
    streaming_checks = {
        "expression_claims": (
            staged["expression_claims"],
            int(expected["expression_claims"]),
        ),
        "edge_claims": (staged["edge_claims"], int(expected["edge_claims"])),
    }
    mismatches = {
        key: {"actual": actual_value, "expected": expected_value}
        for key, (actual_value, expected_value) in checks.items()
        if actual_value != expected_value
    }
    mismatches.update(
        {
            key: {"staged": staged_value, "expected": expected_value}
            for key, (staged_value, expected_value) in streaming_checks.items()
            if staged_value != expected_value
        }
    )
    if mismatches:
        raise CsvContractError(
            f"source count invariant failed for {validated.source_key}: "
            f"{json.dumps(mismatches, sort_keys=True)}"
        )
    return actual


def _refresh_statistics(cur: Any, language_ids: Iterable[int]) -> None:
    for language_id in sorted(set(language_ids)):
        cur.execute(
            """INSERT INTO language_statistics(
                       language_id, expression_count, locale_count, active_ui_locale_count, updated_at)
                   SELECT l.id,
                          COUNT(DISTINCT e.id),
                          COUNT(DISTINCT ll.id),
                          COUNT(DISTINCT CASE WHEN u.status='active' THEN u.locale_id END),
                          (CURRENT_TIMESTAMP::text)
                     FROM languages l
                LEFT JOIN expressions e ON e.language_id=l.id
                LEFT JOIN language_locales ll ON ll.language_id=l.id
                LEFT JOIN ui_locales u ON u.locale_id=ll.id
                    WHERE l.id=%s
                    GROUP BY l.id
                   ON CONFLICT(language_id) DO UPDATE SET
                       expression_count=EXCLUDED.expression_count,
                       locale_count=EXCLUDED.locale_count,
                       active_ui_locale_count=EXCLUDED.active_ui_locale_count,
                       updated_at=EXCLUDED.updated_at""",
            (language_id,),
        )

def _quote_identifier(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


SECONDARY_INDEX_TABLES = (
    "expressions",
    "expression_locale_links",
    "expression_edges",
    "expression_sources",
    "expression_edge_sources",
)


def _capture_secondary_indexes(cur: Any) -> list[tuple[str, str, str]]:
    cur.execute(
        """
        SELECT namespaces.nspname,
               indexes.relname,
               pg_get_indexdef(pg_indexes.indexrelid)
        FROM pg_index pg_indexes
        JOIN pg_class indexes ON indexes.oid=pg_indexes.indexrelid
        JOIN pg_class tables ON tables.oid=pg_indexes.indrelid
        JOIN pg_namespace namespaces ON namespaces.oid=tables.relnamespace
        LEFT JOIN pg_constraint constraints ON constraints.conindid=pg_indexes.indexrelid
        WHERE tables.relname = ANY(%s)
          AND namespaces.nspname NOT IN ('pg_catalog', 'information_schema')
          AND pg_indexes.indisvalid
          AND NOT pg_indexes.indisunique
          AND constraints.oid IS NULL
        ORDER BY namespaces.nspname, indexes.relname
        """,
        (list(SECONDARY_INDEX_TABLES),),
    )
    return [(str(row[0]), str(row[1]), str(row[2])) for row in cur.fetchall()]


def _drop_secondary_indexes(cur: Any, definitions: list[tuple[str, str, str]]) -> None:
    for schema, name, _definition in definitions:
        cur.execute(f"DROP INDEX {_quote_identifier(schema)}.{_quote_identifier(name)}")


def _recreate_secondary_indexes(cur: Any, definitions: list[tuple[str, str, str]]) -> None:
    for _schema, _name, definition in definitions:
        cur.execute(definition)
    for table in SECONDARY_INDEX_TABLES:
        cur.execute(f"ANALYZE {_quote_identifier(table)}")


def _cleanup_candidates(cur: Any) -> None:
    cur.execute(
        """
        DELETE FROM expression_edges edges
        USING _dictionary_orphan_edges candidates
        WHERE edges.id=candidates.edge_id
          AND NOT EXISTS (
              SELECT 1 FROM expression_edge_sources sources
              WHERE sources.edge_id=edges.id
          )
          AND COALESCE(
              jsonb_array_length(
                  CASE
                      WHEN jsonb_typeof(edges.annotations_json::jsonb)='array'
                      THEN edges.annotations_json::jsonb
                      ELSE '[]'::jsonb
                  END
              ),
              0
          )=0
          AND edges.created_by IS NULL
          AND edges.score=0
          AND NOT EXISTS (SELECT 1 FROM edge_votes votes WHERE votes.edge_id=edges.id)
        """
    )
    cur.execute(
        """
        DELETE FROM expressions expressions
        USING _dictionary_orphan_expressions candidates
        WHERE expressions.id=candidates.expression_id
          AND NOT EXISTS (
              SELECT 1 FROM expression_sources sources
              WHERE sources.expression_id=expressions.id
          )
          AND NOT EXISTS (
              SELECT 1 FROM expression_edges edges
              WHERE edges.expression_a_id=expressions.id OR edges.expression_b_id=expressions.id
          )
          AND NOT EXISTS (
              SELECT 1 FROM expression_form_edges form_edges
              WHERE form_edges.form_id=expressions.id OR form_edges.lemma_id=expressions.id
          )
          AND NOT EXISTS (
              SELECT 1 FROM expression_splits splits
              WHERE splits.source_expression_id=expressions.id OR splits.target_expression_id=expressions.id
          )
          AND NOT EXISTS (
              SELECT 1 FROM handbook_section_items items
              WHERE items.expression_id=expressions.id
          )
          AND NOT EXISTS (
              SELECT 1 FROM ui_messages messages
              WHERE messages.source_expression_id=expressions.id
          )
          AND NOT EXISTS (SELECT 1 FROM languages WHERE name_expression_id=expressions.id)
          AND NOT EXISTS (SELECT 1 FROM scripts WHERE name_expression_id=expressions.id)
          AND NOT EXISTS (SELECT 1 FROM regions WHERE name_expression_id=expressions.id)
          AND NOT EXISTS (SELECT 1 FROM language_locales WHERE name_expression_id=expressions.id)
          AND NOT EXISTS (SELECT 1 FROM morphological_dimensions WHERE name_expression_id=expressions.id)
          AND NOT EXISTS (SELECT 1 FROM morphological_features WHERE name_expression_id=expressions.id)
        """
    )


def _refresh_affected_statistics(cur: Any) -> None:
    cur.execute("SELECT language_id FROM _dictionary_affected_languages ORDER BY language_id")
    _refresh_statistics(cur, (int(row[0]) for row in cur.fetchall()))


def _apply_one_source(
    connection: Any,
    validated: ValidatedManifest,
    rebuild_secondary_indexes: bool,
) -> dict[str, int]:
    with connection.transaction():
        with connection.cursor() as cur:
            cur.execute("SAVEPOINT before_source_merge")
            try:
                metadata = validated.manifest.get(
                    "locale_metadata",
                    validated.manifest.get("locales", {}),
                )
                metadata_map = metadata if isinstance(metadata, dict) else {}
                locales = (*validated.layout.locales, *validated.layout.reading_locales)
                _ensure_registry(cur, locales)
                source_id = _source_id(cur, validated)
                _capture_source_candidates(cur, source_id)
                _remove_source_snapshot(cur, source_id, validated.source_key)
                index_definitions = _capture_secondary_indexes(cur) if rebuild_secondary_indexes else []
                if index_definitions:
                    _drop_secondary_indexes(cur, index_definitions)
                _copy_source_rows(cur, validated)
                _merge_staged_source(cur, source_id, validated.source_key)
                counts = _assert_source_counts(cur, validated, source_id)
                if index_definitions:
                    _recreate_secondary_indexes(cur, index_definitions)
                _refresh_affected_statistics(cur)
                cur.execute("RELEASE SAVEPOINT before_source_merge")
                return counts
            except Exception:
                try:
                    cur.execute("ROLLBACK TO SAVEPOINT before_source_merge")
                except Exception:
                    pass
                raise


def create_pre_release_backup(database_url: str, backup_dir: Path) -> Path:
    backup_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    final_path = backup_dir / f"langmap-pre-release-{stamp}-{uuid4().hex}.dump"
    partial_path = backup_dir / f".{final_path.name}.partial"
    try:
        process = subprocess.run(
            [
                "pg_dump",
                "--format=custom",
                "--file",
                str(partial_path),
                "--dbname",
                database_url,
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        if process.returncode != 0:
            detail = (process.stderr or process.stdout or "pg_dump failed").strip()
            raise RuntimeError(f"pre-release pg_dump failed: {detail}")
        if not partial_path.is_file() or partial_path.stat().st_size == 0:
            raise RuntimeError("pre-release pg_dump produced an empty archive")
        os.replace(partial_path, final_path)
        os.chmod(final_path, 0o600)
        return final_path
    finally:
        if partial_path.exists():
            partial_path.unlink()


def apply_target(
    target: Path,
    database_url: str,
    *,
    backup_dir: Path | None = None,
    backup_enabled: bool = True,
    rebuild_secondary_indexes: bool = False,
) -> dict[str, Any]:
    prepared = validate_target(target)
    backup_path: Path | None = None
    if backup_enabled:
        if backup_dir is None:
            raise CsvContractError(
                "pre-release backup is enabled; provide --backup-dir or "
                "LANGMAP_PRE_RELEASE_BACKUP_DIR, or explicitly use --no-pre-release-backup"
            )
        backup_path = create_pre_release_backup(database_url, backup_dir)
    result: dict[str, Any] = {
        "success": False,
        "backup": str(backup_path) if backup_path else None,
        "committed": [],
        "failed": [],
        "not_attempted": [],
        "cleanup": {"status": "pending"},
    }
    with _connect(database_url) as connection:
        _create_temp_tables(connection)
        for index, validated in enumerate(prepared):
            try:
                counts = _apply_one_source(connection, validated, rebuild_secondary_indexes)
            except Exception as exc:
                result["failed"].append(
                    {"source_key": validated.source_key, "error": str(exc)}
                )
                result["not_attempted"] = [
                    item.source_key for item in prepared[index + 1 :]
                ]
                result["cleanup"] = {"status": "skipped", "reason": "source_failed"}
                return result
            result["committed"].append(
                {"source_key": validated.source_key, "summary": counts}
            )
        try:
            with connection.transaction():
                with connection.cursor() as cur:
                    _cleanup_candidates(cur)
                    _refresh_affected_statistics(cur)
            result["cleanup"] = {"status": "committed"}
        except Exception as exc:
            result["cleanup"] = {"status": "failed", "error": str(exc)}
            return result
    result["success"] = True
    return result


def apply(
    manifest_path: Path,
    database_url: str,
    *,
    backup_dir: Path | None = None,
    backup_enabled: bool = True,
    rebuild_secondary_indexes: bool = False,
) -> dict[str, Any]:
    result = apply_target(
        manifest_path,
        database_url,
        backup_dir=backup_dir,
        backup_enabled=backup_enabled,
        rebuild_secondary_indexes=rebuild_secondary_indexes,
    )
    if result["success"] and len(result["committed"]) == 1:
        return result["committed"][0]["summary"]
    return result


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--manifest", type=Path)
    target.add_argument("--input-dir", type=Path)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--check", action="store_true")
    action.add_argument("--apply", action="store_true")
    parser.add_argument("--backup-dir", type=Path)
    parser.add_argument("--no-pre-release-backup", action="store_true")
    parser.add_argument("--rebuild-secondary-indexes", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.rebuild_secondary_indexes and args.check:
            raise CsvContractError("--rebuild-secondary-indexes requires --apply")
        if args.no_pre_release_backup and args.backup_dir is not None:
            raise CsvContractError("--backup-dir cannot be combined with --no-pre-release-backup")
        target_path = args.manifest or args.input_dir
        if target_path is None:
            raise CsvContractError("an import target is required")
        if args.check:
            prepared = validate_target(target_path)
            if args.input_dir:
                output: dict[str, Any] = {
                    "manifests": [item.summary for item in prepared]
                }
            else:
                output = prepared[0].summary
            print(json.dumps(output, ensure_ascii=False, sort_keys=True))
            return 0
        database_url = os.environ.get("DATABASE_URL")
        if not database_url:
            raise CsvContractError("DATABASE_URL is required for --apply")
        backup_dir = args.backup_dir
        if backup_dir is None and not args.no_pre_release_backup:
            configured = os.environ.get("LANGMAP_PRE_RELEASE_BACKUP_DIR")
            backup_dir = Path(configured) if configured else None
        if args.no_pre_release_backup:
            print(
                "warning: pre-release pg_dump disabled; verify an equivalent recovery point exists",
                file=sys.stderr,
            )
        result = apply_target(
            target_path,
            database_url,
            backup_dir=backup_dir,
            backup_enabled=not args.no_pre_release_backup,
            rebuild_secondary_indexes=args.rebuild_secondary_indexes,
        )
        print(json.dumps(result, ensure_ascii=False, sort_keys=True))
        return 0 if result["success"] else 2
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
