from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

from lib import journal
from lib import migrations
from lib.paths import ProjectPaths
from lib.runner import CommandError, run_command


class ProductionInventoryError(RuntimeError):
    pass


@dataclass(frozen=True)
class ProductionExecutor:
    paths: ProjectPaths
    wrangler_bin: Path
    env: Mapping[str, str] | None = None
    timeout_seconds: float = 120.0

    def info(self, database_name: str) -> Any:
        return self._run([str(self.wrangler_bin), "d1", "info", database_name, "--remote", "--json"])

    def select(self, database_name: str, sql: str) -> list[dict[str, Any]]:
        return self._run(
            [
                str(self.wrangler_bin),
                "d1",
                "execute",
                database_name,
                "--remote",
                "--command",
                sql,
                "--json",
            ]
        )

    def _run(self, args: list[str]) -> Any:
        try:
            result = run_command(
                args,
                cwd=self.paths.backend_dir,
                env=self.env,
                timeout=self.timeout_seconds,
            )
        except CommandError as exc:
            raise ProductionInventoryError(str(exc)) from exc
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError as exc:
            raise ProductionInventoryError("wrangler returned invalid JSON") from exc


def inventory_production(
    paths: ProjectPaths,
    *,
    wrangler_bin: Path | None = None,
    env: Mapping[str, str] | None = None,
    report_path: Path | None = None,
) -> dict[str, Any]:
    configured = load_production_identity(paths.backend_dir / "wrangler.jsonc")
    executor = ProductionExecutor(
        paths=paths,
        wrangler_bin=wrangler_bin or (paths.backend_dir / "node_modules" / ".bin" / "wrangler"),
        env=env,
    )
    remote_identity = normalize_remote_identity(executor.info(configured["database_name"]))
    assert_identity(configured, remote_identity)

    schema_results = executor.select(configured["database_name"], INVENTORY_SCHEMA_SQL)
    count_results = executor.select(configured["database_name"], INVENTORY_COUNTS_SQL)
    schema_rows = _flatten_rows(schema_results)
    count_rows = _flatten_rows(count_results)
    locked_migrations = migrations.sync_migration_lock(
        paths.migrations_dir,
        paths.migration_lock_path,
        update=False,
        baseline_created_at="",
        git_commit="",
    )["migrations"]
    applied_names = [str(row["name"]) for row in schema_rows if "name" in row and row.get("kind") == "migration"]
    schema_objects = [
        {"type": str(row["type"]), "name": str(row["name"]), "sql": row.get("sql")}
        for row in schema_rows
        if row.get("kind") == "schema"
    ]
    columns = {
        table: [
            {"name": str(row["name"]), "type": str(row.get("column_type") or "")}
            for row in schema_rows
            if row.get("kind") == "column" and row.get("table_name") == table
        ]
        for table in sorted({str(row["table_name"]) for row in schema_rows if row.get("kind") == "column"})
    }
    counts = {str(row["metric"]): int(row["count"]) for row in count_rows if "metric" in row}
    report = {
        "status": "ok",
        "environment": "production",
        "identity": configured,
        "remote_identity": remote_identity,
        "schema_objects": schema_objects,
        "columns": columns,
        "migrations": {
            "expected": [str(migration["filename"]) for migration in locked_migrations],
            "applied": applied_names,
            "checksums": {
                str(migration["filename"]): str(migration["sha256"])
                for migration in locked_migrations
            },
        },
        "counts": counts,
        "ownership": {
            "system_ui_project": "langmap-web",
            "system_ui_messages": counts.get("managed_ui_messages", 0),
            "system_ui_edges": counts.get("managed_ui_edges", 0),
        },
    }
    journal.write_json_report(report_path or paths.production_inventory_report_path, report)
    return report


def load_production_identity(config_path: Path) -> dict[str, str]:
    try:
        payload = json.loads(_strip_jsonc_comments(config_path.read_text(encoding="utf-8")))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProductionInventoryError(f"invalid Wrangler config: {config_path}") from exc
    databases = payload.get("d1_databases")
    if not isinstance(databases, list) or len(databases) != 1 or not isinstance(databases[0], dict):
        raise ProductionInventoryError("production identity is missing or ambiguous")
    database = databases[0]
    name = _required_identity_value(database, "database_name")
    database_id = _required_identity_value(database, "database_id")
    if _is_placeholder(name) or _is_placeholder(database_id):
        raise ProductionInventoryError("production identity contains a placeholder")
    return {"database_name": name, "database_id": database_id}


def normalize_remote_identity(payload: Any) -> dict[str, str]:
    candidates: list[dict[str, Any]] = []

    def visit(value: Any) -> None:
        if isinstance(value, dict):
            if any(key in value for key in ("name", "database_name")) and any(
                key in value for key in ("uuid", "database_id", "id")
            ):
                candidates.append(value)
            for child in value.values():
                visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)

    visit(payload)
    if len(candidates) != 1:
        raise ProductionInventoryError("remote database identity is missing or ambiguous")
    candidate = candidates[0]
    name = str(candidate.get("name") or candidate.get("database_name") or "").strip()
    database_id = str(
        candidate.get("uuid") or candidate.get("database_id") or candidate.get("id") or ""
    ).strip()
    if not name or not database_id:
        raise ProductionInventoryError("remote database identity is incomplete")
    return {"database_name": name, "database_id": database_id}


