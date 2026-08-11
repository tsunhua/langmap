import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ARTIFACTS = ROOT / "artifacts"


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
        for table, key in [("languages", "languages"), ("scripts", "scripts"), ("regions", "regions")]:
            block = sql.split(f"INSERT OR IGNORE INTO {table}")[1].split(";")[0]
            row_count = block.count("\n  (")
            self.assertEqual(row_count, manifest["counts"][key], f"{table} count mismatch")
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


if __name__ == "__main__":
    unittest.main()
