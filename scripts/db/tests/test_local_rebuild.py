from __future__ import annotations

import hashlib
import json
import os
import shutil
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPTS_DB_DIR = REPO_ROOT / "scripts" / "db"
FIXTURE_WRANGLER = REPO_ROOT / "scripts" / "db" / "tests" / "fixtures" / "wrangler-local"

if str(SCRIPTS_DB_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DB_DIR))


from lib.paths import ProjectPaths  # noqa: E402


def sha256_path(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_fixture_repo(root: Path, *, broken_schema: bool = False) -> ProjectPaths:
    backend_dir = root / "backend"
    migrations_dir = backend_dir / "migrations"
    artifacts_dir = root / "scripts" / "language-reference" / "artifacts"
    ui_dir = root / "scripts" / "i18n" / "artifacts" / "system-ui"
    state_dir = root / "scripts" / "db" / "state"
    local_state_dir = state_dir / "local"
    operations_dir = state_dir / "operations"
    local_d1_state_dir = backend_dir / ".wrangler" / "state"

    migrations_dir.mkdir(parents=True, exist_ok=True)
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    ui_dir.mkdir(parents=True, exist_ok=True)
    local_state_dir.mkdir(parents=True, exist_ok=True)
    operations_dir.mkdir(parents=True, exist_ok=True)
    local_d1_state_dir.parent.mkdir(parents=True, exist_ok=True)

    schema_sql = """
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'user',
  email_verified INTEGER NOT NULL DEFAULT 0,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE languages (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL
);

CREATE TABLE scripts (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('ltr', 'rtl'))
);

CREATE TABLE regions (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  CHECK ((latitude IS NULL) = (longitude IS NULL))
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_languages_code ON languages(code);
CREATE INDEX idx_scripts_code ON scripts(code);
CREATE INDEX idx_regions_code ON regions(code);
"""
    if broken_schema:
        schema_sql = schema_sql.replace(
            """
CREATE TABLE regions (
  code TEXT PRIMARY KEY,
  name_en TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  CHECK ((latitude IS NULL) = (longitude IS NULL))
);
""".strip(),
            "",
        )
    (backend_dir / "schema.sql").write_text(schema_sql.strip() + "\n", encoding="utf-8")

    migration_0001 = migrations_dir / "0001_initial_schema.sql"
    migration_0001.write_text(schema_sql.strip() + "\n", encoding="utf-8")

    lock_payload = {
        "baseline_created_at": "2026-08-01T00:00:00Z",
        "baseline_git_commit": "fixture123",
        "migrations": [
            {
                "sequence": 1,
                "filename": migration_0001.name,
                "size": migration_0001.stat().st_size,
                "sha256": sha256_path(migration_0001),
            }
        ],
    }
    migration_lock_path = root / "scripts" / "db" / "migration-lock.json"
    migration_lock_path.parent.mkdir(parents=True, exist_ok=True)
    migration_lock_path.write_text(json.dumps(lock_payload, indent=2) + "\n", encoding="utf-8")

    language_manifest = {
        "manifest_version": 1,
        "generation": {"language_tag_count": 3, "language_location_count": 0},
        "counts": {"languages": 3, "scripts": 2, "regions": 2},
    }
    (artifacts_dir / "manifest.json").write_text(
        json.dumps(language_manifest, indent=2) + "\n", encoding="utf-8"
    )
    (artifacts_dir / "language-reference.sql").write_text(
        """
INSERT INTO languages (code, name_en) VALUES
  ('eng', 'English'),
  ('spa', 'Spanish'),
  ('cmn', 'Mandarin Chinese');

INSERT INTO scripts (code, name_en, direction) VALUES
  ('Latn', 'Latin', 'ltr'),
  ('Hant', 'Han (Traditional)', 'ltr');

INSERT INTO regions (code, name_en, latitude, longitude) VALUES
  ('US', 'United States', 39.8, -98.6),
  ('TW', 'Taiwan', 23.7, 121.0);
""".strip()
        + "\n",
        encoding="utf-8",
    )

    # ui bundle manifest path must still exist (fingerprint input); its SQL is not loaded.
    ui_manifest = {
        "project_id": "langmap-web",
        "locale_codes": [],
        "counts": {"locale_count": 0, "message_count": 0, "translation_count": 0},
    }
    (ui_dir / "manifest.json").write_text(json.dumps(ui_manifest, indent=2) + "\n", encoding="utf-8")
    (ui_dir / "system-ui.sql").write_text("-- ui seed fixture\n", encoding="utf-8")
    (root / "scripts" / "db").mkdir(parents=True, exist_ok=True)
    (root / "scripts" / "db" / "local-dev-user.sql").write_text(
        "INSERT OR IGNORE INTO users (username, email, password_hash, role, email_verified)\n"
        "VALUES ('dev', 'dev@example.com', 'dev-hash', 'user', 1);\n",
        encoding="utf-8",
    )

    return ProjectPaths(
        repo_root=root,
        backend_dir=backend_dir,
        migrations_dir=migrations_dir,
        migration_lock_path=migration_lock_path,
        state_dir=state_dir,
        local_state_dir=local_state_dir,
        local_fingerprint_path=local_state_dir / "bootstrap-fingerprint.json",
        artifacts_dir=state_dir / "artifacts",
        operations_dir=operations_dir,
        local_d1_state_dir=local_d1_state_dir,
        language_manifest_path=artifacts_dir / "manifest.json",
        ui_bundle_manifest_path=ui_dir / "manifest.json",
    )


def read_fake_log(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


class LocalRebuildTests(unittest.TestCase):
    def test_rebuild_creates_missing_local_metadata_directory(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)
            log_path = root / "fake-wrangler.log"
            shutil.rmtree(paths.local_state_dir)

            from lib import local as local_lib  # noqa: E402

            result = local_lib.rebuild_local_state(
                paths,
                wrangler_bin=FIXTURE_WRANGLER,
                env={"FAKE_WRANGLER_LOG_PATH": str(log_path)},
                owner="test-owner",
                created_at="2026-08-01T00:00:00Z",
            )

            self.assertEqual(result["status"], "rebuilt")
            self.assertTrue(paths.local_state_dir.exists())
            self.assertTrue(paths.local_fingerprint_path.exists())
            self.assertTrue(paths.local_verification_report_path.exists())

    def test_rebuild_swaps_active_state_only_after_success(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)
            log_path = root / "fake-wrangler.log"
            paths.local_d1_state_dir.mkdir(parents=True, exist_ok=True)
            (paths.local_d1_state_dir / "stale.txt").write_text("old", encoding="utf-8")

            from lib import local as local_lib  # noqa: E402

            result = local_lib.rebuild_local_state(
                paths,
                wrangler_bin=FIXTURE_WRANGLER,
                env={"FAKE_WRANGLER_LOG_PATH": str(log_path)},
                owner="test-owner",
                created_at="2026-08-01T00:00:00Z",
            )

            self.assertEqual(result["status"], "rebuilt")
            self.assertFalse((paths.local_d1_state_dir / "stale.txt").exists())
            self.assertTrue(paths.local_fingerprint_path.exists())
            self.assertTrue((paths.local_state_dir / "verification-report.json").exists())

            calls = read_fake_log(log_path)
            # Greenfield loads schema + registry + UI + local-dev user, then baseline.
            self.assertEqual([Path(call["subject"]).name for call in calls[:4]], [
                "schema.sql",
                "language-reference.sql",
                "system-ui.sql",
                "local-dev-user.sql",
            ])
            self.assertEqual(calls[4]["mode"], "command")

            database_path = paths.local_d1_state_dir / "fake-d1.sqlite3"
            self.assertTrue(database_path.exists())
            connection = sqlite3.connect(database_path)
            try:
                applied = connection.execute("SELECT name FROM d1_migrations ORDER BY id").fetchall()
            finally:
                connection.close()
            self.assertEqual([row[0] for row in applied], ["0001_initial_schema.sql"])
            backups = list(paths.local_d1_state_dir.parent.glob("state-backup-*"))
            self.assertEqual(backups, [])

    def test_rebuild_failure_preserves_active_state_and_exposes_temp_dir(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)
            log_path = root / "fake-wrangler.log"
            paths.local_d1_state_dir.mkdir(parents=True, exist_ok=True)
            sentinel = paths.local_d1_state_dir / "keep.txt"
            sentinel.write_text("active", encoding="utf-8")

            from lib import local as local_lib  # noqa: E402

            with self.assertRaises(local_lib.LocalRebuildError) as context:
                local_lib.rebuild_local_state(
                    paths,
                    wrangler_bin=FIXTURE_WRANGLER,
                    env={
                        "FAKE_WRANGLER_LOG_PATH": str(log_path),
                        "FAKE_WRANGLER_FAIL_ON": "language-reference.sql",
                    },
                    owner="test-owner",
                    created_at="2026-08-01T00:00:00Z",
                )

            self.assertTrue(sentinel.exists())
            self.assertTrue(context.exception.temp_state_dir.exists())
            self.assertIn("language-reference.sql", str(context.exception))
            backups = list(paths.local_d1_state_dir.parent.glob("state-backup-*"))
            self.assertEqual(backups, [])

    def test_rebuild_refuses_to_write_baseline_when_schema_invariants_fail(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root, broken_schema=True)
            log_path = root / "fake-wrangler.log"

            from lib import local as local_lib  # noqa: E402

            with self.assertRaises(local_lib.LocalRebuildError) as context:
                local_lib.rebuild_local_state(
                    paths,
                    wrangler_bin=FIXTURE_WRANGLER,
                    env={"FAKE_WRANGLER_LOG_PATH": str(log_path)},
                    owner="test-owner",
                    created_at="2026-08-01T00:00:00Z",
                )

            database_path = context.exception.temp_state_dir / "fake-d1.sqlite3"
            self.assertTrue(database_path.exists())
            connection = sqlite3.connect(database_path)
            try:
                table = connection.execute(
                    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'd1_migrations'"
                ).fetchone()
            finally:
                connection.close()
            self.assertIsNone(table)

    def test_rebuild_restores_active_state_and_metadata_when_post_swap_write_fails(self) -> None:
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            paths = build_fixture_repo(root)
            paths.local_d1_state_dir.mkdir(parents=True, exist_ok=True)
            active_marker = paths.local_d1_state_dir / "keep.txt"
            active_marker.write_text("old-active", encoding="utf-8")
            paths.local_fingerprint_path.parent.mkdir(parents=True, exist_ok=True)
            paths.local_fingerprint_path.write_text('{"fingerprint":"old"}\n', encoding="utf-8")
            paths.local_verification_report_path.write_text('{"status":"old"}\n', encoding="utf-8")

            from lib import local as local_lib  # noqa: E402

            original_replace_path = local_lib._replace_path
            call_count = {"count": 0}

            def flaky_replace_path(source: Path, destination: Path) -> None:
                call_count["count"] += 1
                if call_count["count"] == 2:
                    raise OSError("forced metadata write failure")
                original_replace_path(source, destination)

            with mock.patch.object(local_lib, "_replace_path", side_effect=flaky_replace_path):
                with self.assertRaises(local_lib.LocalRebuildError) as context:
                    local_lib.rebuild_local_state(
                        paths,
                        wrangler_bin=FIXTURE_WRANGLER,
                        env={},
                        owner="test-owner",
                        created_at="2026-08-01T00:00:00Z",
                    )

            self.assertIn("forced metadata write failure", str(context.exception))
            self.assertEqual(active_marker.read_text(encoding="utf-8"), "old-active")
            self.assertEqual(
                paths.local_fingerprint_path.read_text(encoding="utf-8"),
                '{"fingerprint":"old"}\n',
            )
            self.assertEqual(
                paths.local_verification_report_path.read_text(encoding="utf-8"),
                '{"status":"old"}\n',
            )
            backups = list(paths.local_d1_state_dir.parent.glob("state-backup-*"))
            self.assertEqual(backups, [])


if __name__ == "__main__":
    unittest.main()
