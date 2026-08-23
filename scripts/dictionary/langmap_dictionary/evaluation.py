"""Holdout metrics and the fail-closed automatic-merge gate."""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from typing import Any, Iterable, Mapping


def wilson_interval(successes: int, total: int, z: float = 1.959963984540054) -> tuple[float, float]:
    if total == 0:
        return 0.0, 0.0
    if successes < 0 or successes > total or total < 0 or not math.isfinite(z) or z <= 0:
        raise ValueError("invalid Wilson interval inputs")
    p = successes / total
    denominator = 1 + z * z / total
    centre = (p + z * z / (2 * total)) / denominator
    radius = z * math.sqrt((p * (1 - p) + z * z / (4 * total)) / total) / denominator
    return max(0.0, centre - radius), min(1.0, centre + radius)


def _candidate_id(value: Any) -> tuple[str, str]:
    if isinstance(value, tuple) and len(value) == 2:
        return str(value[0]), str(value[1])
    if hasattr(value, "candidate_key"):
        key = value.candidate_key
        return key.left_claim_key, key.right_claim_key
    if isinstance(value, dict):
        key = value.get("candidate_key", value)
        if isinstance(key, dict):
            return str(key["left_claim_key"]), str(key["right_claim_key"])
    raise ValueError("invalid candidate key")


@dataclass(frozen=True)
class EvaluationReport:
    config_hash: str
    total_labels: int
    auto_path_labels: int
    true_positives: int
    false_positives: int
    true_negatives: int
    false_negatives: int
    precision: float
    recall: float
    wilson_lower: float
    wilson_upper: float
    blocker_violations: int = 0
    missing_decisions: int = 0
    adapter_counts: dict[str, int] = field(default_factory=dict)
    adapter_true_positives: dict[str, int] = field(default_factory=dict)
    enabled_adapters: tuple[str, ...] = ()

    @property
    def point_precision(self) -> float:
        return self.precision


@dataclass(frozen=True)
class GateResult:
    enabled: bool
    reasons: tuple[str, ...]
    report: EvaluationReport

    def __bool__(self) -> bool:
        return self.enabled


def evaluate_decisions(gold: Iterable[Mapping[str, Any]], decisions: Iterable[Any], *, config_hash: str = "") -> EvaluationReport:
    gold_rows = list(gold)
    decision_map = {_candidate_id(item): item for item in decisions}
    labels: dict[tuple[str, str], str] = {}
    adapters: dict[tuple[str, str], str] = {}
    for row in gold_rows:
        key = _candidate_id(row)
        if key in labels:
            raise ValueError(f"duplicate gold candidate: {key}")
        label = row.get("label")
        if label not in {"merge", "keep_separate"}:
            raise ValueError(f"invalid gold label for {key}")
        labels[key] = str(label)
        adapters[key] = str(row.get("adapter_id", ""))
    tp = fp = tn = fn = blocker_violations = missing = 0
    auto_path = 0
    adapter_counts: dict[str, int] = {}
    adapter_tp: dict[str, int] = {}
    for key, label in labels.items():
        decision = decision_map.get(key)
        if decision is None:
            missing += 1
            if label == "merge":
                fn += 1
            continue
        actual = getattr(decision, "decision", None)
        reason = getattr(decision, "reason_code", "")
        if isinstance(decision, dict):
            actual = decision.get("decision")
            reason = decision.get("reason_code", "")
        auto_path += 1
        if actual == "merge" and reason not in {"accepted", ""}:
            blocker_violations += 1
        adapter = adapters[key]
        adapter_counts[adapter] = adapter_counts.get(adapter, 0) + 1
        if actual == "merge" and label == "merge":
            tp += 1
            adapter_tp[adapter] = adapter_tp.get(adapter, 0) + 1
        elif actual == "merge":
            fp += 1
        elif label == "merge":
            fn += 1
        else:
            tn += 1
    auto_merges = tp + fp
    precision = tp / auto_merges if auto_merges else 0.0
    recall = tp / (tp + fn) if tp + fn else 0.0
    lower, upper = wilson_interval(tp, auto_merges)
    # A holdout label is eligible for the gate only when the corresponding
    # decision was actually on the automatic path.
    enabled = tuple(sorted(adapter for adapter, count in adapter_counts.items() if count >= 50))
    return EvaluationReport(config_hash, len(labels), auto_path, tp, fp, tn, fn, precision, recall, lower, upper, blocker_violations, missing, adapter_counts, adapter_tp, enabled)


def auto_merge_enabled(
    report: EvaluationReport,
    config_hash: str,
    adapters: Mapping[str, Any] | Iterable[str],
    *,
    minimum_holdout_auto_candidates: int = 1000,
    minimum_adapter_auto_candidates: int = 50,
    minimum_precision: float = 0.995,
    minimum_wilson_lower: float = 0.99,
) -> GateResult:
    reasons: list[str] = []
    if report.config_hash != config_hash:
        reasons.append("config_hash_mismatch")
    if report.auto_path_labels < minimum_holdout_auto_candidates:
        reasons.append("insufficient_holdout_auto_candidates")
    if not math.isfinite(report.precision) or report.precision < minimum_precision:
        reasons.append("precision_below_threshold")
    if not math.isfinite(report.wilson_lower) or report.wilson_lower < minimum_wilson_lower:
        reasons.append("wilson_lower_below_threshold")
    if report.blocker_violations:
        reasons.append("blocker_violations")
    configured = set(adapters.keys()) if isinstance(adapters, Mapping) else set(adapters)
    eligible_adapters = {adapter for adapter in configured if report.adapter_counts.get(adapter, 0) >= minimum_adapter_auto_candidates}
    enabled = tuple(sorted(eligible_adapters & set(report.enabled_adapters)))
    if not eligible_adapters:
        reasons.append("no_enabled_adapters")
    return GateResult(not reasons, tuple(reasons), report if enabled == report.enabled_adapters else EvaluationReport(report.config_hash, report.total_labels, report.auto_path_labels, report.true_positives, report.false_positives, report.true_negatives, report.false_negatives, report.precision, report.recall, report.wilson_lower, report.wilson_upper, report.blocker_violations, report.missing_decisions, report.adapter_counts, report.adapter_true_positives, enabled))
