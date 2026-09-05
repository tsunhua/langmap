from __future__ import annotations

import inspect
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from scripts.db.export_dictionary_delta import _iter_added_rows, export_delta


def _sha256(path: Path) -> str:
    import hashlib

    return hashlib.sha256(path.read_bytes()).hexdigest()


def _make_db(path: Path, *, extra: bool = False) -> None:
    connection = sqlite3.connect(path, timeout=60)
    connection.executescript(
        """
        CREATE TABLE sources (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, name TEXT NOT NULL, UNIQUE(type,name));
        CREATE TABLE languages (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE);
        CREATE TABLE language_locales (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE, language_id INTEGER NOT NULL, name TEXT NOT NULL);
        CREATE TABLE expressions (
          id INTEGER PRIMARY KEY AUTOINCREMENT, language_id INTEGER NOT NULL, text TEXT NOT NULL,
          homograph_index INTEGER NOT NULL DEFAULT 1, source_id INTEGER, created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(language_id, text, homograph_index));
        CREATE TABLE expression_sources (
          expression_id INTEGER NOT NULL, source_id INTEGER NOT NULL, source_marker TEXT NOT NULL DEFAULT '',
          PRIMARY KEY (expression_id, source_id, source_marker)) WITHOUT ROWID;
        CREATE TABLE expression_locale_links (expression_id INTEGER NOT NULL, locale_id INTEGER NOT NULL, PRIMARY KEY (expression_id, locale_id)) WITHOUT ROWID;
        CREATE TABLE expression_readings (
          expression_id INTEGER NOT NULL, locale_id INTEGER NOT NULL, scheme TEXT NOT NULL,
          value TEXT NOT NULL, source_id INTEGER, PRIMARY KEY (expression_id, locale_id, scheme, value)) WITHOUT ROWID;
        CREATE TABLE expression_edges (
          id INTEGER PRIMARY KEY AUTOINCREMENT, expression_a_id INTEGER NOT NULL, expression_b_id INTEGER NOT NULL,
          relation_mask INTEGER NOT NULL DEFAULT 1, score INTEGER NOT NULL DEFAULT 0,
          UNIQUE(expression_a_id, expression_b_id));
        CREATE TABLE expression_edge_sources (
          edge_id INTEGER NOT NULL, source_id INTEGER NOT NULL, source_marker TEXT NOT NULL DEFAULT '',
          PRIMARY KEY (edge_id, source_id, source_marker)) WITHOUT ROWID;
        """
    )
    connection.execute("INSERT INTO languages (code) VALUES ('eng'),('yue')")
    connection.execute("INSERT INTO language_locales (code, language_id, name) VALUES ('eng-Latn-US',1,'English')")
    connection.execute("INSERT INTO sources (type, name) VALUES ('system','seed')")
    connection.execute("INSERT INTO expressions (language_id, text, homograph_index, source_id) VALUES (1,'base',1,1)")
    connection.execute(
        "INSERT INTO expression_sources (expression_id, source_id, source_marker) VALUES (1,1,'')"
    )
    if extra:
        connection.execute("INSERT INTO sources (type, name) VALUES ('publication','com.example.dict')")
        connection.execute("INSERT INTO language_locales (code, language_id, name) VALUES ('yue-Hant-HK',2,'Cantonese')")
        connection.execute("INSERT INTO expressions (language_id, text, homograph_index, source_id) VALUES (2,'逮捕',1,2)")
        connection.execute(
            "INSERT INTO expression_sources (expression_id, source_id, source_marker) VALUES (2,2,'')"
        )
        connection.execute(
            "INSERT INTO expression_locale_links (expression_id, locale_id) VALUES (2,2)"
        )
        connection.execute(
            "INSERT INTO expression_readings (expression_id, locale_id, scheme, value, source_id) VALUES (2,2,'jyutping','daai⁶ bou³',2)"
        )
        connection.execute(
            "INSERT INTO expression_edges (expression_a_id, expression_b_id, relation_mask) VALUES (1,2,1)"
        )
        connection.execute("SELECT id FROM expression_edges WHERE expression_a_id=1")
        edge_id = connection.execute("SELECT id FROM expression_edges WHERE expression_a_id=1").fetchone()[0]
        connection.execute(
            "INSERT INTO expression_edge_sources (edge_id, source_id, source_marker) VALUES (?,2,'')",
            (edge_id,),
        )
    connection.commit()
    connection.close()


