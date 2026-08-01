from __future__ import annotations

import json
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
            import sqlite3

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


if __name__ == "__main__":
    unittest.main()
