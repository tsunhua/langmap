import sys
from pathlib import Path

import pytest

from scripts.dictionary.langmap_dictionary.decision_schema import ReconciliationRequest
from scripts.dictionary.langmap_dictionary.features import CandidateFeatures, CandidateKey
from scripts.dictionary.langmap_dictionary.provider import ProviderError, run_provider

FIXTURE = Path(__file__).parent / "fixtures" / "fake_ai_provider.py"


def _request():
    return ReconciliationRequest(CandidateKey("a", "b"), 1, ("left", "right"), CandidateFeatures("eng", "cod", "a", "b", left_definitions=("fish",), right_definitions=("fish",)))


def test_provider_uses_jsonl_and_checksums(tmp_path):
    result = run_provider([sys.executable, str(FIXTURE)], [_request()], tmp_path / "run", timeout_seconds=5)
    assert result.responses[0].decision == "merge"
    assert len(result.requests_sha256) == 64
    assert result.requests_path.read_text().endswith("\n")


def test_provider_rejects_malformed_output(tmp_path):
    with pytest.raises(ProviderError, match="invalid JSON"):
        run_provider([sys.executable, str(FIXTURE), "--mode", "malformed"], [_request()], tmp_path / "run", timeout_seconds=5)
