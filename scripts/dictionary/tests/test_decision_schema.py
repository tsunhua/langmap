import pytest

from scripts.dictionary.langmap_dictionary.decision_schema import ReconciliationResponse, decode_response
from scripts.dictionary.langmap_dictionary.features import CandidateKey


def _response(**changes):
    value = {"candidate_key": {"left_claim_key": "a", "right_claim_key": "b"}, "pass_id": 1, "decision": "merge", "confidence": 0.999, "evidence_codes": ["same_text", "definition_overlap"], "conflict_codes": [], "summary": "ok", "provider_id": "fake", "model_id": "m1"}
    value.update(changes)
    return value


def test_response_accepts_closed_enum_and_roundtrips():
    response = ReconciliationResponse.from_dict(_response())
    assert response.candidate_key == CandidateKey("a", "b")
    assert response.to_dict()["confidence"] == 0.999


@pytest.mark.parametrize("changes", [{"decision": "maybe"}, {"confidence": True}, {"confidence": 1.1}, {"bogus": 1}])
def test_response_rejects_unsafe_values(changes):
    with pytest.raises(ValueError):
        ReconciliationResponse.from_dict(_response(**changes))


def test_decode_reports_line_number():
    with pytest.raises(ValueError, match="line 7"):
        decode_response("not-json", 7)
