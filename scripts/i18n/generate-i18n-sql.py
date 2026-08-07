#!/usr/bin/env python3
"""
Generate SQL to import UI translations for a locale.

Usage:
  python3 scripts/i18n/generate-i18n-sql.py \\
    cmn-Hant scripts/i18n/cmn-Hant.json

The JSON format is { "key": "translation", ... } — keys match en.ts dotted paths.
"""

from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
import re
import sys
from pathlib import Path

PROJECT_ID = 'langmap-web'
SOURCE_LANGUAGE_CODE = 'en-Latn'
LANGUAGE_ID_BITS = 16
TEXT_ID_BITS = 37
PROJECT_ROOT = Path(__file__).resolve().parents[2]
EN_TS_PATH = PROJECT_ROOT / 'web/src/locales/en.ts'


@dataclass(frozen=True)
class TranslationRow:
    locale_code: str
    key: str
    source_text: str
    translation_text: str
    source_expression_id: int
    target_expression_id: int
    edge_id: str
    source_ref: str


def hash_segment(content: str, bits: int) -> int:
    h = hashlib.sha256(content.encode()).digest()
    head = int.from_bytes(h[:8], 'big')
    modulus = (1 << bits) - 1
    return (head % modulus) + 1


def expression_id(language_code: str, text: str) -> int:
    lang_prefix = hash_segment(language_code, LANGUAGE_ID_BITS)
    text_segment = hash_segment(text, TEXT_ID_BITS)
    return lang_prefix * (2 ** TEXT_ID_BITS) + text_segment


def stable_edge_id(a: int, b: int) -> str:
    return f'{min(a, b)}-{max(a, b)}'


# ---------------------------------------------------------------------------
# Parse en.ts → { dotted_key: source_text }
# ---------------------------------------------------------------------------

def parse_en_ts(path: str) -> dict[str, str]:
    return parse_en_ts_text(Path(path).read_text(encoding='utf-8'))


def parse_en_ts_bytes(data: bytes) -> dict[str, str]:
    return parse_en_ts_text(data.decode('utf-8'))


def parse_en_ts_text(content: str) -> dict[str, str]:
    lines = content.splitlines()
    stack: list[str] = []
    result: dict[str, str] = {}
    in_value = False
    value_buf: list[str] = []
    quote_char = "'"

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('//') or stripped.startswith('*'):
            continue
        if stripped.startswith('export ') or stripped == '} as const':
            continue
        if stripped in ('},', '}', '};'):
            if in_value:
                in_value = False
                value_buf = []
            if stack:
                stack.pop()
            continue
        if in_value:
            value_buf.append(line)
            full = ''.join(value_buf)
            q = re.escape(quote_char)
            if full.count(quote_char) % 2 == 0 and (full.endswith("',") or full.endswith("'")):
                in_value = False
                m = re.match(rf'.*{q}(.*){q}\s*,?\s*$', full, re.DOTALL)
                if m and stack:
                    result['.'.join(stack)] = m.group(1).replace(f'\\{quote_char}', quote_char)
                value_buf = []
            continue
        key_match = re.match(r'^\s*(\w+)\s*:\s*', stripped)
        if not key_match:
            continue
        key = key_match.group(1)
        rest = stripped[key_match.end():]
        if rest.startswith('{'):
            if rest.strip().endswith('},') or rest.strip().endswith('}'):
                inner = rest.strip()
                if inner.endswith(','):
                    inner = inner[:-1]
                if inner.startswith('{') and inner.endswith('}'):
                    inner = inner[1:-1].strip()
                    for pair in re.findall(r"(\w+):\s*'((?:[^'\\]|\\.)*)'", inner):
                        result['.'.join(stack + [key, pair[0]])] = pair[1].replace("\\'", "'")
            else:
                stack.append(key)
        elif rest.startswith("'") or rest.startswith('"'):
            q = rest[0]
            qe = re.escape(q)
            val_match = re.match(rf'^{qe}((?:[^{qe}\\]|\\.)*){qe}\s*,?\s*$', rest)
            if val_match:
                val = val_match.group(1).replace(f'\\{q}', q)
                if stack:
                    result['.'.join(stack + [key])] = val
            else:
                in_value = True
                value_buf = [line]
                quote_char = q
                stack.append(key)
    return result


# ---------------------------------------------------------------------------
# Generate SQL
# ---------------------------------------------------------------------------

def q(sql: str) -> str:
    """Single-quote escape for SQL."""
    return sql.replace("'", "''")


def sql_value(v: str | None) -> str:
    if v is None:
        return 'NULL'
    return f"'{q(v)}'"


def validate_locale_code(locale_code: str) -> None:
    if not re.match(r'^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$', locale_code):
        raise ValueError(f'invalid locale code "{locale_code}"')


def load_translations(path: Path) -> dict[str, str]:
    return load_translations_text(path.read_text(encoding='utf-8'))


