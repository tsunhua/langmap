import csv
import hashlib
import json
from types import SimpleNamespace

import pytest

from scripts.dictionary.import_mapping_csv_pg import (
    CsvContractError,
    create_pre_release_backup,
    iter_rows,
    main,
    validate,
    validate_target,
)


def write_snapshot(
    tmp_path,
    rows,
    *,
    locales=None,
    source_key="fixture:csv",
    source_type=None,
    source_name=None,
):
    tmp_path.mkdir(parents=True, exist_ok=True)
    csv_path = tmp_path / "data.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["ENTRY_ID", "NOTE", "LOCALE_eng-Latn-US", "LOCALE_jpn-Jpan-JP"])
        writer.writerows(rows)
    payload = {
        "schema_version": 1,
        "source_key": source_key,
        "csv": "data.csv",
        "csv_sha256": hashlib.sha256(csv_path.read_bytes()).hexdigest(),
        "locales": locales or {
            "eng-Latn-US": {"name": "English", "name_en": "English (US)"},
            "jpn-Jpan-JP": {"name": "日本語", "name_en": "Japanese (Japan)"},
        },
    }
    if source_type is not None:
        payload["source_type"] = source_type
    if source_name is not None:
        payload["source_name"] = source_name
    manifest = tmp_path / "manifest.json"
    manifest.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    return manifest


def test_validate_counts_same_language_and_cross_language_pairs(tmp_path):
    manifest = write_snapshot(tmp_path, [["entry-1", "note", "word|term", "語"]])

    summary = validate(manifest)

    assert summary["rows"] == 1
    assert summary["expressions"] is None
    assert summary["edges"] is None
    assert summary["distinct_counts"] == "deferred_to_postgresql"
    assert summary["expression_claims"] == 3
    assert summary["edge_claims"] == 3


def test_validate_normalizes_expression_cells_and_deduplicates(tmp_path):
    manifest = write_snapshot(tmp_path, [["entry-1", "", "「Hello！」|Hello", "「你好！」"]])

    summary = validate(manifest)

    assert summary["expressions"] is None
    assert summary["edges"] is None
    assert summary["expression_claims"] == 2
    assert summary["edge_claims"] == 1


def test_validate_rejects_unbalanced_expression_cell_with_location(tmp_path):
    manifest = write_snapshot(tmp_path, [["entry-1", "", "他說「你好", "hello"]])

    with pytest.raises(CsvContractError, match=r"row 2.*eng-Latn-US"):
        validate(manifest)


def test_validate_rejects_punctuation_only_expression_cell(tmp_path):
    manifest = write_snapshot(tmp_path, [["entry-1", "", "！！！", "hello"]])

    with pytest.raises(CsvContractError, match=r"row 2.*eng-Latn-US"):
        validate(manifest)


def test_validate_rejects_unsorted_locale_headers(tmp_path):
    manifest = write_snapshot(tmp_path, [["entry-1", "", "word", "語"]])
    csv_path = tmp_path / "data.csv"
    text = csv_path.read_text(encoding="utf-8").replace(
        "LOCALE_eng-Latn-US,LOCALE_jpn-Jpan-JP",
        "LOCALE_jpn-Jpan-JP,LOCALE_eng-Latn-US",
    )
    csv_path.write_text(text, encoding="utf-8")

    # Refresh checksum so this assertion reaches header validation.
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    payload["csv_sha256"] = hashlib.sha256(csv_path.read_bytes()).hexdigest()
    manifest.write_text(json.dumps(payload), encoding="utf-8")

    try:
        validate(manifest)
    except CsvContractError as exc:
        assert "sorted" in str(exc)
    else:
        raise AssertionError("expected invalid header")


def test_validate_checks_manifest_entry_count(tmp_path):
    manifest = write_snapshot(tmp_path, [["entry-1", "", "word", "語"]])
    payload = json.loads(manifest.read_text(encoding="utf-8"))
    payload["entry_count"] = 2
    manifest.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")

    try:
        validate(manifest)
    except CsvContractError as exc:
        assert "entry_count" in str(exc)
    else:
        raise AssertionError("expected manifest entry_count mismatch")


def test_validate_reads_wide_reading_columns_and_source_identity(tmp_path):
    csv_path = tmp_path / "data.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow([
            "ENTRY_ID",
            "NOTE",
            "LOCALE_eng-Latn-US",
            "LOCALE_jpn-Jpan-JP",
            "READING_jpn-Latn_hepburn-JP",
        ])
        writer.writerow(["oldid:1#basics/1", "formal", "hello", "こんにちは", "Konnichiwa|kon-nee-chee-wah"])
    manifest = tmp_path / "manifest.json"
    manifest.write_text(json.dumps({
        "manifest_version": 2,
        "source_key": "enwikivoyage:1:jpn-Jpan-JP",
        "source_type": "url",
        "source_name": "https://en.wikivoyage.org/wiki/Example#jpn-Jpan-JP",
        "target_locale": "jpn-Jpan-JP",
        "csv": "data.csv",
        "csv_sha256": hashlib.sha256(csv_path.read_bytes()).hexdigest(),
        "entry_count": 1,
        "reading_count": 2,
        "reading_columns": [{"locale": "jpn-Latn_hepburn-JP", "scheme": "hepburn"}],
        "locale_metadata": {
            "eng-Latn-US": {"name": "English", "name_en": "English (US)"},
            "jpn-Jpan-JP": {"name": "日本語", "name_en": "Japanese (Japan)"},
        },
    }, ensure_ascii=False), encoding="utf-8")

    summary = validate(manifest)

    assert summary["readings"] == 2
    assert summary["edges"] is None
    assert summary["edge_claims"] == 1


