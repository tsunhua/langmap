from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from scripts.dictionary.release_dictionary import (
    build_parser,
    replay_delta_to_mirror,
    run_release,
)
from scripts.db.tests.test_local_rebuild import build_fixture_repo


class ReleaseDictionaryTests(unittest.TestCase):
    def test_replay_delta_is_batched_and_checks_foreign_keys(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            database = root / "mirror.sqlite"
            delta = root / "delta.sql"
            with sqlite3.connect(database) as connection:
                connection.execute("CREATE TABLE entries (id INTEGER PRIMARY KEY, text TEXT NOT NULL)")
                connection.commit()
            delta.write_text(
                "PRAGMA defer_foreign_keys=TRUE;\n"
                "INSERT OR IGNORE INTO entries (id, text) VALUES (1, 'one');\n"
                "INSERT OR IGNORE INTO entries (id, text) VALUES (2, 'two');\n"
                "PRAGMA defer_foreign_keys=FALSE;\n",
                encoding="utf-8",
            )

            result = replay_delta_to_mirror(database, delta)

            self.assertEqual(result, {"status": "replayed", "batches": 1})
            with sqlite3.connect(database) as connection:
                self.assertEqual(connection.execute("SELECT COUNT(*) FROM entries").fetchone()[0], 2)

    def test_prepare_runs_import_delta_manifest_and_plan_as_one_flow(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            build_fixture_repo(root)
            input_dir = root / "inputs"
            input_dir.mkdir()
            source = input_dir / "demo.jsonl"
            source.write_text("{}\n", encoding="utf-8")
            d1_database = root / "mirror.sqlite"
            d1_database.touch()
            state_path = root / "state.json"
            staging_root = root / "staging"
            snapshot = root / "snapshots" / "before.sqlite"
            snapshot.parent.mkdir()
            snapshot.touch()
            args = build_parser().parse_args(
                [
                    "--repo-root",
                    str(root),
                    "--input-dir",
                    str(input_dir),
                    "--d1-database",
                    str(d1_database),
                    "--state",
                    str(state_path),
                    "--staging-root",
                    str(staging_root),
                    "--release-name",
                    "023-demo",
                ]
            )

            def fake_export(before, after, output, *, manifest):
                self.assertEqual(before, snapshot)
                self.assertEqual(after, d1_database.resolve())
                output.write_text("-- delta\n", encoding="utf-8")
                manifest.write_text("{}\n", encoding="utf-8")
                return {"expressions": 1}

            with mock.patch(
                "scripts.dictionary.release_dictionary.run_incremental_import",
                return_value=[
                    {
                        "status": "success",
                        "file": source.name,
                        "before_snapshot_path": str(snapshot),
                    }
                ],
            ) as importer, mock.patch(
                "scripts.dictionary.release_dictionary.export_delta",
                side_effect=fake_export,
            ) as exporter, mock.patch(
                "scripts.dictionary.release_dictionary.plan_production",
                return_value={"status": "ready", "operation_id": "operation-123"},
            ) as planner:
                result = run_release(args)

            self.assertEqual(result["status"], "planned")
            self.assertEqual(result["delta"]["counts"], {"expressions": 1})
            self.assertEqual(result["postflight_manifest"], "scripts/db/state/backup/delta/023-demo.manifest.json")
            importer.assert_called_once()
            exporter.assert_called_once()
            planner.assert_called_once()
            plan_kwargs = planner.call_args.kwargs
            self.assertEqual(
                plan_kwargs["approved_data_migration"],
                Path("scripts/db/state/backup/delta/023-demo.sql"),
            )
            self.assertEqual(
                plan_kwargs["dictionary_postflight_manifest"],
                Path("scripts/db/state/backup/delta/023-demo.manifest.json"),
            )

    def test_apply_requires_exact_database_confirmation(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            build_fixture_repo(root)
            input_dir = root / "inputs"
            input_dir.mkdir()
            (input_dir / "demo.jsonl").write_text("{}\n", encoding="utf-8")
            d1_database = root / "mirror.sqlite"
            d1_database.touch()
            snapshot = root / "before.sqlite"
            snapshot.touch()
            args = build_parser().parse_args(
                [
                    "--repo-root",
                    str(root),
                    "--input-dir",
                    str(input_dir),
                    "--d1-database",
                    str(d1_database),
                    "--state",
                    str(root / "state.json"),
                    "--staging-root",
                    str(root / "staging"),
                    "--release-name",
                    "023-demo",
                    "--apply",
                    "--database-name",
                    "langmap-v2",
                ]
            )
            with mock.patch(
                "scripts.dictionary.release_dictionary.run_incremental_import",
                return_value=[
                    {"status": "success", "before_snapshot_path": str(snapshot)}
                ],
            ), mock.patch(
                "scripts.dictionary.release_dictionary.export_delta",
                side_effect=lambda before, after, output, *, manifest: (
                    output.write_text("-- delta\n", encoding="utf-8"),
                    manifest.write_text("{}\n", encoding="utf-8"),
                    {},
                )[-1],
            ), mock.patch(
                "scripts.dictionary.release_dictionary.plan_production",
                return_value={"status": "ready", "operation_id": "operation-123"},
            ):
                with self.assertRaisesRegex(ValueError, "database-name"):
                    run_release(args)


if __name__ == "__main__":
    unittest.main()
