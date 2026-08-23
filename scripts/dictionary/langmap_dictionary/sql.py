"""Deterministic SQLite/D1 statement rendering for release artifacts."""

from __future__ import annotations

import json
from typing import Any, Iterable, Sequence


def sql_literal(value: Any) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "1" if value else "0"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value).replace("'", "''")
    return f"'{text}'"


def insert_or_ignore(table: str, columns: Sequence[str], values: Sequence[Any]) -> str:
    if not table or not all(column.replace("_", "").isalnum() for column in (table, *columns)):
        raise ValueError("SQL identifiers must be simple names")
    if len(columns) != len(values):
        raise ValueError("columns and values have different lengths")
    rendered = ", ".join(sql_literal(value) for value in values)
    return f"INSERT OR IGNORE INTO {table} ({', '.join(columns)}) VALUES ({rendered});"


def update_release_status(release_id: str, status: str) -> str:
    if status not in {"planned", "applying", "validated", "failed"}:
        raise ValueError(f"invalid release status: {status}")
    return f"UPDATE dictionary_dataset_releases SET status={sql_literal(status)} WHERE id={sql_literal(release_id)};"


def transaction(statements: Iterable[str]) -> str:
    body = "\n".join(statement.rstrip(";") + ";" for statement in statements if statement.strip())
    return "PRAGMA foreign_keys = ON;\nBEGIN;\n" + body + "\nCOMMIT;\n"


def json_text(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
