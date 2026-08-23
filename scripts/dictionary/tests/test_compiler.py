from pathlib import Path

from scripts.dictionary.langmap_dictionary.compiler import D1Inventory, build_expression_id, compile_release, expression_text_hash
from scripts.dictionary.langmap_dictionary.adapters.traditional_chinese_english import normalize_release
from scripts.dictionary.langmap_dictionary.clusters import build_explicit_clusters
from scripts.dictionary.langmap_dictionary.loader import load_jsonl_release
from scripts.dictionary.langmap_dictionary.schema import create_staging_database


def test_expression_identity_matches_worker_vector():
    assert expression_text_hash("hello") == "ftze3os7wcrq4jxihmvmlopcty"
    assert build_expression_id("eng", "hello", 2).endswith(".2")


def test_compile_is_deterministic_and_allocates_homographs(tmp_path: Path):
    fixture = Path(__file__).parent / "fixtures" / "traditional_chinese_english_v2.jsonl"
    connection = create_staging_database(tmp_path / "stage.sqlite")
    summary = load_jsonl_release(connection, [fixture])
    normalize_release(connection, summary.release_id)
    build_explicit_clusters(connection, summary.release_id)
    first = compile_release(connection, summary.release_id, D1Inventory(), tmp_path / "artifact")
    assert first.chunks == 1
    assert first.artifact.manifest_hash
    assert len(first.artifact.chunks) == 1
    second = compile_release(connection, summary.release_id, D1Inventory(), tmp_path / "artifact")
    assert first.artifact.manifest_hash == second.artifact.manifest_hash
