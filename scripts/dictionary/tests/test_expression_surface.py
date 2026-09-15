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
    assert split_expression_alternatives("咩（哶）都冇得咩（哶）") == (
        "咩都冇得咩",
        "咩都冇得咩哶",
        "咩哶都冇得咩",
        "咩哶都冇得咩哶",
    )
    assert split_expression_alternatives("wood （木）") == ("wood （木）",)
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


def test_cleans_quoted_dialogue_wrappers_and_mixed_quote_styles():
    assert split_expression_alternatives("'how are you?' — 'I'm good!'") == (
        "how are you?",
        "I'm good!",
    )
    assert split_expression_alternatives("’هل هو مُحِقٌّ؟‘ —’أَظُنُّ ذلك‘") == (
        "هل هو مُحِقٌّ؟",
        "أَظُنُّ ذلك",
    )
    assert prepare_expression_value("‘were you disappointed?' — ‘sort of’")[0] == (
        "were you disappointed?",
        "sort of",
    )


def test_removes_example_wrappers_and_leading_parenthetical_labels():
    assert prepare_expression_value("[A sample sentence]")[0] == ("A sample sentence",)
    assert prepare_expression_value("(public) health service") == (
        ("health service",),
        (),
        "public",
    )


def test_removes_long_leading_usage_groups_and_keeps_valid_alternatives():
    value = "[inform＋〈목〉＋that절/inform＋wh-절/inform＋wh- to do] 〈남에게〉 〈…이라고〉 알리다, 통고하다"
    assert prepare_expression_value(value)[0] == ("알리다, 통고하다",)
    assert surface_errors("！是你！") == ()
    assert surface_errors("B/-") == ()
    assert surface_errors("－투성이") == ()
    assert surface_errors("￠") == ()
    assert prepare_expression_value("(ال)كَثير من شَيْءٍ") == (
        ("كَثير من شَيْءٍ",),
        (),
        "ال",
    )


def test_does_not_treat_slash_glosses_or_apostrophe_forms_as_readings():
    assert extract_reading_parentheses("every one (of them/you/…)") == (
        "every one (of them/you/…)",
        (),
    )
    assert split_expression_alternatives("to drop one's 'H''s") == (
        "to drop one's 'H's",
    )
    assert surface_errors("#MeToo") == ()


def test_keeps_dotted_abbreviations_inside_sentence_surfaces():
    assert split_expression_alternatives("must we really get up at 5 a.m.?") == (
        "must we really get up at 5 a.m.?",
    )


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


def test_extracts_leading_dictionary_usage_groups_as_mapping_annotation():
    assert extract_mapping_annotation("《속담》 Birds of a feather flock together") == (
        "Birds of a feather flock together",
        "속담",
    )
    assert extract_mapping_annotation(
        "［keep＋〈목〉］ 〈남을 위해〉 〈…을〉 보존하다"
    ) == (
        "보존하다",
        "keep＋〈목〉；남을 위해；…을",
    )
    assert extract_mapping_annotation("[U] wooden tablet script") == (
        "wooden tablet script",
        "U",
    )
    assert extract_mapping_annotation("[a]one Kim/a man named Kim") == (
        "one Kim/a man named Kim",
        "a",
    )
    assert extract_mapping_annotation("[A sample sentence]") == (
        "A sample sentence",
        None,
    )


def test_metadata_only_surface_is_not_published_as_an_expression():
    assert prepare_expression_value("［obstetrician/gynecologist］") == (
        (),
        (),
        "obstetrician/gynecologist",
    )
    assert surface_errors("［obstetrician/gynecologist］") == ()


def test_extracts_fullwidth_leading_notes_after_usage_groups():
    assert extract_mapping_annotation(
        "［know＋to do］ （…하지 않으면 안 되는 것을） 알고 있다"
    ) == (
        "알고 있다",
        "know＋to do；하지 않으면 안 되는 것을",
    )


def test_extracts_nested_newace_usage_groups_and_bracketed_surfaces():
    assert extract_mapping_annotation("〈남을〉 〔…에(게)〕 향하게 하다〔to …〕") == (
        "향하게 하다〔to …〕",
        "남을；…에(게)",
    )
    assert extract_mapping_annotation("[You bet!] 《강한 긍정》 그렇고 말고") == (
        "You bet!",
        "강한 긍정；그렇고 말고",
    )
    assert surface_errors("[A of B] A분량의 B") == ()


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
    # Empty slots are removed while the lexical payload remains publishable.
    assert surface_errors("Push []") == ()
    assert surface_errors("[]") == ("placeholder_surface", "punctuation_only")
    assert surface_errors("(心胸)寬廣") == ()
    assert surface_errors("• Two heads are better than one.") == ()
    assert surface_errors("”地叫了起来") == ()
    assert surface_errors("’") == ("punctuation_only",)
    assert surface_errors("¿Qué?") == ()
    assert surface_errors("-backed") == ()
