#!/usr/bin/env python3
"""同步 Glottolog 與 IANA，產生 LangMap 語言 registry 資料。

`languoids.csv` 一列對應一個 Glottolog identity。BCP 47 的 script、region、
variant 組合另寫入 `language-profiles.csv`，因為它們不是新的 languoid；
而每個 variety（語言本體）寫入 `language-varieties.csv`。

使用明確的 seed profiles（language_seed_profiles.json）定義要產生的 BCP 47
language tag，取代舊版的笛卡兒積展開。Seed JSON 採兩層結構：
`varieties[*].profiles[*]`，每個 variety 自帶一組 profile。
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shutil
import sys
import urllib.request
import zipfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Iterator

from glottolog_import import Languoid, read_languoids

IANA_URL = "https://www.iana.org/assignments/language-subtag-registry"
GLOTTOLOG_5_3_URL = (
    "https://cdstar.eva.mpg.de/bitstreams/"
    "EAEA0-608B-9919-A962-0/glottolog_languoid.csv.zip"
)
USER_AGENT = "LangMap language registry sync/1.0"
DEFAULT_PROFILES = Path(__file__).with_name("language_seed_profiles.json")


@dataclass(frozen=True)
class Subtag:
    type: str
    value: str
    descriptions: tuple[str, ...]
    prefixes: tuple[str, ...]
    preferred_value: str | None
    suppress_script: str | None
    deprecated: str | None


def download(url: str, target: Path) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    digest = hashlib.sha256()
    temporary = target.with_suffix(target.suffix + ".tmp")
    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        with urllib.request.urlopen(request, timeout=60) as response, temporary.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                digest.update(chunk)
                output.write(chunk)
        temporary.replace(target)
    except Exception:
        temporary.unlink(missing_ok=True)
        raise
    return digest.hexdigest()


def parse_iana_registry(text: str) -> tuple[str, list[Subtag]]:
    sections = re.split(r"\r?\n%%\r?\n", text.strip())
    header = _parse_record(sections[0])
    file_date = _one(header, "File-Date")
    if not file_date:
        raise ValueError("IANA registry 缺少 File-Date")

    result: list[Subtag] = []
    for raw in sections[1:]:
        record = _parse_record(raw)
        kind = _one(record, "Type")
        value = _one(record, "Subtag") or _one(record, "Tag")
        if not kind or not value:
            raise ValueError("IANA registry record 缺少 Type/Subtag")
        result.append(
            Subtag(
                type=kind,
                value=value,
                descriptions=tuple(record.get("Description", [])),
                prefixes=tuple(record.get("Prefix", [])),
                preferred_value=_one(record, "Preferred-Value"),
                suppress_script=_one(record, "Suppress-Script"),
                deprecated=_one(record, "Deprecated"),
            )
        )
    return file_date, sorted(result, key=lambda item: (item.type, item.value.lower()))


def _parse_record(raw: str) -> dict[str, list[str]]:
    record: dict[str, list[str]] = {}
    current: str | None = None
    for line in raw.splitlines():
        if line.startswith(" ") and current:
            record[current][-1] += line[1:]
            continue
        if ":" not in line:
            continue
        current, value = line.split(":", 1)
        record.setdefault(current, []).append(value.strip())
    return record


def _one(record: dict[str, list[str]], key: str) -> str | None:
    values = record.get(key)
    return values[0] if values else None


def extract_glottolog_csv(archive: Path, target: Path) -> None:
    with zipfile.ZipFile(archive) as bundle:
        candidates = [
            name for name in bundle.namelist()
            if Path(name).name in {"languoid.csv", "languoids.csv"}
            or Path(name).name.endswith("_languoid.csv")
        ]
        if len(candidates) != 1:
            raise ValueError(f"Glottolog archive 中應有一個 languoid CSV，實際為 {candidates}")
        target.parent.mkdir(parents=True, exist_ok=True)
        with bundle.open(candidates[0]) as source, target.open("wb") as output:
            shutil.copyfileobj(source, output)


LANGUOID_FIELDS = (
    "id", "glottocode", "preferred_name", "level", "iso639_3", "parent_id",
    "latitude", "longitude", "status", "source_version",
)


def write_languoids(path: Path, rows: Iterable[Languoid]) -> int:
    count = 0
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=LANGUOID_FIELDS)
        writer.writeheader()
        for row in rows:
            value = asdict(row)
            value["status"] = "active"
            writer.writerow(value)
            count += 1
    return count


def write_subtags(path: Path, file_date: str, rows: Iterable[Subtag]) -> int:
    values = [asdict(row) for row in rows]
    path.write_text(
        json.dumps({"file_date": file_date, "subtags": values}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return len(values)


def canonical_case(parts: Iterable[str]) -> str:
    result: list[str] = []
    for index, part in enumerate(parts):
        if index == 0:
            result.append(part.lower())
        elif len(part) == 4 and part.isalpha():
            result.append(part.title())
        elif len(part) == 2 and part.isalpha():
            result.append(part.upper())
        else:
            result.append(part.lower())
    return "-".join(result)


def sql_literal(value: object) -> str:
    """Escape a value for safe inclusion in a SQL literal."""
    if value is None:
        return "NULL"
    text = str(value).replace("'", "''")
    return f"'{text}'"


# ---------------------------------------------------------------------------
# Seed-based language row generation
# ---------------------------------------------------------------------------

def canonical_seed_code(
    value: str,
    registered: dict[tuple[str, str], Subtag],
) -> str:
    """Validate a canonical seed code against IANA and return canonical casing.

    Accepts public BCP 47 tags and system private-use codes (x-emoji, x-image).
    Raises ValueError for invalid or unregistered tags.
    """
    if value in ("x-emoji", "x-image"):
        return value
    parts = value.split("-")
    if len(parts) < 1 or not parts[0]:
        raise ValueError(f"seed code must start with a language subtag: {value}")
    lang = parts[0].lower()
    if ("language", lang) not in registered:
        raise ValueError(f"seed code uses unregistered language subtag: {value}")
    private_index = next(
        (i for i, p in enumerate(parts) if p.lower() == "x"), len(parts)
    )
    public = parts[1:private_index]
    script_positions = [i for i, p in enumerate(public) if len(p) == 4 and p.isalpha()]
    region_positions = [
        i for i, p in enumerate(public)
        if (len(p) == 2 and p.isalpha()) or (len(p) == 3 and p.isdigit())
    ]
    if script_positions and region_positions and script_positions[0] > region_positions[0]:
        raise ValueError(f"seed code is not canonical BCP 47 order: {value}")
    for p in public:
        pl = p.lower()
        if len(p) == 4 and p.isalpha():
            if ("script", pl) not in registered:
                raise ValueError(f"seed code uses unregistered script: {p}")
        elif (len(p) == 2 and p.isalpha()) or (len(p) == 3 and p.isdigit()):
            if ("region", pl) not in registered:
                raise ValueError(f"seed code uses unregistered region: {p}")
        elif len(p) <= 8 and all(c.isalnum() for c in p):
            pass
        else:
            raise ValueError(f"seed code contains invalid public subtag: {p}")
    return canonical_case(parts)


def split_canonical_seed_code(value: str) -> dict[str, object]:
    """Parse a canonical seed code into its BCP 47 components."""
    if value in ("x-emoji", "x-image"):
        return {
            "language": "x",
            "script": None,
            "region": None,
            "variants": [],
            "private_use": [value],
        }
    parts = value.split("-")
    language = parts[0]
    private_index = next(
        (i for i, p in enumerate(parts) if p.lower() == "x"), len(parts)
    )
    public = parts[1:private_index]
    private_use = parts[private_index + 1:] if private_index < len(parts) else []
    script = None
    region = None
    variants: list[str] = []
    for p in public:
        if len(p) == 4 and p.isalpha():
            script = p
        elif (len(p) == 2 and p.isalpha()) or (len(p) == 3 and p.isdigit()):
            region = p
        else:
            variants.append(p)
    return {
        "language": language,
        "script": script,
        "region": region,
        "variants": variants,
        "private_use": private_use,
    }


# Script families that use right-to-left text direction.
_RTL_SCRIPT_FAMILIES = frozenset({
    "Arab", "Hebr", "Thaa", "Syrc", "Nkoo", "Rohg", "Adlm",
})


def direction_for_script(script: str | None) -> str:
    """Return 'rtl' for Arab-family scripts, 'ltr' otherwise."""
    if script is None:
        return "ltr"
    for family in _RTL_SCRIPT_FAMILIES:
        if script == family or script.startswith(family):
            return "rtl"
    return "ltr"


def seed_variety_rows(
    profiles: dict,
    subtags: list[Subtag],
    languoids_by_code: dict[str, Languoid],
) -> Iterator[dict[str, str]]:
    """Yield language_variety rows from explicit seed entries in the profiles JSON."""
    seen: set[str] = set()
    for entry in sorted(profiles["varieties"], key=lambda row: row["code"]):
        code = entry["code"]
        if code in seen:
            raise ValueError(f"duplicate variety code: {code}")
        seen.add(code)
        glottocode = entry.get("glottocode")
        languoid = languoids_by_code.get(glottocode) if glottocode else None
        if glottocode and languoid is None:
            raise ValueError(f"unknown Glottocode: {glottocode}")
        yield {
            "id": entry["id"],
            "code": code,
            "name": entry["name"],
            "name_en": entry.get("name_en") or "",
            "description": entry.get("description") or "",
            "glottocode": glottocode or "",
            "origin": entry["origin"],
            "community_reason": entry.get("reason") or "",
            "alternate_names_json": json.dumps(
                entry.get("alternate_names") or [], ensure_ascii=False, separators=(",", ":")
            ),
            "references_json": "[]",
            "parent_languoid_id": languoid.parent_id if languoid else "",
        }


def seed_profile_rows(
    profiles: dict,
    subtags: list[Subtag],
    variety_code_to_id: dict[str, str],
) -> Iterator[dict[str, str]]:
    """Yield language_profile rows for each (variety, profile) pair in the seed JSON.

    `variety_code_to_id` maps the seed variety code to its variety id so each
    profile row can carry the required `language_variety_id` foreign key.
    """
    registered = {
        (row.type, row.value.lower()): row
        for row in subtags
        if not row.deprecated
    }
    seen: set[str] = set()
    for variety in sorted(profiles["varieties"], key=lambda row: row["code"]):
        variety_id = variety_code_to_id.get(variety["code"])
        if variety_id is None:
            raise ValueError(f"unknown variety code: {variety['code']}")
        for profile in sorted(variety["profiles"], key=lambda row: row["code"]):
            code = canonical_seed_code(profile["code"], registered)
            if code in seen:
                raise ValueError(f"duplicate seed profile code: {code}")
            seen.add(code)
            parts = split_canonical_seed_code(code)
            yield {
                "code": code,
                "language_variety_id": variety_id,
                "name": profile["name"],
                "name_en": profile.get("name_en") or "",
                "endonym": profile.get("endonym") or "",
                "direction": direction_for_script(parts["script"]),
                "base_language": parts["language"],
                "script_code": parts["script"] or "",
                "region_code": parts["region"] or "",
                "variants_json": json.dumps(parts["variants"], separators=(",", ":")),
                "private_use_json": json.dumps(parts["private_use"], separators=(",", ":")),
            }


LOCATION_FIELDS = (
    "language_variety_id", "city_name", "city_name_en", "territory_code", "script_code",
    "latitude", "longitude", "reference",
)


def seed_location_rows(
    profiles: dict,
    variety_code_to_id: dict[str, str],
    subtags: list[Subtag],
) -> Iterator[dict[str, str]]:
    """Validate and yield representative city rows from seed profiles."""
    registered = {
        (row.type, row.value.upper() if row.type == "region" else row.value.title() if row.type == "script" else row.value.lower())
        for row in subtags if not row.deprecated
    }
    seen: set[tuple[str, str, str, str]] = set()
    locations = profiles.get("locations", [])
    if not isinstance(locations, list):
        raise ValueError("locations 必須是 JSON array")
    for entry in sorted(locations, key=lambda row: (
        row.get("variety_code", ""), row.get("city_name", ""),
        row.get("territory_code", ""), row.get("script_code", ""),
    )):
        if not isinstance(entry, dict):
            raise ValueError("location 必須是 JSON object")
        variety_code = entry.get("variety_code", "")
        city_name = str(entry.get("city_name", "")).strip()
        territory_code = str(entry.get("territory_code", "")).upper()
        script_code = str(entry.get("script_code", "")).title()
        reference = str(entry.get("reference", "")).strip()
        variety_id = variety_code_to_id.get(variety_code)
        if variety_id is None:
            raise ValueError(f"unknown variety_code: {variety_code}")
        if not city_name or not reference:
            raise ValueError("location city_name/reference 不可為空")
        if ("region", territory_code) not in registered:
            raise ValueError(f"location uses unregistered territory: {territory_code}")
        if script_code and ("script", script_code) not in registered:
            raise ValueError(f"location uses unregistered script: {script_code}")
        try:
            latitude = float(entry["latitude"])
            longitude = float(entry["longitude"])
        except (KeyError, TypeError, ValueError) as exc:
            raise ValueError("location latitude/longitude 必須是數字") from exc
        if not -90 <= latitude <= 90 or not -180 <= longitude <= 180:
            raise ValueError("location latitude/longitude 超出範圍")
        key = (variety_id, city_name, territory_code, script_code)
        if key in seen:
            raise ValueError(f"duplicate location: {key}")
        seen.add(key)
        yield {
            "language_variety_id": variety_id,
            "city_name": city_name,
            "city_name_en": str(entry.get("city_name_en", "")).strip(),
            "territory_code": territory_code,
            "script_code": script_code,
            "latitude": str(latitude),
            "longitude": str(longitude),
            "reference": reference,
        }


def read_profiles(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("language profile 必須是 JSON object")
    return value


VARIETY_FIELDS = (
    "id", "code", "name", "name_en", "description", "glottocode",
    "origin", "community_reason", "alternate_names_json", "references_json",
    "parent_languoid_id",
)

PROFILE_FIELDS = (
    "code", "language_variety_id", "name", "name_en", "endonym", "direction",
    "base_language", "script_code", "region_code", "variants_json",
    "private_use_json",
)


def write_varieties(path: Path, rows: Iterable[dict[str, str]]) -> int:
    values = sorted(rows, key=lambda row: row["code"].casefold())
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=VARIETY_FIELDS, lineterminator="\n")
        writer.writeheader()
        for row in values:
            writer.writerow(row)
    return len(values)


def write_profiles(path: Path, rows: Iterable[dict[str, str]]) -> int:
    values = sorted(rows, key=lambda row: row["code"].casefold())
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=PROFILE_FIELDS, lineterminator="\n")
        writer.writeheader()
        for row in values:
            writer.writerow(row)
    return len(values)


def write_locations(path: Path, rows: Iterable[dict[str, str]]) -> int:
    values = sorted(rows, key=lambda row: tuple(row[field].casefold() for field in LOCATION_FIELDS))
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=LOCATION_FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(values)
    return len(values)


# ---------------------------------------------------------------------------
# SQL generation
# ---------------------------------------------------------------------------

def render_languoid_insert(row: Languoid) -> str:
    """Return an idempotent INSERT statement for one languoid row."""
    cols = (
        "id", "glottocode", "preferred_name", "level", "iso639_3", "parent_id",
        "latitude", "longitude", "source_version",
    )
    vals = (
        sql_literal(row.id), sql_literal(row.glottocode),
        sql_literal(row.preferred_name), sql_literal(row.level),
        sql_literal(row.iso639_3) if row.iso639_3 else "NULL",
        sql_literal(row.parent_id) if row.parent_id else "NULL",
        str(row.latitude) if row.latitude is not None else "NULL",
        str(row.longitude) if row.longitude is not None else "NULL",
        sql_literal(row.source_version),
    )
    return (
        f"INSERT INTO languoids ({', '.join(cols)}) VALUES ({', '.join(vals)}) "
        "ON CONFLICT(id) DO UPDATE SET glottocode=excluded.glottocode, "
        "preferred_name=excluded.preferred_name, level=excluded.level, "
        "iso639_3=excluded.iso639_3, parent_id=excluded.parent_id, "
        "latitude=excluded.latitude, longitude=excluded.longitude, "
        "source_version=excluded.source_version;"
    )


def render_subtag_insert(row: Subtag) -> str:
    """Return an idempotent INSERT statement for one IANA subtag."""
    cols = (
        "type", "value", "descriptions", "prefixes",
        "preferred_value", "suppress_script", "deprecated",
    )
    vals = (
        sql_literal(row.type), sql_literal(row.value),
        sql_literal(json.dumps(list(row.descriptions), ensure_ascii=False)),
        sql_literal(json.dumps(list(row.prefixes), ensure_ascii=False)),
        sql_literal(row.preferred_value) if row.preferred_value else "NULL",
        sql_literal(row.suppress_script) if row.suppress_script else "NULL",
        sql_literal(row.deprecated) if row.deprecated else "NULL",
    )
    return (
        f"INSERT INTO language_subtags ({', '.join(cols)}) VALUES ({', '.join(vals)}) "
        "ON CONFLICT(type, value) DO UPDATE SET "
        "descriptions=excluded.descriptions, prefixes=excluded.prefixes, "
        "preferred_value=excluded.preferred_value, "
        "suppress_script=excluded.suppress_script, deprecated=excluded.deprecated;"
    )


def render_variety_insert(row: dict[str, str]) -> str:
    """Return an idempotent INSERT statement for one language_varieties row."""
    cols = VARIETY_FIELDS
    vals = (
        sql_literal(row["id"]), sql_literal(row["code"]),
        sql_literal(row["name"]), sql_literal(row["name_en"]),
        sql_literal(row["description"]),
        sql_literal(row["glottocode"]) if row["glottocode"] else "NULL",
        sql_literal(row["origin"]), sql_literal(row["community_reason"]),
        sql_literal(row["alternate_names_json"]), sql_literal(row["references_json"]),
        sql_literal(row["parent_languoid_id"]) if row["parent_languoid_id"] else "NULL",
    )
    return (
        f"INSERT INTO language_varieties ({', '.join(cols)}) VALUES ({', '.join(vals)}) "
        "ON CONFLICT(code) DO UPDATE SET "
        "name=excluded.name, name_en=excluded.name_en, "
        "description=excluded.description, glottocode=excluded.glottocode, "
        "origin=excluded.origin, community_reason=excluded.community_reason, "
        "alternate_names_json=excluded.alternate_names_json, "
        "references_json=excluded.references_json, "
        "parent_languoid_id=excluded.parent_languoid_id;"
    )


def render_profile_insert(row: dict[str, str]) -> str:
    """Return an idempotent INSERT statement for one language_profiles row."""
    cols = PROFILE_FIELDS
    vals = (
        sql_literal(row["code"]), sql_literal(row["language_variety_id"]),
        sql_literal(row["name"]), sql_literal(row["name_en"]),
        sql_literal(row["endonym"]),
        sql_literal(row["direction"]), sql_literal(row["base_language"]),
        sql_literal(row["script_code"]), sql_literal(row["region_code"]),
        sql_literal(row["variants_json"]), sql_literal(row["private_use_json"]),
    )
    return (
        f"INSERT INTO language_profiles ({', '.join(cols)}) VALUES ({', '.join(vals)}) "
        "ON CONFLICT(code) DO UPDATE SET "
        "language_variety_id=excluded.language_variety_id, "
        "name=excluded.name, name_en=excluded.name_en, endonym=excluded.endonym, "
        "direction=excluded.direction, base_language=excluded.base_language, "
        "script_code=excluded.script_code, region_code=excluded.region_code, "
        "variants_json=excluded.variants_json, "
        "private_use_json=excluded.private_use_json;"
    )


def render_location_insert(row: dict[str, str]) -> str:
    cols = ", ".join(LOCATION_FIELDS)
    vals = ", ".join(sql_literal(row[field]) for field in LOCATION_FIELDS)
    return (
        f"INSERT INTO language_locations ({cols}) VALUES ({vals}) "
        "ON CONFLICT(language_variety_id, city_name, territory_code, script_code) DO UPDATE SET "
        "city_name_en=excluded.city_name_en, latitude=excluded.latitude, "
        "longitude=excluded.longitude, reference=excluded.reference;"
    )


def render_registry_sql(
    languoids: list[Languoid],
    subtags: list[Subtag],
    varieties: list[dict[str, str]],
    profiles: list[dict[str, str]],
    locations: list[dict[str, str]] | None = None,
) -> str:
    """Generate a complete, idempotent SQL script for the language registry."""
    statements = []
    statements.extend(render_languoid_insert(row) for row in languoids)
    statements.extend(
        render_subtag_insert(row)
        for row in sorted(subtags, key=lambda row: (row.type, row.value.lower()))
    )
    statements.extend(
        render_variety_insert(row)
        for row in sorted(varieties, key=lambda row: row["code"])
    )
    statements.extend(
        render_profile_insert(row)
        for row in sorted(profiles, key=lambda row: row["code"])
    )
    statements.extend(
        render_location_insert(row)
        for row in sorted(locations or [], key=lambda row: tuple(row[field] for field in LOCATION_FIELDS))
    )
    return "\n".join(statements) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--glottolog-version", default="5.3")
    parser.add_argument("--glottolog-url", default=GLOTTOLOG_5_3_URL)
    parser.add_argument("--iana-url", default=IANA_URL)
    parser.add_argument("--offline", action="store_true", help="只使用 output/raw 內已下載的檔案")
    parser.add_argument("--profiles", type=Path, default=DEFAULT_PROFILES)
    parser.add_argument("--max-tags", type=int, default=100_000)
    args = parser.parse_args(argv)
    if args.max_tags < 1:
        parser.error("--max-tags 必須大於 0")

    raw = args.output / "raw"
    glottolog_zip = raw / f"glottolog-{args.glottolog_version}-languoids.zip"
    iana_registry = raw / "language-subtag-registry.txt"
    try:
        if not args.offline:
            glottolog_sha = download(args.glottolog_url, glottolog_zip)
            iana_sha = download(args.iana_url, iana_registry)
        else:
            glottolog_sha = hashlib.sha256(glottolog_zip.read_bytes()).hexdigest()
            iana_sha = hashlib.sha256(iana_registry.read_bytes()).hexdigest()

        extracted = raw / "glottolog-languoids.csv"
        extract_glottolog_csv(glottolog_zip, extracted)
        languoids = read_languoids(extracted, args.glottolog_version)
        file_date, subtags = parse_iana_registry(iana_registry.read_text(encoding="utf-8"))
        profiles = read_profiles(args.profiles)
        args.output.mkdir(parents=True, exist_ok=True)
        languoid_count = write_languoids(args.output / "languoids.csv", languoids)
        subtag_count = write_subtags(args.output / "iana-subtags.json", file_date, subtags)
        languoids_by_code = {row.glottocode: row for row in languoids}
        variety_rows = list(seed_variety_rows(profiles, subtags, languoids_by_code))
        variety_code_to_id = {row["code"]: row["id"] for row in variety_rows}
        profile_rows = list(seed_profile_rows(profiles, subtags, variety_code_to_id))
        location_rows = list(seed_location_rows(profiles, variety_code_to_id, subtags))
        write_varieties(args.output / "language-varieties.csv", variety_rows)
        write_profiles(args.output / "language-profiles.csv", profile_rows)
        location_count = write_locations(
            args.output / "language-locations.csv", location_rows
        )
        migration_path = args.output / "online-code-migrations.json"
        migration_manifest = profiles.get("online_code_migrations")
        if migration_manifest is None and migration_path.exists():
            migration_manifest = json.loads(migration_path.read_text(encoding="utf-8"))
        if migration_manifest is None:
            migration_manifest = {"mappings": {}}
        migration_path.write_text(
            json.dumps(migration_manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        manifest = {
            "glottolog": {
                "version": args.glottolog_version,
                "url": args.glottolog_url,
                "sha256": glottolog_sha,
                "languoid_count": languoid_count,
            },
            "iana": {
                "file_date": file_date,
                "url": args.iana_url,
                "sha256": iana_sha,
                "subtag_count": subtag_count,
            },
            "generation": {
                "profile_version": profiles.get("version"),
                "profile_file": args.profiles.name,
                "variety_count": len(variety_rows),
                "profile_count": len(profile_rows),
                "language_location_count": location_count,
            },
        }
        (args.output / "manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        sql_path = args.output / "language-registry.sql"
        sql_path.write_text(
            render_registry_sql(
                languoids, subtags, variety_rows, profile_rows, location_rows
            ),
            encoding="utf-8",
        )
        print(json.dumps(manifest, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        print(f"language-registry-sync: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
