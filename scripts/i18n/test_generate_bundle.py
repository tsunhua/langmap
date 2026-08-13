from __future__ import annotations

import hashlib
import importlib.util
import json
import sqlite3
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
GENERATE_BUNDLE = REPO_ROOT / "scripts" / "i18n" / "generate-bundle.py"
GENERATE_SQL = REPO_ROOT / "scripts" / "i18n" / "generate-i18n-sql.py"


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise AssertionError(f"unable to load module from {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


class GenerateBundleTests(unittest.TestCase):
    maxDiff = None

    def _write_fixture_tree(self, root: Path, *, es_extra: dict[str, str] | None = None) -> tuple[Path, dict[str, Path]]:
        catalog_path = root / "web" / "src" / "locales" / "en.ts"
        catalog_path.parent.mkdir(parents=True, exist_ok=True)
        catalog_path.write_text(
            textwrap.dedent(
                """\
                export const en = {
                  auth: {
                    noAccount: "Don't have an account?",
                  },
                  common: {
                    search: 'Search',
                  },
                  search: {
                    hint: "L'été arrive",
                  },
                } as const

                export type MessageSchema = typeof en
                """
            ),
            encoding="utf-8",
        )

        locale_dir = root / "scripts" / "i18n"
        locale_dir.mkdir(parents=True, exist_ok=True)
        locales = {
            "cmn-Hans-CN": {
                "auth.noAccount": "还没有账号？",
                "common.search": "搜索",
                "search.hint": "L'été 即将到来",
            },
            "cmn-Hant-TW": {
                "auth.noAccount": "還沒有帳號？",
                "common.search": "搜尋",
                "search.hint": "L'été 即將到來",
            },
            "spa-Latn-ES": {
                "auth.noAccount": "¿No tienes una cuenta?",
                "common.search": "Buscar",
                "search.hint": "L'été llega",
            },
            "jpn-Jpan-JP": {
                "auth.noAccount": "アカウントをお持ちではありませんか？",
                "common.search": "検索",
                "search.hint": "L'été が来ます",
            },
        }
        if es_extra:
            locales["spa-Latn-ES"].update(es_extra)

        paths: dict[str, Path] = {}
        for code, payload in locales.items():
            path = locale_dir / f"{code}.json"
            path.write_text(
                json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
            paths[code] = path
        return catalog_path, paths

    def _run_cli(self, *, catalog_path: Path, locale_paths: dict[str, Path], output_dir: Path) -> subprocess.CompletedProcess[str]:
        args = [
            sys.executable,
            str(GENERATE_BUNDLE),
            "--source-catalog",
            str(catalog_path),
            "--output-dir",
            str(output_dir),
        ]
        for code in ("cmn-Hant-TW", "jpn-Jpan-JP", "spa-Latn-ES", "cmn-Hans-CN"):
            args.extend(["--locale", f"{code}={locale_paths[code]}"])
        return subprocess.run(
            args,
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

    def _run_cli_with_locale_args(self, *, catalog_path: Path, locale_args: list[str], output_dir: Path) -> subprocess.CompletedProcess[str]:
        args = [
            sys.executable,
            str(GENERATE_BUNDLE),
            "--source-catalog",
            str(catalog_path),
            "--output-dir",
            str(output_dir),
        ]
        for item in locale_args:
            args.extend(["--locale", item])
        return subprocess.run(
            args,
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

    def _create_sqlite_schema(self, db: sqlite3.Connection) -> None:
        # Mirror the real schema (backend/schema.sql) closely enough that the
        # generated SQL executes cleanly in-memory with FK/UNIQUE/CHECK enforced.
        db.executescript(
            """
            CREATE TABLE languages (code TEXT PRIMARY KEY, name_en TEXT NOT NULL);
            CREATE TABLE scripts (code TEXT PRIMARY KEY, name_en TEXT NOT NULL, direction TEXT NOT NULL);
            CREATE TABLE regions (code TEXT PRIMARY KEY, name_en TEXT NOT NULL, latitude REAL, longitude REAL);
            CREATE TABLE sources (id TEXT PRIMARY KEY, type TEXT NOT NULL, name TEXT NOT NULL);
            CREATE TABLE language_locales (
              code TEXT PRIMARY KEY,
              lang_code TEXT NOT NULL,
              script_code TEXT NOT NULL,
              region_code TEXT NOT NULL,
              place_path TEXT NOT NULL DEFAULT '',
              name TEXT NOT NULL,
              name_en TEXT NOT NULL,
              source_id TEXT,
              source_ref TEXT,
              UNIQUE(lang_code, script_code, region_code, place_path)
            );
            CREATE TABLE expressions (
              id TEXT PRIMARY KEY,
              lang_code TEXT NOT NULL,
              text TEXT NOT NULL,
              text_hash TEXT NOT NULL,
              homograph_index INTEGER NOT NULL DEFAULT 1,
              description TEXT NOT NULL DEFAULT '',
              tags_json TEXT NOT NULL DEFAULT '[]',
              source_id TEXT,
              source_ref TEXT,
              review_status TEXT NOT NULL DEFAULT 'pending',
              created_by INTEGER,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              CHECK(homograph_index >= 1),
              CHECK(source_ref IS NULL OR source_id IS NOT NULL),
              UNIQUE(lang_code, text, homograph_index),
              UNIQUE(lang_code, text_hash, homograph_index)
            );
            CREATE TABLE expression_locale_attestations (
              id TEXT PRIMARY KEY,
              expression_id TEXT NOT NULL,
              language_locale_code TEXT NOT NULL,
              source_id TEXT,
              source_ref TEXT,
              created_by INTEGER,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              UNIQUE(expression_id, language_locale_code, source_id, source_ref)
            );
            CREATE TABLE expression_edges (
              id TEXT PRIMARY KEY,
              expression_a_id TEXT NOT NULL,
              expression_b_id TEXT NOT NULL,
              score INTEGER NOT NULL DEFAULT 0,
              source TEXT NOT NULL,
              created_by INTEGER,
              created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
              CHECK(expression_a_id < expression_b_id),
              UNIQUE(expression_a_id, expression_b_id)
            );
            CREATE TABLE ui_locales (
              project_id TEXT NOT NULL,
              language_locale_code TEXT NOT NULL,
              status TEXT NOT NULL,
              mapping_revision INTEGER NOT NULL DEFAULT 0,
              activation_source TEXT,
              activated_at TEXT,
              PRIMARY KEY(project_id, language_locale_code)
            );
            CREATE TABLE ui_messages (
              project_id TEXT NOT NULL,
              message_key TEXT NOT NULL,
              source_expression_id TEXT NOT NULL,
              source_text TEXT NOT NULL,
              placeholders_json TEXT NOT NULL DEFAULT '[]',
              status TEXT NOT NULL,
              PRIMARY KEY(project_id, message_key)
            );
            """
        )
        db.executemany(
            "INSERT INTO languages (code, name_en) VALUES (?, ?)",
            [
                ("eng", "English"),
                ("cmn", "Mandarin Chinese"),
                ("spa", "Spanish"),
                ("jpn", "Japanese"),
            ],
        )
        db.executemany(
            "INSERT INTO scripts (code, name_en, direction) VALUES (?, ?, ?)",
            [
                ("Latn", "Latin", "ltr"),
                ("Hant", "Han (Traditional)", "ltr"),
                ("Hans", "Han (Simplified)", "ltr"),
                ("Jpan", "Japanese", "ltr"),
            ],
        )
        db.executemany(
            "INSERT INTO regions (code, name_en, latitude, longitude) VALUES (?, ?, ?, ?)",
            [
                ("US", "United States", 39.8, -98.6),
                ("TW", "Taiwan", 23.7, 121.0),
                ("CN", "China", None, None),
                ("ES", "Spain", None, None),
                ("JP", "Japan", 36.2, 138.3),
            ],
        )
        db.executemany(
            "INSERT INTO sources (id, type, name) VALUES (?, ?, ?)",
            [
                ("system-seed", "system", "seed"),
                ("system-ui", "system", "UI"),
            ],
        )
        db.executemany(
            "INSERT INTO language_locales (code, lang_code, script_code, region_code, place_path, name, name_en, source_id, source_ref) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [
                ("eng-Latn-US", "eng", "Latn", "US", "", "English (US)", "English (US)", "system-seed", "seed:system-seed:1"),
                ("cmn-Hant-TW", "cmn", "Hant", "TW", "", "Taiwan Mandarin", "Taiwan Mandarin", "system-seed", "seed:system-seed:1"),
                ("cmn-Hans-CN", "cmn", "Hans", "CN", "", "Simplified Chinese", "Simplified Chinese", "system-seed", "seed:system-seed:1"),
                ("spa-Latn-ES", "spa", "Latn", "ES", "", "Spanish (Spain)", "Spanish (Spain)", "system-seed", "seed:system-seed:1"),
                ("jpn-Jpan-JP", "jpn", "Jpan", "JP", "", "Japanese (Japan)", "Japanese (Japan)", "system-seed", "seed:system-seed:1"),
            ],
        )

    def test_cli_generates_manifest_sql_and_idempotent_bundle(self) -> None:
        self.assertTrue(GENERATE_BUNDLE.exists(), "generate-bundle.py should exist")
        self.assertTrue(GENERATE_SQL.exists(), "generate-i18n-sql.py should exist")

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            catalog_path, locale_paths = self._write_fixture_tree(temp_root)
            output_dir = temp_root / "artifacts" / "system-ui"

            result = self._run_cli(
                catalog_path=catalog_path,
                locale_paths=locale_paths,
                output_dir=output_dir,
            )

            self.assertEqual(result.returncode, 0, msg=result.stderr)

            manifest_path = output_dir / "manifest.json"
            sql_path = output_dir / "system-ui.sql"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            sql_text = sql_path.read_text(encoding="utf-8")

            self.assertEqual(manifest["schema_version"], 1)
            self.assertEqual(manifest["project_id"], "langmap-web")
            self.assertEqual(manifest["ownership_scope"], "managed-system-ui")
            self.assertEqual(
                manifest["locale_codes"],
                ["cmn-Hans-CN", "cmn-Hant-TW", "eng-Latn-US", "jpn-Jpan-JP", "spa-Latn-ES"],
            )
            self.assertEqual(
                manifest["counts"],
                {"locale_count": 5, "message_count": 3, "translation_count": 12},
            )
            self.assertEqual(
                manifest["inputs"]["source_catalog"]["sha256"],
                sha256_text(catalog_path.read_text(encoding="utf-8")),
            )
            for code, path in locale_paths.items():
                self.assertEqual(
                    manifest["inputs"]["locales"][code]["sha256"],
                    sha256_text(path.read_text(encoding="utf-8")),
                )
            self.assertEqual(
                manifest["artifacts"]["system_ui_sql"]["sha256"],
                sha256_text(sql_text),
            )

            self.assertIn("INSERT OR IGNORE INTO ui_locales", sql_text)
            self.assertIn("-- 1. Activate UI locales", sql_text)
            self.assertIn("INSERT OR IGNORE INTO ui_messages", sql_text)
            self.assertIn("INSERT OR IGNORE INTO expression_edges", sql_text)
            self.assertIn("INSERT OR IGNORE INTO expression_locale_attestations", sql_text)
            self.assertNotIn("UPDATE ui_locales SET mapping_revision", sql_text)
            self.assertNotIn("DELETE FROM", sql_text)
            self.assertIn("Don''t have an account?", sql_text)
            self.assertLess(sql_text.index("-- Locale jpn-Jpan-JP"), sql_text.index("-- Locale spa-Latn-ES"))
            self.assertLess(sql_text.index("-- auth.noAccount"), sql_text.index("-- common.search"))
            self.assertLess(sql_text.index("-- common.search"), sql_text.index("-- search.hint"))

            db = sqlite3.connect(":memory:")
            try:
                self._create_sqlite_schema(db)
                db.executescript(sql_text)
                first_counts = {
                    table: db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
                    for table in (
                        "ui_locales",
                        "ui_messages",
                        "expressions",
                        "expression_edges",
                        "expression_locale_attestations",
                    )
                }
                first_revisions = dict(
                    db.execute(
                        "SELECT language_locale_code, mapping_revision FROM ui_locales ORDER BY language_locale_code"
                    ).fetchall()
                )
                db.executescript(sql_text)
                second_counts = {
                    table: db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
                    for table in (
                        "ui_locales",
                        "ui_messages",
                        "expressions",
                        "expression_edges",
                        "expression_locale_attestations",
                    )
                }
                second_revisions = dict(
                    db.execute(
                        "SELECT language_locale_code, mapping_revision FROM ui_locales ORDER BY language_locale_code"
                    ).fetchall()
                )
                locale_statuses = dict(
                    db.execute(
                        "SELECT language_locale_code, status FROM ui_locales ORDER BY language_locale_code"
                    ).fetchall()
                )
            finally:
                db.close()

            self.assertEqual(second_counts, first_counts)

            # Re-import is idempotent: INSERT OR IGNORE leaves mapping_revision at 0
            # on every run (no revision bump on seed import).
            self.assertEqual(
                first_revisions,
                {
                    "cmn-Hans-CN": 0,
                    "cmn-Hant-TW": 0,
                    "eng-Latn-US": 0,
                    "spa-Latn-ES": 0,
                    "jpn-Jpan-JP": 0,
                },
            )
            self.assertEqual(second_revisions, first_revisions)
            self.assertEqual(locale_statuses, {code: "active" for code in first_revisions})

    def test_translation_edges_form_a_clique_per_key(self) -> None:
        self.assertTrue(GENERATE_BUNDLE.exists(), "generate-bundle.py should exist")

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            catalog_path, locale_paths = self._write_fixture_tree(temp_root)
            output_dir = temp_root / "artifacts" / "system-ui"

            result = self._run_cli(
                catalog_path=catalog_path,
                locale_paths=locale_paths,
                output_dir=output_dir,
            )
            self.assertEqual(result.returncode, 0, msg=result.stderr)
            sql_text = (output_dir / "system-ui.sql").read_text(encoding="utf-8")

            db = sqlite3.connect(":memory:")
            try:
                self._create_sqlite_schema(db)
                db.executescript(sql_text)
                edge_rows = db.execute(
                    "SELECT expression_a_id, expression_b_id FROM expression_edges"
                ).fetchall()
            finally:
                db.close()

            # Each key's node set: the English source plus every locale target.
            # Mapping edges form the full clique (all unordered pairs), matching
            # runtime createEdgesBatch — so translations connect to each other,
            # not only to the English source.
            module = load_module("generate_bundle_edges", GENERATE_BUNDLE)
            source_map = module.i18n_sql.parse_en_ts_text(catalog_path.read_text(encoding="utf-8"))
            locales = {
                code: module.i18n_sql.load_translations_text(path.read_text(encoding="utf-8"))
                for code, path in locale_paths.items()
            }
            expected_pairs: set[tuple[str, str]] = set()
            for key, source_text in source_map.items():
                nodes = {module.i18n_sql.expression_id(module.i18n_sql.SOURCE_LANG_CODE, source_text)}
                for locale_code, translations in locales.items():
                    lang_code = module.i18n_sql.locale_to_lang_code(locale_code)
                    nodes.add(module.i18n_sql.expression_id(lang_code, translations[key]))
                ordered = sorted(nodes)
                for i, a in enumerate(ordered):
                    for b in ordered[i + 1:]:
                        expected_pairs.add((a, b))

            edges = {tuple(sorted((a, b))) for a, b in edge_rows}
            self.assertEqual(edges, expected_pairs)
            self.assertEqual(len(edge_rows), len(expected_pairs))
            self.assertEqual(len(edge_rows), len(expected_pairs))

    def test_cli_fails_on_unknown_source_key_and_keeps_existing_artifacts(self) -> None:
        self.assertTrue(GENERATE_BUNDLE.exists(), "generate-bundle.py should exist")

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            catalog_path, locale_paths = self._write_fixture_tree(
                temp_root,
                es_extra={"missing.key": "desconocido"},
            )
            output_dir = temp_root / "artifacts" / "system-ui"
            output_dir.mkdir(parents=True, exist_ok=True)
            manifest_path = output_dir / "manifest.json"
            sql_path = output_dir / "system-ui.sql"
            manifest_path.write_text('{"sentinel":"manifest"}\n', encoding="utf-8")
            sql_path.write_text("-- sentinel sql\n", encoding="utf-8")

            result = self._run_cli(
                catalog_path=catalog_path,
                locale_paths=locale_paths,
                output_dir=output_dir,
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("missing.key", result.stderr)
            self.assertEqual(manifest_path.read_text(encoding="utf-8"), '{"sentinel":"manifest"}\n')
            self.assertEqual(sql_path.read_text(encoding="utf-8"), "-- sentinel sql\n")

    def test_detects_deterministic_id_collisions_for_different_text(self) -> None:
        self.assertTrue(GENERATE_BUNDLE.exists(), "generate-bundle.py should exist")

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            catalog_path, locale_paths = self._write_fixture_tree(temp_root)
            output_dir = temp_root / "artifacts" / "system-ui"
            module = load_module("generate_bundle", GENERATE_BUNDLE)

            def collision_expression_id(lang_code: str, text: str) -> str:
                # Force a string id collision: spa target expressions reuse a cmn id.
                if lang_code == "spa":
                    return "cmn:colliding"
                return module.i18n_sql.expression_id(lang_code, text)

            with self.assertRaisesRegex(ValueError, "expression_id collision"):
                module.generate_bundle(
                    source_catalog_path=catalog_path,
                    locale_paths=locale_paths,
                    output_dir=output_dir,
                    expression_id_fn=collision_expression_id,
                )

    def test_generate_bundle_uses_single_read_snapshot_for_manifest_and_sql(self) -> None:
        self.assertTrue(GENERATE_BUNDLE.exists(), "generate-bundle.py should exist")

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            catalog_path, locale_paths = self._write_fixture_tree(temp_root)
            output_dir = temp_root / "artifacts" / "system-ui"
            module = load_module("generate_bundle_snapshot", GENERATE_BUNDLE)

            call_counts: dict[Path, int] = {}
            original_bytes = {
                catalog_path.resolve(): catalog_path.read_bytes(),
                **{path.resolve(): path.read_bytes() for path in locale_paths.values()},
            }

            def read_bytes_once(path: Path) -> bytes:
                resolved = Path(path).resolve()
                call_counts[resolved] = call_counts.get(resolved, 0) + 1
                if call_counts[resolved] > 1:
                    raise AssertionError(f"unexpected reread of {resolved}")
                payload = original_bytes[resolved]
                if resolved == catalog_path.resolve():
                    catalog_path.write_text("export const en = {} as const\n", encoding="utf-8")
                return payload

            manifest = module.generate_bundle(
                source_catalog_path=catalog_path,
                locale_paths=locale_paths,
                output_dir=output_dir,
                read_bytes_fn=read_bytes_once,
            )

            self.assertEqual(
                set(call_counts.keys()),
                {catalog_path.resolve(), *(path.resolve() for path in locale_paths.values())},
            )
            self.assertTrue(all(count == 1 for count in call_counts.values()))
            self.assertEqual(
                manifest["inputs"]["source_catalog"]["sha256"],
                hashlib.sha256(original_bytes[catalog_path.resolve()]).hexdigest(),
            )

    def test_cli_rejects_missing_or_extra_locale_set(self) -> None:
        self.assertTrue(GENERATE_BUNDLE.exists(), "generate-bundle.py should exist")

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            catalog_path, locale_paths = self._write_fixture_tree(temp_root)
            output_dir = temp_root / "artifacts" / "system-ui"

            missing_result = self._run_cli_with_locale_args(
                catalog_path=catalog_path,
                output_dir=output_dir,
                locale_args=[
                    f"cmn-Hant-TW={locale_paths['cmn-Hant-TW']}",
                    f"jpn-Jpan-JP={locale_paths['jpn-Jpan-JP']}",
                    f"spa-Latn-ES={locale_paths['spa-Latn-ES']}",
                ],
            )
            self.assertNotEqual(missing_result.returncode, 0)
            self.assertIn("cmn-Hans-CN", missing_result.stderr)

            extra_path = temp_root / "scripts" / "i18n" / "fr-FR.json"
            extra_path.write_text(json.dumps({"common.search": "Chercher"}, ensure_ascii=False), encoding="utf-8")
            extra_result = self._run_cli_with_locale_args(
                catalog_path=catalog_path,
                output_dir=output_dir,
                locale_args=[
                    f"cmn-Hant-TW={locale_paths['cmn-Hant-TW']}",
                    f"jpn-Jpan-JP={locale_paths['jpn-Jpan-JP']}",
                    f"spa-Latn-ES={locale_paths['spa-Latn-ES']}",
                    f"cmn-Hans-CN={locale_paths['cmn-Hans-CN']}",
                    f"fr-FR={extra_path}",
                ],
            )
            self.assertNotEqual(extra_result.returncode, 0)
            self.assertIn("fr-FR", extra_result.stderr)

    def test_cli_rejects_duplicate_locale_override(self) -> None:
        self.assertTrue(GENERATE_BUNDLE.exists(), "generate-bundle.py should exist")

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            catalog_path, locale_paths = self._write_fixture_tree(temp_root)
            output_dir = temp_root / "artifacts" / "system-ui"

            result = self._run_cli_with_locale_args(
                catalog_path=catalog_path,
                output_dir=output_dir,
                locale_args=[
                    f"cmn-Hant-TW={locale_paths['cmn-Hant-TW']}",
                    f"jpn-Jpan-JP={locale_paths['jpn-Jpan-JP']}",
                    f"spa-Latn-ES={locale_paths['spa-Latn-ES']}",
                    f"cmn-Hans-CN={locale_paths['cmn-Hans-CN']}",
                    f"spa-Latn-ES={locale_paths['spa-Latn-ES']}",
                ],
            )

            self.assertNotEqual(result.returncode, 0)
            self.assertIn("duplicate locale override: spa-Latn-ES", result.stderr)

    def test_replace_artifacts_rolls_back_if_replace_fails_midway(self) -> None:
        self.assertTrue(GENERATE_BUNDLE.exists(), "generate-bundle.py should exist")

        with tempfile.TemporaryDirectory() as temp_dir:
            temp_root = Path(temp_dir)
            output_dir = temp_root / "artifacts" / "system-ui"
            output_dir.mkdir(parents=True, exist_ok=True)
            manifest_path = output_dir / "manifest.json"
            sql_path = output_dir / "system-ui.sql"
            manifest_original = b'{"sentinel":"manifest-before"}\n'
            sql_original = b"-- sentinel sql before\n"
            manifest_path.write_bytes(manifest_original)
            sql_path.write_bytes(sql_original)

            module = load_module("generate_bundle_replace", GENERATE_BUNDLE)
            staging_dir = temp_root / "staging"
            staging_dir.mkdir()
            staged_sql_path = staging_dir / "system-ui.sql"
            staged_manifest_path = staging_dir / "manifest.json"
            staged_sql_path.write_text("-- new sql\n", encoding="utf-8")
            staged_manifest_path.write_text('{"sentinel":"manifest-after"}\n', encoding="utf-8")

            calls: list[tuple[str, str]] = []

            def flaky_replace(src: Path, dst: Path) -> None:
                calls.append((src.name, dst.name))
                if dst.name == "manifest.json":
                    raise OSError("boom during manifest replace")
                Path(src).replace(dst)

            with self.assertRaisesRegex(OSError, "boom during manifest replace"):
                module.replace_artifacts(
                    output_dir,
                    staged_sql_path,
                    staged_manifest_path,
                    replace_fn=flaky_replace,
                )

            self.assertEqual(sql_path.read_bytes(), sql_original)
            self.assertEqual(manifest_path.read_bytes(), manifest_original)

    def test_generate_i18n_sql_rejects_unknown_keys_instead_of_skipping(self) -> None:
        self.assertTrue(GENERATE_SQL.exists(), "generate-i18n-sql.py should exist")
        module = load_module("generate_i18n_sql", GENERATE_SQL)
        source_map = {"common.search": "Search"}
        translations = {"common.search": "Buscar", "missing.key": "Desconocido"}

        with self.assertRaisesRegex(ValueError, "missing.key"):
            module.generate_sql("spa-Latn-ES", translations, source_map)


if __name__ == "__main__":
    unittest.main()