def test_validate_registers_compact_reading_locale_profile(tmp_path):
    csv_path = tmp_path / "data.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow([
            "ENTRY_ID",
            "NOTE",
            "LOCALE_eng-Latn-US",
            "LOCALE_yue-Hant-CN_Taishan",
            "READING_yue-Latn_gps-CN_Taishan",
        ])
        writer.writerow(["entry-1", "", "word", "詞", "tsi"])
    manifest = tmp_path / "manifest.json"
    manifest.write_text(json.dumps({
        "manifest_version": 1,
        "source_key": "fixture:compact-reading",
        "csv": "data.csv",
        "csv_sha256": hashlib.sha256(csv_path.read_bytes()).hexdigest(),
        "entry_count": 1,
        "reading_count": 1,
        "reading_columns": [{
            "locale": "yue-Latn_gps-CN_Taishan",
            "scheme": "gps",
        }],
        "locales": ["eng-Latn-US", "yue-Hant-CN_Taishan"],
        "locale_metadata": {},
    }, ensure_ascii=False), encoding="utf-8")

    summary = validate(manifest)

    assert summary["readings"] == 1


def test_validate_compact_reading_profile_keeps_lowercase_scheme(tmp_path):
    csv_path = tmp_path / "data.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow([
            "ENTRY_ID",
            "NOTE",
            "LOCALE_eng-Latn-US",
            "LOCALE_nan-Hant-TW",
            "READING_nan-Latn_Tailo-TW",
        ])
        writer.writerow(["entry-1", "", "word", "詞", "tsi"])
    manifest = tmp_path / "manifest.json"
    manifest.write_text(json.dumps({
        "manifest_version": 1,
        "source_key": "fixture:tailo-reading",
        "csv": "data.csv",
        "csv_sha256": hashlib.sha256(csv_path.read_bytes()).hexdigest(),
        "entry_count": 1,
        "reading_count": 1,
        "reading_columns": [{"locale": "nan-Latn_Tailo-TW", "scheme": "tailo"}],
        "locales": ["eng-Latn-US", "nan-Hant-TW"],
        "locale_metadata": {},
    }, ensure_ascii=False), encoding="utf-8")

    summary = validate(manifest)

    assert summary["readings"] == 1


def test_validate_target_discovers_nested_manifests_in_stable_order(tmp_path):
    first = write_snapshot(
        tmp_path / "z-source",
        [["entry-z", "", "word-z", "語-z"]],
        source_key="fixture:z",
    )
    second = write_snapshot(
        tmp_path / "a-source",
        [["entry-a", "", "word-a", "語-a"]],
        source_key="fixture:a",
    )

    prepared = validate_target(tmp_path)

    assert [item.path for item in prepared] == [second, first]
    assert [item.source_key for item in prepared] == ["fixture:a", "fixture:z"]


def test_validate_target_rejects_duplicate_source_identity(tmp_path):
    write_snapshot(
        tmp_path / "one",
        [["entry-1", "", "word-1", "語-1"]],
        source_key="fixture:one",
        source_type="test",
        source_name="same-source",
    )
    write_snapshot(
        tmp_path / "two",
        [["entry-2", "", "word-2", "語-2"]],
        source_key="fixture:two",
        source_type="test",
        source_name="same-source",
    )

    with pytest.raises(CsvContractError, match="duplicate source identity"):
        validate_target(tmp_path)


def test_validate_target_rejects_empty_input_directory(tmp_path):
    with pytest.raises(CsvContractError, match="contains no manifest"):
        validate_target(tmp_path)


def test_validate_zero_row_snapshot_and_stream_rows(tmp_path):
    manifest = write_snapshot(tmp_path / "empty", [])

    prepared = validate_target(manifest)

    assert prepared[0].summary["rows"] == 0
    assert list(iter_rows(prepared[0])) == []


def test_validate_defers_duplicate_entry_id_check_to_postgres_staging(tmp_path):
    manifest = write_snapshot(
        tmp_path / "duplicate-entry",
        [
            ["entry-1", "", "word-1", "語-1"],
            ["entry-1", "", "word-2", "語-2"],
        ],
    )

    summary = validate(manifest)

    assert summary["rows"] == 2
    assert summary["expressions"] is None
    assert summary["expression_claims"] == 4


def test_create_pre_release_backup_publishes_only_completed_archive(tmp_path, monkeypatch):
    def fake_run(command, **_kwargs):
        output_path = command[command.index("--file") + 1]
        with open(output_path, "wb") as handle:
            handle.write(b"custom-format-dump")
        return SimpleNamespace(returncode=0, stdout="", stderr="")

    monkeypatch.setattr(
        "scripts.dictionary.import_mapping_csv_pg.subprocess.run",
        fake_run,
    )

    backup = create_pre_release_backup("postgresql://example", tmp_path)

    assert backup.is_file()
    assert backup.stat().st_size > 0
    assert not list(tmp_path.glob("*.partial"))


def test_apply_requires_backup_destination_by_default(tmp_path, monkeypatch, capsys):
    manifest = write_snapshot(tmp_path / "apply", [["entry-1", "", "word", "語"]])
    monkeypatch.setenv("DATABASE_URL", "postgresql://example")
    monkeypatch.delenv("LANGMAP_PRE_RELEASE_BACKUP_DIR", raising=False)

    result = main(["--manifest", str(manifest), "--apply"])

    assert result == 2
    assert "pre-release backup is enabled" in capsys.readouterr().err
