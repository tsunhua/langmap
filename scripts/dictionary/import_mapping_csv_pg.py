#!/usr/bin/env python3
"""Validate and synchronize one canonical dictionary CSV snapshot into PostgreSQL."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

from scripts.dictionary.text_identity import (
    ExpressionTextIdentityError,
    canonicalize_expression_text,
)


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


def _read_csv(
    path: Path,
    metadata: dict[str, Any],
) -> tuple[list[Locale], list[Row], tuple[tuple[str, str], ...]]:
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
        locale_codes = locale_matches
        if not locale_codes:
            raise CsvContractError("CSV needs at least two LOCALE_<code> columns")
        codes = [match.group("code") for match in locale_codes]
        if len(codes) < 2 or len(codes) != len(set(codes)):
            raise CsvContractError("CSV locale columns must be unique and contain at least two locales")
        if codes != sorted(codes, key=lambda value: value.encode("utf-8")):
            raise CsvContractError("CSV locale columns must be bytewise sorted")
        locales = [_locale(code, metadata) for code in codes]
        if len(reading_columns) != len(set(reading_columns)):
            raise CsvContractError("CSV reading columns must be unique")
        if reading_columns != sorted(
            reading_columns,
            key=lambda item: _reading_header(*item).encode("utf-8"),
        ):
            raise CsvContractError("CSV reading columns must be bytewise sorted")
        locale_by_code = {locale.code: locale for locale in locales}
        for reading_locale, _scheme in reading_columns:
            if reading_locale not in locale_by_code:
                locale_by_code[reading_locale] = _locale(reading_locale, metadata)
        rows: list[Row] = []
        entry_ids: set[str] = set()
        for line_number, values in enumerate(reader, 2):
            if len(values) != len(header):
                raise CsvContractError(f"row {line_number}: column count mismatch")
            entry_id = _canonical(values[0])
            if not entry_id or entry_id in entry_ids:
                raise CsvContractError(f"row {line_number}: ENTRY_ID must be non-empty and unique")
            entry_ids.add(entry_id)
            notes = tuple(dict.fromkeys(_canonical(value) for value in (values[note_index].split("|") if note_index is not None else []) if _canonical(value)))
            cells: list[Cell] = []
            for offset, locale in enumerate(locales, locale_start):
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
            reading_start = locale_start + len(locales)
            for offset, (reading_locale, scheme) in enumerate(reading_columns, reading_start):
                locale = locale_by_code[reading_locale]
                for raw in values[offset].split("|"):
                    value = _canonical(raw)
                    if value:
                        readings.append(Reading(entry_id, locale, scheme, value))
            rows.append(Row(entry_id, notes, tuple(unique.values()), tuple(dict.fromkeys(readings))))
    return locales, rows, tuple(reading_columns)


def _validate_manifest_contract(
    manifest: dict[str, Any],
    locales: list[Locale],
    rows: list[Row],
    reading_columns: tuple[tuple[str, str], ...] = (),
) -> None:
    expected_count = manifest.get("entry_count")
    if expected_count is not None:
        if isinstance(expected_count, bool) or not isinstance(expected_count, int) or expected_count != len(rows):
            raise CsvContractError(
                f"manifest.entry_count={expected_count!r} does not match CSV rows={len(rows)}"
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
    reading_count = sum(len(row.readings) for row in rows)
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


def validate(manifest_path: Path) -> dict[str, Any]:
    manifest, csv_path = _manifest(manifest_path)
    metadata = manifest.get("locale_metadata", manifest.get("locales", {}))
    locales, rows, reading_columns = _read_csv(csv_path, metadata if isinstance(metadata, dict) else {})
    _validate_manifest_contract(manifest, locales, rows, reading_columns)
    expressions = {(cell.locale.language, cell.text) for row in rows for cell in row.cells}
    edges = {
        tuple(sorted(((a.locale.language, a.text), (b.locale.language, b.text))))
        for row in rows
        for index, a in enumerate(row.cells)
        for b in row.cells[index + 1 :]
        if (a.locale.language, a.text) != (b.locale.language, b.text)
    }
    return {
        "source_key": manifest["source_key"],
        "csv": str(csv_path),
        "csv_sha256": _sha256(csv_path),
        "rows": len(rows),
        "locales": len(locales),
        "expressions": len(expressions),
        "edges": len(edges),
        "readings": sum(len(row.readings) for row in rows),
    }


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



def _owned_ids(cur, source_id: int) -> tuple[set[int], set[int]]:
    cur.execute("SELECT expression_id FROM expression_sources WHERE source_id=%s", (source_id,))
    expression_ids = {int(row[0]) for row in cur.fetchall()}
    cur.execute("SELECT edge_id FROM expression_edge_sources WHERE source_id=%s", (source_id,))
    edge_ids = {int(row[0]) for row in cur.fetchall()}
    return expression_ids, edge_ids


def _remove_source_annotations(cur, edge_ids: Iterable[int], source_key: str) -> None:
    for edge_id in sorted(set(edge_ids)):
        cur.execute("SELECT annotations_json FROM expression_edges WHERE id=%s", (edge_id,))
        row = cur.fetchone()
        if not row:
            continue
        existing = row[0]
        if isinstance(existing, list):
            annotations = existing
        else:
            try:
                annotations = json.loads(existing or "[]")
            except (TypeError, json.JSONDecodeError):
                annotations = []
        if not isinstance(annotations, list):
            annotations = []
        filtered = [
            item for item in annotations
            if not (isinstance(item, dict) and item.get("source_key") == source_key)
        ]
        if filtered != annotations:
            cur.execute(
                "UPDATE expression_edges SET annotations_json=%s WHERE id=%s",
                (json.dumps(filtered, ensure_ascii=False, sort_keys=True), edge_id),
            )


def _cleanup_source_orphans(cur, expression_ids: Iterable[int], edge_ids: Iterable[int]) -> None:
    """Remove rows owned only by this snapshot when no user references remain."""
    for edge_id in sorted(set(edge_ids)):
        cur.execute(
            """SELECT e.annotations_json, e.created_by, e.score,
                      EXISTS (SELECT 1 FROM edge_votes v WHERE v.edge_id=e.id)
                 FROM expression_edges e WHERE e.id=%s""",
            (edge_id,),
        )
        row = cur.fetchone()
        if not row:
            continue
        annotations, created_by, score, has_votes = row
        cur.execute("SELECT 1 FROM expression_edge_sources WHERE edge_id=%s LIMIT 1", (edge_id,))
        has_other_source = cur.fetchone() is not None
        try:
            parsed_annotations = annotations if isinstance(annotations, list) else json.loads(annotations or "[]")
        except (TypeError, json.JSONDecodeError):
            parsed_annotations = []
        if (
            not has_other_source
            and not parsed_annotations
            and created_by is None
            and int(score or 0) == 0
            and not has_votes
        ):
            cur.execute("DELETE FROM expression_edges WHERE id=%s", (edge_id,))

    for expression_id in sorted(set(expression_ids)):
        cur.execute("SELECT 1 FROM expression_sources WHERE expression_id=%s LIMIT 1", (expression_id,))
        if cur.fetchone() is not None:
            continue
        cur.execute(
            """SELECT 1 WHERE EXISTS (SELECT 1 FROM expression_edges WHERE expression_a_id=%s OR expression_b_id=%s)
                   OR EXISTS (SELECT 1 FROM expression_form_edges WHERE form_id=%s OR lemma_id=%s)
                   OR EXISTS (SELECT 1 FROM expression_splits WHERE source_expression_id=%s OR target_expression_id=%s)
                   OR EXISTS (SELECT 1 FROM handbook_section_items WHERE expression_id=%s)
                   OR EXISTS (SELECT 1 FROM ui_messages WHERE source_expression_id=%s)
                   OR EXISTS (SELECT 1 FROM languages WHERE name_expression_id=%s)
                   OR EXISTS (SELECT 1 FROM scripts WHERE name_expression_id=%s)
                   OR EXISTS (SELECT 1 FROM regions WHERE name_expression_id=%s)
                   OR EXISTS (SELECT 1 FROM language_locales WHERE name_expression_id=%s)
                   OR EXISTS (SELECT 1 FROM morphological_dimensions WHERE name_expression_id=%s)
                   OR EXISTS (SELECT 1 FROM morphological_features WHERE name_expression_id=%s)""",
            (expression_id, expression_id, expression_id, expression_id, expression_id, expression_id,
             expression_id, expression_id, expression_id, expression_id, expression_id, expression_id,
             expression_id, expression_id),
        )
        if cur.fetchone() is None:
            cur.execute("DELETE FROM expressions WHERE id=%s", (expression_id,))


def _refresh_statistics(cur, language_ids: Iterable[int]) -> None:
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

def apply(manifest_path: Path, database_url: str) -> dict[str, Any]:
    summary = validate(manifest_path)
    manifest, csv_path = _manifest(manifest_path)
    metadata = manifest.get("locale_metadata", manifest.get("locales", {}))
    locales, rows, reading_columns = _read_csv(csv_path, metadata if isinstance(metadata, dict) else {})
    source_key = str(manifest["source_key"])
    with _connect(database_url) as connection:
        with connection.cursor() as cur:
            metadata_map = metadata if isinstance(metadata, dict) else {}
            reading_locale_objects = {
                code: _locale(code, metadata_map)
                for code, _scheme in reading_columns
                if code not in {locale.code for locale in locales}
            }
            locale_ids = _ensure_registry(cur, (*locales, *reading_locale_objects.values()))
            source_type = str(manifest.get("source_type") or "dictionary")
            source_name = str(manifest.get("source_name") or source_key)
            cur.execute(
                "INSERT INTO sources(type,name) VALUES (%s,%s) ON CONFLICT (type,name) DO NOTHING",
                (source_type, source_name),
            )
            cur.execute("SELECT id FROM sources WHERE type=%s AND name=%s", (source_type, source_name))
            source_id = cur.fetchone()[0]
            owned_expression_ids, owned_edge_ids = _owned_ids(cur, source_id)
            affected_language_ids: set[int] = set()
            if owned_expression_ids:
                marks = ",".join("%s" for _ in owned_expression_ids)
                cur.execute(
                    f"SELECT DISTINCT language_id FROM expressions WHERE id IN ({marks})",
                    tuple(sorted(owned_expression_ids)),
                )
                affected_language_ids.update(int(row[0]) for row in cur.fetchall())
            _remove_source_annotations(cur, owned_edge_ids, source_key)
            cur.execute("DELETE FROM expression_edge_sources WHERE source_id=%s", (source_id,))
            cur.execute("DELETE FROM expression_sources WHERE source_id=%s", (source_id,))
            cur.execute("DELETE FROM expression_readings WHERE source_id=%s", (source_id,))
            _cleanup_source_orphans(cur, owned_expression_ids, owned_edge_ids)
            for locale in locales:
                cur.execute("SELECT language_id FROM language_locales WHERE id=%s", (locale_ids[locale.code],))
                affected_language_ids.add(int(cur.fetchone()[0]))
            expression_ids: dict[tuple[str, str], int] = {}
            for row in sorted(rows, key=lambda item: item.entry_id):
                for cell in row.cells:
                    key = (cell.locale.language, cell.text)
                    if key not in expression_ids:
                        cur.execute("SELECT id FROM languages WHERE code=%s", (cell.locale.language,))
                        language_id = cur.fetchone()[0]
                        affected_language_ids.add(int(language_id))
                        cur.execute("INSERT INTO expressions(language_id,text,homograph_index) VALUES (%s,%s,1) ON CONFLICT (language_id,text,homograph_index) DO NOTHING", (language_id, cell.text))
                        cur.execute("SELECT id FROM expressions WHERE language_id=%s AND text=%s AND homograph_index=1", (language_id, cell.text))
                        expression_ids[key] = cur.fetchone()[0]
                    expression_id = expression_ids[key]
                    cur.execute("INSERT INTO expression_locale_links(expression_id,locale_id) VALUES (%s,%s) ON CONFLICT DO NOTHING", (expression_id, locale_ids[cell.locale.code]))
                    cur.execute("INSERT INTO expression_sources(expression_id,source_id,source_marker) VALUES (%s,%s,%s) ON CONFLICT DO NOTHING", (expression_id, source_id, row.entry_id))
                for reading in row.readings:
                    reading_expression_ids = {
                        expression_ids[(cell.locale.language, cell.text)]
                        for cell in row.cells
                        if cell.locale.code == reading.locale.code
                    }
                    for expression_id in sorted(reading_expression_ids):
                        cur.execute(
                            """INSERT INTO expression_readings(expression_id,locale_id,scheme,value,source_id)
                               VALUES (%s,%s,%s,%s,%s) ON CONFLICT DO NOTHING""",
                            (expression_id, locale_ids[reading.locale.code], reading.scheme, reading.value, source_id),
                        )
            for row in sorted(rows, key=lambda item: item.entry_id):
                ids = sorted({expression_ids[(cell.locale.language, cell.text)] for cell in row.cells})
                for left_index, left_id in enumerate(ids):
                    for right_id in ids[left_index + 1 :]:
                        cur.execute("INSERT INTO expression_edges(expression_a_id,expression_b_id,relation_mask) VALUES (%s,%s,1) ON CONFLICT (expression_a_id,expression_b_id) DO NOTHING", (left_id, right_id))
                        cur.execute("SELECT id,annotations_json FROM expression_edges WHERE expression_a_id=%s AND expression_b_id=%s", (left_id, right_id))
                        edge_id, existing = cur.fetchone()
                        annotations = existing if isinstance(existing, list) else json.loads(existing or "[]")
                        annotations = [
                            item for item in annotations
                            if not isinstance(item, dict) or item.get("source_key") != source_key
                        ]
                        annotations.extend({"source_key": source_key, "source_marker": row.entry_id, "text": note} for note in row.notes)
                        cur.execute("UPDATE expression_edges SET annotations_json=%s WHERE id=%s", (json.dumps(annotations, ensure_ascii=False, sort_keys=True), edge_id))
                        cur.execute("INSERT INTO expression_edge_sources(edge_id,source_id,source_marker) VALUES (%s,%s,%s) ON CONFLICT DO NOTHING", (edge_id, source_id, row.entry_id))
            _refresh_statistics(cur, affected_language_ids)
    return summary


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", required=True, type=Path)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--check", action="store_true")
    action.add_argument("--apply", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.apply and not os.environ.get("DATABASE_URL"):
            raise CsvContractError("DATABASE_URL is required for --apply")
        summary = validate(args.manifest) if args.check else apply(args.manifest, os.environ["DATABASE_URL"])
        print(json.dumps(summary, ensure_ascii=False, sort_keys=True))
        return 0
    except (CsvContractError, OSError, RuntimeError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
