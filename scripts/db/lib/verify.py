from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping

from lib import migrations as migrations_lib
from lib.paths import ProjectPaths
from lib.runner import CommandError, run_command


PROJECT_ID = "langmap-web"
CREATE_MIGRATIONS_TABLE_SQL = """CREATE TABLE IF NOT EXISTS "d1_migrations"(
\tid         INTEGER PRIMARY KEY AUTOINCREMENT,
\tname       TEXT UNIQUE,
\tapplied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);"""

OBJECT_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("table", re.compile(r"^\s*CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?P<name>[A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE | re.MULTILINE)),
    ("table", re.compile(r"^\s*CREATE\s+VIRTUAL\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?P<name>[A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE | re.MULTILINE)),
    ("index", re.compile(r"^\s*CREATE\s+INDEX\s+(?:IF\s+NOT\s+EXISTS\s+)?(?P<name>[A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE | re.MULTILINE)),
    ("trigger", re.compile(r"^\s*CREATE\s+TRIGGER\s+(?:IF\s+NOT\s+EXISTS\s+)?(?P<name>[A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE | re.MULTILINE)),
)


class LocalVerificationError(RuntimeError):
    def __init__(self, message: str, *, report: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.report = report


@dataclass(frozen=True)
class LocalWranglerExecutor:
    paths: ProjectPaths
    wrangler_bin: Path
    env: Mapping[str, str] | None = None

    def execute_file(self, persist_to: Path, sql_path: Path) -> list[dict[str, Any]]:
        return self._run([str(self.wrangler_bin), "d1", "execute", "DB", "--local", "--persist-to", str(persist_to), "--file", str(sql_path), "--json"])

    def execute_query(self, persist_to: Path, sql: str) -> list[dict[str, Any]]:
        return self._run([str(self.wrangler_bin), "d1", "execute", "DB", "--local", "--persist-to", str(persist_to), "--command", sql, "--json"])

    def _run(self, args: list[str]) -> list[dict[str, Any]]:
        try:
            result = run_command(args, cwd=self.paths.backend_dir, env=self.env)
        except CommandError as exc:
            message = _extract_command_error_message(exc)
            raise LocalVerificationError(message) from exc
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            raise LocalVerificationError(f"invalid wrangler JSON output: {result.stdout[:200]}") from exc


def verify_local_state(
    paths: ProjectPaths,
    *,
    wrangler_bin: Path | None = None,
    env: Mapping[str, str] | None = None,
    persist_to: Path | None = None,
    write_report: bool = True,
) -> dict[str, Any]:
    executor = LocalWranglerExecutor(paths=paths, wrangler_bin=wrangler_bin or (paths.backend_dir / "node_modules" / ".bin" / "wrangler"), env=env)
    state_dir = persist_to or paths.local_d1_state_dir

    schema_names = _load_expected_schema_names(paths.schema_path)
    actual_objects = _load_actual_schema_names(executor, state_dir)
    missing_objects = {
        kind: sorted(expected - actual_objects.get(kind, set()))
        for kind, expected in schema_names.items()
        if expected - actual_objects.get(kind, set())
    }

    locked = migrations_lib.sync_migration_lock(
        paths.migrations_dir,
        paths.migration_lock_path,
        update=False,
        baseline_created_at="ignored",
        git_commit="ignored",
    )
    applied_names = _first_row_values(
        executor.execute_query(state_dir, 'SELECT name FROM d1_migrations ORDER BY id;')
    )
    expected_names = [entry["filename"] for entry in locked["migrations"]]

    language_manifest = json.loads(paths.language_manifest_path.read_text(encoding="utf-8"))
    ui_manifest = json.loads(paths.ui_bundle_manifest_path.read_text(encoding="utf-8"))
    ui_counts = ui_manifest.get("counts", {})
    locale_codes = [str(code) for code in ui_manifest.get("locale_codes", [])]
    escaped_locale_codes = ["'" + code.replace("'", "''") + "'" for code in locale_codes]
    locale_code_sql = ", ".join(escaped_locale_codes) or "''"

    count_rows = executor.execute_query(
        state_dir,
        f"""
SELECT COUNT(*) AS languages FROM languages;
SELECT COUNT(*) AS languoids FROM languoids;
SELECT COUNT(*) AS language_subtags FROM language_subtags;
SELECT COUNT(*) AS language_locations FROM language_locations;
SELECT COUNT(*) AS ui_locales FROM ui_locales WHERE project_id = '{PROJECT_ID}';
SELECT COUNT(*) AS ui_messages FROM ui_messages WHERE project_id = '{PROJECT_ID}';
SELECT COUNT(*) AS ui_translation_mappings
FROM (
  SELECT m.key, te.language_code
  FROM ui_messages m
  JOIN expression_edges edge
    ON edge.source = 'ui_i18n'
   AND (edge.expression_a_id = m.source_expression_id OR edge.expression_b_id = m.source_expression_id)
  JOIN expressions te
    ON te.id = CASE
      WHEN edge.expression_a_id = m.source_expression_id THEN edge.expression_b_id
      ELSE edge.expression_a_id
    END
  WHERE m.project_id = '{PROJECT_ID}'
    AND te.language_code IN ({locale_code_sql})
  GROUP BY m.key, te.language_code
);
SELECT GROUP_CONCAT(code, ',') AS active_locale_codes
FROM (
  SELECT code
  FROM ui_locales
  WHERE project_id = '{PROJECT_ID}' AND status = 'active'
  ORDER BY code
);
SELECT COUNT(*) AS orphan_languages
FROM languages
WHERE variety_key NOT LIKE 'system:%'
  AND (
    TRIM(COALESCE(glottocode, '')) = ''
    OR NOT EXISTS (SELECT 1 FROM languoids WHERE languoids.glottocode = languages.glottocode)
  );
SELECT COUNT(*) AS orphan_locales
FROM ui_locales locale
LEFT JOIN languages language ON language.code = locale.code
LEFT JOIN ui_locales fallback
  ON fallback.project_id = locale.project_id
 AND fallback.code = locale.fallback_code
WHERE locale.project_id = '{PROJECT_ID}'
  AND (
    language.code IS NULL
    OR (locale.fallback_code IS NOT NULL AND fallback.code IS NULL)
  );
SELECT COUNT(*) AS orphan_messages
FROM ui_messages message
LEFT JOIN expressions expression
  ON expression.id = message.source_expression_id
WHERE message.project_id = '{PROJECT_ID}' AND expression.id IS NULL;
SELECT COUNT(*) AS orphan_edges
FROM expression_edges edge
LEFT JOIN expressions a ON a.id = edge.expression_a_id
LEFT JOIN expressions b ON b.id = edge.expression_b_id
WHERE edge.source = 'ui_i18n'
  AND (
    a.id IS NULL
    OR b.id IS NULL
    OR NOT EXISTS (
      SELECT 1
      FROM ui_messages message
      WHERE message.project_id = '{PROJECT_ID}'
        AND (
          message.source_expression_id = edge.expression_a_id
          OR message.source_expression_id = edge.expression_b_id
        )
    )
  );
""".strip(),
    )
    actual_counts = _rows_to_singletons(count_rows)
    actual_active_codes = _split_codes(actual_counts["active_locale_codes"])
    expected_active_codes = sorted(ui_manifest.get("locale_codes", []))

    report = {
        "status": "ok",
        "schema_objects": {
            "missing": missing_objects,
        },
        "migrations": {
            "expected_names": expected_names,
            "applied_names": applied_names,
            "checksums": {
                entry["filename"]: entry["sha256"] for entry in locked["migrations"]
            },
        },
        "counts": {
            "languages": {
                "expected": int(language_manifest["generation"]["language_tag_count"]),
                "actual": int(actual_counts["languages"]),
            },
            "languoids": {
                "expected": int(language_manifest["glottolog"]["languoid_count"]),
                "actual": int(actual_counts["languoids"]),
            },
            "language_subtags": {
                "expected": int(language_manifest["iana"]["subtag_count"]),
                "actual": int(actual_counts["language_subtags"]),
            },
            "language_locations": {
                "expected": int(language_manifest["generation"]["language_location_count"]),
                "actual": int(actual_counts["language_locations"]),
            },
            "ui_locales": {
                "expected": int(ui_counts["locale_count"]),
                "actual": int(actual_counts["ui_locales"]),
            },
            "ui_messages": {
                "expected": int(ui_counts["message_count"]),
                "actual": int(actual_counts["ui_messages"]),
            },
            "ui_translation_mappings": {
                "expected": int(ui_counts["translation_count"]),
                "actual": int(actual_counts["ui_translation_mappings"]),
            },
        },
        "active_locale_codes": {
            "expected": expected_active_codes,
            "actual": actual_active_codes,
        },
        "orphans": {
            "languages": int(actual_counts["orphan_languages"]),
            "locales": int(actual_counts["orphan_locales"]),
            "messages": int(actual_counts["orphan_messages"]),
            "edges": int(actual_counts["orphan_edges"]),
        },
    }

    mismatches: list[str] = []
    if any(missing_objects.values()):
        mismatches.append("missing schema objects")
    if applied_names != expected_names:
        mismatches.append("migration baseline mismatch")
    for payload in report["counts"].values():
        if payload["expected"] != payload["actual"]:
            mismatches.append("count mismatch")
            break
    if expected_active_codes != actual_active_codes:
        mismatches.append("active locale policy mismatch")
    if any(report["orphans"].values()):
        mismatches.append("orphan references detected")

    if mismatches:
        report["status"] = "error"
    if write_report:
        _write_json(paths.local_verification_report_path, report)
    if mismatches:
        raise LocalVerificationError(", ".join(mismatches), report=report)
    return report


def write_migration_baseline(
    paths: ProjectPaths,
    *,
    executor: LocalWranglerExecutor,
    persist_to: Path,
) -> list[str]:
    expected_objects = _load_expected_schema_names(paths.schema_path)
    actual_objects = _load_actual_schema_names(executor, persist_to)
    required_tables = {"languages", "languoids", "language_subtags", "language_locations", "ui_locales", "ui_messages", "expression_edges"}
    missing_required = required_tables - actual_objects.get("table", set())
    if missing_required:
        raise LocalVerificationError(
            "schema invariants missing before baseline: " + ", ".join(sorted(missing_required))
        )
    if expected_objects["trigger"] - actual_objects.get("trigger", set()):
        raise LocalVerificationError("schema triggers missing before baseline")

    locked = migrations_lib.sync_migration_lock(
        paths.migrations_dir,
        paths.migration_lock_path,
        update=False,
        baseline_created_at="ignored",
        git_commit="ignored",
    )
    migration_names = [entry["filename"] for entry in locked["migrations"]]
    statements = [CREATE_MIGRATIONS_TABLE_SQL, 'DELETE FROM "d1_migrations";']
    for name in migration_names:
        escaped = name.replace("'", "''")
        statements.append(f"INSERT INTO \"d1_migrations\" (name) VALUES ('{escaped}');")
    executor.execute_query(persist_to, "\n".join(statements))
    return migration_names


def _load_expected_schema_names(schema_path: Path) -> dict[str, set[str]]:
    sql = schema_path.read_text(encoding="utf-8")
    names: dict[str, set[str]] = {"table": set(), "index": set(), "trigger": set()}
    for kind, pattern in OBJECT_PATTERNS:
        for match in pattern.finditer(sql):
            names[kind].add(match.group("name"))
    return names


def _load_actual_schema_names(
    executor: LocalWranglerExecutor, persist_to: Path
) -> dict[str, set[str]]:
    rows = executor.execute_query(
        persist_to,
        """
SELECT type, name, sql
FROM sqlite_master
WHERE type IN ('table', 'index', 'trigger')
  AND name NOT LIKE 'sqlite_%'
ORDER BY type, name;
""".strip(),
    )
    actual: dict[str, set[str]] = {"table": set(), "index": set(), "trigger": set()}
    for row in rows[0]["results"]:
        entry_type = row["type"]
        if entry_type in actual:
            actual[entry_type].add(row["name"])
    return actual


def _rows_to_singletons(results: Iterable[dict[str, Any]]) -> dict[str, Any]:
    payload: dict[str, Any] = {}
    for result in results:
        rows = result.get("results", [])
        if not rows:
            continue
        payload.update(rows[0])
    return payload


def _first_row_values(results: list[dict[str, Any]]) -> list[str]:
    names: list[str] = []
    for result in results:
        for row in result.get("results", []):
            value = row.get("name")
            if value is not None:
                names.append(str(value))
    return names


def _split_codes(value: Any) -> list[str]:
    if not value:
        return []
    return [item for item in str(value).split(",") if item]


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _extract_command_error_message(exc: CommandError) -> str:
    stdout = exc.stdout.strip()
    if stdout:
        try:
            payload = json.loads(stdout)
        except json.JSONDecodeError:
            pass
        else:
            if isinstance(payload, dict):
                text = payload.get("error", {}).get("text")
                if text:
                    return str(text)
            if isinstance(payload, list):
                for item in payload:
                    if not isinstance(item, dict):
                        continue
                    text = item.get("error", {}).get("text")
                    if text:
                        return str(text)
    return exc.stderr.strip() or stdout or str(exc)
