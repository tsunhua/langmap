from __future__ import annotations

import json
from pathlib import Path

from scripts.wikivoyage.catalog import load_page_catalog, load_section_catalog
from scripts.wikivoyage.parser import PageSnapshot, export_page, parse_phrase_rows


ROOT = Path(__file__).parents[1]
FIXTURE = ROOT / "tests" / "fixtures"


def _profile():
    return load_page_catalog(ROOT / "page-catalog.json")[16153]


def _sections():
    return load_section_catalog(ROOT / "section-catalog.json")


def _content() -> str:
    return (FIXTURE / "japanese_phrasebook.wikitext").read_text(encoding="utf-8")


def test_parser_extracts_only_explicit_phrase_rows_and_readings() -> None:
    result = parse_phrase_rows(_content(), _profile(), _sections())

    assert result.state == "included"
    assert len(result.entries) == 5
    first = result.entries[0]
    assert first["raw_headword"] == "こんにちは。"
    assert first["senses"][0]["equivalents"][0]["value"] == "Good afternoon."
    assert first["pronunciations"][0]["scheme"] == "hepburn"
    assert first["pronunciations"][1]["scheme"] == "hepburn"
    assert first["raw"]["section_key"] == "basics"
    assert all("narrative" not in json.dumps(entry, ensure_ascii=False) for entry in result.entries)


def test_export_replaces_provisional_revision_and_keeps_source_marker() -> None:
    content = _content()
    snapshot = PageSnapshot.from_content(
        pageid=16153,
        title="Japanese phrasebook",
        canonical_url="https://en.wikivoyage.org/wiki/Japanese_phrasebook",
        revision=5332510,
        revision_timestamp="2026-09-07T00:00:00Z",
        content=content,
    )

    result = export_page(snapshot, _profile(), _sections())

    assert result.entries[0]["raw"]["source_marker"] == "oldid:5332510#basics/1"
    assert result.entries[0]["record_fingerprint"]
    assert result.entries[0]["raw"]["canonical_url"].endswith("Japanese_phrasebook")


def test_cjk_in_romanization_is_quarantined_without_dropping_expression() -> None:
    profile = _profile()
    result = parse_phrase_rows("===Basics===\n; Hello : こんにちは。 ''日本語''", profile, _sections())

    assert len(result.entries) == 1
    assert result.entries[0]["senses"][0]["equivalents"][0]["value"] == "Hello"
    assert result.entries[0]["pronunciations"] == []
    assert any(item["error_code"] == "reading_script_mismatch" for item in result.diagnostics)

