import csv
import json
import tempfile
import unittest
from pathlib import Path

from csv_d1_sync import (
    ColumnSpec,
    extract,
    expression_id,
    expression_id_segments,
    infer_column_specs,
    language_prefix_id,
    parse_schema_counts,
    parser,
    resolve_persist_to,
    text_segment_id,
    write_sql_batches,
)


class CsvD1SyncTest(unittest.TestCase):
    def test_local_defaults_to_config_wrangler_state(self):
        config = Path("/project/backend/wrangler.jsonc")
        self.assertEqual(
            resolve_persist_to(config, False, None),
            Path("/project/backend/.wrangler/state"),
        )
        self.assertIsNone(resolve_persist_to(config, True, None))

    def test_default_batch_size_is_500(self):
        args = parser().parse_args(["sample.csv", "--local"])
        self.assertEqual(args.batch_size, 500)

    def test_parses_wrangler_schema_status(self):
        payload = json.dumps(
            [{"results": [{"table_count": 17, "required_count": 2}]}]
        )
        self.assertEqual(parse_schema_counts(payload), (17, 2))

    def test_expression_id_has_language_prefix_and_text_segment(self):
        value = expression_id("zh-Hant-TW", "戲票")
        self.assertEqual(value, expression_id("zh-Hant-TW", "戲票"))
        self.assertEqual(
            expression_id_segments(value),
            (
                language_prefix_id("zh-Hant-TW"),
                text_segment_id("戲票"),
            ),
        )
        self.assertLessEqual(value, 2**53 - 1)
        self.assertEqual(
            expression_id_segments(expression_id("zh-Hant-TW", "戲單"))[0],
            expression_id_segments(value)[0],
        )
        self.assertNotEqual(
            expression_id_segments(expression_id("en-US", "戲票"))[0],
            expression_id_segments(value)[0],
        )

    def test_infers_language_codes_from_headers(self):
        with tempfile.TemporaryDirectory() as temporary:
            csv_path = Path(temporary) / "sample.csv"
            csv_path.write_text("en-US,zh-Hant-TW\nhello,你好\n", encoding="utf-8")

            self.assertEqual(
                infer_column_specs(csv_path),
                [
                    ColumnSpec("en-US", "en-US"),
                    ColumnSpec("zh-Hant-TW", "zh-Hant-TW"),
                ],
            )

    def test_extracts_deduplicated_expressions_and_pairwise_edges(self):
        with tempfile.TemporaryDirectory() as temporary:
            csv_path = Path(temporary) / "sample.csv"
            with csv_path.open("w", encoding="utf-8", newline="") as target:
                writer = csv.DictWriter(
                    target, fieldnames=["nan-TW-Latn-pehoeji", "zh-Hant-TW", "en-US"]
                )
                writer.writeheader()
                writer.writerow(
                    {"nan-TW-Latn-pehoeji": "lí", "zh-Hant-TW": "你 | 妳", "en-US": "you"}
                )
                writer.writerow(
                    {"nan-TW-Latn-pehoeji": "lí", "zh-Hant-TW": "你", "en-US": "you"}
                )

            expressions, edges, rows = extract(
                csv_path,
                [
                    ColumnSpec("nan-TW-Latn-pehoeji", "nan-TW-Latn-pehoeji"),
                    ColumnSpec("zh-Hant-TW", "zh-Hant-TW"),
                    ColumnSpec("en-US", "en-US"),
                ],
            )

            self.assertEqual(rows, 2)
            self.assertEqual(len(expressions), 4)
            self.assertEqual(len(edges), 6)
            self.assertEqual(
                [(edge.expression_a_id, edge.expression_b_id) for edge in edges],
                sorted(
                    (edge.expression_a_id, edge.expression_b_id) for edge in edges
                ),
            )

    def test_accepts_delimited_values_in_one_cell(self):
        with tempfile.TemporaryDirectory() as temporary:
            csv_path = Path(temporary) / "sample.csv"
            with csv_path.open("w", encoding="utf-8", newline="") as target:
                writer = csv.DictWriter(target, fieldnames=["en-US", "zh-Hant-TW"])
                writer.writeheader()
                writer.writerow({"en-US": "girdle | belt", "zh-Hant-TW": "腰帶"})

            expressions, edges, _ = extract(
                csv_path,
                [
                    ColumnSpec("en-US", "en-US"),
                    ColumnSpec("zh-Hant-TW", "zh-Hant-TW"),
                ],
            )
            self.assertEqual(len(expressions), 3)
            self.assertEqual(len(edges), 3)

    def test_writes_expression_batches_before_edge_batches(self):
        with tempfile.TemporaryDirectory() as temporary:
            csv_path = Path(temporary) / "sample.csv"
            csv_path.write_text("en-US,zh-Hant-TW\nhello,你好\n", encoding="utf-8")
            expressions, edges, _ = extract(
                csv_path,
                [
                    ColumnSpec("en-US", "en-US"),
                    ColumnSpec("zh-Hant-TW", "zh-Hant-TW"),
                ],
            )
            output = Path(temporary) / "sql"
            files = write_sql_batches(
                output, expressions, edges, 1, "dictionary", "sample.csv", "範例"
            )

            self.assertEqual(
                [path.name for path in files],
                ["expressions-0001.sql", "expressions-0002.sql", "edges-0001.sql"],
            )
            manifest = json.loads((output / "manifest.json").read_text())
            self.assertEqual(manifest["expressions"], 2)
            self.assertEqual(manifest["edges"], 1)
            self.assertIn('["範例"]', (output / "expressions-0001.sql").read_text())


if __name__ == "__main__":
    unittest.main()
