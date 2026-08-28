from pathlib import Path

from scripts.dictionary.langmap_dictionary.adapters.traditional_chinese_english import normalize_release
from scripts.dictionary.langmap_dictionary.clusters import build_explicit_clusters
from scripts.dictionary.langmap_dictionary.loader import load_jsonl_release
from scripts.dictionary.langmap_dictionary.schema import create_staging_database

FIXTURE = Path(__file__).parent / "fixtures" / "traditional_chinese_english_v2.jsonl"


def test_cod_markers_produce_three_isolated_headword_clusters(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    release = load_jsonl_release(connection, [FIXTURE]).release_id
    normalize_release(connection, release)
    summary = build_explicit_clusters(connection, release)
    rows = connection.execute("SELECT cluster_key,canonical_text FROM lexical_clusters WHERE occurrence_kind='headword' ORDER BY cluster_key").fetchall()
    assert len(rows) == 3
    assert {row["canonical_text"] for row in rows} == {"cod"}
    assert {row["cluster_key"] for row in rows} == {"headword:fixture.traditional-english:cod-1:1", "headword:fixture.traditional-english:cod-2:2", "headword:fixture.traditional-english:cod-3:3"}
    assert summary.occurrences >= 3
    assert connection.execute("SELECT COUNT(*) FROM cluster_members WHERE cluster_key LIKE 'claim:%'").fetchone()[0] >= 4


def test_cluster_bulk_build_uses_insert_counts_and_reports_timings(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    release = load_jsonl_release(connection, [FIXTURE]).release_id
    normalize_release(connection, release)
    statements = []
    events = []
    timings = {}
    connection.set_trace_callback(statements.append)

    summary = build_explicit_clusters(
        connection,
        release,
        progress=events.append,
        defer_foreign_keys=True,
        timings=timings,
    )

    sql = [statement.upper().replace(" ", "") for statement in statements]
    assert not any("SELECTCOUNT(*)FROMLEXICAL_CLUSTERS" in statement for statement in sql)
    assert not any("SELECTCOUNT(*)FROMCLUSTER_MEMBERS" in statement for statement in sql)
    assert "PRAGMAFOREIGN_KEYS=OFF" in sql
    assert "PRAGMAFOREIGN_KEY_CHECK(CLUSTER_MEMBERS)" in sql
    assert "PRAGMAFOREIGN_KEYS=ON" in sql
    assert summary.clusters == connection.execute("SELECT COUNT(*) FROM lexical_clusters").fetchone()[0]
    assert summary.occurrences == connection.execute("SELECT COUNT(*) FROM cluster_members").fetchone()[0]
    assert events[-1]["step"] == "completed"
    assert set(timings) == {
        "cluster_cleanup",
        "cluster_clusters_insert",
        "cluster_members_insert",
        "cluster_foreign_key_check",
        "cluster_index",
        "cluster_commit",
    }
    assert connection.execute(
        "SELECT 1 FROM sqlite_master WHERE type='index' AND name='idx_clusters_text'"
    ).fetchone() is not None
