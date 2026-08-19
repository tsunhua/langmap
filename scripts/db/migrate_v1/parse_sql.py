from __future__ import annotations

import re
import sqlite3


INSERT_RE = re.compile(
    r'INSERT(?:\s+OR\s+IGNORE)?\s+INTO\s+"?(?P<table>[A-Za-z_]+)"?\s*'
    r'\((?P<columns>.*?)\)\s*VALUES\s*(?P<values>.*?);',
    re.IGNORECASE | re.DOTALL,
)


def load_table(contents: str, table: str) -> list[dict[str, object]]:
    """Evaluate INSERT statements with SQLite, including replace()/char()."""
    connection = sqlite3.connect(':memory:')
    try:
        rows: list[dict[str, object]] = []
        for match in INSERT_RE.finditer(contents):
            if match.group('table').lower() != table.lower():
                continue
            columns = [part.strip().strip('"') for part in match.group('columns').split(',')]
            quoted_table = '"' + table.replace('"', '""') + '"'
            quoted_columns = ', '.join('"' + column.replace('"', '""') + '"' for column in columns)
            connection.execute(f'CREATE TABLE IF NOT EXISTS {quoted_table} ({", ".join(f"{column} TEXT" for column in quoted_columns.split(", "))})')
            statement = f'INSERT INTO {quoted_table} ({quoted_columns}) VALUES {match.group("values")}'
            connection.execute(statement)
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
