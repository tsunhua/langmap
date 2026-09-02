#!/usr/bin/env python3
"""Stage dictionary JSONL and emit offline preview artifacts."""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
import time
from pathlib import Path

from langmap_dictionary.adapters.traditional_chinese_english import normalize_release
from langmap_dictionary.clusters import build_explicit_clusters
from langmap_dictionary.corpus import freeze_corpus, scan_corpus
from langmap_dictionary.loader import load_jsonl_release
from langmap_dictionary.local_import import import_release_to_local_d1
from langmap_dictionary.preview import build_preview
from langmap_dictionary.quality import assert_reading_quality, evaluate_quality
from langmap_dictionary.report import write_quality_report
from langmap_dictionary.schema import create_staging_database
from langmap_dictionary.publisher import publish_command
from langmap_dictionary.reconciliation import apply_reconciled_clusters, reconcile_release


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="LangMap dictionary staging workflow")
    commands = parser.add_subparsers(dest="command", required=True)
    stage = commands.add_parser("stage", help="load Structured JSONL v2 into SQLite")
    stage.add_argument("jsonl", nargs="+", type=Path)
    stage.add_argument("--database", required=True, type=Path)
    stage.add_argument("--batch-size", type=int, default=500)
    stage.add_argument("--fast", action="store_true", help="use compact, unsafe writes for a disposable staging database")
    preview = commands.add_parser("preview", help="normalize and emit an offline artifact")
    preview.add_argument("--database", required=True, type=Path)
    preview.add_argument("--release", required=True)
    preview.add_argument("--output", required=True, type=Path)
    preview.add_argument("--batch-size", type=int, default=500)
    preview.add_argument("--commit-every", type=int, default=10_000)
    preview.add_argument("--fast", action="store_true", help="use unsafe pragmas for a disposable staging database")
    prepare = commands.add_parser("prepare", help="normalize and build clusters without emitting a preview artifact")
    prepare.add_argument("--database", required=True, type=Path)
    prepare.add_argument("--release", required=True)
    prepare.add_argument("--batch-size", type=int, default=500)
    prepare.add_argument("--commit-every", type=int, default=10_000)
    prepare.add_argument("--resume", action="store_true")
    prepare.add_argument("--fast", action="store_true", help="use unsafe pragmas for a disposable staging database")
    inspect = commands.add_parser("inspect", help="show staging counts")
    inspect.add_argument("--database", required=True, type=Path)
    inspect.add_argument("--release", required=True)
    local_import = commands.add_parser("local-import", help="set-based import into a local Miniflare D1 SQLite file")
    local_import.add_argument("--database", required=True, type=Path)
    local_import.add_argument("--release", required=True)
    local_import.add_argument("--d1-database", required=True, type=Path)
    local_import.add_argument("--no-activate", action="store_true")
    local_import.add_argument(
        "--packed",
        action="store_true",
        help="write the space-priority integer-keyed dictionary catalog (requires a fresh catalog)",
    )
    local_import.add_argument(
        "--append",
        action="store_true",
        help="append one packed release to an existing catalog (use with --packed)",
    )
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
    reconcile.add_argument("--gold", required=True, type=Path, help="holdout reconciliation labels in JSONL; gate is fail-closed without it")
    reconcile.add_argument("--provider-command", required=True, nargs="+", type=str)
    reconcile.add_argument("--output", type=Path)
    corpus = commands.add_parser("corpus", help="freeze and validate a complete v2 corpus")
    corpus.add_argument("action", choices=("freeze", "validate", "report"))
    corpus.add_argument("--input", required=True, type=Path)
    corpus.add_argument("--output", required=True, type=Path)
    corpus.add_argument("--database", type=Path)
    corpus.add_argument("--release")
    corpus.add_argument("--profiles", type=Path, default=Path(__file__).parent / "config" / "dictionaries.json")
    return parser


def _configure_staging_writes(connection: sqlite3.Connection, *, fast: bool) -> None:
    if fast:
        # The staging database is reproducible from JSONL.  Avoid durability
        # work that only makes a disposable full-corpus import slower.
        connection.execute("PRAGMA journal_mode=OFF")
        connection.execute("PRAGMA synchronous=OFF")
        connection.execute("PRAGMA locking_mode=EXCLUSIVE")
        connection.execute("PRAGMA temp_store=MEMORY")
        connection.execute("PRAGMA cache_size=-524288")
        return
    connection.execute("PRAGMA journal_mode=WAL")
    connection.execute("PRAGMA synchronous=OFF")
    connection.execute("PRAGMA wal_autocheckpoint=0")


def _emit_progress(payload: dict[str, object]) -> None:
    print(json.dumps(payload, ensure_ascii=False, sort_keys=True), file=sys.stderr, flush=True)


