from __future__ import annotations

import hashlib
import json
from pathlib import Path

from scripts.wikivoyage.export_phrasebooks import export_snapshot_directory
from scripts.wikivoyage.quality import evaluate_export_quality, quality_gate


ROOT = Path(__file__).parents[1]
FIXTURE = ROOT / "tests" / "fixtures"


def _snapshot(tmp_path: Path) -> Path:
    content = (FIXTURE / "japanese_phrasebook.wikitext").read_text(encoding="utf-8")
    snapshot = tmp_path / "snapshot"
    path = snapshot / "pages/16153-5332510.wikitext"
    path.parent.mkdir(parents=True)
    path.write_text(content, encoding="utf-8")
    snapshot.joinpath("manifest.json").write_text(json.dumps({
        "schema_version": 1,
        "site": "enwikivoyage",
        "category": "Category:Phrasebooks",
        "license": "CC BY-SA 4.0",
        "pages": [{
            "pageid": 16153,
            "title": "Japanese phrasebook",
            "canonical_url": "https://en.wikivoyage.org/wiki/Japanese_phrasebook",
            "revision": 5332510,
            "revision_timestamp": "2026-09-07T00:00:00Z",
            "snapshot_file": "pages/16153-5332510.wikitext",
            "snapshot_sha256": hashlib.sha256(content.encode("utf-8")).hexdigest(),
        }],
    }), encoding="utf-8")
    return snapshot


def test_quality_gate_checks_page_accounting_samples_and_review_counts(tmp_path: Path) -> None:
    snapshot = _snapshot(tmp_path)
    output = tmp_path / "export"
    export_snapshot_directory(
        snapshot,
        output,
        page_catalog_path=ROOT / "page-catalog.json",
        section_catalog_path=ROOT / "section-catalog.json",
    )
    report = quality_gate(snapshot, output)

    assert report.passed is True
    assert report.manifest_pages == report.report_pages == report.included_pages == report.jsonl_files == 1
    assert report.input_entries == 5
    assert len(report.samples) == 3
    assert report.quarantine_rows == 2
    assert report.removal_rows == 0


def test_quality_gate_fails_when_included_page_jsonl_is_missing(tmp_path: Path) -> None:
    snapshot = _snapshot(tmp_path)
    output = tmp_path / "export"
    export_snapshot_directory(
        snapshot,
        output,
        page_catalog_path=ROOT / "page-catalog.json",
        section_catalog_path=ROOT / "section-catalog.json",
    )
    (output / "16153.jsonl").unlink()

    report = evaluate_export_quality(snapshot, output)

    assert report.passed is False
    assert "jsonl_page_count_mismatch" in report.errors
    assert "no_valid_entries" in report.errors
