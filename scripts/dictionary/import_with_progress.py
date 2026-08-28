#!/usr/bin/env python3
"""進度式詞典匯入器：逐檔顯示狀態與進度，支援指定檔案重匯。

用法：
  ./scripts/dictionary/import_with_progress.py --list            # 列出全部檔與狀態
  ./scripts/dictionary/import_with_progress.py --next            # 匯入下一部未匯入的檔
  ./scripts/dictionary/import_with_progress.py --all             # 匯入所有未匯入/失敗的檔
  ./scripts/dictionary/import_with_progress.py --only Turkish    # 只處理檔名含 Turkish 的檔（含已匯入者，依 sha 判斷）
  ./scripts/dictionary/import_with_progress.py --force Turkish   # 強制重匯 Turkish（忽略 state，先清記錄）
  ./scripts/dictionary/import_with_progress.py --only Turkish --limit 2

說明：
  - resume 依 /Volumes/DATA/langmap-incremental-state.json 的 sha 判斷。
  - --force 會先清除該檔在 state 內的記錄，強制走完整 stage/normalize/import。
  - 匯入是 merge 式（INSERT OR IGNORE）；若需「移除舊資料再重匯」，先手動清 D1 再跑。
  - 0 位元組空檔視為 "empty" 並跳過（--list 顯示狀態，--next/--all 不排入）；
    --force/--only 會列出但迴圈內明確提示後跳過。檔案補齊內容後會自動回到待處理清單。
  - staging 根目錄不存在時會自動建立（mkdir -p）。
"""

from __future__ import annotations

import argparse
import os
import shutil
import sqlite3
import sys
import tempfile
import time
from pathlib import Path
from typing import Any, Callable

sys.path.insert(0, str(Path(__file__).resolve().parent))

from langmap_dictionary.local_import import import_release_to_local_d1

import incremental_import as inc

STATE_VERSION = 1
INPUT_DIR = Path("/Volumes/DATA/langmap-structured-jsonl")
STATE_PATH = Path("/Volumes/DATA/langmap-incremental-state.json")
STAGING_ROOT = Path("/Volumes/DATA/langmap-staging-parts")


def default_d1() -> Path:
    root = Path(__file__).resolve().parents[2]  # langmap/
    matches = sorted((root / "backend/.wrangler/state").rglob("*.sqlite"))
    for candidate in matches:
        if candidate.name != "metadata.sqlite" and "/d1/" in str(candidate):
            return candidate
    raise SystemExit("找不到本地 D1（backend/.wrangler/state/v3/d1/...）")


def human(n: int) -> str:
    if n >= 10 ** 6:
        return f"{n / 10 ** 6:.1f}M"
    if n >= 10 ** 3:
        return f"{n / 10 ** 3:.0f}K"
    return str(n)


def status_of(record: dict | None, path: Path) -> str:
    if path.stat().st_size == 0:
        return "empty"
    if not isinstance(record, dict):
        return "pending"
    digest = inc.file_sha256(path)
    if record.get("status") == "success" and record.get("sha256") == digest:
        return "up-to-date"
    if record.get("status") == "success":
        return "stale"
    if record.get("status") == "empty":
        return "pending"
    return str(record.get("status", "pending"))


def list_files() -> list[Path]:
    return inc.order_jsonl_files(INPUT_DIR)


def force_reset(state: dict, fragments: list[str]) -> None:
    for path in list_files():
        if any(f in path.name for f in fragments):
            if path.name in state["files"]:
                del state["files"][path.name]
                print(f"  已清除 {path.name} 的 state 記錄（準備強制重匯）")


def d1_counts(d1: Path) -> dict[str, int]:
    connection = sqlite3.connect(d1, timeout=60)
    try:
        values = connection.execute(
            "SELECT (SELECT COUNT(*) FROM expressions),(SELECT COUNT(*) FROM expression_edges),"
            "(SELECT COUNT(*) FROM expressions WHERE source_id IN "
            "(SELECT id FROM sources WHERE type='publication'))"
        ).fetchone()
        return {"terms": int(values[0]), "edges": int(values[1]), "dict_terms": int(values[2])}
    finally:
        connection.close()


ProgressCallback = Callable[[dict[str, Any]], None]


