import json
import sqlite3
import unittest
from pathlib import Path

from glottolog_import import read_languoids, validate_languoids, import_sqlite, release_manifest, verify_sha256, release_diff
from language_migration import validate_manifest

ROOT = Path(__file__).parent


class LanguageDataTests(unittest.TestCase):
    def test_fixture_validates_and_is_stably_sorted(self):
        rows = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        self.assertEqual([row.id for row in rows], ["glotto:abcd1234", "glotto:chao1238", "glotto:mand1415"])
        self.assertEqual(rows[1].parent_id, "glotto:abcd1234")

    def test_import_is_idempotent_and_retires_missing_release_rows(self):
        rows = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        db = sqlite3.connect(":memory:")
        db.executescript("CREATE TABLE languoids (id TEXT PRIMARY KEY, glottocode TEXT UNIQUE, preferred_name TEXT, level TEXT, iso639_3 TEXT, parent_id TEXT, latitude REAL, longitude REAL, status TEXT, source_version TEXT, updated_at TEXT);")
        self.assertEqual(import_sqlite(db, rows, {})["added"], 3)
        self.assertEqual(import_sqlite(db, rows, {})["unchanged"], 3)
        reduced = [row for row in rows if row.glottocode != "mand1415"]
        import_sqlite(db, reduced, {})
        self.assertEqual(db.execute("SELECT status FROM languoids WHERE id='glotto:mand1415'").fetchone()[0], "retired")

    def test_release_manifest_and_checksum_are_reproducible(self):
        source = ROOT / "fixtures/glottolog-mini.csv"
        digest = verify_sha256(source, None)
        manifest = release_manifest(read_languoids(source, "5.3"), "5.3", source, "https://glottolog.org/meta/downloads")
        self.assertEqual(manifest["sha256"], digest)
        self.assertEqual(manifest["source_file"], source.name)
        with self.assertRaises(ValueError):
            verify_sha256(source, "0" * 64)

    def test_release_diff_does_not_mutate_database(self):
        rows = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        db = sqlite3.connect(":memory:")
        db.executescript("CREATE TABLE languoids (id TEXT PRIMARY KEY, glottocode TEXT UNIQUE, preferred_name TEXT, level TEXT, iso639_3 TEXT, parent_id TEXT, latitude REAL, longitude REAL, status TEXT, source_version TEXT, updated_at TEXT);")
        self.assertEqual(release_diff(db, rows)["added"], 3)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM languoids").fetchone()[0], 0)

    def test_import_smoke_against_canonical_schema(self):
        schema = (ROOT.parent.parent / "backend" / "schema.sql").read_text(encoding="utf-8")
        db = sqlite3.connect(":memory:")
        db.execute("PRAGMA foreign_keys=ON")
        db.executescript(schema)
        rows = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        result = import_sqlite(db, rows, {"source_version": "5.3"})
        self.assertEqual(result["active"], 3)
        self.assertEqual(db.execute("SELECT COUNT(*) FROM languoids WHERE status='active'").fetchone()[0], 3)

    def test_migration_manifest_fails_unmapped_and_duplicate_targets(self):
        manifest = json.loads((ROOT / "fixtures/language-migration.json").read_text())
        self.assertEqual(validate_manifest(manifest, {"nan-x-cha", "en_US"}), [])
        self.assertTrue(validate_manifest(manifest, {"unknown"}))
        manifest["mappings"]["legacy"] = {"action": "keep", "canonical": "en"}
        self.assertTrue(any("duplicate canonical" in error for error in validate_manifest(manifest)))

    def test_parent_cycle_is_rejected(self):
        rows = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        bad = list(rows)
        bad[0] = bad[0].__class__(**{**bad[0].__dict__, "parent_id": bad[1].id})
        bad[1] = bad[1].__class__(**{**bad[1].__dict__, "parent_id": bad[0].id})
        with self.assertRaises(ValueError):
            validate_languoids(bad)


if __name__ == "__main__":
    unittest.main()
