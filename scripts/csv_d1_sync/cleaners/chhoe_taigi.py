from __future__ import annotations

import csv
from pathlib import Path

from .base import (
    CleanResult,
    CsvCleaner,
    expand_parenthetical_variants,
    join_variants,
    normalize_text,
    remove_trailing_supplement,
    split_and_normalize,
    split_outside_parentheses,
)


class ChhoeTaigiTaioanPehoeKichhooGikuCleaner(CsvCleaner):
    name = "chhoe-taigi"
    headers = ["nan-TW-Latn-pehoeji", "nan-TW-Latn-tailo", "zh-Hant-TW", "en-US"]
    required_columns = {
        "PojUnicode",
        "PojUnicodeOthers",
        "KipUnicode",
        "KipUnicodeOthers",
        "HoaBun",
        "EngBun",
        "LekuPoj",
        "LekuHoabun",
        "LekuEngbun",
    }

    def clean(self, source: Path) -> CleanResult:
        output: list[dict[str, str]] = []
        source_rows = 0
        with source.open("r", encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream)
            missing = sorted(self.required_columns - set(reader.fieldnames or []))
            if missing:
                raise ValueError(f"ChhoeTaigi CSV 缺少欄位：{', '.join(missing)}")

            for source_rows, row in enumerate(reader, start=1):
                word_row = self._word_row(row)
                if sum(bool(value) for value in word_row.values()) >= 2:
                    output.append(word_row)
                output.extend(self._example_rows(row))

        return CleanResult(self.headers, output, source_rows)

    def _word_row(self, row: dict[str, str]) -> dict[str, str]:
        poj = normalize_text(row.get("PojUnicode"))
        if poj.startswith(("'", '"')):
            poj = ""
        values = {
            "nan-TW-Latn-pehoeji": list(
                dict.fromkeys(
                    ([poj] if poj else [])
                    + split_and_normalize(
                        row.get("PojUnicodeOthers"), r"[/\\／]"
                    )
                )
            ),
            "nan-TW-Latn-tailo": list(
                dict.fromkeys(
                    split_and_normalize(row.get("KipUnicode"), r"[/\\／,，、]")
                    + split_and_normalize(
                        row.get("KipUnicodeOthers"), r"[/\\／,，、]"
                    )
                )
            ),
            "zh-Hant-TW": [
                variant
                for piece in split_outside_parentheses(
                    row.get("HoaBun"), "/\\／,，、"
                )
                for variant in expand_parenthetical_variants(piece)
            ],
            "en-US": [
                cleaned
                for value in split_outside_parentheses(
                    row.get("EngBun"), "/\\／,，、;"
                )
                if (cleaned := remove_trailing_supplement(value))
            ],
        }
        return {
            header: join_variants(values[header])
            for header in self.headers
        }

    def _example_rows(self, row: dict[str, str]) -> list[dict[str, str]]:
        groups = {
            "nan-TW-Latn-pehoeji": split_and_normalize(row.get("LekuPoj"), r"[/\\／]"),
            "zh-Hant-TW": split_and_normalize(row.get("LekuHoabun"), r"[/\\／]"),
            "en-US": [
                cleaned
                for value in split_and_normalize(
                    row.get("LekuEngbun"), r"[/\\／]"
                )
                if (cleaned := remove_trailing_supplement(value))
            ],
        }
        count = max((len(values) for values in groups.values()), default=0)
        output = []
        for index in range(count):
            cleaned = {
                language: values[index] if index < len(values) else ""
                for language, values in groups.items()
            }
            cleaned["nan-TW-Latn-tailo"] = ""
            ordered = {header: cleaned.get(header, "") for header in self.headers}
            if sum(bool(value) for value in ordered.values()) >= 2:
                output.append(ordered)
        return output
