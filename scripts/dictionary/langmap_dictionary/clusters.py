"""Deterministic lexical occurrence clusters; AI merging happens later."""

from __future__ import annotations

from .models import ClusterSummary


def build_explicit_clusters(connection, release_id: str) -> ClusterSummary:
    connection.execute("DELETE FROM cluster_members WHERE release_id=?", (release_id,))
    connection.execute("DELETE FROM lexical_clusters WHERE release_id=?", (release_id,))
    connection.execute(
        "INSERT OR IGNORE INTO lexical_clusters(release_id,cluster_key,occurrence_kind,lang_code,canonical_text) "
        "SELECT release_id,cluster_key,occurrence_kind,lang_code,canonical_text "
        "FROM lexical_occurrences NOT INDEXED WHERE release_id=?",
        (release_id,),
    )
    connection.execute(
        "INSERT INTO cluster_members(release_id,cluster_key,claim_key) "
        "SELECT release_id,cluster_key,claim_key FROM lexical_occurrences NOT INDEXED WHERE release_id=?",
        (release_id,),
    )
    clusters = int(connection.execute(
        "SELECT COUNT(*) FROM lexical_clusters WHERE release_id=?", (release_id,)
    ).fetchone()[0])
    occurrences = int(connection.execute(
        "SELECT COUNT(*) FROM cluster_members WHERE release_id=?", (release_id,)
    ).fetchone()[0])
    quarantined = connection.execute("SELECT COUNT(*) FROM quarantine_items WHERE release_id=?", (release_id,)).fetchone()[0]
    connection.commit()
    return ClusterSummary(release_id, clusters, occurrences, quarantined)
