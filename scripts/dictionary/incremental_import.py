#!/usr/bin/env python3
"""Import Structured JSONL files into the local packed catalog one at a time."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sqlite3
import sys
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable

from langmap_dictionary.adapters.traditional_chinese_english import normalize_release
from langmap_dictionary.clusters import build_explicit_clusters
from langmap_dictionary.loader import load_jsonl_release
from langmap_dictionary.local_import import import_release_to_local_d1
from langmap_dictionary.quality import ReadingQualityError, assert_reading_quality
from langmap_dictionary.schema import create_staging_database


STATE_VERSION = 1
ProgressCallback = Callable[[dict[str, Any]], None]


@dataclass(frozen=True)
class StagingPreparation:
    release_id: str
    input_records: int
    normalized_entries: int
    clusters: int
    phase_seconds: dict[str, float]


def order_jsonl_files(input_dir: Path) -> list[Path]:
    """Return JSONL inputs in deterministic small-first order."""

    return sorted(
        (path for path in Path(input_dir).glob("*.jsonl") if path.is_file()),
        key=lambda path: (path.stat().st_size, path.name),
    )


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def create_sqlite_snapshot(source: Path, destination: Path) -> str:
    """Create a consistent SQLite backup without copying live WAL sidecars."""

    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_name(f".{destination.name}.{time.time_ns()}.tmp")
    try:
        with sqlite3.connect(source, timeout=60) as source_db:
            with sqlite3.connect(temporary) as snapshot_db:
                source_db.backup(snapshot_db)
        temporary.replace(destination)
    finally:
        if temporary.exists():
            temporary.unlink()
    return file_sha256(destination)


def _snapshot_run_key(files: list[tuple[Path, int, str]]) -> str:
    payload = [
        {"name": source.name, "bytes": size, "sha256": digest}
        for source, size, digest in files
    ]
    return hashlib.sha256(
        json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()


def _ensure_before_snapshot(
    state: dict[str, Any],
    state_path: Path,
    snapshot_root: Path,
    run_key: str,
    d1_database: Path,
) -> dict[str, str]:
    snapshots = state.setdefault("before_snapshots", {})
    if not isinstance(snapshots, dict):
        raise ValueError("incremental state before_snapshots must be an object")
    existing = snapshots.get(run_key)
    if isinstance(existing, dict):
        existing_path = Path(str(existing.get("path", "")))
        existing_sha256 = str(existing.get("sha256", ""))
        if (
            existing_path.is_file()
            and existing_sha256
            and file_sha256(existing_path) == existing_sha256
        ):
            return {"path": str(existing_path), "sha256": existing_sha256}
        raise ValueError(f"recorded before snapshot is missing or changed: {existing_path}")

    destination = snapshot_root / (
        f"before-{run_key[:16]}-{time.time_ns()}.sqlite"
    )
    sha256 = create_sqlite_snapshot(d1_database, destination)
    metadata = {"path": str(destination), "sha256": sha256}
    snapshots[run_key] = metadata
    _write_state(state_path, state)
    return metadata


def _load_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"version": STATE_VERSION, "files": {}}
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict) or payload.get("version") != STATE_VERSION:
        raise ValueError(f"unsupported incremental state: {path}")
    files = payload.get("files")
    if not isinstance(files, dict):
        raise ValueError(f"incremental state files must be an object: {path}")
    return payload


def _write_state(path: Path, state: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.{time.time_ns()}.tmp")
    temporary.write_text(
        json.dumps(state, ensure_ascii=False, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def _d1_catalog_snapshot(path: Path) -> dict[str, int]:
    connection = sqlite3.connect(path, timeout=60)
    try:
        values = connection.execute(
            "SELECT "
            "(SELECT COUNT(*) FROM languages),"
            "(SELECT COUNT(*) FROM language_locales),"
            "(SELECT COUNT(*) FROM expressions),"
            "(SELECT COUNT(*) FROM expression_edges),"
            "(SELECT COUNT(*) FROM expression_readings),"
            "(SELECT COUNT(*) FROM sources)"
        ).fetchone()
        return {
            "languages": int(values[0]),
            "locales": int(values[1]),
            "terms": int(values[2]),
            "edges": int(values[3]),
            "readings": int(values[4]),
            "sources": int(values[5]),
        }
    finally:
        connection.close()


def _d1_has_release(path: Path, release_id: str) -> bool:
    if not release_id or not path.is_file():
        return False
    connection = sqlite3.connect(path, timeout=60)
    try:
        return connection.execute(
            "SELECT 1 FROM sources WHERE type='publication' LIMIT 1"
        ).fetchone() is not None
    finally:
        connection.close()


def _d1_bytes(path: Path) -> int:
    return sum(
        candidate.stat().st_size
        for candidate in (
            path,
            path.with_name(path.name + "-wal"),
            path.with_name(path.name + "-shm"),
        )
        if candidate.exists()
    )


def _prepare_staging(
    source: Path,
    staging_path: Path,
    *,
    batch_size: int,
    commit_every: int,
    progress: ProgressCallback | None = None,
) -> StagingPreparation:
    phase_seconds: dict[str, float] = {}

    def phase_callback(phase: str, started: float):
        def emit(event: dict[str, Any]) -> None:
            if progress is None:
                return
            payload = dict(event)
            payload["step"] = str(payload.get("step") or payload.get("phase") or phase)
            payload["phase"] = phase
            payload["elapsed_seconds"] = round(time.perf_counter() - started, 3)
            progress(payload)
        return emit

    stage_started = time.perf_counter()
    if progress is not None:
        progress({"phase": "stage", "step": "start", "processed": 0, "elapsed_seconds": 0.0})
    staging = create_staging_database(staging_path, fast=True)
    try:
        loaded = load_jsonl_release(
            staging,
            [source],
            batch_size=batch_size,
            compact=True,
            progress=phase_callback("stage", stage_started),
        )
    finally:
        staging.close()
    phase_seconds["stage"] = round(time.perf_counter() - stage_started, 3)

    normalize_started = time.perf_counter()
    if progress is not None:
        progress({"phase": "normalize", "step": "start", "processed": 0, "elapsed_seconds": 0.0})
    staging = create_staging_database(staging_path, fast=True)
    try:
        normalize_timings: dict[str, float] = {}
        normalized = normalize_release(
            staging,
            loaded.release_id,
            batch_size=batch_size,
            commit_every=commit_every,
            progress=phase_callback("normalize", normalize_started),
            defer_foreign_keys=True,
            timings=normalize_timings,
        )
        assert_reading_quality(staging, loaded.release_id)
        phase_seconds["normalize"] = round(time.perf_counter() - normalize_started, 3)
        phase_seconds.update(normalize_timings)
        cluster_started = time.perf_counter()
        if progress is not None:
            progress({"phase": "cluster", "step": "start", "processed": 0, "elapsed_seconds": 0.0})
        cluster_timings: dict[str, float] = {}
        clusters = build_explicit_clusters(
            staging,
            loaded.release_id,
            progress=phase_callback("cluster", cluster_started),
            defer_foreign_keys=True,
            timings=cluster_timings,
        )
        phase_seconds["cluster"] = round(time.perf_counter() - cluster_started, 3)
        phase_seconds.update(cluster_timings)
    finally:
        staging.close()
    return StagingPreparation(
        loaded.release_id,
        loaded.input_records,
        normalized,
        clusters.clusters,
        phase_seconds,
    )


def run_incremental_import(
    input_dir: Path,
    d1_database: Path,
    state_path: Path,
    staging_root: Path,
    *,
    snapshot_root: Path | None = None,
    batch_size: int = 5_000,
    commit_every: int = 50_000,
    resume: bool = True,
    keep_staging: bool = False,
    limit_files: int | None = None,
    only_names: set[str] | None = None,
    stop_on_error: bool = False,
    progress: ProgressCallback | None = None,
) -> list[dict[str, Any]]:
    """Run independent stage/normalize/import transactions in small-first order."""

    if batch_size < 1 or commit_every < 1:
        raise ValueError("batch_size and commit_every must be positive")
    input_dir = Path(input_dir).resolve()
    d1_database = Path(d1_database).resolve()
    state_path = Path(state_path).resolve()
    staging_root = Path(staging_root).resolve()
    snapshot_root = Path(snapshot_root or state_path.parent / "snapshots").resolve()
    if not input_dir.is_dir():
        raise NotADirectoryError(input_dir)
    if not d1_database.is_file():
        raise FileNotFoundError(d1_database)
    staging_root.mkdir(parents=True, exist_ok=True)

    files = order_jsonl_files(input_dir)
    if only_names is not None:
        files = [path for path in files if path.name in only_names]
    if limit_files is not None:
        if limit_files < 1:
            raise ValueError("limit_files must be positive")
        files = files[:limit_files]
    file_details = [
        (source, source.stat().st_size, file_sha256(source)) for source in files
    ]
    run_key = _snapshot_run_key(file_details)
    state = _load_state(state_path)
    results: list[dict[str, Any]] = []

    for ordinal, (source, source_size, digest) in enumerate(file_details, 1):
        previous = state["files"].get(source.name)
        if (
            resume
            and isinstance(previous, dict)
            and previous.get("status") == "success"
            and previous.get("sha256") == digest
            and _d1_has_release(d1_database, str(previous.get("release_id") or ""))
        ):
            skipped = {
                "file": source.name,
                "ordinal": ordinal,
                "bytes": source_size,
                "sha256": digest,
                "status": "skipped",
                "release_id": previous.get("release_id"),
                "reason": "already_imported",
            }
            for key in (
                "before_snapshot_path",
                "before_snapshot_sha256",
                "snapshot_run_key",
            ):
                if previous.get(key):
                    skipped[key] = previous[key]
            results.append(skipped)
            print(json.dumps(skipped, ensure_ascii=False, sort_keys=True), flush=True)
            continue

        started = time.perf_counter()
        staging_dir = Path(tempfile.mkdtemp(prefix="langmap-file-", dir=staging_root))
        staging_path = staging_dir / "staging.sqlite"
        row: dict[str, Any] = {
            "file": source.name,
            "ordinal": ordinal,
            "bytes": source_size,
            "sha256": digest,
            "status": "failed",
            "staging_path": str(staging_path),
        }
        try:
            prepared = _prepare_staging(
                source,
                staging_path,
                batch_size=batch_size,
                commit_every=commit_every,
                progress=progress,
            )
            snapshot = _ensure_before_snapshot(
                state,
                state_path,
                snapshot_root,
                run_key,
                d1_database,
            )
            row.update(
                {
                    "status": "snapshot_created",
                    "release_id": prepared.release_id,
                    "before_snapshot_path": snapshot["path"],
                    "before_snapshot_sha256": snapshot["sha256"],
                    "snapshot_run_key": run_key,
                }
            )
            state["files"][source.name] = row
            _write_state(state_path, state)
            before = _d1_catalog_snapshot(d1_database)
            append = before["languages"] > 0 or before["terms"] > 0
            summary = import_release_to_local_d1(
                staging_path,
                d1_database,
                prepared.release_id,
                packed=True,
                append=append,
                progress=progress,
            )
            after = _d1_catalog_snapshot(d1_database)
            elapsed = time.perf_counter() - started
            row.update(
                {
                    "status": "success",
                    "release_id": prepared.release_id,
                    "input_records": prepared.input_records,
                    "normalized_entries": prepared.normalized_entries,
                    "clusters": prepared.clusters,
                    "expressions": summary.expressions,
                    "bindings": summary.bindings,
                    "edges": summary.edges,
                    "readings": summary.readings,
                    "pos_attestations": summary.pos_attestations,
                    "seconds": round(elapsed, 3),
                    "entries_per_second": round(prepared.input_records / elapsed, 2) if elapsed else 0,
                    "mb_per_second": round(source_size / elapsed / 1024 / 1024, 3) if elapsed else 0,
                    "d1_before": before,
                    "d1_after": after,
                    "d1_bytes": _d1_bytes(d1_database),
                    "phase_seconds": {
                        **prepared.phase_seconds,
                        **summary.phase_seconds,
                        "total": round(elapsed, 3),
                    },
                    "staging_path": str(staging_path) if keep_staging else None,
                }
            )
            state["files"][source.name] = row
            _write_state(state_path, state)
            results.append(row)
            print(json.dumps(row, ensure_ascii=False, sort_keys=True), flush=True)
            if not keep_staging:
                shutil.rmtree(staging_dir, ignore_errors=True)
        except Exception as error:
            row.update(
                {
                    "seconds": round(time.perf_counter() - started, 3),
                    "error": f"{type(error).__name__}: {error}",
                    "staging_path": str(staging_path),
                }
            )
            state["files"][source.name] = row
            _write_state(state_path, state)
            results.append(row)
            print(json.dumps(row, ensure_ascii=False, sort_keys=True), flush=True)
            if stop_on_error:
                raise
    return results


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--d1-database", required=True, type=Path)
    parser.add_argument("--state", required=True, type=Path)
    parser.add_argument("--staging-root", required=True, type=Path)
    parser.add_argument(
        "--snapshot-root",
        type=Path,
        help="directory for immutable pre-import SQLite snapshots; defaults beside --state",
    )
    parser.add_argument("--batch-size", type=int, default=5_000)
    parser.add_argument("--commit-every", type=int, default=50_000)
    parser.add_argument("--no-resume", action="store_true")
    parser.add_argument("--keep-staging", action="store_true")
    parser.add_argument("--limit-files", type=int)
    parser.add_argument("--only", dest="only_names", action="append", type=str,
                        help="process only JSONL files whose name contains this substring (repeatable)")
    parser.add_argument("--stop-on-error", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    only_names: set[str] | None = None
    if args.only_names:
        all_names = {path.name for path in Path(args.input_dir).glob("*.jsonl")}
        only_names = {name for name in all_names if any(fragment in name for fragment in args.only_names)}
        missing = set(args.only_names) - {name for name in only_names for fragment in args.only_names if fragment in name}
        if missing:
            print(f"警告：沒有檔名含 {sorted(missing)} 的 JSONL", file=sys.stderr)
    rows = run_incremental_import(
        args.input_dir,
        args.d1_database,
        args.state,
        args.staging_root,
        snapshot_root=args.snapshot_root,
        batch_size=args.batch_size,
        commit_every=args.commit_every,
        resume=not args.no_resume,
        keep_staging=args.keep_staging,
        limit_files=args.limit_files,
        only_names=only_names,
        stop_on_error=args.stop_on_error,
    )
    return 0 if all(row.get("status") in {"success", "skipped"} for row in rows) else 1


if __name__ == "__main__":
    raise SystemExit(main())
