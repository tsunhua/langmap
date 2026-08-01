from __future__ import annotations

import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPTS_DB_DIR = REPO_ROOT / "scripts" / "db"
FIXTURE_WRANGLER = REPO_ROOT / "scripts" / "db" / "tests" / "fixtures" / "wrangler-local"

if str(SCRIPTS_DB_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DB_DIR))


from scripts.db.tests.test_local_rebuild import build_fixture_repo  # noqa: E402


class VerifyTests(unittest.TestCase):
    def _assert_baseline_not_written(self, database_path: Path) -> None:
        self.assertTrue(database_path.exists())
        connection = sqlite3.connect(database_path)
        try:
            table = connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'd1_migrations'"
            ).fetchone()
        finally:
            connection.close()
        self.assertIsNone(table)

    def test_verify_reports_expected_counts_and_zero_orphans(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)

            from lib import local as local_lib  # noqa: E402
            from lib import verify as verify_lib  # noqa: E402

            local_lib.rebuild_local_state(
                paths,
                wrangler_bin=FIXTURE_WRANGLER,
                env={},
                owner="test-owner",
                created_at="2026-08-01T00:00:00Z",
            )

            report = verify_lib.verify_local_state(
                paths,
                wrangler_bin=FIXTURE_WRANGLER,
                env={},
            )

            self.assertEqual(report["status"], "ok")
            self.assertEqual(report["counts"]["languages"]["actual"], 4)
            self.assertEqual(report["counts"]["languoids"]["actual"], 3)
            self.assertEqual(report["counts"]["language_subtags"]["actual"], 3)
            self.assertEqual(report["counts"]["language_locations"]["actual"], 2)
            self.assertEqual(report["counts"]["ui_locales"]["actual"], 2)
            self.assertEqual(report["counts"]["ui_messages"]["actual"], 2)
            self.assertEqual(report["counts"]["ui_translation_mappings"]["actual"], 4)
            self.assertEqual(report["active_locale_codes"]["actual"], ["es-ES", "zh-Hant-TW"])
            self.assertEqual(report["orphans"]["languages"], 0)
            self.assertEqual(report["orphans"]["locales"], 0)
            self.assertEqual(report["orphans"]["messages"], 0)
            self.assertEqual(report["orphans"]["edges"], 0)

            written = json.loads((paths.local_state_dir / "verification-report.json").read_text(encoding="utf-8"))
            self.assertEqual(written["status"], "ok")

    def test_verify_rejects_unknown_migration_rows(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)

            from lib import local as local_lib  # noqa: E402
            from lib import verify as verify_lib  # noqa: E402

            local_lib.rebuild_local_state(
                paths,
                wrangler_bin=FIXTURE_WRANGLER,
                env={},
                owner="test-owner",
                created_at="2026-08-01T00:00:00Z",
            )

            database_path = paths.local_d1_state_dir / "fake-d1.sqlite3"
            connection = sqlite3.connect(database_path)
            try:
                connection.execute("INSERT INTO d1_migrations (name) VALUES ('9999_bad.sql')")
                connection.commit()
            finally:
                connection.close()

            with self.assertRaises(verify_lib.LocalVerificationError):
                verify_lib.verify_local_state(
                    paths,
                    wrangler_bin=FIXTURE_WRANGLER,
                    env={},
                )

    def test_verify_rejects_repo_migration_checksum_drift(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)

            from lib import local as local_lib  # noqa: E402
            from lib import verify as verify_lib  # noqa: E402

            local_lib.rebuild_local_state(
                paths,
                wrangler_bin=FIXTURE_WRANGLER,
                env={},
                owner="test-owner",
                created_at="2026-08-01T00:00:00Z",
            )

            (paths.migrations_dir / "0002_init.sql").write_text("ALTER TABLE languages ADD COLUMN broken TEXT;\n", encoding="utf-8")

            with self.assertRaises(verify_lib.LocalVerificationError):
                verify_lib.verify_local_state(paths, wrangler_bin=FIXTURE_WRANGLER, env={})

    def test_verify_rejects_tampered_lock_checksum(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)

            from lib import local as local_lib  # noqa: E402
            from lib import verify as verify_lib  # noqa: E402

            local_lib.rebuild_local_state(
                paths,
                wrangler_bin=FIXTURE_WRANGLER,
                env={},
                owner="test-owner",
                created_at="2026-08-01T00:00:00Z",
            )

            payload = json.loads(paths.migration_lock_path.read_text(encoding="utf-8"))
            payload["migrations"][0]["sha256"] = "0" * 64
            paths.migration_lock_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

            with self.assertRaises(verify_lib.LocalVerificationError):
                verify_lib.verify_local_state(paths, wrangler_bin=FIXTURE_WRANGLER, env={})

    def test_verify_rejects_missing_expected_index_before_baseline(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)

            from lib import local as local_lib  # noqa: E402

            with self.assertRaises(local_lib.LocalRebuildError) as context:
                local_lib.rebuild_local_state(
                    paths,
                    wrangler_bin=FIXTURE_WRANGLER,
                    env={"FAKE_WRANGLER_SKIP_PATTERN": "CREATE INDEX idx_expression_edges_a_id"},
                    owner="test-owner",
                    created_at="2026-08-01T00:00:00Z",
                )

            self._assert_baseline_not_written(context.exception.temp_state_dir / "fake-d1.sqlite3")

    def test_verify_rejects_missing_expected_trigger_before_baseline(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)

            from lib import local as local_lib  # noqa: E402

            with self.assertRaises(local_lib.LocalRebuildError) as context:
                local_lib.rebuild_local_state(
                    paths,
                    wrangler_bin=FIXTURE_WRANGLER,
                    env={"FAKE_WRANGLER_SKIP_PATTERN": "CREATE TRIGGER expressions_ai"},
                    owner="test-owner",
                    created_at="2026-08-01T00:00:00Z",
                )

            self._assert_baseline_not_written(context.exception.temp_state_dir / "fake-d1.sqlite3")

    def test_verify_rejects_missing_expected_virtual_table_before_baseline(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)

            from lib import local as local_lib  # noqa: E402

            with self.assertRaises(local_lib.LocalRebuildError) as context:
                local_lib.rebuild_local_state(
                    paths,
                    wrangler_bin=FIXTURE_WRANGLER,
                    env={"FAKE_WRANGLER_SKIP_PATTERN": "CREATE VIRTUAL TABLE expressions_fts"},
                    owner="test-owner",
                    created_at="2026-08-01T00:00:00Z",
                )

            self._assert_baseline_not_written(context.exception.temp_state_dir / "fake-d1.sqlite3")


if __name__ == "__main__":
    unittest.main()
