import json
from pathlib import Path
from unittest import mock

from scripts.db.lib.dictionary_release import ReleasePaths, apply_release
from scripts.dictionary.langmap_dictionary.artifact import write_release_artifact


def test_apply_resumes_after_checkpoint(tmp_path: Path):
    root = tmp_path / "repo"
    (root / "backend").mkdir(parents=True)
    artifact = write_release_artifact(root / "artifact", release_id="r1", metadata={}, files={"sql/00001.sql": b"SELECT 1;\n", "sql/00002.sql": b"SELECT 2;\n"}, chunks=("sql/00001.sql", "sql/00002.sql"))
    calls = []

    def fake_run(args, **kwargs):
        calls.append(tuple(args))
        if len(calls) == 1:
            raise RuntimeError("stop")
        return mock.Mock(stdout="", stderr="", returncode=0)

    with mock.patch("scripts.db.lib.dictionary_release.run_command", side_effect=fake_run):
        try:
            apply_release(ReleasePaths(root, root / "state"), artifact.manifest_path, wrangler_bin=Path("wrangler"))
        except RuntimeError:
            pass
        # A failed first command does not claim a completed chunk.
        result = apply_release(ReleasePaths(root, root / "state"), artifact.manifest_path, wrangler_bin=Path("wrangler"))
    assert result.completed_chunks == 2
    assert len(calls) == 3
