"""Two-pass provider reconciliation and conservative complete-link clustering."""

from __future__ import annotations

import hashlib
import json
import sqlite3
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any, Mapping, Sequence

from .candidates import Candidate, generate_candidates
from .decision_schema import ReconciliationRequest, ReconciliationResponse
from .evaluation import auto_merge_enabled, evaluate_decisions
from .features import CandidateFeatures, CandidateKey
from .provider import ProviderError, ProviderRun, run_provider


def _canonical(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))


@dataclass(frozen=True)
class AcceptedPair:
    candidate_key: CandidateKey
    confidence_min: float
    decision_fingerprint: str


@dataclass(frozen=True)
class LexicalCluster:
    occurrence_keys: tuple[str, ...]
    cluster_key: str


@dataclass(frozen=True)
class ReconciliationDecision:
    candidate_key: CandidateKey
    decision: str
    reason_code: str
    confidence_min: float | None
    responses: tuple[ReconciliationResponse, ...]
    features_fingerprint: str


@dataclass(frozen=True)
class ReconciliationSummary:
    release_id: str
    candidates: tuple[Candidate, ...]
    decisions: tuple[ReconciliationDecision, ...]
    accepted_pairs: tuple[AcceptedPair, ...]
    clusters: tuple[LexicalCluster, ...]
    provider_runs: tuple[ProviderRun, ...]
    config_hash: str
    provider_error: str | None = None
    evaluation_gate_enabled: bool = False
    evaluation_gate_reasons: tuple[str, ...] = ()


def config_fingerprint(config: Mapping[str, Any]) -> str:
    return hashlib.sha256(_canonical(dict(config)).encode("utf-8")).hexdigest()


def _reverse_features(features: CandidateFeatures) -> CandidateFeatures:
    def rev(values: tuple[Any, ...]) -> tuple[Any, ...]:
        return tuple(reversed(values))
    return replace(
        features,
        left_definitions=rev(features.left_definitions), right_definitions=rev(features.right_definitions),
        left_labels=rev(features.left_labels), right_labels=rev(features.right_labels),
        left_examples=rev(features.left_examples), right_examples=rev(features.right_examples),
        left_equivalent_neighbors=rev(features.left_equivalent_neighbors), right_equivalent_neighbors=rev(features.right_equivalent_neighbors),
        left_raw_evidence_order=rev(features.left_raw_evidence_order), right_raw_evidence_order=rev(features.right_raw_evidence_order),
    )


def _requests(candidates: Sequence[Candidate], pass_id: int) -> tuple[ReconciliationRequest, ...]:
    return tuple(
        ReconciliationRequest(candidate.key, pass_id, ("left", "right") if pass_id == 1 else ("right", "left"), candidate.features if pass_id == 1 else _reverse_features(candidate.features))
        for candidate in candidates if not candidate.blockers
    )


def _decision_fingerprint(responses: Sequence[ReconciliationResponse], config_hash: str) -> str:
    payload = {"config_hash": config_hash, "responses": [item.to_dict() for item in responses]}
    return hashlib.sha256(_canonical(payload).encode("utf-8")).hexdigest()


def _accepted(candidate: Candidate, first: ReconciliationResponse, second: ReconciliationResponse, threshold: float, config_hash: str) -> tuple[AcceptedPair | None, str]:
    if first.decision != "merge" or second.decision != "merge":
        return None, "dual_pass_disagreement"
    if first.conflict_codes or second.conflict_codes:
        return None, "provider_conflict"
    threshold = max(0.98, threshold)
    if first.confidence < threshold or second.confidence < threshold:
        return None, "confidence_below_threshold"
    if len(set(first.evidence_codes)) < 2 or len(set(second.evidence_codes)) < 2:
        return None, "insufficient_evidence_codes"
    if (first.provider_id, first.model_id) != (second.provider_id, second.model_id):
        return None, "provider_identity_mismatch"
    return AcceptedPair(candidate.key, min(float(first.confidence), float(second.confidence)), _decision_fingerprint((first, second), config_hash)), "accepted"


