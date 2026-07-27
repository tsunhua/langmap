#!/usr/bin/env python3
"""從 CSV 抽取詞句與映射，批次同步到 LangMap v2 D1。"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from itertools import combinations
from pathlib import Path

LANGUAGE_CODE = re.compile(r"^[A-Za-z]{1,3}(?:-[A-Za-z0-9]{1,8})*$")
VARIANT_SEPARATOR = " | "
LANGUAGE_ID_BITS = 16
TEXT_ID_BITS = 37
TEXT_ID_MASK = (1 << TEXT_ID_BITS) - 1


@dataclass(frozen=True)
class ColumnSpec:
    column: str
    language: str


@dataclass(frozen=True)
class Expression:
    id: int
    text: str
    language: str


@dataclass(frozen=True)
class Edge:
    id: str
    expression_a_id: int
    expression_b_id: int


def hash_segment(content: str, bits: int) -> int:
    digest = hashlib.sha256(content.encode("utf-8")).digest()
    return (int.from_bytes(digest[:8], "big") % ((1 << bits) - 1)) + 1


def language_prefix_id(language_code: str) -> int:
    return hash_segment(language_code, LANGUAGE_ID_BITS)


def text_segment_id(text: str) -> int:
    return hash_segment(text, TEXT_ID_BITS)


def expression_id(language_code: str, text: str) -> int:
    return (language_prefix_id(language_code) << TEXT_ID_BITS) | text_segment_id(
        text
    )


def expression_id_segments(value: int) -> tuple[int, int]:
    return value >> TEXT_ID_BITS, value & TEXT_ID_MASK


def stable_edge_id(expression_a_id: int, expression_b_id: int) -> str:
    left, right = sorted((expression_a_id, expression_b_id))
    return f"{left}-{right}"


def infer_column_specs(csv_path: Path) -> list[ColumnSpec]:
    with csv_path.open("r", encoding="utf-8-sig", newline="") as source:
        headers = csv.DictReader(source).fieldnames or []
    specs = [
        ColumnSpec(header.strip(), header.strip()) for header in headers if header.strip()
    ]
    if not specs:
        raise ValueError("CSV 沒有表頭")
    invalid = [spec.column for spec in specs if not LANGUAGE_CODE.fullmatch(spec.column)]
    if invalid:
        raise ValueError(
            "CSV 表頭必須是語言代碼；請先執行對應 cleaner。"
            f" 不規範表頭：{', '.join(invalid)}"
        )
    return specs


def split_values(value: str) -> list[str]:
    return list(
        dict.fromkeys(
            text
            for part in value.split(VARIANT_SEPARATOR)
            if (text := part.strip())
        )
    )


def extract(
    csv_path: Path, specs: list[ColumnSpec]
) -> tuple[list[Expression], list[Edge], int]:
    language_prefixes: dict[int, str] = {}
    for spec in specs:
        prefix = language_prefix_id(spec.language)
        previous_language = language_prefixes.get(prefix)
        if previous_language is not None and previous_language != spec.language:
            raise ValueError(
                f"語言 ID 前綴碰撞：{previous_language!r} 與 "
                f"{spec.language!r} 都是 {prefix}"
            )
        language_prefixes[prefix] = spec.language

    expressions: dict[tuple[str, str], Expression] = {}
    ids: dict[int, tuple[str, str]] = {}
    edges: dict[tuple[int, int], Edge] = {}
    row_count = 0

    with csv_path.open("r", encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        headers = set(reader.fieldnames or [])
        missing = [spec.column for spec in specs if spec.column not in headers]
        if missing:
            raise ValueError(f"CSV 缺少欄位：{', '.join(missing)}")

        for row_count, row in enumerate(reader, start=1):
            row_expressions: dict[int, Expression] = {}
            for spec in specs:
                for text in split_values(row.get(spec.column, "")):
                    key = (text, spec.language)
                    expr_id = expression_id(spec.language, text)
                    previous = ids.get(expr_id)
                    if previous is not None and previous != key:
                        raise ValueError(
                            f"穩定 ID 碰撞：{previous!r} 與 {key!r} 都是 {expr_id}"
                        )
                    ids[expr_id] = key
                    expression = expressions.setdefault(
                        key, Expression(expr_id, text, spec.language)
                    )
                    row_expressions[expression.id] = expression

            for left, right in combinations(sorted(row_expressions), 2):
                edge_key = (left, right)
                edges.setdefault(edge_key, Edge(stable_edge_id(left, right), left, right))

    return (
        sorted(expressions.values(), key=lambda item: item.id),
        sorted(edges.values(), key=lambda item: (item.expression_a_id, item.expression_b_id)),
        row_count,
    )


def sql_string(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def chunks(items: list, size: int):
    for start in range(0, len(items), size):
        yield items[start : start + size]


def load_lang_mapping(path: Path, value_column: str) -> dict[str, str]:
    with path.open("r", encoding="utf-8-sig", newline="") as source:
        reader = csv.DictReader(source)
        headers = {name.strip() for name in (reader.fieldnames or [])}
        if {"lang", value_column} - headers:
            raise ValueError(f"CSV 需要 lang,{value_column} 欄位：{path}")
        mapping: dict[str, str] = {}
        for row in reader:
            lang = (row.get("lang") or "").strip()
            value = (row.get(value_column) or "").strip()
            if not lang or not value:
                continue
            if lang in mapping and mapping[lang] != value:
                raise ValueError(
                    f"CSV 對 {lang} 的 {value_column} 有衝突：{mapping[lang]} / {value}"
                )
            mapping[lang] = value
    return mapping


def load_lang_tags(path: Path) -> dict[str, str]:
    return load_lang_mapping(path, "tag")


def load_lang_authors(path: Path) -> dict[str, str]:
    return load_lang_mapping(path, "created_by")


def write_sql_batches(
    output_dir: Path,
    expressions: list[Expression],
    edges: list[Edge],
    batch_size: int,
    source_type: str,
    source_ref: str,
    tag: str | None,
    lang_tags: dict[str, str] | None,
    default_created_by: str,
    lang_authors: dict[str, str] | None,
) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    for old_file in output_dir.glob("*.sql"):
        old_file.unlink()

    files: list[Path] = []
    default_tags = json.dumps([tag], ensure_ascii=False) if tag else None

    def tags_for(language: str) -> str | None:
        if lang_tags:
            per_lang = lang_tags.get(language)
            return json.dumps([per_lang], ensure_ascii=False) if per_lang else None
        return default_tags

    def created_by_for(language: str) -> str:
        if lang_authors:
            return lang_authors.get(language, default_created_by)
        return default_created_by

    for index, batch in enumerate(chunks(expressions, batch_size), start=1):
        path = output_dir / f"expressions-{index:04d}.sql"
        values = []
        for expression in batch:
            tags = tags_for(expression.language)
            values.append(
                "("
                + ", ".join(
                    [
                        str(expression.id),
                        sql_string(expression.text),
                        sql_string(expression.language),
                        sql_string(source_type),
                        sql_string(source_ref),
                        "'approved'",
                        sql_string(created_by_for(expression.language)),
                        "NULL" if tags is None else sql_string(tags),
                    ]
                )
                + ")"
            )
        path.write_text(
            "INSERT OR IGNORE INTO expressions "
            "(id, text, language_code, source_type, source_ref, review_status, created_by, tags) VALUES\n"
            + ",\n".join(values)
            + ";\n",
            encoding="utf-8",
        )
        files.append(path)

    for index, batch in enumerate(chunks(edges, batch_size), start=1):
        path = output_dir / f"edges-{index:04d}.sql"
        values = [
            f"({sql_string(edge.id)}, {edge.expression_a_id}, {edge.expression_b_id}, "
            f"0, 'batch', {sql_string(default_created_by)})"
            for edge in batch
        ]
        path.write_text(
            "INSERT OR IGNORE INTO expression_edges "
            "(id, expression_a_id, expression_b_id, score, source, created_by) VALUES\n"
            + ",\n".join(values)
            + ";\n",
            encoding="utf-8",
        )
        files.append(path)

    manifest = {
        "expressions": len(expressions),
        "edges": len(edges),
        "batches": [path.name for path in files],
    }
    (output_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return files


def wrangler_command(
    config: Path,
    database: str,
    sql_file: Path,
    remote: bool,
    persist_to: Path | None,
) -> list[str]:
    command = [
        "npx",
        "wrangler",
        "d1",
        "execute",
        database,
        "--config",
        str(config),
        "--file",
        str(sql_file),
        "--yes",
        "--remote" if remote else "--local",
    ]
    if persist_to is not None:
        command.extend(["--persist-to", str(persist_to)])
    return command


def wrangler_query_command(
    config: Path,
    database: str,
    query: str,
    remote: bool,
    persist_to: Path | None,
) -> list[str]:
    command = [
        "npx",
        "wrangler",
        "d1",
        "execute",
        database,
        "--config",
        str(config),
        "--command",
        query,
        "--json",
        "--remote" if remote else "--local",
    ]
    if persist_to is not None:
        command.extend(["--persist-to", str(persist_to)])
    return command


def parse_schema_counts(payload: str) -> tuple[int, int]:
    results = json.loads(payload)
    entries = results if isinstance(results, list) else results.get("result", [])
    rows = [
        row
        for entry in entries
        for row in entry.get("results", [])
    ]
    if not rows:
        raise ValueError("Wrangler schema 查詢沒有回傳結果")
    return int(rows[0]["table_count"]), int(rows[0]["required_count"])


def query_schema_counts(
    config: Path,
    database: str,
    remote: bool,
    persist_to: Path | None,
) -> tuple[int, int]:
    query = (
        "SELECT COUNT(*) AS table_count, "
        "COUNT(CASE WHEN name IN ('expressions','expression_edges') THEN 1 END) "
        "AS required_count FROM sqlite_schema "
        "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
        "AND name NOT LIKE '_cf_%';"
    )
    result = subprocess.run(
        wrangler_query_command(config, database, query, remote, persist_to),
        check=True,
        cwd=config.parent,
        capture_output=True,
        text=True,
    )
    return parse_schema_counts(result.stdout)


def ensure_target_schema(
    config: Path,
    database: str,
    remote: bool,
    persist_to: Path | None,
) -> None:
    table_count, required_count = query_schema_counts(
        config, database, remote, persist_to
    )
    if required_count == 2:
        return
    if remote:
        raise RuntimeError(
            "remote D1 缺少 expressions/expression_edges；請先執行 v2 setup"
        )
    if table_count:
        raise RuntimeError(
            "local D1 已有資料表但缺少完整 v2 schema；為避免覆寫，不會自動初始化"
        )

    schema = config.parent / "schema.sql"
    if not schema.is_file():
        raise RuntimeError(f"找不到 local 初始化 schema：{schema}")
    print("local D1 為空，正在初始化 backend/schema.sql", file=sys.stderr)
    subprocess.run(
        wrangler_command(config, database, schema, False, persist_to),
        check=True,
        cwd=config.parent,
    )
    _, required_count = query_schema_counts(config, database, False, persist_to)
    if required_count != 2:
        raise RuntimeError("local D1 schema 初始化後仍缺少必要資料表")


def resolve_persist_to(
    config: Path, remote: bool, persist_to: Path | None
) -> Path | None:
    if remote:
        return None
    if persist_to is not None:
        return persist_to.resolve()
    return (config.parent / ".wrangler" / "state").resolve()


def sync_batches(
    files: list[Path],
    config: Path,
    database: str,
    remote: bool,
    persist_to: Path | None,
    start_batch: int = 1,
) -> None:
    if shutil.which("npx") is None:
        raise RuntimeError("找不到 npx")
    if start_batch > 1:
        if start_batch > len(files):
            raise ValueError(f"--start-batch {start_batch} 超出批次數 {len(files)}")
        files = files[start_batch - 1 :]
    ensure_target_schema(config, database, remote, persist_to)
    for index, sql_file in enumerate(files, start=start_batch):
        print(f"[{index}/{start_batch + len(files) - 1}] 同步 {sql_file.name}", file=sys.stderr)
        subprocess.run(
            wrangler_command(config, database, sql_file, remote, persist_to),
            check=True,
            cwd=config.parent,
        )


def load_existing_batches(output_dir: Path) -> list[Path] | None:
    expressions = sorted(output_dir.glob("expressions-*.sql"))
    edges = sorted(output_dir.glob("edges-*.sql"))
    files = expressions + edges
    if not files:
        return None
    manifest_path = output_dir / "manifest.json"
    if not manifest_path.is_file():
        return None
    return files


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(
        description="從 CSV 抽取同列詞句並建立兩兩映射，批次同步到 LangMap v2 D1。"
    )
    root.add_argument("csv", type=Path)
    root.add_argument("--database", default="langmap-v2")
    root.add_argument(
        "--config",
        type=Path,
        default=Path(__file__).resolve().parents[2] / "backend" / "wrangler.jsonc",
    )
    target = root.add_mutually_exclusive_group(required=True)
    target.add_argument("--local", action="store_true")
    target.add_argument("--remote", action="store_true")
    root.add_argument("--persist-to", type=Path)
    root.add_argument("--batch-size", type=int, default=500)
    root.add_argument("--source-type", default="dictionary")
    root.add_argument("--source-ref")
    root.add_argument("--tag")
    root.add_argument(
        "--lang-tags",
        type=Path,
        help="CSV（欄位 lang,tag）指定每個語言的 tag；存在時忽略 --tag。",
    )
    root.add_argument(
        "--created-by",
        default="system",
        help="expressions.created_by 的預設值；per-lang 未指定時使用。",
    )
    root.add_argument(
        "--lang-authors",
        type=Path,
        help="CSV（欄位 lang,created_by）指定每個語言的 created_by；未列出的語言 fallback 到 --created-by。",
    )
    root.add_argument(
        "--output-dir",
        type=Path,
        help="保留生成的 SQL；省略時使用臨時目錄並在結束後刪除。已存在 SQL 時會重複使用。",
    )
    root.add_argument(
        "--start-batch",
        type=int,
        default=1,
        help="從第 N 批開始同步（斷點續傳）；搭配 --output-dir 使用。",
    )
    root.add_argument("--dry-run", action="store_true", help="只生成 SQL，不執行 Wrangler。")
    return root


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    if args.batch_size < 1:
        raise ValueError("--batch-size 必須大於 0")
    if args.start_batch < 1:
        raise ValueError("--start-batch 必須大於 0")
    if args.start_batch > 1 and not args.output_dir:
        raise ValueError("--start-batch 必須搭配 --output-dir，否則無法斷點續傳")

    csv_path = args.csv.resolve()
    if not csv_path.is_file():
        raise FileNotFoundError(f"找不到 CSV：{csv_path}")
    config = args.config.resolve()
    if not config.is_file():
        raise FileNotFoundError(f"找不到 Wrangler config：{config}")
    persist_to = resolve_persist_to(config, args.remote, args.persist_to)

    existing_files: list[Path] | None = None
    if args.output_dir:
        output_dir = args.output_dir.resolve()
        if output_dir.is_dir():
            existing_files = load_existing_batches(output_dir)
            if existing_files:
                print(
                    f"找到既有 SQL {len(existing_files)} 個批次於 {output_dir}，重複使用（不重新抽取 CSV）",
                    file=sys.stderr,
                )

    lang_tags: dict[str, str] | None = None
    if args.lang_tags is not None:
        lang_tags_path = args.lang_tags.resolve()
        if not lang_tags_path.is_file():
            raise FileNotFoundError(f"找不到 lang-tags CSV：{lang_tags_path}")
        lang_tags = load_lang_tags(lang_tags_path)
        if args.tag:
            print("--lang-tags 已提供，忽略 --tag", file=sys.stderr)

    lang_authors: dict[str, str] | None = None
    if args.lang_authors is not None:
        lang_authors_path = args.lang_authors.resolve()
        if not lang_authors_path.is_file():
            raise FileNotFoundError(f"找不到 lang-authors CSV：{lang_authors_path}")
        lang_authors = load_lang_authors(lang_authors_path)

    if existing_files is not None:
        files = existing_files
    else:
        specs = infer_column_specs(csv_path)
        expressions, edges, rows = extract(csv_path, specs)
        source_ref = args.source_ref or csv_path.name
        print(
            f"抽取完成：CSV {rows} 列、詞句 {len(expressions)} 筆、映射 {len(edges)} 筆",
            file=sys.stderr,
        )
        if args.output_dir:
            output_dir = args.output_dir.resolve()
            files = write_sql_batches(
                output_dir,
                expressions,
                edges,
                args.batch_size,
                args.source_type,
                source_ref,
                args.tag,
                lang_tags,
                args.created_by,
                lang_authors,
            )
            print(f"SQL：{output_dir}", file=sys.stderr)
        else:
            with tempfile.TemporaryDirectory(prefix="langmap-csv-d1-") as temporary:
                output_dir = Path(temporary)
                files = write_sql_batches(
                    output_dir,
                    expressions,
                    edges,
                    args.batch_size,
                    args.source_type,
                    source_ref,
                    args.tag,
                    lang_tags,
                    args.created_by,
                    lang_authors,
                )
                if not args.dry_run:
                    sync_batches(
                        files, config, args.database, args.remote, persist_to,
                        start_batch=args.start_batch,
                    )
                else:
                    raise ValueError("--dry-run 必須搭配 --output-dir，否則生成結果會被刪除")
            return 0

    if not args.dry_run:
        sync_batches(
            files, config, args.database, args.remote, persist_to,
            start_batch=args.start_batch,
        )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError, subprocess.CalledProcessError) as error:
        print(f"錯誤：{error}", file=sys.stderr)
        raise SystemExit(1)
