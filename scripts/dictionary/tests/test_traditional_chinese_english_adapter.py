from pathlib import Path

import pytest

from scripts.dictionary.langmap_dictionary.adapters.traditional_chinese_english import TraditionalChineseEnglishAdapter, canonicalize_text, normalize_release
from scripts.dictionary.langmap_dictionary.clusters import build_explicit_clusters
from scripts.dictionary.langmap_dictionary.loader import load_jsonl_release
from scripts.dictionary.langmap_dictionary.models import StagedEntry, StagedPronunciation, StagedSense
from scripts.dictionary.langmap_dictionary.schema import create_staging_database

FIXTURE = Path(__file__).parent / "fixtures" / "traditional_chinese_english_v2.jsonl"


def test_canonicalize_text_removes_terminal_periods_but_keeps_other_punctuation():
    assert canonicalize_text("祝日を楽しく祝う.") == "祝日を楽しく祝う"
    assert canonicalize_text("喜び祝う．") == "喜び祝う"
    assert canonicalize_text("歡慶節日。") == "歡慶節日"
    assert canonicalize_text("真的嗎？") == "真的嗎？"
    assert canonicalize_text("太好了！") == "太好了！"
    assert canonicalize_text("...") == "..."


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


def test_normalization_resume_uses_checkpoint_without_duplicate_rows(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    summary = load_jsonl_release(connection, [FIXTURE])
    assert normalize_release(connection, summary.release_id, batch_size=1) == 3
    occurrence_count = connection.execute("SELECT COUNT(*) FROM lexical_occurrences").fetchone()[0]

    assert normalize_release(connection, summary.release_id, resume=True, batch_size=1) == 0
    assert connection.execute("SELECT COUNT(*) FROM lexical_occurrences").fetchone()[0] == occurrence_count
    assert connection.execute(
        "SELECT processed_entries,status FROM normalization_progress WHERE release_id=?",
        (summary.release_id,),
    ).fetchone()[:] == (3, "completed")

    connection.execute("DELETE FROM normalization_progress WHERE release_id=?", (summary.release_id,))
    connection.commit()
    assert normalize_release(connection, summary.release_id, resume=True, batch_size=1) == 0
    assert connection.execute("SELECT COUNT(*) FROM lexical_occurrences").fetchone()[0] == occurrence_count


def test_normalization_rejects_invalid_batch_settings(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    summary = load_jsonl_release(connection, [FIXTURE])

    with pytest.raises(ValueError, match="batch_size"):
        normalize_release(connection, summary.release_id, batch_size=0)
    with pytest.raises(ValueError, match="commit_every"):
        normalize_release(connection, summary.release_id, commit_every=0)


def test_normalization_reports_monotonic_progress(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    summary = load_jsonl_release(connection, [FIXTURE])
    events = []

    normalize_release(
        connection,
        summary.release_id,
        commit_every=1,
        progress=events.append,
    )

    processed = [event["processed_entries"] for event in events]
    assert processed == sorted(processed)
    assert {1, 2, 3} <= set(processed)
    assert events[-1]["status"] == "completed"


def test_normalization_flushes_progress_more_often_than_it_commits(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    summary = load_jsonl_release(connection, [FIXTURE])
    events = []
    statements = []
    connection.set_trace_callback(statements.append)

    normalize_release(
        connection,
        summary.release_id,
        batch_size=1,
        commit_every=10,
        progress=events.append,
    )

    running = [event["processed_entries"] for event in events if event["status"] == "running"]
    assert running == [1, 2, 3]
    assert sum(statement == "COMMIT" for statement in statements) == 1


def test_normalization_can_defer_and_restore_foreign_key_checks(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    summary = load_jsonl_release(connection, [FIXTURE])
    normalize_release(connection, summary.release_id)
    build_explicit_clusters(connection, summary.release_id)
    statements = []
    connection.set_trace_callback(statements.append)

    normalize_release(
        connection,
        summary.release_id,
        defer_foreign_keys=True,
    )

    normalized = [statement.upper().replace(" ", "") for statement in statements]
    assert "PRAGMAFOREIGN_KEYS=OFF" in normalized
    assert "PRAGMAFOREIGN_KEY_CHECK" in normalized
    assert "PRAGMAFOREIGN_KEYS=ON" in normalized
    assert connection.execute("PRAGMA foreign_keys").fetchone()[0] == 1
    assert connection.execute("PRAGMA foreign_key_check").fetchall() == []


def test_normalization_reports_component_timings(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    summary = load_jsonl_release(connection, [FIXTURE])
    events = []
    timings = {}

    normalize_release(
        connection,
        summary.release_id,
        batch_size=1,
        progress=events.append,
        timings=timings,
        defer_foreign_keys=True,
    )

    expected = {
        "normalize_staging_read",
        "normalize_compute",
        "normalize_sqlite_flush",
        "normalize_checkpoint_commit",
        "normalize_foreign_key_check",
    }
    assert set(timings) == expected
    assert all(value >= 0 for value in timings.values())
    assert events[-1]["status"] == "completed"
    assert set(events[-1]["timings"]) == expected


def test_adapter_removes_bullet_only_from_normalized_equivalent():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry("r", "d", "e", "頭", "頭", None, "cmn-Hant-to-eng", "a" * 64, senses=(StagedSense("s", 1, equivalents=("• head",)),))
    occurrence = adapter.normalize_entry(entry).senses[0].occurrences[0]
    assert occurrence.raw_value == "• head"
    assert occurrence.canonical_text == "head"


def test_adapter_promotes_foreign_script_definition_to_equivalent():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.kn-en.oup", "e", "book", "book", None,
        "eng-to-kan", "a" * 64,
        senses=(StagedSense("s", 1, definitions=("a written work published as printed pages", "(ಮುದ್ರಿತ) ಗ್ರಂಥ; ಪುಸ್ತಕ"), equivalents=()),),
    )
    normalized = adapter.normalize_entry(entry)
    assert normalized.headword.lang_code == "eng"
    promoted = [o for o in normalized.senses[0].occurrences if o.occurrence_kind == "equivalent" and o.lang_code == "kan"]
    assert len(promoted) == 1
    assert promoted[0].canonical_text.startswith("(ಮುದ್ರಿತ)")


def test_adapter_keeps_latin_definition_as_meaning_not_equivalent():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zh_HK-en.idioms.cp", "e", "一不做，二不休", "一不做，二不休", None,
        "cmn-Hant-to-eng", "a" * 64,
        senses=(StagedSense("s", 1, definitions=("once you start, finish it",), equivalents=("no half measures",)),),
    )
    normalized = adapter.normalize_entry(entry)
    equivalents = [o.canonical_text for o in normalized.senses[0].occurrences if o.occurrence_kind == "equivalent"]
    assert "no half measures" in equivalents
    assert "once you start, finish it" not in equivalents


def test_adapter_does_not_promote_same_language_definition():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zh_HK.common", "e", "腦子", "腦子", None,
        "cmn-Hant-to-cmn-Hant", "a" * 64,
        senses=(StagedSense("s", 1, definitions=(".腦力。",), equivalents=()),),
    )
    normalized = adapter.normalize_entry(entry)
    promoted = [o for o in normalized.senses[0].occurrences if o.occurrence_kind == "equivalent"]
    assert promoted == []


def test_adapter_publishes_exporter_raw_related_text_synonym():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zh_CN.thes", "e", "哀", "哀", None,
        "cmn-Hans-to-cmn-Hans", "a" * 64,
        senses=(StagedSense(
            "s", 1,
            relations=({
                "kind": "synonym",
                "raw_related_text": "悲",
                "reading": "bēi",
                "language_hint": "cmn-Hans",
            },),
        ),),
    )

    synonyms = [
        occurrence
        for occurrence in adapter.normalize_entry(entry).senses[0].occurrences
        if occurrence.occurrence_kind == "synonym"
    ]

    assert [(item.raw_value, item.canonical_text, item.lang_code, item.locale_code) for item in synonyms] == [
        ("悲", "悲", "cmn", "cmn-Hans-CN")
    ]


def test_adapter_strips_leading_sentence_punctuation_from_promoted_definition():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.kn-en.oup", "e", "book", "book", None,
        "eng-to-kan", "a" * 64,
        senses=(StagedSense("s", 1, definitions=(".ಮುದ್ರಿತ ಗ್ರಂಥ",), equivalents=()),),
    )
    normalized = adapter.normalize_entry(entry)
    promoted = [o for o in normalized.senses[0].occurrences if o.occurrence_kind == "equivalent"]
    assert len(promoted) == 1
    assert promoted[0].canonical_text.startswith("ಮುದ್ರಿತ")


def test_adapter_uses_non_english_direction_profiles():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry("r", "d", "e", "mot", "mot", None, "fra-to-eng", "a" * 64, senses=(StagedSense("s", 1, equivalents=("word",), examples=({"text": "mot exemple", "translation": "example word"},)),))
    normalized = adapter.normalize_entry(entry)
    assert normalized.headword.lang_code == "fra"
    assert normalized.senses[0].occurrences[0].lang_code == "eng"
    assert normalized.senses[0].occurrences[1].lang_code == "fra"
    assert normalized.senses[0].occurrences[2].lang_code == "eng"


def _pronunciation(ordinal: int, scheme: str, value: str) -> StagedPronunciation:
    return StagedPronunciation(ordinal, value, scheme, {})


def _yue_entry(pronunciations):
    return StagedEntry(
        "r", "com.apple.dictionary.yue-en.oup", "e", "撻", "撻", "1",
        "yue-to-eng", "a" * 64, pronunciations=tuple(pronunciations),
    )


def test_adapter_publishes_cantonese_jyutping_reading_without_spaced_tones():
    adapter = TraditionalChineseEnglishAdapter()
    entry = _yue_entry([
        _pronunciation(1, "unknown", "daat 3"),
        _pronunciation(2, "jyutping", "daat³"),
        _pronunciation(3, "unknown", "cyu 4 fong 4/2 lou 2 daat 3 saang 1 jyu 4/2"),
    ])
    published = [r for r in adapter.normalize_entry(entry).readings if not r.errors]
    assert {r.scheme for r in published} == {"jyutping"}
    assert {r.locale_code for r in published} == {"yue-Hant-HK"}
    assert {r.value for r in published} == {"daat³"}


def test_adapter_quarantines_example_transcription_inside_cantonese_entry():
    adapter = TraditionalChineseEnglishAdapter()
    entry = _yue_entry([
        _pronunciation(1, "unknown", "taat 3"),
        _pronunciation(2, "jyutping", "taat³"),
        _pronunciation(3, "unknown", "keoi 5 taat 3 zo 2 jat 1 cin 1 man 4/1"),
    ])
    rejected = [r for r in adapter.normalize_entry(entry).readings if r.errors]
    assert rejected and all(r.scheme == "unknown" and r.locale_code is None for r in rejected)


def test_adapter_preserves_traditional_cantonese_example_locale():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "org.jyutjyu.hk-cantowords", "e", "苦悶", "苦悶", None,
        "yue-Hans-HK-to-eng", "a" * 64,
        senses=(StagedSense(
            "s", 1,
            examples=({
                "text": "純粹發泄下工作嘅苦悶咋",
                "translation": "This is just to vent out my boredom at work",
                "language_hint": "yue-Hant-HK",
            },),
        ),),
    )
    occurrences = adapter.normalize_entry(entry).senses[0].occurrences
    example = next(item for item in occurrences if item.occurrence_kind == "example" and item.lang_code == "yue")
    assert example.locale_code == "yue-Hant-HK"


