#!/usr/bin/env python3
"""Generate the pinned ISO language-reference seed SQL + manifest.

Offline and deterministic: reads committed raw/ + overlays/, emits fixed-sorted
artifacts/language-reference.sql and artifacts/manifest.json. No network access.
"""
from __future__ import annotations

import csv
import hashlib
import json
import sys
import unicodedata
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
OVERLAYS = ROOT / "overlays"
ARTIFACTS = ROOT / "artifacts"

MIN_LANGUAGES = 7000
MIN_SCRIPTS = 100
MIN_REGIONS = 200

# Canonical locales used by the application and dictionary adapters. Their
# integer IDs are allocated from this stable code order during fresh rebuild.
REFERENCE_LOCALES = (
    ('cmn-Hans-CN', 'cmn', 'Hans', None, 'CN', '', '普通话', 'Simplified Chinese'),
    ('cmn-Hant-TW', 'cmn', 'Hant', None, 'TW', '', '華語', 'Taiwan Mandarin'),
    ('eng-Latn-US', 'eng', 'Latn', None, 'US', '', 'English', 'English (US)'),
    ('eng-Latn-GB', 'eng', 'Latn', None, 'GB', '', 'English', 'English (UK)'),
    ('jpn-Jpan-JP', 'jpn', 'Jpan', None, 'JP', '', '日本語', 'Japanese (Japan)'),
    ('nan-Hant-CN', 'nan', 'Hant', None, 'CN', '', '閩南語', 'Min Nan Chinese'),
    ('nan-Hant-CN_Chaozhou', 'nan', 'Hant', None, 'CN', 'Chaozhou', '潮州話', 'Chaozhou Hokkien'),
    ('nan-Hant-CN_LufengJiazi', 'nan', 'Hant', None, 'CN', 'LufengJiazi', '陸豐甲子話', 'Lufeng Jiazi Hokkien'),
    ('nan-Latn-CN_LufengJiazi', 'nan', 'Latn', None, 'CN', 'LufengJiazi', '陸豐甲子話（拉丁字）', 'Lufeng Jiazi Hokkien (Latin)'),
    ('nan-Hant-TW', 'nan', 'Hant', None, 'TW', '', '台語', 'Taiwanese Hokkien'),
    ('spa-Latn-ES', 'spa', 'Latn', None, 'ES', '', 'Español', 'Spanish (Spain)'),
    ('ral-Latn-IN', 'ral', 'Latn', None, 'IN', '', 'Ralte', 'Ralte'),
    ('swh-Latn-TZ', 'swh', 'Latn', None, 'TZ', '', 'Kiswahili', 'Swahili'),
    ('wuu-Hans-CN_Wenzhou', 'wuu', 'Hans', None, 'CN', 'Wenzhou', '温州话', 'Wenzhou Wu'),
    ('wuu-Hant-CN_Taizhou', 'wuu', 'Hant', None, 'CN', 'Taizhou', '台州話', 'Taizhou Wu'),
    ('yue-Hant-HK', 'yue', 'Hant', None, 'HK', '', '粵語', 'Cantonese'),
    ('zyg-Latn-CN_Jingxi', 'zyg', 'Latn', None, 'CN', 'Jingxi', '靖西壮语', 'Jingxi Zhuang'),
)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def sql_str(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


BASE32_ALPHABET = "abcdefghijklmnopqrstuvwxyz234567"


def expression_text_hash(text: str) -> str:
    # Mirrors backend/src/services/expressionIdentity.ts:computeTextHash.
    normalized = unicodedata.normalize("NFC", text.strip())
    digest = hashlib.sha256(normalized.encode("utf-8")).digest()[:16]
    bits = "".join(f"{b:08b}" for b in digest)
    out: list[str] = []
    for i in range(0, len(bits), 5):
        out.append(BASE32_ALPHABET[int(bits[i : i + 5].ljust(5, "0"), 2)])
    return "".join(out)


def build_expression_id(lang_code: str, text_hash: str, homograph_index: int = 1) -> str:
    # Mirrors backend/src/services/expressionIdentity.ts:buildExpressionId.
    return f"{lang_code}:{text_hash}" if homograph_index == 1 else f"{lang_code}:{text_hash}.{homograph_index}"


def read_languages() -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    with (RAW / "iso639-3.tab").open(encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh, delimiter="\t"):
            if row.get("Scope") != "I":
                continue
            code = (row.get("Id") or "").strip().lower()
            name = (row.get("Ref_Name") or "").strip()
            if code and name:
                rows.append((code, name))
    rows.sort()
    return rows


def read_script_directions() -> dict[str, str]:
    data = json.loads((OVERLAYS / "script-directions.json").read_text(encoding="utf-8"))
    cleaned: dict[str, str] = {}
    for k, v in data.items():
        if v not in ("ltr", "rtl"):
            raise ValueError(f"invalid direction {v!r} for {k!r}")
        cleaned[k.strip()] = v
    return cleaned


def read_scripts(directions: dict[str, str]) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    with (RAW / "iso15924.txt").open(encoding="utf-8") as fh:
        for line in fh:
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            parts = [p.strip() for p in line.split(";")]
            if len(parts) < 3 or not parts[0] or not parts[2]:
                continue
            code, name = parts[0], parts[2]
            direction = directions.get(code)
            if direction is None:
                raise ValueError(f"script {code!r} missing curated direction overlay")
            rows.append((code, name, direction))
    rows.sort()
    return rows


def read_region_coords() -> dict[str, tuple[float | None, float | None]]:
    coords: dict[str, tuple[float | None, float | None]] = {}
    path = OVERLAYS / "region-coordinates.tsv"
    if not path.exists():
        return coords
    with path.open(encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh, delimiter="\t"):
            code = (row.get("code") or "").strip()
            if not code:
                continue
            lat = float(row["latitude"]) if row.get("latitude") else None
            lon = float(row["longitude"]) if row.get("longitude") else None
            if (lat is None) != (lon is None):
                raise ValueError(f"region {code!r} has unpaired coordinates")
            coords[code] = (lat, lon)
    return coords


def read_regions(coords: dict[str, tuple[float | None, float | None]]) -> list[tuple[str, str, float | None, float | None]]:
    rows: list[tuple[str, str, float | None, float | None]] = []
    with (RAW / "iso3166-1.tsv").open(encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh, delimiter="\t"):
            code = (row.get("code") or "").strip()
            name = (row.get("name_en") or "").strip()
            if not code or not name:
                continue
            lat, lon = coords.get(code, (None, None))
            rows.append((code, name, lat, lon))
    rows.sort()
    return rows


def read_name_canonical_texts() -> tuple[dict[str, str], dict[str, str]]:
    data = json.loads((OVERLAYS / "name-canonical-texts.json").read_text(encoding="utf-8"))
    overrides = {k.strip(): v.strip() for k, v in data.get("language_canonical_overrides", {}).items() if v}
    locales = {k.strip(): v.strip() for k, v in data.get("locale_canonical_texts", {}).items() if v}
    for code, text in locales.items():
        lang = code.split("-", 1)[0]
        if len(lang) != 3:
            raise ValueError(f"locale {code!r} has invalid lang prefix {lang!r}")
        if not text:
            raise ValueError(f"locale {code!r} missing canonical text")
    return overrides, locales


def read_name_translations() -> list[dict[str, str]]:
    data = json.loads((OVERLAYS / "name-translations.json").read_text(encoding="utf-8"))
    rows: list[dict[str, str]] = []
    seen: set[tuple[str, str]] = set()
    for t in data.get("translations", []):
        canonical = (t.get("canonical_text") or "").strip()
        locale = (t.get("target_locale") or "").strip()
        text = (t.get("text") or "").strip()
        if not canonical or not locale or not text:
            raise ValueError(f"incomplete translation row {t!r}")
        if (canonical, locale) in seen:
            raise ValueError(f"duplicate translation for {canonical!r} in {locale!r}")
        seen.add((canonical, locale))
        rows.append({"canonical_text": canonical, "target_locale": locale, "text": text})
    rows.sort(key=lambda r: (r["canonical_text"], r["target_locale"]))
    return rows


def read_script_region_zh_names() -> dict[str, dict[str, dict[str, str]]]:
    """Code-keyed zh script/region names from the CLDR-derived overlay.

    Curated entries in name-translations.json take precedence; this overlay
    only fills codes not already translated there.
    """
    data = json.loads((OVERLAYS / "script-region-zh-names.json").read_text(encoding="utf-8"))
    cleaned: dict[str, dict[str, dict[str, str]]] = {"scripts": {}, "regions": {}}
    for kind in ("scripts", "regions"):
        for code, texts in (data.get(kind) or {}).items():
            entries: dict[str, str] = {}
            for locale, text in (texts or {}).items():
                if locale not in ("cmn-Hans-CN", "cmn-Hant-TW") or not (text or "").strip():
                    raise ValueError(f"invalid zh name entry {code!r} in {kind}: {locale!r}={text!r}")
                entries[locale] = text.strip()
            if entries:
                cleaned[kind][code.strip()] = entries
    return cleaned


def merge_zh_overlay(
    translations: list[dict[str, str]],
    scripts: list[tuple[str, str, str]],
    regions: list[tuple[str, str, float | None, float | None]],
    overlay: dict[str, dict[str, dict[str, str]]],
) -> list[dict[str, str]]:
    covered = {(t["canonical_text"], t["target_locale"]) for t in translations}
    by_code: dict[str, dict[str, str]] = {
        "scripts": {c: n for c, n, _d in scripts},
        "regions": {c: n for c, n, _lat, _lon in regions},
    }
    merged = list(translations)
    for kind, code_entries in overlay.items():
        for code, texts in code_entries.items():
            canonical = by_code.get(kind, {}).get(code)
            if not canonical:
                raise ValueError(f"zh overlay references unknown {kind[:-1]} code {code!r}")
            for locale, text in texts.items():
                if (canonical, locale) in covered:
                    continue
                merged.append({"canonical_text": canonical, "target_locale": locale, "text": text})
    merged.sort(key=lambda r: (r["canonical_text"], r["target_locale"]))
    return merged


INSERT_BATCH = 500


def _insert_blocks(table: str, columns: list[str], value_rows: list[str]) -> list[str]:
    # D1/miniflare rejects oversized single statements (SQLITE_TOOBIG), so chunk
    # each table into multiple INSERT statements of at most INSERT_BATCH rows.
    cols = ", ".join(columns)
    out: list[str] = []
    for i in range(0, len(value_rows), INSERT_BATCH):
        chunk = value_rows[i:i + INSERT_BATCH]
        out.append(f"INSERT OR IGNORE INTO {table} ({cols}) VALUES")
        out.append(",\n".join(chunk) + ";")
    return out


def emit_name_seed_sql(
    languages: list[tuple[str, str]], scripts: list[tuple[str, str, str]],
    regions: list[tuple[str, str, float | None, float | None]],
    translations: list[dict[str, str]], language_ids: dict[str, int],
) -> tuple[list[str], dict[str, int]]:
    """Emit canonical name expressions, their translations, and direct edges.

    Names stay in the ordinary expression graph.  Registry tables only retain a
    numeric pointer to the English canonical expression; they never duplicate a
    localized label.
    """
    locale_names = [row[7] for row in REFERENCE_LOCALES]
    canonical_texts = sorted({name for _code, name in languages} | {name for _code, name, _direction in scripts} | {name for _code, name, _lat, _lon in regions} | set(locale_names))
    eng_id = language_ids['eng']
    lines = ['-- LOCALIZED NAME EXPRESSIONS AND DIRECT SEMANTIC EDGES']
    lines.append("INSERT OR IGNORE INTO sources (type, name) VALUES ('system', 'LangMap canonical names seed');")
    source_exprs = [f"  ({eng_id}, {sql_str(text)}, (SELECT id FROM sources WHERE type='system' AND name='LangMap canonical names seed'))" for text in canonical_texts]
    lines += _insert_blocks('expressions', ['language_id', 'text', 'source_id'], source_exprs)

    target_exprs: list[str] = []
    for item in translations:
        lang = item['target_locale'].split('-', 1)[0]
        target_exprs.append(f"  ({language_ids[lang]}, {sql_str(item['text'])}, (SELECT id FROM sources WHERE type='system' AND name='LangMap canonical names seed'))")
    lines += _insert_blocks('expressions', ['language_id', 'text', 'source_id'], target_exprs)

    for item in translations:
        locale = item['target_locale']; lang = locale.split('-', 1)[0]
        source = sql_str(item['canonical_text']); target = sql_str(item['text'])
        lines.append(
            "INSERT OR IGNORE INTO expression_edges (expression_a_id, expression_b_id, relation_mask, score) "
            f"SELECT min(src.id, tgt.id), max(src.id, tgt.id), 1, 0 FROM expressions src JOIN expressions tgt "
            f"WHERE src.language_id={eng_id} AND src.text={source} AND tgt.language_id={language_ids[lang]} AND tgt.text={target};"
        )
        lines.append(
            "INSERT OR IGNORE INTO expression_locale_links (expression_id, locale_id) "
            f"SELECT e.id, l.id FROM expressions e JOIN language_locales l ON l.code={sql_str(locale)} "
            f"WHERE e.language_id={language_ids[lang]} AND e.text={target};"
        )

    bindings = [
        "UPDATE languages SET name_expression_id=(SELECT e.id FROM expressions e WHERE e.language_id=%d AND e.text=languages.name_en LIMIT 1);" % eng_id,
        "UPDATE language_locales SET name_expression_id=(SELECT e.id FROM expressions e WHERE e.language_id=%d AND e.text=language_locales.name_en LIMIT 1);" % eng_id,
        "UPDATE scripts SET name_expression_id=(SELECT e.id FROM expressions e WHERE e.language_id=%d AND e.text=scripts.name_en LIMIT 1);" % eng_id,
        "UPDATE regions SET name_expression_id=(SELECT e.id FROM expressions e WHERE e.language_id=%d AND e.text=regions.name_en LIMIT 1);" % eng_id,
    ]
    lines.extend(bindings)
    return lines, {
        'name_canonical_expressions': len(canonical_texts),
        'name_target_expressions': len(target_exprs),
        'name_edges': len(translations),
        'name_attestations': len(translations),
    }


def emit_sql(
    languages: list[tuple[str, str]],
    scripts: list[tuple[str, str, str]],
    regions: list[tuple[str, str, float | None, float | None]],
    overrides: dict[str, str],
    locale_texts: dict[str, str],
    translations: list[dict[str, str]],
) -> tuple[str, dict[str, int]]:
    lines: list[str] = ["-- AUTO-GENERATED by scripts/language-reference/generate.py. Do not edit."]

    language_ids = {code: index for index, (code, _name) in enumerate(languages, start=1)}
    lang_vals = [f"  ({language_ids[c]}, {sql_str(c)}, {sql_str(n)})" for c, n in languages]
    lines += _insert_blocks("languages", ["id", "code", "name_en"], lang_vals)

    script_vals = [f"  ({sql_str(c)}, {sql_str(n)}, {sql_str(d)})" for c, n, d in scripts]
    lines += _insert_blocks("scripts", ["code", "name_en", "direction"], script_vals)

    region_vals: list[str] = []
    for c, n, lat, lon in regions:
        lat_s = "NULL" if lat is None else repr(lat)
        lon_s = "NULL" if lon is None else repr(lon)
        region_vals.append(f"  ({sql_str(c)}, {sql_str(n)}, {lat_s}, {lon_s})")
    lines += _insert_blocks("regions", ["code", "name_en", "latitude", "longitude"], region_vals)

    locale_rows = []
    for locale in sorted(REFERENCE_LOCALES):
        code, lang, script, orthography, region, place, name, name_en = locale
        if lang not in language_ids:
            raise ValueError(f"locale {code!r} references unknown language {lang!r}")
        locale_rows.append(
            f"  ({len(locale_rows) + 1}, {sql_str(code)}, {language_ids[lang]}, {sql_str(script)}, "
            f"{('NULL' if orthography is None else sql_str(orthography))}, {sql_str(region)}, "
            f"{sql_str(place)}, {sql_str(name)}, {sql_str(name_en)}, NULL, NULL)"
        )
    lines += _insert_blocks(
        "language_locales",
        ["id", "code", "language_id", "script_code", "orthography", "region_code", "place_path", "name", "name_en", "latitude", "longitude"],
        locale_rows,
    )

    name_lines, name_counts = emit_name_seed_sql(languages, scripts, regions, translations, language_ids)
    lines.extend(name_lines)

    name_counts['language_locales'] = len(locale_rows)

    return "\n".join(lines) + "\n", name_counts


def build_manifest(languages, scripts, regions, directions, region_coords, sql_text, locale_texts, translations, name_counts) -> dict:
    def src(name: str, path: Path, **extra) -> dict:
        payload = {
            "name": name,
            "path": str(path.relative_to(ROOT)),
            "sha256": sha256_file(path),
            "size": path.stat().st_size,
        }
        payload.update(extra)
        return payload

    return {
        "manifest_version": 1,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "sources": {
            "iso639-3": src("ISO 639-3 (individual scope)", RAW / "iso639-3.tab", license="FSFAP", source="Debian iso-codes (mirrors SIL)"),
            "iso15924": src("ISO 15924", RAW / "iso15924.txt", license="Unicode-DFS-2016", source="unicode.org"),
            "iso3166-1": src("ISO 3166-1 alpha-2", RAW / "iso3166-1.tsv", license="FSFAP", source="Debian iso-codes"),
        },
        "overlays": {
            "script_directions": {"path": "overlays/script-directions.json", "covered_scripts": len(directions)},
            "region_coordinates": {"path": "overlays/region-coordinates.tsv", "covered_regions": len(region_coords)},
            "name_canonical_texts": {"path": "overlays/name-canonical-texts.json", "locale_count": len(locale_texts)},
            "name_translations": {"path": "overlays/name-translations.json", "translation_count": len(translations)},
            "script_region_zh_names": {"path": "overlays/script-region-zh-names.json", "source": "Unicode CLDR cldr-localenames-full zh / zh-Hant", "translation_count": sum(len(v) for v in read_script_region_zh_names().values() for v in v.values())},
        },
        "counts": {
            "languages": len(languages),
            "scripts": len(scripts),
            "regions": len(regions),
            "language_locales": len(REFERENCE_LOCALES),
            **name_counts,
        },
        "artifacts": {
            "language_reference_sql": {
                "path": "language-reference.sql",
                "sha256": hashlib.sha256(sql_text.encode("utf-8")).hexdigest(),
            }
        },
    }


def main() -> int:
    directions = read_script_directions()
    region_coords = read_region_coords()
    languages = read_languages()
    scripts = read_scripts(directions)
    regions = read_regions(region_coords)
    overrides, locale_texts = read_name_canonical_texts()
    translations = merge_zh_overlay(read_name_translations(), scripts, regions, read_script_region_zh_names())

    if len(languages) < MIN_LANGUAGES:
        raise SystemExit(f"languages count {len(languages)} < {MIN_LANGUAGES}")
    if len(scripts) < MIN_SCRIPTS:
        raise SystemExit(f"scripts count {len(scripts)} < {MIN_SCRIPTS}")
    if len(regions) < MIN_REGIONS:
        raise SystemExit(f"regions count {len(regions)} < {MIN_REGIONS}")

    sql_text, name_counts = emit_sql(languages, scripts, regions, overrides, locale_texts, translations)
    manifest = build_manifest(languages, scripts, regions, directions, region_coords, sql_text, locale_texts, translations, name_counts)

    ARTIFACTS.mkdir(parents=True, exist_ok=True)
    (ARTIFACTS / "language-reference.sql").write_text(sql_text, encoding="utf-8")
    (ARTIFACTS / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {ARTIFACTS / 'language-reference.sql'} ({len(languages)} languages, {len(scripts)} scripts, {len(regions)} regions, "
          f"{name_counts['name_canonical_expressions']} canonical names, {name_counts['name_edges']} name edges)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
