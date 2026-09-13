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


def test_thai_target_first_row_keeps_target_language_and_reading() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[35697]
    result = parse_phrase_rows("===Basics===\n; เปิด (''pèrt'') : Open", profile, _sections())

    assert len(result.entries) == 1
    entry = result.entries[0]
    assert entry["raw_headword"] == "เปิด"
    assert entry["senses"][0]["equivalents"][0]["value"] == "Open"
    assert entry["pronunciations"][0]["value"] == "pèrt"
    assert entry["raw"]["row_orientation"] == "target-to-english"


def test_plain_target_respelling_is_separate_reading() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[37990]
    result = parse_phrase_rows("===Basics===\n; CLOSED : Đóng cửa (dauung-kưə)", profile, _sections())

    assert len(result.entries) == 1
    entry = result.entries[0]
    assert entry["raw_headword"] == "Đóng cửa"
    assert entry["pronunciations"] == [{
        "value": "dauung-kưə",
        "scheme": "wikivoyage-respelling",
        "locale": "vie-Latn-VN",
    }]


def test_cantonese_inline_reading_keeps_placeholder_slots_out_of_expression() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[5837]
    result = parse_phrase_rows(
        "===Directions===\n"
        "; Where are there a lot of_____ ? : 边度有好多_____呀？ Bīndouh yáuh hóudō _____ a?\n"
        "; Past the _____ : 过咗_____ Gwojó _____",
        profile,
        _sections(),
    )

    assert [(entry["raw_headword"], entry["pronunciations"][0]["value"]) for entry in result.entries] == [
        ("边度有好多_____呀？", "Bīndouh yáuh hóudō _____ a?"),
        ("过咗_____", "Gwojó _____"),
    ]


def test_cantonese_inline_reading_splits_pinned_lowercase_respelling() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[5837]
    result = parse_phrase_rows(
        "===Directions===\n"
        "; past the _____ : 过咗_____/過咗_____ gwojó _____",
        profile,
        _sections(),
    )

    assert [(entry["raw_headword"], entry["pronunciations"][0]["value"]) for entry in result.entries] == [
        ("过咗_____", "gwojó _____"),
        ("過咗_____", "gwojó _____"),
    ]


def test_cantonese_notes_and_multiple_readings_stay_out_of_headword() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[5837]
    result = parse_phrase_rows(
        "===Eating===\n"
        "; I want a dish containing _____. : 我要帶 _____ 嘅嘢食. Ngóh yiu daai _____ ge jè sik. (example: 帶檸檬嘅紅豆冰 red-bean ice with lemon)\n"
        "; (fresh) vegetables : (新鮮) 菜 (sānsīn) choi\n"
        "; coffee : 咖啡 gafē / go bī (in Malaysia, from Malay \"kopi\")\n"
        "===Problems===\n"
        "; I'll call the police. : 我会叫警察。/我會叫警察。 Ngóh wúih giu gíngchaat. (差佬 chāai lóu is in colloquial speech and this word is not vulgar.)",
        profile,
        _sections(),
    )

    by_headword = {entry["raw_headword"]: entry for entry in result.entries}
    food = by_headword["我要帶 _____ 嘅嘢食"]
    assert food["pronunciations"][0]["value"] == "Ngóh yiu daai _____ ge jè sik"
    assert food["raw"]["target_annotation"].startswith("example:")
    vegetables = by_headword["(新鮮) 菜"]
    assert [item["value"] for item in vegetables["pronunciations"]] == ["sānsīn", "choi"]
    coffee = by_headword["咖啡"]
    assert [item["value"] for item in coffee["pronunciations"]] == ["gafē", "go bī"]
    assert coffee["raw"]["target_annotation"] == 'in Malaysia, from Malay "kopi"'
    police = [entry for entry in result.entries if entry["raw_headword"] == "我会叫警察"][0]
    assert police["raw"]["target_annotation"].startswith("差佬")


