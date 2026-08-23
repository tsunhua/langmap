"""Bounded deterministic candidate generation and closed-set blockers."""

from __future__ import annotations

import sqlite3
from dataclasses import dataclass

from .features import CandidateFeatures, CandidateKey, build_features

BLOCKER_CODES = frozenset({
    "different_language", "different_text", "explicit_homograph_conflict",
    "pos_conflict", "fallback_identity_ambiguous", "published_identity_conflict",
    "insufficient_semantic_evidence", "candidate_group_too_large",
})


@dataclass(frozen=True)
class Candidate:
    key: CandidateKey
    features: CandidateFeatures
    blockers: tuple[str, ...] = ()

    @property
    def candidate_key(self) -> CandidateKey:
        return self.key


@dataclass(frozen=True)
class CandidateQuarantine:
    language_code: str | None
    canonical_text: str
    claim_keys: tuple[str, ...]
    error_code: str


@dataclass(frozen=True)
class CandidateSummary:
    candidates: tuple[Candidate, ...]
    quarantined: tuple[CandidateQuarantine, ...]

    @property
    def eligible(self) -> tuple[Candidate, ...]:
        return tuple(item for item in self.candidates if not item.blockers)

    @property
    def quarantine(self) -> tuple[CandidateQuarantine, ...]:
        return self.quarantined


def _pos_conflict(features: CandidateFeatures) -> bool:
    left, right = set(features.left_pos), set(features.right_pos)
    return bool(left and right and left.isdisjoint(right))


def deterministic_blockers(features: CandidateFeatures) -> tuple[str, ...]:
    blockers: set[str] = set()
    if not features.language_code:
        blockers.add("different_language")
    if any(code == "different_language" for code in features.completeness_codes):
        blockers.add("different_language")
    if "different_text" in features.completeness_codes:
        blockers.add("different_text")
    if (
        features.left_dictionary_key == features.right_dictionary_key
        and features.left_homograph_marker
        and features.right_homograph_marker
        and features.left_homograph_marker != features.right_homograph_marker
    ):
        blockers.add("explicit_homograph_conflict")
    if _pos_conflict(features):
        blockers.add("pos_conflict")
    if features.left_binding_ambiguous or features.right_binding_ambiguous:
        blockers.add("fallback_identity_ambiguous")
    if set(features.left_published_expression_ids) & set(features.right_published_expression_ids):
        pass
    elif features.left_published_expression_ids and features.right_published_expression_ids:
        blockers.add("published_identity_conflict")
    if (
        not features.left_definitions and not features.left_equivalent_neighbors and not features.left_examples
    ) or (
        not features.right_definitions and not features.right_equivalent_neighbors and not features.right_examples
    ):
        blockers.add("insufficient_semantic_evidence")
    return tuple(sorted(blockers))


def _occurrence_groups(connection: sqlite3.Connection, release_id: str) -> dict[tuple[str, str], list[str]]:
    groups: dict[tuple[str, str], list[str]] = {}
    rows = connection.execute(
        "SELECT claim_key,lang_code,canonical_text FROM lexical_occurrences "
        "WHERE release_id=? AND lang_code IS NOT NULL AND canonical_text <> '' "
        "AND errors_json='[]' ORDER BY lang_code,canonical_text,claim_key",
        (release_id,),
    )
    for row in rows:
        groups.setdefault((str(row["lang_code"]), str(row["canonical_text"])), []).append(str(row["claim_key"]))
    return groups


def generate_candidates(connection: sqlite3.Connection, release_id: str, max_group_size: int = 50) -> CandidateSummary:
    if max_group_size < 2:
        raise ValueError("max_group_size must be at least 2")
    candidates: list[Candidate] = []
    quarantined: list[CandidateQuarantine] = []
    for (language, text), claim_keys in _occurrence_groups(connection, release_id).items():
        if len(claim_keys) > max_group_size:
            quarantined.append(CandidateQuarantine(language, text, tuple(claim_keys), "candidate_group_too_large"))
            continue
        for index, left in enumerate(claim_keys):
            for right in claim_keys[index + 1:]:
                key = CandidateKey(left, right)
                features = build_features(connection, release_id, key)
                candidates.append(Candidate(key, features, deterministic_blockers(features)))
    candidates.sort(key=lambda item: item.key)
    quarantined.sort(key=lambda item: (item.language_code or "", item.canonical_text, item.claim_keys))
    return CandidateSummary(tuple(candidates), tuple(quarantined))
