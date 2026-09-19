from __future__ import annotations

import csv
import importlib.util
import json
from pathlib import Path

import pytest


MODULE_PATH = Path(__file__).with_name("generate-ui-csv.py")
SPEC = importlib.util.spec_from_file_location("generate_ui_csv", MODULE_PATH)
assert SPEC and SPEC.loader
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def test_normalize_writes_one_wide_csv_and_manifest(tmp_path: Path) -> None:
    source = tmp_path / "input.csv"
    source.write_text(
        "ENTRY_ID,NOTE,LOCALE_eng-Latn-US,LOCALE_jpn-Jpan-JP\n"
        "b,,B,ビー\n"
        "a,,A,エー\n",
        encoding="utf-8",
    )

    output = tmp_path / "out" / "ui-locales.csv"
    manifest_path = tmp_path / "out" / "ui-locales.manifest.json"
    locales, count = MODULE.normalize_csv(source, output)
    manifest = MODULE.write_manifest(manifest_path, output, locales, count)

    with output.open(encoding="utf-8", newline="") as handle:
        assert list(csv.reader(handle)) == [
            ["ENTRY_ID", "NOTE", "LOCALE_eng-Latn-US", "LOCALE_jpn-Jpan-JP"],
            ["a", "", "A", "エー"],
            ["b", "", "B", "ビー"],
        ]
    assert manifest["entry_count"] == 2
    assert json.loads(manifest_path.read_text(encoding="utf-8"))["source_key"] == "system-ui"


def test_normalize_rejects_rows_without_two_locales(tmp_path: Path) -> None:
    source = tmp_path / "input.csv"
    source.write_text("ENTRY_ID,NOTE,LOCALE_eng-Latn-US,LOCALE_jpn-Jpan-JP\na,,A,\n", encoding="utf-8")

    with pytest.raises(MODULE.UiCsvError, match="two locale"):
        MODULE.normalize_csv(source, tmp_path / "out" / "ui-locales.csv")