def test_cantonese_inline_reading_can_follow_sentence_punctuation_without_space() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[5837]
    result = parse_phrase_rows(
        "===Emergencies===\n; I am innocent : 我係冤枉㗎！Ngóh hai yūn wong gaa!",
        profile,
        _sections(),
    )

    assert result.entries[0]["raw_headword"] == "我係冤枉㗎！"
    assert result.entries[0]["pronunciations"][0]["value"] == "Ngóh hai yūn wong gaa!"


def test_target_reading_shell_is_removed_from_surface() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[28280]
    result = parse_phrase_rows("===Basics===\n; CLOSED : Fechado (, /fɨ.ˈʃa.du/)", profile, _sections())

    assert result.entries[0]["raw_headword"] == "Fechado"
    assert result.entries[0]["pronunciations"][0]["value"] == "fɨ.ˈʃa.du"


def test_nested_respelling_parenthetical_keeps_ipa_reading() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[28280]
    result = parse_phrase_rows(
        "===Basics===\n; CLOSED : Fechado (''f(ih)-SHAH-doo'', /fɨ.ˈʃa.du/)",
        profile,
        _sections(),
    )

    assert result.entries[0]["raw_headword"] == "Fechado"
    assert [reading["value"] for reading in result.entries[0]["pronunciations"]] == ["fɨ.ˈʃa.du"]


def test_portuguese_gender_alternatives_are_clean_expression_rows() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[28280]
    result = parse_phrase_rows(
        "===Basics===\n"
        "; Fine, thank you. : Bem, obrigado. (masc.) / Bem, obrigada. (fem.) (''buhny'', /bɐ̃j/)\n"
        "; I'm lost. : Estou perdido. (masc.) / Estou perdida. (fem.) (''sh-TOH'', /ʃ.ˈto/)",
        profile,
        _sections(),
    )

    assert {entry["raw_headword"] for entry in result.entries} == {
        "Bem, obrigado",
        "Bem, obrigada",
        "Estou perdido",
        "Estou perdida",
    }
    assert all("masc" not in entry["raw_headword"] and "fem" not in entry["raw_headword"] for entry in result.entries)


def test_portuguese_spaced_alternatives_before_readings_are_split() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[28280]
    result = parse_phrase_rows(
        "===Basics===\n"
        "; I understand. : Compreendo. / Percebo. / Entendo. (''kohm-prih-EHN-doo'' / ''pihr-SIH-boo / ehn-TEHN-doo'', /kõ.pɾi.ˈẽ.du/, /pɨɾ.ˈse.bu/, /ẽ.ˈtẽ.du/)",
        profile,
        _sections(),
    )

    assert {entry["raw_headword"] for entry in result.entries} == {"Compreendo", "Percebo", "Entendo"}
    assert all("/" not in entry["raw_headword"] for entry in result.entries)


def test_portuguese_malformed_ipa_tail_is_a_reading_not_surface_text() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[28280]
    result = parse_phrase_rows(
        "===Food===\n"
        "; Can I look at the menu, please? : Posso ver a ementa, por favor? ''POH-soo'', /ˈpo.su ˈveɾ/)",
        profile,
        _sections(),
    )

    entry = result.entries[0]
    assert entry["raw_headword"] == "Posso ver a ementa, por favor?"
    assert {reading["value"] for reading in entry["pronunciations"]} >= {"POH-soo", "ˈpo.su ˈveɾ"}


def test_portuguese_unclosed_ipa_slash_is_a_reading_not_surface_text() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[28280]
    result = parse_phrase_rows(
        "===Food===\n"
        "; It was delicious. : Estava uma delícia. (''sh-TAH-vuh'', /ʃ.ˈta.vɐ)",
        profile,
        _sections(),
    )

    entry = result.entries[0]
    assert entry["raw_headword"] == "Estava uma delícia"
    assert {reading["value"] for reading in entry["pronunciations"]} >= {"sh-TAH-vuh", "ʃ.ˈta.vɐ"}


