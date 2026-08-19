from pathlib import Path
import unittest

from scripts.db.migrate_v1.identity import build_expression_id, compute_text_hash
from scripts.db.migrate_v1.expressions import migrate_expressions
from scripts.db.migrate_v1.handbooks import migrate_handbooks, parse_sections
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

    def test_parser_keeps_semicolons_inside_text(self) -> None:
        rows = load_table(
            "INSERT INTO \"expressions\" (id,text) VALUES (1,'wait; then go');",
            'expressions',
        )
        self.assertEqual(rows, [{'id': 1, 'text': 'wait; then go'}])

    def test_identity_vector_and_homographs(self) -> None:
        self.assertEqual(compute_text_hash('hello'), 'ftze3os7wcrq4jxihmvmlopcty')
        self.assertEqual(build_expression_id('eng', compute_text_hash('hello'), 2), 'eng:ftze3os7wcrq4jxihmvmlopcty.2')

    def test_mapping(self) -> None:
        self.assertEqual(map_language_code('nan-TW-POJ'), 'nan')
        self.assertEqual(map_expression_locale('nan-TW-POJ'), 'nan-Latn_Pehoeji-TW')
        self.assertIsNone(map_language_code('unknown'))

    def test_migrates_user_expressions_and_readings(self) -> None:
        rows = [
            {'id': 1, 'text': ' hello ', 'language_code': 'en-US', 'created_by': 'lshare', 'review_status': 'approved'},
            {'id': 2, 'text': 'hello', 'language_code': 'en-US', 'created_by': 'lshare', 'review_status': 'approved'},
            {'id': 3, 'text': 'hó', 'language_code': 'nan-TW-POJ', 'created_by': 'lshare'},
            {'id': 4, 'text': 'system', 'language_code': 'en-US', 'created_by': 'system'},
            {'id': 5, 'text': 'unknown', 'language_code': 'xx', 'created_by': 'lshare'},
        ]
        result = migrate_expressions(rows, {'lshare': 1})
        expressions = result['expressions']
        self.assertEqual(len(expressions), 3)
        self.assertEqual(expressions[0]['homograph_index'], 1)
        self.assertEqual(expressions[1]['homograph_index'], 2)
        self.assertEqual(len(result['attestations']), 3)
        self.assertEqual(result['readings'][0]['scheme'], 'poj')
        self.assertEqual(result['report'], {'skipped': 0, 'dropped_owner': 1, 'dropped_unmapped': 1})

    def test_migrates_handbook_sections_and_items(self) -> None:
        self.assertEqual(parse_sections('## One\n{{text:翁|mid:1}}\n\n### Two\n{{2}}'), [('One', ['text:翁']), ('Two', ['2'])])
        result = migrate_handbooks(
            [{'id': 10, 'user_id': 7, 'title': 'Guide', 'is_public': 1, 'content': '## One\n{{text:翁}}\n{{999}}'}],
            [],
            {'text:翁': 'nan:one', '2': 'nan:two'},
            {7: 7},
        )
        self.assertEqual(len(result['handbooks']), 1)
        self.assertEqual(len(result['sections']), 1)
        self.assertEqual(len(result['items']), 1)
        self.assertEqual(result['report']['skipped_unmapped_items'], 1)


if __name__ == '__main__':
    unittest.main()
