from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Callable

from lib.paths import ProjectPaths


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
    for command in ("status", "rebuild", "verify"):
        subparser = local_commands.add_parser(command)
        subparser.set_defaults(handler=_stub_handler)

    production_parser = environment_parser.add_parser("production")
    production_commands = production_parser.add_subparsers(dest="command", required=True)
    for command in ("inventory", "plan", "apply", "verify"):
        subparser = production_commands.add_parser(command)
        subparser.set_defaults(handler=_stub_handler)

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


if __name__ == "__main__":
    raise SystemExit(main())