def test_portuguese_leading_ellipsis_is_layout_not_expression_text() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[28280]
    result = parse_phrase_rows(
        "===Lodging===\n; ...a bathroom? : ... Casa de banho (''KAH-zuh'')",
        profile,
        _sections(),
    )

    assert result.entries[0]["raw_headword"] == "Casa de banho"
    assert result.entries[0]["senses"][0]["equivalents"][0]["value"] == "a bathroom?"


def test_portuguese_sentence_punctuation_splits_target_phrases() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[28280]
    result = parse_phrase_rows(
        "===Emergencies===\n; Stop! Thief! : Pára! Ladrão! (''PAH-ruh'')",
        profile,
        _sections(),
    )

    assert [entry["raw_headword"] for entry in result.entries] == ["Pára!", "Ladrão!"]


def test_reading_first_chinese_row_uses_parenthetical_english_gloss() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[7357]
    result = parse_phrase_rows("===Eating===\n;''sī'': 丝 (絲) (shredded)", profile, _sections())

    assert [(entry["raw_headword"], entry["senses"][0]["equivalents"][0]["value"]) for entry in result.entries] == [
        ("丝", "shredded"),
        ("絲", "shredded"),
    ]
    assert all(entry["pronunciations"][0]["value"] == "sī" for entry in result.entries)
    assert all(entry["raw"]["row_orientation"] == "reading-to-target-gloss" for entry in result.entries)


def test_infobox_reading_markup_does_not_leak_into_english() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[7357]
    result = parse_phrase_rows(
        "===Lodging===\n{{infobox|Common signs|\n; 推 (推) : Push [''tuī'']\n; 饮水 (飲水) / 饮用水 (飲用水) : Drinking water [''yǐnshuǐ''] / [''yǐnyòngshuǐ'']}}",
        profile,
        _sections(),
    )

    assert [(entry["raw_headword"], entry["senses"][0]["equivalents"][0]["value"]) for entry in result.entries] == [
        ("推", "Push"),
        ("推", "Push"),
        ("饮水", "Drinking water"),
        ("飲水", "Drinking water"),
        ("饮用水", "Drinking water"),
        ("飲用水", "Drinking water"),
    ]


def test_chinese_grammar_example_does_not_promote_formula_to_english() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[7357]
    result = parse_phrase_rows(
        "===Going to the doctor===\n{{infobox|Asking a question in Chinese|\n; Verb/Adj. + 不 (不) ''bù'' + Verb/Adj. : Example - 好不好？ （好不好？）''hăo bù hăo?'' - Is that okay? / Are you all right? (literally - good not good?)\n}}",
        profile,
        _sections(),
    )

    assert len(result.entries) == 4
    assert {entry["raw_headword"] for entry in result.entries} == {"好不好？"}
    assert {entry["senses"][0]["equivalents"][0]["value"] for entry in result.entries} == {
        "Is that okay?",
        "Are you all right?",
    }
    assert all(
        not entry["raw_headword"].startswith("Example -")
        and not entry["senses"][0]["equivalents"][0]["value"].startswith("Verb")
        for entry in result.entries
    )


def test_chinese_positive_negative_pair_becomes_binary_question_phrase() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[7357]
    result = parse_phrase_rows(
        "===Problems===\n{{infobox|To be or not to be?|\n; To be or not to be: 是 (是) ''shì'', 不是 (不是) ''bú shì''\n}}",
        profile,
        _sections(),
    )

    assert len(result.entries) == 2
    assert {entry["raw_headword"] for entry in result.entries} == {"是不是"}
    assert {entry["senses"][0]["equivalents"][0]["value"] for entry in result.entries} == {
        "To be or not to be"
    }
    assert all(
        {reading["value"] for reading in entry["pronunciations"]} == {"shì bú shì"}
        for entry in result.entries
    )


