from pathlib import Path

from scripts.dictionary.langmap_dictionary.adapters.traditional_chinese_english import TraditionalChineseEnglishAdapter, normalize_release
from scripts.dictionary.langmap_dictionary.clusters import build_explicit_clusters
from scripts.dictionary.langmap_dictionary.loader import load_jsonl_release
from scripts.dictionary.langmap_dictionary.schema import create_staging_database

FIXTURE = Path(__file__).parent / "fixtures" / "traditional_chinese_english_v2.jsonl"


def test_adapter_maps_languages_readings_pos_and_keeps_offline_fields(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    summary = load_jsonl_release(connection, [FIXTURE])
    normalize_release(connection, summary.release_id)
    head = connection.execute("SELECT * FROM lexical_occurrences WHERE occurrence_kind='headword' ORDER BY entry_key LIMIT 1").fetchone()
    assert head["lang_code"] == "eng"
    assert head["locale_code"] == "eng-Latn-US"
    assert connection.execute("SELECT scheme,locale_code FROM lexical_readings ORDER BY claim_key").fetchone()[:2] == ("ipa", "eng-Latn-GB")
    assert connection.execute("SELECT code FROM normalized_pos WHERE sense_key='cod-1-s1'").fetchone()[0] == "noun"
    assert connection.execute("SELECT definitions_json,labels_json FROM input_senses WHERE sense_key='cod-1-s1'").fetchone()[0] == '["fish"]'
    assert build_explicit_clusters(connection, summary.release_id).clusters >= 3


def test_adapter_removes_bullet_only_from_normalized_equivalent():
    adapter = TraditionalChineseEnglishAdapter()
    from scripts.dictionary.langmap_dictionary.models import StagedEntry, StagedSense
    entry = StagedEntry("r", "d", "e", "頭", "頭", None, "cmn-Hant-to-eng", "a" * 64, senses=(StagedSense("s", 1, equivalents=("• head",)),))
    occurrence = adapter.normalize_entry(entry).senses[0].occurrences[0]
    assert occurrence.raw_value == "• head"
    assert occurrence.canonical_text == "head"


def test_adapter_uses_non_english_direction_profiles():
    adapter = TraditionalChineseEnglishAdapter()
    from scripts.dictionary.langmap_dictionary.models import StagedEntry, StagedSense
    entry = StagedEntry("r", "d", "e", "mot", "mot", None, "fra-to-eng", "a" * 64, senses=(StagedSense("s", 1, equivalents=("word",), examples=({"text": "mot exemple", "translation": "example word"},)),))
    normalized = adapter.normalize_entry(entry)
    assert normalized.headword.lang_code == "fra"
    assert normalized.senses[0].occurrences[0].lang_code == "eng"
    assert normalized.senses[0].occurrences[1].lang_code == "fra"
    assert normalized.senses[0].occurrences[2].lang_code == "eng"
