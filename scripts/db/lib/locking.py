from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Callable


class OperationLockError(RuntimeError):
    pass


def acquire_operation_lock(
    lock_path: Path,
    *,
    operation: str,
    owner: str,
    pid: int,
    created_at: str,
) -> dict[str, Any]:
    payload = {
        "operation": operation,
        "owner": owner,
        "pid": pid,
        "created_at": created_at,
    }
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        fd = os.open(str(lock_path), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o644)
    except FileExistsError as exc:
        existing = json.loads(lock_path.read_text(encoding="utf-8"))
        raise OperationLockError(
            "operation lock already exists: "
            f"owner={existing.get('owner')} created_at={existing.get('created_at')}"
        ) from exc

    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    return payload


def unlock_stale_operation_lock(
    lock_path: Path,
    *,
    pid_exists: Callable[[int], bool] | None = None,
) -> dict[str, Any]:
    if not lock_path.exists():
        raise FileNotFoundError(f"operation lock is missing: {lock_path}")

    payload = json.loads(lock_path.read_text(encoding="utf-8"))
    pid = int(payload["pid"])
    checker = pid_exists or _pid_exists
    if checker(pid):
        raise OperationLockError(f"process {pid} is still running; refusing to unlock")

    lock_path.unlink()
    return payload


def _pid_exists(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True
