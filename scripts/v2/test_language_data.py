import csv
import json
import sqlite3
import unittest
from pathlib import Path

from glottolog_import import read_languoids, validate_languoids, import_sqlite, release_manifest, verify_sha256, release_diff
from language_migration import validate_manifest
from sync_language_registry import (
    _profile_tags,
    _variant_tag,
    canonical_case,
    language_rows,
    parse_iana_registry,
    online_code_migrations,
    write_languages,
    _special_content_rows,
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
        manifest["mappings"]["legacy"] = {"action": "keep", "canonical": "en"}
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

    def test_language_rows_separate_content_tags_from_languoids(self):
        languoids = read_languoids(ROOT / "fixtures/glottolog-mini.csv", "5.3")
        _, subtags = parse_iana_registry("""File-Date: 2026-06-15
%%
Type: script
Subtag: Hant
Description: Traditional Han
Added: 2005-10-16
%%
Type: script
Subtag: Bopo
Description: Bopomofo
Added: 2005-10-16
%%
Type: script
Subtag: Hanb
Description: Han with Bopomofo
Added: 2016-02-26
%%
Type: region
Subtag: TW
Description: Taiwan
Added: 2005-10-16
%%
Type: variant
Subtag: example
Description: Example
Added: 2026-01-01
Prefix: nan
""")
        profiles = {
            "iso639_3_to_bcp47": {"cmn": "zh"},
            "chinese_priority": {
                "combinations": {
                    "nan": [{"script": "Hant", "regions": ["TW"]}],
                    "zh": [
                        {"script": "Hant", "regions": ["TW"]},
                        {"script": "Bopo", "regions": ["TW"]},
                        {"script": "Hanb", "regions": ["TW"]},
                    ],
                },
            },
            "major_regions": {},
        }
        expanded = list(language_rows(languoids, subtags, profiles))
        self.assertIn("nan-Hant-TW", [row["code"] for row in expanded])
        self.assertIn("zh-Hant-TW", [row["code"] for row in expanded])
        self.assertIn("zh-Bopo-TW", [row["code"] for row in expanded])
        self.assertIn("zh-Hanb-TW", [row["code"] for row in expanded])
        self.assertNotIn("nan-Bopo-TW", [row["code"] for row in expanded])
        self.assertNotIn("nan-Hanb-TW", [row["code"] for row in expanded])
        self.assertIn("nan-example", [row["code"] for row in expanded])
        self.assertNotIn("nan-Hant", [row["code"] for row in expanded])
        self.assertNotIn("nan-TW", [row["code"] for row in expanded])
        self.assertNotIn("zh-Hant", [row["code"] for row in expanded])
        self.assertNotIn("zh-TW", [row["code"] for row in expanded])
        self.assertNotIn("zh", [row["code"] for row in expanded])
        self.assertNotIn("nan", [row["code"] for row in expanded])
        self.assertTrue(all(row["languoid_id"].startswith("glotto:") for row in expanded))
        self.assertEqual(canonical_case(["nan", "hant", "tw"]), "nan-Hant-TW")

    def test_languoid_without_iso_uses_ancestor_and_private_glottocode(self):
        root, dialect, language = read_languoids(
            ROOT / "fixtures/glottolog-mini.csv", "5.3"
        )
        without_iso = dialect.__class__(
            **{**dialect.__dict__, "iso639_3": None, "parent_id": language.id}
        )
        rows = list(language_rows(
            [root, language, without_iso],
            [],
            {
                "iso639_3_to_bcp47": {"cmn": "zh"},
                "chinese_priority": {},
                "major_regions": {},
            },
        ))
        self.assertIn("zh-x-chao1238", [row["code"] for row in rows])
        self.assertEqual(
            [row["code"] for row in rows if row["languoid_id"] == without_iso.id],
            ["zh-x-chao1238"],
        )

    def test_zh_dialect_is_split_by_script_without_region_expansion(self):
        root, dialect, language = read_languoids(
            ROOT / "fixtures/glottolog-mini.csv", "5.3"
        )
        without_iso = dialect.__class__(
            **{**dialect.__dict__, "iso639_3": None, "parent_id": language.id}
        )
        _, subtags = parse_iana_registry("""File-Date: 2026-06-15
%%
Type: script
Subtag: Hans
Description: Han (Simplified variant)
Added: 2005-10-16
%%
Type: script
Subtag: Hant
Description: Han (Traditional variant)
Added: 2005-10-16
""")
        profiles = {
            "iso639_3_to_bcp47": {"cmn": "zh"},
            "chinese_priority": {
                "glottolog_roots": ["mand1415"],
                "required_scripts": ["Hans", "Hant"],
            },
            "major_regions": {},
        }
        rows = list(language_rows([root, language, without_iso], subtags, profiles))
        dialect_codes = [
            row["code"] for row in rows if row["languoid_id"] == without_iso.id
        ]
        self.assertEqual(
            dialect_codes,
            ["zh-Hans-x-chao1238", "zh-Hant-x-chao1238"],
        )

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

    def test_language_csv_is_globally_sorted_by_code(self):
        target = ROOT / "fixtures/languages-sorted.tmp.csv"
        rows = [
            {field: "" for field in (
                "code", "name", "name_en", "direction", "is_active",
                "region_code", "languoid_id", "base_language",
                "script_code", "source_version",
            )}
            for _ in range(3)
        ]
        rows[0]["code"] = "yue-Hant-HK"
        rows[1]["code"] = "en-US"
        rows[2]["code"] = "x-image"
        try:
            write_languages(target, rows, 10)
            with target.open(encoding="utf-8") as handle:
                written = list(csv.DictReader(handle))
            self.assertEqual(
                [row["code"] for row in written],
                ["en-US", "x-image", "yue-Hant-HK"],
            )
        finally:
            target.unlink(missing_ok=True)

    def test_online_legacy_codes_have_explicit_canonical_migrations(self):
        profiles = json.loads((ROOT / "language_profiles.json").read_text(encoding="utf-8"))
        self.assertEqual(
            online_code_migrations(profiles),
            {
                "nan-TW-Latn-tailo": "nan-Latn-TW-tailo",
                "nan-TW-Latn-pehoeji": "nan-Latn-TW-pehoeji",
            },
        )

    def test_jyutping_gets_latin_script_without_generic_yue_tags(self):
        self.assertEqual(
            _variant_tag("yue", "jyutping", "Latn"),
            "yue-Latn-jyutping",
        )
        profiles = {
            "chinese_priority": {
                "required_scripts": ["Hans", "Hant", "Latn"],
                "combinations": {
                    "yue": [{"script": "Hant", "regions": ["HK"]}],
                },
                "omit_base": ["yue"],
            },
            "major_regions": {},
        }
        tags = _profile_tags(
            "yue",
            "",
            profiles,
            {"Hans", "Hant", "Latn"},
            {"HK", "CN", "MO"},
            True,
        )
        self.assertEqual(tags, ["yue-Hant-HK"])

    def test_known_latin_orthography_variants_get_explicit_script(self):
        for prefix, variant, expected in [
            ("kyh", "unifon", "kyh-Latn-unifon"),
            ("lld", "anpezo", "lld-Latn-anpezo"),
            ("lld", "fascia", "lld-Latn-fascia"),
            ("lld", "fodom", "lld-Latn-fodom"),
            ("lld", "gherd", "lld-Latn-gherd"),
            ("lld", "valbadia", "lld-Latn-valbadia"),
            ("ltg", "ltg1929", "ltg-Latn-ltg1929"),
            ("ltg", "ltg2007", "ltg-Latn-ltg2007"),
        ]:
            with self.subTest(variant=variant):
                self.assertEqual(_variant_tag(prefix, variant, "Latn"), expected)

    def test_only_allowlisted_private_content_codes_are_generated(self):
        profiles = json.loads((ROOT / "language_profiles.json").read_text(encoding="utf-8"))
        rows = _special_content_rows(profiles)
        self.assertEqual([row["code"] for row in rows], ["x-emoji", "x-image"])
        self.assertTrue(all(not row["languoid_id"] for row in rows))
        with self.assertRaises(ValueError):
            _special_content_rows({
                "special_content_codes": [{
                    "code": "x-arbitrary",
                    "name": "任意",
                    "name_en": "Arbitrary",
                    "direction": "ltr",
                }],
            })

    def test_profile_expansion_replaces_generic_base(self):
        profiles = {
            "chinese_priority": {},
            "major_regions": {"en": ["US", "GB"]},
        }
        tags = _profile_tags(
            "en",
            "",
            profiles,
            set(),
            {"US", "GB"},
            False,
        )
        self.assertEqual(tags, ["en-US", "en-GB"])


if __name__ == "__main__":
    unittest.main()
