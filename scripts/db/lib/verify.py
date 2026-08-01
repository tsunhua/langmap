from __future__ import annotations

import json
import re
import sqlite3
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
    ("table", re.compile(r"^\s*CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?P<name>\"[^\"]+\"|`[^`]+`|[A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)),
    ("virtual_table", re.compile(r"^\s*CREATE\s+VIRTUAL\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?P<name>\"[^\"]+\"|`[^`]+`|[A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)),
    ("index", re.compile(r"^\s*CREATE\s+INDEX\s+(?:IF\s+NOT\s+EXISTS\s+)?(?P<name>\"[^\"]+\"|`[^`]+`|[A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)),
    ("trigger", re.compile(r"^\s*CREATE\s+TRIGGER\s+(?:IF\s+NOT\s+EXISTS\s+)?(?P<name>\"[^\"]+\"|`[^`]+`|[A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)),
)


@dataclass(frozen=True)
class SchemaObject:
    kind: str
    name: str
    normalized_sql: str


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

    locked = _load_verified_migration_lock(paths)
    expected_objects = _load_expected_schema_objects(paths.schema_path)
    actual_objects = _load_actual_schema_objects(executor, state_dir)
    schema_mismatches = _compare_expected_schema_objects(expected_objects, actual_objects)
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
            "missing": [
                {"kind": item.kind, "name": item.name}
                for item in schema_mismatches["missing"]
            ],
            "mismatched_sql": [
                {"kind": expected.kind, "name": expected.name}
                for expected, _ in schema_mismatches["mismatched_sql"]
            ],
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
    if schema_mismatches["missing"] or schema_mismatches["mismatched_sql"]:
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
    expected_objects = _load_expected_schema_objects(paths.schema_path)
    actual_objects = _load_actual_schema_objects(executor, persist_to)
    schema_mismatches = _compare_expected_schema_objects(expected_objects, actual_objects)
    if schema_mismatches["missing"] or schema_mismatches["mismatched_sql"]:
        names = [
            f"{item.kind}:{item.name}" for item in schema_mismatches["missing"]
        ] + [
            f"{expected.kind}:{expected.name}"
            for expected, _ in schema_mismatches["mismatched_sql"]
        ]
        raise LocalVerificationError(
            "schema invariants missing before baseline: " + ", ".join(sorted(names))
        )

    locked = _load_verified_migration_lock(paths)
    migration_names = [entry["filename"] for entry in locked["migrations"]]
    statements = [CREATE_MIGRATIONS_TABLE_SQL, 'DELETE FROM "d1_migrations";']
    for name in migration_names:
        escaped = name.replace("'", "''")
        statements.append(f"INSERT INTO \"d1_migrations\" (name) VALUES ('{escaped}');")
    executor.execute_query(persist_to, "\n".join(statements))
    return migration_names


def _load_expected_schema_objects(schema_path: Path) -> dict[tuple[str, str], SchemaObject]:
    sql = schema_path.read_text(encoding="utf-8")
    objects: dict[tuple[str, str], SchemaObject] = {}
    for statement in _split_sql(sql):
        schema_object = _parse_schema_object(statement)
        if schema_object is None:
            continue
        objects[(schema_object.kind, schema_object.name)] = schema_object
    return objects


def _load_actual_schema_objects(
    executor: LocalWranglerExecutor, persist_to: Path
) -> dict[tuple[str, str], SchemaObject]:
    rows = executor.execute_query(
        persist_to,
        """
SELECT type, name, sql
FROM sqlite_master
WHERE type IN ('table', 'index', 'trigger')
  AND name NOT LIKE 'sqlite_%'
  AND name != 'd1_migrations'
ORDER BY type, name;
""".strip(),
    )
    actual: dict[tuple[str, str], SchemaObject] = {}
    for row in rows[0]["results"]:
        sql = row.get("sql")
        if not sql:
            continue
        schema_object = _parse_actual_schema_object(
            entry_type=str(row["type"]),
            name=str(row["name"]),
            sql=str(sql),
        )
        actual[(schema_object.kind, schema_object.name)] = schema_object
    return actual


def _compare_expected_schema_objects(
    expected: dict[tuple[str, str], SchemaObject],
    actual: dict[tuple[str, str], SchemaObject],
) -> dict[str, Any]:
    missing: list[SchemaObject] = []
    mismatched_sql: list[tuple[SchemaObject, SchemaObject]] = []
    for key, expected_object in expected.items():
        actual_object = actual.get(key)
        if actual_object is None:
            missing.append(expected_object)
            continue
        if actual_object.normalized_sql != expected_object.normalized_sql:
            mismatched_sql.append((expected_object, actual_object))
    return {"missing": missing, "mismatched_sql": mismatched_sql}


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


def _load_verified_migration_lock(paths: ProjectPaths) -> dict[str, Any]:
    try:
        return migrations_lib.sync_migration_lock(
            paths.migrations_dir,
            paths.migration_lock_path,
            update=False,
            baseline_created_at="ignored",
            git_commit="ignored",
        )
    except (FileNotFoundError, ValueError) as exc:
        raise LocalVerificationError(f"migration lock verification failed: {exc}") from exc


def _split_sql(script: str) -> list[str]:
    statements: list[str] = []
    buffer = ""
    for line in script.splitlines(keepends=True):
        buffer += line
        if sqlite3.complete_statement(buffer):
            statement = buffer.strip()
            if statement:
                statements.append(statement)
            buffer = ""
    trailing = buffer.strip()
    if trailing:
        statements.append(trailing)
    return statements


def _parse_schema_object(statement: str) -> SchemaObject | None:
    for kind, pattern in OBJECT_PATTERNS:
        match = pattern.match(statement)
        if match is None:
            continue
        name = _strip_identifier_quotes(match.group("name"))
        return SchemaObject(kind=kind, name=name, normalized_sql=_normalize_sql(statement))
    return None


def _parse_actual_schema_object(*, entry_type: str, name: str, sql: str) -> SchemaObject:
    kind = "virtual_table" if entry_type == "table" and re.match(r"^\s*CREATE\s+VIRTUAL\s+TABLE", sql, re.IGNORECASE) else entry_type
    return SchemaObject(kind=kind, name=name, normalized_sql=_normalize_sql(sql))


def _strip_identifier_quotes(value: str) -> str:
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("`") and value.endswith("`")):
        return value[1:-1]
    return value


def _normalize_sql(value: str) -> str:
    normalized = value.strip().rstrip(";")
    normalized = normalized.replace('"', "").replace("`", "")
    normalized = re.sub(r"\s+", " ", normalized)
    return normalized.lower()


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
