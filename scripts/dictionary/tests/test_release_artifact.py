import json

import pytest

from scripts.dictionary.langmap_dictionary.artifact import load_artifact, write_release_artifact


def test_artifact_is_atomic_and_checksummed(tmp_path):
    output = tmp_path / "release"
    artifact = write_release_artifact(output, release_id="r1", metadata={"expected_counts": {"expressions": 1}}, files={"sql/00001.sql": b"BEGIN;\nCOMMIT;\n"}, chunks=("sql/00001.sql",))
    assert load_artifact(output).manifest_hash == artifact.manifest_hash
    (output / "sql/00001.sql").write_bytes(b"tampered")
    with pytest.raises(ValueError, match="checksum"):
        load_artifact(output)


def test_manifest_is_stable_json(tmp_path):
    output = tmp_path / "release"
    write_release_artifact(output, release_id="r1", metadata={}, files={"sql/00001.sql": b"SELECT 1;\n"}, chunks=("sql/00001.sql",))
    payload = json.loads((output / "manifest.json").read_text())
    assert payload["release_id"] == "r1"
    assert payload["chunks"][0]["path"] == "sql/00001.sql"
