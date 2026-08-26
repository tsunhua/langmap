import hashlib
import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent
ARTIFACTS = ROOT / 'artifacts'


class TestGenerator(unittest.TestCase):
    def test_artifacts_are_present_and_byte_stable(self):
        sql_path = ARTIFACTS / 'language-reference.sql'
        manifest_path = ARTIFACTS / 'manifest.json'
        self.assertTrue(sql_path.exists())
        self.assertTrue(manifest_path.exists())
        before = hashlib.sha256(sql_path.read_bytes()).hexdigest()
        result = subprocess.run([sys.executable, str(ROOT / 'generate.py')], capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(before, hashlib.sha256(sql_path.read_bytes()).hexdigest())

    def test_manifest_counts_and_checksum_match_integer_seed(self):
        manifest = json.loads((ARTIFACTS / 'manifest.json').read_text(encoding='utf-8'))
        sql = (ARTIFACTS / 'language-reference.sql').read_text(encoding='utf-8')

        def count_rows(table: str) -> int:
            return sum(stmt.count('\n  (') for stmt in sql.split(';') if f'INSERT OR IGNORE INTO {table}' in stmt)

        for table, key in [('languages', 'languages'), ('scripts', 'scripts'), ('regions', 'regions'), ('language_locales', 'language_locales')]:
            self.assertEqual(count_rows(table), manifest['counts'][key], table)
        self.assertGreaterEqual(manifest['counts']['languages'], 7000)
        self.assertGreaterEqual(manifest['counts']['scripts'], 100)
        self.assertGreaterEqual(manifest['counts']['regions'], 200)
        self.assertEqual(hashlib.sha256((ARTIFACTS / 'language-reference.sql').read_bytes()).hexdigest(), manifest['artifacts']['language_reference_sql']['sha256'])

    def test_registry_rows_use_integer_ids_and_no_legacy_expression_seed(self):
        sql = (ARTIFACTS / 'language-reference.sql').read_text(encoding='utf-8')
        self.assertIn('INSERT OR IGNORE INTO languages (id, code, name_en)', sql)
        self.assertIn('INSERT OR IGNORE INTO language_locales (id, code, language_id', sql)
        self.assertNotIn('INSERT OR IGNORE INTO expressions', sql)
        self.assertNotIn('name-edge:', sql)
        self.assertNotIn('name-att:', sql)

    def test_script_names_keep_direction(self):
        sql = (ARTIFACTS / 'language-reference.sql').read_text(encoding='utf-8')
        self.assertIn("('Arab', 'Arabic', 'rtl')", sql)
        self.assertIn("('Latn', 'Latin', 'ltr')", sql)


if __name__ == '__main__':
    unittest.main()
