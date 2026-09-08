from __future__ import annotations

import json
import sqlite3
from pathlib import Path

from scripts.dictionary.langmap_dictionary.adapters.traditional_chinese_english import normalize_release
from scripts.dictionary.langmap_dictionary.clusters import build_explicit_clusters
from scripts.dictionary.langmap_dictionary.loader import load_jsonl_release
from scripts.dictionary.langmap_dictionary.local_import import import_release_to_local_d1
from scripts.dictionary.langmap_dictionary.schema import create_staging_database


ROOT = Path(__file__).parents[3]


def _entry() -> dict[str, object]:
    return {
        "record_type": "entry",
        "schema_version": 2,
        "dictionary_key": "enwikivoyage:16153",
        "entry_key": "16153:basics:abc:1",
        "record_fingerprint": "a" * 64,
        "csv_row_number": 1,
        "raw_headword": "トイレ",
        "canonical_headword": "トイレ",
        "homograph_marker": None,
        "direction_hint": "jpn-to-eng",
        "forms": [],
        "mappings": [],
        "pronunciations": [{"value": "toire", "scheme": "hepburn", "locale": "jpn-Jpan-JP"}],
        "senses": [{
            "sense_key": "16153:basics:abc:1:sense:1",
            "ordinal": 1,
            "definitions": [],
            "pos": [],
            "equivalents": [{"value": "Toilet", "language": "eng", "locale": "eng-Latn-US"}],
            "relations": [],
            "examples": [],
            "labels": [],
        }],
        "diagnostics": [],
        "raw": {
            "pageid": 16153,
            "revision": 5332510,
            "section_key": "basics",
            "row": 1,
            "target_lang_code": "jpn",
            "target_locale_code": "jpn-Jpan-JP",
            "source_marker": "oldid:5332510#basics/1",
        },
    }


def test_wikivoyage_import_preserves_direct_edge_reading_and_markers(tmp_path: Path) -> None:
    jsonl = tmp_path / "16153.jsonl"
    header = {
        "record_type": "dictionary",
        "schema_version": 2,
        "dictionary_key": "enwikivoyage:16153",
        "entry_count": 1,
        "input_file_name": "pages/16153-5332510.wikitext",
        "input_sha256": "b" * 64,
        "exporter_version": "wikivoyage-phrasebook-2",
    }
    jsonl.write_text("\n".join(json.dumps(row, ensure_ascii=False) for row in (header, _entry())) + "\n", encoding="utf-8")
    (tmp_path / "source-catalog.json").write_text(json.dumps({"sources": {
        "enwikivoyage:16153": {
            "type": "url",
            "name": "https://en.wikivoyage.org/wiki/Japanese_phrasebook",
            "source_rank": 100,
        },
    }}), encoding="utf-8")

    staging_path = tmp_path / "staging.sqlite"
    staging = create_staging_database(staging_path)
    loaded = load_jsonl_release(staging, [jsonl])
    normalize_release(staging, loaded.release_id)
    build_explicit_clusters(staging, loaded.release_id)
    staging.close()

    d1_path = tmp_path / "canonical.sqlite"
    canonical = sqlite3.connect(d1_path)
    canonical.row_factory = sqlite3.Row
    canonical.executescript((ROOT / "backend/schema.sql").read_text(encoding="utf-8"))
    canonical.execute("INSERT INTO users(username,email,password_hash,role) VALUES('langmap','x','x','system')")
    canonical.execute("INSERT INTO languages(code,name_en) VALUES('eng','English')")
    canonical.execute("INSERT INTO languages(code,name_en) VALUES('jpn','Japanese')")
    canonical.execute("INSERT INTO language_locales(code,language_id,name,name_en) VALUES('eng-Latn-US',1,'English','English')")
    canonical.execute("INSERT INTO language_locales(code,language_id,name,name_en) VALUES('jpn-Jpan-JP',2,'日本語','Japanese')")
    canonical.commit()
    summary = import_release_to_local_d1(
        staging_path,
        d1_path,
        loaded.release_id,
        source_catalog=json.loads((tmp_path / "source-catalog.json").read_text(encoding="utf-8"))["sources"],
    )

    assert summary.edges == 1
    assert canonical.execute("SELECT COUNT(*) FROM expression_edges").fetchone()[0] == 1
    assert tuple(canonical.execute("SELECT scheme,value FROM expression_readings").fetchone()) == ("hepburn", "toire")
    marker_rows = canonical.execute("SELECT source_marker FROM expression_edge_sources").fetchall()
    assert [row[0] for row in marker_rows] == ["oldid:5332510#basics/1"]
    assert canonical.execute("SELECT COUNT(*) FROM expression_sources WHERE source_marker=?", ("oldid:5332510#basics/1",)).fetchone()[0] == 2
    canonical.close()