def test_adapter_routes_cantonese_example_reading_to_example_expression():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "org.jyutjyu.hk-cantowords", "e", "苦悶", "苦悶", None,
        "yue-Hans-HK-to-eng", "a" * 64,
        senses=(StagedSense(
            "s", 1,
            examples=({
                "text": "純粹發泄下工作嘅苦悶咋",
                "translation": "This is just to vent out my boredom at work",
                "language_hint": "yue-Hant-HK",
                "readings": [{
                    "value": "seon4 seoi5 faat3 sit3 haa5 gung1 zok3 ge3 fu2 mun6 zaa3",
                    "scheme": "jyutping",
                    "locale": "yue-Hant-HK",
                }],
            },),
        ),),
    )
    normalized = adapter.normalize_entry(entry)
    readings = [reading for reading in normalized.readings if reading.target_claim_key]
    assert [(reading.scheme, reading.locale_code, reading.value, reading.target_claim_key) for reading in readings] == [
        (
            "jyutping",
            "yue-Hant-HK",
            "seon4 seoi5 faat3 sit3 haa5 gung1 zok3 ge3 fu2 mun6 zaa3",
            "entry:e:sense:s:example:1:text",
        ),
    ]


def test_adapter_accepts_capitalized_jyutping_scheme_and_removes_digit_spaces():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.yue-en.cp", "e", "一了百了", "一了百了", None,
        "yue-to-eng", "a" * 64,
        pronunciations=(
            _pronunciation(1, "unknown", "jat 1 liu 5 baak 3 liu 5"),
            _pronunciation(2, "Jyutping", "jat¹ liu⁵ baak³ liu⁵"),
        ),
    )
    published = [r for r in adapter.normalize_entry(entry).readings if not r.errors]
    assert {r.value for r in published} == {"jat¹ liu⁵ baak³ liu⁵"}
    assert {r.locale_code for r in published} == {"yue-Hant-HK"}


