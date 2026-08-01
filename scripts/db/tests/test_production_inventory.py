from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

from scripts.db.tests.test_local_rebuild import build_fixture_repo


REPO_ROOT = Path(__file__).resolve().parents[3]
FAKE_WRANGLER = REPO_ROOT / "scripts" / "db" / "tests" / "fixtures" / "wrangler-production"


class ProductionInventoryTests(unittest.TestCase):
    def _paths(self, root: Path):
        paths = build_fixture_repo(root)
        (paths.backend_dir / "wrangler.jsonc").write_text(
            json.dumps(
                {
                    "d1_databases": [
                        {
                            "binding": "DB",
                            "database_name": "langmap-v2",
                            "database_id": "69a50b71-8cff-4e50-9e73-1e9020d34bd3",
                        }
                    ]
                }
            ),
            encoding="utf-8",
        )
        return paths

    def test_inventory_is_read_only_and_writes_redacted_report(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)
            log_path = root / "wrangler.log"

            from lib.production import inventory_production  # noqa: E402

            report = inventory_production(
                paths,
                wrangler_bin=FAKE_WRANGLER,
                env={"FAKE_PRODUCTION_WRANGLER_LOG": str(log_path)},
            )

            self.assertEqual(report["status"], "ok")
            self.assertEqual(report["identity"]["database_name"], "langmap-v2")
            self.assertEqual(report["counts"]["languages"], 62)
            self.assertEqual(report["counts"]["orphan_expression_edges"], 0)
            self.assertTrue(paths.production_inventory_report_path.exists())
            report_text = paths.production_inventory_report_path.read_text(encoding="utf-8")
            self.assertNotIn("SECRET", report_text)
            calls = log_path.read_text(encoding="utf-8").splitlines()
            self.assertEqual(len(calls), 3)
            self.assertTrue(all("--remote" in call for call in calls))
            self.assertTrue(all("--command" not in call or "SELECT" in call for call in calls[1:]))

    def test_identity_mismatch_fails_before_query(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)
            config = json.loads((paths.backend_dir / "wrangler.jsonc").read_text(encoding="utf-8"))
            config["d1_databases"][0]["database_id"] = "wrong-id"
            (paths.backend_dir / "wrangler.jsonc").write_text(json.dumps(config), encoding="utf-8")
            log_path = root / "wrangler.log"

            from lib.production import ProductionInventoryError, inventory_production  # noqa: E402

            with self.assertRaises(ProductionInventoryError):
                inventory_production(
                    paths,
                    wrangler_bin=FAKE_WRANGLER,
                    env={"FAKE_PRODUCTION_WRANGLER_LOG": str(log_path)},
                )

            calls = log_path.read_text(encoding="utf-8").splitlines()
            self.assertEqual(len(calls), 1)
            self.assertNotIn("--command", calls[0])

    def test_baseline_check_is_pure_and_does_not_write_migrations(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)

            from lib.production import check_baseline, inventory_production  # noqa: E402

            report = inventory_production(paths, wrangler_bin=FAKE_WRANGLER, env={})
            paths.production_baseline_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "identity": report["identity"],
                        "schema_objects": report["schema_objects"],
                        "migration_checksums": report["migrations"]["checksums"],
                    }
                ),
                encoding="utf-8",
            )
            result = check_baseline(paths, report)
            self.assertEqual(result["status"], "ok")

    def test_plan_is_read_only_and_blocks_on_baseline_mismatch(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)
            log_path = root / "wrangler.log"

            from lib.production import plan_production  # noqa: E402

            plan = plan_production(
                paths,
                wrangler_bin=FAKE_WRANGLER,
                env={"FAKE_PRODUCTION_WRANGLER_LOG": str(log_path)},
            )

            self.assertEqual(plan["status"], "blocked")
            self.assertFalse(plan["mutation_allowed"])
            self.assertTrue(plan["operation_id"])
            self.assertEqual(plan["reference_diff"]["counts"]["delete"], 0)
            self.assertTrue((paths.production_plan_dir / f"{plan['operation_id']}.json").exists())
            for line in log_path.read_text(encoding="utf-8").splitlines():
                self.assertNotIn("INSERT", line.upper())
                self.assertNotIn("UPDATE", line.upper())
                self.assertNotIn("DELETE", line.upper())


class ReferenceDiffTests(unittest.TestCase):
    def test_reference_diff_never_deletes_artifact_missing_remote_rows(self) -> None:
        from lib.reference import diff_owned_references

        diff = diff_owned_references(
            {"managed.a": "new", "managed.b": "same"},
            {"managed.a": "old", "managed.b": "same", "remote.only": "keep"},
            owned_keys={"managed.a", "managed.b"},
        )

        self.assertEqual(diff.counts, {"insert": 0, "update": 1, "unchanged": 1, "manual_review": 1, "delete": 0})
        self.assertIn("remote.only", diff.manual_review)
