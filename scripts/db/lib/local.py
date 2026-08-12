from __future__ import annotations

import json
import os
import shutil
import tempfile
from pathlib import Path
from typing import Any, Mapping
from uuid import uuid4

from lib.fingerprint import compute_bootstrap_fingerprint, default_fingerprint_inputs
from lib.locking import acquire_operation_lock
from lib.paths import ProjectPaths
from lib.verify import LocalVerificationError, LocalWranglerExecutor, verify_local_state, write_migration_baseline


class LocalRebuildError(RuntimeError):
    def __init__(self, message: str, *, temp_state_dir: Path) -> None:
        super().__init__(message)
        self.temp_state_dir = temp_state_dir


def rebuild_local_state(
    paths: ProjectPaths,
    *,
    wrangler_bin: Path | None = None,
    env: Mapping[str, str] | None = None,
    owner: str = "scripts/db/manage.py",
    created_at: str = "2026-08-01T00:00:00Z",
    timeout_seconds: float = 120.0,
) -> dict[str, Any]:
    executor = LocalWranglerExecutor(
        paths=paths,
        wrangler_bin=wrangler_bin or (paths.backend_dir / "node_modules" / ".bin" / "wrangler"),
        env=env,
        timeout_seconds=timeout_seconds,
    )
    desired_fingerprint = compute_bootstrap_fingerprint(default_fingerprint_inputs(paths))
    active_state_dir = paths.ensure_safe_cleanup_target(
        paths.local_d1_state_dir,
        allowed_root=paths.local_d1_state_dir,
        allow_exact_root=True,
    )
    lock_payload = acquire_operation_lock(
        paths.local_rebuild_lock_path,
        operation="local-rebuild",
        owner=owner,
        pid=os.getpid(),
        created_at=created_at,
    )
    temp_state_dir = Path(
        tempfile.mkdtemp(
            prefix="local-d1-rebuild-",
            dir=str(paths.local_d1_state_dir.parent),
        )
    )

    try:
        executor.execute_file(temp_state_dir, paths.schema_path)
        executor.execute_file(temp_state_dir, paths.language_registry_sql_path)
        executor.execute_file(temp_state_dir, paths.system_ui_sql_path)
        write_migration_baseline(paths, executor=executor, persist_to=temp_state_dir)
        verification_report = verify_local_state(
            paths,
            wrangler_bin=executor.wrangler_bin,
            env=env,
            persist_to=temp_state_dir,
            write_report=False,
            timeout_seconds=timeout_seconds,
        )
        metadata_payloads = {
            paths.local_fingerprint_path: {
                "fingerprint": desired_fingerprint,
                "updated_at": created_at,
                "lock": lock_payload,
            },
            paths.local_verification_report_path: verification_report,
        }
        _activate_transactionally(
            active_state_dir=active_state_dir,
            temp_state_dir=temp_state_dir,
            metadata_payloads=metadata_payloads,
        )
        return {
            "status": "rebuilt",
            "fingerprint": desired_fingerprint,
            "verification_report_path": str(paths.local_verification_report_path),
            "state_dir": str(active_state_dir),
        }
    except LocalVerificationError as exc:
        raise LocalRebuildError(str(exc), temp_state_dir=temp_state_dir) from exc
    except Exception as exc:  # pragma: no cover - defensive guard for file-system issues
        raise LocalRebuildError(str(exc), temp_state_dir=temp_state_dir) from exc
    finally:
        if paths.local_rebuild_lock_path.exists():
            paths.local_rebuild_lock_path.unlink()


def verify_local_environment(
    paths: ProjectPaths,
    *,
    wrangler_bin: Path | None = None,
    env: Mapping[str, str] | None = None,
    timeout_seconds: float = 120.0,
) -> dict[str, Any]:
    return verify_local_state(
        paths,
        wrangler_bin=wrangler_bin,
        env=env,
        timeout_seconds=timeout_seconds,
    )


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _activate_transactionally(
    *,
    active_state_dir: Path,
    temp_state_dir: Path,
    metadata_payloads: dict[Path, dict[str, Any]],
) -> None:
    metadata_snapshot = _capture_metadata_snapshot(metadata_payloads.keys())
    metadata_root = next(iter(metadata_payloads)).parent
    metadata_root.mkdir(parents=True, exist_ok=True)
    staged_metadata_dir = Path(
        tempfile.mkdtemp(
            prefix="local-d1-metadata-",
            dir=str(metadata_root),
        )
    )
    staged_metadata = _stage_metadata_files(staged_metadata_dir, metadata_payloads)
    backup_state_dir = active_state_dir.parent / f"state-backup-{uuid4().hex[:8]}"
    active_swapped = False
    backup_exists = False
    try:
        if active_state_dir.exists():
            active_state_dir.rename(backup_state_dir)
            backup_exists = True
        temp_state_dir.rename(active_state_dir)
        active_swapped = True
        _commit_staged_metadata(staged_metadata)
    except Exception:
        _rollback_activation(
            active_state_dir=active_state_dir,
            backup_state_dir=backup_state_dir,
            active_swapped=active_swapped,
            backup_exists=backup_exists,
            metadata_snapshot=metadata_snapshot,
        )
        raise
    finally:
        if staged_metadata_dir.exists():
            shutil.rmtree(staged_metadata_dir, ignore_errors=True)
    if backup_exists and backup_state_dir.exists():
        shutil.rmtree(backup_state_dir, ignore_errors=True)


def _capture_metadata_snapshot(paths: Any) -> dict[Path, bytes | None]:
    snapshot: dict[Path, bytes | None] = {}
    for path in paths:
        snapshot[path] = path.read_bytes() if path.exists() else None
    return snapshot


def _stage_metadata_files(
    staged_dir: Path,
    metadata_payloads: dict[Path, dict[str, Any]],
) -> dict[Path, Path]:
    staged_dir.mkdir(parents=True, exist_ok=True)
    staged_files: dict[Path, Path] = {}
    for final_path, payload in metadata_payloads.items():
        staged_path = staged_dir / final_path.name
        _write_json(staged_path, payload)
        staged_files[final_path] = staged_path
    return staged_files


def _commit_staged_metadata(staged_files: dict[Path, Path]) -> None:
    for final_path, staged_path in staged_files.items():
        final_path.parent.mkdir(parents=True, exist_ok=True)
        _replace_path(staged_path, final_path)


def _rollback_activation(
    *,
    active_state_dir: Path,
    backup_state_dir: Path,
    active_swapped: bool,
    backup_exists: bool,
    metadata_snapshot: dict[Path, bytes | None],
) -> None:
    if active_swapped and active_state_dir.exists():
        shutil.rmtree(active_state_dir, ignore_errors=True)
    if backup_exists and backup_state_dir.exists():
        backup_state_dir.rename(active_state_dir)
    _restore_metadata_snapshot(metadata_snapshot)


def _restore_metadata_snapshot(snapshot: dict[Path, bytes | None]) -> None:
    for path, previous_bytes in snapshot.items():
        if previous_bytes is None:
            if path.exists():
                path.unlink()
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(previous_bytes)


def _replace_path(source: Path, destination: Path) -> None:
    os.replace(source, destination)
