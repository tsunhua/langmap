from scripts.dictionary.langmap_dictionary.expression_surface import (
    extract_mapping_annotation,
    extract_reading_parentheses,
    normalize_expression_surface,
    prepare_paired_expression_values,
    prepare_expression_value,
    surface_errors,
    split_expression_alternatives,
)


def test_splits_top_level_slash_alternatives_and_keeps_sentence_punctuation():
    assert split_expression_alternatives("Hello!/i say!/hey!") == (
        "Hello!",
        "i say!",
        "hey!",
    )


def test_splits_internal_sentence_boundaries_into_separate_expressions():
    assert split_expression_alternatives("Hello! I say! Hey?") == (
        "Hello!",
        "I say!",
        "Hey?",
    )


def test_does_not_split_sentence_punctuation_inside_curly_quotes():
    assert split_expression_alternatives("狗“汪汪！”地叫了起来") == (
        "狗“汪汪！”地叫了起来",
    )


def test_keeps_periods_inside_ascii_abbreviations_together():
    assert split_expression_alternatives("A.A.") == ("A.A",)


def test_keeps_ipa_slash_pair_as_reading_not_expression_alternatives():
    assert split_expression_alternatives("/ˈbo.ɐ ˈtaɾ.dɨ/") == (
        "/ˈbo.ɐ ˈtaɾ.dɨ/",
    )


def test_keeps_slashes_inside_parentheses_and_brackets():
    assert split_expression_alternatives("word (formal/informal) [a/b]") == (
        "word (formal/informal) [a/b]",
    )


def test_expands_cjk_parenthetical_alternative_but_not_prose_note():
    assert split_expression_alternatives("你（們）好") == ("你好", "你們好")
    assert split_expression_alternatives("Hello (only on the telephone)") == (
        "Hello (only on the telephone)",
    )


def test_extracts_ipa_from_parenthetical_shell():
    assert extract_reading_parentheses("Boa tarde (, /ˈbo.ɐ ˈtaɾ.dɨ/)") == (
        "Boa tarde",
        ("ˈbo.ɐ ˈtaɾ.dɨ",),
    )


def test_extracts_plain_respelling_from_parenthetical_shell():
    assert extract_reading_parentheses("Đóng cửa (dauung-kưə)") == (
        "Đóng cửa",
        ("dauung-kưə",),
    )


def test_drops_empty_parenthetical_shell_and_placeholder_alternatives():
    assert extract_mapping_annotation("¡PRECAUCIÓN! (/)") == ("¡PRECAUCIÓN!", None)
    assert split_expression_alternatives("Toilet [] / [] / []") == ("Toilet",)


def test_paired_examples_align_dialogue_turns_before_sentence_splitting():
    left = "¡hombre! ¿tú por aquí? — ya ves, no tenía otra cosa que hacer"
    right = "hello, what are you doing here? — well, i didn't have anything else to do"
    prepared = prepare_paired_expression_values(left, right)
    assert prepared[0] == ("¡hombre! ¿tú por aquí?", "ya ves, no tenía otra cosa que hacer")
    assert prepared[3] == ("hello, what are you doing here?", "well, i didn't have anything else to do")


def test_moves_grammatical_rewrite_after_arrow_to_mapping_annotation():
    assert prepare_expression_value(
        "She said, “I wish I had a car.”⇒She said she wished she had a car"
    ) == (
        ("She said, “I wish I had a car.”",),
        (),
        "rewrite: She said she wished she had a car",
    )


def test_does_not_guess_when_a_surface_contains_multiple_rewrite_arrows():
    value = "now⇒then⇒later"
    assert prepare_expression_value(value) == ((value,), (), None)


def test_keeps_literal_bracket_notation_in_explanatory_text():
    value = "square brackets ([ ])"
    assert normalize_expression_surface(value) == value
    assert surface_errors(value) == ()


def test_extracts_mapping_annotation_from_terminal_parentheses():
    assert extract_mapping_annotation("Hello (only on the telephone)") == (
        "Hello",
        "only on the telephone",
    )


def test_keeps_lexical_parenthetical_complements_in_the_expression():
    assert extract_mapping_annotation("intimidated (by)") == (
        "intimidated (by)",
        None,
    )
    assert extract_mapping_annotation("new kid (on the block)") == (
        "new kid (on the block)",
        None,
    )


def test_normalizes_orphan_terminal_punctuation_without_removing_question_or_exclamation():
    assert normalize_expression_surface("Hello ,") == "Hello"
    assert normalize_expression_surface("Good afternoon.") == "Good afternoon"
    assert normalize_expression_surface("Are you ready?") == "Are you ready?"
    assert normalize_expression_surface("Hey!") == "Hey!"
    assert normalize_expression_surface("— Yes, please") == "Yes, please"
    assert normalize_expression_surface("──好的，谢谢") == "好的，谢谢"


def test_does_not_guess_through_unbalanced_parentheses():
    value = "Hello (only on the telephone"
    assert split_expression_alternatives(value) == (value,)
    assert extract_mapping_annotation(value) == (value, None)


def test_reports_malformed_surface_and_reading_only_candidates():
    assert surface_errors("Hello (only on the telephone") == ("malformed_surface",)
    assert surface_errors("/ˈbo.ɐ ˈtaɾ.dɨ/") == ("reading_in_expression",)
    assert surface_errors("Push []") == ("placeholder_surface",)
    assert surface_errors("”地叫了起来") == ("leading_punctuation",)
    assert surface_errors("’") == ("punctuation_only",)
    assert surface_errors("¿Qué?") == ()
