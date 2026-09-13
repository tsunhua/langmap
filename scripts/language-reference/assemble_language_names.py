#!/usr/bin/env python3
"""Assemble code-keyed language names from pinned local source snapshots.

The generated overlay is intentionally separate from the canonical name seed:
the same English label can describe a language and a script, while an ISO
639-3 code remains an unambiguous key for a language name.  This script does
not fetch data or machine-translate unmatched languages.  It accepts local
CLDR, Debian iso-codes PO, and Wikidata exports, applies the curated rows first,
and records source coverage and provenance in the output JSON.

Example:

    python3 scripts/language-reference/assemble_language_names.py \
      --cldr-zh /path/to/zh/languages.json \
      --cldr-ja /path/to/ja/languages.json \
      --iso-zh-cn /path/to/zh_CN.po \
      --iso-zh-tw /path/to/zh_TW.po \
      --iso-ja /path/to/ja.po \
      --wikidata /path/to/wikidata.json

The command is offline and deterministic after its input snapshots have been
downloaded.  The normal generator only consumes the resulting overlay.
"""
from __future__ import annotations

import argparse
import ast
import csv
import hashlib
import json
import re
import sys
import unicodedata
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parent
RAW = ROOT / "raw"
DEFAULT_OUTPUT = ROOT / "overlays" / "language-name-translations.json"

TARGETS = {
    "cmn-Hans-CN": {
        "cldr_key": "cmn-Hans-CN",
        "wikidata_lang": "zh-hans",
        "po_key": "cmn-Hans-CN",
    },
    "cmn-Hant-TW": {
        "cldr_key": "cmn-Hant-TW",
        "wikidata_lang": "zh-hant",
        "po_key": "cmn-Hant-TW",
    },
    "jpn-Jpan-JP": {
        "cldr_key": "jpn-Jpan-JP",
        "wikidata_lang": "ja",
        "po_key": "jpn-Jpan-JP",
    },
}

# ISO 639-3 has no mandatory relationship to the two-letter keys used by
# CLDR.  Keep the small, stable aliases needed by the registry here; exact
# three-letter CLDR entries are still matched directly.
CLDR_ALIASES = {
    "arb": "ar",
    "cmn": "zh",
    "ell": "el",
    "eng": "en",
    "fra": "fr",
    "grc": "grc",
    "hak": "hak",
    "jpn": "ja",
    "kor": "ko",
    "nan": "nan",
    "rus": "ru",
    "spa": "es",
    "swh": "sw",
    "tha": "th",
    "wuu": "wuu",
    "yue": "yue",
}

