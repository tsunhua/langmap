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
    seed_profile_rows,
    seed_variety_rows,
    render_registry_sql,
    split_canonical_seed_code,
    write_locations,
    write_profiles,
    write_varieties,
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

    def test_csv_artifacts_use_repository_lf_line_endings(self):
        target = ROOT / "fixtures/varieties-line-endings.tmp.csv"
        try:
            write_varieties(target, [{"code": "en", "name": "English"}])
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
            "version": 5,
            "varieties": [
                {
                    "id": "var-chao",
                    "code": "nan-x-chao1238",
                    "name": "潮州話",
                    "name_en": "Chaozhou",
                    "glottocode": "chao1238",
                    "origin": "seed",
                    "reason": "existing-online-code",
                    "profiles": [
                        {"code": "nan-Hant-x-chao1238", "name": "傳承體", "name_en": "Traditional"},
                    ],
                },
                {
                    "id": "var-emoji",
                    "code": "x-emoji",
                    "name": "Emoji 表情",
                    "name_en": "Emoji",
                    "glottocode": None,
                    "origin": "system",
                    "reason": "special-content",
                    "profiles": [
                        {"code": "x-emoji", "name": "Emoji", "name_en": "Emoji"},
                    ],
                },
            ],
        }
        variety_rows = list(seed_variety_rows(
            profiles,
            subtags,
            {row.glottocode: row for row in languoids},
        ))
        self.assertEqual(
            [row["code"] for row in variety_rows],
            ["nan-x-chao1238", "x-emoji"],
        )
        variety_code_to_id = {row["code"]: row["id"] for row in variety_rows}
        profile_rows = list(seed_profile_rows(profiles, subtags, variety_code_to_id))
        self.assertEqual(
            [row["code"] for row in profile_rows],
            ["nan-Hant-x-chao1238", "x-emoji"],
        )
        self.assertEqual(profile_rows[0]["language_variety_id"], "var-chao")
        self.assertEqual(profile_rows[1]["language_variety_id"], "var-emoji")

    def test_seed_alternate_names_reach_the_variety_rows(self):
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
            "version": 5,
            "varieties": [
                {
                    "id": "var-cmn",
                    "code": "cmn",
                    "name": "华语",
                    "name_en": "Mandarin Chinese",
                    "glottocode": "mand1415",
                    "origin": "seed",
                    "reason": "major-east-asia-language",
                    "alternate_names": ["普通话", "国语", "汉语"],
                    "profiles": [
                        {"code": "cmn-Hans", "name": "简体", "name_en": "Simplified"},
                    ],
                },
                {
                    "id": "var-ja",
                    "code": "ja",
                    "name": "日本語",
                    "name_en": "Japanese",
                    "glottocode": None,
                    "origin": "seed",
                    "reason": "major-east-asia-language",
                    "profiles": [
                        {"code": "ja", "name": "標準", "name_en": "Japanese"},
                    ],
                },
            ],
        }
        rows = {
            row["code"]: row
            for row in seed_variety_rows(
                profiles, subtags, {row.glottocode: row for row in languoids}
            )
        }

        self.assertEqual(
            json.loads(rows["cmn"]["alternate_names_json"]),
            ["普通话", "国语", "汉语"],
        )
        self.assertEqual(json.loads(rows["ja"]["alternate_names_json"]), [])

    def test_real_seed_carries_mandarin_alternate_names(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        varieties = {v["code"]: v for v in profiles["varieties"]}

        self.assertIn("普通话", varieties["cmn"]["alternate_names"])
        self.assertIn("國語", varieties["cmn"]["alternate_names"])

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
            "version": 5,
            "varieties": [
                {
                    "id": "var-cmn",
                    "code": "cmn",
                    "name": "Mandarin",
                    "name_en": "Mandarin",
                    "glottocode": "mand1415",
                    "origin": "seed",
                    "reason": "existing-online-code",
                    "profiles": [
                        {"code": "cmn-Hans", "name": "简体", "name_en": "Simplified"},
                    ],
                },
                {
                    "id": "var-emoji",
                    "code": "x-emoji",
                    "name": "Emoji 表情",
                    "name_en": "Emoji",
                    "glottocode": None,
                    "origin": "system",
                    "reason": "special-content",
                    "profiles": [
                        {"code": "x-emoji", "name": "Emoji", "name_en": "Emoji"},
                    ],
                },
            ],
        }
        variety_rows = list(seed_variety_rows(
            profiles, subtags, {row.glottocode: row for row in languoids}
        ))
        variety_code_to_id = {row["code"]: row["id"] for row in variety_rows}
        profile_rows = list(seed_profile_rows(profiles, subtags, variety_code_to_id))
        schema = (ROOT.parent.parent / "backend" / "schema.sql").read_text(encoding="utf-8")
        db = sqlite3.connect(":memory:")
        db.execute("PRAGMA foreign_keys=ON")
        db.executescript(schema)
        db.executescript(
            render_registry_sql(languoids, subtags, variety_rows, profile_rows)
        )
        self.assertEqual(
            db.execute("SELECT code FROM language_varieties ORDER BY code").fetchall(),
            [("cmn",), ("x-emoji",)],
        )
        self.assertEqual(
            db.execute("SELECT code FROM language_profiles ORDER BY code").fetchall(),
            [("cmn-Hans",), ("x-emoji",)],
        )
        self.assertGreater(
            db.execute("SELECT COUNT(*) FROM language_subtags").fetchone()[0], 0,
        )
        self.assertEqual(db.execute("PRAGMA foreign_key_check").fetchall(), [])

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

    def test_language_locations_schema_is_minimal_and_indexed(self):
        schema = (ROOT.parent.parent / "backend/schema.sql").read_text()
        self.assertIn("CREATE TABLE language_locations", schema)
        self.assertIn(
            "PRIMARY KEY (language_variety_id, city_name, territory_code, script_code)",
            schema,
        )
        self.assertIn(
            "FOREIGN KEY (language_variety_id) REFERENCES language_varieties(id)",
            schema,
        )
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
            {"variety_code": "yue", "city_name": "香港", "city_name_en": "Hong Kong",
             "territory_code": "HK", "script_code": "Hans", "latitude": 22.3193,
             "longitude": 114.1694, "reference": "ref"},
        ]}, {"yue": "var-yue"}, subtags))
        self.assertEqual(rows[0]["city_name"], "香港")
        self.assertEqual(rows[0]["language_variety_id"], "var-yue")
        self.assertEqual(list(seed_location_rows({"locations": []}, {}, subtags)), [])

        with self.assertRaisesRegex(ValueError, "unknown variety_code"):
            list(seed_location_rows({"locations": [{"variety_code": "missing"}]}, {}, subtags))

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
        codes = {p["code"] for v in profiles["varieties"] for p in v["profiles"]}

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
        codes = {p["code"] for v in profiles["varieties"] for p in v["profiles"]}

        self.assertTrue({
            "en", "en-US", "en-GB",
            "pt", "pt-BR",
            "ko", "ko-KR", "ko-KP",
            "yue-Hant",
        }.issubset(codes))

    def test_seed_varieties_are_two_layer_and_profile_codes_unique(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        varieties = profiles["varieties"]

        codes = [v["code"] for v in varieties]
        ids = [v["id"] for v in varieties]
        self.assertEqual(len(codes), len(set(codes)), "variety code must be unique")
        self.assertEqual(len(ids), len(set(ids)), "variety id must be unique")
        for variety in varieties:
            self.assertTrue(variety["profiles"], f"variety {variety['code']} has no profiles")
            self.assertNotIn("Simplified", variety["name_en"])
            self.assertNotIn("Traditional", variety["name_en"])

        profile_codes: list[str] = []
        for variety in varieties:
            profile_codes.extend(p["code"] for p in variety["profiles"])
        self.assertEqual(len(profile_codes), len(set(profile_codes)), "profile code must be globally unique")

        by_code = {v["code"]: v for v in varieties}
        self.assertEqual(
            {p["code"] for p in by_code["cmn"]["profiles"]},
            {"cmn-Hans", "cmn-Hant"},
        )

    def test_chaozhou_profiles_use_exact_glottocode_for_each_script(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        varieties = {v["code"]: v for v in profiles["varieties"]}

        self.assertIn("nan-x-chao1238", varieties)
        chao = varieties["nan-x-chao1238"]
        self.assertEqual(chao["glottocode"], "chao1238")
        self.assertEqual({p["code"] for p in chao["profiles"]}, {
            "nan-Hans-x-chao1238",
            "nan-Hant-x-chao1238",
            "nan-Latn-x-chao1238",
        })
        self.assertNotIn("nan-x-chao1239", varieties)

    def test_seed_profiles_register_all_chinese_varieties(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        self.assertEqual(profiles["version"], 8)
        varieties = {v["code"]: v for v in profiles["varieties"]}
        expected = {
            "cjy": ("晉語", "Jin Chinese", "jiny1235"),
            "gan": ("贛語", "Gan Chinese", "ganc1239"),
            "czo": ("閩中語", "Min Zhong", "minz1235"),
            "cpx": ("莆仙話", "Pu-Xian", "puxi1243"),
            "cnp": ("桂北平話", "Northern Pinghua", "nort3268"),
            "csp": ("桂南平話", "Southern Pinghua", "sout3250"),
        }
        for code, (name, name_en, glottocode) in expected.items():
            entry = varieties[code]
            self.assertEqual(entry["name"], name)
            self.assertEqual(entry["name_en"], name_en)
            self.assertEqual(entry["glottocode"], glottocode)
            self.assertEqual(entry["origin"], "seed")
            self.assertEqual(entry["reason"], "major-east-asia-language")
            self.assertEqual(
                {p["code"] for p in entry["profiles"]},
                {f"{code}-Hans", f"{code}-Hant"},
            )

    def test_seed_profiles_carry_chinese_variety_representative_cities(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        locations = {
            (loc["variety_code"], loc["city_name"]): loc
            for loc in profiles["locations"]
        }
        expected = {
            ("cjy", "Taiyuan"): ("CN", "Hans", 37.8706, 112.5489),
            ("gan", "Nanchang"): ("CN", "Hans", 28.6820, 115.8579),
            ("czo", "Sanming"): ("CN", "Hans", 26.2634, 117.6394),
            ("cpx", "Putian"): ("CN", "Hans", 25.4540, 119.0078),
            ("cnp", "Guilin"): ("CN", "Hans", 25.2742, 110.2900),
            ("csp", "Nanning"): ("CN", "Hans", 22.8170, 108.3665),
        }
        for key, (territory, script, lat, lon) in expected.items():
            loc = locations[key]
            self.assertEqual(loc["territory_code"], territory)
            self.assertEqual(loc["script_code"], script)
            self.assertEqual(loc["latitude"], lat)
            self.assertEqual(loc["longitude"], lon)

    def test_sinitic_locations_carry_script_localized_names(self):
        profiles = json.loads((ROOT / "language_seed_profiles.json").read_text())
        han_profiles = {
            v["code"]: v["profiles"]
            for v in profiles["varieties"]
            if any(p["code"].endswith("-Hans") for p in v["profiles"])
        }
        for loc in profiles["locations"]:
            if loc["variety_code"] not in han_profiles:
                self.assertNotIn("city_name_localized", loc)
                continue
            codes = {p["code"] for p in han_profiles[loc["variety_code"]]}
            localized = loc["city_name_localized"]
            self.assertEqual(
                set(localized),
                {c for c in codes if c.endswith(("-Hans", "-Hant"))},
            )
            self.assertTrue(all(v for v in localized.values()), localized)

    def test_expression_schema_tracks_common_variant_classification(self):
        schema = (ROOT.parent.parent / "backend/schema.sql").read_text()
        self.assertIn("variation_status TEXT NOT NULL DEFAULT 'unclassified'", schema)
        self.assertIn("variation_status IN ('unclassified', 'shared', 'variant')", schema)

        db = sqlite3.connect(":memory:")
        db.execute("PRAGMA foreign_keys=ON")
        db.executescript(schema)
        db.execute(
            "INSERT INTO language_varieties (id, code, name, origin) VALUES ('var-en', 'en', 'English', 'seed')"
        )
        db.execute(
            "INSERT INTO language_profiles (code, language_variety_id, name, direction, base_language) "
            "VALUES ('en', 'var-en', 'English', 'ltr', 'en')"
        )
        db.execute("INSERT INTO expressions (id, text, language_profile_code) VALUES (1, 'book', 'en')")
        self.assertEqual(
            db.execute("SELECT variation_status FROM expressions WHERE id = 1").fetchone()[0],
            "unclassified",
        )
        with self.assertRaises(sqlite3.IntegrityError):
            db.execute(
                "INSERT INTO expressions (id, text, language_profile_code, variation_status) "
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

    @unittest.skip(
        "Migration 0012 targeted the single-table languages schema; the "
        "two-table (varieties + profiles) model supersedes it and Task 4 will "
        "introduce the new content-profile migration test."
    )
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
                ("zh-Hant-TW", "傳承體中文", "zh", "Hant", "TW", "glotto:mand1415"),
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
            [("en-US", "English", None), ("ja-JP", "日本語", "en-US"), ("zh-Hant-TW", "傳承體中文", "en-US")],
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
