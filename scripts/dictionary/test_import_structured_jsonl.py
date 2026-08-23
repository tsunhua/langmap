from import_structured_jsonl import MESSAGE, main


def test_flat_importer_points_to_staging_workflow(capsys):
    assert main(["input.jsonl"]) == 2
    assert MESSAGE in capsys.readouterr().err
    assert "manage.py" in MESSAGE
