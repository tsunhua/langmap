import json

import pytest

from scripts.dictionary.export_teochew_csv_jsonl import export_teochew_csv


def _records(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]


def test_export_splits_sources_and_preserves_selected_columns(tmp_path):
    source = tmp_path / "teochew.csv"
    source.write_text(
        "latn_norm,puj,dp,han,han_variants,en,zh_CN,zh_TW,source\n"
        "si-kue,Si-kue,,四,,Four,,四,001_Handbook_of_the_Swatow_Vernacular\n"
        "a,a,,阿,,A prefix,,字,003_First_Lessons_in_the_Tie-chiw_Dialect\n"
        "a,,a¹,亞,,,简,繁,dieghv\n",
        encoding="utf-8",
    )

    summary = export_teochew_csv(source, tmp_path / "jsonl")

    assert summary.entry_count == 3
    assert {item["source_profile"] for item in summary.files} == {"swatow", "chaozhou"}

    swatow_path = next(
        tmp_path.joinpath("jsonl").glob("*001-handbook-of-the-swatow-vernacular.jsonl")
    )
    swatow = _records(swatow_path)
    assert swatow[0]["source_value"] == "001_Handbook_of_the_Swatow_Vernacular"
    assert swatow[1]["raw_headword"] == "Si-kue"
    assert swatow[1]["canonical_headword"] == "Si-kue"
    assert swatow[1]["direction_hint"] == "nan-Latn-CN_Swatow-to-eng"
    assert swatow[1]["mappings"] == [
        {"language_hint": "nan-Hant-CN_Swatow", "source_column": "han", "value": "四"},
        {"language_hint": "eng-Latn-US", "source_column": "en", "value": "Four"},
        {"language_hint": "cmn-Hant-TW", "source_column": "zh_TW", "value": "四"},
    ]

    chaozhou_path = next(tmp_path.joinpath("jsonl").glob("*dieghv.jsonl"))
    chaozhou = _records(chaozhou_path)
    assert chaozhou[1]["raw_headword"] == "a¹"
    assert chaozhou[1]["direction_hint"] == "nan-Latn-CN_Chaozhou_DP-to-eng"
    assert chaozhou[1]["mappings"] == [
        {"language_hint": "nan-Hant-CN_Chaozhou", "source_column": "han", "value": "亞"},
        {"language_hint": "cmn-Hant-TW", "source_column": "zh_TW", "value": "繁"},
        {"language_hint": "cmn-Hans-CN", "source_column": "zh_CN", "value": "简"},
    ]
    assert "latn_norm" not in chaozhou[1]


def test_empty_source_is_the_swatow_ssmp_profile(tmp_path):
    source = tmp_path / "teochew.csv"
    source.write_text(
        "puj,dp,han,en,zh_TW,zh_CN,source\n"
        "a,,,meaning,,,\n",
        encoding="utf-8",
    )

    summary = export_teochew_csv(source, tmp_path / "jsonl")

    assert summary.files[0]["source_key"] == "org.hokkien-writing.ssmp"
    records = _records(tmp_path / "jsonl" / "org.hokkien-writing.ssmp.jsonl")
    assert records[0]["source_profile"] == "swatow"
    assert records[1]["direction_hint"] == "nan-Latn-CN_Swatow-to-eng"


def test_unknown_source_fails_closed(tmp_path):
    source = tmp_path / "teochew.csv"
    source.write_text(
        "puj,dp,han,en,zh_TW,zh_CN,source\n"
        "a,,,meaning,,,new-source\n",
        encoding="utf-8",
    )

    with pytest.raises(ValueError, match="unknown source"):
        export_teochew_csv(source, tmp_path / "jsonl")


def test_export_refuses_overwrite(tmp_path):
    source = tmp_path / "teochew.csv"
    source.write_text(
        "puj,dp,han,en,zh_TW,zh_CN,source\n"
        "a,,,meaning,,,teochew\n",
        encoding="utf-8",
    )
    output_dir = tmp_path / "jsonl"
    export_teochew_csv(source, output_dir)

    with pytest.raises(FileExistsError):
        export_teochew_csv(source, output_dir)
