from scripts.dictionary.langmap_dictionary.features import CandidateKey
from scripts.dictionary.langmap_dictionary.reconciliation import AcceptedPair, build_complete_link_clusters


def _pair(left, right):
    return AcceptedPair(CandidateKey(*sorted((left, right))), 0.999, "fingerprint")


def test_complete_link_does_not_follow_unverified_transitive_chain():
    clusters = build_complete_link_clusters(("a", "b", "c"), (_pair("a", "b"), _pair("b", "c")))
    assert [item.occurrence_keys for item in clusters] == [("a", "b"), ("c",)]


def test_complete_link_joins_only_when_all_pairs_are_accepted():
    clusters = build_complete_link_clusters(("a", "b", "c"), (_pair("a", "b"), _pair("a", "c"), _pair("b", "c")))
    assert clusters[0].occurrence_keys == ("a", "b", "c")
