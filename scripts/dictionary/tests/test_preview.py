import json
from pathlib import Path

import pytest

from scripts.dictionary.langmap_dictionary.adapters.traditional_chinese_english import normalize_release
from scripts.dictionary.langmap_dictionary.clusters import build_explicit_clusters
from scripts.dictionary.langmap_dictionary.loader import load_jsonl_release
from scripts.dictionary.langmap_dictionary.preview import build_preview
from scripts.dictionary.langmap_dictionary.schema import create_staging_database

FIXTURE = Path(__file__).parent / "fixtures" / "traditional_chinese_english_v2.jsonl"


def test_preview_is_deterministic_and_contains_no_sql(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    release = load_jsonl_release(connection, [FIXTURE]).release_id
    normalize_release(connection, release)
    build_explicit_clusters(connection, release)
    output = tmp_path / "artifact"
    first = build_preview(connection, release, output)
    bytes_first = {path.name: path.read_bytes() for path in output.iterdir()}
    second = build_preview(connection, release, output)
    assert first == second
    assert bytes_first == {path.name: path.read_bytes() for path in output.iterdir()}
    assert not list(output.glob("*.sql"))
    bindings = [json.loads(line) for line in (output / "bindings.jsonl").read_text().splitlines()]
    assert all("definitions" not in item and "labels" not in item for item in bindings)


def test_preview_refuses_different_existing_artifact(tmp_path):
    connection = create_staging_database(tmp_path / "stage.sqlite")
    release = load_jsonl_release(connection, [FIXTURE]).release_id
    normalize_release(connection, release)
    build_explicit_clusters(connection, release)
    output = tmp_path / "artifact"
    build_preview(connection, release, output)
    (output / "manifest.json").write_text('{"manifest_hash":"different"}\n', encoding="utf-8")
    with pytest.raises(FileExistsError):
        build_preview(connection, release, output)
