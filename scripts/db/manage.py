from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Callable

from lib.fingerprint import build_local_status
from lib.local import rebuild_local_state, verify_local_environment
from lib.paths import ProjectPaths
from lib.production import apply_production, inventory_production, plan_production


Handler = Callable[[ProjectPaths, argparse.Namespace], int]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="manage.py",
        description="Safe database management command dispatcher.",
    )
    parser.add_argument("--repo-root", type=Path, default=None, help=argparse.SUPPRESS)
    environment_parser = parser.add_subparsers(dest="environment", required=True)

    local_parser = environment_parser.add_parser("local")
    local_commands = local_parser.add_subparsers(dest="command", required=True)
    status_parser = local_commands.add_parser("status")
    status_parser.set_defaults(handler=_local_status_handler)
    rebuild_parser = local_commands.add_parser("rebuild")
    rebuild_parser.set_defaults(handler=_local_rebuild_handler)
    verify_parser = local_commands.add_parser("verify")
    verify_parser.set_defaults(handler=_local_verify_handler)

    production_parser = environment_parser.add_parser("production")
    production_commands = production_parser.add_subparsers(dest="command", required=True)
    inventory_parser = production_commands.add_parser("inventory")
    inventory_parser.set_defaults(handler=_production_inventory_handler)
    plan_parser = production_commands.add_parser("plan")
    plan_parser.set_defaults(handler=_production_plan_handler)
    apply_parser = production_commands.add_parser("apply")
    apply_parser.add_argument("--plan", type=Path, required=True)
    apply_parser.add_argument("--database-name", required=True)
    apply_parser.add_argument("--confirm-production", required=True)
    apply_parser.set_defaults(handler=_production_apply_handler)
    verify_parser = production_commands.add_parser("verify")
    verify_parser.set_defaults(handler=_stub_handler)

    restore_parser = production_commands.add_parser("restore")
    restore_parser.add_argument("bookmark")
    restore_parser.set_defaults(handler=_stub_handler)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    paths = ProjectPaths.discover(args.repo_root)
    handler: Handler = args.handler
    return handler(paths, args)


def _stub_handler(paths: ProjectPaths, args: argparse.Namespace) -> int:
    payload = {
        "environment": args.environment,
        "command": args.command,
        "bookmark": getattr(args, "bookmark", None),
        "repo_root": str(paths.repo_root),
    }
    print(json.dumps(payload, ensure_ascii=False))
    return 0


def _local_status_handler(paths: ProjectPaths, args: argparse.Namespace) -> int:
    print(json.dumps(build_local_status(paths), ensure_ascii=False))
    return 0


def _local_rebuild_handler(paths: ProjectPaths, args: argparse.Namespace) -> int:
    payload = rebuild_local_state(
        paths,
        wrangler_bin=_wrangler_bin_from_env(),
        owner="scripts/db/manage.py",
        created_at="2026-08-01T00:00:00Z",
    )
    print(json.dumps(payload, ensure_ascii=False))
    return 0


def _local_verify_handler(paths: ProjectPaths, args: argparse.Namespace) -> int:
    payload = verify_local_environment(paths, wrangler_bin=_wrangler_bin_from_env())
    print(json.dumps(payload, ensure_ascii=False))
    return 0


def _production_inventory_handler(paths: ProjectPaths, args: argparse.Namespace) -> int:
    report = inventory_production(paths, wrangler_bin=_wrangler_bin_from_env())
    summary = {
        "status": report["status"],
        "environment": "production",
        "database_name": report["identity"]["database_name"],
        "database_id": report["identity"]["database_id"],
        "schema_object_count": len(report["schema_objects"]),
        "migration_count": len(report["migrations"]["applied"]),
        "counts": report["counts"],
        "report_path": str(paths.production_inventory_report_path),
    }
    print(json.dumps(summary, ensure_ascii=False))
    return 0


def _production_plan_handler(paths: ProjectPaths, args: argparse.Namespace) -> int:
    plan = plan_production(paths, wrangler_bin=_wrangler_bin_from_env())
    print(json.dumps(plan, ensure_ascii=False))
    return 0 if plan["status"] == "ready" else 1


def _production_apply_handler(paths: ProjectPaths, args: argparse.Namespace) -> int:
    result = apply_production(
        paths,
        plan_path=args.plan,
        database_name=args.database_name,
        confirmation=args.confirm_production,
        wrangler_bin=_wrangler_bin_from_env(),
    )
    print(json.dumps(result, ensure_ascii=False))
    return 0


def _wrangler_bin_from_env() -> Path | None:
    configured = os.environ.get("LANGMAP_WRANGLER_BIN")
    return Path(configured) if configured else None


if __name__ == "__main__":
    raise SystemExit(main())
