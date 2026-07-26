#!/usr/bin/env python3
"""執行資料集專屬清洗，輸出標準的多語 CSV。"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

from cleaners import ChhoeTaigiTaioanPehoeKichhooGikuCleaner, CsvCleaner


CLEANERS: dict[str, type[CsvCleaner]] = {
    ChhoeTaigiTaioanPehoeKichhooGikuCleaner.name:
        ChhoeTaigiTaioanPehoeKichhooGikuCleaner,
}


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(description="把來源 CSV 清洗成語言代碼表頭的標準 CSV。")
    root.add_argument("cleaner", choices=sorted(CLEANERS))
    root.add_argument("source", type=Path)
    root.add_argument("output", type=Path)
    return root


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    source = args.source.resolve()
    output = args.output.resolve()
    if not source.is_file():
        raise FileNotFoundError(f"找不到來源 CSV：{source}")
    if source == output:
        raise ValueError("輸出不可覆蓋來源 CSV")

    result = CLEANERS[args.cleaner]().clean(source)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=result.headers)
        writer.writeheader()
        writer.writerows(result.rows)

    print(
        f"清洗完成：來源 {result.source_rows} 列，標準 CSV {len(result.rows)} 列\n"
        f"輸出：{output}",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError) as error:
        print(f"錯誤：{error}", file=sys.stderr)
        raise SystemExit(1)