def test_adapter_keeps_unknown_scheme_readings_of_other_languages_quarantined():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zh_TW.wn", "e", "丫", "丫", None,
        "cmn-Hant-to-cmn-Hant", "a" * 64,
        pronunciations=(_pronunciation(1, "unknown", "| yā |"),),
    )
    readings = adapter.normalize_entry(entry).readings
    assert readings and all(r.errors == ("unknown_reading_scheme",) for r in readings)


def test_adapter_reclassifies_cmn_headword_ipa_scheme_pinyin_as_pinyin():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zh_CN.idioms", "e", "阿聾送殯", "阿聾送殯", None,
        "cmn-Hant-to-eng", "a" * 64,
        pronunciations=(_pronunciation(1, "UK_IPA solitary", "ā lóng sòng bìn"),),
    )
    published = [r for r in adapter.normalize_entry(entry).readings if not r.errors]
    assert [(r.scheme, r.locale_code, r.value) for r in published] == [("pinyin", "cmn-Hant-TW", "ā lóng sòng bìn")]


def test_adapter_keeps_english_ipa_reading_on_english_headword():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.yue-en.oup", "e", "supposing", "supposing", None,
        "eng-to-yue", "b" * 64,
        pronunciations=(_pronunciation(1, "UK_IPA", "səˈpəʊzɪŋ"),),
    )
    published = [r for r in adapter.normalize_entry(entry).readings if not r.errors]
    assert [(r.scheme, r.locale_code, r.value) for r in published] == [("ipa", "eng-Latn-GB", "səˈpəʊzɪŋ")]


