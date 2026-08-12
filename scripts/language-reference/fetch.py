#!/usr/bin/env python3
"""One-shot fetcher for pinned ISO sources into raw/. Run manually to refresh pins.

Not run at build/test time. Records provenance into raw/provenance.json.

Sources:
- ISO 639-3 and ISO 3166-1 come from the Debian ``iso-codes`` project
  (https://salsa.debian.org/iso-codes-team/iso-codes), which republishes the
  official ISO data under the FSF All Permissive License (FSFAP). The canonical
  SIL ISO 639-3 download (iso639-3.sil.org) sits behind a Cloudflare JS
  challenge that blocks programmatic access, so iso-codes is used as the
  authoritative, freely-licensed, programmatically-reachable mirror. The JSON
  payloads are converted to the SIL tab / TSV layouts the generator consumes.
- ISO 15924 is fetched directly from unicode.org.
"""
from __future__ import annotations

import hashlib
import json
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

RAW = Path(__file__).resolve().parent / "raw"

USER_AGENT = "langmap-language-reference-fetch/1.0"

ISO_CODES_BASE = (
    "https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/data"
)

SOURCES = [
    {
        "key": "iso639-3",
        "url": f"{ISO_CODES_BASE}/iso_639-3.json",
        "license": "FSFAP",
        "upstream": "https://iso639-3.sil.org/ (SIL canonical; Cloudflare-blocked)",
        "convert": "iso6393",
        "out": "iso639-3.tab",
    },
    {
        "key": "iso15924",
        "url": "https://www.unicode.org/iso15924/iso15924.txt",
        "license": "Unicode-DFS-2016",
        "convert": None,
        "out": "iso15924.txt",
    },
    {
        "key": "iso3166-1",
        "url": f"{ISO_CODES_BASE}/iso_3166-1.json",
        "license": "FSFAP",
        "upstream": "https://www.iso.org/iso-3166-country-codes.html (ISO canonical; not freely downloadable)",
        "convert": "iso3166-1",
        "out": "iso3166-1.tsv",
    },
]


def http_get(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def to_iso6393_sil_tab(json_bytes: bytes) -> bytes:
    """iso-codes iso_639-3.json -> SIL iso_639-3.tab layout.

    WHY match the SIL layout: the generator reads this as a tab-delimited file
    with the SIL column names (Id / Scope / Language_Type / Ref_Name).
    """
    data = json.loads(json_bytes)
    lines = ["Id\tScope\tLanguage_Type\tRef_Name\tComment"]
    for e in data["639-3"]:
        lines.append(
            "\t".join(
                [
                    e.get("alpha_3", ""),
                    e.get("scope", ""),
                    e.get("type", ""),
                    str(e.get("name", "")).replace("\t", " "),
                    "",
                ]
            )
        )
    return ("\n".join(lines) + "\n").encode("utf-8")


def to_iso3166_1_tsv(json_bytes: bytes) -> bytes:
    """iso-codes iso_3166-1.json -> code/name_en TSV."""
    data = json.loads(json_bytes)
    lines = ["code\tname_en"]
    for e in data["3166-1"]:
        lines.append(
            f"{e.get('alpha_2', '')}\t{str(e.get('name', '')).replace(chr(9), ' ')}"
        )
    return ("\n".join(lines) + "\n").encode("utf-8")


CONVERTERS = {
    "iso6393": to_iso6393_sil_tab,
    "iso3166-1": to_iso3166_1_tsv,
}


def main() -> int:
    RAW.mkdir(parents=True, exist_ok=True)
    downloaded_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    provenance: dict = {"downloaded_at": downloaded_at, "files": {}}
    for src in SOURCES:
        print(f"fetching {src['key']} from {src['url']}")
        raw_bytes = http_get(src["url"])
        source_sha = sha256_bytes(raw_bytes)
        converter = CONVERTERS[src["convert"]] if src["convert"] else None
        out_bytes = converter(raw_bytes) if converter else raw_bytes
        (RAW / src["out"]).write_bytes(out_bytes)
        entry: dict = {
            "url": src["url"],
            "license": src["license"],
            "source_sha256": source_sha,
            "out": src["out"],
            "out_sha256": sha256_bytes(out_bytes),
            "out_size": len(out_bytes),
        }
        if "upstream" in src:
            entry["upstream"] = src["upstream"]
        if converter is not None:
            entry["converted_from"] = "JSON"
        provenance["files"][src["key"]] = entry
    (RAW / "provenance.json").write_text(
        json.dumps(provenance, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"wrote {RAW / 'provenance.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