def build_complete_link_clusters(
    occurrence_keys: Sequence[str], accepted_pairs: Sequence[AcceptedPair],
    explicit_groups: Sequence[Sequence[str]] = (),
) -> tuple[LexicalCluster, ...]:
    """Greedily build complete-link clusters in lexical order.

    A pair's acceptance is required for every cross-pair, so a transitive chain
    cannot silently join an unverified pair.
    """
    accepted = {frozenset((item.candidate_key.left_claim_key, item.candidate_key.right_claim_key)) for item in accepted_pairs}
    keys = sorted(set(occurrence_keys))
    groups = [tuple(sorted(set(group))) for group in explicit_groups if group]
    grouped: dict[str, tuple[str, ...]] = {member: group for group in groups for member in group}
    clusters: list[list[str]] = []
    for key in keys:
        unit = list(grouped.get(key, (key,)))
        if any(member in keys for member in unit if member != key):
            # The unit is handled when its lexically first member is visited.
            if key != min(unit):
                continue
            unit = sorted(set(unit) & set(keys))
        placed = False
        for cluster in clusters:
            # Members of one explicit group are already known to be the same
            # indivisible unit; only newly introduced cross-unit pairs need AI
            # acceptance.  Requiring an artificial self-pair here would make
            # every explicit group impossible to merge with another unit.
            cross_pairs_verified = all(
                (
                    grouped.get(left) is not None
                    and grouped.get(left) == grouped.get(right)
                )
                or frozenset((left, right)) in accepted
                for left in cluster
                for right in unit
                if left != right
            )
            if cross_pairs_verified:
                cluster.extend(item for item in unit if item not in cluster)
                placed = True
                break
        if not placed:
            clusters.append(unit)
    result: list[LexicalCluster] = []
    for cluster in clusters:
        members = tuple(sorted(set(cluster)))
        cluster_key = hashlib.sha256("\0".join(members).encode("utf-8")).hexdigest()[:32]
        result.append(LexicalCluster(members, cluster_key))
    return tuple(sorted(result, key=lambda item: item.occurrence_keys))


def _explicit_cluster_groups(
    connection: sqlite3.Connection, release_id: str,
) -> tuple[tuple[str, ...], ...]:
    """Return the existing entry-local groups as indivisible reconciliation units."""

    groups: dict[str, list[str]] = {}
    for row in connection.execute(
        "SELECT cluster_key,claim_key FROM cluster_members "
        "WHERE release_id=? ORDER BY cluster_key,claim_key",
        (release_id,),
    ):
        groups.setdefault(str(row[0]), []).append(str(row[1]))
    return tuple(tuple(members) for members in groups.values())


def _reconciled_cluster_key(members: Sequence[str], config_hash: str) -> str:
    """Version an AI-produced identity by the reconciliation policy."""

    payload = "reconciled\0" + config_hash + "\0" + "\0".join(sorted(set(members)))
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:32]


def build_reconciled_clusters(
    connection: sqlite3.Connection,
    release_id: str,
    occurrence_keys: Sequence[str],
    accepted_pairs: Sequence[AcceptedPair],
    config_hash: str,
) -> tuple[LexicalCluster, ...]:
    """Build final clusters while preserving explicit groups and versioning merges.

    Existing entry-local groups are passed as indivisible units.  A cluster that
    remains exactly the same keeps its original key, while a cluster changed by
    accepted AI pairs receives a deterministic key containing the config hash.
    This makes a reconciliation rerun auditable and prevents a policy change
    from silently reusing an old identity.
    """

    groups = _explicit_cluster_groups(connection, release_id)
    # Build the key map in one pass; SQLite group_concat ordering is not
    # portable, so retain the explicit row ordering in Python.
    explicit_by_key: dict[str, list[str]] = {}
    for row in connection.execute(
        "SELECT cluster_key,claim_key FROM cluster_members "
        "WHERE release_id=? ORDER BY cluster_key,claim_key",
        (release_id,),
    ):
        explicit_by_key.setdefault(str(row[0]), []).append(str(row[1]))
    explicit_keys = {
        tuple(sorted(members)): cluster_key
        for cluster_key, members in explicit_by_key.items()
    }
    raw = build_complete_link_clusters(occurrence_keys, accepted_pairs, groups)
    return tuple(
        LexicalCluster(
            item.occurrence_keys,
            explicit_keys.get(item.occurrence_keys)
            or _reconciled_cluster_key(item.occurrence_keys, config_hash),
        )
        for item in raw
    )


def apply_reconciled_clusters(
    connection: sqlite3.Connection,
    release_id: str,
    clusters: Sequence[LexicalCluster],
) -> None:
    """Replace staging clusters with the already-validated reconciliation result."""

    occurrence_rows: dict[str, sqlite3.Row] = {}
    for cluster in clusters:
        for claim_key in cluster.occurrence_keys:
            row = connection.execute(
                "SELECT occurrence_kind,lang_code,canonical_text "
                "FROM lexical_occurrences WHERE release_id=? AND claim_key=?",
                (release_id, claim_key),
            ).fetchone()
            if row is None:
                raise ValueError(f"reconciliation references unknown claim: {claim_key}")
            occurrence_rows[claim_key] = row

    connection.execute("DELETE FROM cluster_members WHERE release_id=?", (release_id,))
    connection.execute("DELETE FROM lexical_clusters WHERE release_id=?", (release_id,))
    for cluster in clusters:
        first = occurrence_rows[cluster.occurrence_keys[0]]
        connection.execute(
            "INSERT INTO lexical_clusters "
            "(release_id,cluster_key,occurrence_kind,lang_code,canonical_text) "
            "VALUES (?,?,?,?,?)",
            (
                release_id,
                cluster.cluster_key,
                first["occurrence_kind"],
                first["lang_code"],
                first["canonical_text"],
            ),
        )
        connection.executemany(
            "INSERT INTO cluster_members(release_id,cluster_key,claim_key) VALUES (?,?,?)",
            ((release_id, cluster.cluster_key, claim_key) for claim_key in cluster.occurrence_keys),
        )
        connection.executemany(
            "UPDATE lexical_occurrences SET cluster_key=? "
            "WHERE release_id=? AND claim_key=?",
            ((cluster.cluster_key, release_id, claim_key) for claim_key in cluster.occurrence_keys),
        )


