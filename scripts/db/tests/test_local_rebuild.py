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
    artifacts_dir = root / "scripts" / "v2" / "artifacts" / "language-registry-5.3"
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
CREATE TABLE languoids (
  id TEXT PRIMARY KEY,
  glottocode TEXT UNIQUE NOT NULL,
  preferred_name TEXT NOT NULL
);
CREATE INDEX idx_languoids_glottocode ON languoids(glottocode);

CREATE TABLE language_subtags (
  type TEXT NOT NULL,
  value TEXT NOT NULL,
  PRIMARY KEY (type, value)
);

CREATE TABLE language_varieties (
  id TEXT PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  origin TEXT NOT NULL,
  glottocode TEXT
);
CREATE INDEX idx_language_varieties_glottocode ON language_varieties(glottocode);

CREATE TABLE language_profiles (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  direction TEXT NOT NULL DEFAULT 'ltr'
);

CREATE TABLE language_locations (
  language_variety_id TEXT NOT NULL,
  city_name TEXT NOT NULL,
  territory_code TEXT NOT NULL,
  script_code TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (language_variety_id, city_name, territory_code, script_code)
);
CREATE INDEX idx_language_locations_variety ON language_locations(language_variety_id);

CREATE TABLE expressions (
  id INTEGER PRIMARY KEY,
  text TEXT NOT NULL,
  language_profile_code TEXT NOT NULL,
  source_type TEXT,
  source_ref TEXT,
  review_status TEXT
);

CREATE TABLE expression_edges (
  id TEXT PRIMARY KEY,
  expression_a_id INTEGER NOT NULL,
  expression_b_id INTEGER NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL DEFAULT 'batch',
  UNIQUE(expression_a_id, expression_b_id)
);
CREATE INDEX idx_expression_edges_a_id ON expression_edges(expression_a_id);

CREATE TABLE ui_locales (
  project_id TEXT NOT NULL,
  code TEXT NOT NULL,
  native_name TEXT NOT NULL,
  direction TEXT NOT NULL DEFAULT 'ltr',
  fallback_code TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  mapping_revision INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (project_id, code)
);

CREATE TABLE ui_messages (
  project_id TEXT NOT NULL,
  key TEXT NOT NULL,
  source_expression_id INTEGER NOT NULL,
  placeholders_json TEXT,
  source_hash TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  PRIMARY KEY (project_id, key)
);

CREATE VIRTUAL TABLE expressions_fts USING fts5(
  text,
  content='expressions',
  content_rowid='id'
);

CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN
  INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;
"""
    if broken_schema:
        schema_sql = schema_sql.replace(
            """
CREATE TABLE ui_messages (
  project_id TEXT NOT NULL,
  key TEXT NOT NULL,
  source_expression_id INTEGER NOT NULL,
  placeholders_json TEXT,
  source_hash TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  PRIMARY KEY (project_id, key)
);
""".strip(),
            "",
        )
    (backend_dir / "schema.sql").write_text(schema_sql.strip() + "\n", encoding="utf-8")

    migration_0002 = migrations_dir / "0002_init.sql"
    migration_0002.write_text("ALTER TABLE language_varieties ADD COLUMN name_en TEXT;\n", encoding="utf-8")
    migration_0003 = migrations_dir / "0003_seed.sql"
    migration_0003.write_text("UPDATE language_varieties SET origin = origin;\n", encoding="utf-8")

    lock_payload = {
        "baseline_created_at": "2026-08-01T00:00:00Z",
        "baseline_git_commit": "fixture123",
        "migrations": [
            {
                "sequence": 2,
                "filename": migration_0002.name,
                "size": migration_0002.stat().st_size,
                "sha256": sha256_path(migration_0002),
            },
            {
                "sequence": 3,
                "filename": migration_0003.name,
                "size": migration_0003.stat().st_size,
                "sha256": sha256_path(migration_0003),
            },
        ],
    }
    migration_lock_path = root / "scripts" / "db" / "migration-lock.json"
    migration_lock_path.parent.mkdir(parents=True, exist_ok=True)
    migration_lock_path.write_text(json.dumps(lock_payload, indent=2) + "\n", encoding="utf-8")

    language_manifest = {
        "glottolog": {"version": "fixture", "languoid_count": 3},
        "iana": {"file_date": "2026-08-01", "subtag_count": 3},
        "generation": {"variety_count": 4, "language_location_count": 2},
    }
    (artifacts_dir / "manifest.json").write_text(
        json.dumps(language_manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    (artifacts_dir / "language-registry.sql").write_text(
        """
