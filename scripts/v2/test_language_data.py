import csv
import json
import sqlite3
import unittest
from pathlib import Path

from glottolog_import import read_languoids, validate_languoids, import_sqlite, release_manifest, verify_sha256, release_diff
from language_migration import validate_manifest
from sync_language_registry import (
    canonical_case,
    canonical_seed_code,
    direction_for_script,
    parse_iana_registry,
    render_registry_sql,
    seed_language_rows,
    split_canonical_seed_code,
    write_languages,
)

ROOT = Path(__file__).parent


class LanguageDataTests(unittest.TestCase):
    def test_fixture_validates_and_is_stably_sorted(self):
        rows = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        self.assertEqual([row.id for row in rows], ["glotto:abcd1234", "glotto:chao1238", "glotto:mand1415"])
        self.assertEqual(rows[1].parent_id, "glotto:abcd1234")

    def test_official_glottolog_53_column_names_are_supported(self):
        source = ROOT / "fixtures/glottolog-official-columns.tmp.csv"
        source.write_text(
            "id,family_id,parent_id,name,level,latitude,longitude,iso639P3code\n"
            "root1234,,,Root,family,,,\n"
            "lang1234,root1234,,Language,language,1.2,3.4,abc\n",
            encoding="utf-8",
        )
        try:
            rows = read_languoids(source, "5.3")
            self.assertEqual(rows[1].glottocode, "lang1234")
            self.assertEqual(rows[1].iso639_3, "abc")
            self.assertEqual(rows[1].parent_id, "glotto:root1234")
        finally:
            source.unlink(missing_ok=True)

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
        manifest["mappings"]["legacy"] = {"action": "keep", "canonical": "en-US"}
        self.assertTrue(any("duplicate canonical" in error for error in validate_manifest(manifest)))

    def test_parent_cycle_is_rejected(self):
        rows = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        bad = list(rows)
        bad[0] = bad[0].__class__(**{**bad[0].__dict__, "parent_id": bad[1].id})
        bad[1] = bad[1].__class__(**{**bad[1].__dict__, "parent_id": bad[0].id})
        with self.assertRaises(ValueError):
            validate_languoids(bad)

    def test_iana_registry_parser_keeps_prefix_and_metadata(self):
        text = """File-Date: 2026-06-15
%%
Type: language
Subtag: sl
Description: Slovenian
Added: 2005-10-16
%%
Type: variant
Subtag: rozaj
Description: Resian
Added: 2006-12-01
Prefix: sl
%%
Type: region
Subtag: IT
Description: Italy
Added: 2005-10-16
"""
        file_date, rows = parse_iana_registry(text)
        self.assertEqual(file_date, "2026-06-15")
        variant = next(row for row in rows if row.type == "variant")
        self.assertEqual(variant.prefixes, ("sl",))

    def test_cartesian_writer_removes_partial_output_when_caller_handles_error(self):
        target = ROOT / "fixtures/languages-overflow.tmp.csv"
        try:
            with self.assertRaises(ValueError):
                write_languages(
                    target,
                    ({"code": str(index)} for index in range(2)),
                    1,
                )
        finally:
            target.unlink(missing_ok=True)

    def test_seed_profiles_are_the_only_generated_languages(self):
        languoids = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        _, subtags = parse_iana_registry("""File-Date: 2026-06-15
%%
Type: language
Subtag: nan
Description: Min Nan Chinese
Added: 2005-10-16
%%
Type: script
Subtag: Hant
Description: Han (Traditional variant)
Added: 2005-10-16
""")
        profiles = {
            "version": 2,
            "languages": [
                {
                    "code": "nan-Hant-x-chao1238",
                    "name": "潮州話",
                    "name_en": "Chaozhou",
                    "glottocode": "chao1238",
                    "origin": "seed",
                    "reason": "existing-online-code",
                },
                {
                    "code": "x-emoji",
                    "name": "Emoji 表情",
                    "name_en": "Emoji",
                    "glottocode": None,
                    "origin": "system",
                    "reason": "special-content",
                },
            ],
        }
        rows = list(seed_language_rows(
            profiles,
            subtags,
            {row.glottocode: row for row in languoids},
        ))
        self.assertEqual(
            [row["code"] for row in rows],
            ["nan-Hant-x-chao1238", "x-emoji"],
        )
        self.assertEqual(rows[0]["variety_key"], "glotto:chao1238")
        self.assertTrue(rows[1]["variety_key"].startswith("system:"))

    def test_registry_sql_loads_into_canonical_schema(self):
        languoids = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        _, subtags = parse_iana_registry("""File-Date: 2026-06-15
%%
Type: language
Subtag: cmn
Description: Mandarin
Added: 2005-10-16
%%
Type: script
Subtag: Hans
Description: Han (Simplified variant)
Added: 2005-10-16
""")
        profiles = {
            "version": 2,
            "languages": [
                {
                    "code": "cmn-Hans",
                    "name": "Mandarin",
                    "name_en": "Mandarin",
                    "glottocode": "mand1415",
                    "origin": "seed",
                    "reason": "existing-online-code",
                },
                {
                    "code": "x-emoji",
                    "name": "Emoji 表情",
                    "name_en": "Emoji",
                    "glottocode": None,
                    "origin": "system",
                    "reason": "special-content",
                },
            ],
        }
        seed_rows = list(seed_language_rows(
            profiles, subtags, {row.glottocode: row for row in languoids}
        ))
        schema = (ROOT.parent.parent / "backend" / "schema.sql").read_text(encoding="utf-8")
        db = sqlite3.connect(":memory:")
        db.execute("PRAGMA foreign_keys=ON")
        db.executescript(schema)
        db.executescript(render_registry_sql(languoids, subtags, seed_rows))
        self.assertEqual(
            db.execute("SELECT code FROM languages ORDER BY code").fetchall(),
            [("cmn-Hans",), ("x-emoji",)],
        )
        self.assertGreater(
            db.execute("SELECT COUNT(*) FROM language_subtags").fetchone()[0], 0,
        )

    def test_canonical_seed_code_rejects_unregistered_language(self):
        _, subtags = parse_iana_registry("""File-Date: 2026-06-15
%%
Type: language
Subtag: en
Description: English
Added: 2005-10-16
""")
        registered = {(row.type, row.value.lower()): row for row in subtags if not row.deprecated}
        with self.assertRaises(ValueError):
            canonical_seed_code("zz", registered)

    def test_split_canonical_seed_code_parses_components(self):
        result = split_canonical_seed_code("nan-Hant-TW-tailo")
        self.assertEqual(result["language"], "nan")
        self.assertEqual(result["script"], "Hant")
        self.assertEqual(result["region"], "TW")
        self.assertEqual(result["variants"], ["tailo"])
        self.assertEqual(result["private_use"], [])

    def test_split_canonical_seed_code_handles_private_use(self):
        result = split_canonical_seed_code("x-emoji")
        self.assertEqual(result["language"], "x")
        self.assertEqual(result["script"], None)
        self.assertEqual(result["region"], None)
        self.assertEqual(result["private_use"], ["x-emoji"])

    def test_direction_for_script_returns_rtl_for_arab_family(self):
        self.assertEqual(direction_for_script("Arab"), "rtl")
        self.assertEqual(direction_for_script("Hebr"), "rtl")
        self.assertEqual(direction_for_script("Latn"), "ltr")
        self.assertEqual(direction_for_script(None), "ltr")

    def test_canonical_case(self):
        self.assertEqual(canonical_case(["nan", "hant", "tw"]), "nan-Hant-TW")

    def test_language_schema_is_single_profile_table(self):
        schema = (ROOT.parent.parent / "backend/schema.sql").read_text()
        self.assertIn("variety_key TEXT NOT NULL", schema)
        self.assertIn("CREATE TABLE language_subtags", schema)
        self.assertNotIn("language_varieties", schema)
        self.assertNotIn("languoid_id TEXT\n", schema)
        self.assertNotIn("is_active INTEGER", schema)

    def test_language_migration_preserves_canonical_codes(self):
        manifest = {
            "mappings": {
                "en-US": {"action": "keep", "canonical": "en-US"},
                "nan-TW-Latn-tailo": {
                    "action": "canonicalize",
                    "canonical": "nan-Latn-TW-tailo",
                },
            }
        }
        self.assertEqual(validate_manifest(
            manifest, {"en-US", "nan-TW-Latn-tailo"}
        ), [])


if __name__ == "__main__":
    unittest.main()
