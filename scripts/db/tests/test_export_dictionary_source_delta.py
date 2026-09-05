from __future__ import annotations

import json
import sqlite3
import tempfile
import unittest
from pathlib import Path

from scripts.db.export_dictionary_source_delta import export_source_delta


SCHEMA = """
PRAGMA foreign_keys=ON;
CREATE TABLE languages (id INTEGER PRIMARY KEY AUTOINCREMENT,code TEXT NOT NULL UNIQUE);
CREATE TABLE scripts (code TEXT PRIMARY KEY);
CREATE TABLE regions (code TEXT PRIMARY KEY);
CREATE TABLE sources (id INTEGER PRIMARY KEY AUTOINCREMENT,type TEXT NOT NULL,name TEXT NOT NULL,UNIQUE(type,name));
CREATE TABLE language_locales (id INTEGER PRIMARY KEY AUTOINCREMENT,code TEXT NOT NULL UNIQUE,language_id INTEGER NOT NULL,script_code TEXT,orthography TEXT,region_code TEXT,place_path TEXT NOT NULL DEFAULT '',name TEXT NOT NULL,name_en TEXT NOT NULL,name_expression_id INTEGER,latitude REAL,longitude REAL);
CREATE TABLE expressions (id INTEGER PRIMARY KEY AUTOINCREMENT,language_id INTEGER NOT NULL,text TEXT NOT NULL,homograph_index INTEGER NOT NULL DEFAULT 1,pos_mask INTEGER NOT NULL DEFAULT 0,source_id INTEGER,created_by INTEGER,created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,UNIQUE(language_id,text,homograph_index));
CREATE TABLE expression_sources (expression_id INTEGER NOT NULL,source_id INTEGER NOT NULL,source_marker TEXT NOT NULL DEFAULT '',PRIMARY KEY(expression_id,source_id,source_marker)) WITHOUT ROWID;
CREATE TABLE expression_locale_links (expression_id INTEGER NOT NULL,locale_id INTEGER NOT NULL,PRIMARY KEY(expression_id,locale_id)) WITHOUT ROWID;
CREATE TABLE expression_readings (expression_id INTEGER NOT NULL,locale_id INTEGER NOT NULL,scheme TEXT NOT NULL,value TEXT NOT NULL,source_id INTEGER,PRIMARY KEY(expression_id,locale_id,scheme,value)) WITHOUT ROWID;
CREATE TABLE expression_edges (id INTEGER PRIMARY KEY AUTOINCREMENT,expression_a_id INTEGER NOT NULL,expression_b_id INTEGER NOT NULL,relation_mask INTEGER NOT NULL DEFAULT 1,score INTEGER NOT NULL DEFAULT 0,created_by INTEGER,CHECK(expression_a_id<expression_b_id),UNIQUE(expression_a_id,expression_b_id));
CREATE TABLE expression_edge_sources (edge_id INTEGER NOT NULL,source_id INTEGER NOT NULL,source_marker TEXT NOT NULL DEFAULT '',PRIMARY KEY(edge_id,source_id,source_marker)) WITHOUT ROWID;
"""


def _base(path: Path, *, ids: tuple[int, int]) -> sqlite3.Connection:
    connection = sqlite3.connect(path)
    connection.executescript(SCHEMA)
    connection.execute("INSERT INTO languages(id,code) VALUES (?, 'eng'), (?, 'wuu')", ids)
    connection.execute("INSERT INTO scripts(code) VALUES ('Latn'),('Hant')")
    connection.execute("INSERT INTO regions(code) VALUES ('US'),('CN')")
    connection.execute("INSERT INTO language_locales(code,language_id,script_code,region_code,name,name_en) VALUES ('eng-Latn-US',?,'Latn','US','English','English')", (ids[0],))
    connection.commit()
    return connection


def _staging(path: Path) -> None:
    connection = _base(path, ids=(1818, 7108))
    connection.execute("INSERT INTO language_locales(id,code,language_id,script_code,region_code,place_path,name,name_en) VALUES (136,'wuu-Hant-CN_Shanghai',7108,'Hant','CN','Shanghai','上海話','Shanghai Wu')")
    connection.execute("INSERT INTO sources(id,type,name) VALUES (65,'publication','org.example.pott')")
    connection.execute("INSERT INTO expressions(id,language_id,text,source_id) VALUES (500,1818,'hello',65),(900,7108,'儂好',65)")
    connection.execute("INSERT INTO expression_sources VALUES (500,65,'1'),(900,65,'1')")
    connection.execute("INSERT INTO expression_locale_links VALUES (500,1),(900,136)")
    connection.execute("INSERT INTO expression_readings VALUES (900,136,'church','nong hau',65)")
    connection.execute("INSERT INTO expression_edges(id,expression_a_id,expression_b_id) VALUES (700,500,900)")
    connection.execute("INSERT INTO expression_edge_sources VALUES (700,65,'1')")
    connection.commit()
    connection.close()


class ExportDictionarySourceDeltaTests(unittest.TestCase):
    def test_release_resolves_production_ids_and_is_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            staging = root / "staging.sqlite"
            target = root / "target.sqlite"
            delta = root / "delta.sql"
            manifest = root / "manifest.json"
            _staging(staging)
            target_connection = _base(target, ids=(1, 2))
            target_connection.execute("INSERT INTO sources(id,type,name) VALUES (9,'system','seed')")
            target_connection.execute("INSERT INTO expressions(id,language_id,text,source_id) VALUES (42,1,'hello',9)")
            target_connection.commit()

            counts = export_source_delta(
                staging,
                delta,
                source_type="publication",
                source_name="org.example.pott",
                locale_codes=("eng-Latn-US", "wuu-Hant-CN_Shanghai"),
                manifest=manifest,
                rows_per_insert=1,
            )
            sql = delta.read_text(encoding="utf-8")
            target_connection.executescript(sql)
            target_connection.executescript(sql)

            source_id = target_connection.execute("SELECT id FROM sources WHERE name='org.example.pott'").fetchone()[0]
            self.assertNotEqual(source_id, 65)
            self.assertEqual(target_connection.execute("SELECT id FROM expressions WHERE text='hello'").fetchone()[0], 42)
            self.assertNotEqual(target_connection.execute("SELECT id FROM expressions WHERE text='儂好'").fetchone()[0], 900)
            self.assertEqual(target_connection.execute("SELECT COUNT(*) FROM expression_sources WHERE source_id=?", (source_id,)).fetchone()[0], 2)
            self.assertEqual(target_connection.execute("SELECT COUNT(*) FROM expression_edge_sources WHERE source_id=?", (source_id,)).fetchone()[0], 1)
            self.assertEqual(target_connection.execute("SELECT COUNT(*) FROM expression_readings WHERE source_id=?", (source_id,)).fetchone()[0], 1)
            self.assertEqual(counts["expression_locale_links"], 2)
            payload = json.loads(manifest.read_text(encoding="utf-8"))
            self.assertEqual(payload["expected_counts"], counts)
            self.assertEqual(payload["source"]["name"], "org.example.pott")
            target_connection.close()

    def test_requires_explicit_locales(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            staging = root / "staging.sqlite"
            _staging(staging)
            with self.assertRaisesRegex(ValueError, "locale code"):
                export_source_delta(
                    staging,
                    root / "delta.sql",
                    source_type="publication",
                    source_name="org.example.pott",
                    locale_codes=(),
                )


if __name__ == "__main__":
    unittest.main()
