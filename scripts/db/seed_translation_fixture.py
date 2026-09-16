#!/usr/bin/env python3
"""Seed a repeatable local Mandarin → Taiwanese Hokkien translation fixture.

The script is deliberately local-only. It executes the generated SQL through
Wrangler with ``d1 execute --local`` and never accepts a remote mode.

Default login:
    translation-fixture@example.com / fixture

Examples:
    python3 scripts/db/seed_translation_fixture.py
    python3 scripts/db/seed_translation_fixture.py --dry-run > /tmp/fixture.sql
    python3 scripts/db/seed_translation_fixture.py --output /tmp/fixture.sql
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[2]
BACKEND_DIR = PROJECT_ROOT / "backend"
WRANGLER_CONFIG = BACKEND_DIR / "wrangler.jsonc"
DEFAULT_WRANGLER = BACKEND_DIR / "node_modules" / ".bin" / "wrangler"
DEFAULT_PERSIST_TO = BACKEND_DIR / ".wrangler" / "state"
DEFAULT_DATABASE = "langmap-v2"

FIXTURE_VERSION = "v1"
SOURCE_TYPE = "system"
SOURCE_NAME = f"LangMap local AI translation fixture {FIXTURE_VERSION}"
MARKER_PREFIX = f"local-ai-fixture-{FIXTURE_VERSION}"
DEFAULT_USERNAME = "translation-fixture"
DEFAULT_EMAIL = "translation-fixture@example.com"
DEFAULT_PASSWORD = "fixture"
PASSWORD_SALT = "langmap-translation-fixture-v1"
SOURCE_LOCALE = "cmn-Hans-CN"
TARGET_LOCALE = "nan-Hant-TW"

REQUIRED_TABLES = (
    "users",
    "languages",
    "language_locales",
    "sources",
    "expressions",
    "expression_locale_links",
    "expression_edges",
    "expression_sources",
    "expression_edge_sources",
    "language_statistics",
    "ui_locales",
)


@dataclass(frozen=True)
class FixturePair:
    source_text: str
    target_text: str


# These are synthetic, AI-assisted test strings for exercising the translation
# path. They are not presented as an authoritative Taiwanese Hokkien lexicon.
FIXTURE_PAIRS: tuple[FixturePair, ...] = (
    FixturePair("你好吗？", "你好無？"),
    FixturePair("谢谢你。", "多謝你。"),
    FixturePair("不客气。", "免客氣。"),
    FixturePair("对不起。", "拍謝。"),
    FixturePair("没关系。", "無要緊。"),
    FixturePair("早上好。", "早安。"),
    FixturePair("晚安。", "暗安。"),
    FixturePair("你吃饭了吗？", "你食飽未？"),
    FixturePair("我吃饱了。", "我食飽矣。"),
    FixturePair("你要去哪里？", "你欲去佗位？"),
    FixturePair("我不知道。", "我毋知。"),
    FixturePair("请再说一次。", "請閣講一擺。"),
    FixturePair("请慢一点说。", "請講較慢。"),
    FixturePair("等我一下。", "等我一下。"),
    FixturePair("现在几点？", "現在幾點？"),
    FixturePair("今天天气很好。", "今仔日天氣真好。"),
    FixturePair("明天见。", "明仔載見。"),
    FixturePair("我喜欢这个。", "我佮意這个。"),
    FixturePair("这个多少钱？", "這个偌濟錢？"),
    FixturePair("请给我一杯水。", "請予我一杯水。"),
)


class FixtureError(RuntimeError):
    """Raised when the local D1 cannot be safely seeded."""


def sql_quote(value: str) -> str:
    """Return a SQLite string literal without relying on shell quoting."""

    return "'" + value.replace("'", "''") + "'"


def password_hash(password: str) -> str:
    """Mirror the Worker SHA-256 password format with a stable fixture salt."""

    digest = hashlib.sha256(f"{PASSWORD_SALT}:{password}".encode("utf-8")).hexdigest()
    return f"{PASSWORD_SALT}:{digest}"


def _user_id(email: str) -> str:
    return f"(SELECT id FROM users WHERE email={sql_quote(email)} LIMIT 1)"


def _source_id() -> str:
    return (
        "(SELECT id FROM sources WHERE type="
        f"{sql_quote(SOURCE_TYPE)} AND name={sql_quote(SOURCE_NAME)} LIMIT 1)"
    )


def _expression_id(lang_code: str, text: str) -> str:
    return (
        "(SELECT e.id FROM expressions e JOIN languages l ON l.id=e.language_id "
        f"WHERE l.code={sql_quote(lang_code)} AND e.text={sql_quote(text)} "
        "AND e.homograph_index=1 LIMIT 1)"
    )


def _append_expression_sql(lines: list[str], *, lang_code: str, locale_code: str, text: str, marker: str, email: str) -> None:
    quoted_lang = sql_quote(lang_code)
    quoted_locale = sql_quote(locale_code)
    quoted_text = sql_quote(text)
    quoted_marker = sql_quote(marker)
    lines.extend(
        [
            "INSERT OR IGNORE INTO expressions "
            "(language_id, text, homograph_index, pos_mask, source_id, created_by) "
            f"SELECT l.id, {quoted_text}, 1, 0, {_source_id()}, {_user_id(email)} "
            f"FROM languages l WHERE l.code={quoted_lang};",
            "INSERT OR IGNORE INTO expression_locale_links (expression_id, locale_id) "
            "SELECT e.id, ll.id FROM expressions e "
            "JOIN languages l ON l.id=e.language_id "
            f"JOIN language_locales ll ON ll.code={quoted_locale} AND ll.language_id=l.id "
            f"WHERE l.code={quoted_lang} AND e.text={quoted_text} AND e.homograph_index=1;",
            "INSERT OR IGNORE INTO expression_sources "
            "(expression_id, source_id, source_marker) "
            "SELECT e.id, "
            f"{_source_id()}, {quoted_marker} FROM expressions e "
            "JOIN languages l ON l.id=e.language_id "
            f"WHERE l.code={quoted_lang} AND e.text={quoted_text} AND e.homograph_index=1;",
        ]
    )


def _append_edge_sql(lines: list[str], *, pair: FixturePair, marker: str, email: str) -> None:
    source_id = _expression_id("cmn", pair.source_text)
    target_id = _expression_id("nan", pair.target_text)
    quoted_marker = sql_quote(marker)
    low_id = f"CASE WHEN {source_id} < {target_id} THEN {source_id} ELSE {target_id} END"
    high_id = f"CASE WHEN {source_id} < {target_id} THEN {target_id} ELSE {source_id} END"
    lines.extend(
        [
            "INSERT OR IGNORE INTO expression_edges "
            "(expression_a_id, expression_b_id, relation_mask, score, annotations_json, created_by) "
            f"SELECT {low_id}, {high_id}, 1, 0, '[]', {_user_id(email)} "
            f"WHERE {source_id} IS NOT NULL AND {target_id} IS NOT NULL;",
            "INSERT OR IGNORE INTO expression_edge_sources "
            "(edge_id, source_id, source_marker) "
            "SELECT edge.id, "
            f"{_source_id()}, {quoted_marker} FROM expression_edges edge "
            f"WHERE edge.expression_a_id={low_id} AND edge.expression_b_id={high_id};",
        ]
    )


def build_sql(*, username: str = DEFAULT_USERNAME, email: str = DEFAULT_EMAIL, password: str = DEFAULT_PASSWORD) -> str:
    """Render the deterministic local-D1 fixture SQL."""

    if not username.strip() or not email.strip() or not password:
        raise ValueError("username, email, and password must be non-empty")
    if len(FIXTURE_PAIRS) != 20:
        raise AssertionError(f"expected 20 fixture pairs, got {len(FIXTURE_PAIRS)}")

    lines = [
        "-- Generated by scripts/db/seed_translation_fixture.py.",
        "-- Local-only synthetic AI translation fixture; do not apply remotely.",
        "PRAGMA foreign_keys = ON;",
        "",
        "-- 1. Dedicated local test account",
        "INSERT INTO users (username, email, password_hash, role, email_verified) "
        f"VALUES ({sql_quote(username)}, {sql_quote(email)}, {sql_quote(password_hash(password))}, 'user', 1) "
        "ON CONFLICT(email) DO UPDATE SET "
        "username=excluded.username, password_hash=excluded.password_hash, "
        "role='user', email_verified=1, updated_at=CURRENT_TIMESTAMP;",
        "",
        "-- 2. Provenance source shared by all fixture rows",
        f"INSERT OR IGNORE INTO sources (type, name) VALUES ({sql_quote(SOURCE_TYPE)}, {sql_quote(SOURCE_NAME)});",
        "",
        "-- 3. Expressions, locale attestations, and expression provenance",
    ]

    for index, pair in enumerate(FIXTURE_PAIRS, start=1):
        marker = f"{MARKER_PREFIX}-{index:02d}"
        _append_expression_sql(
            lines,
            lang_code="cmn",
            locale_code=SOURCE_LOCALE,
            text=pair.source_text,
            marker=f"{marker}-cmn",
            email=email,
        )
        _append_expression_sql(
            lines,
            lang_code="nan",
            locale_code=TARGET_LOCALE,
            text=pair.target_text,
            marker=f"{marker}-nan",
            email=email,
        )
        _append_edge_sql(lines, pair=pair, marker=marker, email=email)

    lines.extend(
        [
            "",
            "-- 4. Keep the language list counts in sync with direct SQL seeding",
            "INSERT OR REPLACE INTO language_statistics "
            "(language_id, expression_count, locale_count, active_ui_locale_count, updated_at) "
            "SELECT l.id, "
            "(SELECT COUNT(*) FROM expressions e WHERE e.language_id=l.id), "
            "(SELECT COUNT(*) FROM language_locales ll WHERE ll.language_id=l.id), "
            "(SELECT COUNT(*) FROM ui_locales u JOIN language_locales ll ON ll.id=u.locale_id "
            "WHERE ll.language_id=l.id AND u.status='active'), CURRENT_TIMESTAMP "
            "FROM languages l WHERE l.code IN ('cmn', 'nan');",
            "",
        ]
    )
    return "\n".join(lines)


def _walk_result_rows(payload: Any) -> Iterable[dict[str, Any]]:
    if isinstance(payload, dict):
        rows = payload.get("results")
        if isinstance(rows, list):
            for row in rows:
                if isinstance(row, dict):
                    yield row
        for value in payload.values():
            yield from _walk_result_rows(value)
    elif isinstance(payload, list):
        for value in payload:
            yield from _walk_result_rows(value)


def _find_error(payload: Any) -> Any | None:
    if isinstance(payload, dict):
        error = payload.get("error")
        if error:
            return error
        for value in payload.values():
            found = _find_error(value)
            if found:
                return found
    elif isinstance(payload, list):
        for value in payload:
            found = _find_error(value)
            if found:
                return found
    return None


def _first_row(payload: Any) -> dict[str, Any]:
    row = next(iter(_walk_result_rows(payload)), None)
    if row is None:
        raise FixtureError("Wrangler 沒有回傳可解析的 D1 結果")
    return row


def _resolve_wrangler(path_value: str | None) -> Path:
    if path_value:
        candidate = Path(path_value).expanduser()
        candidate = candidate if candidate.is_absolute() else (PROJECT_ROOT / candidate)
    elif DEFAULT_WRANGLER.exists():
        candidate = DEFAULT_WRANGLER
    else:
        discovered = shutil.which("wrangler")
        if not discovered:
            raise FixtureError(f"找不到 Wrangler：{DEFAULT_WRANGLER}")
        candidate = Path(discovered)
    if not candidate.exists():
        raise FixtureError(f"Wrangler 不存在：{candidate}")
    return candidate.resolve()


def _wrangler_base_args(wrangler: Path, database: str, persist_to: Path) -> list[str]:
    return [
        str(wrangler),
        "--config",
        str(WRANGLER_CONFIG),
        "d1",
        "execute",
        database,
        "--local",
        "--persist-to",
        str(persist_to),
        "--yes",
        "--json",
    ]


def _execute_json(wrangler: Path, database: str, persist_to: Path, *, command: str | None = None, file: Path | None = None) -> Any:
    if (command is None) == (file is None):
        raise ValueError("exactly one of command or file is required")
    args = _wrangler_base_args(wrangler, database, persist_to)
    args.extend(["--command", command] if command is not None else ["--file", str(file)])
    completed = subprocess.run(
        args,
        cwd=str(BACKEND_DIR),
        capture_output=True,
        text=True,
        check=False,
    )
    raw = completed.stdout.strip()
    if completed.returncode != 0:
        detail = completed.stderr.strip() or raw or f"exit code {completed.returncode}"
        raise FixtureError(f"Wrangler 執行失敗：{detail}")
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        detail = completed.stderr.strip() or raw[:500]
        raise FixtureError(f"Wrangler 回傳不是 JSON：{detail}") from exc
    error = _find_error(payload)
    if error:
        raise FixtureError(f"Wrangler/D1 回傳錯誤：{json.dumps(error, ensure_ascii=False)}")
    return payload


def _preflight(wrangler: Path, database: str, persist_to: Path) -> None:
    table_literals = ", ".join(sql_quote(name) for name in REQUIRED_TABLES)
    query = (
        "SELECT "
        f"(SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name IN ({table_literals})) AS required_table_count, "
        "(SELECT COUNT(*) FROM languages WHERE code='cmn') AS cmn_language_count, "
        "(SELECT COUNT(*) FROM languages WHERE code='nan') AS nan_language_count, "
        f"(SELECT COUNT(*) FROM language_locales WHERE code IN ({sql_quote(SOURCE_LOCALE)}, {sql_quote(TARGET_LOCALE)})) AS locale_count;"
    )
    try:
        payload = _execute_json(wrangler, database, persist_to, command=query)
    except FixtureError as exc:
        message = str(exc)
        if "no such table" in message.lower():
            raise FixtureError(
                "本地 D1 尚未初始化 canonical schema；請先執行 "
                "./scripts/db/manage.sh local rebuild，再重新執行此腳本。"
            ) from exc
        raise

    row = _first_row(payload)
    expected_tables = len(REQUIRED_TABLES)
    actual_tables = int(row.get("required_table_count", 0))
    if actual_tables != expected_tables:
        raise FixtureError(
            f"本地 D1 缺少必要 schema（{actual_tables}/{expected_tables} 個表）；"
            "請先執行 ./scripts/db/manage.sh local rebuild。"
        )
    if int(row.get("cmn_language_count", 0)) != 1 or int(row.get("nan_language_count", 0)) != 1:
        raise FixtureError("本地 registry 缺少 cmn 或 nan；請先執行 ./scripts/db/manage.sh local rebuild。")
    if int(row.get("locale_count", 0)) != 2:
        raise FixtureError(
            f"本地 registry 缺少 {SOURCE_LOCALE} 或 {TARGET_LOCALE}；"
            "請先執行 ./scripts/db/manage.sh local rebuild。"
        )


def _verify(wrangler: Path, database: str, persist_to: Path, *, email: str) -> dict[str, int]:
    source = sql_quote(SOURCE_NAME)
    source_type = sql_quote(SOURCE_TYPE)
    marker_like = sql_quote(f"{MARKER_PREFIX}-%")
    query = (
        "SELECT "
        f"(SELECT COUNT(*) FROM users WHERE email={sql_quote(email)}) AS users, "
        f"(SELECT COUNT(*) FROM sources WHERE type={source_type} AND name={source}) AS sources, "
        "(SELECT COUNT(*) FROM expression_sources es JOIN sources s ON s.id=es.source_id "
        f"WHERE s.type={source_type} AND s.name={source} AND es.source_marker LIKE {marker_like}) AS expressions, "
        "(SELECT COUNT(*) FROM expression_locale_links ell JOIN expressions e ON e.id=ell.expression_id "
        "JOIN expression_sources es ON es.expression_id=e.id JOIN sources s ON s.id=es.source_id "
        f"WHERE s.type={source_type} AND s.name={source} AND es.source_marker LIKE {marker_like}) AS locale_links, "
        "(SELECT COUNT(*) FROM expression_edge_sources ees JOIN sources s ON s.id=ees.source_id "
        f"WHERE s.type={source_type} AND s.name={source} AND ees.source_marker LIKE {marker_like}) AS edges;"
    )
    row = _first_row(_execute_json(wrangler, database, persist_to, command=query))
    return {key: int(row.get(key, 0)) for key in ("users", "sources", "expressions", "locale_links", "edges")}


def _write_output(path: Path, sql: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(sql, encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", default=DEFAULT_DATABASE, help=f"local D1 name (default: {DEFAULT_DATABASE})")
    parser.add_argument("--persist-to", type=Path, default=DEFAULT_PERSIST_TO, help="Wrangler local persistence directory")
    parser.add_argument("--wrangler", help="Wrangler executable path")
    parser.add_argument("--username", default=DEFAULT_USERNAME, help=f"fixture username (default: {DEFAULT_USERNAME})")
    parser.add_argument("--email", default=DEFAULT_EMAIL, help=f"fixture email (default: {DEFAULT_EMAIL})")
    parser.add_argument("--password", default=DEFAULT_PASSWORD, help="fixture password (default: fixture)")
    parser.add_argument("--output", type=Path, help="also save the generated SQL to this path")
    parser.add_argument("--dry-run", action="store_true", help="print SQL only; do not invoke Wrangler")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        sql = build_sql(username=args.username, email=args.email, password=args.password)
        if args.output:
            _write_output(args.output, sql)
        if args.dry_run:
            sys.stdout.write(sql)
            return 0

        wrangler = _resolve_wrangler(args.wrangler)
        persist_to = args.persist_to.expanduser().resolve()
        _preflight(wrangler, args.database, persist_to)
        with tempfile.TemporaryDirectory(prefix="langmap-translation-fixture-") as temp_dir:
            sql_path = Path(temp_dir) / "translation-fixture.sql"
            sql_path.write_text(sql, encoding="utf-8")
            _execute_json(wrangler, args.database, persist_to, file=sql_path)
        counts = _verify(wrangler, args.database, persist_to, email=args.email)
        expected = {"users": 1, "sources": 1, "expressions": 40, "locale_links": 40, "edges": 20}
        if counts != expected:
            raise FixtureError(f"注入後計數不符合預期：{counts}，預期：{expected}")
        print(
            f"已注入本地翻譯測試資料：{len(FIXTURE_PAIRS)} 對、"
            f"{counts['expressions']} 個 expressions、{counts['edges']} 條 mappings。"
        )
        print(f"測試帳號：{args.email} / {args.password}")
        return 0
    except (FixtureError, OSError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