def load_translations_bytes(data: bytes) -> dict[str, str]:
    return load_translations_text(data.decode('utf-8'))


def load_translations_text(content: str) -> dict[str, str]:
    data = json.loads(content)
    if not isinstance(data, dict):
        raise ValueError('translations file must be a JSON object { "key": "text", ... }')
    translations: dict[str, str] = {}
    for key, value in data.items():
        if not isinstance(key, str) or not isinstance(value, str):
            raise ValueError('translations file must be a JSON object of string keys and string values')
        translations[key] = value
    return translations


def find_unknown_keys(translations: dict[str, str], source_map: dict[str, str]) -> list[str]:
    return sorted(key for key in translations if key not in source_map)


def build_translation_rows(
    locale_code: str,
    translations: dict[str, str],
    source_map: dict[str, str],
    *,
    source_language_code: str = SOURCE_LANGUAGE_CODE,
    expression_id_fn=expression_id,
    stable_edge_id_fn=stable_edge_id,
) -> list[TranslationRow]:
    validate_locale_code(locale_code)
    unknown = find_unknown_keys(translations, source_map)
    if unknown:
        joined = ', '.join(unknown)
        raise ValueError(f'unknown source key(s) for {locale_code}: {joined}')

    rows: list[TranslationRow] = []
    for key in sorted(translations.keys()):
        translation_text = translations[key]
        source_text = source_map[key]
        source_expression_id = expression_id_fn(source_language_code, source_text)
        target_expression_id = expression_id_fn(locale_code, translation_text)
        rows.append(
            TranslationRow(
                locale_code=locale_code,
                key=key,
                source_text=source_text,
                translation_text=translation_text,
                source_expression_id=source_expression_id,
                target_expression_id=target_expression_id,
                edge_id=stable_edge_id_fn(source_expression_id, target_expression_id),
                source_ref=f'{PROJECT_ID}:{key}',
            )
        )
    return rows


def render_locale_sql(locale_code: str, rows: list[TranslationRow]) -> str:
    lines: list[str] = []
    lines.append(f'-- Generated i18n import for {locale_code}')
    lines.append(f'-- Project: {PROJECT_ID}')
    lines.append('')

    # 1. Register locale
    lines.append('-- 1. Register locale')
    lines.append(f"""
INSERT OR IGNORE INTO ui_locales (project_id, code, native_name, direction, status)
SELECT '{PROJECT_ID}', '{locale_code}',
       v.name || IIF(COALESCE(p.script_code, '') != '', '（' || p.name || '）', ''),
       p.direction, 'active'
FROM language_profiles p
JOIN language_varieties v ON v.id = p.language_variety_id
WHERE p.code = '{locale_code}';
""".strip())
    lines.append('')

    # 2. Process each translation
    lines.append(f'-- 2. Translations ({len(rows)} keys)')

    for row in rows:
        lines.append(f"""
-- {row.key}
INSERT OR IGNORE INTO expressions (id, text, language_profile_code, source_type, source_ref, review_status)
VALUES ({row.source_expression_id}, '{q(row.source_text)}', '{SOURCE_LANGUAGE_CODE}', 'ui_i18n', '{row.source_ref}', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('{PROJECT_ID}', '{row.key}', {row.source_expression_id}, '[]', '{row.source_expression_id}', 'active');

INSERT OR IGNORE INTO expressions (id, text, language_profile_code, source_type, source_ref, review_status)
VALUES ({row.target_expression_id}, '{q(row.translation_text)}', '{locale_code}', 'ui_i18n', '{row.source_ref}', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('{row.edge_id}', {row.source_expression_id}, {row.target_expression_id}, 0, 'ui_i18n');
""".strip())
        lines.append('')

    lines.append('-- Done')
    return '\n'.join(lines)


def generate_sql(
    locale_code: str,
    translations: dict[str, str],
    source_map: dict[str, str],
) -> str:
    rows = build_translation_rows(locale_code, translations, source_map)
    return render_locale_sql(locale_code, rows)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) != 3:
        print(f'Usage: {sys.argv[0]} <locale_code> <translations.json>', file=sys.stderr)
        print(
            f'  e.g. {sys.argv[0]} cmn-Hant '
            'scripts/i18n/cmn-Hant.json',
            file=sys.stderr,
        )
        sys.exit(1)

    locale_code = sys.argv[1]
    trans_path = Path(sys.argv[2])

    try:
        validate_locale_code(locale_code)
        translations = load_translations(trans_path)

        source_map = parse_en_ts(EN_TS_PATH)
    except FileNotFoundError:
        print(f'Error: source catalog not found at {EN_TS_PATH}', file=sys.stderr)
        sys.exit(1)
    except ValueError as exc:
        print(f'Error: {exc}', file=sys.stderr)
        sys.exit(1)

    try:
        print(generate_sql(locale_code, translations, source_map))
    except ValueError as exc:
        print(f'Error: {exc}', file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