def test_chinese_slash_target_pairs_each_locale_form_with_its_reading() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[7357]
    result = parse_phrase_rows(
        "===Lodging===\n{{infobox|Common signs|\n; 厕所 (廁所) / 洗手间  (洗手間) / 盥洗室 (盥洗室) : Toilet [''cèsuǒ''] / [''xǐshǒujiān''] / [''guànxǐshì'']\n}}",
        profile,
        _sections(),
    )

    assert len(result.entries) == 6
    assert {
        (entry["raw_headword"], entry["raw"]["target_locale_code"], entry["pronunciations"][0]["value"])
        for entry in result.entries
    } == {
        ("厕所", "cmn-Hans-CN", "cèsuǒ"),
        ("洗手间", "cmn-Hans-CN", "xǐshǒujiān"),
        ("盥洗室", "cmn-Hans-CN", "guànxǐshì"),
        ("廁所", "cmn-Hant-TW", "cèsuǒ"),
        ("洗手間", "cmn-Hant-TW", "xǐshǒujiān"),
        ("盥洗室", "cmn-Hant-TW", "guànxǐshì"),
    }


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


def test_two_line_chinese_definition_rows_are_imported() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[7357]
    result = parse_phrase_rows(
        "===Basics===\n;Yes, I've eaten.\n:已经吃了 (已經吃了) ''Yǐjīng chī le''",
        profile,
        _sections(),
    )

    assert [(entry["raw_headword"], entry["senses"][0]["equivalents"][0]["value"]) for entry in result.entries] == [
        ("已经吃了", "Yes, I've eaten"),
        ("已經吃了", "Yes, I've eaten"),
    ]
    assert all(entry["raw"]["wikitext_line"] == 2 for entry in result.entries)

    slash = parse_phrase_rows(
        "===Eating===\n; Takeout / take away\n: 打包 (打包) ''dǎ bāo'' / 外带 (外帶) ''wài dài''",
        profile,
        _sections(),
    )
    assert {entry["senses"][0]["equivalents"][0]["value"] for entry in slash.entries} == {"Takeout", "take away"}


def test_nested_sections_inherit_the_reviewed_parent_and_driving_maps_to_transport() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[7357]
    result = parse_phrase_rows(
        "===Transportation===\n====Bus and Train====\n; bus : 公交车 (公交車) ''gōng jiāo chē''\n====Directions====\n; street : 街 (街) ''jiē''\n====Taxi====\n; Taxi : 出租车 (出租車) ''chū zū chē''\n===Driving===\n; I want to rent a car. : 我想要租车。 (我想要租車。) ''wǒ xiǎngyào zūchē''",
        profile,
        _sections(),
    )

    values = [entry["senses"][0]["equivalents"][0]["value"] for entry in result.entries]
    assert values.count("bus") == 2
    assert values.count("street") == 2
    assert values.count("Taxi") == 2
    assert values.count("I want to rent a car") == 2
    assert {entry["raw"]["section_key"] for entry in result.entries if entry["senses"][0]["equivalents"][0]["value"] != "street"} == {"transport"}
    assert {entry["raw"]["section_key"] for entry in result.entries if entry["senses"][0]["equivalents"][0]["value"] == "street"} == {"directions"}


def test_spanish_regional_gender_row_drops_explanatory_prose() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[33822]
    result = parse_phrase_rows(
        "===Eating===\n; Excuse me, waiter/waitress? (getting attention of server'): ¡camarero/a! (''kah-mah-REH-roh/ah'') (Spain), ¡mesero/a! (''meh-SEH-roh/-rah'') (Latin America), ¡mozo/a! (''MOH-soh/sah'') (Argentina and Uruguay). In some places (e.g. Nicaragua) you may simply whistle or make a sssss ssssss sound to get the attention of a waitress/waiter",
        profile,
        _sections(),
    )

    targets = {entry["raw_headword"] for entry in result.entries}
    assert targets == {"¡camarero!", "¡camarera!", "¡mesero!", "¡mesera!", "¡mozo!", "¡moza!"}
    assert all("In some places" not in target and "waitress" not in target for target in targets)
    readings = {reading["value"] for entry in result.entries for reading in entry["pronunciations"]}
    assert "In some places" not in readings
    assert "ah" in readings and "-rah" in readings


