from __future__ import annotations

import json
from pathlib import Path

from scripts.wikivoyage.catalog import load_page_catalog, load_section_catalog
from scripts.wikivoyage.export_phrasebooks import export_snapshot_directory


ROOT = Path(__file__).parents[1]
FIXTURE = ROOT / "tests" / "fixtures"


def test_export_snapshot_directory_writes_v2_file_and_report(tmp_path: Path) -> None:
    snapshot_dir = tmp_path / "snapshot"
    (snapshot_dir / "pages").mkdir(parents=True)
    content = (FIXTURE / "japanese_phrasebook.wikitext").read_text(encoding="utf-8")
    import hashlib
    digest = hashlib.sha256(content.encode("utf-8")).hexdigest()
    (snapshot_dir / "pages/16153-5332510.wikitext").write_text(content, encoding="utf-8")
    (snapshot_dir / "manifest.json").write_text(json.dumps({
        "schema_version": 1,
        "site": "enwikivoyage",
        "category": "Category:Phrasebooks",
        "pages": [{
            "pageid": 16153,
            "title": "Japanese phrasebook",
            "canonical_url": "https://en.wikivoyage.org/wiki/Japanese_phrasebook",
            "revision": 5332510,
            "revision_timestamp": "2026-09-07T00:00:00Z",
            "snapshot_file": "pages/16153-5332510.wikitext",
            "snapshot_sha256": digest,
        }],
    }), encoding="utf-8")

    report = export_snapshot_directory(
        snapshot_dir,
        tmp_path / "jsonl",
        page_catalog_path=ROOT / "page-catalog.json",
        section_catalog_path=ROOT / "section-catalog.json",
    )

    assert report["counts"]["included"] == 1
    output = tmp_path / "jsonl/16153.jsonl"
    records = [json.loads(line) for line in output.read_text(encoding="utf-8").splitlines()]
    assert records[0]["schema_version"] == 2
    assert records[0]["entry_count"] == len(records) - 1
    assert all(row["dictionary_key"] == "enwikivoyage:16153" for row in records[1:])

