import csv
import hashlib
import json

from scripts.dictionary.import_mapping_csv_pg import CsvContractError, validate


def write_snapshot(tmp_path, rows, *, locales=None):
    csv_path = tmp_path / "data.csv"
    with csv_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["ENTRY_ID", "NOTE", "LOCALE_eng-Latn-US", "LOCALE_jpn-Jpan-JP"])
        writer.writerows(rows)
    payload = {
        "schema_version": 1,
        "source_key": "fixture:csv",
        "csv": "data.csv",
        "csv_sha256": hashlib.sha256(csv_path.read_bytes()).hexdigest(),
        "locales": locales or {
            "eng-Latn-US": {"name": "English", "name_en": "English (US)"},
            "jpn-Jpan-JP": {"name": "日本語", "name_en": "Japanese (Japan)"},
        },
    }
    manifest = tmp_path / "manifest.json"
    manifest.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
    return manifest


def test_validate_counts_same_language_and_cross_language_pairs(tmp_path):
    manifest = write_snapshot(tmp_path, [["entry-1", "note", "word|term", "語"]])

    summary = validate(manifest)

    assert summary["rows"] == 1
    assert summary["expressions"] == 3
    assert summary["edges"] == 3


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
            "READING_jpn-Jpan-JP_hepburn",
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
        "reading_columns": [{"locale": "jpn-Jpan-JP", "scheme": "hepburn"}],
        "locale_metadata": {
            "eng-Latn-US": {"name": "English", "name_en": "English (US)"},
            "jpn-Jpan-JP": {"name": "日本語", "name_en": "Japanese (Japan)"},
        },
    }, ensure_ascii=False), encoding="utf-8")

    summary = validate(manifest)

    assert summary["readings"] == 2
    assert summary["edges"] == 1


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
