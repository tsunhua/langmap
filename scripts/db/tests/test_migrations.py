from __future__ import annotations

import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPTS_DB_DIR = REPO_ROOT / "scripts" / "db"
FIXTURES_DIR = REPO_ROOT / "scripts" / "db" / "tests" / "fixtures" / "migrations"

if str(SCRIPTS_DB_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DB_DIR))


from lib import migrations as migrations_lib  # noqa: E402


class MigrationDiscoveryTests(unittest.TestCase):
    def test_discover_migrations_returns_sorted_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            shutil.copy(FIXTURES_DIR / "0003_seed.sql", temp_root / "0003_seed.sql")
            shutil.copy(FIXTURES_DIR / "0002_schema.sql", temp_root / "0002_schema.sql")

            migrations = migrations_lib.discover_migrations(temp_root)

        self.assertEqual(
            [migration.filename for migration in migrations],
            ["0002_schema.sql", "0003_seed.sql"],
        )
        self.assertTrue(all(migration.sha256 for migration in migrations))
        self.assertEqual(migrations[0].size, (FIXTURES_DIR / "0002_schema.sql").stat().st_size)

    def test_discover_migrations_ignores_review_metadata_sidecars(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            (temp_root / "0002_schema.sql").write_text("SELECT 1;\n", encoding="utf-8")
            (temp_root / "0002_schema.meta.json").write_text(
                json.dumps({"preflight": ["check"], "postflight": ["verify"], "reversible": True}),
                encoding="utf-8",
            )

            try:
                migrations = migrations_lib.discover_migrations(temp_root)
            except ValueError as exc:
                self.fail(f"metadata sidecar must not be treated as a migration: {exc}")

        self.assertEqual([migration.filename for migration in migrations], ["0002_schema.sql"])

    def test_discover_rejects_invalid_filename(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            (temp_root / "bad-name.sql").write_text("SELECT 1;\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "invalid migration filename"):
                migrations_lib.discover_migrations(temp_root)

    def test_discover_rejects_hidden_entry(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            (temp_root / "0002_schema.sql").write_text("SELECT 1;\n", encoding="utf-8")
            (temp_root / ".DS_Store").write_text("finder noise", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "invalid migration filename"):
                migrations_lib.discover_migrations(temp_root)

    def test_discover_rejects_duplicate_sequence(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            (temp_root / "0002_schema.sql").write_text("SELECT 1;\n", encoding="utf-8")
            (temp_root / "0002_duplicate.sql").write_text("SELECT 2;\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "duplicate migration sequence"):
                migrations_lib.discover_migrations(temp_root)

    def test_discover_rejects_gap_after_first_sequence(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            (temp_root / "0002_schema.sql").write_text("SELECT 1;\n", encoding="utf-8")
            (temp_root / "0004_seed.sql").write_text("SELECT 2;\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "missing migration sequence"):
                migrations_lib.discover_migrations(temp_root)

    def test_discover_rejects_empty_file(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            (temp_root / "0002_schema.sql").write_text("", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "empty migration file"):
                migrations_lib.discover_migrations(temp_root)

    def test_discover_rejects_symlink(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            target = temp_root / "target.sql"
            target.write_text("SELECT 1;\n", encoding="utf-8")
            (temp_root / "0002_schema.sql").symlink_to(target)

            with self.assertRaisesRegex(ValueError, "symlink"):
                migrations_lib.discover_migrations(temp_root)


class MigrationLockTests(unittest.TestCase):
    def _make_migrations_dir(self) -> tempfile.TemporaryDirectory[str]:
        temp_dir = tempfile.TemporaryDirectory()
        temp_root = Path(temp_dir.name)
        shutil.copy(FIXTURES_DIR / "0002_schema.sql", temp_root / "0002_schema.sql")
        shutil.copy(FIXTURES_DIR / "0003_seed.sql", temp_root / "0003_seed.sql")
        return temp_dir

    def test_repository_migrations_match_committed_lock(self) -> None:
        lock_data = migrations_lib.sync_migration_lock(
            REPO_ROOT / "backend" / "migrations",
            REPO_ROOT / "scripts" / "db" / "migration-lock.json",
            update=False,
            baseline_created_at="unused-for-existing-lock",
            git_commit="unused-for-existing-lock",
        )

        self.assertEqual(
            [entry["filename"] for entry in lock_data["migrations"]],
            [path.name for path in sorted((REPO_ROOT / "backend" / "migrations").glob("*.sql"))],
        )

    def test_sync_lock_requires_existing_file_unless_update_mode(self) -> None:
        with self._make_migrations_dir() as temp_dir:
            temp_root = Path(temp_dir)
            lock_path = temp_root.parent / f"{temp_root.name}-migration-lock.json"

            with self.assertRaisesRegex(FileNotFoundError, "migration lock file is missing"):
                migrations_lib.sync_migration_lock(
                    temp_root,
                    lock_path,
                    update=False,
                    baseline_created_at="2026-08-01T00:00:00Z",
                    git_commit="abc1234",
                )

            lock_data = migrations_lib.sync_migration_lock(
                temp_root,
                lock_path,
                update=True,
                baseline_created_at="2026-08-01T00:00:00Z",
                git_commit="abc1234",
            )

            self.assertEqual(lock_data["baseline_created_at"], "2026-08-01T00:00:00Z")
            self.assertEqual(lock_data["baseline_git_commit"], "abc1234")
            self.assertEqual(
                [entry["filename"] for entry in lock_data["migrations"]],
                ["0002_schema.sql", "0003_seed.sql"],
            )
            self.assertTrue(lock_path.exists())

    def test_sync_lock_rejects_published_checksum_changes(self) -> None:
        with self._make_migrations_dir() as temp_dir:
            temp_root = Path(temp_dir)
            lock_path = temp_root.parent / f"{temp_root.name}-migration-lock.json"
            migrations_lib.sync_migration_lock(
                temp_root,
                lock_path,
                update=True,
                baseline_created_at="2026-08-01T00:00:00Z",
                git_commit="abc1234",
            )
            (temp_root / "0003_seed.sql").write_text("INSERT INTO demo VALUES (2);\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "checksum changed"):
                migrations_lib.sync_migration_lock(
                    temp_root,
                    lock_path,
                    update=False,
                    baseline_created_at="2026-08-01T00:00:00Z",
                    git_commit="abc1234",
                )

    def test_sync_lock_rejects_missing_locked_migration(self) -> None:
        with self._make_migrations_dir() as temp_dir:
            temp_root = Path(temp_dir)
            lock_path = temp_root.parent / f"{temp_root.name}-migration-lock.json"
            migrations_lib.sync_migration_lock(
                temp_root,
                lock_path,
                update=True,
                baseline_created_at="2026-08-01T00:00:00Z",
                git_commit="abc1234",
            )
            (temp_root / "0003_seed.sql").unlink()

            with self.assertRaisesRegex(ValueError, "missing migration file"):
                migrations_lib.sync_migration_lock(
                    temp_root,
                    lock_path,
                    update=False,
                    baseline_created_at="2026-08-01T00:00:00Z",
                    git_commit="abc1234",
                )

    def test_sync_lock_adds_new_migration_only_in_update_mode(self) -> None:
        with self._make_migrations_dir() as temp_dir:
            temp_root = Path(temp_dir)
            lock_path = temp_root.parent / f"{temp_root.name}-migration-lock.json"
            original = migrations_lib.sync_migration_lock(
                temp_root,
                lock_path,
                update=True,
                baseline_created_at="2026-08-01T00:00:00Z",
                git_commit="abc1234",
            )
            (temp_root / "0004_more.sql").write_text("ALTER TABLE demo ADD COLUMN note TEXT;\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "unlocked migration"):
                migrations_lib.sync_migration_lock(
                    temp_root,
                    lock_path,
                    update=False,
                    baseline_created_at="2026-08-02T00:00:00Z",
                    git_commit="def5678",
                )

            updated = migrations_lib.sync_migration_lock(
                temp_root,
                lock_path,
                update=True,
                baseline_created_at="2026-08-02T00:00:00Z",
                git_commit="def5678",
            )

            self.assertEqual(updated["baseline_created_at"], original["baseline_created_at"])
            self.assertEqual(updated["baseline_git_commit"], original["baseline_git_commit"])
            self.assertEqual(
                [entry["filename"] for entry in updated["migrations"]],
                ["0002_schema.sql", "0003_seed.sql", "0004_more.sql"],
            )
            written = json.loads(lock_path.read_text(encoding="utf-8"))
            self.assertEqual(written, updated)

    def test_sync_lock_rejects_tampered_sequence(self) -> None:
        with self._make_migrations_dir() as temp_dir:
            temp_root = Path(temp_dir)
            lock_path = temp_root.parent / f"{temp_root.name}-migration-lock.json"
            migrations_lib.sync_migration_lock(
                temp_root,
                lock_path,
                update=True,
                baseline_created_at="2026-08-01T00:00:00Z",
                git_commit="abc1234",
            )
            payload = json.loads(lock_path.read_text(encoding="utf-8"))
            payload["migrations"][0]["sequence"] = 9999
            lock_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

            with self.assertRaisesRegex(ValueError, "published migration sequence changed"):
                migrations_lib.sync_migration_lock(
                    temp_root,
                    lock_path,
                    update=False,
                    baseline_created_at="2026-08-01T00:00:00Z",
                    git_commit="abc1234",
                )


if __name__ == "__main__":
    unittest.main()
