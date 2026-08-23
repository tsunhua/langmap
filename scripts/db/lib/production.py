from __future__ import annotations

import json
import hashlib
import re
import uuid
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
        "managed_ui_edges": str(ui_manifest["counts"]["translation_count"]),
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
        "approved_data_migration": None,
        "dictionary_artifact": dictionary_artifact,
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
    executor = ProductionExecutor(
        paths=paths,
        wrangler_bin=wrangler_bin or (paths.backend_dir / "node_modules" / ".bin" / "wrangler"),
        env=env,
    )
    operation = {
        "operation_id": str(plan["operation_id"]),
        "status": "started",
        "database": configured,
        "plan_path": str(plan_path),
        "failed_stage": None,
    }
    journal.append_operation(paths.production_operation_journal_path, operation)
    try:
        remote_identity = normalize_remote_identity(executor.info(database_name))
        assert_identity(configured, remote_identity)
        bookmark = _extract_bookmark(executor.bookmark(database_name))
        operation["bookmark"] = bookmark
        journal.append_operation(paths.production_operation_journal_path, {**operation, "status": "bookmarked"})
        if plan.get("pending_migrations"):
            executor.mutate(["d1", "migrations", "apply", database_name, "--remote"])
        dictionary_artifact = plan.get("dictionary_artifact")
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
            journal.append_operation(paths.production_operation_journal_path, {**operation, "status": "dictionary-release-activated", "release_id": release_id})
        approved_data_migration = plan.get("approved_data_migration")
        if approved_data_migration and not dictionary_artifact:
            data_path = _resolve_managed_artifact(paths, str(approved_data_migration))
            executor.mutate(
                ["d1", "execute", database_name, "--remote", "--file", str(data_path)]
            )
        else:
            journal.append_operation(
                paths.production_operation_journal_path,
                {**operation, "status": "data-migration-skipped"},
            )
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
        verified = inventory_production(paths, wrangler_bin=executor.wrangler_bin, env=env)
        if plan.get("pending_migrations"):
            check_target_schema(paths, verified)
        else:
            check_baseline(paths, verified)
        journal.append_operation(
            paths.production_operation_journal_path,
            {**operation, "status": "succeeded", "verified": True},
        )
        return {"status": "succeeded", "bookmark": bookmark, "operation_id": operation["operation_id"]}
    except Exception as exc:
        journal.append_operation(
            paths.production_operation_journal_path,
            {**operation, "status": "failed", "error": str(exc)},
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
                "--remote",
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


def _resolve_managed_artifact(paths: ProjectPaths, relative_path: str) -> Path:
    candidate = (paths.repo_root / relative_path).resolve()
    try:
        candidate.relative_to(paths.repo_root)
    except ValueError as exc:
        raise ProductionInventoryError("approved data migration escapes repository") from exc
    if not candidate.is_file():
        raise ProductionInventoryError("approved data migration artifact is missing")
    return candidate


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
        return "PRAGMA table_info('')"
    statements = []
    for table_name in table_names:
        escaped_name = table_name.replace("'", "''")
        statements.append(f"PRAGMA table_info('{escaped_name}')")
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
SELECT 'languages' AS metric, COUNT(*) AS count FROM languages;
SELECT 'language_locales' AS metric, COUNT(*) AS count FROM language_locales;
SELECT 'expressions' AS metric, COUNT(*) AS count FROM expressions;
SELECT 'expression_edges' AS metric, COUNT(*) AS count FROM expression_edges;
SELECT 'users' AS metric, COUNT(*) AS count FROM users;
SELECT 'handbooks' AS metric, COUNT(*) AS count FROM handbooks;
SELECT 'handbook_sections' AS metric, COUNT(*) AS count FROM handbook_sections;
SELECT 'handbook_section_items' AS metric, COUNT(*) AS count FROM handbook_section_items;
SELECT 'votes' AS metric, COUNT(*) AS count FROM votes;
SELECT 'ui_locales' AS metric, COUNT(*) AS count FROM ui_locales;
SELECT 'ui_messages' AS metric, COUNT(*) AS count FROM ui_messages;
SELECT 'managed_ui_messages' AS metric, COUNT(*) FROM ui_messages WHERE project_id = 'langmap-web';
SELECT 'managed_ui_edges' AS metric, COUNT(*) AS count FROM expression_edges WHERE id LIKE 'ui-edge:%';
SELECT 'ui_key' AS kind, message_key AS key, source_expression_id AS source_hash
FROM ui_messages WHERE project_id = 'langmap-web' ORDER BY message_key;
SELECT 'orphan_ui_messages' AS metric, COUNT(*) FROM ui_messages m LEFT JOIN expressions e ON e.id = m.source_expression_id WHERE e.id IS NULL;
SELECT 'orphan_expression_edges' AS metric, COUNT(*) FROM expression_edges x LEFT JOIN expressions a ON a.id = x.expression_a_id LEFT JOIN expressions b ON b.id = x.expression_b_id WHERE a.id IS NULL OR b.id IS NULL;
SELECT 'orphan_handbook_items' AS metric, COUNT(*) FROM handbook_section_items i LEFT JOIN expressions e ON e.id = i.expression_id WHERE e.id IS NULL;
""".strip()