def prepare_and_import(
    path: Path,
    d1: Path,
    batch: int,
    commit: int,
    keep: bool,
    *,
    progress: ProgressCallback | None = None,
) -> dict:
    """One-file stage/normalize/import; return a summary dict."""
    digest = inc.file_sha256(path)
    started = time.perf_counter()
    staging_dir = Path(tempfile.mkdtemp(prefix="langmap-file-", dir=STAGING_ROOT))
    staging_path = staging_dir / "staging.sqlite"
    try:
        prepared = inc._prepare_staging(
            path,
            staging_path,
            batch_size=batch,
            commit_every=commit,
            progress=progress,
        )
    except Exception:
        if not keep:
            shutil.rmtree(staging_dir, ignore_errors=True)
        raise
    try:
        summary = import_release_to_local_d1(
            staging_path,
            d1,
            prepared.release_id,
            packed=True,
            append=True,
            progress=progress,
        )
    finally:
        if not keep:
            shutil.rmtree(staging_dir, ignore_errors=True)
    return {
        "release_id": prepared.release_id,
        "input_records": prepared.input_records,
        "normalized": prepared.normalized_entries,
        "clusters": prepared.clusters,
        "expressions": summary.expressions,
        "edges": summary.edges,
        "seconds": round(time.perf_counter() - started, 1),
        "sha256": digest,
        "phase_seconds": {
            **prepared.phase_seconds,
            **summary.phase_seconds,
            "total": round(time.perf_counter() - started, 3),
        },
    }