def test_adapter_quarantines_thai_respelling_mislabeled_as_english_ipa():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.th-en.oup", "e", "peg", "peg", None,
        "eng-to-tha", "a" * 64,
        pronunciations=(_pronunciation(1, "UK_IPA solitary", "เพก"),),
    )

    readings = adapter.normalize_entry(entry).readings

    assert [(r.scheme, r.locale_code, r.value, r.errors) for r in readings] == [
        ("ipa", None, "เพก", ("reading_script_mismatch",))
    ]


def test_adapter_quarantines_hangul_value_mislabeled_as_ipa():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.ko.NewAce", "e", "ㄱㄴㄷ순", "ㄱㄴㄷ-순", None,
        "kor-to-kor", "a" * 64,
        pronunciations=(_pronunciation(1, "UK_IPA solitary", "-영-쑨"),),
    )

    readings = adapter.normalize_entry(entry).readings

    assert [(r.scheme, r.locale_code, r.value, r.errors) for r in readings] == [
        ("ipa", None, "-영-쑨", ("reading_script_mismatch",))
    ]


def test_adapter_quarantines_relation_reading_promoted_to_headword_pronunciation():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zh_CN.thes", "e", "浪费", "浪费", None,
        "cmn-Hans-to-cmn-Hans", "a" * 64,
        pronunciations=(
            _pronunciation(1, "pinyin", "lànɡfèi"),
            _pronunciation(2, "pinyin", "huīhuò"),
        ),
        senses=(StagedSense(
            "s", 1,
            relations=({
                "kind": "synonym",
                "raw_related_text": "挥霍",
                "reading": "huīhuò",
                "language_hint": "cmn-Hans",
            },),
        ),),
    )

    readings = adapter.normalize_entry(entry).readings

    assert [(r.value, r.errors) for r in readings] == [
        ("lànɡfèi", ()),
        ("huīhuò", ("relation_reading_as_headword",)),
    ]


