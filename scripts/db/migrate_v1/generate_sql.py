from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable


SOURCE_ID = 'v1-migration'


def _literal(value: object) -> str:
    if value is None:
        return 'NULL'
    if isinstance(value, bool):
        return '1' if value else '0'
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def insert_sql(table: str, columns: list[str], rows: Iterable[dict[str, object]]) -> str:
    statements = []
    for row in rows:
        values = ', '.join(_literal(row.get(column)) for column in columns)
        statements.append(f'INSERT OR IGNORE INTO {table} ({", ".join(columns)}) VALUES ({values});')
    return '\n'.join(statements) + ('\n' if statements else '')


def generate_sql_files(result: dict[str, object], output_dir: Path) -> dict[str, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    files: dict[str, tuple[str, list[str], list[dict[str, object]]]] = {
        'users.sql': ('users', ['id', 'username', 'email', 'password_hash', 'role', 'email_verified', 'created_at', 'updated_at'], result['users']),
        'sources.sql': ('sources', ['id', 'type', 'name'], [{'id': SOURCE_ID, 'type': 'system', 'name': 'LangMap V1 migration'}]),
        'expressions.sql': ('expressions', ['id', 'lang_code', 'text', 'text_hash', 'homograph_index', 'description', 'tags_json', 'source_id', 'source_ref', 'review_status', 'created_by', 'created_at', 'updated_at'], result['expressions']),
        'attestations.sql': ('expression_locale_attestations', ['id', 'expression_id', 'language_locale_code', 'source_id', 'source_ref', 'created_by'], result['attestations']),
        'readings.sql': ('expression_readings', ['id', 'expression_id', 'language_locale_code', 'scheme', 'value', 'source_id', 'source_ref', 'created_by'], result['readings']),
        'handbooks.sql': ('handbooks', ['id', 'user_id', 'title', 'visibility', 'status', 'score', 'created_at', 'updated_at'], result['handbooks']),
        'sections.sql': ('handbook_sections', ['id', 'handbook_id', 'title', 'position'], result['sections']),
        'items.sql': ('handbook_section_items', ['section_id', 'expression_id', 'position'], result['items']),
    }
    paths: dict[str, Path] = {}
    for filename, (table, columns, rows) in files.items():
        path = output_dir / filename
        path.write_text(insert_sql(table, columns, rows), encoding='utf-8')
        paths[filename] = path
    (output_dir / 'report.json').write_text(json.dumps(result['report'], ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    paths['report.json'] = output_dir / 'report.json'
    return paths
