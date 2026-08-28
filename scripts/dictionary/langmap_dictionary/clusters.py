"""Deterministic lexical occurrence clusters; AI merging happens later."""

from __future__ import annotations

import sqlite3
import time
from typing import Any, Callable

from .models import ClusterSummary


ProgressCallback = Callable[[dict[str, Any]], None]


def _timing_snapshot(timings: dict[str, float]) -> dict[str, float]:
    return {key: round(value, 3) for key, value in timings.items()}


def build_explicit_clusters(
    connection,
    release_id: str,
    *,
    progress: ProgressCallback | None = None,
    defer_foreign_keys: bool = False,
    timings: dict[str, float] | None = None,
) -> ClusterSummary:
    component_timings = timings if timings is not None else {}
    timing_keys = (
        "cluster_cleanup",
        "cluster_clusters_insert",
        "cluster_members_insert",
        "cluster_foreign_key_check",
        "cluster_index",
        "cluster_commit",
    )
    component_timings.update({key: 0.0 for key in timing_keys})

    def measure(key: str, operation):
        started = time.perf_counter()
        try:
            return operation()
        finally:
            component_timings[key] += time.perf_counter() - started

    def emit(step: str, processed: int = 0, *, status: str = "running") -> None:
        if progress is not None:
            progress({
                "phase": "cluster",
                "step": step,
                "processed": processed,
                "status": status,
                "timings": _timing_snapshot(component_timings),
            })

    foreign_keys_enabled = bool(connection.execute("PRAGMA foreign_keys").fetchone()[0])
    restore_foreign_keys = defer_foreign_keys and foreign_keys_enabled
    if restore_foreign_keys:
        connection.commit()
        connection.execute("PRAGMA foreign_keys = OFF")

    succeeded = False
    try:
        def cleanup() -> None:
            # Rebuild once after the bulk load instead of maintaining this
            # lookup index for every inserted cluster.
            connection.execute("DROP INDEX IF EXISTS idx_clusters_text")
            connection.execute("DELETE FROM cluster_members WHERE release_id=?", (release_id,))
            connection.execute("DELETE FROM lexical_clusters WHERE release_id=?", (release_id,))

        measure("cluster_cleanup", cleanup)
        emit("cleanup")

        clusters_cursor = measure(
            "cluster_clusters_insert",
            lambda: connection.execute(
                "INSERT OR IGNORE INTO lexical_clusters(release_id,cluster_key,occurrence_kind,lang_code,canonical_text) "
                "SELECT release_id,cluster_key,occurrence_kind,lang_code,canonical_text "
                "FROM lexical_occurrences NOT INDEXED WHERE release_id=?",
                (release_id,),
            ),
        )
        clusters = int(clusters_cursor.rowcount)
        emit("clusters", clusters)

        members_cursor = measure(
            "cluster_members_insert",
            lambda: connection.execute(
                "INSERT INTO cluster_members(release_id,cluster_key,claim_key) "
                "SELECT release_id,cluster_key,claim_key FROM lexical_occurrences NOT INDEXED WHERE release_id=?",
                (release_id,),
            ),
        )
        occurrences = int(members_cursor.rowcount)
        emit("members", occurrences)

        def check_foreign_keys() -> None:
            if not defer_foreign_keys:
                return
            violation = connection.execute("PRAGMA foreign_key_check(cluster_members)").fetchone()
            if violation is not None:
                raise sqlite3.IntegrityError(f"cluster foreign key violation: {tuple(violation)!r}")

        measure("cluster_foreign_key_check", check_foreign_keys)
        emit("foreign-key-check", occurrences)

        measure(
            "cluster_index",
            lambda: connection.execute(
                "CREATE INDEX IF NOT EXISTS idx_clusters_text "
                "ON lexical_clusters(release_id, lang_code, canonical_text)"
            ),
        )
        emit("index", clusters)

        quarantined = int(connection.execute(
            "SELECT COUNT(*) FROM quarantine_items WHERE release_id=?", (release_id,)
        ).fetchone()[0])
        measure("cluster_commit", connection.commit)
        succeeded = True
        for key in timing_keys:
            component_timings[key] = round(component_timings[key], 6)
        emit("completed", occurrences, status="completed")
        return ClusterSummary(release_id, clusters, occurrences, quarantined)
    finally:
        if not succeeded and connection.in_transaction:
            connection.rollback()
        if restore_foreign_keys:
            connection.execute("PRAGMA foreign_keys = ON")
