from __future__ import annotations

import re
import sqlite3


INSERT_RE = re.compile(
    r'INSERT(?:\s+OR\s+IGNORE)?\s+INTO\s+"?(?P<table>[A-Za-z_]+)"?\s*'
    r'\((?P<columns>.*?)\)\s*VALUES\s*(?P<values>.*)',
    re.IGNORECASE | re.DOTALL,
)


def _sql_statements(contents: str) -> list[str]:
    statements: list[str] = []
    start = 0
    in_string = False
    index = 0
    while index < len(contents):
        char = contents[index]
        if char == "'":
            if in_string and index + 1 < len(contents) and contents[index + 1] == "'":
                index += 2
                continue
            in_string = not in_string
        elif char == ';' and not in_string:
            statements.append(contents[start:index + 1])
            start = index + 1
        index += 1
    if contents[start:].strip():
        statements.append(contents[start:])
    return statements


def load_table(contents: str, table: str) -> list[dict[str, object]]:
    """Evaluate INSERT statements with SQLite, including replace()/char()."""
    connection = sqlite3.connect(':memory:')
    try:
        rows: list[dict[str, object]] = []
        for statement in _sql_statements(contents):
            match = INSERT_RE.fullmatch(statement.strip())
            if match is None:
                continue
            if match.group('table').lower() != table.lower():
                continue
            columns = [part.strip().strip('"') for part in match.group('columns').split(',')]
            quoted_table = '"' + table.replace('"', '""') + '"'
            quoted_columns = ', '.join('"' + column.replace('"', '""') + '"' for column in columns)
            connection.execute(f'CREATE TABLE IF NOT EXISTS {quoted_table} ({", ".join(quoted_columns.split(", "))})')
            insert = f'INSERT INTO {quoted_table} ({quoted_columns}) VALUES {match.group("values").rstrip(";").strip()}'
            connection.execute(insert)
        connection.commit()
        cursor = connection.execute(f'SELECT * FROM "{table.replace(chr(34), chr(34) * 2)}"')
        names = [description[0] for description in cursor.description or ()]
        rows.extend(dict(zip(names, row)) for row in cursor.fetchall())
        return rows
    finally:
        connection.close()


def load_table_file(path: str, table: str) -> list[dict[str, object]]:
    with open(path, encoding='utf-8') as handle:
        return load_table(handle.read(), table)