def reconcile_release(
    connection: sqlite3.Connection,
    release_id: str,
    provider_command: Sequence[str],
    config: Mapping[str, Any],
    *,
    output_dir: Path | None = None,
    gold_rows: Sequence[Mapping[str, Any]] | None = None,
) -> ReconciliationSummary:
    candidates = generate_candidates(connection, release_id, int(config.get("max_candidate_group_size", 50))).candidates
    eligible = tuple(item for item in candidates if not item.blockers)
    config_hash = config_fingerprint(config)
    if not eligible:
        return ReconciliationSummary(release_id, candidates, (), (), (), (), config_hash)
    root = Path(output_dir or Path.cwd() / ".reconciliation-provider")
    root.mkdir(parents=True, exist_ok=True)
    timeout = float(config.get("provider_timeout_seconds", 1800))
    runs: list[ProviderRun] = []
    try:
        runs.append(run_provider(provider_command, _requests(eligible, 1), root / "pass-1", timeout, pass_id=1))
        runs.append(run_provider(provider_command, _requests(eligible, 2), root / "pass-2", timeout, pass_id=2))
    except ProviderError as error:
        decisions = tuple(ReconciliationDecision(item.key, "abstain", "provider_failure", None, (), item.features.features_fingerprint) for item in eligible)
        return ReconciliationSummary(release_id, candidates, decisions, (), (), tuple(runs), config_hash, str(error))
    first = {(item.candidate_key.left_claim_key, item.candidate_key.right_claim_key): item for item in runs[0].responses}
    second = {(item.candidate_key.left_claim_key, item.candidate_key.right_claim_key): item for item in runs[1].responses}
    threshold = float(config.get("auto_merge_threshold", 0.995))
    decisions: list[ReconciliationDecision] = []
    accepted: list[AcceptedPair] = []
    for candidate in eligible:
        key = (candidate.key.left_claim_key, candidate.key.right_claim_key)
        left, right = first[key], second[key]
        pair, reason = _accepted(candidate, left, right, threshold, config_hash)
        if pair:
            accepted.append(pair)
        decisions.append(ReconciliationDecision(candidate.key, "merge" if pair else "keep_separate", reason, pair.confidence_min if pair else min(left.confidence, right.confidence), (left, right), candidate.features.features_fingerprint))
    holdout = tuple(
        row for row in (gold_rows or ())
        if not row.get("split") or row.get("split") == "holdout"
    )
    gate_reasons: list[str] = []
    if not holdout:
        gate_reasons.append("evaluation_gold_missing")
    else:
        adapters = {
            str(row.get("adapter_id", "")): True
            for row in holdout
            if str(row.get("adapter_id", ""))
        }
        report = evaluate_decisions(holdout, decisions, config_hash=config_hash)
        gate = auto_merge_enabled(
            report,
            config_hash,
            adapters,
            minimum_holdout_auto_candidates=int(config.get("minimum_holdout_auto_candidates", 1000)),
            minimum_adapter_auto_candidates=int(config.get("minimum_adapter_auto_candidates", 50)),
            minimum_precision=float(config.get("minimum_precision", 0.995)),
            minimum_wilson_lower=float(config.get("minimum_wilson_lower", 0.99)),
        )
        gate_reasons.extend(gate.reasons)
    gate_enabled = not gate_reasons
    if not gate_enabled:
        accepted = []
        decisions = [
            replace(item, decision="keep_separate", reason_code="evaluation_gate:" + ",".join(gate_reasons))
            if item.decision == "merge" else item
            for item in decisions
        ]
    occurrence_keys = [row[0] for row in connection.execute("SELECT claim_key FROM lexical_occurrences WHERE release_id=? ORDER BY claim_key", (release_id,))]
    clusters = build_reconciled_clusters(connection, release_id, occurrence_keys, accepted, config_hash)
    return ReconciliationSummary(release_id, candidates, tuple(decisions), tuple(accepted), clusters, tuple(runs), config_hash, None, gate_enabled, tuple(gate_reasons))
