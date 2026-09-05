import json
import sqlite3
from pathlib import Path

from scripts.dictionary.repair_example_edges import (
    load_source_pairs,
    repair,
    repair_approved_unmatched_edges,
)


def _database(path: Path) -> None:
    connection = sqlite3.connect(path)
    connection.executescript(
        """
        CREATE TABLE languages (id INTEGER PRIMARY KEY, code TEXT NOT NULL UNIQUE);
        CREATE TABLE sources (id INTEGER PRIMARY KEY, name TEXT NOT NULL UNIQUE);
        CREATE TABLE expressions (id INTEGER PRIMARY KEY, language_id INTEGER NOT NULL, text TEXT NOT NULL);
        CREATE TABLE expression_edges (
          id INTEGER PRIMARY KEY, expression_a_id INTEGER NOT NULL, expression_b_id INTEGER NOT NULL,
          relation_mask INTEGER NOT NULL, score INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE expression_edge_sources (
          edge_id INTEGER NOT NULL, source_id INTEGER NOT NULL, source_marker TEXT NOT NULL DEFAULT '',
          PRIMARY KEY (edge_id, source_id, source_marker)
        ) WITHOUT ROWID;
        INSERT INTO languages VALUES (1, 'eng'), (2, 'cmn');
        INSERT INTO sources VALUES (28, 'fixture.dictionary'), (29, 'other.dictionary');
        INSERT INTO expressions VALUES
          (1, 1, 'star'), (2, 2, '星'),
          (3, 1, 'what do my stars say?'), (4, 2, '我的星象怎么样？'),
          (5, 1, 'stale example'), (6, 2, '过期例句'),
          (7, 1, 'shared example'), (8, 2, '共享例句');
        INSERT INTO expression_edges VALUES
          (10, 1, 2, 1, 0), (11, 3, 4, 1, 0), (12, 5, 6, 1, 0), (13, 7, 8, 1, 0), (14, 1, 4, 1, 0);
        INSERT INTO expression_edge_sources VALUES
          (10, 28, ''), (11, 28, ''), (12, 28, ''), (13, 28, ''), (13, 29, ''), (14, 28, '');
        """
    )
    connection.commit()
    connection.close()


def _jsonl(path: Path) -> None:
    records = [
        {
            "record_type": "dictionary",
            "schema_version": 2,
            "dictionary_key": "fixture.dictionary",
            "entry_count": 1,
        },
        {
            "record_type": "entry",
            "schema_version": 2,
            "dictionary_key": "fixture.dictionary",
            "entry_key": "star",
            "canonical_headword": "star",
            "direction_hint": "eng-to-cmn-Hans",
            "senses": [
                {
                    "equivalents": ["星"],
                    "examples": [
                        {"text": "what do my stars say?", "translation": "我的星象怎么样？"},
                        {"text": "shared example", "translation": "共享例句"},
                    ],
                }
            ],
        },
    ]
    path.write_text("\n".join(json.dumps(item, ensure_ascii=False) for item in records) + "\n", encoding="utf-8")


def test_source_pairs_keep_examples_distinct_from_equivalents(tmp_path: Path):
    source = tmp_path / "source.jsonl"
    _jsonl(source)

    equivalents, examples, polluted_examples, header = load_source_pairs(source)

    assert header["dictionary_key"] == "fixture.dictionary"
    assert (("cmn", "星"), ("eng", "star")) in equivalents
    assert (("cmn", "我的星象怎么样？"), ("eng", "what do my stars say?")) in examples
    assert (("cmn", "我的星象怎么样？"), ("eng", "what do my stars say?")) not in equivalents
    assert (("cmn", "我的星象怎么样？"), ("eng", "star")) in polluted_examples


def test_repair_retypes_examples_and_removes_stale_source_claims(tmp_path: Path):
    source = tmp_path / "source.jsonl"
    mirror = tmp_path / "mirror.sqlite"
    output = tmp_path / "repair.split.sql"
    report = tmp_path / "repair.report.json"
    _jsonl(source)
    _database(mirror)

    result = repair(source, mirror, output, report)
    connection = sqlite3.connect(mirror)
    connection.executescript(output.read_text(encoding="utf-8"))

    assert connection.execute("SELECT relation_mask FROM expression_edges WHERE id=10").fetchone()[0] == 1
    assert connection.execute("SELECT relation_mask FROM expression_edges WHERE id=11").fetchone()[0] == 4
    assert connection.execute("SELECT relation_mask FROM expression_edges WHERE id=13").fetchone()[0] == 5
    assert connection.execute("SELECT COUNT(*) FROM expression_edges WHERE id=12").fetchone()[0] == 1
    assert connection.execute("SELECT COUNT(*) FROM expression_edges WHERE id=14").fetchone()[0] == 0
    assert connection.execute("SELECT COUNT(*) FROM expression_edge_sources WHERE source_id=28 AND edge_id=14").fetchone()[0] == 0
    connection.close()

    assert result["example_source_only_edge_count"] == 1
    assert result["example_shared_edge_count"] == 1
    assert result["polluted_edge_count"] == 1
    assert result["unmatched_edge_count"] == 1
    assert json.loads(report.read_text(encoding="utf-8"))["polluted_source_claim_count"] == 1


def test_repair_can_remove_explicitly_approved_unmatched_claim(tmp_path: Path):
    source = tmp_path / "source.jsonl"
    mirror = tmp_path / "mirror.sqlite"
    output = tmp_path / "repair.split.sql"
    report = tmp_path / "repair.report.json"
    _jsonl(source)
    _database(mirror)

    result = repair(
        source,
        mirror,
        output,
        report,
        remove_unmatched_edges=[12],
    )
    connection = sqlite3.connect(mirror)
    connection.executescript(output.read_text(encoding="utf-8"))

    assert connection.execute("SELECT COUNT(*) FROM expression_edges WHERE id=12").fetchone()[0] == 0
    assert connection.execute("SELECT COUNT(*) FROM expression_edge_sources WHERE edge_id=12").fetchone()[0] == 0
    connection.close()

    assert result["approved_unmatched_edge_count"] == 1
    assert result["unmatched_edge_count"] == 0
    assert json.loads(report.read_text(encoding="utf-8"))["approved_unmatched_edges"][0]["edge_id"] == 12


def test_targeted_repair_checks_only_approved_edge_claims(tmp_path: Path):
    source = tmp_path / "source.jsonl"
    mirror = tmp_path / "mirror.sqlite"
    output = tmp_path / "repair.split.sql"
    report = tmp_path / "repair.report.json"
    _jsonl(source)
    _database(mirror)

    result = repair_approved_unmatched_edges(source, mirror, output, report, [12])
    connection = sqlite3.connect(mirror)
    connection.executescript(output.read_text(encoding="utf-8"))

    assert connection.execute("SELECT COUNT(*) FROM expression_edges WHERE id=12").fetchone()[0] == 0
    connection.close()
    assert result["approval_mode"] == "explicit-unmatched-edge"
    assert result["source_claims_not_scanned"] is True
    assert result["approved_unmatched_edges"][0]["edge_id"] == 12
    assert "Explicitly approved unmatched" in output.read_text(encoding="utf-8")
