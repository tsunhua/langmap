from __future__ import annotations

import csv
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path
from uuid import uuid4

import pytest


ROOT = Path(__file__).parents[3]
IMPORTER = ROOT / "scripts" / "dictionary" / "import_mapping_csv_pg.py"


def _write_manifest(tmp_path: Path) -> tuple[Path, str]:
    source_key = f"test:csv-import:{uuid4().hex}"
    csv_path = tmp_path / "data.csv"
    suffix = source_key.rsplit(":", 1)[-1][:12]
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow([
            "ENTRY_ID",
            "NOTE",
            "LOCALE_eng-Latn-US",
            "LOCALE_jpn-Jpan-JP",
            "READING_jpn-Jpan-JP_kana",
        ])
        writer.writerow([f"entry-{suffix}", "integration", f"word-{suffix}", f"語-{suffix}", f"ご-{suffix}"])
    manifest = tmp_path / "manifest.json"
    manifest.write_text(
        json.dumps(
            {
                "manifest_version": 1,
                "source_key": source_key,
                "source_type": "test",
                "source_name": source_key,
                "csv": csv_path.name,
                "csv_sha256": hashlib.sha256(csv_path.read_bytes()).hexdigest(),
                "entry_count": 1,
                "locales": ["eng-Latn-US", "jpn-Jpan-JP"],
                "locale_metadata": {
                    "eng-Latn-US": {"name": "English", "name_en": "English"},
                    "jpn-Jpan-JP": {"name": "日本語", "name_en": "Japanese"},
                },
                "reading_count": 1,
                "reading_columns": [{"locale": "jpn-Jpan-JP", "scheme": "kana"}],
            },
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    return manifest, source_key


def _run(manifest: Path, database_url: str, action: str) -> subprocess.CompletedProcess[str]:
    environment = os.environ.copy()
    environment["DATABASE_URL"] = database_url
    return subprocess.run(
        [sys.executable, str(IMPORTER), "--manifest", str(manifest), action],
        cwd=ROOT,
        env=environment,
        text=True,
        capture_output=True,
        check=False,
    )


def test_csv_import_is_idempotent_against_isolated_postgres(tmp_path: Path) -> None:
    database_url = os.environ.get("LANGMAP_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("set LANGMAP_TEST_DATABASE_URL to an isolated PostgreSQL database")

    manifest, source_name = _write_manifest(tmp_path)
    check = _run(manifest, database_url, "--check")
    assert check.returncode == 0, check.stderr
    first = _run(manifest, database_url, "--apply")
    assert first.returncode == 0, first.stderr
    second = _run(manifest, database_url, "--apply")
    assert second.returncode == 0, second.stderr

    import psycopg

    with psycopg.connect(database_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT id FROM sources WHERE type=%s AND name=%s", ("test", source_name))
            source_id = cursor.fetchone()[0]
            cursor.execute("SELECT count(*) FROM expression_sources WHERE source_id=%s", (source_id,))
            expression_count = cursor.fetchone()[0]
            cursor.execute("SELECT count(*) FROM expression_edge_sources WHERE source_id=%s", (source_id,))
            edge_count = cursor.fetchone()[0]
            cursor.execute("SELECT count(*) FROM expression_readings WHERE source_id=%s", (source_id,))
            reading_count = cursor.fetchone()[0]

    assert {"expressions": expression_count, "edges": edge_count, "readings": reading_count} == {
        "expressions": 2,
        "edges": 1,
        "readings": 1,
    }
