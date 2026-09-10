from scripts.dictionary.langmap_dictionary.text_identity import canonicalize_expression_text


def test_sentence_cases_cased_scripts_without_rewriting_uncased_scripts():
    assert canonicalize_expression_text("  cafe\u0301  ") == "Café"
    assert canonicalize_expression_text("CLOSED") == "CLOSED"
    assert canonicalize_expression_text("UFO") == "UFO"
    assert canonicalize_expression_text("Closed") == "Closed"
    assert canonicalize_expression_text("i only eat Halal food") == "I only eat halal food"
    assert canonicalize_expression_text("廁所") == "廁所"


def test_sentence_case_preserves_inner_whitespace():
    assert canonicalize_expression_text("A  B\tc") == "A  b\tc"
