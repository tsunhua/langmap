import json
from pathlib import Path

from scripts.dictionary.manage import main

FIXTURE = Path(__file__).parent / "fixtures" / "traditional_chinese_english_v2.jsonl"


def test_manage_cli_stage_preview_inspect(tmp_path, capsys):
    database = tmp_path / "stage.sqlite"
    assert main(["stage", str(FIXTURE), "--database", str(database)]) == 0
    staged = json.loads(capsys.readouterr().out)
    assert staged["staged_entries"] == 3
    assert main(["preview", "--database", str(database), "--release", staged["release_id"], "--output", str(tmp_path / "artifact")]) == 0
    assert (tmp_path / "artifact" / "manifest.json").is_file()
    assert main(["inspect", "--database", str(database), "--release", staged["release_id"]]) == 0