def main(argv: list[str] | None = None) -> int:
    parser = _parser()
    args = parser.parse_args(argv)
    try:
        if args.command == "stage":
            connection = create_staging_database(args.database, fast=args.fast)
            _configure_staging_writes(connection, fast=args.fast)
            summary = load_jsonl_release(
                connection,
                args.jsonl,
                batch_size=args.batch_size,
                progress=_emit_progress,
                compact=args.fast,
            )
            print(json.dumps({"release_id": summary.release_id, "manifest_hash": summary.manifest_hash, "input_records": summary.input_records, "staged_entries": summary.staged_entries, "staged_senses": summary.staged_senses, "quarantined": summary.quarantined}, ensure_ascii=False, sort_keys=True))
            return 0
        if args.command in {"preview", "prepare"}:
            connection = create_staging_database(args.database, fast=args.fast)
            _configure_staging_writes(connection, fast=args.fast)
            started = time.perf_counter()
            normalized = normalize_release(
                connection,
                args.release,
                resume=getattr(args, "resume", False),
                batch_size=args.batch_size,
                commit_every=args.commit_every,
                progress=_emit_progress,
            )
            assert_reading_quality(connection, args.release)
            normalized_seconds = time.perf_counter() - started
            started = time.perf_counter()
            summary = build_explicit_clusters(connection, args.release)
            cluster_seconds = time.perf_counter() - started
            if args.command == "prepare":
                print(json.dumps({
                    "release_id": args.release,
                    "normalized_entries": normalized,
                    "clusters": summary.clusters,
                    "occurrences": summary.occurrences,
                    "quarantined": summary.quarantined,
                    "normalized_seconds": round(normalized_seconds, 3),
                    "cluster_seconds": round(cluster_seconds, 3),
                }, ensure_ascii=False, sort_keys=True))
                return 0
            manifest = build_preview(connection, args.release, args.output)
            print(json.dumps({"release_id": manifest.release_id, "manifest_hash": manifest.manifest_hash, "clusters": summary.clusters, "normalized_seconds": round(normalized_seconds, 3), "cluster_seconds": round(cluster_seconds, 3), "output": str(args.output)}, ensure_ascii=False, sort_keys=True))
            return 0
        if args.command == "local-import":
            if args.append and not args.packed:
                raise ValueError("--append requires --packed")
            summary = import_release_to_local_d1(
                args.database,
                args.d1_database,
                args.release,
                activate=not args.no_activate,
                packed=args.packed,
                append=args.append,
            )
            print(json.dumps(summary.__dict__, ensure_ascii=False, sort_keys=True))
            return 0
        if args.command in {"plan", "apply", "verify", "activate", "rollback"}:
            result = publish_command(args.root, args.command, args.manifest, environment=args.environment, database_name=args.database_name, release_id=args.release_id, parent_release_id=args.parent_release_id)
            print(json.dumps(result, ensure_ascii=False, sort_keys=True))
            return 0
        if args.command == "reconcile":
            config = json.loads(args.config.read_text(encoding="utf-8"))
            if not isinstance(config, dict):
                raise ValueError("reconciliation config must be an object")
            gold_rows: list[dict[str, object]] = []
            with args.gold.open(encoding="utf-8") as handle:
                for line_number, line in enumerate(handle, 1):
                    if not line.strip():
                        continue
                    value = json.loads(line)
                    if not isinstance(value, dict):
                        raise ValueError(f"gold line {line_number} must be an object")
                    gold_rows.append(value)
            connection = create_staging_database(args.database)
            summary = reconcile_release(connection, args.release, tuple(args.provider_command), config, output_dir=args.output, gold_rows=gold_rows)
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
                        json.dumps({"config_hash": summary.config_hash, "reason_code": decision.reason_code, "features_fingerprint": decision.features_fingerprint, "responses": [item.to_dict() for item in decision.responses]}, ensure_ascii=False, sort_keys=True, separators=(",", ":")),
                    ),
                )
            if summary.clusters:
                apply_reconciled_clusters(connection, args.release, summary.clusters)
            connection.commit()
            print(json.dumps({"release_id": args.release, "candidates": len(summary.candidates), "decisions": len(summary.decisions), "accepted_merges": len(summary.accepted_pairs), "clusters": len(summary.clusters), "config_hash": summary.config_hash, "provider_error": summary.provider_error, "evaluation_gate_enabled": summary.evaluation_gate_enabled, "evaluation_gate_reasons": summary.evaluation_gate_reasons}, ensure_ascii=False, sort_keys=True))
            return 0
        if args.command == "corpus":
            if args.action == "freeze":
                first = scan_corpus(args.input)
                second = scan_corpus(args.input)
                payload = freeze_corpus(first, second)
                args.output.parent.mkdir(parents=True, exist_ok=True)
                args.output.write_text(json.dumps(payload, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")
                print(json.dumps({"files": len(payload["files"]), "corpus_hash": payload["corpus_hash"], "output": str(args.output)}, ensure_ascii=False, sort_keys=True))
                return 0
            if args.database is None or not args.release:
                raise ValueError("corpus validate/report require --database and --release")
            profiles_payload = json.loads(args.profiles.read_text(encoding="utf-8"))
            profiles = profiles_payload.get("profiles", {}) if isinstance(profiles_payload, dict) else {}
            connection = create_staging_database(args.database)
            gate = evaluate_quality(connection, args.release, profiles)
            if args.action == "report":
                write_quality_report(args.output, gate, release_id=args.release)
            print(json.dumps(gate.to_dict() | {"release_id": args.release, "output": str(args.output) if args.action == "report" else None}, ensure_ascii=False, sort_keys=True))
            return 0 if gate.passed else 1
        if args.command != "inspect":
            raise ValueError(f"unknown command: {args.command}")
        connection = create_staging_database(args.database)
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
