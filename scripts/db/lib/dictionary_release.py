"""Managed dictionary release executor shared by local and production flows."""

from __future__ import annotations

import hashlib
import json
import os
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

try:
    from scripts.db.lib.runner import CommandError, run_command
except ModuleNotFoundError:
    try:
        from .runner import CommandError, run_command
    except ImportError:  # direct execution from scripts/db
        from lib.runner import CommandError, run_command


class DictionaryReleaseError(RuntimeError):
    pass


@dataclass(frozen=True)
class ReleasePaths:
    repo_root: Path
    state_dir: Path

    @property
    def checkpoint_root(self) -> Path:
        return self.state_dir / "dictionary"


@dataclass(frozen=True)
class ApplyResult:
    release_id: str
    completed_chunks: int
    total_chunks: int
    resumed: bool
    status: str

    def to_dict(self) -> dict[str, Any]:
        return {"release_id": self.release_id, "completed_chunks": self.completed_chunks, "total_chunks": self.total_chunks, "resumed": self.resumed, "status": self.status}


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _load_manifest(manifest_path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise DictionaryReleaseError("release manifest is missing or invalid") from exc
    if not isinstance(payload, dict) or not isinstance(payload.get("release_id"), str) or not isinstance(payload.get("chunks"), list) or not payload["chunks"]:
        raise DictionaryReleaseError("release manifest requires release_id and chunks")
    return payload


def _validate_manifest(manifest_path: Path, payload: dict[str, Any]) -> list[tuple[Path, str]]:
    root = manifest_path.parent.resolve()
    chunks: list[tuple[Path, str]] = []
    for descriptor in payload["chunks"]:
        if not isinstance(descriptor, dict):
            raise DictionaryReleaseError("invalid chunk descriptor")
        relative = descriptor.get("path")
        digest = descriptor.get("sha256")
        if not isinstance(relative, str) or Path(relative).is_absolute() or ".." in Path(relative).parts or not isinstance(digest, str):
            raise DictionaryReleaseError("chunk path must be relative and contained")
        path = (root / relative).resolve()
        try:
            path.relative_to(root)
        except ValueError as exc:
            raise DictionaryReleaseError("chunk escapes artifact root") from exc
        if not path.is_file() or _sha256(path) != digest:
            raise DictionaryReleaseError(f"chunk checksum mismatch: {relative}")
        chunks.append((path, digest))
    return chunks


def _atomic_json(path: Path, payload: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=str(path.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(dict(payload), handle, ensure_ascii=False, sort_keys=True, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_name, path)
    except Exception:
        try:
            os.unlink(temporary_name)
        except OSError:
            pass
        raise


def _checkpoint(paths: ReleasePaths, release_id: str) -> Path:
    return paths.checkpoint_root / release_id / "checkpoint.json"


def _run_chunk(*, wrangler_bin: Path, database_name: str, chunk: Path, remote: bool, cwd: Path, env: Mapping[str, str] | None) -> None:
    args = [str(wrangler_bin), "d1", "execute", database_name]
    args.append("--remote" if remote else "--local")
    args.extend(["--file", str(chunk)])
    try:
        run_command(args, cwd=cwd, env=env, timeout=300)
    except CommandError as exc:
        raise DictionaryReleaseError(str(exc)) from exc


def _run_command(*, wrangler_bin: Path, database_name: str, sql: str, remote: bool, cwd: Path, env: Mapping[str, str] | None) -> None:
    args = [str(wrangler_bin), "d1", "execute", database_name]
    args.append("--remote" if remote else "--local")
    args.extend(["--command", sql])
    try:
        run_command(args, cwd=cwd, env=env, timeout=300)
    except CommandError as exc:
        raise DictionaryReleaseError(str(exc)) from exc


def apply_release(paths: ReleasePaths, manifest_path: Path, *, environment: str = "local", database_name: str = "DB", wrangler_bin: Path | None = None, env: Mapping[str, str] | None = None) -> ApplyResult:
    if environment not in {"local", "production"}:
        raise ValueError("environment must be local or production")
    manifest_path = Path(manifest_path).resolve()
    payload = _load_manifest(manifest_path)
    chunks = _validate_manifest(manifest_path, payload)
    checkpoint_path = _checkpoint(paths, str(payload["release_id"]))
    checkpoint: dict[str, Any] = {}
    if checkpoint_path.exists():
        try:
            checkpoint = json.loads(checkpoint_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise DictionaryReleaseError("release checkpoint is invalid") from exc
    completed = int(checkpoint.get("completed_chunks", 0))
    if completed < 0 or completed > len(chunks):
        raise DictionaryReleaseError("release checkpoint chunk count is invalid")
    previous_hashes = checkpoint.get("chunk_hashes", [])
    if previous_hashes and previous_hashes != [digest for _, digest in chunks[:completed]]:
        raise DictionaryReleaseError("release checkpoint does not match artifact")
    binary = wrangler_bin or (paths.repo_root / "backend" / "node_modules" / ".bin" / "wrangler")
    remote = environment == "production"
    for index in range(completed, len(chunks)):
        path, digest = chunks[index]
        _run_chunk(wrangler_bin=binary, database_name=database_name, chunk=path, remote=remote, cwd=paths.repo_root / "backend", env=env)
        completed = index + 1
        _atomic_json(checkpoint_path, {"release_id": payload["release_id"], "manifest_hash": payload.get("manifest_hash"), "completed_chunks": completed, "chunk_hashes": [item_digest for _, item_digest in chunks[:completed]]})
    return ApplyResult(str(payload["release_id"]), completed, len(chunks), bool(checkpoint), "validated")


def verify_release(paths: ReleasePaths, manifest_path: Path, *, environment: str = "local", database_name: str = "DB", wrangler_bin: Path | None = None, env: Mapping[str, str] | None = None) -> dict[str, Any]:
    payload = _load_manifest(Path(manifest_path).resolve())
    chunks = _validate_manifest(Path(manifest_path).resolve(), payload)
    checkpoint_path = _checkpoint(paths, str(payload["release_id"]))
    completed = 0
    if checkpoint_path.exists():
        completed = int(json.loads(checkpoint_path.read_text(encoding="utf-8")).get("completed_chunks", 0))
    return {"status": "ok" if completed == len(chunks) else "incomplete", "release_id": payload["release_id"], "completed_chunks": completed, "total_chunks": len(chunks), "manifest_hash": payload.get("manifest_hash")}


def activate_release(paths: ReleasePaths, release_id: str, *, environment: str = "local", database_name: str = "DB", wrangler_bin: Path | None = None, env: Mapping[str, str] | None = None) -> dict[str, Any]:
    escaped = release_id.replace("'", "''")
    sql = "BEGIN; INSERT OR IGNORE INTO dictionary_dataset_state(dataset_key, active_release_id) VALUES ('managed-dictionaries', NULL); UPDATE dictionary_dataset_state SET active_release_id='{}', updated_at=CURRENT_TIMESTAMP WHERE dataset_key='managed-dictionaries'; UPDATE dictionary_dataset_releases SET activated_at=COALESCE(activated_at,CURRENT_TIMESTAMP) WHERE id='{}' AND status='validated'; COMMIT;".format(escaped, escaped)
    binary = wrangler_bin or (paths.repo_root / "backend" / "node_modules" / ".bin" / "wrangler")
    _run_command(wrangler_bin=binary, database_name=database_name, sql=sql, remote=environment == "production", cwd=paths.repo_root / "backend", env=env)
    return {"status": "activated", "release_id": release_id}


def rollback_release(paths: ReleasePaths, release_id: str, parent_release_id: str | None, *, environment: str = "local", database_name: str = "DB", wrangler_bin: Path | None = None, env: Mapping[str, str] | None = None) -> dict[str, Any]:
    if parent_release_id is None:
        raise DictionaryReleaseError("rollback requires a parent release")
    return activate_release(paths, parent_release_id, environment=environment, database_name=database_name, wrangler_bin=wrangler_bin, env=env) | {"rolled_back_from": release_id}
