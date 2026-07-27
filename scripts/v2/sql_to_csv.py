#!/usr/bin/env python3
"""
將僅含 `INSERT INTO "table" (cols) VALUES(...)` 的 SQL dump 轉為 CSV。

用法：
    python3 sql_to_csv.py <input.sql> [more.sql ...] [-o out_dir]

- 自動掃描每個檔案中出現的 table 與欄位，動態建立 TEXT 欄位的臨時表。
- 使用 SQLite in-memory DB 執行 INSERT，因此支援 `replace(..., '\\n', char(10))`
  等內建函式呼叫。
- 每張表輸出到 `<out_dir>/<table>.csv`；同一次執行中重複的表會累加匯入。
- 預設 out_dir 為第一個輸入檔所在目錄。
"""

from __future__ import annotations

import argparse
import csv
import re
import sqlite3
import sys
from pathlib import Path


INSERT_HEADER_RE = re.compile(
    r'INSERT\s+INTO\s+"([^"]+)"\s*\(([^)]*)\)\s*VALUES',
    re.IGNORECASE,
)


def parse_columns(cols_sql: str) -> list[str]:
    return [c.strip().strip('"') for c in cols_sql.split(",")]


def scan_schema(sql_text: str) -> dict[str, list[str]]:
    """回傳 {table: columns}，同表若欄位不同則以第一次見到的為準。"""
    schema: dict[str, list[str]] = {}
    for m in INSERT_HEADER_RE.finditer(sql_text):
        table = m.group(1)
        cols = parse_columns(m.group(2))
        if table not in schema:
            schema[table] = cols
    return schema


def ensure_tables(conn: sqlite3.Connection, schema: dict[str, list[str]]) -> None:
    for table, cols in schema.items():
        quoted = ", ".join(f'"{c}" TEXT' for c in cols)
        conn.execute(f'CREATE TABLE IF NOT EXISTS "{table}" ({quoted})')


def export_table(conn: sqlite3.Connection, table: str, out_path: Path) -> int:
    cur = conn.execute(f'SELECT * FROM "{table}"')
    cols = [d[0] for d in cur.description]
    count = 0
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        w.writerow(cols)
        for row in cur:
            w.writerow(["" if v is None else v for v in row])
            count += 1
    return count


def load_sql_file(conn: sqlite3.Connection, sql_path: Path) -> set[str]:
    text = sql_path.read_text(encoding="utf-8")
    schema = scan_schema(text)
    if not schema:
        print(f"[warn] {sql_path.name}: 找不到 INSERT INTO 語句", file=sys.stderr)
        return set()
    ensure_tables(conn, schema)
    conn.executescript(text)
    return set(schema.keys())


def main() -> int:
    parser = argparse.ArgumentParser(description="SQL dump → CSV")
    parser.add_argument("inputs", nargs="+", help="SQL 檔案路徑")
    parser.add_argument(
        "-o",
        "--out-dir",
        default=None,
        help="CSV 輸出目錄，預設為第一個輸入檔所在目錄",
    )
    args = parser.parse_args()

    inputs = [Path(p).resolve() for p in args.inputs]
    for p in inputs:
        if not p.is_file():
            print(f"[error] 找不到檔案：{p}", file=sys.stderr)
            return 1

    out_dir = Path(args.out_dir).resolve() if args.out_dir else inputs[0].parent
    out_dir.mkdir(parents=True, exist_ok=True)

    conn = sqlite3.connect(":memory:")
    conn.execute("PRAGMA foreign_keys=OFF")
    conn.execute("PRAGMA defer_foreign_keys=ON")

    touched: set[str] = set()
    for path in inputs:
        print(f"[load] {path}")
        touched |= load_sql_file(conn, path)

    for table in sorted(touched):
        out_path = out_dir / f"{table}.csv"
        n = export_table(conn, table, out_path)
        print(f"[write] {out_path}  rows={n}")

    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