def assert_identity(configured: dict[str, str], remote: dict[str, str]) -> None:
    if configured != remote:
        raise ProductionInventoryError(
            "production identity mismatch: "
            f"configured={configured['database_name']}/{configured['database_id']} "
            f"remote={remote['database_name']}/{remote['database_id']}"
        )


def check_baseline(paths: ProjectPaths, inventory: dict[str, Any]) -> dict[str, Any]:
    baseline = json.loads(paths.production_baseline_path.read_text(encoding="utf-8"))
    if baseline.get("identity") != inventory.get("identity"):
        raise ProductionInventoryError("production baseline identity mismatch")
    expected_objects = {
        (str(item["type"]), str(item["name"])) for item in baseline.get("schema_objects", [])
    }
    actual_objects = {
        (str(item["type"]), str(item["name"])) for item in inventory.get("schema_objects", [])
    }
    if expected_objects != actual_objects:
        raise ProductionInventoryError("production schema baseline mismatch")
    expected_migrations = baseline.get("migration_checksums", {})
    if expected_migrations != inventory.get("migrations", {}).get("checksums", {}):
        raise ProductionInventoryError("production migration checksum baseline mismatch")
    applied = set(inventory.get("migrations", {}).get("applied", []))
    if applied != set(expected_migrations):
        raise ProductionInventoryError("production migration history baseline mismatch")
    return {"status": "ok", "schema_objects": len(actual_objects), "migration_count": len(expected_migrations)}


def _required_identity_value(payload: dict[str, Any], key: str) -> str:
    value = payload.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ProductionInventoryError(f"production identity missing {key}")
    return value.strip()


def _is_placeholder(value: str) -> bool:
    lowered = value.lower()
    return lowered.startswith("your-") or "placeholder" in lowered or "<" in value or ">" in value


def _strip_jsonc_comments(text: str) -> str:
    return re.sub(r"^\s*//.*$", "", text, flags=re.MULTILINE)


def _flatten_rows(results: Any) -> list[dict[str, Any]]:
    if not isinstance(results, list):
        raise ProductionInventoryError("wrangler query response must be a result list")
    rows: list[dict[str, Any]] = []
    for result in results:
        if isinstance(result, dict):
            result_rows = result.get("results", [])
            if isinstance(result_rows, list):
                rows.extend(row for row in result_rows if isinstance(row, dict))
    return rows


INVENTORY_SCHEMA_SQL = """
SELECT 'schema' AS kind, type, name, sql FROM sqlite_master
WHERE type IN ('table', 'index', 'trigger')
  AND name NOT LIKE 'sqlite_%'
  AND name NOT IN ('d1_migrations', '_cf_METADATA')
  AND name NOT LIKE 'expressions_fts_%'
ORDER BY type, name;
SELECT 'column' AS kind, m.name AS table_name, p.name, p.type AS column_type
FROM sqlite_master m JOIN pragma_table_info(m.name) p
WHERE m.type = 'table' AND m.name NOT LIKE 'sqlite_%'
ORDER BY m.name, p.cid;
SELECT 'migration' AS kind, name FROM d1_migrations ORDER BY id;
""".strip()

INVENTORY_COUNTS_SQL = """
SELECT 'languages' AS metric, COUNT(*) AS count FROM languages;
SELECT 'languoids' AS metric, COUNT(*) AS count FROM languoids;
SELECT 'language_locations' AS metric, COUNT(*) AS count FROM language_locations;
SELECT 'expressions' AS metric, COUNT(*) AS count FROM expressions;
SELECT 'expression_edges' AS metric, COUNT(*) AS count FROM expression_edges;
SELECT 'ui_locales' AS metric, COUNT(*) AS count FROM ui_locales;
SELECT 'ui_messages' AS metric, COUNT(*) AS count FROM ui_messages;
SELECT 'managed_ui_messages' AS metric, COUNT(*) FROM ui_messages WHERE project_id = 'langmap-web';
SELECT 'managed_ui_edges' AS metric, COUNT(*) FROM expression_edges WHERE source = 'ui_i18n';
SELECT 'orphan_languages' AS metric, COUNT(*) FROM languages WHERE variety_key NOT LIKE 'system:%' AND (TRIM(COALESCE(glottocode, '')) = '' OR NOT EXISTS (SELECT 1 FROM languoids WHERE languoids.glottocode = languages.glottocode));
SELECT 'orphan_ui_messages' AS metric, COUNT(*) FROM ui_messages m LEFT JOIN expressions e ON e.id = m.source_expression_id WHERE e.id IS NULL;
SELECT 'orphan_expression_edges' AS metric, COUNT(*) FROM expression_edges x LEFT JOIN expressions a ON a.id = x.expression_a_id LEFT JOIN expressions b ON b.id = x.expression_b_id WHERE a.id IS NULL OR b.id IS NULL;
""".strip()
