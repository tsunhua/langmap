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
    seed_location_rows,
    render_registry_sql,
    seed_language_rows,
    split_canonical_seed_code,
    write_languages,
    write_locations,
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

    def test_csv_artifacts_use_repository_lf_line_endings(self):
        target = ROOT / "fixtures/languages-line-endings.tmp.csv"
        try:
            write_languages(target, [{"code": "en", "name": "English"}], 10)
            self.assertNotIn(b"\r\n", target.read_bytes())
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

    def test_seed_alternate_names_reach_the_registry_rows(self):
        languoids = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        _, subtags = parse_iana_registry("""File-Date: 2026-06-15
%%
Type: language
Subtag: cmn
Description: Mandarin Chinese
Added: 2005-10-16
%%
Type: language
Subtag: ja
Description: Japanese
Added: 2005-10-16
%%
Type: script
Subtag: Hans
Description: Han (Simplified variant)
Added: 2005-10-16
""")
        profiles = {
            "version": 3,
            "languages": [
                {
                    "code": "cmn-Hans",
                    "name": "华语",
                    "name_en": "Mandarin Chinese (Simplified)",
                    "glottocode": "mand1415",
                    "origin": "seed",
                    "reason": "major-east-asia-language",
                    "alternate_names": ["普通话", "国语", "汉语"],
                },
                {
                    "code": "ja",
                    "name": "日本語",
                    "name_en": "Japanese",
                    "glottocode": None,
                    "origin": "seed",
                    "reason": "major-east-asia-language",
                },
            ],
        }
        rows = {
            row["code"]: row
            for row in seed_language_rows(
                profiles, subtags, {row.glottocode: row for row in languoids}
            )
        }

        self.assertEqual(
            json.loads(rows["cmn-Hans"]["alternate_names_json"]),
            ["普通话", "国语", "汉语"],
        )
        self.assertEqual(json.loads(rows["ja"]["alternate_names_json"]), [])

    def test_real_seed_carries_mandarin_alternate_names(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        by_code = {profile["code"]: profile for profile in profiles["languages"]}

        self.assertIn("普通话", by_code["cmn-Hans"]["alternate_names"])
        self.assertIn("國語", by_code["cmn-Hant"]["alternate_names"])

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

    def test_language_locations_schema_is_minimal_and_indexed(self):
        schema = (ROOT.parent.parent / "backend/schema.sql").read_text()
        self.assertIn("CREATE TABLE language_locations", schema)
        self.assertIn("PRIMARY KEY (variety_key, city_name, territory_code, script_code)", schema)
        self.assertIn("CREATE INDEX idx_language_locations_variety", schema)
        self.assertIn("CREATE INDEX idx_language_locations_city", schema)
        self.assertNotIn("CREATE TABLE places", schema)
        self.assertNotIn("geometry", schema.lower())
        self.assertNotIn("polygon", schema.lower())

    def test_locations_are_validated_and_stably_sorted(self):
        subtags = [
            type("Subtag", (), {"type": "region", "value": "HK", "deprecated": None})(),
            type("Subtag", (), {"type": "script", "value": "Hans", "deprecated": None})(),
        ]
        rows = list(seed_location_rows({"locations": [
            {"variety_key": "glotto:yue", "city_name": "香港", "city_name_en": "Hong Kong",
             "territory_code": "HK", "script_code": "Hans", "latitude": 22.3193,
             "longitude": 114.1694, "reference": "ref"},
        ]}, {"glotto:yue"}, subtags))
        self.assertEqual(rows[0]["city_name"], "香港")
        self.assertEqual(list(seed_location_rows({"locations": []}, set(), subtags)), [])

        with self.assertRaisesRegex(ValueError, "unknown variety_key"):
            list(seed_location_rows({"locations": [{"variety_key": "missing"}]}, set(), subtags))

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

    def test_language_migration_allows_explicit_many_to_one_canonicalization(self):
        manifest = {"mappings": {
            "yue-Hans-CN": {"action": "canonicalize", "canonical": "yue-Hans"},
            "yue-Hans-SG": {"action": "canonicalize", "canonical": "yue-Hans"},
        }}
        self.assertEqual(validate_manifest(manifest), [])

    def test_seed_profiles_do_not_use_regions_as_language_geography(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        codes = {profile["code"] for profile in profiles["languages"]}

        self.assertTrue({
            "ar", "bn", "de", "es", "fa", "fr", "hi", "id", "it", "ja",
            "mr", "pa-Guru", "ru", "th", "tr", "ur", "vi",
            "cmn-Hans", "cmn-Hant", "yue-Hans", "yue-Hant",
            "wuu-Hans", "wuu-Hant", "hsn-Hans", "hsn-Hant",
            "hak-Hans", "hak-Hant", "cdo-Hans", "cdo-Hant",
            "mnp-Hans", "mnp-Hant", "nan-Hans", "nan-Hant",
            "bo-Tibt", "ug-Arab", "mn-Mong", "mn-Cyrl",
            "kk-Arab", "kk-Cyrl", "ky-Arab", "ky-Cyrl", "za-Latn",
        }.issubset(codes))
        self.assertTrue({
            "ja-JP", "zh-Hans-CN", "zh-Hant-TW", "yue-Hans-CN",
            "yue-Hant-HK", "yue-Hant-MO", "wuu-Hans-CN", "ug-Arab-CN",
        }.isdisjoint(codes))

    def test_seed_profiles_include_common_and_reviewed_variant_layers(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        codes = {profile["code"] for profile in profiles["languages"]}

        self.assertTrue({
            "en", "en-US", "en-GB",
            "pt", "pt-BR",
            "ko", "ko-KR", "ko-KP",
            "yue-Hant",
        }.issubset(codes))

    def test_chaozhou_profiles_use_exact_glottocode_for_each_script(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        by_code = {profile["code"]: profile for profile in profiles["languages"]}

        expected = {
            "nan-Hans-x-chao1238",
            "nan-Hant-x-chao1238",
            "nan-Latn-x-chao1238",
        }
        self.assertTrue(expected.issubset(by_code))
        self.assertNotIn("nan-x-chao1239", by_code)
        for code in expected:
            self.assertEqual(by_code[code]["glottocode"], "chao1238")

    def test_expression_schema_tracks_common_variant_classification(self):
        schema = (ROOT.parent.parent / "backend/schema.sql").read_text()
        self.assertIn("variation_status TEXT NOT NULL DEFAULT 'unclassified'", schema)
        self.assertIn("variation_status IN ('unclassified', 'shared', 'variant')", schema)

        db = sqlite3.connect(":memory:")
        db.executescript(schema)
        db.execute(
            "INSERT INTO languages (code, name, variety_key) VALUES ('en', 'English', 'test:en')"
        )
        db.execute("INSERT INTO expressions (id, text, language_code) VALUES (1, 'book', 'en')")
        self.assertEqual(
            db.execute("SELECT variation_status FROM expressions WHERE id = 1").fetchone()[0],
            "unclassified",
        )
        with self.assertRaises(sqlite3.IntegrityError):
            db.execute(
                "INSERT INTO expressions (id, text, language_code, variation_status) "
                "VALUES (2, 'colour', 'en', 'unknown')"
            )

    def test_seed_profiles_publish_reviewed_code_migration_matrix(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        migration_manifest = profiles.get("online_code_migrations")
        self.assertIsNotNone(migration_manifest)
        mappings = migration_manifest["mappings"]

        self.assertEqual(mappings["ja-JP"], {
            "action": "canonicalize", "canonical": "ja",
        })
        self.assertEqual(mappings["yue-Hans-CN"], {
            "action": "canonicalize", "canonical": "yue-Hans",
        })
        self.assertEqual(mappings["yue-Hant-HK"], {
            "action": "canonicalize", "canonical": "yue-Hant",
        })
        self.assertEqual(mappings["yue-Hant-MO"], {
            "action": "canonicalize", "canonical": "yue-Hant",
        })
        self.assertEqual(mappings["en-US"], {
            "action": "keep", "canonical": "en-US",
        })
        self.assertEqual(validate_manifest(profiles["online_code_migrations"]), [])

    def test_content_profile_migration_preserves_references_and_merges_stats(self):
        migration_path = ROOT.parent.parent / "backend/migrations/0012_canonicalize_language_content_profiles.sql"
        self.assertTrue(migration_path.exists(), "content-profile migration must exist")

        schema = (ROOT.parent.parent / "backend/schema.sql").read_text()
        db = sqlite3.connect(":memory:")
        db.execute("PRAGMA foreign_keys=ON")
        db.executescript(schema)
        db.executemany(
            "INSERT INTO languages (code, name, base_language, script_code, region_code, variety_key, origin) VALUES (?, ?, ?, ?, ?, ?, 'seed')",
            [
                ("en-US", "English", "en", "", "US", "glotto:stan1293"),
                ("ja-JP", "日本語", "ja", "", "JP", "glotto:nucl1643"),
                ("zh-Hant-TW", "繁體中文", "zh", "Hant", "TW", "glotto:mand1415"),
                ("yue-Hant-HK", "粵語", "yue", "Hant", "HK", "glotto:yuec1235"),
                ("yue-Hant-MO", "粵語", "yue", "Hant", "MO", "glotto:yuec1235"),
            ],
        )
        db.executemany(
            "INSERT INTO expressions (id, text, language_code) VALUES (?, ?, ?)",
            [(1, "日本語", "ja-JP"), (2, "廣東話", "yue-Hant-HK"), (3, "粵語", "yue-Hant-MO")],
        )
        db.executemany(
            "INSERT INTO language_stats (language_code, expression_count) VALUES (?, ?)",
            [("yue-Hant-HK", 2), ("yue-Hant-MO", 3)],
        )
        db.executemany(
            "INSERT INTO ui_locales (project_id, code, native_name, fallback_code) VALUES ('langmap-web', ?, ?, ?)",
            [("en-US", "English", None), ("ja-JP", "日本語", "en-US"), ("zh-Hant-TW", "繁體中文", "en-US")],
        )

        db.executescript(migration_path.read_text())

        self.assertEqual(
            db.execute("SELECT language_code FROM expressions ORDER BY id").fetchall(),
            [("ja",), ("yue-Hant",), ("yue-Hant",)],
        )
        self.assertEqual(
            db.execute("SELECT expression_count FROM language_stats WHERE language_code='yue-Hant'").fetchone(),
            (5,),
        )
        self.assertEqual(
            db.execute("SELECT code FROM ui_locales ORDER BY code").fetchall(),
            [("en-US",), ("ja",), ("zh-Hant",)],
        )
        self.assertEqual(
            db.execute("SELECT code FROM languages WHERE code IN ('ja-JP','zh-Hant-TW','yue-Hant-HK','yue-Hant-MO')").fetchall(),
            [],
        )
        self.assertEqual(db.execute("PRAGMA foreign_key_check").fetchall(), [])


if __name__ == "__main__":
    unittest.main()