# These are deliberately narrow, reviewable product choices for languages
# already visible in the application or whose external sources disagree.
# They also ensure that the first local rollout fixes the names the user can
# currently see on /languages.
CURATED = {
    "arb": {
        "cmn-Hans-CN": "标准阿拉伯语",
        "cmn-Hant-TW": "標準阿拉伯語",
        "jpn-Jpan-JP": "標準アラビア語",
    },
    "cmn": {
        "cmn-Hans-CN": "普通话",
        "cmn-Hant-TW": "華語",
        "jpn-Jpan-JP": "普通話",
    },
    "ell": {
        "cmn-Hans-CN": "现代希腊语",
        "cmn-Hant-TW": "現代希臘語",
        "jpn-Jpan-JP": "現代ギリシア語",
    },
    "eng": {
        "cmn-Hans-CN": "英语",
        "cmn-Hant-TW": "英語",
        "jpn-Jpan-JP": "英語",
    },
    "fra": {
        "cmn-Hans-CN": "法语",
        "cmn-Hant-TW": "法語",
        "jpn-Jpan-JP": "フランス語",
    },
    "hak": {
        "cmn-Hans-CN": "客家话",
        "cmn-Hant-TW": "客家話",
        "jpn-Jpan-JP": "客家語",
    },
    "jpn": {
        "cmn-Hans-CN": "日语",
        "cmn-Hant-TW": "日語",
        "jpn-Jpan-JP": "日本語",
    },
    "kor": {
        "cmn-Hans-CN": "韩语",
        "cmn-Hant-TW": "韓語",
        "jpn-Jpan-JP": "韓国語",
    },
    "nan": {
        "cmn-Hans-CN": "闽南语",
        "cmn-Hant-TW": "閩南語",
        "jpn-Jpan-JP": "閩南語",
    },
    "ral": {
        "cmn-Hans-CN": "拉尔特语",
        "cmn-Hant-TW": "拉爾特語",
        "jpn-Jpan-JP": "ラルテー語",
    },
    "rus": {
        "cmn-Hans-CN": "俄语",
        "cmn-Hant-TW": "俄語",
        "jpn-Jpan-JP": "ロシア語",
    },
    "spa": {
        "cmn-Hans-CN": "西班牙语",
        "cmn-Hant-TW": "西班牙語",
        "jpn-Jpan-JP": "スペイン語",
    },
    "swh": {
        "cmn-Hans-CN": "斯瓦希里语",
        "cmn-Hant-TW": "斯瓦希里語",
        "jpn-Jpan-JP": "スワヒリ語",
    },
    "tha": {
        "cmn-Hans-CN": "泰语",
        "cmn-Hant-TW": "泰語",
        "jpn-Jpan-JP": "タイ語",
    },
    "wuu": {
        "cmn-Hans-CN": "吴语",
        "cmn-Hant-TW": "吳語",
        "jpn-Jpan-JP": "呉語",
    },
    "yue": {
        "cmn-Hans-CN": "粤语",
        "cmn-Hant-TW": "粵語",
        "jpn-Jpan-JP": "広東語",
    },
    "zyg": {
        "cmn-Hans-CN": "央壮语",
        "cmn-Hant-TW": "央壯語",
        "jpn-Jpan-JP": "徳靖チワン語",
    },
    "x-emoji": {
        "cmn-Hans-CN": "表情符号",
        "cmn-Hant-TW": "表情符號",
        "jpn-Jpan-JP": "絵文字",
    },
    "x-image": {
        "cmn-Hans-CN": "图像",
        "cmn-Hant-TW": "圖像",
        "jpn-Jpan-JP": "画像",
    },
}

WIKIDATA_QUERY = """SELECT ?code ?lang ?label WHERE {
  ?item wdt:P220 ?code .
  VALUES ?lang { \"zh-hans\" \"zh-hant\" \"zh\" \"ja\" }
  ?item rdfs:label ?label .
  FILTER(LANG(?label)=STR(?lang))
  FILTER(STRLEN(?code)=3)
}"""


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_language_codes(path: Path) -> set[str]:
    codes = set()
    with path.open(encoding="utf-8", newline="") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            if row.get("Scope") == "I" and row.get("Id"):
                codes.add(row["Id"].strip().lower())
    codes.update({"x-emoji", "x-image"})
    return codes


def _po_value(block: list[str], index: int, prefix: str) -> str:
    values = []
    first = block[index][len(prefix) :].strip()
    if first:
        values.append(ast.literal_eval(first))
    index += 1
    while index < len(block) and block[index].startswith('"'):
        values.append(ast.literal_eval(block[index]))
        index += 1
    return "".join(values)


def read_po(path: Path) -> dict[str, str]:
    """Read non-fuzzy ``Name for <code>`` entries from a gettext PO file."""
    values: dict[str, str] = {}
    block: list[str] = []
    blocks = path.read_text(encoding="utf-8").splitlines() + [""]
    for line in blocks:
        if line.strip():
            block.append(line)
            continue
        comments = " ".join(
            line.strip()[2:].strip()
            for line in block
            if line.strip().startswith("#.")
        )
        fuzzy = any(
            line.strip().startswith("#,") and "fuzzy" in line
            for line in block
        )
        msgid_index = next(
            (index for index, line in enumerate(block) if line.startswith("msgid ")),
            None,
        )
        msgstr_index = next(
            (index for index, line in enumerate(block) if line.startswith("msgstr ")),
            None,
        )
        match = re.fullmatch(r"Name for ([a-z0-9-]{3})", comments)
        if match and msgid_index is not None and msgstr_index is not None and not fuzzy:
            value = _po_value(block, msgstr_index, "msgstr ").strip()
            if value:
                values[match.group(1)] = value
        block = []
    return values


