import json
from pathlib import Path
from unittest import mock

from scripts.db.lib.dictionary_release import ReleasePaths, activate_release, apply_release
from scripts.dictionary.langmap_dictionary.artifact import write_release_artifact


def test_activation_is_one_command_transaction(tmp_path: Path):
    root = tmp_path / "repo"
    (root / "backend").mkdir(parents=True)
    seen = []

    def fake_run(args, **kwargs):
        seen.append(tuple(args))
        return mock.Mock(stdout="", stderr="", returncode=0)

    with mock.patch("scripts.db.lib.dictionary_release.run_command", side_effect=fake_run):
        result = activate_release(ReleasePaths(root, root / "state"), "r1", wrangler_bin=Path("wrangler"))
    assert result["status"] == "activated"
    assert len(seen) == 1
    assert "BEGIN;" in seen[0][-1]
