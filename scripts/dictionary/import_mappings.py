#!/usr/bin/env python3
"""Import dictionary rows as LangMap contribution batches.

Input columns are language/profile labels such as ``cmn-Hant（華語繁體）`` and
``eng（英文）``. Columns ending in ``_definition`` are ignored. The script
only writes through the local LangMap API by default; use ``--dry-run`` to
inspect payloads without writing anything.
"""

from __future__ import annotations

import argparse
import csv
import getpass
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


DEFAULT_BASE_URL = "http://127.0.0.1:8788"
DEFAULT_BATCH_SIZE = 20
HEADER_RE = re.compile(r"^([A-Za-z][A-Za-z0-9]*(?:-[A-Za-z0-9]+)*)")


@dataclass(frozen=True)
class Column:
    index: int
    lang_code: str
    locale_code: str | None
    role: str = "expression"
    scheme: str | None = None


def parse_column(header: str, locale_map: dict[str, str]) -> Column | None:
    label = header.strip()
    if not label or re.match(r"^[A-Za-z0-9]+_definition(?:$|[（(])", label, re.IGNORECASE):
        return None
    match = HEADER_RE.match(label)
    if not match:
        return None
    profile = match.group(1)
    lang_code = profile.split("-", 1)[0].lower()
    if not re.fullmatch(r"[a-z0-9]{2,8}", lang_code):
        return None
    if lang_code == "cmn" and profile.lower().startswith("cmn-bopo"):
        return Column(-1, lang_code, locale_map.get(profile), "reading", "zhuyin")
    if lang_code == "cmn" and profile.lower().startswith("cmn-latn"):
        return Column(-1, lang_code, locale_map.get(profile), "reading", "pinyin")
    return Column(-1, lang_code, locale_map.get(profile), "expression")


def read_rows(path: Path, locale_map: dict[str, str], encoding: str, reading_locale: str) -> tuple[list[Column], Iterable[dict[str, list[dict[str, str]]]]]:
    handle = path.open("r", encoding=encoding, newline="")
    reader = csv.DictReader(handle)
    if not reader.fieldnames:
        handle.close()
        raise ValueError("CSV has no header row")

    columns: list[Column] = []
    for index, header in enumerate(reader.fieldnames):
        column = parse_column(header, locale_map)
        if column:
            columns.append(Column(index, column.lang_code, column.locale_code, column.role, column.scheme))

    if len(columns) < 2:
        handle.close()
        raise ValueError("CSV must contain at least two language columns")

    def rows() -> Iterable[dict[str, list[dict[str, str]]]]:
        try:
            for raw in reader:
                expressions: list[dict[str, str]] = []
                readings: list[dict[str, str]] = []
                for column in columns:
                    header = reader.fieldnames[column.index]
                    values = [value.strip() for value in (raw.get(header) or "").split("|") if value.strip()]
                    if not values:
                        continue
                    for text in values:
                        if column.role == "reading":
                            readings.append({"scheme": column.scheme or "unknown", "value": text, "language_locale_code": column.locale_code or reading_locale})
                        else:
                            item = {"lang_code": column.lang_code, "text": text}
                            if column.locale_code:
                                item["language_locale_code"] = column.locale_code
                            expressions.append(item)
                # Deduplicate identical language/text pairs within a row.
                unique = list({(item["lang_code"], item["text"]): item for item in expressions}.values())
                readings = list({(item["scheme"], item["value"], item["language_locale_code"]): item for item in readings}.values())
                if len(unique) >= 2:
                    yield {"expressions": unique, "readings": readings}
        finally:
            handle.close()

    return columns, rows()


def request_json(url: str, method: str, body: object | None = None, token: str | None = None) -> dict:
    data = None if body is None else json.dumps(body, ensure_ascii=False).encode("utf-8")
    headers = {"Accept": "application/json"}
    if data is not None:
        headers["Content-Type"] = "application/json"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed ({error.code}): {detail}") from error