def read_cldr(path: Path) -> dict[str, str]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    main = payload.get("main")
    if not isinstance(main, dict) or len(main) != 1:
        raise ValueError(f"CLDR file has an unexpected main locale: {path}")
    locale = next(iter(main))
    languages = main[locale]["localeDisplayNames"]["languages"]
    if not isinstance(languages, dict):
        raise ValueError(f"CLDR language data is missing: {path}")
    return {
        str(code).lower(): str(text).strip()
        for code, text in languages.items()
        if str(text).strip()
    }


def read_wikidata(path: Path) -> dict[str, dict[str, set[str]]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    bindings = payload.get("results", {}).get("bindings", [])
    if not isinstance(bindings, list):
        raise ValueError(f"Wikidata result has an unexpected shape: {path}")
    values: dict[str, dict[str, set[str]]] = defaultdict(lambda: defaultdict(set))
    for binding in bindings:
        if not isinstance(binding, dict):
            continue
        code = str(binding.get("code", {}).get("value", "")).strip().lower()
        language = str(binding.get("lang", {}).get("value", "")).strip().lower()
        label = str(binding.get("label", {}).get("value", "")).strip()
        if len(code) == 3 and language and label:
            values[code][language].add(label)
    return values


def source_metadata(name: str, path: Path, url: str) -> dict[str, str | int]:
    return {
        "name": name,
        "file": path.name,
        "sha256": sha256_file(path),
        "size": path.stat().st_size,
        "url": url,
    }


def unique_value(values: set[str]) -> str | None:
    return next(iter(values)) if len(values) == 1 else None


def assemble(
    *,
    iso639_path: Path,
    cldr_zh_path: Path,
    cldr_zh_hant_path: Path,
    cldr_ja_path: Path,
    iso_zh_cn_path: Path,
    iso_zh_tw_path: Path,
    iso_ja_path: Path,
    wikidata_path: Path,
) -> dict[str, Any]:
    language_codes = read_language_codes(iso639_path)
    cldr = {
        "cmn-Hans-CN": read_cldr(cldr_zh_path),
        "cmn-Hant-TW": read_cldr(cldr_zh_hant_path),
        "jpn-Jpan-JP": read_cldr(cldr_ja_path),
    }
    po = {
        "cmn-Hans-CN": read_po(iso_zh_cn_path),
        "cmn-Hant-TW": read_po(iso_zh_tw_path),
        "jpn-Jpan-JP": read_po(iso_ja_path),
    }
    wikidata = read_wikidata(wikidata_path)

    translations: dict[str, dict[str, str]] = {locale: {} for locale in TARGETS}
    provenance: dict[str, dict[str, str]] = {locale: {} for locale in TARGETS}
    source_counts: dict[str, Counter[str]] = {
        locale: Counter() for locale in TARGETS
    }
    conflicts: dict[str, list[str]] = {locale: [] for locale in TARGETS}

    for locale, config in TARGETS.items():
        for code in sorted(language_codes):
            text: str | None = None
            source: str | None = None

            if code in CURATED and locale in CURATED[code]:
                text = CURATED[code][locale]
                source = "curated"
            else:
                cldr_key = CLDR_ALIASES.get(code, code)
                if config["cldr_key"] in cldr and cldr_key in cldr[config["cldr_key"]]:
                    text = cldr[config["cldr_key"]][cldr_key]
                    source = "cldr"

                if text is None:
                    labels = wikidata.get(code, {}).get(config["wikidata_lang"], set())
                    text = unique_value(labels)
                    if labels and text is None:
                        conflicts[locale].append(code)
                    elif text is not None:
                        source = "wikidata"

                if text is None:
                    text = po[config["po_key"]].get(code)
                    if text is not None:
                        source = "iso-codes"

            if text is None or source is None:
                continue
            text = unicodedata.normalize("NFC", text.strip())
            if not text:
                continue
            translations[locale][code] = text
            provenance[locale][code] = source
            source_counts[locale][source] += 1

    return {
        "schema_version": 1,
        "target_locales": list(TARGETS),
        "source_precedence": ["curated", "cldr", "wikidata", "iso-codes"],
        "wikidata_query": WIKIDATA_QUERY,
        "sources": {
            "cldr_zh": source_metadata(
                "Unicode CLDR 48.2 Chinese language names",
                cldr_zh_path,
                "https://raw.githubusercontent.com/unicode-org/cldr-json/48.2.0/cldr-json/cldr-localenames-full/main/zh/languages.json",
            ),
            "cldr_ja": source_metadata(
                "Unicode CLDR 48.2 Japanese language names",
                cldr_ja_path,
                "https://raw.githubusercontent.com/unicode-org/cldr-json/48.2.0/cldr-json/cldr-localenames-full/main/ja/languages.json",
            ),
            "cldr_zh_hant": source_metadata(
                "Unicode CLDR 48.2 Traditional Chinese language names",
                cldr_zh_hant_path,
                "https://unpkg.com/cldr-localenames-full@48.2.0/main/zh-Hant/languages.json",
            ),
            "iso_zh_cn": source_metadata(
                "Debian iso-codes Chinese (Simplified) ISO 639-3 names",
                iso_zh_cn_path,
                "https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/iso_639-3/zh_CN.po",
            ),
            "iso_zh_tw": source_metadata(
                "Debian iso-codes Chinese (Traditional) ISO 639-3 names",
                iso_zh_tw_path,
                "https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/iso_639-3/zh_TW.po",
            ),
            "iso_ja": source_metadata(
                "Debian iso-codes Japanese ISO 639-3 names",
                iso_ja_path,
                "https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/iso_639-3/ja.po",
            ),
            "wikidata": source_metadata(
                "Wikidata ISO 639-3 labels",
                wikidata_path,
                "https://query.wikidata.org/",
            ),
        },
        "coverage": {
            locale: {
                "translated_codes": len(translations[locale]),
                "source_counts": dict(sorted(source_counts[locale].items())),
                "conflict_count": len(conflicts[locale]),
            }
            for locale in TARGETS
        },
        "conflicts": {locale: sorted(values) for locale, values in conflicts.items() if values},
        "translations": {
            locale: dict(sorted(values.items())) for locale, values in translations.items()
        },
        "provenance": {
            locale: dict(sorted(values.items())) for locale, values in provenance.items()
        },
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iso639-3", type=Path, default=RAW / "iso639-3.tab")
    parser.add_argument("--cldr-zh", type=Path, required=True)
    parser.add_argument("--cldr-zh-hant", type=Path, required=True)
    parser.add_argument("--cldr-ja", type=Path, required=True)
    parser.add_argument("--iso-zh-cn", type=Path, required=True)
    parser.add_argument("--iso-zh-tw", type=Path, required=True)
    parser.add_argument("--iso-ja", type=Path, required=True)
    parser.add_argument("--wikidata", type=Path, required=True)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    result = assemble(
        iso639_path=args.iso639_3,
        cldr_zh_path=args.cldr_zh,
        cldr_zh_hant_path=args.cldr_zh_hant,
        cldr_ja_path=args.cldr_ja,
        iso_zh_cn_path=args.iso_zh_cn,
        iso_zh_tw_path=args.iso_zh_tw,
        iso_ja_path=args.iso_ja,
        wikidata_path=args.wikidata,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"wrote {args.output}")
    for locale, coverage in result["coverage"].items():
        print(
            f"{locale}: {coverage['translated_codes']} codes; "
            f"sources={coverage['source_counts']}; "
            f"conflicts={coverage['conflict_count']}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