def test_adapter_keeps_a_legitimate_single_homophone_reading():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zh_CN.thes", "e", "行", "行", None,
        "cmn-Hans-to-cmn-Hans", "a" * 64,
        pronunciations=(_pronunciation(1, "pinyin", "xíng"),),
        senses=(StagedSense(
            "s", 1,
            relations=({
                "kind": "synonym",
                "raw_related_text": "走",
                "reading": "xíng",
                "language_hint": "cmn-Hans",
            },),
        ),),
    )

    readings = adapter.normalize_entry(entry).readings

    assert [(r.value, r.errors) for r in readings] == [("xíng", ())]


def test_adapter_folds_crown_pinyin_equivalent_into_cmn_headword_reading():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zhs-ja.Crown", "e", "切迫", "切迫", None,
        "cmn-Hans-to-jpn", "a" * 64,
        senses=(StagedSense("s", 1, equivalents=("緊迫", "jǐnpò", "期限紧迫", "qīxiàn jǐnpò"), examples=()),),
    )
    normalized = adapter.normalize_entry(entry)
    published = [r for r in normalized.readings if not r.errors]
    assert {"pinyin" for r in published} == {"pinyin"}
    assert {r.locale_code for r in published} == {"cmn-Hant-TW"}
    assert {"jǐnpò", "qīxiàn jǐnpò"}.issubset({r.value for r in published})
    kinds = {occ.occurrence_kind for sense in normalized.senses for occ in sense.occurrences}
    assert "equivalent" in kinds
    texts = {occ.raw_value for sense in normalized.senses for occ in sense.occurrences}
    assert "緊迫" in texts and "jǐnpò" not in texts


def test_adapter_drops_pinyin_equivalent_when_headword_is_not_chinese():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zhs-ja.Crown", "e", "もう", "もう", None,
        "jpn-to-cmn-Hans", "a" * 64,
        senses=(StagedSense("s", 1, equivalents=("快要…", "kuàiyào…", "是要来了", "kuàiyào lái le"), examples=()),),
    )
    normalized = adapter.normalize_entry(entry)
    texts = {occ.raw_value for sense in normalized.senses for occ in sense.occurrences}
    assert "快要…" in texts and "kuàiyào…" not in texts and "kuàiyào lái le" not in texts
    assert normalized.readings == ()


def test_adapter_classifies_crown_latin_gloss_as_english_after_dropping_pinyin():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zhs-ja.Crown", "e", "置き忘れる", "おきわすれる", None,
        "jpn-to-cmn-Hans", "a" * 64,
        senses=(StagedSense(
            "s", 1,
            equivalents=("遗失", "yíshī", "忘", "wàng", "mislay", "leave"),
            examples=(),
        ),),
    )
    normalized = adapter.normalize_entry(entry)
    occurrences = {
        occurrence.raw_value: occurrence
        for sense in normalized.senses
        for occurrence in sense.occurrences
    }
    assert occurrences["遗失"].lang_code == "cmn"
    assert occurrences["忘"].lang_code == "cmn"
    assert occurrences["mislay"].lang_code == "eng"
    assert occurrences["leave"].locale_code == "eng-Latn-US"
    assert "yíshī" not in occurrences and "wàng" not in occurrences


