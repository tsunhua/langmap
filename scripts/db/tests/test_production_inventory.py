from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

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
            self.assertEqual(report["counts"]["managed_ui_edges"], 1058)
            self.assertEqual(report["counts"]["orphan_expression_edges"], 0)
            self.assertTrue(paths.production_inventory_report_path.exists())
            report_text = paths.production_inventory_report_path.read_text(encoding="utf-8")
            self.assertNotIn("SECRET", report_text)
            calls = log_path.read_text(encoding="utf-8").splitlines()
            self.assertEqual(len(calls), 4)
            self.assertNotIn("--remote", calls[0])
            self.assertTrue(all("--remote" in call for call in calls[1:]))
            self.assertTrue(
                all(
                    "--command" not in call
                    or "SELECT" in call
                    or "PRAGMA" in call
                    for call in calls[1:]
                )
            )
            self.assertIn("PRAGMA table_info", calls[2])

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

            with mock.patch("lib.production._current_git_commit", return_value="fixture-commit"):
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

    def test_plan_records_approved_data_migration_with_repo_relative_path_and_sha(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)
            log_path = root / "wrangler.log"
            data_path = root / "scripts" / "db" / "state" / "approved-delta.sql"
            data_path.parent.mkdir(parents=True, exist_ok=True)
            data_path.write_text("INSERT INTO expressions (id) VALUES (1);", encoding="utf-8")

            from lib.production import ProductionInventoryError, plan_production  # noqa: E402

            with mock.patch("lib.production._current_git_commit", return_value="fixture-commit"):
                plan = plan_production(
                    paths,
                    wrangler_bin=FAKE_WRANGLER,
                    env={"FAKE_PRODUCTION_WRANGLER_LOG": str(log_path)},
                    approved_data_migration=Path("scripts/db/state/approved-delta.sql"),
                )

            self.assertIsNotNone(plan["approved_data_migration"])
            recorded = plan["approved_data_migration"]
            self.assertEqual(recorded["path"], "scripts/db/state/approved-delta.sql")
            self.assertEqual(
                recorded["sha256"],
                hashlib.sha256(data_path.read_bytes()).hexdigest(),
            )
            stored = json.loads(
                (paths.production_plan_dir / f"{plan['operation_id']}.json").read_text(encoding="utf-8")
            )
            self.assertEqual(stored["approved_data_migration"], recorded)

            with mock.patch("lib.production._current_git_commit", return_value="fixture-commit"):
                with self.assertRaises(ProductionInventoryError):
                    plan_production(
                        paths,
                        wrangler_bin=FAKE_WRANGLER,
                        env={"FAKE_PRODUCTION_WRANGLER_LOG": str(log_path)},
                        approved_data_migration=Path("../outside.sql"),
                    )

    def test_data_only_plan_skips_unchanged_reference_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)
            log_path = root / "wrangler.log"
            data_path = root / "scripts" / "db" / "state" / "approved-delta.sql"
            data_path.parent.mkdir(parents=True, exist_ok=True)
            data_path.write_text(
                "INSERT OR IGNORE INTO expressions (id) VALUES (1);",
                encoding="utf-8",
            )
            ui_manifest = json.loads(paths.ui_bundle_manifest_path.read_text(encoding="utf-8"))
            ui_manifest["counts"].update(
                {"message_count": 312, "translation_count": 1058}
            )
            paths.ui_bundle_manifest_path.write_text(
                json.dumps(ui_manifest), encoding="utf-8"
            )
            language_manifest = json.loads(
                paths.language_manifest_path.read_text(encoding="utf-8")
            )
            language_manifest["counts"]["languages"] = 62
            paths.language_manifest_path.write_text(
                json.dumps(language_manifest), encoding="utf-8"
            )

            from lib.production import apply_production, inventory_production, plan_production  # noqa: E402

            inventory = inventory_production(paths, wrangler_bin=FAKE_WRANGLER, env={})
            paths.production_baseline_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "identity": inventory["identity"],
                        "schema_objects": inventory["schema_objects"],
                        "migration_checksums": inventory["migrations"]["checksums"],
                    }
                ),
                encoding="utf-8",
            )
            with mock.patch("lib.production._current_git_commit", return_value="fixture-commit"):
                plan = plan_production(
                    paths,
                    wrangler_bin=FAKE_WRANGLER,
                    env={"FAKE_PRODUCTION_WRANGLER_LOG": str(log_path)},
                    approved_data_migration=Path("scripts/db/state/approved-delta.sql"),
                )

            self.assertEqual(
                plan["reference_artifacts"],
                {"action": "skip", "reason": "unchanged-data-only-release"},
            )
            log_path.write_text("", encoding="utf-8")
            with mock.patch("lib.production._current_git_commit", return_value="fixture-commit"):
                result = apply_production(
                    paths,
                    plan_path=paths.production_plan_dir / f"{plan['operation_id']}.json",
                    database_name="langmap-v2",
                    confirmation="langmap-v2",
                    wrangler_bin=FAKE_WRANGLER,
                    env={
                        "FAKE_PRODUCTION_WRANGLER_LOG": str(log_path),
                        "FAKE_PRODUCTION_ALLOW_MUTATIONS": "1",
                    },
                )

            self.assertEqual(result["status"], "succeeded")
            calls = [json.loads(line) for line in log_path.read_text(encoding="utf-8").splitlines()]
            file_paths = [
                call[call.index("--file") + 1]
                for call in calls
                if "--file" in call
            ]
            self.assertEqual([Path(path).name for path in file_paths], ["approved-delta.sql"])

    def test_split_sql_is_grouped_into_bounded_batches(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "approved.split.sql"
            path.write_text(
                "INSERT OR IGNORE INTO expressions (id) VALUES (1);\n"
                "INSERT OR IGNORE INTO expressions (id) VALUES (2);\n"
                "INSERT OR IGNORE INTO expressions (id) VALUES (3);\n",
                encoding="utf-8",
            )

            from lib.production import _approved_sql_batches  # noqa: E402

            batches = list(_approved_sql_batches(path, max_bytes=120))

            self.assertEqual([index for index, _ in batches], [0, 1])
            self.assertIn("VALUES (1);\nINSERT OR IGNORE", batches[0][1])
            self.assertLessEqual(len(batches[0][1].encode("utf-8")), 120)
            self.assertIn("VALUES (3);", batches[1][1])

    def test_split_apply_resumes_from_last_successful_batch(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)
            log_path = root / "wrangler.log"
            data_path = root / "scripts" / "db" / "state" / "approved.split.sql"
            data_path.parent.mkdir(parents=True, exist_ok=True)
            data_path.write_text(
                "INSERT OR IGNORE INTO expressions (id) VALUES (1);\n"
                "INSERT OR IGNORE INTO expressions (id) VALUES (2);\n"
                "INSERT OR IGNORE INTO expressions (id) VALUES (3);\n",
                encoding="utf-8",
            )

            from lib import production as production_lib  # noqa: E402

            inventory = production_lib.inventory_production(
                paths, wrangler_bin=FAKE_WRANGLER, env={}
            )
            paths.production_baseline_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "identity": inventory["identity"],
                        "schema_objects": inventory["schema_objects"],
                        "migration_checksums": inventory["migrations"]["checksums"],
                    }
                ),
                encoding="utf-8",
            )
            plan_path = paths.production_plan_dir / "split-resume-plan.json"
            plan_path.parent.mkdir(parents=True, exist_ok=True)
            plan_path.write_text(
                json.dumps(
                    {
                        "status": "ready",
                        "operation_id": "split-resume-operation",
                        "identity": inventory["identity"],
                        "git_commit": "fixture-commit",
                        "pending_migrations": [],
                        "approved_data_migration": {
                            "path": "scripts/db/state/approved.split.sql",
                            "sha256": hashlib.sha256(data_path.read_bytes()).hexdigest(),
                            "bytes": data_path.stat().st_size,
                            "mode": "split",
                        },
                        "dictionary_artifact": None,
                        "reference_artifacts": {
                            "action": "skip",
                            "reason": "unchanged-data-only-release",
                        },
                    }
                ),
                encoding="utf-8",
            )
            apply_kwargs = {
                "plan_path": plan_path,
                "database_name": "langmap-v2",
                "confirmation": "langmap-v2",
                "wrangler_bin": FAKE_WRANGLER,
                "env": {
                    "FAKE_PRODUCTION_WRANGLER_LOG": str(log_path),
                    "FAKE_PRODUCTION_ALLOW_MUTATIONS": "1",
                },
            }
            mutation_calls: list[list[str]] = []
            failed = False

            def mutate_once_then_fail(_executor, args):
                nonlocal failed
                mutation_calls.append(args)
                if "--command" in args and not failed:
                    failed = True
                    return ""
                if "--command" in args and len(mutation_calls) == 2:
                    raise production_lib.ProductionInventoryError("batch unavailable")
                return ""

            with mock.patch.object(
                production_lib, "_current_git_commit", return_value="fixture-commit"
            ), mock.patch.object(
                production_lib, "SPLIT_SQL_BATCH_BYTES", 80
            ), mock.patch.object(
                production_lib.ProductionExecutor,
                "mutate",
                autospec=True,
                side_effect=mutate_once_then_fail,
            ):
                with self.assertRaisesRegex(
                    production_lib.ProductionInventoryError, "batch unavailable"
                ):
                    production_lib.apply_production(paths, **apply_kwargs)

            with mock.patch.object(
                production_lib, "_current_git_commit", return_value="fixture-commit"
            ), mock.patch.object(
                production_lib, "SPLIT_SQL_BATCH_BYTES", 80
            ), mock.patch.object(
                production_lib.ProductionExecutor,
                "mutate",
                autospec=True,
                side_effect=lambda _executor, args: mutation_calls.append(args),
            ):
                result = production_lib.apply_production(paths, **apply_kwargs)

            self.assertEqual(result["status"], "succeeded")
            self.assertEqual(
                sum("--command" in args for args in mutation_calls),
                4,
            )
            self.assertEqual(
                sum(
                    "VALUES (1);" in args[args.index("--command") + 1]
                    for args in mutation_calls
                    if "--command" in args
                ),
                1,
            )
            self.assertIn("data-batch-applied", paths.production_operation_journal_path.read_text(encoding="utf-8"))

    def test_apply_requires_confirmation_and_bookmarks_before_mutation(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)
            log_path = root / "wrangler.log"

            from lib.production import apply_production, inventory_production  # noqa: E402

            inventory = inventory_production(paths, wrangler_bin=FAKE_WRANGLER, env={})
            paths.production_baseline_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "identity": inventory["identity"],
                        "schema_objects": inventory["schema_objects"],
                        "migration_checksums": inventory["migrations"]["checksums"],
                    }
                ),
                encoding="utf-8",
            )
            plan_path = paths.production_plan_dir / "fixture-plan.json"
            plan_path.parent.mkdir(parents=True, exist_ok=True)
            plan_path.write_text(
                json.dumps(
                    {
                        "status": "ready",
                        "operation_id": "fixture-operation",
                        "identity": inventory["identity"],
                        "git_commit": "fixture-commit",
                        "pending_migrations": [],
                    }
                ),
                encoding="utf-8",
            )

            from lib import production as production_lib  # noqa: E402

            with mock.patch.object(production_lib, "_current_git_commit", return_value="fixture-commit"):
                result = apply_production(
                    paths,
                    plan_path=plan_path,
                    database_name="langmap-v2",
                    confirmation="langmap-v2",
                    wrangler_bin=FAKE_WRANGLER,
                    env={
                        "FAKE_PRODUCTION_WRANGLER_LOG": str(log_path),
                        "FAKE_PRODUCTION_ALLOW_MUTATIONS": "1",
                    },
                )

            self.assertEqual(result["status"], "succeeded")
            calls = [json.loads(line) for line in log_path.read_text(encoding="utf-8").splitlines()]
            time_travel_index = next(i for i, call in enumerate(calls) if "time-travel" in call)
            mutation_indices = [
                i for i, call in enumerate(calls) if "--file" in call or "migrations" in call
            ]
            self.assertTrue(mutation_indices)
            self.assertLess(time_travel_index, min(mutation_indices))
            journal = paths.production_operation_journal_path.read_text(encoding="utf-8")
            self.assertIn('"status": "succeeded"', journal)

    def test_apply_resumes_after_data_stage_without_replaying_delta(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)
            log_path = root / "wrangler.log"
            data_path = root / "scripts" / "db" / "state" / "approved-delta.sql"
            data_path.parent.mkdir(parents=True, exist_ok=True)
            data_path.write_text(
                "INSERT OR IGNORE INTO expressions (id) VALUES (1);",
                encoding="utf-8",
            )

            from lib import production as production_lib  # noqa: E402

            inventory = production_lib.inventory_production(
                paths, wrangler_bin=FAKE_WRANGLER, env={}
            )
            paths.production_baseline_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "identity": inventory["identity"],
                        "schema_objects": inventory["schema_objects"],
                        "migration_checksums": inventory["migrations"]["checksums"],
                    }
                ),
                encoding="utf-8",
            )
            plan_path = paths.production_plan_dir / "resume-plan.json"
            plan_path.parent.mkdir(parents=True, exist_ok=True)
            plan_path.write_text(
                json.dumps(
                    {
                        "status": "ready",
                        "operation_id": "resume-operation",
                        "identity": inventory["identity"],
                        "git_commit": "fixture-commit",
                        "pending_migrations": [],
                        "approved_data_migration": {
                            "path": "scripts/db/state/approved-delta.sql",
                            "sha256": hashlib.sha256(data_path.read_bytes()).hexdigest(),
                            "bytes": data_path.stat().st_size,
                            "mode": "file",
                        },
                        "dictionary_artifact": None,
                        "reference_artifacts": {
                            "action": "skip",
                            "reason": "unchanged-data-only-release",
                        },
                    }
                ),
                encoding="utf-8",
            )
            apply_kwargs = {
                "plan_path": plan_path,
                "database_name": "langmap-v2",
                "confirmation": "langmap-v2",
                "wrangler_bin": FAKE_WRANGLER,
                "env": {
                    "FAKE_PRODUCTION_WRANGLER_LOG": str(log_path),
                    "FAKE_PRODUCTION_ALLOW_MUTATIONS": "1",
                },
            }

            with mock.patch.object(
                production_lib, "_current_git_commit", return_value="fixture-commit"
            ), mock.patch.object(
                production_lib,
                "inventory_production",
                side_effect=production_lib.ProductionInventoryError("verify unavailable"),
            ):
                with self.assertRaisesRegex(
                    production_lib.ProductionInventoryError, "verify unavailable"
                ):
                    production_lib.apply_production(paths, **apply_kwargs)

            with mock.patch.object(
                production_lib, "_current_git_commit", return_value="fixture-commit"
            ):
                result = production_lib.apply_production(paths, **apply_kwargs)

            self.assertEqual(result["status"], "succeeded")
            self.assertTrue(result["resumed"])
            calls = [json.loads(line) for line in log_path.read_text(encoding="utf-8").splitlines()]
            delta_calls = [
                call for call in calls
                if "--file" in call and Path(call[call.index("--file") + 1]).name == "approved-delta.sql"
            ]
            bookmark_calls = [call for call in calls if "time-travel" in call]
            self.assertEqual(len(delta_calls), 1)
            self.assertEqual(len(bookmark_calls), 1)
            events = [
                json.loads(line)
                for line in paths.production_operation_journal_path.read_text(encoding="utf-8").splitlines()
            ]
            self.assertIn("data-applied", {event["status"] for event in events})
            self.assertEqual(events[-1]["status"], "succeeded")

    def test_restore_verifies_after_restore_and_records_previous_bookmark(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)
            log_path = root / "wrangler.log"

            from lib.production import inventory_production, restore_production  # noqa: E402

            inventory = inventory_production(paths, wrangler_bin=FAKE_WRANGLER, env={})
            paths.production_baseline_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "identity": inventory["identity"],
                        "schema_objects": inventory["schema_objects"],
                        "migration_checksums": inventory["migrations"]["checksums"],
                    }
                ),
                encoding="utf-8",
            )
            result = restore_production(
                paths,
                bookmark="bookmark-123",
                database_name="langmap-v2",
                confirmation="langmap-v2",
                wrangler_bin=FAKE_WRANGLER,
                env={
                    "FAKE_PRODUCTION_ALLOW_MUTATIONS": "1",
                    "FAKE_PRODUCTION_WRANGLER_LOG": str(log_path),
                },
            )

            self.assertEqual(result["status"], "succeeded")
            self.assertEqual(result["previous_bookmark"], "previous-bookmark-123")
            journal = paths.production_operation_journal_path.read_text(encoding="utf-8")
            self.assertIn('"previous_bookmark": "previous-bookmark-123"', journal)
            calls = [json.loads(line) for line in log_path.read_text(encoding="utf-8").splitlines()]
            restore_call = next(call for call in calls if "restore" in call)
            self.assertNotIn("--remote", restore_call)

    def test_verify_checks_baseline_and_orphan_counts_read_only(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)

            from lib.production import inventory_production, verify_production  # noqa: E402

            inventory = inventory_production(paths, wrangler_bin=FAKE_WRANGLER, env={})
            paths.production_baseline_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "identity": inventory["identity"],
                        "schema_objects": inventory["schema_objects"],
                        "migration_checksums": inventory["migrations"]["checksums"],
                    }
                ),
                encoding="utf-8",
            )
            result = verify_production(paths, wrangler_bin=FAKE_WRANGLER, env={})

            self.assertEqual(result["status"], "ok")
            self.assertEqual(result["counts"]["orphan_expression_edges"], 0)

    def test_manage_cli_routes_production_verify(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = self._paths(root)

            from lib.production import inventory_production  # noqa: E402

            inventory = inventory_production(paths, wrangler_bin=FAKE_WRANGLER, env={})
            paths.production_baseline_path.write_text(
                json.dumps(
                    {
                        "schema_version": 1,
                        "identity": inventory["identity"],
                        "schema_objects": inventory["schema_objects"],
                        "migration_checksums": inventory["migrations"]["checksums"],
                    }
                ),
                encoding="utf-8",
            )
            result = subprocess.run(
                [
                    sys.executable,
                    str(REPO_ROOT / "scripts/db/manage.py"),
                    "--repo-root",
                    str(root),
                    "production",
                    "verify",
                ],
                cwd=REPO_ROOT,
                env={**os.environ, "LANGMAP_WRANGLER_BIN": str(FAKE_WRANGLER)},
                capture_output=True,
                text=True,
            )

            self.assertEqual(result.returncode, 0, msg=result.stderr)
            self.assertEqual(json.loads(result.stdout)["status"], "ok")


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

    def test_high_risk_migration_requires_reversible_preflight_and_postflight_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            migration = Path(temp_dir) / "0012_rebuild.sql"
            migration.write_text("ALTER TABLE languages RENAME TO languages_old;\n", encoding="utf-8")

            from lib.production import ProductionInventoryError, load_migration_metadata  # noqa: E402

            with self.assertRaises(ProductionInventoryError):
                load_migration_metadata(migration)

            metadata = migration.with_suffix(".meta.json")
            metadata.write_text(
                json.dumps(
                    {
                        "preflight": ["assert languages exists"],
                        "postflight": ["assert languages row count reconciles"],
                        "reversible": True,
                    }
                ),
                encoding="utf-8",
            )
            self.assertEqual(load_migration_metadata(migration)["reversible"], True)


class ApprovedSqlSplitTests(unittest.TestCase):
    def test_split_approved_sql_ignores_comments_and_pragmas(self) -> None:
        from lib.production import _split_approved_sql  # noqa: E402

        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "x.sql"
            path.write_text(
                "-- header comment\n"
                "PRAGMA defer_foreign_keys=TRUE;\n"
                "DELETE FROM expression_sources\n"
                " WHERE source_id = 17;\n"
                "DELETE FROM expressions WHERE source_id = 17;\n"
                "PRAGMA defer_foreign_keys=FALSE;\n",
                encoding="utf-8",
            )
            statements = _split_approved_sql(path)
            self.assertEqual(len(statements), 2)
            self.assertIn("DELETE FROM expression_sources", statements[0])
            self.assertIn("DELETE FROM expressions", statements[1])

    def test_plan_marks_split_mode_for_dot_split_sql(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = ProductionInventoryTests._paths(self, root)
            log_path = root / "wrangler.log"
            data_path = root / "scripts" / "db" / "state" / "approved.split.sql"
            data_path.parent.mkdir(parents=True, exist_ok=True)
            data_path.write_text("DELETE FROM sources WHERE name='x';\n", encoding="utf-8")

            from lib.production import plan_production  # noqa: E402

            with mock.patch("lib.production._current_git_commit", return_value="fixture-commit"):
                plan = plan_production(
                    paths,
                    wrangler_bin=FAKE_WRANGLER,
                    env={"FAKE_PRODUCTION_WRANGLER_LOG": str(log_path)},
                    approved_data_migration=Path("scripts/db/state/approved.split.sql"),
                )
            self.assertEqual(plan["approved_data_migration"]["mode"], "split")
