from __future__ import annotations

import hashlib
import json
from pathlib import Path

from scripts.wikivoyage.pipeline import run_pipeline


ROOT = Path(__file__).parents[1]
FIXTURE = ROOT / "tests" / "fixtures"


def test_pipeline_runs_export_and_quality_without_d1(tmp_path: Path) -> None:
    content = (FIXTURE / "japanese_phrasebook.wikitext").read_text(encoding="utf-8")
    snapshot = tmp_path / "snapshot"
    snapshot_file = snapshot / "pages/16153-5332510.wikitext"
    snapshot_file.parent.mkdir(parents=True)
    snapshot_file.write_text(content, encoding="utf-8")
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

    result = run_pipeline(
        snapshot,
        tmp_path / "export",
        page_catalog_path=ROOT / "page-catalog.json",
        section_catalog_path=ROOT / "section-catalog.json",
    )

    assert result["snapshot_pages"] == 1
    assert result["quality"]["passed"] is True
    assert Path(result["quality_report"]).is_file()
