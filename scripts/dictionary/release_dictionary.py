#!/usr/bin/env python3
"""Prepare and optionally apply one managed dictionary data release.

The default command imports selected JSONL files into the persistent mirror,
exports a checksum-locked delta and postflight manifest, and creates a
production plan.  Production mutation requires the explicit ``--apply`` flag
and an exact database-name confirmation.

Example:
  python3 scripts/dictionary/release_dictionary.py \
      --input-dir /Volumes/DATA/langmap-structured-jsonl \
      --d1-database scripts/db/state/backup/publish-mirror.incremental.sqlite \
      --state scripts/db/state/backup/import-state/jyutjyu.json \
      --staging-root /tmp/langmap-dictionary-staging \
      --snapshot-root scripts/db/state/backup/snapshots \
      --release-name 023-jyutjyu-repair
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "scripts" / "dictionary"))
sys.path.insert(0, str(REPO_ROOT / "scripts" / "db"))

from incremental_import import run_incremental_import  # noqa: E402
from export_dictionary_delta import export_delta  # noqa: E402
from lib.paths import ProjectPaths  # noqa: E402
from lib.production import apply_production, plan_production  # noqa: E402


RELEASE_NAME_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=REPO_ROOT)
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--d1-database", required=True, type=Path)
    parser.add_argument("--state", required=True, type=Path)
    parser.add_argument("--staging-root", required=True, type=Path)
    parser.add_argument("--snapshot-root", type=Path)
    parser.add_argument("--release-name", required=True)
    parser.add_argument("--delta-dir", type=Path)
    parser.add_argument("--batch-size", type=int, default=5_000)
    parser.add_argument("--commit-every", type=int, default=50_000)
    parser.add_argument("--limit-files", type=int)
    parser.add_argument(
        "--only",
        dest="only_fragments",
        action="append",
        help="只處理檔名包含此片段的 JSONL；可重複指定",
    )
    parser.add_argument("--no-resume", action="store_true")
    parser.add_argument("--keep-staging", action="store_true")
    parser.add_argument("--stop-on-error", action="store_true")
    parser.add_argument(
        "--split",
        action="store_true",
        help="將 delta 標記為 split，production apply 會按有限大小批次執行",
    )
    parser.add_argument("--refresh-language-statistics", action="store_true")
    parser.add_argument("--wrangler-bin", type=Path)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--database-name")
    parser.add_argument("--confirm-production")
    parser.add_argument("--timeout-seconds", type=float, default=120.0)
    return parser


def _validate_release_name(value: str) -> str:
    if not RELEASE_NAME_RE.fullmatch(value):
        raise ValueError(
            "release-name 只能包含英數字、句點、底線與連字符，且不可由符號開頭"
        )
    return value


def _resolve_path(repo_root: Path, value: Path) -> Path:
    candidate = value.expanduser()
    return candidate.resolve() if candidate.is_absolute() else (repo_root / candidate).resolve()


def _select_only_names(input_dir: Path, fragments: list[str] | None) -> set[str] | None:
    if not fragments:
        return None
    names = {path.name for path in input_dir.glob("*.jsonl") if path.is_file()}
    selected = {name for name in names if any(fragment in name for fragment in fragments)}
    missing = [fragment for fragment in fragments if not any(fragment in name for name in names)]
    if missing:
        raise FileNotFoundError(f"找不到符合 --only 的 JSONL 檔名片段：{', '.join(missing)}")
    return selected


def _relative(repo_root: Path, path: Path) -> Path:
    try:
        return path.resolve().relative_to(repo_root.resolve())
    except ValueError as exc:
        raise ValueError(f"release artifact 必須位於 repository 內：{path}") from exc


def run_release(args: argparse.Namespace) -> dict[str, Any]:
    repo_root = _resolve_path(REPO_ROOT, args.repo_root)
    paths = ProjectPaths.discover(repo_root)
    release_name = _validate_release_name(args.release_name)
    input_dir = _resolve_path(repo_root, args.input_dir)
    d1_database = _resolve_path(repo_root, args.d1_database)
    state_path = _resolve_path(repo_root, args.state)
    staging_root = _resolve_path(repo_root, args.staging_root)
    snapshot_root = (
        _resolve_path(repo_root, args.snapshot_root) if args.snapshot_root else None
    )
    only_names = _select_only_names(input_dir, args.only_fragments)
    results = run_incremental_import(
        input_dir,
        d1_database,
        state_path,
        staging_root,
        snapshot_root=snapshot_root,
        batch_size=args.batch_size,
        commit_every=args.commit_every,
        resume=not args.no_resume,
        keep_staging=args.keep_staging,
        limit_files=args.limit_files,
        only_names=only_names,
        stop_on_error=args.stop_on_error,
    )
    failed = [row for row in results if row.get("status") not in {"success", "skipped"}]
    if failed:
        return {"status": "import_failed", "results": results}
    successful = [row for row in results if row.get("status") == "success"]
    if not successful:
        return {"status": "nothing_to_publish", "results": results}
    snapshot_paths = {str(row.get("before_snapshot_path") or "") for row in successful}
    snapshot_paths.discard("")
    if len(snapshot_paths) != 1:
        raise ValueError("成功的 import 沒有唯一的 before snapshot，停止產生 delta")
    before_snapshot = Path(next(iter(snapshot_paths)))
    if not before_snapshot.is_file():
        raise FileNotFoundError(f"before snapshot 不存在：{before_snapshot}")

    delta_dir = (
        _resolve_path(repo_root, args.delta_dir)
        if args.delta_dir
        else paths.state_dir / "backup" / "delta"
    )
    delta_suffix = ".split.sql" if args.split else ".sql"
    delta_path = delta_dir / f"{release_name}{delta_suffix}"
    manifest_path = delta_dir / f"{release_name}.manifest.json"
    delta_dir.mkdir(parents=True, exist_ok=True)
    counts = export_delta(
        before_snapshot,
        d1_database,
        delta_path,
        manifest=manifest_path,
    )
    wrangler_bin = (
        _resolve_path(repo_root, args.wrangler_bin)
        if args.wrangler_bin
        else paths.backend_dir / "node_modules" / ".bin" / "wrangler"
    )
    plan = plan_production(
        paths,
        wrangler_bin=wrangler_bin,
        env=dict(os.environ),
        approved_data_migration=_relative(repo_root, delta_path),
        dictionary_postflight_manifest=_relative(repo_root, manifest_path),
        refresh_language_statistics=args.refresh_language_statistics,
    )
    summary: dict[str, Any] = {
        "status": "planned" if plan["status"] == "ready" else "blocked",
        "release_name": release_name,
        "import": results,
        "delta": {"path": str(_relative(repo_root, delta_path)), "counts": counts},
        "postflight_manifest": str(_relative(repo_root, manifest_path)),
        "plan_path": str(paths.production_plan_dir / f"{plan['operation_id']}.json"),
        "plan": plan,
    }
    if not args.apply or plan["status"] != "ready":
        return summary
    if not args.database_name or args.confirm_production != args.database_name:
        raise ValueError("--apply 必須同時提供相同的 --database-name 與 --confirm-production")
    applied = apply_production(
        paths,
        plan_path=paths.production_plan_dir / f"{plan['operation_id']}.json",
        database_name=args.database_name,
        confirmation=args.confirm_production,
        wrangler_bin=wrangler_bin,
        env=dict(os.environ),
        timeout_seconds=args.timeout_seconds,
    )
    summary["status"] = applied["status"]
    summary["apply"] = applied
    return summary


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        result = run_release(args)
    except (FileNotFoundError, OSError, RuntimeError, ValueError) as exc:
        print(f"release failed: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0 if result["status"] in {"planned", "succeeded", "nothing_to_publish"} else 1


if __name__ == "__main__":
    raise SystemExit(main())
