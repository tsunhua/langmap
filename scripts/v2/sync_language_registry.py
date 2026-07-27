#!/usr/bin/env python3
"""同步 Glottolog 與 IANA，產生 LangMap 語言 registry 資料。

`languoids.csv` 一列對應一個 Glottolog identity。BCP 47 的 script、region、
variant 組合另寫入 `languages.csv`，因為它們不是新的 languoid。

預設輸出全部 languoid 的 base tag、IANA variant prefix，以及
language_profiles.json 明確列出的高價值 script/region 組合。它不生成無語義
依據的全球笛卡兒積。
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
DEFAULT_PROFILES = Path(__file__).with_name("language_profiles.json")


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


def _variant_tag(prefix: str, variant: str, script: str | None) -> str:
    parts = prefix.split("-")
    has_script = any(len(part) == 4 and part.isalpha() for part in parts[1:])
    if script and not has_script:
        parts.insert(1, script)
    return canonical_case([*parts, variant])


def language_rows(
    languoids: Iterable[Languoid],
    subtags: Iterable[Subtag],
    profiles: dict,
) -> Iterator[dict[str, str]]:
    languoid_list = list(languoids)
    by_id = {row.id: row for row in languoid_list}
    active = [row for row in subtags if not row.deprecated and not row.preferred_value]
    registered_scripts = {row.value for row in active if row.type == "script"}
    registered_regions = {row.value for row in active if row.type == "region"}
    variants = [row for row in active if row.type == "variant"]
    variant_scripts = profiles.get("variant_scripts", {})
    if not isinstance(variant_scripts, dict):
        raise ValueError("variant_scripts 必須是 JSON object")
    for variant, script in variant_scripts.items():
        if not isinstance(variant, str) or not isinstance(script, str):
            raise ValueError("variant_scripts 的 key/value 必須是字串")
        if script not in registered_scripts:
            raise ValueError(f"variant {variant} 使用未登記的 script: {script}")
    variant_tags = {
        _variant_tag(prefix, variant.value, variant_scripts.get(variant.value))
        for variant in variants
        for prefix in variant.prefixes
    }
    omitted_generated = profiles.get("omit_generated_codes", [])
    if not isinstance(omitted_generated, list) or not all(
        isinstance(code, str) for code in omitted_generated
    ):
        raise ValueError("omit_generated_codes 必須是字串陣列")
    variant_tags.difference_update(omitted_generated)
    by_iso = {
        row.iso639_3.lower(): row
        for row in languoid_list
        if row.iso639_3 and row.level in {"language", "dialect"}
    }
    primary_aliases = _iana_primary_aliases(active)
    configured_aliases = profiles.get("iso639_3_to_bcp47", {})
    if not isinstance(configured_aliases, dict):
        raise ValueError("iso639_3_to_bcp47 必須是 JSON object")
    primary_aliases.update(configured_aliases)
    by_content_base = {
        primary_aliases.get(iso, iso): languoid for iso, languoid in by_iso.items()
    }

    owners: dict[str, str] = {}
    languoid_profiles: list[tuple[str, str, Languoid]] = []
    for languoid in languoid_list:
        if languoid.level not in {"language", "dialect"}:
            continue
        iso = _nearest_iso(languoid, by_id)
        base = primary_aliases.get(iso, iso) if iso else "und"
        private = "" if languoid.iso639_3 else languoid.glottocode
        languoid_profiles.append((base.lower(), private, languoid))

    for base, private, languoid in sorted(
        languoid_profiles, key=lambda item: (item[0], item[1], item[2].id)
    ):
        chinese = profiles.get("chinese_priority", {})
        roots = chinese.get("glottolog_roots", [])
        if not isinstance(roots, list) or not all(isinstance(root, str) for root in roots):
            raise ValueError("chinese_priority.glottolog_roots 必須是字串陣列")
        is_sinitic = _descends_from(
            languoid, {f"glotto:{root}" for root in roots}, by_id
        )
        candidates = _profile_tags(
            base, private, profiles, registered_scripts, registered_regions, is_sinitic
        )
        for code in candidates:
            if code in owners:
                continue
            owners[code] = languoid.id
            parts = code.split("-")
            yield _language_row(code, languoid, parts)

    # Prefix 是 IANA 對 variant 有語義的官方提示；不把 variant 乘到所有語言。
    for tag in sorted(variant_tags):
        base = tag.split("-", 1)[0].lower()
        languoid = by_content_base.get(base)
        if not languoid or tag in owners:
            continue
        owners[tag] = languoid.id
        yield _language_row(tag, languoid, tag.split("-"))

    for required in _required_online_codes(profiles):
        tag = required["canonical"]
        expected_id = f"glotto:{required['glottocode']}"
        if tag in owners:
            if owners[tag] != expected_id:
                raise ValueError(
                    f"required online code {tag} 指向 {owners[tag]}，預期 {expected_id}"
                )
            continue
        languoid = by_id.get(expected_id)
        if not languoid:
            raise ValueError(f"required online code {tag} 缺少 {expected_id}")
        _validate_required_tag(tag, required["glottocode"], active)
        owners[tag] = languoid.id
        yield _language_row(tag, languoid, tag.split("-"))

    for row in _special_content_rows(profiles):
        code = row["code"]
        if code in owners:
            raise ValueError(f"special content code 與語言 tag 衝突: {code}")
        owners[code] = ""
        yield row


def _iana_primary_aliases(subtags: Iterable[Subtag]) -> dict[str, str]:
    """Derive ISO 639-3 → shortest BCP 47 primary tags from IANA descriptions."""
    languages = [row for row in subtags if row.type == "language"]
    short_by_description: dict[str, str] = {}
    for row in languages:
        if len(row.value) == 2:
            for description in row.descriptions:
                short_by_description.setdefault(description.casefold(), row.value.lower())
    aliases: dict[str, str] = {}
    for row in languages:
        if len(row.value) != 3:
            continue
        matches = {
            short_by_description[description.casefold()]
            for description in row.descriptions
            if description.casefold() in short_by_description
        }
        if len(matches) == 1:
            aliases[row.value.lower()] = matches.pop()
    return aliases


def _required_online_codes(profiles: dict) -> list[dict[str, str]]:
    rows = profiles.get("required_online_codes", [])
    if not isinstance(rows, list):
        raise ValueError("required_online_codes 必須是陣列")
    result: list[dict[str, str]] = []
    for row in rows:
        if (
            not isinstance(row, dict)
            or not all(isinstance(row.get(key), str) for key in ("observed", "canonical", "glottocode"))
        ):
            raise ValueError("required_online_codes 每項必須包含 observed/canonical/glottocode")
        result.append(row)
    return result


def _validate_required_tag(tag: str, glottocode: str, subtags: Iterable[Subtag]) -> None:
    parts = tag.split("-")
    registered = {
        (row.type, row.value.lower())
        for row in subtags
        if not row.deprecated and not row.preferred_value
    }
    if ("language", parts[0].lower()) not in registered:
        raise ValueError(f"required online code 使用未登記的 language: {tag}")
    private_index = next(
        (index for index, part in enumerate(parts) if part.lower() == "x"), len(parts)
    )
    public = parts[1:private_index]
    script_positions = [index for index, part in enumerate(public) if len(part) == 4 and part.isalpha()]
    region_positions = [
        index for index, part in enumerate(public)
        if (len(part) == 2 and part.isalpha()) or (len(part) == 3 and part.isdigit())
    ]
    if script_positions and region_positions and script_positions[0] > region_positions[0]:
        raise ValueError(f"required online code 不是 canonical BCP 47 次序: {tag}")
    if private_index < len(parts) and parts[private_index + 1:] != [glottocode]:
        raise ValueError(f"required online code private-use 與 Glottocode 不一致: {tag}")


def online_code_migrations(profiles: dict) -> dict[str, str]:
    return {
        row["observed"]: row["canonical"]
        for row in _required_online_codes(profiles)
        if row["observed"] != row["canonical"]
    }


def _special_content_rows(profiles: dict) -> list[dict[str, str]]:
    entries = profiles.get("special_content_codes", [])
    if not isinstance(entries, list):
        raise ValueError("special_content_codes 必須是陣列")
    rows: list[dict[str, str]] = []
    for entry in entries:
        if not isinstance(entry, dict):
            raise ValueError("special_content_codes 每項必須是 object")
        code = entry.get("code")
        if code not in {"x-emoji", "x-image"}:
            raise ValueError(f"不允許的 private-use-only content code: {code}")
        if not all(isinstance(entry.get(key), str) for key in ("name", "name_en", "direction")):
            raise ValueError(f"{code} 缺少 name/name_en/direction")
        rows.append({
            "code": code,
            "name": entry["name"],
            "name_en": entry["name_en"],
            "direction": entry["direction"],
            "is_active": "0",
            "region_code": "",
            "languoid_id": "",
            "base_language": "x",
            "script_code": "",
            "source_version": "langmap-special-1",
        })
    return rows


def _profile_tags(
    base: str,
    private: str,
    profiles: dict,
    registered_scripts: set[str],
    registered_regions: set[str],
    is_sinitic: bool,
) -> list[str]:
    suffix = ["x", private] if private else []
    chinese = profiles.get("chinese_priority", {})
    result = [canonical_case([base, *suffix])]
    required_scripts = _validated_profile_values(
        chinese.get("required_scripts", []), registered_scripts, "required script"
    )
    # A Glottocode-specific Sinitic dialect distinguishes writing systems,
    # but never inherits ancestor regions.
    if private:
        if is_sinitic:
            return [
                canonical_case([base, script, *suffix])
                for script in required_scripts
            ]
        return result
    combinations = chinese.get("combinations", {})
    if not isinstance(combinations, dict):
        raise ValueError("chinese_priority.combinations 必須是 JSON object")
    if base in combinations:
        # A configured expansion replaces its generic base; only leaf tags
        # are useful in the selectable content registry.
        result = []
        entries = combinations[base]
        if not isinstance(entries, list):
            raise ValueError(f"chinese combination {base} 必須是陣列")
        for entry in entries:
            if not isinstance(entry, dict) or not isinstance(entry.get("script"), str):
                raise ValueError(f"chinese combination {base} 缺少 script")
            script = _validated_profile_values(
                [entry["script"]], registered_scripts, "script"
            )[0]
            regions = _validated_profile_values(
                entry.get("regions", []), registered_regions, "region"
            )
            result.extend(
                canonical_case([base, script, region])
                for region in regions
            )
    elif is_sinitic:
        result = []
        result.extend(canonical_case([base, script]) for script in required_scripts)
    else:
        regions = _validated_profile_values(
            profiles.get("major_regions", {}).get(base, []),
            registered_regions,
            "region",
        )
        if regions:
            result = []
        result.extend(canonical_case([base, region, *suffix]) for region in regions)
    return result


def _validated_profile_values(
    values: object,
    registered: set[str],
    kind: str,
) -> list[str]:
    if not isinstance(values, list) or not all(isinstance(value, str) for value in values):
        raise ValueError(f"profile {kind} 必須是字串陣列")
    unknown = sorted(set(values) - registered)
    if unknown:
        raise ValueError(f"profile 含未登記的 {kind}: {', '.join(unknown)}")
    return values


def read_profiles(path: Path) -> dict:
    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError("language profile 必須是 JSON object")
    return value


def _nearest_iso(languoid: Languoid, by_id: dict[str, Languoid]) -> str | None:
    current = languoid
    seen: set[str] = set()
    while True:
        if current.iso639_3:
            return current.iso639_3
        if not current.parent_id or current.parent_id in seen:
            return None
        seen.add(current.id)
        current = by_id[current.parent_id]


def _descends_from(
    languoid: Languoid,
    roots: set[str],
    by_id: dict[str, Languoid],
) -> bool:
    current = languoid
    seen: set[str] = set()
    while True:
        if current.id in roots:
            return True
        if not current.parent_id or current.parent_id in seen:
            return False
        seen.add(current.id)
        current = by_id[current.parent_id]


def _language_row(code: str, languoid: Languoid, parts: list[str]) -> dict[str, str]:
    script = next((part for part in parts[1:] if len(part) == 4 and part.isalpha()), "")
    region = next(
        (part for part in parts[1:] if (len(part) == 2 and part.isalpha()) or
         (len(part) == 3 and part.isdigit())),
        "",
    )
    return {
        "code": code,
        "name": languoid.preferred_name,
        "name_en": languoid.preferred_name,
        "direction": "rtl" if script in {"Adlm", "Arab", "Hebr", "Nkoo", "Rohg", "Syrc", "Thaa"} else "ltr",
        "is_active": "0",
        "region_code": region,
        "languoid_id": languoid.id,
        "base_language": parts[0].lower(),
        "script_code": script,
        "source_version": languoid.source_version,
    }


LANGUAGE_FIELDS = (
    "code", "name", "name_en", "direction", "is_active", "region_code",
    "languoid_id", "base_language", "script_code", "source_version",
)


def write_languages(path: Path, rows: Iterable[dict[str, str]], max_tags: int) -> int:
    values = sorted(rows, key=lambda row: row["code"].casefold())
    count = len(values)
    if count > max_tags:
        raise ValueError(
            f"候選 tag 超過 --max-tags={max_tags}；未寫入 languages.csv"
        )
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=LANGUAGE_FIELDS)
        writer.writeheader()
        for row in values:
            writer.writerow(row)
    return count


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
        languages_path = args.output / "languages.csv"
        try:
            language_count = write_languages(
                languages_path,
                language_rows(languoids, subtags, profiles),
                args.max_tags,
            )
        except Exception:
            languages_path.unlink(missing_ok=True)
            raise
        migrations = online_code_migrations(profiles)
        (args.output / "online-code-migrations.json").write_text(
            json.dumps(migrations, ensure_ascii=False, indent=2) + "\n",
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
                "language_tag_count": language_count,
                "max_tags": args.max_tags,
                "required_online_code_count": len(_required_online_codes(profiles)),
                "online_code_migration_count": len(migrations),
            },
        }
        (args.output / "manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(json.dumps(manifest, ensure_ascii=False, indent=2))
        return 0
    except (OSError, ValueError, zipfile.BadZipFile) as exc:
        print(f"language-registry-sync: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
