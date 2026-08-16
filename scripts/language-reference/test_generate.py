import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path

from generate import build_expression_id, expression_text_hash

ROOT = Path(__file__).resolve().parent
ARTIFACTS = ROOT / "artifacts"

KNOWN = {
    "English": "xiiyx574tqno3qpnwkfavkdobm",
    "Japanese": "xzhosbwt57wpynfjjjwng6ddhi",
    "Mandarin Chinese": "wahosxiiyppkc7vkgn2foa4zda",
    "Min Nan Chinese (Hokkien)": "cvv4hpw64s3dtefqqwzcbxhr2y",
    "Spanish": "gqiqlhfy4bta4ko5pi3tpzs2fa",
    "Japanese (Japan)": "gu52ixjn6apik3jjkpzi5bj4oq",
    "普通话": "6q2zdme4dnc4v7u2tg6jzfu4rq",
    "華語": "ourhuuu2u4tghx6o6m7won2u6m",
    "日语": "hkke3wzynd2lehwvcuqfvvvh4a",
    "日語": "yigtj7ofv3bw4svpyfze3x4adq",
    "日语（日本）": "auelzis6d2oav6qw4gfizxoipq",
    "日語（日本）": "fey3ky7n7du23uvlvnc6yqv3xi",
    "英语": "2fsixlf4cyykmdv4aci7u6smw4",
    "英語": "k64pyj2pcbv4msv2jspahel7ue",
    "西班牙语": "nsds2j7ygwo4pjnluarq3hn3xy",
    "西班牙語": "5vowucfjacuokpyxngunzsmowq",
    "闽南语": "dtd7wb44qk6zm2g2h667asgcbq",
    "閩南語": "gslrtrbgubtqpzrokd3o47oymu",
}


def test_expression_text_hash_known_answers():
    for text, expected in KNOWN.items():
        assert expression_text_hash(text) == expected, text


def test_build_expression_id():
    assert build_expression_id("cmn", KNOWN["普通话"]) == "cmn:6q2zdme4dnc4v7u2tg6jzfu4rq"
    assert build_expression_id("cmn", "hash", 2) == "cmn:hash.2"


class TestGenerator(unittest.TestCase):
    def test_artifacts_exist(self):
        self.assertTrue((ARTIFACTS / "language-reference.sql").exists())
        self.assertTrue((ARTIFACTS / "manifest.json").exists())

    def test_sql_is_deterministic(self):
        before = hashlib.sha256((ARTIFACTS / "language-reference.sql").read_bytes()).hexdigest()
        rc = subprocess.run([sys.executable, str(ROOT / "generate.py")], capture_output=True)
        self.assertEqual(rc.returncode, 0, rc.stderr.decode())
        after = hashlib.sha256((ARTIFACTS / "language-reference.sql").read_bytes()).hexdigest()
        self.assertEqual(before, after, "generator output must be byte-stable")

    def test_manifest_counts_match_sql_and_mins(self):
        manifest = json.loads((ARTIFACTS / "manifest.json").read_text(encoding="utf-8"))
        sql = (ARTIFACTS / "language-reference.sql").read_text(encoding="utf-8")

        def count_rows(table: str) -> int:
            # INSERTs are batched, so sum value rows across every statement.
            return sum(
                stmt.count("\n  (")
                for stmt in sql.split(";")
                if f"INSERT OR IGNORE INTO {table}" in stmt
            )

        for table, key in [("languages", "languages"), ("scripts", "scripts"), ("regions", "regions")]:
            self.assertEqual(count_rows(table), manifest["counts"][key], f"{table} count mismatch")
        self.assertGreaterEqual(manifest["counts"]["languages"], 7000)
        self.assertGreaterEqual(manifest["counts"]["scripts"], 100)
        self.assertGreaterEqual(manifest["counts"]["regions"], 200)

    def test_manifest_has_version_and_checksum(self):
        manifest = json.loads((ARTIFACTS / "manifest.json").read_text(encoding="utf-8"))
        self.assertIn("manifest_version", manifest)
        actual = hashlib.sha256((ARTIFACTS / "language-reference.sql").read_bytes()).hexdigest()
        self.assertEqual(actual, manifest["artifacts"]["language_reference_sql"]["sha256"])

    def test_manifest_records_source_provenance(self):
        manifest = json.loads((ARTIFACTS / "manifest.json").read_text(encoding="utf-8"))
        for key in ("iso639-3", "iso15924", "iso3166-1"):
            self.assertIn(key, manifest["sources"])
            self.assertTrue(manifest["sources"][key]["sha256"])

    def test_script_names_use_english_name_column(self):
        sql = (ARTIFACTS / "language-reference.sql").read_text(encoding="utf-8")
        self.assertIn("('Arab', 'Arabic', 'rtl')", sql)
        self.assertIn("('Latn', 'Latin', 'ltr')", sql)

    def test_name_seed_ids_match_known_answers(self):
        sql = (ARTIFACTS / "language-reference.sql").read_text(encoding="utf-8")
        self.assertIn("eng:xiiyx574tqno3qpnwkfavkdobm", sql)  # English
        self.assertIn("eng:wahosxiiyppkc7vkgn2foa4zda", sql)  # Mandarin Chinese
        self.assertIn("eng:gqiqlhfy4bta4ko5pi3tpzs2fa", sql)  # Spanish
        self.assertIn("eng:cvv4hpw64s3dtefqqwzcbxhr2y", sql)  # Min Nan Chinese (Hokkien)
        self.assertIn("cmn:6q2zdme4dnc4v7u2tg6jzfu4rq", sql)  # 普通话
        self.assertIn("cmn:hkke3wzynd2lehwvcuqfvvvh4a", sql)  # 日语
        self.assertIn("cmn:auelzis6d2oav6qw4gfizxoipq", sql)  # 日语（日本）
        self.assertIn("name-edge:cmn:6q2zdme4dnc4v7u2tg6jzfu4rq:eng:wahosxiiyppkc7vkgn2foa4zda", sql)
        self.assertIn("name-edge:cmn:auelzis6d2oav6qw4gfizxoipq:eng:gu52ixjn6apik3jjkpzi5bj4oq", sql)
        self.assertIn("name-att:cmn:hkke3wzynd2lehwvcuqfvvvh4a:cmn-Hans-CN", sql)
        self.assertIn("name-att:cmn:yigtj7ofv3bw4svpyfze3x4adq:cmn-Hant-TW", sql)

    def test_name_seed_bindings_present(self):
        sql = (ARTIFACTS / "language-reference.sql").read_text(encoding="utf-8")
        self.assertIn("UPDATE languages AS l", sql)
        self.assertIn("UPDATE language_locales AS l", sql)
        self.assertIn("'system-names'", sql)


if __name__ == "__main__":
    unittest.main()
