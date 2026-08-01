from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPTS_DB_DIR = REPO_ROOT / "scripts" / "db"
MANAGE_PY = SCRIPTS_DB_DIR / "manage.py"

if str(SCRIPTS_DB_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DB_DIR))


from lib import fingerprint as fingerprint_lib  # noqa: E402
from lib import locking as locking_lib  # noqa: E402
from lib import migrations as migrations_lib  # noqa: E402


class FingerprintTests(unittest.TestCase):
    def _write_inputs(self, temp_root: Path) -> fingerprint_lib.FingerprintInputs:
        schema_path = temp_root / "schema.sql"
        lock_path = temp_root / "migration-lock.json"
        language_manifest_path = temp_root / "language-manifest.json"
        ui_bundle_manifest_path = temp_root / "ui-manifest.json"

        schema_path.write_text("CREATE TABLE demo (id INTEGER);\n", encoding="utf-8")
        lock_path.write_text(json.dumps({"migrations": ["0002_demo.sql"]}), encoding="utf-8")
        language_manifest_path.write_text(
            json.dumps({"manifest_version": 1, "languages": ["nan-Hant"]}),
            encoding="utf-8",
        )
        ui_bundle_manifest_path.write_text(
            json.dumps({"bundle_version": 1, "locales": ["en-US"]}),
            encoding="utf-8",
        )

        return fingerprint_lib.FingerprintInputs(
            schema_path=schema_path,
            migration_lock_path=lock_path,
            language_manifest_path=language_manifest_path,
            ui_bundle_manifest_path=ui_bundle_manifest_path,
            dev_fixture_version="fixture-v1",
        )

    def test_fingerprint_changes_when_any_input_changes(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            inputs = self._write_inputs(temp_root)
            baseline = fingerprint_lib.compute_bootstrap_fingerprint(inputs)

            cases = (
                ("schema", inputs.schema_path, "CREATE TABLE demo (id INTEGER, note TEXT);\n"),
                ("lock", inputs.migration_lock_path, json.dumps({"migrations": ["0002_demo.sql", "0003_more.sql"]})),
                ("language manifest", inputs.language_manifest_path, json.dumps({"manifest_version": 2})),
                ("ui manifest", inputs.ui_bundle_manifest_path, json.dumps({"bundle_version": 2})),
            )
            for label, path, new_content in cases:
                with self.subTest(label=label):
                    original = path.read_text(encoding="utf-8")
                    path.write_text(new_content, encoding="utf-8")
                    try:
                        changed = fingerprint_lib.compute_bootstrap_fingerprint(inputs)
                    finally:
                        path.write_text(original, encoding="utf-8")
                    self.assertNotEqual(changed, baseline)

            changed_version = fingerprint_lib.compute_bootstrap_fingerprint(
                fingerprint_lib.FingerprintInputs(
                    schema_path=inputs.schema_path,
                    migration_lock_path=inputs.migration_lock_path,
                    language_manifest_path=inputs.language_manifest_path,
                    ui_bundle_manifest_path=inputs.ui_bundle_manifest_path,
                    dev_fixture_version="fixture-v2",
                )
            )
            self.assertNotEqual(changed_version, baseline)

    def test_fingerprint_is_deterministic_for_same_inputs(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            inputs = self._write_inputs(Path(temp_dir))

            first = fingerprint_lib.compute_bootstrap_fingerprint(inputs)
            second = fingerprint_lib.compute_bootstrap_fingerprint(inputs)

        self.assertEqual(first, second)


class OperationLockTests(unittest.TestCase):
    def test_second_process_is_rejected_with_owner_and_time(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            lock_path = Path(temp_dir) / "local.lock.json"
            locking_lib.acquire_operation_lock(
                lock_path,
                operation="local-status",
                owner="first-process",
                pid=111,
                created_at="2026-08-01T10:00:00Z",
            )

            with self.assertRaises(locking_lib.OperationLockError) as context:
                locking_lib.acquire_operation_lock(
                    lock_path,
                    operation="local-status",
                    owner="second-process",
                    pid=222,
                    created_at="2026-08-01T10:01:00Z",
                )

        message = str(context.exception)
        self.assertIn("first-process", message)
        self.assertIn("2026-08-01T10:00:00Z", message)

    def test_unlock_stale_lock_requires_missing_pid(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            lock_path = Path(temp_dir) / "local.lock.json"
            locking_lib.acquire_operation_lock(
                lock_path,
                operation="local-status",
                owner="first-process",
                pid=111,
                created_at="2026-08-01T10:00:00Z",
            )

            with self.assertRaisesRegex(locking_lib.OperationLockError, "still running"):
                locking_lib.unlock_stale_operation_lock(
                    lock_path,
                    pid_exists=lambda pid: True,
                )

            unlocked = locking_lib.unlock_stale_operation_lock(
                lock_path,
                pid_exists=lambda pid: False,
            )

        self.assertEqual(unlocked["owner"], "first-process")
        self.assertFalse(lock_path.exists())


class LocalStatusTests(unittest.TestCase):
    def _make_repo_root(self, temp_root: Path) -> None:
        (temp_root / "backend" / "migrations").mkdir(parents=True)
        (temp_root / "backend" / ".wrangler").mkdir(parents=True)
        (temp_root / "scripts" / "db" / "state").mkdir(parents=True)
        (temp_root / "scripts" / "v2" / "fixtures").mkdir(parents=True)
        (temp_root / "scripts" / "i18n" / "artifacts" / "system-ui").mkdir(parents=True)

        shutil.copy(REPO_ROOT / "backend" / "migrations" / "0002_add_name_en.sql", temp_root / "backend" / "migrations" / "0002_add_name_en.sql")
        shutil.copy(REPO_ROOT / "backend" / "migrations" / "0003_add_lang_family_status.sql", temp_root / "backend" / "migrations" / "0003_add_lang_family_status.sql")

        (temp_root / "backend" / "schema.sql").write_text("CREATE TABLE demo (id INTEGER);\n", encoding="utf-8")
        (temp_root / "scripts" / "v2" / "fixtures" / "language-migration.json").write_text(
            json.dumps({"manifest_version": 1, "mappings": {"en_US": {"canonical": "en-US"}}}),
            encoding="utf-8",
        )
        (temp_root / "scripts" / "i18n" / "artifacts" / "system-ui" / "manifest.json").write_text(
            json.dumps({"bundle_version": 1, "locales": ["en-US"]}),
            encoding="utf-8",
        )

        lock_data = migrations_lib.sync_migration_lock(
            temp_root / "backend" / "migrations",
            temp_root / "scripts" / "db" / "migration-lock.json",
            update=True,
            baseline_created_at="2026-08-01T00:00:00Z",
            git_commit="abc1234",
        )
        self.assertTrue(lock_data["migrations"])

    def test_local_status_reports_rebuild_required_without_mutating_state(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            self._make_repo_root(temp_root)

            result = subprocess.run(
                [sys.executable, str(MANAGE_PY), "--repo-root", str(temp_root), "local", "status"],
                cwd=REPO_ROOT,
                capture_output=True,
                text=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, msg=result.stderr)
            payload = json.loads(result.stdout)
            self.assertIn("desired_fingerprint", payload)
            self.assertIsNone(payload["stored_fingerprint"])
            self.assertFalse(payload["state_exists"])
            self.assertTrue(payload["rebuild_required"])
            self.assertFalse((temp_root / "scripts" / "db" / "state" / "local").exists())


if __name__ == "__main__":
    unittest.main()
