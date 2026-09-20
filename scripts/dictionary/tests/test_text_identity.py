import json
from pathlib import Path

import pytest

from scripts.dictionary.text_identity import (
    ExpressionTextIdentityError,
    canonicalize_expression_text,
)


CASES = json.loads(
    (Path(__file__).parent / "fixtures" / "expression_identity_cases.json").read_text(
        encoding="utf-8"
    )
)


@pytest.mark.parametrize("case", CASES, ids=lambda case: case["name"])
def test_shared_expression_identity_case(case):
    if "error" in case:
        with pytest.raises(ExpressionTextIdentityError) as raised:
            canonicalize_expression_text(case["input"])
        assert raised.value.code == case["error"]
    else:
        assert canonicalize_expression_text(case["input"]) == case["output"]


def test_apostrophe_between_letters_is_lexical_content():
    assert canonicalize_expression_text("don't") == "Don't"
