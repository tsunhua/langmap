"""Thin CLI-facing wrapper around the shared managed release executor."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.db.lib.dictionary_release import ReleasePaths, activate_release, apply_release, rollback_release, verify_release


def _paths(root: Path) -> ReleasePaths:
    return ReleasePaths(root.resolve(), root.resolve() / "scripts" / "db" / "state")


def publish_command(root: Path, command: str, manifest: Path, *, environment: str = "local", database_name: str = "DB", wrangler_bin: Path | None = None, parent_release_id: str | None = None, release_id: str | None = None) -> dict[str, Any]:
    paths = _paths(root)
    if command == "plan":
        payload = json.loads(Path(manifest).read_text(encoding="utf-8"))
        if not isinstance(payload, dict) or not payload.get("release_id"):
            raise ValueError("release manifest is invalid")
        return {"status": "ready", "environment": environment, "release_id": payload["release_id"], "manifest": str(Path(manifest).resolve()), "manifest_hash": payload.get("manifest_hash"), "chunks": len(payload.get("chunks", [])), "mutation_allowed": False}
    if command == "apply":
        return apply_release(paths, manifest, environment=environment, database_name=database_name, wrangler_bin=wrangler_bin).to_dict()
    payload = json.loads(Path(manifest).read_text(encoding="utf-8"))
    selected_release = release_id or str(payload.get("release_id", ""))
    if command == "verify":
        return verify_release(paths, manifest, environment=environment, database_name=database_name, wrangler_bin=wrangler_bin)
    if command == "activate":
        return activate_release(paths, selected_release, environment=environment, database_name=database_name, wrangler_bin=wrangler_bin)
    if command == "rollback":
        return rollback_release(paths, selected_release, parent_release_id, environment=environment, database_name=database_name, wrangler_bin=wrangler_bin)
    raise ValueError(f"unknown publisher command: {command}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Apply and verify managed dictionary release artifacts")
    parser.add_argument("command", choices=("apply", "verify", "activate", "rollback"))
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--environment", choices=("local", "production"), default="local")
    parser.add_argument("--database-name", default="DB")
    parser.add_argument("--release-id")
    parser.add_argument("--parent-release-id")
    args = parser.parse_args(argv)
    result = publish_command(args.root, args.command, args.manifest, environment=args.environment, database_name=args.database_name, release_id=args.release_id, parent_release_id=args.parent_release_id)
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
