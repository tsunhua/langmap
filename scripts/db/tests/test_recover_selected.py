import unittest

from scripts.db.migrate_v1.recover_selected import (
    HANDBOOK_ID,
    HANDBOOK_TITLE,
    _is_cjk_text,
    _select_data,
    map_old_expression,
)


class RecoverSelectedTest(unittest.TestCase):
    def test_jiazi_profiles_use_han_presence_not_ascii_regex(self) -> None:
        self.assertEqual(
            map_old_expression("nan-x-cha-Latn-puj", "tsṳ-niêⁿ"),
            ("nan", "nan-Latn-CN_LufengJiazi"),
        )
        self.assertEqual(
            map_old_expression("nan-x-cha-jiazi", "〇"),
            ("nan", "nan-Hant-CN_LufengJiazi"),
        )
        self.assertTrue(_is_cjk_text("做蜀khà"))

    def test_selection_is_one_hop_and_drops_ui_and_exact_locale_exceptions(self) -> None:
        data = _select_data(
            {
                "users": [
                    {
                        "id": 10,
                        "username": "monhiko",
                        "email": "m@example.com",
                    },
                    {
                        "id": 11,
                        "username": "tsunhua",
                        "email": "t@example.com",
                    },
                ],
                "expressions": [
                    {
                        "id": 1,
                        "language_code": "en-US",
                        "text": "seed",
                        "created_by": "monhiko",
                        "created_at": "2026-01-01",
                    },
                    {
                        "id": 2,
                        "language_code": "zh-CN",
                        "text": "direct",
                        "created_by": "system",
                        "created_at": "2026-01-01",
                    },
                    {
                        "id": 3,
                        "language_code": "zh-CN",
                        "text": "second-hop",
                        "created_by": "system",
                        "created_at": "2026-01-01",
                    },
                    {
                        "id": 4,
                        "language_code": "zh-CN",
                        "text": "ui",
                        "created_by": "system",
                        "tags": '["langmap.ui"]',
                        "created_at": "2026-01-01",
                    },
                    {
                        "id": 5,
                        "language_code": "fr-FR",
                        "text": "no-locale",
                        "created_by": "system",
                        "created_at": "2026-01-01",
                    },
                    {
                        "id": 6,
                        "language_code": "nan-x-cha-jiazi",
                        "text": "甲",
                        "created_by": "tsunhua",
                        "created_at": "2026-01-01",
                    },
                ],
                "expression_meaning": [
                    {"id": "1-9", "expression_id": 1, "meaning_id": 9},
                    {"id": "2-9", "expression_id": 2, "meaning_id": 9},
                    {"id": "3-10", "expression_id": 3, "meaning_id": 10},
                    {"id": "4-9", "expression_id": 4, "meaning_id": 9},
                ],
                "handbooks": [
                    {
                        "id": HANDBOOK_ID,
                        "title": HANDBOOK_TITLE,
                        "user_id": 11,
                        "is_public": 1,
                        "source_lang": "nan-x-cha-jiazi",
                        "content": "## 分類\n{{text:甲}}",
                        "renders": 'data-expression-id="6"',
                    }
                ],
                "handbook_pages": [],
            }
        )
        self.assertEqual(data.seed_user_ids, {"1"})
        self.assertEqual(data.seed_handbook_ids, {"6"})
        self.assertEqual(set(data.selected_rows), {"1", "2", "6"})
        self.assertEqual(len(data.edges), 1)
        self.assertEqual(data.report["scope"]["included_handbooks"], [HANDBOOK_TITLE])


if __name__ == "__main__":
    unittest.main()