INSERT INTO languoids (id, glottocode, preferred_name) VALUES
  ('glotto:eng', 'eng1234', 'English'),
  ('glotto:spa', 'spa1234', 'Spanish'),
  ('glotto:zho', 'zho1234', 'Chinese');

INSERT INTO language_subtags (type, value) VALUES
  ('language', 'en'),
  ('language', 'es'),
  ('language', 'zh');

INSERT INTO language_varieties (id, code, name, origin, glottocode) VALUES
  ('var:en-US', 'en-US', 'English (United States)', 'seed', 'eng1234'),
  ('var:es-ES', 'es-ES', 'Español', 'seed', 'spa1234'),
  ('var:zh-Hant-TW', 'zh-Hant-TW', '繁體中文', 'seed', 'zho1234'),
  ('var:x-emoji', 'x-emoji', 'Emoji', 'system', '');

INSERT INTO language_profiles (code, name, direction) VALUES
  ('en-US', 'English (United States)', 'ltr'),
  ('es-ES', 'Español', 'ltr'),
  ('zh-Hant-TW', '繁體中文', 'ltr');

INSERT INTO language_locations (language_variety_id, city_name, territory_code, script_code) VALUES
  ('var:spa', 'Madrid', 'ES', ''),
  ('var:zho', 'Taipei', 'TW', 'Hant');
""".strip()
        + "\n",
        encoding="utf-8",
    )

    ui_manifest = {
        "project_id": "langmap-web",
        "locale_codes": ["es-ES", "zh-Hant-TW"],
        "counts": {"locale_count": 2, "message_count": 2, "translation_count": 4},
    }
    (ui_dir / "manifest.json").write_text(json.dumps(ui_manifest, indent=2) + "\n", encoding="utf-8")
    (ui_dir / "system-ui.sql").write_text(
        """
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
VALUES ('langmap-web', 'es-ES', 'Español', 'ltr', 'active');
INSERT INTO ui_locales (project_id, code, native_name, direction, status)
VALUES ('langmap-web', 'zh-Hant-TW', '繁體中文', 'ltr', 'active');

INSERT INTO expressions (id, text, language_profile_code, source_type, source_ref, review_status) VALUES
  (1001, 'Hello', 'en-US', 'ui_i18n', 'langmap-web:greeting.hello', 'approved'),
  (1002, 'Bye', 'en-US', 'ui_i18n', 'langmap-web:greeting.bye', 'approved'),
  (2001, 'Hola', 'es-ES', 'ui_i18n', 'langmap-web:greeting.hello', 'pending'),
  (2002, 'Adiós', 'es-ES', 'ui_i18n', 'langmap-web:greeting.bye', 'pending'),
  (3001, '你好', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:greeting.hello', 'pending'),
  (3002, '再見', 'zh-Hant-TW', 'ui_i18n', 'langmap-web:greeting.bye', 'pending');

INSERT INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status) VALUES
  ('langmap-web', 'greeting.hello', 1001, '[]', '1001', 'active'),
  ('langmap-web', 'greeting.bye', 1002, '[]', '1002', 'active');

INSERT INTO expression_edges (id, expression_a_id, expression_b_id, score, source) VALUES
  ('1001-2001', 1001, 2001, 0, 'ui_i18n'),
  ('1002-2002', 1002, 2002, 0, 'ui_i18n'),
  ('1001-3001', 1001, 3001, 0, 'ui_i18n'),
  ('1002-3002', 1002, 3002, 0, 'ui_i18n');
""".strip()
        + "\n",
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
            self.assertEqual([Path(call["subject"]).name for call in calls[:3]], [
                "schema.sql",
                "language-registry.sql",
                "system-ui.sql",
            ])
            self.assertEqual(calls[3]["mode"], "command")

            database_path = paths.local_d1_state_dir / "fake-d1.sqlite3"
            self.assertTrue(database_path.exists())
            connection = sqlite3.connect(database_path)
            try:
                applied = connection.execute("SELECT name FROM d1_migrations ORDER BY id").fetchall()
            finally:
                connection.close()
            self.assertEqual([row[0] for row in applied], ["0002_init.sql", "0003_seed.sql"])
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
                        "FAKE_WRANGLER_FAIL_ON": "system-ui.sql",
                    },
                    owner="test-owner",
                    created_at="2026-08-01T00:00:00Z",
                )

            self.assertTrue(sentinel.exists())
            self.assertTrue(context.exception.temp_state_dir.exists())
            self.assertIn("system-ui.sql", str(context.exception))
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