class ExportDeltaTests(unittest.TestCase):
    def test_added_rows_are_streamed_in_primary_key_order(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            before = root / "before.sqlite"
            after = root / "after.sqlite"
            _make_db(before)
            _make_db(after, extra=True)

            connection = sqlite3.connect(after)
            connection.row_factory = sqlite3.Row
            connection.execute("ATTACH DATABASE ? AS before_db", (str(before),))
            rows = _iter_added_rows(
                connection,
                "expressions",
                ["id"],
                ["id", "language_id", "text", "homograph_index", "source_id", "created_at"],
                limit=None,
            )

            self.assertTrue(inspect.isgenerator(rows))
            self.assertEqual([row["text"] for row in rows], ["逮捕"])
            connection.close()

    def test_delta_contains_only_new_rows_in_fk_order(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            before = root / "before.sqlite"
            after = root / "after.sqlite"
            output = root / "delta.sql"
            _make_db(before)
            _make_db(after, extra=True)
            counts = export_delta(before, after, output)
            self.assertEqual(
                counts,
                {
                    "sources": 1,
                    "language_locales": 1,
                    "expressions": 1,
                    "expression_sources": 1,
                    "expression_locale_links": 1,
                    "expression_readings": 1,
                    "expression_edges": 1,
                    "expression_edge_sources": 1,
                },
            )
            text = output.read_text(encoding="utf-8")
            self.assertIn('INSERT OR IGNORE INTO "sources"', text)
            # FK order: language_locales before expressions before edges
            self.assertLess(
                text.index('INSERT OR IGNORE INTO "language_locales"'),
                text.index('INSERT OR IGNORE INTO "expressions"'),
            )
            self.assertLess(
                text.index('INSERT OR IGNORE INTO "expressions"'),
                text.index('INSERT OR IGNORE INTO "expression_edges"'),
            )
            self.assertIn("'com.example.dict'", text)
            self.assertIn("'逮捕'", text)
            self.assertIn("'jyutping'", text)
            self.assertNotIn("'base'", text)

    def test_delta_writes_deterministic_postflight_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            before = root / "before.sqlite"
            after = root / "after.sqlite"
            output = root / "delta.sql"
            manifest = root / "manifest.json"
            _make_db(before)
            _make_db(after, extra=True)

            counts = export_delta(before, after, output, manifest=manifest)

            payload = json.loads(manifest.read_text(encoding="utf-8"))
            self.assertEqual(payload["added_counts"], counts)
            self.assertEqual(payload["before_counts"]["expressions"], 1)
            self.assertEqual(payload["after_counts"]["expressions"], 2)
            self.assertEqual(payload["before_sha256"], _sha256(before))
            self.assertEqual(payload["after_sha256"], _sha256(after))
            self.assertEqual(payload["samples"]["added"]["expressions"][0]["text"], "逮捕")
            self.assertEqual(payload["samples"]["after"]["expression_readings"][0]["scheme"], "jyutping")

    def test_empty_delta(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            before = root / "before.sqlite"
            after = root / "after.sqlite"
            output = root / "delta.sql"
            _make_db(before)
            _make_db(after)
            counts = export_delta(before, after, output)
            self.assertTrue(all(value == 0 for value in counts.values()))
            self.assertNotIn("INSERT OR IGNORE", output.read_text(encoding="utf-8"))

    def test_limit_truncates_per_table(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            before = root / "before.sqlite"
            after = root / "after.sqlite"
            output = root / "delta.sql"
            _make_db(before)
            _make_db(after, extra=True)
            counts = export_delta(before, after, output, limit=1)
            self.assertLessEqual(max(counts.values()), 1)

    def test_batches_rows_and_replays_the_delta(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            before = root / "before.sqlite"
            after = root / "after.sqlite"
            output = root / "delta.sql"
            _make_db(before)
            _make_db(after, extra=True)
            connection = sqlite3.connect(after)
            connection.executemany(
                "INSERT INTO expressions (language_id,text,homograph_index,source_id) VALUES (2,?,1,2)",
                [("詞二",), ("詞三",)],
            )
            connection.commit()
            connection.close()

            export_delta(before, after, output, rows_per_insert=2)
            text = output.read_text(encoding="utf-8")
            self.assertIn("),\n  (", text)
            self.assertEqual(text.count('INSERT OR IGNORE INTO "expressions"'), 2)

            replay = sqlite3.connect(before)
            replay.executescript(text)
            replay.commit()
            self.assertEqual(
                replay.execute("SELECT COUNT(*) FROM expressions").fetchone()[0],
                4,
            )
            replay.close()

    def test_rejects_non_positive_batch_size(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            before = root / "before.sqlite"
            after = root / "after.sqlite"
            output = root / "delta.sql"
            _make_db(before)
            _make_db(after)
            with self.assertRaisesRegex(ValueError, "rows_per_insert must be positive"):
                export_delta(before, after, output, rows_per_insert=0)


if __name__ == "__main__":
    unittest.main()