def test_spanish_slash_target_drops_empty_reading_shell() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[33822]
    result = parse_phrase_rows(
        "===Transportation===\n; CAUTION/ATTENION : ¡PRECAUCIÓN!/¡ATENCIÓN! (''pray-caw-SYON''/''ah-ten-SYON'')",
        profile,
        _sections(),
    )

    assert [entry["raw_headword"] for entry in result.entries] == ["¡PRECAUCIÓN!", "¡ATENCIÓN!"]
    assert [entry["senses"][0]["equivalents"][0]["value"] for entry in result.entries] == ["Caution", "Attenion"]
    assert [entry["pronunciations"][0]["value"] for entry in result.entries] == [
        "pray-caw-SYON",
        "ah-ten-SYON",
    ]


def test_german_target_first_infobox_keeps_german_as_the_headword() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[12641]
    result = parse_phrase_rows(
        "===Basics===\n{{infobox|The right way to say yes|\n; Ja, ich esse gern Wurst. : Yes, I like eating sausages.\n}}",
        profile,
        _sections(),
    )

    assert len(result.entries) == 1
    entry = result.entries[0]
    assert entry["raw_headword"] == "Ja, ich esse gern Wurst"
    assert entry["senses"][0]["equivalents"][0]["value"] == "Yes, I like eating sausages"
    assert entry["raw"]["row_orientation"] == "target-to-english"


def test_all_caps_multiword_english_phrase_uses_sentence_case() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[33822]
    result = parse_phrase_rows(
        "===Transportation===\n; ONE WAY : SENTIDO ÚNICO",
        profile,
        _sections(),
    )

    assert result.entries[0]["senses"][0]["equivalents"][0]["value"] == "One way"


def test_inline_english_explanation_is_not_imported_as_chinese_reading() -> None:
    profile = load_page_catalog(ROOT / "page-catalog.json")[7357]
    result = parse_phrase_rows(
        "===Eating===\n; Excuse me, waiter? : 服务员！ (服務員！) ''fúwùyuán'' <br/> In Taiwan it is common to call a waitress using the term 小姐 ''xiǎojiě''",
        profile,
        _sections(),
    )

    assert {entry["raw_headword"] for entry in result.entries} == {"服务员！", "服務員！"}
    assert {
        tuple(reading["value"] for reading in entry["pronunciations"])
        for entry in result.entries
    } == {("fúwùyuán", "xiǎojiě")}


def test_target_metadata_does_not_leak_into_japanese_or_thai_headword() -> None:
    japanese = load_page_catalog(ROOT / "page-catalog.json")[16153]
    japanese_result = parse_phrase_rows(
        "===Transportation===\n; I want to rent a car. : レンタカーお願いします。 (''Rentakā (rent-a-car) onegaishimasu.'') 0:01",
        japanese,
        _sections(),
    )
    assert japanese_result.entries[0]["raw_headword"] == "レンタカーお願いします"
    assert "rent-a-car" not in japanese_result.entries[0]["raw_headword"]
    assert "0:01" not in japanese_result.entries[0]["raw_headword"]

    thai = load_page_catalog(ROOT / "page-catalog.json")[35697]
    thai_result = parse_phrase_rows(
        "===Basics===\n; Excuse me : น้องครับ (if the waiter looks younger than you)",
        thai,
        _sections(),
    )
    assert thai_result.entries[0]["raw_headword"] == "น้องครับ"
