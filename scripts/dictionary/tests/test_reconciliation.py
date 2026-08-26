from scripts.dictionary.langmap_dictionary.features import CandidateKey
from pathlib import Path
import sys

from scripts.dictionary.langmap_dictionary.adapters.traditional_chinese_english import normalize_release
from scripts.dictionary.langmap_dictionary.clusters import build_explicit_clusters
from scripts.dictionary.langmap_dictionary.loader import load_jsonl_release
from scripts.dictionary.langmap_dictionary.reconciliation import (
    AcceptedPair,
    build_complete_link_clusters,
    build_reconciled_clusters,
    reconcile_release,
)
from scripts.dictionary.langmap_dictionary.schema import create_staging_database


def _pair(left, right):
    return AcceptedPair(CandidateKey(*sorted((left, right))), 0.999, "fingerprint")


def test_complete_link_does_not_follow_unverified_transitive_chain():
    clusters = build_complete_link_clusters(("a", "b", "c"), (_pair("a", "b"), _pair("b", "c")))
    assert [item.occurrence_keys for item in clusters] == [("a", "b"), ("c",)]


def test_complete_link_joins_only_when_all_pairs_are_accepted():
    clusters = build_complete_link_clusters(("a", "b", "c"), (_pair("a", "b"), _pair("a", "c"), _pair("b", "c")))
    assert clusters[0].occurrence_keys == ("a", "b", "c")


def test_complete_link_treats_explicit_groups_as_indivisible_units():
    clusters = build_complete_link_clusters(
        ("a", "a2", "b"),
        (_pair("a", "b"), _pair("a2", "b")),
        explicit_groups=(("a", "a2"),),
    )
    assert clusters[0].occurrence_keys == ("a", "a2", "b")


def test_reconciled_clusters_preserve_explicit_key_and_version_ai_key(tmp_path):
    fixture = Path(__file__).parent / "fixtures" / "traditional_chinese_english_v2.jsonl"
    database = tmp_path / "staging.sqlite"
    connection = create_staging_database(database)
    release_id = load_jsonl_release(connection, [fixture]).release_id
    normalize_release(connection, release_id)
    build_explicit_clusters(connection, release_id)
    claims = [
        row[0]
        for row in connection.execute(
            "SELECT claim_key FROM lexical_occurrences "
            "WHERE release_id=? AND occurrence_kind='headword' AND canonical_text='cod' "
            "ORDER BY claim_key",
            (release_id,),
        )
    ]
    original_key = connection.execute(
        "SELECT cluster_key FROM cluster_members WHERE release_id=? AND claim_key=?",
        (release_id, claims[2]),
    ).fetchone()[0]
    clusters = build_reconciled_clusters(
        connection,
        release_id,
        [row[0] for row in connection.execute(
            "SELECT claim_key FROM lexical_occurrences WHERE release_id=? ORDER BY claim_key",
            (release_id,),
        )],
        (_pair(claims[0], claims[1]),),
        "config-hash",
    )
    merged = next(item for item in clusters if set(claims[:2]) <= set(item.occurrence_keys))
    unchanged = next(item for item in clusters if item.occurrence_keys == (claims[2],))
    assert merged.cluster_key != original_key
    assert unchanged.cluster_key == original_key


def test_reconcile_applies_only_when_holdout_gate_passes(tmp_path):
    database = tmp_path / "staging.sqlite"
    connection = create_staging_database(database)
    release_id = "release-gate"
    connection.execute(
        "INSERT INTO staging_releases(id,manifest_hash,schema_version,status) "
        "VALUES (?,?,1,'staged')",
        (release_id, "a" * 64),
    )
    for entry_key in ("e1", "e2"):
        connection.execute(
            "INSERT INTO input_entries "
            "(release_id,entry_key,dictionary_key,raw_headword,canonical_headword,"
            "homograph_marker,direction_hint,record_fingerprint,raw_json) "
            "VALUES (?,?,?,?,?,?,?,?,?)",
            (release_id, entry_key, "fixture", "foo", "foo", None, None, "b" * 64, "{}"),
        )
        sense_key = f"{entry_key}-s"
        connection.execute(
            "INSERT INTO input_senses "
            "(release_id,sense_key,entry_key,ordinal,definitions_json,pos_json,"
            "equivalents_json,relations_json,examples_json,labels_json,raw_json) "
            "VALUES (?,?,?,?,?,?,?,?,?,?,?)",
            (release_id, sense_key, entry_key, 1, '["same meaning"]', '[]', '["bar"]', '[]', '["example"]', '[]', '{}'),
        )
        connection.execute(
            "INSERT INTO lexical_occurrences "
            "(release_id,claim_key,occurrence_kind,entry_key,sense_key,raw_value,"
            "canonical_text,lang_code,locale_code,cluster_key,metadata_json,errors_json) "
            "VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
            (
                release_id,
                f"entry:{entry_key}:headword",
                "headword",
                entry_key,
                sense_key,
                "foo",
                "foo",
                "eng",
                "eng-Latn-US",
                f"headword:{entry_key}",
                '{"adapter_id":"fixture"}',
                "[]",
            ),
        )
    build_explicit_clusters(connection, release_id)
    config = {
        "auto_merge_threshold": 0.995,
        "max_candidate_group_size": 50,
        "provider_timeout_seconds": 20,
        "minimum_holdout_auto_candidates": 1,
        "minimum_adapter_auto_candidates": 1,
        "minimum_precision": 0.995,
        "minimum_wilson_lower": 0,
        "required_passes": 2,
    }
    gold = [{
        "candidate_key": {
            "left_claim_key": "entry:e1:headword",
            "right_claim_key": "entry:e2:headword",
        },
        "label": "merge",
        "adapter_id": "fixture",
        "split": "holdout",
    }]
    summary = reconcile_release(
        connection,
        release_id,
        [sys.executable, str(Path(__file__).parent / "fixtures" / "fake_ai_provider.py")],
        config,
        output_dir=tmp_path / "provider",
        gold_rows=gold,
    )
    assert summary.evaluation_gate_enabled is True
    assert len(summary.accepted_pairs) == 1
    assert summary.clusters[0].occurrence_keys == ("entry:e1:headword", "entry:e2:headword")
