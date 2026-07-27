#!/usr/bin/env python3
"""將 expressions.csv + expression_meaning.csv 依語言代碼樞紐成寬表 CSV。

用法：
    python3 pivot_by_language.py \
        --expressions expressions.csv \
        --meanings expression_meaning.csv \
        --langs cieh-tc emoji image ral zyg-jx swh wuu-sh \
        --ref en zh-TW zh-CN \
        -o pivot.csv
"""

from __future__ import annotations

import argparse
import csv
import sys
from collections import defaultdict
from pathlib import Path


EN_FALLBACK = ("en-US", "en-GB")


def load_expressions(path: Path) -> dict[str, dict[str, str]]:
    out: dict[str, dict[str, str]] = {}
    with path.open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            out[row["id"]] = row
    return out


def load_meaning_index(
    path: Path,
) -> tuple[dict[str, list[str]], set[str]]:
    """回傳 (meaning_id -> [expression_id], 所有出現過的 expression_id)。"""
    m2e: dict[str, list[str]] = defaultdict(list)
    linked: set[str] = set()
    with path.open(encoding="utf-8", newline="") as f:
        for row in csv.DictReader(f):
            mid = row["meaning_id"]
            eid = row["expression_id"]
            if eid:
                linked.add(eid)
            if mid and eid:
                m2e[mid].append(eid)
    return m2e, linked


def match_lang(row_lc: str, wanted: str) -> bool:
    if wanted == "en":
        return row_lc in EN_FALLBACK
    return row_lc == wanted


def gather_texts(
    expr_ids: list[str],
    exprs: dict[str, dict[str, str]],
    lang: str,
) -> str:
    hits: list[tuple[int, str, str]] = []
    for eid in expr_ids:
        row = exprs.get(eid)
        if not row:
            continue
        if match_lang(row["language_code"], lang):
            try:
                order = int(eid)
            except ValueError:
                order = 0
            # 對 "en" 欄：en-US 優先於 en-GB
            lang_rank = 0
            if lang == "en":
                lang_rank = 0 if row["language_code"] == "en-US" else 1
            hits.append((lang_rank, order, row["text"]))
    if not hits:
        return ""
    hits.sort()
    return "|".join(text for _, _, text in hits)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--expressions", required=True)
    p.add_argument("--meanings", required=True)
    p.add_argument("--langs", nargs="+", required=True, help="目標語言代碼")
    p.add_argument("--ref", nargs="*", default=[], help="參考語言代碼")
    p.add_argument("-o", "--output", required=True)
    args = p.parse_args()

    exprs = load_expressions(Path(args.expressions))
    m2e, linked = load_meaning_index(Path(args.meanings))

    targets = set(args.langs)
    all_langs = sorted(set(args.langs) | set(args.ref))
    header = list(all_langs)

    written = 0
    orphan = 0
    out_path = Path(args.output)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f, quoting=csv.QUOTE_MINIMAL, lineterminator="\n")
        w.writerow(header)

        # 1. 以 meaning 聚合
        for mid, eids in m2e.items():
            langs_in_meaning = {
                exprs[e]["language_code"] for e in eids if e in exprs
            }
            has_target = any(
                any(match_lang(lc, t) for lc in langs_in_meaning) for t in targets
            )
            if not has_target:
                continue
            row = [gather_texts(eids, exprs, lang) for lang in all_langs]
            w.writerow(row)
            written += 1

        # 2. 沒有 meaning 關聯的目標語言 expression
        for eid, row in exprs.items():
            if row["meaning_id"] or eid in linked:
                continue
            lc = row["language_code"]
            hit_lang = next((t for t in targets if match_lang(lc, t)), None)
            if not hit_lang:
                continue
            out = [row["text"] if lang == hit_lang else "" for lang in all_langs]
            w.writerow(out)
            orphan += 1

    print(f"[write] {out_path}  meaning_rows={written}  orphan_rows={orphan}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
