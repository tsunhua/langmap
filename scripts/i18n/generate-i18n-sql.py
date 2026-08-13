#!/usr/bin/env python3
"""
Generate SQL to import UI translations for a locale.

Usage:
  python3 scripts/i18n/generate-i18n-sql.py \\
    cmn-Hant-TW scripts/i18n/cmn-Hant-TW.json

The JSON format is { "key": "translation", ... } — keys match en.ts dotted paths.
"""

from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json
import re
import sys
import unicodedata
from pathlib import Path

PROJECT_ID = 'langmap-web'
# Full BCP-47-ish locale code of the UI source copy (matches language_locales seed).
SOURCE_LANGUAGE_CODE = 'eng-Latn-US'
# 3-letter lang_code of the source expressions (expressions.lang_code FK).
SOURCE_LANG_CODE = 'eng'
# Provenance stamped onto seeded UI expressions (matches the 'system-ui' source
# seeded in schema.sql and used by generate-ui-seed.py).
SOURCE_ID = 'system-ui'
PROJECT_ROOT = Path(__file__).resolve().parents[2]
EN_TS_PATH = PROJECT_ROOT / 'web/src/locales/en.ts'

# Base32 alphabet used by the runtime computeTextHash
# (backend/src/services/expressionIdentity.ts). Lowercase Crockford-like, no 0/1.
_BASE32_ALPHABET = 'abcdefghijklmnopqrstuvwxyz234567'


@dataclass(frozen=True)
class TranslationRow:
    locale_code: str            # full locale, e.g. 'cmn-Hant-TW'
    lang_code: str              # 3-letter expression lang_code, e.g. 'cmn'
    key: str                    # dotted en.ts path / ui_messages.message_key
    source_text: str            # canonicalized English source text
    translation_text: str       # canonicalized translation text
    source_expression_id: str   # 'eng:<hash>'
    target_expression_id: str   # '<lang>:<hash>'
    edge_id: str                # 'ui-edge:<lo>:<hi>'
    attestation_id: str         # 'ui-att:<locale>:<target_id>'
    source_ref: str             # 'ui:langmap-web:<key>:1'


# ---------------------------------------------------------------------------
# Identity functions — exact ports of backend/src/services/expressionIdentity.ts.
# Seed ids MUST match runtime createExpression ids so the UNIQUE-reuse path and
# translation edges line up.
# ---------------------------------------------------------------------------

def canonicalize_expression_text(text: str) -> str:
    """Port of canonicalizeExpressionText: trim + NFC."""
    return unicodedata.normalize('NFC', text.strip())


def compute_text_hash(canonical_text: str) -> str:
    """Port of computeTextHash: SHA-256[:16] → 5-bit groups (MSB-first, final
    group right-padded with zero bits) → lowercase base32 alphabet. 26 chars."""
    digest = hashlib.sha256(canonical_text.encode('utf-8')).digest()[:16]
    bits = ''.join(f'{byte:08b}' for byte in digest)
    out = []
    for i in range(0, len(bits), 5):
        group = bits[i:i + 5].ljust(5, '0')
        out.append(_BASE32_ALPHABET[int(group, 2)])
    return ''.join(out)


def build_expression_id(lang_code: str, text_hash: str, homograph_index: int = 1) -> str:
    """Port of buildExpressionId. omits the '.N' suffix when N == 1."""
    lang = lang_code.lower()
    if homograph_index > 1:
        return f'{lang}:{text_hash}.{homograph_index}'
    return f'{lang}:{text_hash}'


def expression_id(lang_code: str, text: str) -> str:
    """Convenience: canonicalize → hash → build id, matching runtime createExpression.

    Lang_code here is the 3-letter expressions.lang_code (NOT the full locale);
    callers pass locale_to_lang_code(...) for target locales and SOURCE_LANG_CODE
    for the source.
    """
    return build_expression_id(lang_code, compute_text_hash(canonicalize_expression_text(text)))


def locale_to_lang_code(locale_code: str) -> str:
    """Derive the 3-letter expressions.lang_code from a full locale code."""
    return locale_code.split('-', 1)[0].lower()


def extract_placeholders(text: str) -> list[str]:
    """Sorted unique {placeholder} names, matching the runtime placeholder check."""
    return sorted(set(re.findall(r'\{(\w+)\}', text)))


def stable_edge_id(a: str, b: str) -> str:
    """Deterministic expression_edges.id; canonicalized so a < b (string order),
    matching runtime canonicalizeEdgePair + the schema CHECK constraint."""
    lo, hi = (a, b) if a < b else (b, a)
    return f'ui-edge:{lo}:{hi}'


