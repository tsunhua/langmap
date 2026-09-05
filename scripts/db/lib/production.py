from __future__ import annotations

import json
import hashlib
import re
import uuid
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

from lib import journal
from lib import migrations
from lib.reference import diff_owned_references
from lib.paths import ProjectPaths
from lib.runner import CommandError, run_command
from lib.dictionary_release import ReleasePaths, apply_release as apply_dictionary_release, verify_release as verify_dictionary_release, activate_release as activate_dictionary_release


class ProductionInventoryError(RuntimeError):
    pass


SPLIT_SQL_BATCH_BYTES = 256 * 1024

DICTIONARY_POSTFLIGHT_TABLES = (
    "sources",
    "language_locales",
    "expressions",
    "expression_sources",
    "expression_locale_links",
    "expression_readings",
    "expression_edges",
    "expression_edge_sources",
)
DICTIONARY_POSTFLIGHT_PRIMARY_KEYS = {
    "sources": ("id",),
    "language_locales": ("id",),
    "expressions": ("id",),
    "expression_sources": ("expression_id", "source_id", "source_marker"),
    "expression_locale_links": ("expression_id", "locale_id"),
    "expression_readings": ("expression_id", "locale_id", "scheme", "value"),
    "expression_edges": ("id",),
    "expression_edge_sources": ("edge_id", "source_id", "source_marker"),
}