def test_adapter_corrects_crown_chinese_name_direction_from_pinyin_and_japanese_equivalent():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zhs-ja.Crown", "e", "马可・波罗", "马可・波罗", None,
        "jpn-to-cmn-Hans", "a" * 64,
        pronunciations=(_pronunciation(1, "1", "Mǎkě・Bōluó"),),
        senses=(StagedSense(
            "s", 1,
            equivalents=("マルコ・ポーロ．イタリアの商人・旅行家．",),
            examples=(),
        ),),
    )
    normalized = adapter.normalize_entry(entry)
    assert normalized.headword.lang_code == "cmn"
    assert normalized.headword.locale_code == "cmn-Hans-CN"
    equivalent = normalized.senses[0].occurrences[0]
    assert equivalent.lang_code == "jpn"
    assert [(r.scheme, r.value) for r in normalized.readings if not r.errors] == [
        ("pinyin", "Mǎkě・Bōluó")
    ]


def test_adapter_does_not_flip_japanese_entry_with_example_pinyin():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zhs-ja.Crown", "e", "挨拶", "あいさつ", None,
        "jpn-to-cmn-Hans", "a" * 64,
        pronunciations=(_pronunciation(1, "1", "nǐ hǎo"),),
        senses=(StagedSense("s", 1, equivalents=("问候",), examples=()),),
    )
    normalized = adapter.normalize_entry(entry)
    assert normalized.headword.lang_code == "jpn"


def test_adapter_classifies_numeric_scheme_pinyin_pronunciation_as_pinyin():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zhs-ja.Crown", "e", "AA制", "AA制", None,
        "cmn-Hans-to-jpn", "a" * 64,
        pronunciations=(_pronunciation(1, "1", "AA zhì"),),
    )
    published = [r for r in adapter.normalize_entry(entry).readings if not r.errors]
    assert [(r.scheme, r.locale_code, r.value) for r in published] == [("pinyin", "cmn-Hant-TW", "AA zhì")]


def test_adapter_folds_pinyin_equivalent_in_non_crown_bundle():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "com.apple.dictionary.zh_CN-en.OCD", "e", "切迫", "切迫", None,
        "cmn-Hant-to-eng", "a" * 64,
        pronunciations=(_pronunciation(1, "1", "AA zhì"),),
        senses=(StagedSense("s", 1, equivalents=("緊迫", "jǐnpò"), examples=()),),
    )
    normalized = adapter.normalize_entry(entry)
    texts = {occ.raw_value for sense in normalized.senses for occ in sense.occurrences}
    assert "jǐnpò" not in texts
    readings = [r for r in normalized.readings if not r.errors]
    assert [(r.scheme, r.value) for r in readings] == [("pinyin", "AA zhì"), ("pinyin", "jǐnpò")]


def test_adapter_accepts_chhoetaigi_language_hints_and_tailo_readings():
    adapter = TraditionalChineseEnglishAdapter()
    entry = StagedEntry(
        "r", "org.chhoetaigi.ChhoeTaigi_KamJitian", "e", "行", "行", None,
        "nan-to-eng", "a" * 64,
        pronunciations=(StagedPronunciation(1, "kiânn", "tailo", {"locale": "nan-Hant-CN"}),),
        senses=(StagedSense(
            "s", 1,
            equivalents=(
                {"value": "kiâⁿ", "language_hint": "nan-Hant-CN"},
                {"value": "go", "language_hint": "eng"},
                {"value": "行", "language_hint": "cmn-Hant"},
            ),
        ),),
    )

    normalized = adapter.normalize_entry(entry)
    occurrences = {
        occurrence.raw_value: occurrence
        for sense in normalized.senses
        for occurrence in sense.occurrences
    }

    assert occurrences["kiâⁿ"].lang_code == "nan"
    assert occurrences["kiâⁿ"].locale_code == "nan-Hant-CN"
    assert occurrences["go"].locale_code == "eng-Latn-US"
    assert occurrences["行"].locale_code == "cmn-Hant-TW"
    assert [(reading.scheme, reading.locale_code, reading.value) for reading in normalized.readings] == [
        ("tailo", "nan-Hant-CN", "kiânn")
    ]
