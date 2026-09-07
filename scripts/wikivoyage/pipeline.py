#!/usr/bin/env python3
"""Run the safe Wikivoyage export pipeline and optional local D1 import."""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path
from typing import Any

from .build_handbook import build_managed_handbook
from .catalog import load_page_catalog, load_section_catalog, validate_registry, write_registry_report
from .download import DEFAULT_CATEGORY, DEFAULT_USER_AGENT, MediaWikiClient, download_snapshot
from .export_phrasebooks import export_snapshot_directory
from .quality import QualityGateError, evaluate_export_quality


def _dictionary_importer():
    """Load the existing importer without making ``langmap_dictionary`` global."""

    dictionary_root = Path(__file__).parents[1] / "dictionary"
    if str(dictionary_root) not in sys.path:
        sys.path.insert(0, str(dictionary_root))
    from incremental_import import run_incremental_import

    return run_incremental_import


def run_pipeline(
    snapshot_dir: Path,
    export_dir: Path,
    *,
    page_catalog_path: Path,
    section_catalog_path: Path,
    report_path: Path | None = None,
    quality_report_path: Path | None = None,
    download: bool = False,
    api_url: str | None = None,
    category: str = DEFAULT_CATEGORY,
    user_agent: str = DEFAULT_USER_AGENT,
    d1_database: Path | None = None,
    state_path: Path | None = None,
    staging_root: Path | None = None,
    snapshot_root: Path | None = None,
    batch_pages: int | None = None,
    resume: bool = True,
    build_handbook: bool = False,
    stop_on_error: bool = False,
) -> dict[str, Any]:
    """Download (optionally), export, gate, then import only to local SQLite.

    Production D1 is deliberately outside this entry point. A caller must
    provide an explicit local SQLite path for staging/import and a separate
    flag for handbook generation.
    """

    snapshot_dir = Path(snapshot_dir)
    export_dir = Path(export_dir)
    if download:
        client = MediaWikiClient(api_url or "https://en.wikivoyage.org/w/api.php", user_agent=user_agent)
        manifest = download_snapshot(client, snapshot_dir, category=category)
    else:
        manifest = json.loads((snapshot_dir / "manifest.json").read_text(encoding="utf-8"))
    manifest_payload = manifest.to_dict() if hasattr(manifest, "to_dict") else manifest
    report = export_snapshot_directory(
        snapshot_dir,
        export_dir,
        page_catalog_path=Path(page_catalog_path),
        section_catalog_path=Path(section_catalog_path),
        report_path=report_path or export_dir / "export-report.json",
    )
    quality = evaluate_export_quality(snapshot_dir, export_dir, report_path or export_dir / "export-report.json")
    quality_payload = quality.to_dict()
    quality_path = quality_report_path or export_dir / "quality-report.json"
    Path(quality_path).parent.mkdir(parents=True, exist_ok=True)
    temporary = Path(quality_path).with_name(f".{Path(quality_path).name}.tmp")
    temporary.write_text(json.dumps(quality_payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(quality_path)
    if not quality.passed:
        raise QualityGateError("Wikivoyage export quality gate failed: " + ", ".join(quality.errors))

    result: dict[str, Any] = {
        "snapshot_pages": len(manifest_payload.get("pages", [])) if isinstance(manifest_payload, dict) else 0,
        "export": report,
        "quality": quality_payload,
        "quality_report": str(quality_path),
    }
    if d1_database is not None:
        if state_path is None or staging_root is None:
            raise ValueError("--state and --staging-root are required with --d1-database")
        importer = _dictionary_importer()
        imports = importer(
            export_dir,
            Path(d1_database),
            Path(state_path),
            Path(staging_root),
            snapshot_root=snapshot_root,
            limit_files=batch_pages,
            resume=resume,
            stop_on_error=stop_on_error,
        )
        result["imports"] = imports
        if any(item.get("status") not in {"success", "skipped"} for item in imports):
            raise RuntimeError("one or more Wikivoyage files failed local import")
        connection = sqlite3.connect(Path(d1_database))
        try:
            discovered = [
                (int(item["pageid"]), str(item["title"]))
                for item in (manifest_payload.get("pages", []) if isinstance(manifest_payload, dict) else [])
                if isinstance(item, dict)
            ]
            registry = validate_registry(connection, discovered, load_page_catalog(Path(page_catalog_path)))
            registry_path = export_dir / "registry-report.json"
            write_registry_report(registry, registry_path)
            result["registry_report"] = registry.to_dict()
            if build_handbook:
                build = build_managed_handbook(connection, load_section_catalog(Path(section_catalog_path)))
                result["handbook"] = {
                    "id": build.handbook_id,
                    "sections": build.sections,
                    "items": build.items,
                    "reused": build.reused,
                }
        finally:
            connection.close()
    elif build_handbook:
        raise ValueError("--build-handbook requires --d1-database")
    return result


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--snapshot-dir", type=Path, required=True)
    parser.add_argument("--export-dir", type=Path, required=True)
    parser.add_argument("--page-catalog", type=Path, default=Path(__file__).with_name("page-catalog.json"))
    parser.add_argument("--section-catalog", type=Path, default=Path(__file__).with_name("section-catalog.json"))
    parser.add_argument("--report", type=Path)
    parser.add_argument("--quality-report", type=Path)
    parser.add_argument("--download", action="store_true")
    parser.add_argument("--api-url")
    parser.add_argument("--category", default=DEFAULT_CATEGORY)
    parser.add_argument("--user-agent", default=DEFAULT_USER_AGENT)
    parser.add_argument("--d1-database", type=Path)
    parser.add_argument("--state", type=Path)
    parser.add_argument("--staging-root", type=Path)
    parser.add_argument("--snapshot-root", type=Path)
    parser.add_argument("--batch-pages", type=int)
    parser.add_argument("--no-resume", action="store_true")
    parser.add_argument("--build-handbook", action="store_true")
    parser.add_argument("--stop-on-error", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    result = run_pipeline(
        args.snapshot_dir,
        args.export_dir,
        page_catalog_path=args.page_catalog,
        section_catalog_path=args.section_catalog,
        report_path=args.report,
        quality_report_path=args.quality_report,
        download=args.download,
        api_url=args.api_url,
        category=args.category,
        user_agent=args.user_agent,
        d1_database=args.d1_database,
        state_path=args.state,
        staging_root=args.staging_root,
        snapshot_root=args.snapshot_root,
        batch_pages=args.batch_pages,
        resume=not args.no_resume,
        build_handbook=args.build_handbook,
        stop_on_error=args.stop_on_error,
    )
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
