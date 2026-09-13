from __future__ import annotations

import sqlite3

from scripts.dictionary.langmap_dictionary.adapters.registry import (
    adapter_for_dictionary_key,
    adapter_for_release,
)
from scripts.dictionary.langmap_dictionary.adapters.wikivoyage_phrasebook import WikivoyagePhrasebookAdapter
from scripts.dictionary.langmap_dictionary.models import StagedEntry, StagedPronunciation, StagedSense


def _entry(*, language: str = "eng", reading_scheme: str = "hepburn", reading: str = "toire") -> StagedEntry:
    return StagedEntry(
        "release-1",
        "enwikivoyage:16153",
        "16153:basics:abc:1",
        "トイレはどこですか？",
        "トイレはどこですか？",
        None,
        "jpn-to-eng",
        "f" * 64,
        (StagedPronunciation(1, reading, reading_scheme, {"locale": "jpn-Jpan-JP"}),),
        (StagedSense(
            "16153:basics:abc:1:sense:1",
            1,
            equivalents=({"value": "Where is the toilet?", "language": language, "locale": "eng-Latn-US"},),
        ),),
        raw={"raw": {"target_lang_code": "jpn", "target_locale_code": "jpn-Jpan-JP", "source_marker": "oldid:5332510#basics/24"}},
    )


def test_adapter_projects_target_head_and_english_mapping() -> None:
    normalized = WikivoyagePhrasebookAdapter().normalize_entry(_entry())

    assert normalized.headword.lang_code == "jpn"
    assert normalized.headword.locale_code == "jpn-Jpan-JP"
    assert normalized.senses[0].occurrences[0].lang_code == "eng"
    assert normalized.senses[0].occurrences[0].locale_code == "eng-Latn-US"
    assert normalized.senses[0].occurrences[0].errors == ()
    assert normalized.readings[0].scheme == "hepburn"
    assert normalized.readings[0].target_claim_key is None
    assert normalized.headword.metadata["source_marker"] == "oldid:5332510#basics/24"


def test_adapter_quarantines_non_english_equivalent_and_unknown_reading() -> None:
    normalized = WikivoyagePhrasebookAdapter().normalize_entry(
        _entry(language="jpn", reading_scheme="local", reading="読み")
    )

    assert "non_english_equivalent" in normalized.senses[0].occurrences[0].errors
    assert "unknown_reading_scheme" in normalized.readings[0].errors


def test_adapter_splits_english_alternatives_and_keeps_explanation_as_annotation() -> None:
    normalized = WikivoyagePhrasebookAdapter().normalize_entry(
        StagedEntry(
            "release-1",
            "enwikivoyage:16153",
            "entry",
            "トイレはどこですか？",
            "トイレはどこですか？",
            None,
            "jpn-to-eng",
            "f" * 64,
            senses=(StagedSense(
                "sense",
                1,
                equivalents=({
                    "value": "Hello!/i say!/hey! (only on the telephone)",
                    "language": "eng",
                    "locale": "eng-Latn-US",
                },),
            ),),
            raw={"raw": {"target_lang_code": "jpn", "target_locale_code": "jpn-Jpan-JP"}},
        )
    )

    assert [item.canonical_text for item in normalized.senses[0].occurrences] == [
        "Hello!",
        "I say!",
        "Hey!",
    ]
    assert [annotation.text for annotation in normalized.annotations] == ["only on the telephone"] * 3


def test_adapter_extracts_plain_target_respelling_as_reading() -> None:
    normalized = WikivoyagePhrasebookAdapter().normalize_entry(
        StagedEntry(
            "release-1", "enwikivoyage:37990", "entry", "Đóng cửa (dauung-kưə)",
            "Đóng cửa (dauung-kưə)", None, "vie-to-eng", "f" * 64,
            senses=(StagedSense("sense", 1, equivalents=({"value": "Closed", "language": "eng", "locale": "eng-Latn-US"},)),),
            raw={"raw": {"target_lang_code": "vie", "target_locale_code": "vie-Latn-VN"}},
        )
    )

    assert normalized.headword.canonical_text == "Đóng cửa"
    assert [(reading.scheme, reading.value, reading.errors) for reading in normalized.readings] == [
        ("wikivoyage-respelling", "dauung-kưə", ()),
    ]


def test_adapter_attaches_parser_target_annotation_to_mapping_edge() -> None:
    normalized = WikivoyagePhrasebookAdapter().normalize_entry(
        StagedEntry(
            "release-1", "enwikivoyage:5837", "entry", "我会叫警察", "我会叫警察", None,
            "yue-to-eng", "f" * 64,
            senses=(StagedSense("sense", 1, equivalents=({"value": "I'll call the police", "language": "eng", "locale": "eng-Latn-US"},)),),
            raw={"raw": {"target_lang_code": "yue", "target_locale_code": "yue-Hant-HK", "target_annotation": "差佬 is colloquial"}},
        )
    )

    assert [annotation.text for annotation in normalized.annotations] == ["差佬 is colloquial"]
    assert normalized.annotations[0].target_claim_key == normalized.headword.claim_key


def test_dictionary_key_and_release_dispatch_are_explicit() -> None:
    assert isinstance(adapter_for_dictionary_key("enwikivoyage:16153"), WikivoyagePhrasebookAdapter)
    connection = sqlite3.connect(":memory:")
    connection.execute("CREATE TABLE input_entries(release_id TEXT, dictionary_key TEXT)")
    connection.execute("INSERT INTO input_entries VALUES ('release-1','enwikivoyage:16153')")

    assert isinstance(adapter_for_release(connection, "release-1"), WikivoyagePhrasebookAdapter)
