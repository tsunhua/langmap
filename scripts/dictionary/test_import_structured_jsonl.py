import json
from pathlib import Path

from import_structured_jsonl import clean_equivalent, collect_data, read_entries, render_sql, write_sql


def test_clean_equivalent_removes_leading_bullet_only():
    assert clean_equivalent("• Turn a deaf ear to") == ("Turn a deaf ear to", True)
    assert clean_equivalent("As deaf as a post.") == ("As deaf as a post.", False)


def test_read_and_collect_structured_entry(tmp_path: Path):
    path = tmp_path / "idioms.jsonl"
    path.write_text(
        "\n".join([
            json.dumps({"record_type": "dictionary", "dictionary": "fixture"}),
            json.dumps({
                "headword": "阿聾送殯",
                "pronunciations": [{"value": "ā lóng sòng bìn", "scheme": "UK_IPA solitary", "dialect": None}],
                "senses": [{"sense_id": 1, "equivalents": ["The deaf attends the funeral.", "• Turn a deaf ear to"]}],
                "record_type": "entry",
                "entry_id": "fixture-entry",
                "source_row": 8,
            }),
        ]) + "\n",
        encoding="utf-8",
    )

    data = collect_data(read_entries(path))

    assert data.entries == 1
    assert data.bullet_prefix_count == 1
    assert ("eng", "Turn a deaf ear to") in data.expressions
    assert all("• " not in text for _, text in data.expressions)
    assert data.pronunciation_count == 1
    assert len(data.edges) == 2


def test_render_sql_keeps_source_provenance_and_clean_text(tmp_path: Path):
    path = tmp_path / "fixture.jsonl"
    path.write_text(json.dumps({
        "headword": "阿聾送殯",
        "pronunciations": [{"value": "ā lóng sòng bìn", "scheme": "UK_IPA solitary"}],
        "senses": [{"sense_id": 1, "equivalents": ["• Turn a deaf ear to"]}],
        "record_type": "entry",
        "entry_id": "fixture-entry",
    }) + "\n", encoding="utf-8")
    data = collect_data(read_entries(path))

    sql = "\n".join(render_sql(
        data,
        source_id="fixture-source",
        source_name="Fixture dictionary",
        creator_email="dev@example.com",
    ))

    assert "'Turn a deaf ear to'" in sql
    assert "• " not in sql
    assert "entry:fixture-entry:sense:1:equivalent:1" in sql
    assert "fixture-source" in sql


def test_write_sql_removes_stale_chunks_for_same_output(tmp_path: Path):
    output = tmp_path / "import.sql"
    stale = tmp_path / "import-9999.sql"
    stale.write_text("stale", encoding="utf-8")

    write_sql(output, ["-- header", "PRAGMA foreign_keys = ON;", "SELECT 1;"], chunk_size=10)

    assert not stale.exists()
    assert output.exists()
