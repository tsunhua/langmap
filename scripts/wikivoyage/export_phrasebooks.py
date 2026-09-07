#!/usr/bin/env python3
"""Export pinned Wikivoyage snapshots as one Structured JSONL v2 file/page."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

from .catalog import load_page_catalog, load_section_catalog, profile_for
from .download import PageDescriptor
from .parser import PageSnapshot, export_page


EXPORTER_VERSION = "wikivoyage-phrasebook-1"


def _load_manifest(path: Path) -> dict[str, Any]:
    value = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(value, dict) or not isinstance(value.get("pages"), list):
        raise ValueError(f"invalid snapshot manifest: {path}")
    return value


def _descriptor(raw: dict[str, Any]) -> PageDescriptor:
    return PageDescriptor(
        pageid=int(raw["pageid"]),
        title=str(raw["title"]),
        canonical_url=str(raw["canonical_url"]),
        revision=int(raw["revision"]),
        revision_timestamp=str(raw["revision_timestamp"]),
        snapshot_file=str(raw["snapshot_file"]),
        snapshot_sha256=str(raw["snapshot_sha256"]),
    )


def write_jsonl_v2(result, destination: Path, snapshot: PageSnapshot) -> Path:
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    records = list(result.entries)
    header = {
        "record_type": "dictionary",
        "schema_version": 2,
        "dictionary_key": f"enwikivoyage:{snapshot.pageid}",
        "input_file_name": snapshot.snapshot_file if hasattr(snapshot, "snapshot_file") else f"pages/{snapshot.pageid}-{snapshot.revision}.wikitext",
        "input_sha256": snapshot.content_sha256,
        "entry_count": len(records),
        "exporter_version": EXPORTER_VERSION,
        "site": "enwikivoyage",
        "pageid": snapshot.pageid,
        "revision": snapshot.revision,
    }
    encoded = "\n".join(json.dumps(item, ensure_ascii=False, sort_keys=True) for item in [header, *records]) + "\n"
    temporary = destination.with_name(f".{destination.name}.tmp")
    temporary.write_text(encoded, encoding="utf-8")
    temporary.replace(destination)
    return destination


def _write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in rows)
    temporary = path.with_name(f".{path.name}.tmp")
    temporary.write_text(encoded, encoding="utf-8")
    temporary.replace(path)


def export_snapshot_directory(
    snapshot_dir: Path,
    output_dir: Path,
    *,
    page_catalog_path: Path,
    section_catalog_path: Path,
    report_path: Path | None = None,
) -> dict[str, Any]:
    snapshot_dir = Path(snapshot_dir)
    output_dir = Path(output_dir)
    manifest = _load_manifest(snapshot_dir / "manifest.json")
    page_catalog = load_page_catalog(page_catalog_path)
    section_catalog = load_section_catalog(section_catalog_path)
    report_pages: list[dict[str, Any]] = []
    source_catalog: dict[str, dict[str, Any]] = {}
    quarantine_rows: list[dict[str, Any]] = []
    removal_rows: list[dict[str, Any]] = []
    for raw in sorted(manifest["pages"], key=lambda item: int(item["pageid"])):
        descriptor = _descriptor(raw)
        content_path = snapshot_dir / descriptor.snapshot_file
        content = content_path.read_text(encoding="utf-8")
        if hashlib.sha256(content.encode("utf-8")).hexdigest() != descriptor.snapshot_sha256:
            raise ValueError(f"snapshot checksum mismatch: {content_path}")
        snapshot = PageSnapshot.from_content(
            pageid=descriptor.pageid,
            title=descriptor.title,
            canonical_url=descriptor.canonical_url,
            revision=descriptor.revision,
            revision_timestamp=descriptor.revision_timestamp,
            content=content,
        )
        profile = profile_for(descriptor.pageid, descriptor.title, page_catalog)
        result = export_page(snapshot, profile, section_catalog)
        source_catalog[f"enwikivoyage:{descriptor.pageid}"] = {
            "type": "url",
            "name": descriptor.canonical_url,
            "source_rank": 100,
        }
        output_path = output_dir / f"{descriptor.pageid}.jsonl"
        if result.entries:
            write_jsonl_v2(result, output_path, snapshot)
        for diagnostic in result.diagnostics:
            # Page-level blocked reasons are registry accounting, not parser
            # quarantine. Row-level diagnostics carry an error_code and are
            # retained for review without entering the staging input.
            if diagnostic.get("error_code"):
                quarantine_rows.append({
                    "pageid": descriptor.pageid,
                    "title": descriptor.title,
                    "revision": descriptor.revision,
                    **diagnostic,
                })
        report_pages.append({
            "pageid": descriptor.pageid,
            "title": descriptor.title,
            "state": result.state,
            "entry_count": len(result.entries),
            "diagnostics": list(result.diagnostics),
        })
    report = {
        "schema_version": 1,
        "site": manifest.get("site", "enwikivoyage"),
        "category": manifest.get("category", "Category:Phrasebooks"),
        "pages": report_pages,
        "counts": {state: sum(item["state"] == state for item in report_pages) for state in ("included", "empty", "excluded", "blocked", "quarantined")},
    }
    source_catalog_path = output_dir / "source-catalog.json"
    source_catalog_path.parent.mkdir(parents=True, exist_ok=True)
    source_catalog_path.write_text(
        json.dumps({"schema_version": 1, "sources": source_catalog}, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    review_dir = output_dir / "review"
    _write_jsonl(review_dir / "quarantine.jsonl", sorted(quarantine_rows, key=lambda row: (int(row["pageid"]), int(row.get("line", 0)), str(row.get("error_code", "")))))
    # Removals are intentionally an explicit, operator-reviewed input. The
    # first export has no prior identity set; keeping an empty deterministic
    # artifact makes the quality report and release package shape stable.
    _write_jsonl(review_dir / "removals.jsonl", removal_rows)
    report_path = Path(report_path or output_dir / "export-report.json")
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return report


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--snapshot-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--page-catalog", type=Path, required=True)
    parser.add_argument("--section-catalog", type=Path, required=True)
    parser.add_argument("--report", type=Path)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    report = export_snapshot_directory(
        args.snapshot_dir,
        args.output_dir,
        page_catalog_path=args.page_catalog,
        section_catalog_path=args.section_catalog,
        report_path=args.report,
    )
    print(json.dumps(report, ensure_ascii=False, sort_keys=True))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