@dataclass(frozen=True)
class ProductionExecutor:
    paths: ProjectPaths
    wrangler_bin: Path
    env: Mapping[str, str] | None = None
    timeout_seconds: float = 120.0

    def info(self, database_name: str) -> Any:
        return self._run([str(self.wrangler_bin), "d1", "info", database_name, "--json"])

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

    def bookmark(self, database_name: str) -> dict[str, Any]:
        return self._run(
            [str(self.wrangler_bin), "d1", "time-travel", "info", database_name, "--json"]
        )

    def mutate(self, args: list[str]) -> str:
        try:
            result = run_command(
                [str(self.wrangler_bin), *args],
                cwd=self.paths.backend_dir,
                env=self.env,
                timeout=self.timeout_seconds,
            )
        except CommandError as exc:
            raise ProductionInventoryError(str(exc)) from exc
        return result.stdout

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
    schema_rows = _flatten_rows(schema_results)
    table_names = sorted(
        str(row["name"])
        for row in schema_rows
        if row.get("kind") == "schema"
        and row.get("type") == "table"
        and not str(row.get("name", "")).startswith("_cf_")
    )
    column_rows: list[dict[str, Any]] = []
    for start in range(0, len(table_names), 3):
        table_batch = table_names[start : start + 3]
        column_results = executor.select(
            configured["database_name"],
            _build_column_inventory_sql(table_batch),
        )
        column_rows.extend(_annotate_column_rows(table_batch, column_results))
    count_results = executor.select(configured["database_name"], INVENTORY_COUNTS_SQL)
    schema_rows.extend(column_rows)
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
    counts = {
        str(row["metric"]): int(row["count"])
        for row in count_rows
        if "metric" in row and "count" in row
    }
    managed_keys = {
        str(row["key"]): str(row.get("source_hash") or "")
        for row in count_rows
        if row.get("kind") == "ui_key"
    }
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
            "system_ui_keys": managed_keys,
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
    try:
        baseline = json.loads(paths.production_baseline_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProductionInventoryError("production baseline is missing or invalid") from exc
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
    actual_checksums = inventory.get("migrations", {}).get("checksums", {})
    if any(actual_checksums.get(name) != checksum for name, checksum in expected_migrations.items()):
        raise ProductionInventoryError("production migration checksum baseline mismatch")
    applied = set(inventory.get("migrations", {}).get("applied", []))
    if applied != set(expected_migrations):
        raise ProductionInventoryError("production migration history baseline mismatch")
    return {"status": "ok", "schema_objects": len(actual_objects), "migration_count": len(expected_migrations)}


def check_target_schema(paths: ProjectPaths, inventory: dict[str, Any]) -> dict[str, Any]:
    expected_objects = {
        (kind, name)
        for kind, name in _expected_schema_object_names(paths.schema_path)
    }
    actual_objects = {
        (str(item["type"]), str(item["name"]))
        for item in inventory.get("schema_objects", [])
    }
    if not expected_objects.issubset(actual_objects):
        raise ProductionInventoryError("production target schema mismatch")
    expected_migrations = list(inventory.get("migrations", {}).get("expected", []))
    applied_migrations = list(inventory.get("migrations", {}).get("applied", []))
    if applied_migrations != expected_migrations:
        raise ProductionInventoryError("production target migration history mismatch")
    return {
        "status": "ok",
        "schema_objects": len(expected_objects),
        "migration_count": len(expected_migrations),
    }


def _expected_schema_object_names(schema_path: Path) -> set[tuple[str, str]]:
    objects: set[tuple[str, str]] = set()
    for statement in schema_path.read_text(encoding="utf-8").split(";"):
        match = re.match(
            r"\s*CREATE\s+(TABLE|INDEX|TRIGGER)\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:\"([^\"]+)\"|`([^`]+)`|([A-Za-z_][A-Za-z0-9_]*))",
            statement,
            re.IGNORECASE,
        )
        if not match:
            continue
        kind = match.group(1).lower()
        name = next(value for value in match.groups()[1:] if value is not None)
        objects.add((kind, name))
    return objects


def plan_production(
    paths: ProjectPaths,
    *,
    wrangler_bin: Path | None = None,
    env: Mapping[str, str] | None = None,
    dictionary_artifact_manifest: Path | None = None,
    approved_data_migration: Path | None = None,
    dictionary_postflight_manifest: Path | None = None,
    refresh_language_statistics: bool = False,
) -> dict[str, Any]:
    inventory = inventory_production(paths, wrangler_bin=wrangler_bin, env=env)
    operation_id = uuid.uuid4().hex
    baseline_error: str | None = None
    try:
        schema_preflight = check_baseline(paths, inventory)
    except ProductionInventoryError as exc:
        schema_preflight = {"status": "blocked"}
        baseline_error = str(exc)

    expected_migrations = list(inventory["migrations"]["expected"])
    applied_migrations = set(inventory["migrations"]["applied"])
    pending_migrations = [name for name in expected_migrations if name not in applied_migrations]
    migration_risks: dict[str, Any] = {}
    metadata_errors: list[str] = []
    for name in pending_migrations:
        migration_path = paths.migrations_dir / name
        risk = classify_migration_risk(migration_path)
        entry: dict[str, Any] = {"classification": risk}
        if risk == "high":
            try:
                entry["metadata"] = load_migration_metadata(migration_path)
            except ProductionInventoryError as exc:
                entry["metadata_status"] = "missing-or-invalid"
                metadata_errors.append(f"{name}: {exc}")
        migration_risks[name] = entry
    if metadata_errors:
        baseline_error = "; ".join(metadata_errors)
    language_manifest = json.loads(paths.language_manifest_path.read_text(encoding="utf-8"))
    ui_manifest = json.loads(paths.ui_bundle_manifest_path.read_text(encoding="utf-8"))
    expected_refs = {
        "languages": str(language_manifest["counts"]["languages"]),
        "ui_messages": str(ui_manifest["counts"]["message_count"]),
        "managed_ui_edges": str(ui_manifest["counts"].get("edge_count", ui_manifest["counts"]["translation_count"])),
    }
    actual_refs = {
        "languages": str(inventory["counts"].get("languages", 0)),
        "ui_messages": str(inventory["counts"].get("ui_messages", 0)),
        "managed_ui_edges": str(inventory["ownership"].get("system_ui_edges", 0)),
    }
    reference_actions = {
        key: "unchanged" if expected_refs[key] == actual_refs[key] else "manual-review"
        for key in expected_refs
    }
    desired_keys = _load_bundle_message_keys(paths.system_ui_sql_path)
    remote_keys = inventory["ownership"].get("system_ui_keys", {})
    key_diff = diff_owned_references(
        desired_keys,
        remote_keys,
        owned_keys=set(remote_keys),
    )
    dictionary_artifact: dict[str, Any] | None = None
    if dictionary_artifact_manifest is not None:
        dictionary_artifact = _validate_dictionary_artifact(paths, dictionary_artifact_manifest)
    approved_data: dict[str, Any] | None = None
    if approved_data_migration is not None:
        resolved = _resolve_managed_artifact(paths, str(approved_data_migration))
        approved_data = {
            "path": str(resolved.relative_to(paths.repo_root.resolve())),
            "sha256": _sha256_path(resolved),
            "bytes": resolved.stat().st_size,
            "mode": "split" if str(approved_data_migration).endswith(".split.sql") else "file",
        }
    dictionary_postflight: dict[str, Any] | None = None
    if dictionary_postflight_manifest is not None:
        dictionary_postflight, postflight_error = _validate_dictionary_postflight_manifest(
            paths,
            dictionary_postflight_manifest,
            inventory,
        )
        if postflight_error:
            baseline_error = postflight_error
        else:
            sample_error = _validate_dictionary_postflight_samples(
                paths,
                dictionary_postflight,
                sections=("before",),
                wrangler_bin=wrangler_bin,
                env=env,
            )
            if sample_error:
                baseline_error = sample_error
    statistics_refresh: dict[str, Any] | None = None
    if refresh_language_statistics:
        refresh_path = (
            paths.repo_root
            / "scripts"
            / "db"
            / "state"
            / "backup"
            / "delta"
            / "006-refresh-language-statistics.sql"
        )
        resolved_refresh = _resolve_managed_artifact(paths, str(refresh_path.relative_to(paths.repo_root)))
        statistics_refresh = {
            "path": str(resolved_refresh.relative_to(paths.repo_root.resolve())),
            "sha256": _sha256_path(resolved_refresh),
            "bytes": resolved_refresh.stat().st_size,
            "mode": "file",
        }
    reference_changes = any(
        action != "unchanged" for action in reference_actions.values()
    ) or any(
        key_diff.counts.get(key, 0)
        for key in ("insert", "update", "manual_review", "delete")
    )
    if (
        approved_data is not None
        and dictionary_artifact is None
        and not pending_migrations
        and not reference_changes
    ):
        reference_artifacts = {
            "action": "skip",
            "reason": "unchanged-data-only-release",
        }
    else:
        reference_artifacts = {
            "action": "apply",
            "reason": (
                "reference-changes-detected"
                if reference_changes
                else "full-release"
            ),
        }
    plan = {
        "status": "blocked" if baseline_error else "ready",
        "environment": "production",
        "operation_id": operation_id,
        "identity": inventory["identity"],
        "schema_preflight": schema_preflight,
        "schema_preflight_error": baseline_error,
        "pending_migrations": pending_migrations,
        "migration_risks": migration_risks,
        "reference_diff": {
            "managed_keys": key_diff.counts,
            "missing_keys": list(key_diff.inserts),
            "changed_keys": list(key_diff.updates),
            "manual_review_keys": list(key_diff.manual_review),
            "expected": expected_refs,
            "actual": actual_refs,
            "actions": reference_actions,
            "counts": key_diff.counts,
            "aggregate_counts": {
                "unchanged": sum(action == "unchanged" for action in reference_actions.values()),
                "manual_review": sum(action == "manual-review" for action in reference_actions.values()),
            },
        },
        "risk": "high" if pending_migrations or baseline_error else "low",
        "mutation_allowed": False,
        "git_commit": _current_git_commit(paths),
        "migration_checksums": inventory["migrations"]["checksums"],
        "artifacts": {
            "language_registry": str(paths.language_registry_sql_path.relative_to(paths.repo_root)),
            "system_ui": str(paths.system_ui_sql_path.relative_to(paths.repo_root)),
        },
        "approved_data_migration": approved_data,
        "dictionary_artifact": dictionary_artifact,
        "dictionary_postflight": dictionary_postflight,
        "reference_artifacts": reference_artifacts,
        "statistics_refresh": statistics_refresh,
    }
    journal.write_json_report(paths.production_plan_dir / f"{operation_id}.json", plan)
    return plan


def verify_production(
    paths: ProjectPaths,
    *,
    wrangler_bin: Path | None = None,
    env: Mapping[str, str] | None = None,
) -> dict[str, Any]:
    inventory = inventory_production(paths, wrangler_bin=wrangler_bin, env=env)
    try:
        baseline = check_baseline(paths, inventory)
    except ProductionInventoryError:
        baseline = check_target_schema(paths, inventory)
    orphan_counts = {
        key: value
        for key, value in inventory["counts"].items()
        if key.startswith("orphan_") and value
    }
    if orphan_counts:
        raise ProductionInventoryError(
            "production orphan references detected: " + json.dumps(orphan_counts, sort_keys=True)
        )
    return {
        "status": "ok",
        "environment": "production",
        "identity": inventory["identity"],
        "baseline": baseline,
        "counts": inventory["counts"],
        "ownership": inventory["ownership"],
    }


def apply_production(
    paths: ProjectPaths,
    *,
    plan_path: Path,
    database_name: str,
    confirmation: str,
    wrangler_bin: Path | None = None,
    env: Mapping[str, str] | None = None,
    confirm_release_id: str | None = None,
    timeout_seconds: float = 120.0,
) -> dict[str, Any]:
    plan = _load_plan(plan_path)
    configured = load_production_identity(paths.backend_dir / "wrangler.jsonc")
    if plan.get("status") != "ready":
        raise ProductionInventoryError("production plan is not ready")
    if database_name != configured["database_name"] or confirmation != configured["database_name"]:
        raise ProductionInventoryError("production database name confirmation mismatch")
    if plan.get("identity") != configured:
        raise ProductionInventoryError("production plan identity mismatch")
    if plan.get("git_commit") != _current_git_commit(paths):
        raise ProductionInventoryError("production plan Git commit mismatch")
    operation_id = str(plan["operation_id"])
    try:
        prior_events = journal.read_operation_events(
            paths.production_operation_journal_path,
            operation_id,
        )
    except ValueError as exc:
        raise ProductionInventoryError(str(exc)) from exc
    expected_plan_path = plan_path.resolve()
    for event in prior_events:
        recorded_database = event.get("database")
        if recorded_database is not None and recorded_database != configured:
            raise ProductionInventoryError("production operation database changed during resume")
        recorded_plan_path = event.get("plan_path")
        if isinstance(recorded_plan_path, str) and recorded_plan_path:
            candidate = Path(recorded_plan_path)
            if not candidate.is_absolute():
                candidate = paths.repo_root / candidate
            if candidate.resolve() != expected_plan_path:
                raise ProductionInventoryError("production operation plan changed during resume")
    completed_stages = {
        str(event.get("status", "")) for event in prior_events
    }
    prior_bookmark = next(
        (
            str(event["bookmark"])
            for event in prior_events
            if isinstance(event.get("bookmark"), str) and event["bookmark"]
        ),
        None,
    )
    if "succeeded" in completed_stages:
        return {
            "status": "succeeded",
            "bookmark": prior_bookmark,
            "operation_id": operation_id,
            "resumed": True,
        }
    executor = ProductionExecutor(
        paths=paths,
        wrangler_bin=wrangler_bin or (paths.backend_dir / "node_modules" / ".bin" / "wrangler"),
        env=env,
        timeout_seconds=timeout_seconds,
    )
    dictionary_postflight = plan.get("dictionary_postflight")
    if dictionary_postflight is not None:
        if not isinstance(dictionary_postflight, dict):
            raise ProductionInventoryError("dictionary postflight metadata is invalid")
        _validate_dictionary_postflight_artifact(paths, dictionary_postflight)
    operation = {
        "operation_id": operation_id,
        "status": "started",
        "database": configured,
        "plan_path": str(plan_path),
        "failed_stage": None,
        "resumed": bool(prior_events),
    }
    journal.append_operation(paths.production_operation_journal_path, operation)
    current_stage = "identity"
    try:
        remote_identity = normalize_remote_identity(executor.info(database_name))
        assert_identity(configured, remote_identity)
        checkpointed_stages = {
            "migrations-applied",
            "dictionary-release-activated",
            "data-applied",
            "references-applied",
            "statistics-refreshed",
        }
        mutation_may_have_started = any(
            event.get("status") == "failed"
            and event.get("failed_stage") in {"migrations", "data", "statistics", "references"}
            for event in prior_events
        )
        if completed_stages & checkpointed_stages or mutation_may_have_started:
            if prior_bookmark is None:
                raise ProductionInventoryError(
                    "resumable production operation is missing its original bookmark"
                )
            bookmark = prior_bookmark
        else:
            current_stage = "bookmark"
            bookmark = _extract_bookmark(executor.bookmark(database_name))
        operation["bookmark"] = bookmark
        if not (completed_stages & checkpointed_stages) and not mutation_may_have_started:
            journal.append_operation(
                paths.production_operation_journal_path,
                {**operation, "status": "bookmarked"},
            )
        if plan.get("pending_migrations") and "migrations-applied" not in completed_stages:
            current_stage = "migrations"
            executor.mutate(["d1", "migrations", "apply", database_name, "--remote"])
            journal.append_operation(
                paths.production_operation_journal_path,
                {**operation, "status": "migrations-applied"},
            )
        dictionary_artifact = plan.get("dictionary_artifact")
        approved_data_migration = plan.get("approved_data_migration")
        data_already_applied = (
            "data-applied" in completed_stages
            or "dictionary-release-activated" in completed_stages
        )
        if not data_already_applied:
            current_stage = "data"
            if dictionary_artifact:
                release_id = str(dictionary_artifact.get("release_id", ""))
                if not confirm_release_id or confirm_release_id != release_id:
                    raise ProductionInventoryError("dictionary release confirmation mismatch")
                manifest_path = _resolve_dictionary_artifact(paths, str(dictionary_artifact["manifest_path"]))
                result = apply_dictionary_release(
                    ReleasePaths(paths.repo_root, paths.state_dir),
                    manifest_path,
                    environment="production",
                    database_name=database_name,
                    wrangler_bin=executor.wrangler_bin,
                    env=env,
                )
                if result.status != "validated":
                    raise ProductionInventoryError("dictionary release did not validate")
                activate_dictionary_release(
                    ReleasePaths(paths.repo_root, paths.state_dir),
                    release_id,
                    environment="production",
                    database_name=database_name,
                    wrangler_bin=executor.wrangler_bin,
                    env=env,
                )
                journal.append_operation(
                    paths.production_operation_journal_path,
                    {
                        **operation,
                        "status": "dictionary-release-activated",
                        "release_id": release_id,
                    },
                )
            elif approved_data_migration:
                relative = approved_data_migration.get("path")
                if not isinstance(relative, str):
                    raise ProductionInventoryError("approved data migration path is invalid")
                data_path = _resolve_managed_artifact(paths, relative)
                expected = approved_data_migration.get("sha256")
                if not isinstance(expected, str) or not expected:
                    raise ProductionInventoryError("approved data migration checksum is invalid")
                if _sha256_path(data_path) != expected:
                    raise ProductionInventoryError("approved data migration checksum mismatch")
                mode = approved_data_migration.get("mode", "file")
                if mode == "split":
                    completed_batches = {
                        int(event["batch_index"])
                        for event in prior_events
                        if event.get("status") == "data-batch-applied"
                        and event.get("data_sha256") == expected
                        and isinstance(event.get("batch_index"), int)
                    }
                    for batch_index, batch in _approved_sql_batches(
                        data_path,
                        max_bytes=SPLIT_SQL_BATCH_BYTES,
                    ):
                        if batch_index in completed_batches:
                            continue
                        executor.mutate(
                            ["d1", "execute", database_name, "--remote", "--command", batch]
                        )
                        journal.append_operation(
                            paths.production_operation_journal_path,
                            {
                                **operation,
                                "status": "data-batch-applied",
                                "batch_index": batch_index,
                                "batch_bytes": len(batch.encode("utf-8")),
                                "data_sha256": expected,
                            },
                        )
                else:
                    executor.mutate(
                        ["d1", "execute", database_name, "--remote", "--file", str(data_path)]
                    )
            else:
                journal.append_operation(
                    paths.production_operation_journal_path,
                    {**operation, "status": "data-migration-skipped"},
                )
            journal.append_operation(
                paths.production_operation_journal_path,
                {
                    **operation,
                    "status": "data-applied",
                    "mutation": bool(dictionary_artifact or approved_data_migration),
                },
            )
        statistics_refresh = plan.get("statistics_refresh")
        if (
            isinstance(statistics_refresh, dict)
            and "statistics-refreshed" not in completed_stages
        ):
            current_stage = "statistics"
            relative = statistics_refresh.get("path")
            expected = statistics_refresh.get("sha256")
            if not isinstance(relative, str) or not isinstance(expected, str) or not expected:
                raise ProductionInventoryError("statistics refresh artifact metadata is invalid")
            statistics_path = _resolve_managed_artifact(paths, relative)
            if _sha256_path(statistics_path) != expected:
                raise ProductionInventoryError("statistics refresh checksum mismatch")
            executor.mutate(
                [
                    "d1",
                    "execute",
                    database_name,
                    "--remote",
                    "--file",
                    str(statistics_path),
                ]
            )
            journal.append_operation(
                paths.production_operation_journal_path,
                {**operation, "status": "statistics-refreshed"},
            )
        reference_artifacts = plan.get("reference_artifacts")
        apply_references = not isinstance(reference_artifacts, dict) or (
            reference_artifacts.get("action", "apply") == "apply"
        )
        if "references-applied" not in completed_stages:
            current_stage = "references"
            if apply_references:
                executor.mutate(
                    [
                        "d1",
                        "execute",
                        database_name,
                        "--remote",
                        "--file",
                        str(paths.language_registry_sql_path),
                    ]
                )
                executor.mutate(
                    [
                        "d1",
                        "execute",
                        database_name,
                        "--remote",
                        "--file",
                        str(paths.system_ui_sql_path),
                    ]
                )
                for edge_sql_path in paths.system_ui_edges_sql_paths:
                    executor.mutate(
                        [
                            "d1",
                            "execute",
                            database_name,
                            "--remote",
                            "--file",
                            str(edge_sql_path),
                        ]
                    )
            journal.append_operation(
                paths.production_operation_journal_path,
                {
                    **operation,
                    "status": "references-applied",
                    "action": "apply" if apply_references else "skip",
                },
            )
        current_stage = "verify"
        verified = inventory_production(paths, wrangler_bin=executor.wrangler_bin, env=env)
        if plan.get("pending_migrations"):
            check_target_schema(paths, verified)
        else:
            check_baseline(paths, verified)
        if isinstance(dictionary_postflight, dict):
            _validate_dictionary_postflight_after(dictionary_postflight, verified)
            sample_error = _validate_dictionary_postflight_samples(
                paths,
                dictionary_postflight,
                sections=("after", "added"),
                wrangler_bin=executor.wrangler_bin,
                env=env,
            )
            if sample_error:
                raise ProductionInventoryError(sample_error)
        journal.append_operation(
            paths.production_operation_journal_path,
            {**operation, "status": "succeeded", "verified": True},
        )
        return {
            "status": "succeeded",
            "bookmark": bookmark,
            "operation_id": operation["operation_id"],
            "resumed": bool(prior_events),
        }
    except Exception as exc:
        journal.append_operation(
            paths.production_operation_journal_path,
            {
                **operation,
                "status": "failed",
                "failed_stage": current_stage,
                "error": str(exc),
            },
        )
        raise


def restore_production(
    paths: ProjectPaths,
    *,
    bookmark: str,
    database_name: str,
    confirmation: str,
    wrangler_bin: Path | None = None,
    env: Mapping[str, str] | None = None,
) -> dict[str, Any]:
    _validate_bookmark(bookmark)
    configured = load_production_identity(paths.backend_dir / "wrangler.jsonc")
    if database_name != configured["database_name"] or confirmation != configured["database_name"]:
        raise ProductionInventoryError("production database name confirmation mismatch")
    executor = ProductionExecutor(
        paths=paths,
        wrangler_bin=wrangler_bin or (paths.backend_dir / "node_modules" / ".bin" / "wrangler"),
        env=env,
    )
    operation = {
        "operation_id": uuid.uuid4().hex,
        "status": "started",
        "database": configured,
        "bookmark": bookmark,
        "failed_stage": None,
    }
    journal.append_operation(paths.production_operation_journal_path, operation)
    try:
        current = inventory_production(paths, wrangler_bin=executor.wrangler_bin, env=env)
        operation["pre_restore_inventory"] = {
            "schema_object_count": len(current["schema_objects"]),
            "migration_count": len(current["migrations"]["applied"]),
        }
        restore_result = executor.mutate(
            [
                "d1",
                "time-travel",
                "restore",
                database_name,
                "--bookmark",
                bookmark,
                "--json",
            ]
        )
        previous_bookmark = _extract_bookmark(json.loads(restore_result))
        operation["previous_bookmark"] = previous_bookmark
        after = inventory_production(paths, wrangler_bin=executor.wrangler_bin, env=env)
        check_baseline(paths, after)
        journal.append_operation(
            paths.production_operation_journal_path,
            {**operation, "status": "succeeded", "verified": True},
        )
        return {
            "status": "succeeded",
            "operation_id": operation["operation_id"],
            "previous_bookmark": previous_bookmark,
        }
    except Exception as exc:
        journal.append_operation(
            paths.production_operation_journal_path,
            {
                **operation,
                "status": "needs_manual_intervention",
                "error": str(exc),
            },
        )
        raise


def _load_plan(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProductionInventoryError("production plan is missing or invalid") from exc
    if not isinstance(payload, dict):
        raise ProductionInventoryError("production plan must be an object")
    return payload


def _split_approved_sql(path: Path) -> list[str]:
    """Split an approved data migration into standalone statements for D1's
    per-statement ``--command`` execution.  Statements are separated by ``;``
    at end-of-line; comments and the trailing pragmas are ignored."""
    raw = path.read_text(encoding="utf-8")
    statements: list[str] = []
    for chunk in raw.split(";\n"):
        lines = [
            line.strip()
            for line in chunk.splitlines()
            if not line.strip().startswith("--") and line.strip()
        ]
        if not lines:
            continue
        statement = " ".join(lines).strip()
        if statement and not statement.upper().startswith("PRAGMA"):
            statements.append(statement)
    return statements


def _approved_sql_batches(
    path: Path,
    *,
    max_bytes: int = SPLIT_SQL_BATCH_BYTES,
) -> Iterator[tuple[int, str]]:
    """Group standalone approved SQL statements into bounded remote commands."""

    if max_bytes < 1:
        raise ValueError("max_bytes must be positive")
    statements: list[str] = []
    current_bytes = 0
    batch_index = 0
    for statement in _split_approved_sql(path):
        statement = statement.rstrip()
        if not statement.endswith(";"):
            statement += ";"
        statement_bytes = len(statement.encode("utf-8"))
        separator_bytes = len("\n".encode("utf-8")) if statements else 0
        if statements and current_bytes + separator_bytes + statement_bytes > max_bytes:
            yield batch_index, "\n".join(statements)
            batch_index += 1
            statements = []
            current_bytes = 0
            separator_bytes = 0
        statements.append(statement)
        current_bytes += separator_bytes + statement_bytes
    if statements:
        yield batch_index, "\n".join(statements)


def _resolve_managed_artifact(paths: ProjectPaths, relative_path: str) -> Path:
    boundary = paths.repo_root.resolve()
    candidate = (boundary / relative_path).resolve()
    try:
        candidate.relative_to(boundary)
    except ValueError as exc:
        raise ProductionInventoryError("approved data migration escapes repository") from exc
    if not candidate.is_file():
        raise ProductionInventoryError("approved data migration artifact is missing")
    return candidate


def _validate_dictionary_postflight_manifest(
    paths: ProjectPaths,
    manifest_path: Path,
    inventory: dict[str, Any],
) -> tuple[dict[str, Any], str | None]:
    candidate = Path(manifest_path)
    try:
        resolved = _resolve_managed_artifact(paths, str(candidate))
        payload = json.loads(resolved.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError, ProductionInventoryError) as exc:
        raise ProductionInventoryError("dictionary postflight manifest is invalid") from exc
    if not isinstance(payload, dict) or payload.get("schema_version") != 1:
        raise ProductionInventoryError("dictionary postflight manifest schema version is invalid")

    count_sets: dict[str, dict[str, int]] = {}
    for count_name in ("before_counts", "after_counts", "added_counts"):
        raw_counts = payload.get(count_name)
        if not isinstance(raw_counts, dict):
            raise ProductionInventoryError(
                f"dictionary postflight manifest requires {count_name}"
            )
        counts: dict[str, int] = {}
        for table in DICTIONARY_POSTFLIGHT_TABLES:
            value = raw_counts.get(table)
            if not isinstance(value, int) or isinstance(value, bool) or value < 0:
                raise ProductionInventoryError(
                    f"dictionary postflight {count_name} has invalid {table}"
                )
            counts[table] = value
        count_sets[count_name] = counts
    for hash_name in ("before_sha256", "after_sha256"):
        value = payload.get(hash_name)
        if not isinstance(value, str) or len(value) != 64 or any(
            character not in "0123456789abcdef" for character in value.lower()
        ):
            raise ProductionInventoryError(
                f"dictionary postflight manifest has invalid {hash_name}"
            )

    samples_payload = payload.get("samples")
    samples: dict[str, dict[str, list[dict[str, Any]]]] | None = None
    if samples_payload is not None:
        if not isinstance(samples_payload, dict):
            raise ProductionInventoryError("dictionary postflight samples are invalid")
        samples = {}
        for section in ("before", "after", "added"):
            raw_section = samples_payload.get(section)
            if not isinstance(raw_section, dict):
                raise ProductionInventoryError(
                    f"dictionary postflight samples require {section}"
                )
            section_samples: dict[str, list[dict[str, Any]]] = {}
            for table, rows in raw_section.items():
                if table not in DICTIONARY_POSTFLIGHT_TABLES:
                    raise ProductionInventoryError(
                        f"dictionary postflight samples contain unknown table {table}"
                    )
                if not isinstance(rows, list) or len(rows) > 3:
                    raise ProductionInventoryError(
                        f"dictionary postflight samples for {table} are invalid"
                    )
                normalized_rows: list[dict[str, Any]] = []
                for row in rows:
                    if not isinstance(row, dict) or not row:
                        raise ProductionInventoryError(
                            f"dictionary postflight sample row for {table} is invalid"
                        )
                    if any(
                        not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", str(column))
                        or not _is_json_scalar(value)
                        for column, value in row.items()
                    ):
                        raise ProductionInventoryError(
                            f"dictionary postflight sample values for {table} are invalid"
                        )
                    if any(
                        primary_key not in row
                        for primary_key in DICTIONARY_POSTFLIGHT_PRIMARY_KEYS[table]
                    ):
                        raise ProductionInventoryError(
                            f"dictionary postflight sample key is incomplete for {table}"
                        )
                    normalized_rows.append({str(column): value for column, value in row.items()})
                section_samples[table] = normalized_rows
            samples[section] = section_samples

    metadata = {
        "path": str(resolved.relative_to(paths.repo_root.resolve())),
        "sha256": _sha256_path(resolved),
        "bytes": resolved.stat().st_size,
        **count_sets,
    }
    if samples is not None:
        metadata["samples"] = samples
    mismatches = {
        table: {
            "expected": count_sets["before_counts"][table],
            "actual": inventory.get("counts", {}).get(table),
        }
        for table in DICTIONARY_POSTFLIGHT_TABLES
        if inventory.get("counts", {}).get(table)
        != count_sets["before_counts"][table]
    }
    if mismatches:
        return (
            metadata,
            "dictionary postflight before-count mismatch: "
            + json.dumps(mismatches, sort_keys=True),
        )
    return metadata, None


def _is_json_scalar(value: Any) -> bool:
    return value is None or isinstance(value, (bool, int, float, str))


def _sql_literal(value: Any) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return repr(value)
    if isinstance(value, str):
        return "'" + value.replace("'", "''") + "'"
    raise ProductionInventoryError("dictionary postflight sample value is not scalar")


def _quoted_identifier(value: str) -> str:
    return '"' + value.replace('"', '""') + '"'


def _dictionary_postflight_sample_queries(
    samples: dict[str, dict[str, list[dict[str, Any]]]],
    sections: tuple[str, ...],
) -> tuple[str, list[tuple[str, str]]]:
    statements: list[str] = []
    descriptors: list[tuple[str, str]] = []
    for section in sections:
        for table in DICTIONARY_POSTFLIGHT_TABLES:
            rows = samples.get(section, {}).get(table, [])
            if not rows:
                continue
            columns = list(rows[0])
            if any(list(row) != columns for row in rows):
                raise ProductionInventoryError(
                    f"dictionary postflight sample columns differ for {table}"
                )
            primary_keys = DICTIONARY_POSTFLIGHT_PRIMARY_KEYS[table]
            predicates = []
            for row in rows:
                predicates.append(
                    "(" + " AND ".join(
                        f"{_quoted_identifier(column)} IS {_sql_literal(row[column])}"
                        for column in primary_keys
                    ) + ")"
                )
            select_columns = ", ".join(_quoted_identifier(column) for column in columns)
            order_columns = ", ".join(_quoted_identifier(column) for column in primary_keys)
            statements.append(
                f"SELECT {select_columns} FROM {_quoted_identifier(table)} "
                f"WHERE {' OR '.join(predicates)} ORDER BY {order_columns}"
            )
            descriptors.append((section, table))
    return "; ".join(statements), descriptors


def _query_dictionary_postflight_samples(
    paths: ProjectPaths,
    postflight: dict[str, Any],
    *,
    sections: tuple[str, ...],
    wrangler_bin: Path | None,
    env: Mapping[str, str] | None,
) -> dict[str, dict[str, list[dict[str, Any]]]]:
    samples = postflight.get("samples")
    if not isinstance(samples, dict):
        return {}
    sql, descriptors = _dictionary_postflight_sample_queries(samples, sections)
    if not sql:
        return {section: {} for section in sections}
    configured = load_production_identity(paths.backend_dir / "wrangler.jsonc")
    executor = ProductionExecutor(
        paths=paths,
        wrangler_bin=wrangler_bin or (paths.backend_dir / "node_modules" / ".bin" / "wrangler"),
        env=env,
    )
    results = executor.select(configured["database_name"], sql)
    if not isinstance(results, list) or len(results) != len(descriptors):
        raise ProductionInventoryError("dictionary postflight sample query response is invalid")
    actual: dict[str, dict[str, list[dict[str, Any]]]] = {
        section: {} for section in sections
    }
    for descriptor, result in zip(descriptors, results):
        if not isinstance(result, dict) or not isinstance(result.get("results"), list):
            raise ProductionInventoryError("dictionary postflight sample rows are invalid")
        section, table = descriptor
        actual[section][table] = [
            row for row in result["results"] if isinstance(row, dict)
        ]
    return actual


def _validate_dictionary_postflight_samples(
    paths: ProjectPaths,
    postflight: dict[str, Any],
    *,
    sections: tuple[str, ...],
    wrangler_bin: Path | None,
    env: Mapping[str, str] | None,
) -> str | None:
    samples = postflight.get("samples")
    if not isinstance(samples, dict):
        return None
    actual = _query_dictionary_postflight_samples(
        paths,
        postflight,
        sections=sections,
        wrangler_bin=wrangler_bin,
        env=env,
    )
    mismatches: dict[str, Any] = {}
    for section in sections:
        expected_section = samples.get(section, {})
        actual_section = actual.get(section, {})
        for table in DICTIONARY_POSTFLIGHT_TABLES:
            expected_rows = expected_section.get(table, [])
            actual_rows = actual_section.get(table, [])
            if expected_rows != actual_rows:
                mismatches[f"{section}.{table}"] = {
                    "expected": expected_rows,
                    "actual": actual_rows,
                }
    if mismatches:
        return "dictionary postflight sample mismatch: " + json.dumps(
            mismatches, ensure_ascii=False, sort_keys=True
        )
    return None


def _validate_dictionary_postflight_after(
    postflight: dict[str, Any], inventory: dict[str, Any]
) -> None:
    expected_counts = postflight.get("after_counts")
    if not isinstance(expected_counts, dict):
        raise ProductionInventoryError("dictionary postflight after-counts are missing")
    mismatches = {
        table: {
            "expected": expected_counts.get(table),
            "actual": inventory.get("counts", {}).get(table),
        }
        for table in DICTIONARY_POSTFLIGHT_TABLES
        if inventory.get("counts", {}).get(table) != expected_counts.get(table)
    }
    if mismatches:
        raise ProductionInventoryError(
            "dictionary postflight after-count mismatch: "
            + json.dumps(mismatches, sort_keys=True)
        )


def _validate_dictionary_postflight_artifact(
    paths: ProjectPaths, postflight: dict[str, Any]
) -> Path:
    relative = postflight.get("path")
    expected = postflight.get("sha256")
    if not isinstance(relative, str) or not isinstance(expected, str) or not expected:
        raise ProductionInventoryError("dictionary postflight artifact metadata is invalid")
    artifact_path = _resolve_managed_artifact(paths, relative)
    if _sha256_path(artifact_path) != expected:
        raise ProductionInventoryError("dictionary postflight manifest checksum mismatch")
    return artifact_path


def _resolve_dictionary_artifact(paths: ProjectPaths, relative_path: str) -> Path:
    candidate = (paths.repo_root / relative_path).resolve()
    try:
        candidate.relative_to(paths.dictionary_artifacts_dir.resolve())
    except ValueError as exc:
        raise ProductionInventoryError("dictionary artifact escapes managed artifact directory") from exc
    if not candidate.is_file():
        raise ProductionInventoryError("dictionary artifact manifest is missing")
    return candidate


def _validate_dictionary_artifact(paths: ProjectPaths, manifest_path: Path) -> dict[str, Any]:
    candidate = Path(manifest_path)
    if candidate.is_absolute():
        try:
            candidate.relative_to(paths.repo_root)
        except ValueError as exc:
            raise ProductionInventoryError("dictionary artifact must be inside repository") from exc
    resolved = _resolve_dictionary_artifact(paths, str(candidate))
    try:
        payload = json.loads(resolved.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProductionInventoryError("dictionary artifact manifest is invalid") from exc
    if not isinstance(payload, dict) or not isinstance(payload.get("release_id"), str):
        raise ProductionInventoryError("dictionary artifact manifest requires release_id")
    chunks = payload.get("chunks")
    if not isinstance(chunks, list) or not chunks:
        raise ProductionInventoryError("dictionary artifact manifest requires chunks")
    for chunk in chunks:
        if not isinstance(chunk, dict) or not isinstance(chunk.get("path"), str):
            raise ProductionInventoryError("dictionary artifact chunk descriptor is invalid")
        chunk_path = (resolved.parent / chunk["path"]).resolve()
        try:
            chunk_path.relative_to(paths.dictionary_artifacts_dir.resolve())
        except ValueError as exc:
            raise ProductionInventoryError("dictionary chunk escapes managed artifact directory") from exc
        if not chunk_path.is_file():
            raise ProductionInventoryError("dictionary artifact chunk is missing")
        if chunk.get("sha256") != _sha256_path(chunk_path):
            raise ProductionInventoryError("dictionary artifact chunk checksum mismatch")
    return {"manifest_path": str(resolved.relative_to(paths.repo_root)), "manifest_sha256": _sha256_path(resolved), "release_id": payload["release_id"], "manifest_hash": payload.get("manifest_hash"), "chunks": chunks, "expected_counts": payload.get("expected_counts", {})}


def _extract_bookmark(payload: Any) -> str:
    if isinstance(payload, dict):
        for key in ("bookmark", "current_bookmark", "previous_bookmark"):
            value = payload.get(key)
            if isinstance(value, str) and value.strip():
                return value.strip()
        for value in payload.values():
            try:
                return _extract_bookmark(value)
            except ProductionInventoryError:
                pass
    elif isinstance(payload, list):
        for value in payload:
            try:
                return _extract_bookmark(value)
            except ProductionInventoryError:
                pass
    raise ProductionInventoryError("Time Travel bookmark was not returned")


def _validate_bookmark(bookmark: str) -> None:
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}.*", bookmark) or not re.fullmatch(
        r"[A-Za-z0-9._:-]{8,256}", bookmark
    ):
        raise ProductionInventoryError("invalid or unsupported Time Travel bookmark")


def _current_git_commit(paths: ProjectPaths) -> str:
    try:
        result = run_command(["git", "rev-parse", "HEAD"], cwd=paths.repo_root)
    except CommandError as exc:
        raise ProductionInventoryError("unable to determine current Git commit") from exc
    return result.stdout.strip()


def _sha256_path(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def classify_migration_risk(path: Path) -> str:
    sql = path.read_text(encoding="utf-8").lower()
    if any(token in sql for token in ("drop table", "delete from", "update ", "alter table", "rename to")):
        return "high"
    if any(token in sql for token in ("insert ", "create table", "create index")):
        return "medium"
    return "low"


def load_migration_metadata(path: Path) -> dict[str, Any]:
    metadata_path = path.with_suffix(".meta.json")
    try:
        payload = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ProductionInventoryError(f"high-risk migration metadata missing: {metadata_path}") from exc
    if not isinstance(payload, dict):
        raise ProductionInventoryError(f"migration metadata must be an object: {metadata_path}")
    for key in ("preflight", "postflight"):
        if not isinstance(payload.get(key), list) or not payload[key]:
            raise ProductionInventoryError(f"migration metadata requires non-empty {key}: {metadata_path}")
    if payload.get("reversible") is not True:
        raise ProductionInventoryError(f"migration metadata must declare reversible=true: {metadata_path}")
    return {
        "preflight": [str(item) for item in payload["preflight"]],
        "postflight": [str(item) for item in payload["postflight"]],
        "reversible": True,
    }


def _load_bundle_message_keys(sql_path: Path) -> dict[str, str]:
    sql = sql_path.read_text(encoding="utf-8")
    pattern = re.compile(
        r"INSERT OR IGNORE INTO ui_messages\s*\([^)]*\)\s*VALUES\s*\(\s*'langmap-web'\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'",
        re.IGNORECASE | re.DOTALL,
    )
    return {
        key.replace("''", "'"): source_expression_id.replace("''", "'")
        for key, source_expression_id in pattern.findall(sql)
    }


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
SELECT 'migration' AS kind, name FROM d1_migrations ORDER BY id;
""".strip()


def _build_column_inventory_sql(table_names: list[str]) -> str:
    if not table_names:
        return 'PRAGMA table_info("")'
    statements = []
    for table_name in table_names:
        escaped_name = table_name.replace('"', '""')
        statements.append(f'PRAGMA table_info("{escaped_name}")')
    return "; ".join(statements)


def _annotate_column_rows(table_names: list[str], results: Any) -> list[dict[str, Any]]:
    if not isinstance(results, list) or len(results) != len(table_names):
        raise ProductionInventoryError("wrangler column query response does not match table list")
    rows: list[dict[str, Any]] = []
    for table_name, result in zip(table_names, results):
        if not isinstance(result, dict) or not isinstance(result.get("results"), list):
            raise ProductionInventoryError("wrangler column query response is invalid")
        for column in result["results"]:
            if not isinstance(column, dict):
                continue
            rows.append(
                {
                    "kind": "column",
                    "table_name": table_name,
                    "name": column.get("name"),
                    "column_type": column.get("type"),
                }
            )
    return rows

INVENTORY_COUNTS_SQL = """
SELECT 'sources' AS metric, COUNT(*) AS count FROM sources;
SELECT 'languages' AS metric, COUNT(*) AS count FROM languages;
SELECT 'language_locales' AS metric, COUNT(*) AS count FROM language_locales;
SELECT 'expressions' AS metric, COUNT(*) AS count FROM expressions;
SELECT 'expression_sources' AS metric, COUNT(*) AS count FROM expression_sources;
SELECT 'expression_locale_links' AS metric, COUNT(*) AS count FROM expression_locale_links;
SELECT 'expression_readings' AS metric, COUNT(*) AS count FROM expression_readings;
SELECT 'expression_edges' AS metric, COUNT(*) AS count FROM expression_edges;
SELECT 'expression_edge_sources' AS metric, COUNT(*) AS count FROM expression_edge_sources;
SELECT 'users' AS metric, COUNT(*) AS count FROM users;
SELECT 'handbooks' AS metric, COUNT(*) AS count FROM handbooks;
SELECT 'handbook_sections' AS metric, COUNT(*) AS count FROM handbook_sections;
SELECT 'handbook_section_items' AS metric, COUNT(*) AS count FROM handbook_section_items;
SELECT 'edge_votes' AS metric, COUNT(*) AS count FROM edge_votes;
SELECT 'handbook_votes' AS metric, COUNT(*) AS count FROM handbook_votes;
SELECT 'ui_locales' AS metric, COUNT(*) AS count FROM ui_locales;
SELECT 'ui_messages' AS metric, COUNT(*) AS count FROM ui_messages;
SELECT 'managed_ui_messages' AS metric, COUNT(*) FROM ui_messages WHERE project_id = 'langmap-web';
SELECT 'managed_ui_edges' AS metric, COUNT(DISTINCT edge.id) AS count
FROM ui_messages message
JOIN expression_edges edge
  ON edge.expression_a_id = message.source_expression_id
  OR edge.expression_b_id = message.source_expression_id
JOIN expressions translation
  ON translation.id = CASE
    WHEN edge.expression_a_id = message.source_expression_id THEN edge.expression_b_id
    ELSE edge.expression_a_id
  END
JOIN sources source ON source.id = translation.source_id
JOIN expression_locale_links locale_link ON locale_link.expression_id = translation.id
JOIN ui_locales ui_locale
  ON ui_locale.locale_id = locale_link.locale_id
 AND ui_locale.project_id = 'langmap-web'
 AND ui_locale.status = 'active'
WHERE message.project_id = 'langmap-web'
  AND message.status = 'active'
  AND translation.id <> message.source_expression_id
  AND source.type = 'system'
  AND source.name = 'system-ui';
SELECT 'ui_key' AS kind, message_key AS key, source_expression_id AS source_hash
FROM ui_messages WHERE project_id = 'langmap-web' ORDER BY message_key;
SELECT 'orphan_ui_messages' AS metric, COUNT(*) FROM ui_messages m LEFT JOIN expressions e ON e.id = m.source_expression_id WHERE e.id IS NULL;
SELECT 'orphan_expression_edges' AS metric, COUNT(*) FROM expression_edges x LEFT JOIN expressions a ON a.id = x.expression_a_id LEFT JOIN expressions b ON b.id = x.expression_b_id WHERE a.id IS NULL OR b.id IS NULL;
SELECT 'orphan_handbook_items' AS metric, COUNT(*) FROM handbook_section_items i LEFT JOIN expressions e ON e.id = i.expression_id WHERE e.id IS NULL;
""".strip()
