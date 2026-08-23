from scripts.dictionary.langmap_dictionary.evaluation import auto_merge_enabled, evaluate_decisions, wilson_interval


def test_wilson_boundary_cases():
    assert wilson_interval(0, 0) == (0.0, 0.0)
    assert wilson_interval(1000, 1000)[0] > 0.996
    assert wilson_interval(995, 1000)[0] < 0.99


def test_gate_requires_precision_and_holdout_volume():
    gold = [{"candidate_key": {"left_claim_key": f"a{i}", "right_claim_key": f"b{i}"}, "label": "merge", "adapter_id": "fixture"} for i in range(2)]
    decisions = [{"candidate_key": item["candidate_key"], "decision": "merge"} for item in gold]
    report = evaluate_decisions(gold, decisions, config_hash="cfg")
    result = auto_merge_enabled(report, "cfg", {"fixture"})
    assert not result.enabled
    assert "insufficient_holdout_auto_candidates" in result.reasons
