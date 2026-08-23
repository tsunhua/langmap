"""Deterministic lexical occurrence clusters; AI merging happens later."""

from __future__ import annotations

from .models import ClusterSummary


def build_explicit_clusters(connection, release_id: str) -> ClusterSummary:
    connection.execute("DELETE FROM cluster_members WHERE release_id=?", (release_id,))
    connection.execute("DELETE FROM lexical_clusters WHERE release_id=?", (release_id,))
    rows = connection.execute("SELECT * FROM lexical_occurrences WHERE release_id=? ORDER BY cluster_key, claim_key", (release_id,))
    seen: set[str] = set()
    occurrences = 0
    for row in rows:
        if row["cluster_key"] not in seen:
            connection.execute("INSERT INTO lexical_clusters VALUES (?,?,?,?,?)", (release_id, row["cluster_key"], row["occurrence_kind"], row["lang_code"], row["canonical_text"]))
            seen.add(row["cluster_key"])
        connection.execute("INSERT INTO cluster_members VALUES (?,?,?)", (release_id, row["cluster_key"], row["claim_key"]))
        occurrences += 1
    quarantined = connection.execute("SELECT COUNT(*) FROM quarantine_items WHERE release_id=?", (release_id,)).fetchone()[0]
    connection.commit()
    return ClusterSummary(release_id, len(seen), occurrences, quarantined)
