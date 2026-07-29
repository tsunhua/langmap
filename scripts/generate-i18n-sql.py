#!/usr/bin/env python3
"""
Generate SQL to import UI translations for a locale.

Usage:
  python3 scripts/generate-i18n-sql.py zh-CN scripts/i18n/zh-CN.json

Pipe to wrangler:
  python3 scripts/generate-i18n-sql.py zh-CN scripts/i18n/zh-CN.json \\
    | wrangler d1 execute langmap-v2 --command "$(cat)"

The JSON format is { "key": "translation", ... } — keys match en.ts dotted paths.
"""

import hashlib
import json
import re
import sys

PROJECT_ID = 'langmap-web'
LANGUAGE_ID_BITS = 16
TEXT_ID_BITS = 37
EN_TS_PATH = 'web/src/locales/en.ts'


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
    with open(path) as f:
        lines = f.readlines()
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
            value_buf.append(line.rstrip())
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
                value_buf = [line.rstrip()]
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


def generate_sql(locale_code: str, translations: dict[str, str],
                 source_map: dict[str, str]) -> str:
    lines: list[str] = []
    lines.append(f'-- Generated i18n import for {locale_code}')
    lines.append(f'-- Project: {PROJECT_ID}')
    lines.append('')

    # 1. Register locale
    lines.append('-- 1. Register locale')
    lines.append(f"""
INSERT OR IGNORE INTO ui_locales (project_id, code, native_name, direction, status)
SELECT '{PROJECT_ID}', '{locale_code}', l.name, l.direction, 'active'
FROM languages l WHERE l.code = '{locale_code}';
""".strip())
    lines.append('')

    # 2. Process each translation
    sorted_keys = sorted(translations.keys())
    lines.append(f'-- 2. Translations ({len(sorted_keys)} keys)')

    for key in sorted_keys:
        translation = translations[key]
        source_text = source_map.get(key)
        if not source_text:
            print(f'  ⚠  Skipping "{key}": source text not found in en.ts', file=sys.stderr)
            continue

        # Compute IDs
        src_id = expression_id('en-US', source_text)
        tgt_id = expression_id(locale_code, translation)
        edge_id = stable_edge_id(src_id, tgt_id)
        source_ref = f'{PROJECT_ID}:{key}'

        lines.append(f"""
-- {key}
INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES ({src_id}, '{q(source_text)}', 'en-US', 'ui_i18n', '{source_ref}', 'approved');

INSERT OR IGNORE INTO ui_messages (project_id, key, source_expression_id, placeholders_json, source_hash, status)
VALUES ('{PROJECT_ID}', '{key}', {src_id}, '[]', '{src_id}', 'active');

INSERT OR IGNORE INTO expressions (id, text, language_code, source_type, source_ref, review_status)
VALUES ({tgt_id}, '{q(translation)}', '{locale_code}', 'ui_i18n', '{source_ref}', 'pending');

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source)
VALUES ('{edge_id}', {src_id}, {tgt_id}, 0, 'ui_i18n');
""".strip())
        lines.append('')

    lines.append('-- Done')
    return '\n'.join(lines)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) != 3:
        print(f'Usage: {sys.argv[0]} <locale_code> <translations.json>', file=sys.stderr)
        print(f'  e.g. {sys.argv[0]} zh-CN scripts/i18n/zh-CN.json', file=sys.stderr)
        sys.exit(1)

    locale_code = sys.argv[1]
    trans_path = sys.argv[2]

    # Validate locale code
    if not re.match(r'^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$', locale_code):
        print(f'Error: invalid locale code "{locale_code}"', file=sys.stderr)
        sys.exit(1)

    # Load translation JSON
    with open(trans_path) as f:
        translations = json.load(f)
    if not isinstance(translations, dict):
        print('Error: translations file must be a JSON object { "key": "text", ... }', file=sys.stderr)
        sys.exit(1)

    # Parse source map from en.ts
    try:
        source_map = parse_en_ts(EN_TS_PATH)
    except FileNotFoundError:
        print(f'Error: {EN_TS_PATH} not found — run from project root', file=sys.stderr)
        sys.exit(1)

    # Validate keys
    unknown = [k for k in translations if k not in source_map]
    if unknown:
        print(f'Warning: {len(unknown)} key(s) not found in en.ts (will be skipped):', file=sys.stderr)
        for k in unknown:
            print(f'  - {k}', file=sys.stderr)

    sql = generate_sql(locale_code, translations, source_map)
    print(sql)


if __name__ == '__main__':
    main()
