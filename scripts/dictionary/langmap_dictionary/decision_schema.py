"""Strict JSONL DTOs for reconciliation providers."""

from __future__ import annotations

import json
import math
from dataclasses import dataclass
from typing import Any

from .features import CandidateFeatures, CandidateKey

DECISIONS = frozenset({"merge", "keep_separate", "abstain"})
EVIDENCE_CODES = frozenset({
    "same_text", "same_language", "definition_overlap", "neighbor_overlap", "example_overlap",
    "label_compatibility", "pos_compatibility", "same_dictionary", "cross_dictionary",
})
CONFLICT_CODES = frozenset({
    "explicit_homograph_conflict", "pos_conflict", "published_identity_conflict",
    "fallback_identity_ambiguous", "insufficient_semantic_evidence", "different_language", "different_text",
})


def _strict_dict(value: Any, expected: set[str], label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be an object")
    unknown = set(value) - expected
    missing = expected - set(value)
    if unknown:
        raise ValueError(f"{label} has unknown fields: {', '.join(sorted(unknown))}")
    if missing:
        raise ValueError(f"{label} missing fields: {', '.join(sorted(missing))}")
    return value


@dataclass(frozen=True)
class ReconciliationRequest:
    candidate_key: CandidateKey
    pass_id: int
    evidence_order: tuple[str, ...]
    features: CandidateFeatures

    def __post_init__(self) -> None:
        if not isinstance(self.pass_id, int) or isinstance(self.pass_id, bool) or self.pass_id not in (1, 2):
            raise ValueError("pass_id must be 1 or 2")
        if not self.evidence_order or any(not isinstance(item, str) for item in self.evidence_order):
            raise ValueError("evidence_order must contain strings")

    def to_dict(self) -> dict[str, Any]:
        return {"candidate_key": self.candidate_key.to_dict(), "pass_id": self.pass_id,
                "evidence_order": list(self.evidence_order), "features": self.features.to_dict()}

    @classmethod
    def from_dict(cls, value: Any) -> "ReconciliationRequest":
        item = _strict_dict(value, {"candidate_key", "pass_id", "evidence_order", "features"}, "request")
        order = item["evidence_order"]
        if not isinstance(order, list):
            raise ValueError("request.evidence_order must be an array")
        return cls(CandidateKey.from_dict(item["candidate_key"]), item["pass_id"], tuple(order), CandidateFeatures.from_dict(item["features"]))


@dataclass(frozen=True)
class ReconciliationResponse:
    candidate_key: CandidateKey
    pass_id: int
    decision: str
    confidence: float
    evidence_codes: tuple[str, ...]
    conflict_codes: tuple[str, ...]
    summary: str
    provider_id: str
    model_id: str

    def __post_init__(self) -> None:
        if self.decision not in DECISIONS:
            raise ValueError(f"unknown decision: {self.decision}")
        if isinstance(self.confidence, bool) or not isinstance(self.confidence, (float, int)) or not math.isfinite(float(self.confidence)) or not 0 <= float(self.confidence) <= 1:
            raise ValueError("confidence must be finite and between 0 and 1")
        if self.pass_id not in (1, 2):
            raise ValueError("pass_id must be 1 or 2")
        if not isinstance(self.summary, str) or not isinstance(self.provider_id, str) or not isinstance(self.model_id, str) or not self.provider_id.strip() or not self.model_id.strip():
            raise ValueError("summary, provider_id and model_id must be strings")
        unknown_evidence = set(self.evidence_codes) - EVIDENCE_CODES
        unknown_conflict = set(self.conflict_codes) - CONFLICT_CODES
        if unknown_evidence:
            raise ValueError(f"unknown evidence codes: {', '.join(sorted(unknown_evidence))}")
        if unknown_conflict:
            raise ValueError(f"unknown conflict codes: {', '.join(sorted(unknown_conflict))}")

    def to_dict(self) -> dict[str, Any]:
        return {"candidate_key": self.candidate_key.to_dict(), "pass_id": self.pass_id,
                "decision": self.decision, "confidence": float(self.confidence),
                "evidence_codes": sorted(set(self.evidence_codes)), "conflict_codes": sorted(set(self.conflict_codes)),
                "summary": self.summary, "provider_id": self.provider_id, "model_id": self.model_id}

    @classmethod
    def from_dict(cls, value: Any) -> "ReconciliationResponse":
        item = _strict_dict(value, {"candidate_key", "pass_id", "decision", "confidence", "evidence_codes", "conflict_codes", "summary", "provider_id", "model_id"}, "response")
        if not isinstance(item["evidence_codes"], list) or not isinstance(item["conflict_codes"], list):
            raise ValueError("response code fields must be arrays")
        return cls(CandidateKey.from_dict(item["candidate_key"]), item["pass_id"], item["decision"], item["confidence"], tuple(sorted(set(item["evidence_codes"]))), tuple(sorted(set(item["conflict_codes"]))), item["summary"], item["provider_id"], item["model_id"])


def encode_jsonl(value: ReconciliationRequest | ReconciliationResponse) -> str:
    payload = value.to_dict()
    return json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


def decode_response(line: str, line_number: int = 1) -> ReconciliationResponse:
    try:
        value = json.loads(line)
    except json.JSONDecodeError as error:
        raise ValueError(f"response line {line_number}: invalid JSON: {error.msg}") from error
    try:
        return ReconciliationResponse.from_dict(value)
    except (TypeError, ValueError, KeyError) as error:
        raise ValueError(f"response line {line_number}: {error}") from error
