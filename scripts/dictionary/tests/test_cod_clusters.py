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