def print_progress(event: dict[str, Any]) -> None:
    phase = str(event.get("phase", "unknown"))
    step = str(event.get("step", "progress"))
    processed = event.get(
        "processed",
        event.get("processed_entries", event.get("input_records", event.get("files", 0))),
    )
    total = event.get("total")
    counter = f"{processed}/{total}" if total is not None else str(processed)
    elapsed = float(event.get("elapsed_seconds", 0.0))
    timings = event.get("timings")
    detail = ""
    if isinstance(timings, dict):
        labels = (
            ("normalize_staging_read", "read"),
            ("normalize_compute", "compute"),
            ("normalize_sqlite_flush", "flush"),
            ("normalize_checkpoint_commit", "commit"),
            ("normalize_foreign_key_check", "fk"),
            ("cluster_cleanup", "cleanup"),
            ("cluster_clusters_insert", "clusters"),
            ("cluster_members_insert", "members"),
            ("cluster_foreign_key_check", "fk"),
            ("cluster_index", "index"),
            ("cluster_commit", "commit"),
        )
        values = [f"{label}={float(timings[key]):.1f}s" for key, label in labels if key in timings]
        if values:
            detail = "；" + " ".join(values)
    print(f"    [{phase}/{step}] {counter}（{elapsed:.1f}s{detail}）", flush=True)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    actions = parser.add_mutually_exclusive_group()
    actions.add_argument("--list", action="store_true", help="列出全部 JSONL 與狀態，不匯入")
    actions.add_argument("--next", action="store_true", help="只處理下一部未匯入的檔")
    actions.add_argument("--all", action="store_true", help="處理所有未匯入/失敗/stale 的檔")
    actions.add_argument("--only", action="append", type=str, metavar="FRAG",
                         help="只處理檔名含 FRAG 的 JSONL（可重複）")
    actions.add_argument("--force", action="append", type=str, metavar="FRAG",
                         help="強制重匯檔名含 FRAG 者（先清 state 記錄）")
    parser.add_argument("--limit", type=int, default=None, metavar="N", help="最多處理 N 檔")
    parser.add_argument("--batch-size", type=int, default=int(os.environ.get("LANGMAP_IMPORT_BATCH", "5000")))
    parser.add_argument("--commit-every", type=int, default=int(os.environ.get("LANGMAP_IMPORT_COMMIT", "50000")))
    parser.add_argument("--keep-staging", action="store_true")
    parser.add_argument("--d1", type=Path, default=None)
    args = parser.parse_args(argv)
    read_only = args.list or not any((args.next, args.all, args.only, args.force))

    STAGING_ROOT.mkdir(parents=True, exist_ok=True)
    d1 = args.d1 or default_d1()
    state = inc._load_state(STATE_PATH)
    files = list_files()
    if state["files"]:
        print("檢查既有匯入記錄與檔案 SHA-256…", flush=True)
    statuses: dict[Path, str] = {}

    def current_status(path: Path) -> str:
        if path not in statuses:
            statuses[path] = status_of(state["files"].get(path.name), path)
        return statuses[path]

    # Resolve the working set.
    working: list[Path] = []
    if args.force:
        force_reset(state, args.force)
        inc._write_state(STATE_PATH, state)
        fragments = [f for f in (args.force or []) if f]
        for path in files:
            if any(f in path.name for f in fragments):
                working.append(path)
        if not working:
            print("警告：--force 沒有對應到任何 JSONL")
    elif args.only:
        fragments = args.only
        for path in files:
            if any(f in path.name for f in fragments):
                working.append(path)
    elif args.next:
        for path in files:
            if current_status(path) not in ("up-to-date", "empty"):
                working = [path]
                break
    else:  # --all or read-only status listing
        for path in files:
            if current_status(path) not in ("up-to-date", "empty"):
                working.append(path)
                if args.limit is not None and len(working) >= args.limit:
                    break

    if args.limit is not None:
        working = working[: args.limit]

    # Print plan.
    print(f"D1: {d1}")
    print(f"待處理 {len(working)} 檔 / 總共 {len(files)} 檔：")
    for i, path in enumerate(working, 1):
        st = current_status(path)
        size = human(path.stat().st_size)
        print(f"  [{i:>2}/{len(working):>2}] {size:>6}  {st:<10} {path.name}")
    if not working:
        print("沒有需要處理的檔案（全部 up-to-date）。")
        return 0
    if read_only:
        print("\n（只列出狀態；使用 --next、--all、--only 或 --force 才會匯入）")
        return 0

    print()
    failures = []
    for i, path in enumerate(working, 1):
        if path.stat().st_size == 0:
            print(f"\n=== [{i}/{len(working)}] {path.name} （0 bytes） ===")
            print("  跳過：JSONL 為空檔，無法匯入；補齊內容後重跑即可。")
            state["files"][path.name] = {"file": path.name, "status": "empty", "sha256": inc.file_sha256(path)}
            inc._write_state(STATE_PATH, state)
            continue
        before = d1_counts(d1)
        print(f"\n=== [{i}/{len(working)}] {path.name} （{human(path.stat().st_size)}） ===")
        print("  匯入進度：", flush=True)
        last_phase = "start"

        def report(event: dict[str, Any]) -> None:
            nonlocal last_phase
            last_phase = str(event.get("phase", last_phase))
            print_progress(event)

        try:
            record = prepare_and_import(
                path,
                d1,
                args.batch_size,
                args.commit_every,
                args.keep_staging,
                progress=report,
            )
            after = d1_counts(d1)
            dt = record["seconds"]
            print(f"完成（{dt:.0f}s）")
            print(f"  新增 expressions={after['terms'] - before['terms']:+} "
                  f"edges={after['edges'] - before['edges']:+} "
                  f"dict_terms={after['dict_terms'] - before['dict_terms']:+}")
            state["files"][path.name] = {
                "file": path.name, "status": "success", "sha256": record["sha256"],
                "seconds": dt,
                "input_records": record["input_records"],
                "normalized_entries": record["normalized"],
                "expressions": record["expressions"],
                "edges": record["edges"],
                "phase_seconds": record["phase_seconds"],
            }
            inc._write_state(STATE_PATH, state)
        except Exception as exc:
            failures.append((path.name, f"{type(exc).__name__}: {exc}"))
            print(f"失敗：{exc}")
            state["files"][path.name] = {
                "file": path.name,
                "status": "failed",
                "sha256": inc.file_sha256(path),
                "last_phase": last_phase,
            }
            inc._write_state(STATE_PATH, state)

    print("\n===== 摘要 =====")
    counts = d1_counts(d1)
    print(f"D1 現在：terms={counts['terms']} edges={counts['edges']} dict_terms={counts['dict_terms']}")
    if failures:
        print("失敗：")
        for name, error in failures:
            print(f"  - {name}: {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
