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


def test_split_profile_emits_exact_simplified_and_traditional_locales() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[7357]
    result = parse_phrase_rows("===Basics===\n; Hello : 你好。 (你好。) ''Nǐ hǎo''", profile, _sections())

    assert len(result.entries) == 2
    assert [(entry["raw_headword"], entry["raw"]["target_locale_code"]) for entry in result.entries] == [
        ("你好", "cmn-Hans-CN"),
        ("你好", "cmn-Hant-TW"),
    ]
    assert all(entry["pronunciations"][0]["locale"] == entry["raw"]["target_locale_code"] for entry in result.entries)


def test_reverse_definition_row_keeps_target_and_inline_reading() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[5837]
    result = parse_phrase_rows("===Eating===\n;煎 jīn: pan-fried", profile, _sections())

    assert len(result.entries) == 1
    assert result.entries[0]["raw_headword"] == "煎"
    assert result.entries[0]["senses"][0]["equivalents"][0]["value"] == "pan-fried"
    assert result.entries[0]["pronunciations"][0]["value"] == "jīn"


def test_parser_extracts_only_explicit_phrase_rows_and_readings() -> None:
    result = parse_phrase_rows(_content(), _profile(), _sections())

    assert result.state == "included"
    assert len(result.entries) == 5
    first = result.entries[0]
    assert first["raw_headword"] == "こんにちは"
    assert first["senses"][0]["equivalents"][0]["value"] == "Good afternoon"
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


def test_terminal_stops_and_slash_variants_are_normalized() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[35697]
    result = parse_phrase_rows(
        "===Shopping===\n; OK, I'll take it. : ตกลง ผม/ดิฉัน จะซื้อ (''tok long phŏm/dì-chăn jà súe'')",
        profile,
        _sections(),
    )

    assert [(entry["raw_headword"], entry["senses"][0]["equivalents"][0]["value"]) for entry in result.entries] == [
        ("ตกลง ผม จะซื้อ", "OK, I'll take it"),
        ("ตกลง ดิฉัน จะซื้อ", "OK, I'll take it"),
    ]
    assert [entry["pronunciations"][0]["value"] for entry in result.entries] == [
        "tok long phŏm jà súe",
        "tok long dì-chăn jà súe",
    ]

    no_space = parse_phrase_rows(
        "===Shopping===\n; OK, I'll take it. : ตกลง ผม/ดิฉันเอา (''tok long phŏm/dì-chăn ao'')",
        profile,
        _sections(),
    )
    assert [entry["raw_headword"] for entry in no_space.entries] == ["ตกลง ผมเอา", "ตกลง ดิฉันเอา"]


def test_slashes_in_readings_become_separate_readings_without_new_expression() -> None:
    result = parse_phrase_rows(_content(), _profile(), _sections())

    toilet = next(entry for entry in result.entries if entry["raw_headword"].startswith("お手洗い"))
    assert len(result.entries) == 5
    assert [reading["value"] for reading in toilet["pronunciations"]] == [
        "Otearai wa doko desu ka?",
        "toire wa doko desu ka?",
        "Oh-teh-ah-rah-ee",
        "toh-ee-reh",
    ]
