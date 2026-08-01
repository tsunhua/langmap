from __future__ import annotations

import json
import os
import shutil
import tempfile
from pathlib import Path
from typing import Any, Mapping

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
) -> dict[str, Any]:
    executor = LocalWranglerExecutor(
        paths=paths,
        wrangler_bin=wrangler_bin or (paths.backend_dir / "node_modules" / ".bin" / "wrangler"),
        env=env,
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
        )

        if active_state_dir.exists():
            shutil.rmtree(active_state_dir)
        temp_state_dir.rename(active_state_dir)
        _write_json(
            paths.local_fingerprint_path,
            {
                "fingerprint": desired_fingerprint,
                "updated_at": created_at,
                "lock": lock_payload,
            },
        )
        _write_json(paths.local_verification_report_path, verification_report)
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
) -> dict[str, Any]:
    return verify_local_state(paths, wrangler_bin=wrangler_bin, env=env)


def _write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