def login(base_url: str, email: str, password: str) -> str:
    result = request_json(f"{base_url.rstrip('/')}/api/v2/auth/login", "POST", {"email": email, "password": password})
    token = result.get("data", {}).get("token")
    if not token:
        raise RuntimeError("Login response did not contain data.token")
    return str(token)


def expression_id(result: dict) -> str:
    value = result.get("data", {}).get("expression", {}).get("id")
    if not value:
        raise RuntimeError("Create expression response did not contain data.expression.id")
    return str(value)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_path", type=Path)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--token", help="Existing JWT; avoids login")
    parser.add_argument("--email", default="dev@example.com")
    parser.add_argument("--password", help="Login password; defaults to prompt")
    parser.add_argument("--locale-map", action="append", default=[], metavar="PROFILE=LOCALE")
    parser.add_argument("--batch-size", type=int, default=DEFAULT_BATCH_SIZE, help="Reserved for future multi-row API batching")
    parser.add_argument("--reading-locale", default="cmn-Hant-TW", help="Locale attached to zhuyin/pinyin readings")
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--max-rows", type=int)
    parser.add_argument("--encoding", default="utf-8-sig")
    parser.add_argument("--dry-run", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.batch_size < 2:
        raise SystemExit("--batch-size must be at least 2")
    locale_map: dict[str, str] = {
        "cmn-Hant": "cmn-Hant-TW",
        "eng": "eng-Latn-US",
    }
    for item in args.locale_map:
        profile, separator, locale = item.partition("=")
        if not separator or not profile or not locale:
            raise SystemExit(f"Invalid --locale-map: {item!r}; expected PROFILE=LOCALE")
        locale_map[profile] = locale

    columns, row_iter = read_rows(args.csv_path, locale_map, args.encoding, args.reading_locale)
    rows = list(row_iter)
    rows = rows[args.offset:]
    if args.max_rows is not None:
        rows = rows[:args.max_rows]
    print(json.dumps({"columns": [column.lang_code for column in columns], "rows": len(rows), "dry_run": args.dry_run}, ensure_ascii=False))

    if args.dry_run:
        for index, row in enumerate(rows, start=1):
            print(json.dumps({"row": index, **row}, ensure_ascii=False))
        return 0

    token = args.token
    if not token:
        password = args.password or getpass.getpass(f"Password for {args.email}: ")
        token = login(args.base_url, args.email, password)

    submitted = 0
    readings_submitted = 0
    for index, row in enumerate(rows, start=1):
        ids_by_lang: dict[str, list[str]] = {}
        for item in row["expressions"]:
            result = request_json(f"{args.base_url.rstrip('/')}/api/v2/expressions", "POST", item, token)
            ids_by_lang.setdefault(item["lang_code"], []).append(expression_id(result))
            submitted += 1

        edge_count = 0
        languages = list(ids_by_lang)
        for left_index, left_lang in enumerate(languages):
            for right_lang in languages[left_index + 1:]:
                if left_lang == right_lang:
                    continue
                for left_id in ids_by_lang[left_lang]:
                    for right_id in ids_by_lang[right_lang]:
                        request_json(
                            f"{args.base_url.rstrip('/')}/api/v2/expressions/{urllib.parse.quote(left_id, safe='')}/mappings",
                            "POST",
                            {"target_expression_id": right_id, "source": "dictionary"},
                            token,
                        )
                        edge_count += 1

        for cmn_id in ids_by_lang.get("cmn", []):
            for reading in row["readings"]:
                request_json(f"{args.base_url.rstrip('/')}/api/v2/expressions/{urllib.parse.quote(cmn_id, safe='')}/readings", "POST", reading, token)
                readings_submitted += 1
        print(json.dumps({"row": index, "expressions": len(row["expressions"]), "readings": len(row["readings"]), "edges": edge_count}, ensure_ascii=False))
    print(json.dumps({"submitted_expressions": submitted, "submitted_readings": readings_submitted}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, RuntimeError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(1) from error
