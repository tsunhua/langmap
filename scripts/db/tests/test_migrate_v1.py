from pathlib import Path
import unittest

from scripts.db.migrate_v1.identity import build_expression_id, compute_text_hash
from scripts.db.migrate_v1.mapping import map_expression_locale, map_language_code
from scripts.db.migrate_v1.parse_sql import load_table
from scripts.db.migrate_v1.users import migrate_users


ROOT = Path(__file__).resolve().parents[2]


class MigrateV1Test(unittest.TestCase):
    def test_loads_users_and_preserves_bcrypt(self) -> None:
        contents = (ROOT / 'v2' / 'remote-users.sql').read_text(encoding='utf-8')
        rows = load_table(contents, 'users')
        migrated = migrate_users(rows)
        self.assertEqual(len(migrated), 12)
        self.assertTrue(str(migrated[0]['password_hash']).startswith('$2b$10$'))
        self.assertEqual(migrated[0]['role'], 'admin')
        self.assertIsInstance(migrated[0]['email_verified'], int)

    def test_identity_vector_and_homographs(self) -> None:
        self.assertEqual(compute_text_hash('hello'), 'ftze3os7wcrq4jxihmvmlopcty')
        self.assertEqual(build_expression_id('eng', compute_text_hash('hello'), 2), 'eng:ftze3os7wcrq4jxihmvmlopcty.2')

    def test_mapping(self) -> None:
        self.assertEqual(map_language_code('nan-TW-POJ'), 'nan')
        self.assertEqual(map_expression_locale('nan-TW-POJ'), 'nan-Latn_Pehoeji-TW')
        self.assertIsNone(map_language_code('unknown'))


if __name__ == '__main__':
    unittest.main()
