import csv
from pathlib import Path

from import_mappings import parse_column, read_rows


def test_parse_dictionary_headers():
    assert parse_column("cmn-Hant（華語繁體）", {}) is not None
    assert parse_column("eng_definition（英文釋義）", {}) is None
    assert parse_column("", {}) is None


def test_read_rows_ignores_definitions_and_empty_values(tmp_path: Path):
    path = tmp_path / "dictionary.csv"
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow(["cmn-Hant（繁體）", "eng（英文）", "eng_definition（釋義）"])
        writer.writerow(["你好", "hello", "問候語"])
        writer.writerow(["只有中文", "", ""])

    columns, rows = read_rows(path, {}, "utf-8", "cmn-Hant-TW")
    assert [column.lang_code for column in columns] == ["cmn", "eng"]
    assert list(rows) == [{
        "expressions": [
            {"lang_code": "cmn", "text": "你好"},
            {"lang_code": "eng", "text": "hello"},
        ],
        "readings": [],
    }]


def test_dictionary_profiles_can_attach_exact_locales(tmp_path: Path):
    path = tmp_path / "profiles.csv"
    path.write_text("cmn-Hant,eng\n你好,hello\n", encoding="utf-8")
    _, rows = read_rows(path, {"cmn-Hant": "cmn-Hant-TW", "eng": "eng-Latn-US"}, "utf-8", "cmn-Hant-TW")
    assert list(rows) == [{
        "expressions": [
            {"lang_code": "cmn", "text": "你好", "language_locale_code": "cmn-Hant-TW"},
            {"lang_code": "eng", "text": "hello", "language_locale_code": "eng-Latn-US"},
        ],
        "readings": [],
    }]


def test_readings_are_separate_from_expressions(tmp_path: Path):
    path = tmp_path / "readings.csv"
    path.write_text("cmn-Hant,cmn-Bopo-zhuyin,cmn-Latn-pinyin,eng\n你好,ㄋㄧˇ ㄏㄠˇ,ni3 hao3,hello\n", encoding="utf-8")
    _, rows = read_rows(path, {}, "utf-8", "cmn-Hant-TW")
    assert list(rows) == [{
        "expressions": [{"lang_code": "cmn", "text": "你好"}, {"lang_code": "eng", "text": "hello"}],
        "readings": [
            {"scheme": "zhuyin", "value": "ㄋㄧˇ ㄏㄠˇ", "language_locale_code": "cmn-Hant-TW"},
            {"scheme": "pinyin", "value": "ni3 hao3", "language_locale_code": "cmn-Hant-TW"},
        ],
    }]


def test_pipe_separates_multiple_expressions_and_readings(tmp_path: Path):
    path = tmp_path / "pipes.csv"
    path.write_text("cmn-Hant,cmn-Bopo-zhuyin,eng\n時髦的 | 流行的,ㄕˊ ㄇㄠˊ | ㄌㄧㄡˊ ㄒㄧㄥˊ,fashionable | trendy\n", encoding="utf-8")
    _, rows = read_rows(path, {"cmn-Hant": "cmn-Hant-TW"}, "utf-8", "cmn-Hant-TW")
    row = list(rows)[0]
    assert [item["text"] for item in row["expressions"]] == ["時髦的", "流行的", "fashionable", "trendy"]
    assert [item["value"] for item in row["readings"]] == ["ㄕˊ ㄇㄠˊ", "ㄌㄧㄡˊ ㄒㄧㄥˊ"]
