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

from scripts.dictionary.text_identity import canonicalize_expression_text


ROOT = Path(__file__).parents[3]
IMPORTER = ROOT / "scripts" / "dictionary" / "import_mapping_csv_pg.py"


def _write_manifest(
    tmp_path: Path,
    *,
    source_key: str | None = None,
    source_name: str | None = None,
    values: tuple[str, str] | None = None,
    include_row: bool = True,
    duplicate_entry_id: bool = False,
) -> tuple[Path, str]:
    source_key = source_key or f"test:csv-import:{uuid4().hex}"
    tmp_path.mkdir(parents=True, exist_ok=True)
    csv_path = tmp_path / "data.csv"
    suffix = source_key.rsplit(":", 1)[-1][:12]
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow([
            "ENTRY_ID",
            "NOTE",
            "LOCALE_eng-Latn-US",
            "LOCALE_jpn-Jpan-JP",
            "READING_jpn-Latn_hepburn-JP",
        ])
        if include_row:
            source_value, target_value = values or (f"word-{suffix}", f"語-{suffix}")
            writer.writerow([f"entry-{suffix}", "integration", source_value, target_value, f"go-{suffix}"])
            if duplicate_entry_id:
                writer.writerow([
                    f"entry-{suffix}",
                    "integration-duplicate",
                    f"{source_value}-duplicate",
                    f"{target_value}-duplicate",
                    f"go-{suffix}-duplicate",
                ])
    manifest = tmp_path / "manifest.json"
    manifest.write_text(
        json.dumps(
            {
                "manifest_version": 1,
                "source_key": source_key,
                "source_type": "test",
                "source_name": source_name or source_key,
                "csv": csv_path.name,
                "csv_sha256": hashlib.sha256(csv_path.read_bytes()).hexdigest(),
                "entry_count": 2 if duplicate_entry_id else (1 if include_row else 0),
                "locales": ["eng-Latn-US", "jpn-Jpan-JP"],
                "locale_metadata": {
                    "eng-Latn-US": {"name": "English", "name_en": "English"},
                    "jpn-Jpan-JP": {"name": "日本語", "name_en": "Japanese"},
                },
                "reading_count": 2 if duplicate_entry_id else (1 if include_row else 0),
                "reading_columns": [{"locale": "jpn-Latn_hepburn-JP", "scheme": "hepburn"}],
            },
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    return manifest, source_key


def _run(
    target: Path,
    database_url: str,
    action: str,
    *,
    input_dir: bool = False,
    extra_args: list[str] | None = None,
    disable_backup: bool = True,
) -> subprocess.CompletedProcess[str]:
    environment = os.environ.copy()
    environment["DATABASE_URL"] = database_url
    target_flag = "--input-dir" if input_dir else "--manifest"
    return subprocess.run(
        [
            sys.executable,
            str(IMPORTER),
            target_flag,
            str(target),
            action,
            *( ["--no-pre-release-backup"] if disable_backup else [] ),
            *(extra_args or []),
        ],
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


def test_apply_rejects_duplicate_entry_ids_in_postgres_staging(tmp_path: Path) -> None:
    database_url = os.environ.get("LANGMAP_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("set LANGMAP_TEST_DATABASE_URL to an isolated PostgreSQL database")

    manifest, source_key = _write_manifest(
        tmp_path / "duplicate-entry",
        duplicate_entry_id=True,
    )

    result = _run(manifest, database_url, "--apply")

    assert result.returncode == 2
    output = json.loads(result.stdout)
    assert output["committed"] == []
    assert output["failed"][0]["source_key"] == source_key
    assert "duplicate key" in output["failed"][0]["error"]


def test_batch_keeps_earlier_source_when_later_source_fails(tmp_path: Path) -> None:
    database_url = os.environ.get("LANGMAP_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("set LANGMAP_TEST_DATABASE_URL to an isolated PostgreSQL database")

    release_dir = tmp_path / "release"
    first_key = f"test:batch:first:{uuid4().hex}"
    first_name = f"batch-first:{uuid4().hex}"
    _first_manifest, _ = _write_manifest(
        release_dir / "01-first",
        source_key=first_key,
        source_name=first_name,
    )
    second_key = f"test:batch:fail:{uuid4().hex}"
    second_name = f"batch-fail:{uuid4().hex}"
    _second_manifest, _ = _write_manifest(
        release_dir / "02-fail",
        source_key=second_key,
        source_name=second_name,
    )

    import psycopg

    with psycopg.connect(database_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute("DROP TRIGGER IF EXISTS test_fail_dictionary_source ON expression_sources")
            cursor.execute(
                """
                CREATE OR REPLACE FUNCTION test_fail_dictionary_source() RETURNS trigger
                LANGUAGE plpgsql AS $$
                BEGIN
                    IF EXISTS (SELECT 1 FROM sources WHERE id=NEW.source_id AND name LIKE 'batch-fail:%') THEN
                        RAISE EXCEPTION 'intentional source failure';
                    END IF;
                    RETURN NEW;
                END;
                $$
                """,
            )
            cursor.execute(
                """
                CREATE TRIGGER test_fail_dictionary_source
                BEFORE INSERT ON expression_sources
                FOR EACH ROW EXECUTE FUNCTION test_fail_dictionary_source()
                """
            )
        connection.commit()

    try:
        result = _run(release_dir, database_url, "--apply", input_dir=True)
    finally:
        with psycopg.connect(database_url) as connection:
            with connection.cursor() as cursor:
                cursor.execute("DROP TRIGGER IF EXISTS test_fail_dictionary_source ON expression_sources")
                cursor.execute("DROP FUNCTION IF EXISTS test_fail_dictionary_source()")

    assert result.returncode == 2
    output = json.loads(result.stdout)
    assert [item["source_key"] for item in output["committed"]] == [first_key]
    assert output["failed"][0]["source_key"] == second_key
    assert output["not_attempted"] == []

    with psycopg.connect(database_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT id FROM sources WHERE type=%s AND name=%s", ("test", first_name))
            assert cursor.fetchone() is not None
            cursor.execute("SELECT count(*) FROM expression_sources WHERE source_id=(SELECT id FROM sources WHERE type=%s AND name=%s)", ("test", first_name))
            assert cursor.fetchone()[0] == 2
            cursor.execute("SELECT count(*) FROM sources WHERE type=%s AND name=%s", ("test", second_name))
            assert cursor.fetchone()[0] == 0


def test_apply_can_rebuild_secondary_indexes_in_source_transaction(tmp_path: Path) -> None:
    database_url = os.environ.get("LANGMAP_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("set LANGMAP_TEST_DATABASE_URL to an isolated PostgreSQL database")

    manifest, _source_key = _write_manifest(tmp_path / "index-rebuild")
    result = _run(
        manifest,
        database_url,
        "--apply",
        extra_args=["--rebuild-secondary-indexes"],
    )

    assert result.returncode == 0, result.stderr + result.stdout

    import psycopg

    with psycopg.connect(database_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT indexname
                FROM pg_indexes
                WHERE tablename IN (
                    'expressions', 'expression_locale_links', 'expression_edges',
                    'expression_sources', 'expression_edge_sources'
                )
                ORDER BY indexname
                """
            )
            indexes = {row[0] for row in cursor.fetchall()}

    assert "idx_expressions_language_created" in indexes
    assert "idx_expression_edges_b_id" in indexes


def test_apply_creates_one_default_pre_release_backup(tmp_path: Path) -> None:
    database_url = os.environ.get("LANGMAP_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("set LANGMAP_TEST_DATABASE_URL to an isolated PostgreSQL database")

    manifest, _source_key = _write_manifest(tmp_path / "backup")
    backup_dir = tmp_path / "backups"
    result = _run(
        manifest,
        database_url,
        "--apply",
        extra_args=["--backup-dir", str(backup_dir)],
        disable_backup=False,
    )

    assert result.returncode == 0, result.stderr + result.stdout
    output = json.loads(result.stdout)
    backup_path = Path(output["backup"])
    assert backup_path.parent == backup_dir
    assert backup_path.is_file()
    assert backup_path.stat().st_size > 0


def test_batch_preserves_shared_expressions_and_edges(tmp_path: Path) -> None:
    database_url = os.environ.get("LANGMAP_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("set LANGMAP_TEST_DATABASE_URL to an isolated PostgreSQL database")

    release_dir = tmp_path / "shared-release"
    first_key = f"test:shared:first:{uuid4().hex}"
    second_key = f"test:shared:second:{uuid4().hex}"
    shared_word = canonicalize_expression_text(f"shared-word-{uuid4().hex}")
    shared_target = canonicalize_expression_text(f"共享詞-{uuid4().hex}")
    _first_manifest, _ = _write_manifest(
        release_dir / "01-first",
        source_key=first_key,
        values=(shared_word, shared_target),
    )
    _second_manifest, _ = _write_manifest(
        release_dir / "02-second",
        source_key=second_key,
        values=(shared_word, shared_target),
    )

    result = _run(release_dir, database_url, "--apply", input_dir=True)

    assert result.returncode == 0, result.stderr + result.stdout
    assert json.loads(result.stdout)["not_attempted"] == []

    import psycopg

    with psycopg.connect(database_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT count(*) FROM expressions WHERE text IN (%s, %s)",
                (shared_word, shared_target),
            )
            assert cursor.fetchone()[0] == 2
            cursor.execute(
                """
                SELECT count(*)
                FROM expression_sources
                WHERE expression_id IN (SELECT id FROM expressions WHERE text IN (%s, %s))
                """,
                (shared_word, shared_target),
            )
            assert cursor.fetchone()[0] == 4
            cursor.execute(
                """
                SELECT count(DISTINCT edges.id)
                FROM expression_edges edges
                JOIN expression_sources source_a ON source_a.expression_id=edges.expression_a_id
                JOIN expression_sources source_b ON source_b.expression_id=edges.expression_b_id
                WHERE edges.expression_a_id IN (SELECT id FROM expressions WHERE text IN (%s, %s))
                  AND edges.expression_b_id IN (SELECT id FROM expressions WHERE text IN (%s, %s))
                """,
                (shared_word, shared_target, shared_word, shared_target),
            )
            assert cursor.fetchone()[0] == 1
            cursor.execute(
                """
                SELECT count(*)
                FROM expression_edge_sources markers
                JOIN expression_edges edges ON edges.id=markers.edge_id
                WHERE edges.expression_a_id IN (SELECT id FROM expressions WHERE text IN (%s, %s))
                  AND edges.expression_b_id IN (SELECT id FROM expressions WHERE text IN (%s, %s))
                """,
                (shared_word, shared_target, shared_word, shared_target),
            )
            assert cursor.fetchone()[0] == 2


def test_zero_row_source_retires_previous_snapshot_and_orphans(tmp_path: Path) -> None:
    database_url = os.environ.get("LANGMAP_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("set LANGMAP_TEST_DATABASE_URL to an isolated PostgreSQL database")

    source_key = f"test:zero-row:{uuid4().hex}"
    source_name = f"zero-row:{uuid4().hex}"
    values = (
        canonicalize_expression_text(f"zero-word-{uuid4().hex}"),
        canonicalize_expression_text(f"零詞-{uuid4().hex}"),
    )
    populated, _ = _write_manifest(
        tmp_path / "populated",
        source_key=source_key,
        source_name=source_name,
        values=values,
    )
    empty, _ = _write_manifest(
        tmp_path / "empty",
        source_key=source_key,
        source_name=source_name,
        include_row=False,
    )

    first = _run(populated, database_url, "--apply")
    second = _run(empty, database_url, "--apply")

    assert first.returncode == 0, first.stderr + first.stdout
    assert second.returncode == 0, second.stderr + second.stdout

    import psycopg

    with psycopg.connect(database_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT id FROM sources WHERE type=%s AND name=%s", ("test", source_name))
            source_id = cursor.fetchone()[0]
            cursor.execute("SELECT count(*) FROM expression_sources WHERE source_id=%s", (source_id,))
            assert cursor.fetchone()[0] == 0
            cursor.execute(
                "SELECT count(*) FROM expressions WHERE text IN (%s, %s)",
                values,
            )
            assert cursor.fetchone()[0] == 0