def stable_attestation_id(locale_code: str, target_expression_id: str) -> str:
    """Deterministic expression_locale_attestations.id. The UNIQUE on
    (expression_id, language_locale_code, source_id, source_ref) cannot dedupe
    NULL provenance (SQLite treats NULLs as distinct), so idempotent re-import
    relies on this deterministic PRIMARY KEY."""
    return f'ui-att:{locale_code}:{target_expression_id}'


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
    if not re.match(r'^[a-z]{3}-[A-Z][a-z]{3}-[A-Z]{2}(?:_[A-Z][A-Za-z]*)*$', locale_code):
        raise ValueError(f'invalid language locale code "{locale_code}" (expected format: xxx-Xxxx-XX)')


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
    source_lang_code: str = SOURCE_LANG_CODE,
    source_language_code: str = SOURCE_LANGUAGE_CODE,
    expression_id_fn=expression_id,
    stable_edge_id_fn=stable_edge_id,
    stable_attestation_id_fn=stable_attestation_id,
) -> list[TranslationRow]:
    validate_locale_code(locale_code)
    unknown = find_unknown_keys(translations, source_map)
    if unknown:
        joined = ', '.join(unknown)
        raise ValueError(f'unknown source key(s) for {locale_code}: {joined}')

    lang_code = locale_to_lang_code(locale_code)
    rows: list[TranslationRow] = []
    for key in sorted(translations.keys()):
        source_text = canonicalize_expression_text(source_map[key])
        translation_text = canonicalize_expression_text(translations[key])
        source_expression_id = expression_id_fn(source_lang_code, source_map[key])
        target_expression_id = expression_id_fn(lang_code, translations[key])
        rows.append(
            TranslationRow(
                locale_code=locale_code,
                lang_code=lang_code,
                key=key,
                source_text=source_text,
                translation_text=translation_text,
                source_expression_id=source_expression_id,
                target_expression_id=target_expression_id,
                edge_id=stable_edge_id_fn(source_expression_id, target_expression_id),
                attestation_id=stable_attestation_id_fn(locale_code, target_expression_id),
                source_ref=f'ui:{PROJECT_ID}:{key}:1',
            )
        )
    return rows


def render_locale_sql(locale_code: str, rows: list[TranslationRow]) -> str:
    lines: list[str] = []
    lines.append(f'-- Generated i18n import for {locale_code}')
    lines.append(f'-- Project: {PROJECT_ID}')
    lines.append('')

    # 1. Activate the UI locale (FK → language_locales; must already be seeded).
    lines.append('-- 1. Activate UI locale')
    lines.append(
        "INSERT OR IGNORE INTO ui_locales "
        "(project_id, language_locale_code, status, mapping_revision, activation_source, activated_at) "
        f"VALUES ('{PROJECT_ID}', '{locale_code}', 'active', 0, 'system', CURRENT_TIMESTAMP);"
    )
    lines.append('')

    # 2. Source expressions + ui_messages (self-contained single-locale import).
    lines.append(f'-- 2. Source messages ({len(rows)} keys)')
    for row in rows:
        source_hash = compute_text_hash(row.source_text)
        placeholders = json.dumps(extract_placeholders(row.source_text))
        lines.append(f"""
-- {row.key}
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by)
VALUES ('{q(row.source_expression_id)}', '{SOURCE_LANG_CODE}', '{q(row.source_text)}', '{q(source_hash)}', 1, '', '[]', '{SOURCE_ID}', '{q(row.source_ref)}', 'approved', NULL);

INSERT OR IGNORE INTO ui_messages (project_id, message_key, source_expression_id, source_text, placeholders_json, status)
VALUES ('{PROJECT_ID}', '{row.key}', '{q(row.source_expression_id)}', '{q(row.source_text)}', '{q(placeholders)}', 'active');
""".strip())
        lines.append('')

    # 3. Translation expressions, attestations, and mapping edges.
    lines.append(f'-- 3. Translations ({len(rows)} keys)')

    for row in rows:
        lo, hi = (row.source_expression_id, row.target_expression_id) \
            if row.source_expression_id < row.target_expression_id \
            else (row.target_expression_id, row.source_expression_id)
        target_hash = compute_text_hash(row.translation_text)
        lines.append(f"""
-- {row.key}
INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by)
VALUES ('{q(row.target_expression_id)}', '{row.lang_code}', '{q(row.translation_text)}', '{q(target_hash)}', 1, '', '[]', '{SOURCE_ID}', '{q(row.source_ref)}', 'approved', NULL);

INSERT OR IGNORE INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by)
VALUES ('{q(row.attestation_id)}', '{q(row.target_expression_id)}', '{locale_code}', NULL, NULL, NULL);

INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by)
VALUES ('{q(row.edge_id)}', '{q(lo)}', '{q(hi)}', 0, 'translation', NULL);
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
            f'  e.g. {sys.argv[0]} cmn-Hant-TW '
            'scripts/i18n/cmn-Hant-TW.json',
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
