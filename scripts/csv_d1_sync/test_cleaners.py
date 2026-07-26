import csv
import tempfile
import unittest
from pathlib import Path

from cleaners.base import (
    expand_parenthetical_variants,
    normalize_text,
    remove_trailing_supplement,
    split_outside_parentheses,
)
from cleaners.chhoe_taigi import ChhoeTaigiTaioanPehoeKichhooGikuCleaner


class ChhoeTaigiCleanerTest(unittest.TestCase):
    def test_cleans_headers_variants_and_examples(self):
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary) / "source.csv"
            headers = sorted(
                ChhoeTaigiTaioanPehoeKichhooGikuCleaner.required_columns
            )
            with source.open("w", encoding="utf-8", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=headers)
                writer.writeheader()
                writer.writerow(
                    {
                        "PojUnicode": "  lí  ",
                        "PojUnicodeOthers": "lír/lí",
                        "KipUnicode": "lí",
                        "KipUnicodeOthers": "",
                        "HoaBun": "你、妳",
                        "EngBun": "you",
                        "LekuPoj": "Lí hó/Lí chia̍h pá--bōe?",
                        "LekuHoabun": "你好／你吃飽了嗎？",
                        "LekuEngbun": "Hello\\Have you eaten?",
                    }
                )

            result = ChhoeTaigiTaioanPehoeKichhooGikuCleaner().clean(source)

            self.assertEqual(
                result.headers, ["nan-TW-Latn-pehoeji", "nan-TW-Latn-tailo", "zh-Hant-TW", "en-US"]
            )
            self.assertEqual(result.source_rows, 1)
            self.assertEqual(len(result.rows), 3)
            self.assertEqual(result.rows[0]["nan-TW-Latn-pehoeji"], "lí | lír")
            self.assertEqual(result.rows[0]["zh-Hant-TW"], "你 | 妳")
            self.assertEqual(result.rows[1]["en-US"], "Hello")
            self.assertEqual(result.rows[2]["zh-Hant-TW"], "你吃飽了嗎？")

    def test_expands_parenthetical_replacement(self):
        self.assertEqual(
            expand_parenthetical_variants("戲單(票)"), ["戲單", "戲票"]
        )
        self.assertEqual(
            expand_parenthetical_variants("我(我們)要去"), ["我要去", "我們要去"]
        )

    def test_splits_english_list_outside_parentheses(self):
        self.assertEqual(
            split_outside_parentheses(
                "girdle, belt, ribbon (cloth, silk)", ",;"
            ),
            ["girdle", "belt", "ribbon (cloth, silk)"],
        )

    def test_removes_trailing_english_supplement(self):
        self.assertEqual(
            remove_trailing_supplement(
                "a reel of tape (i.e. for the electric recorder)"
            ),
            "a reel of tape",
        )
        self.assertEqual(
            remove_trailing_supplement(
                "As soos as they lifed the red hat and took a look…. "
                "(Cf. Story of [Gô-Hōng])"
            ),
            "As soos as they lifed the red hat and took a look….",
        )
        self.assertEqual(
            remove_trailing_supplement("a car (or any vehicle)"),
            "a car (or any vehicle)",
        )

    def test_removes_edge_noise(self):
        self.assertEqual(normalize_text(" €燃燒 "), "燃燒")
        self.assertEqual(normalize_text("燃著€"), "燃著")


if __name__ == "__main__":
    unittest.main()
