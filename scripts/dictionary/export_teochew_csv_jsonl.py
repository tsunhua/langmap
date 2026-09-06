#!/usr/bin/env python3
"""Convert the consolidated Hokkien-writing Teochew CSV to JSONL v2.

The wide CSV contains several independent source dictionaries.  This exporter
keeps one JSONL artifact per ``source`` value so a production release can be
owned and verified source by source.  Source profiles also decide whether the
romanized and written expressions are Chaozhou or Swatow.  Values are copied
after whitespace trimming and Unicode NFC normalization; their casing is not
changed.

The ``puj`` or ``dp`` value is the headword.  The other selected columns are
entry-level mappings: ``han`` is the dialect's written form, ``en`` is English,
and ``zh_TW``/``zh_CN`` are Traditional/Simplified Mandarin translations.
``latn_norm`` and ``han_variants`` are intentionally not imported.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import tempfile
import unicodedata
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping


CHAOZHOU_HAN_LOCALE = "nan-Hant-CN_Chaozhou"
SWATOW_HAN_LOCALE = "nan-Hant-CN_Swatow"
CHAOZHOU_PUJ_LOCALE = "nan-Latn-CN_Chaozhou"
CHAOZHOU_DP_LOCALE = "nan-Latn-CN_Chaozhou_DP"
SWATOW_PUJ_LOCALE = "nan-Latn-CN_Swatow"
SWATOW_DP_LOCALE = "nan-Latn-CN_Swatow_DP"
MANDARIN_TRADITIONAL_LOCALE = "cmn-Hant-TW"
MANDARIN_SIMPLIFIED_LOCALE = "cmn-Hans-CN"
ENGLISH_LOCALE = "eng-Latn-US"

REQUIRED_COLUMNS = ("puj", "dp", "han", "en", "zh_TW", "zh_CN", "source")


@dataclass(frozen=True)
class SourceProfile:
    source_value: str
    source_key: str
    dialect: str
    locator_label: str

    @property
    def han_locale(self) -> str:
        return SWATOW_HAN_LOCALE if self.dialect == "swatow" else CHAOZHOU_HAN_LOCALE

    @property
    def puj_locale(self) -> str:
        return SWATOW_PUJ_LOCALE if self.dialect == "swatow" else CHAOZHOU_PUJ_LOCALE

    @property
    def dp_locale(self) -> str:
        return SWATOW_DP_LOCALE if self.dialect == "swatow" else CHAOZHOU_DP_LOCALE


# The empty source value is the SSMP export in the upstream merge pipeline.
# It is retained as a separate source key while using the Swatow profile named
# by the book title, "The Swatow Syllabary with Mandarin Pronunciations".
SOURCE_PROFILES: Mapping[str, SourceProfile] = {
    "": SourceProfile(
        "",
        "org.hokkien-writing.ssmp",
        "swatow",
        "ssmp (source column empty)",
    ),
    "001_Handbook_of_the_Swatow_Vernacular": SourceProfile(
        "001_Handbook_of_the_Swatow_Vernacular",
        "org.hokkien-writing.001-handbook-of-the-swatow-vernacular",
        "swatow",
        "001_Handbook_of_the_Swatow_Vernacular",
    ),
    "002_English-Chinese_Vocabulary_of_the_Vernacular_Or_Spoken_Language_of_Swatow": SourceProfile(
        "002_English-Chinese_Vocabulary_of_the_Vernacular_Or_Spoken_Language_of_Swatow",
        "org.hokkien-writing.002-english-chinese-vocabulary-of-the-vernacular-or-spoken-language-of-swatow",
        "swatow",
        "002_English-Chinese_Vocabulary_of_the_Vernacular_Or_Spoken_Language_of_Swatow",
    ),
    "003_First_Lessons_in_the_Tie-chiw_Dialect": SourceProfile(
        "003_First_Lessons_in_the_Tie-chiw_Dialect",
        "org.hokkien-writing.003-first-lessons-in-the-tie-chiw-dialect",
        "chaozhou",
        "003_First_Lessons_in_the_Tie-chiw_Dialect",
    ),
    "007_A_Pronouncing_and_Defining_Dictionary_of_the_Swatow_Dialect": SourceProfile(
        "007_A_Pronouncing_and_Defining_Dictionary_of_the_Swatow_Dialect",
        "org.hokkien-writing.007-a-pronouncing-and-defining-dictionary-of-the-swatow-dialect",
        "swatow",
        "007_A_Pronouncing_and_Defining_Dictionary_of_the_Swatow_Dialect",
    ),
    "008_A_Chinese_and_English_Vocabulary_in_the_Tie-chiu_Dialect": SourceProfile(
        "008_A_Chinese_and_English_Vocabulary_in_the_Tie-chiu_Dialect",
        "org.hokkien-writing.008-a-chinese-and-english-vocabulary-in-the-tie-chiu-dialect",
        "chaozhou",
        "008_A_Chinese_and_English_Vocabulary_in_the_Tie-chiu_Dialect",
    ),
    "dieghv": SourceProfile(
        "dieghv",
        "org.hokkien-writing.dieghv",
        "chaozhou",
        "dieghv",
    ),
    "teochew": SourceProfile(
        "teochew",
        "org.hokkien-writing.teochew",
        "chaozhou",
        "teochew",
    ),
    "teochew.chars": SourceProfile(
        "teochew.chars",
        "org.hokkien-writing.teochew-chars",
        "chaozhou",
        "teochew.chars",
    ),
    "teochew.khau_sek": SourceProfile(
        "teochew.khau_sek",
        "org.hokkien-writing.teochew-khau-sek",
        "chaozhou",
        "teochew.khau_sek",
    ),
}

_SAFE_FILENAME = re.compile(r"[^A-Za-z0-9._-]+")


@dataclass(frozen=True)
class ExportSummary:
    input_path: Path
    output_dir: Path
    input_sha256: str
    files: tuple[dict[str, Any], ...]

    @property
    def entry_count(self) -> int:
        return sum(int(item["entry_count"]) for item in self.files)


def _clean(value: Any) -> str:
    return unicodedata.normalize("NFC", str(value or "").strip())


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


def _profile_for(source: str) -> SourceProfile:
    try:
        return SOURCE_PROFILES[source]
    except KeyError as error:
        known = ", ".join(repr(value) for value in sorted(SOURCE_PROFILES))
        raise ValueError(f"unknown source {source!r}; expected one of {known}") from error


def _mapping_values(
    row: Mapping[str, str],
    profile: SourceProfile,
    headword_column: str,
) -> list[dict[str, str]]:
    columns = (
        ("puj", profile.puj_locale),
        ("dp", profile.dp_locale),
        ("han", profile.han_locale),
        ("en", ENGLISH_LOCALE),
        ("zh_TW", MANDARIN_TRADITIONAL_LOCALE),
        ("zh_CN", MANDARIN_SIMPLIFIED_LOCALE),
    )
    mappings: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for column, locale in columns:
        value = _clean(row.get(column))
        if not value or column == headword_column:
            continue
        key = (locale, value)
        if key in seen:
            continue
        seen.add(key)
        mappings.append({"value": value, "language_hint": locale, "source_column": column})
    return mappings


def _record(
    profile: SourceProfile,
    csv_row_number: int,
    source_row_number: int,
    row: Mapping[str, str],
) -> dict[str, Any]:
    puj = _clean(row.get("puj"))
    dp = _clean(row.get("dp"))
    if puj:
        headword, headword_column, headword_locale = puj, "puj", profile.puj_locale
    elif dp:
        headword, headword_column, headword_locale = dp, "dp", profile.dp_locale
    else:
        raise ValueError(f"CSV row {csv_row_number}: both puj and dp are empty")

    entry_key = f"row-{source_row_number:06d}"
    locator = f"{profile.locator_label} > CSV row {csv_row_number}"
    record: dict[str, Any] = {
        "record_type": "entry",
        "schema_version": 2,
        "dictionary_key": profile.source_key,
        "entry_key": entry_key,
        "record_fingerprint": "",
        "csv_row_number": csv_row_number,
        "raw_headword": headword,
        "canonical_headword": headword,
        "homograph_marker": None,
        "direction_hint": f"{headword_locale}-to-eng",
        "native_locator": locator,
        "forms": [],
        "mappings": _mapping_values(row, profile, headword_column),
        "pronunciations": [],
        "senses": [{
            "sense_key": f"{entry_key}-s1",
            "ordinal": 1,
            "native_locator": locator,
            "definitions": [],
            "pos": [],
            "equivalents": [],
            "relations": [],
            "examples": [],
            "labels": [],
        }],
        "diagnostics": [],
    }
    fingerprint_payload = dict(record)
    fingerprint_payload.pop("record_fingerprint")
    record["record_fingerprint"] = hashlib.sha256(
        json.dumps(
            fingerprint_payload,
            ensure_ascii=False,
            sort_keys=True,
            separators=(",", ":"),
        ).encode("utf-8")
    ).hexdigest()
    return record


def _json_line(payload: object) -> bytes:
    return (
        json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
        + "\n"
    ).encode("utf-8")


def _filename(profile: SourceProfile) -> str:
    return _SAFE_FILENAME.sub("-", profile.source_key).strip("-") + ".jsonl"


def export_teochew_csv(
    input_path: Path,
    output_dir: Path,
    *,
    encoding: str = "utf-8-sig",
) -> ExportSummary:
    """Write one deterministic JSONL file per source and refuse overwrite."""

    input_path = Path(input_path)
    output_dir = Path(output_dir)
    if not input_path.is_file():
        raise FileNotFoundError(input_path)
    output_dir.mkdir(parents=True, exist_ok=True)

    input_sha256 = _file_sha256(input_path)
    source_counts: Counter[str] = Counter()
    for row in _rows(input_path, encoding):
        source_counts[_clean(row.get("source"))] += 1
    profiles = [_profile_for(source) for source in sorted(source_counts)]
    output_paths = [output_dir / _filename(profile) for profile in profiles]
    existing = [path for path in output_paths if path.exists()]
    if existing:
        raise FileExistsError(existing[0])

    summaries: list[dict[str, Any]] = []
    for profile in profiles:
        output_path = output_dir / _filename(profile)
        expected_count = source_counts[profile.source_value]
        temporary_name: str | None = None
        output_digest = hashlib.sha256()
        count = 0
        source_row_number = 0
        try:
            fd, temporary_name = tempfile.mkstemp(
                prefix=f".{output_path.name}.", suffix=".tmp", dir=output_dir
            )
            with os.fdopen(fd, "wb") as handle:
                header = {
                    "record_type": "dictionary",
                    "schema_version": 2,
                    "dictionary_key": profile.source_key,
                    "source_value": profile.source_value,
                    "source_profile": profile.dialect,
                    "input_file_name": input_path.name,
                    "input_sha256": input_sha256,
                    "entry_count": expected_count,
                    "exporter_version": "langmap-teochew-csv/1",
                }
                header_line = _json_line(header)
                handle.write(header_line)
                output_digest.update(header_line)
                for csv_row_number, row in enumerate(_rows(input_path, encoding), 2):
                    if _clean(row.get("source")) != profile.source_value:
                        continue
                    source_row_number += 1
                    line = _json_line(_record(profile, csv_row_number, source_row_number, row))
                    handle.write(line)
                    output_digest.update(line)
                    count += 1
                if count != expected_count:
                    raise ValueError(
                        f"source {profile.source_value!r}: entry count changed while reading"
                    )
                handle.flush()
                os.fsync(handle.fileno())
            os.replace(temporary_name, output_path)
            temporary_name = None
        finally:
            if temporary_name is not None:
                os.unlink(temporary_name)
        summaries.append({
            "output_path": str(output_path),
            "source_key": profile.source_key,
            "source_value": profile.source_value,
            "source_profile": profile.dialect,
            "entry_count": count,
            "output_sha256": output_digest.hexdigest(),
        })
    return ExportSummary(input_path, output_dir, input_sha256, tuple(summaries))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument("--encoding", default="utf-8-sig")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    summary = export_teochew_csv(args.input, args.output_dir, encoding=args.encoding)
    print(json.dumps({
        "input_path": str(summary.input_path),
        "input_sha256": summary.input_sha256,
        "output_dir": str(summary.output_dir),
        "entry_count": summary.entry_count,
        "files": list(summary.files),
    }, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
