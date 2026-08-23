#!/usr/bin/env python3
"""Stage dictionary JSONL and emit offline preview artifacts."""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path

from langmap_dictionary.adapters.traditional_chinese_english import normalize_release
from langmap_dictionary.clusters import build_explicit_clusters
from langmap_dictionary.loader import load_jsonl_release
from langmap_dictionary.preview import build_preview
from langmap_dictionary.schema import create_staging_database
from langmap_dictionary.publisher import publish_command
from langmap_dictionary.reconciliation import reconcile_release


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="LangMap dictionary staging workflow")
    commands = parser.add_subparsers(dest="command", required=True)
    stage = commands.add_parser("stage", help="load Structured JSONL v2 into SQLite")
    stage.add_argument("jsonl", nargs="+", type=Path)
    stage.add_argument("--database", required=True, type=Path)
    preview = commands.add_parser("preview", help="normalize and emit an offline artifact")
    preview.add_argument("--database", required=True, type=Path)
    preview.add_argument("--release", required=True)
    preview.add_argument("--output", required=True, type=Path)
    inspect = commands.add_parser("inspect", help="show staging counts")
    inspect.add_argument("--database", required=True, type=Path)
    inspect.add_argument("--release", required=True)
    for name in ("plan", "apply", "verify", "activate", "rollback"):
        command = commands.add_parser(name, help=f"{name} a compiled D1 release artifact")
        command.add_argument("--manifest", required=True, type=Path)
        command.add_argument("--root", type=Path, default=Path.cwd())
        command.add_argument("--environment", choices=("local", "production"), default="local")
        command.add_argument("--database-name", default="DB")
        command.add_argument("--release-id")
        command.add_argument("--parent-release-id")
    reconcile = commands.add_parser("reconcile", help="run the two-pass offline reconciliation provider")
    reconcile.add_argument("action", choices=("run",))
    reconcile.add_argument("--database", required=True, type=Path)
    reconcile.add_argument("--release", required=True)
    reconcile.add_argument("--config", required=True, type=Path)
    reconcile.add_argument("--provider-command", required=True, nargs="+", type=str)
    reconcile.add_argument("--output", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = _parser()
    args = parser.parse_args(argv)
    try:
        if args.command == "stage":
            connection = create_staging_database(args.database)
            summary = load_jsonl_release(connection, args.jsonl)
            print(json.dumps({"release_id": summary.release_id, "manifest_hash": summary.manifest_hash, "input_records": summary.input_records, "staged_entries": summary.staged_entries, "staged_senses": summary.staged_senses, "quarantined": summary.quarantined}, ensure_ascii=False, sort_keys=True))
            return 0
        connection = create_staging_database(args.database)
        if args.command == "preview":
            normalize_release(connection, args.release)
            summary = build_explicit_clusters(connection, args.release)
            manifest = build_preview(connection, args.release, args.output)
            print(json.dumps({"release_id": manifest.release_id, "manifest_hash": manifest.manifest_hash, "clusters": summary.clusters, "output": str(args.output)}, ensure_ascii=False, sort_keys=True))
            return 0
        if args.command in {"plan", "apply", "verify", "activate", "rollback"}:
            result = publish_command(args.root, args.command, args.manifest, environment=args.environment, database_name=args.database_name, release_id=args.release_id, parent_release_id=args.parent_release_id)
            print(json.dumps(result, ensure_ascii=False, sort_keys=True))
            return 0
        if args.command == "reconcile":
            config = json.loads(args.config.read_text(encoding="utf-8"))
            if not isinstance(config, dict):
                raise ValueError("reconciliation config must be an object")
            connection = create_staging_database(args.database)
            summary = reconcile_release(connection, args.release, tuple(args.provider_command), config, output_dir=args.output)
            for decision in summary.decisions:
                connection.execute(
                    "INSERT OR REPLACE INTO merge_decisions (release_id, decision_key, left_cluster_key, right_cluster_key, decision, confidence, rationale_json) VALUES (?,?,?,?,?,?,?)",
                    (
                        args.release,
                        f"{decision.candidate_key.left_claim_key}\0{decision.candidate_key.right_claim_key}",
                        decision.candidate_key.left_claim_key,
                        decision.candidate_key.right_claim_key,
                        decision.decision,
                        decision.confidence_min,
                        json.dumps({"reason_code": decision.reason_code, "features_fingerprint": decision.features_fingerprint, "responses": [item.to_dict() for item in decision.responses]}, ensure_ascii=False, sort_keys=True, separators=(",", ":")),
                    ),
                )
            connection.commit()
            print(json.dumps({"release_id": args.release, "candidates": len(summary.candidates), "decisions": len(summary.decisions), "accepted_merges": len(summary.accepted_pairs), "clusters": len(summary.clusters), "config_hash": summary.config_hash, "provider_error": summary.provider_error}, ensure_ascii=False, sort_keys=True))
            return 0
        row = connection.execute("SELECT * FROM staging_releases WHERE id=?", (args.release,)).fetchone()
        if row is None:
            raise ValueError(f"unknown release: {args.release}")
        result = dict(row)
        result["clusters"] = connection.execute("SELECT COUNT(*) FROM lexical_clusters WHERE release_id=?", (args.release,)).fetchone()[0]
        result["occurrences"] = connection.execute("SELECT COUNT(*) FROM lexical_occurrences WHERE release_id=?", (args.release,)).fetchone()[0]
        print(json.dumps(result, ensure_ascii=False, sort_keys=True))
        return 0
    except (OSError, ValueError, sqlite3.Error) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
