#!/usr/bin/env python3
"""Generate INSERT OR IGNORE seed SQL for morphological dimensions and features.

Identity matches scripts/i18n/generate-i18n-sql.py (and runtime
expressionIdentity.ts): NFC + trim, SHA-256[:16], base32 alphabet
abcdefghijklmnopqrstuvwxyz234567, id {lang}:{hash}.

Usage:
  python3 scripts/morphology/generate-form-feature-seed.py
  python3 scripts/morphology/generate-form-feature-seed.py -o /tmp/morph-seed.sql
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_NAMES_PATH = SCRIPT_DIR / 'names.json'
PROJECT_ROOT = SCRIPT_DIR.parents[1]

_BASE32_ALPHABET = 'abcdefghijklmnopqrstuvwxyz234567'

LOCALES = (
    'eng-Latn-US',
    'cmn-Hans-CN',
    'cmn-Hant-TW',
    'jpn-Jpan-JP',
    'spa-Latn-ES',
)
ENG_LOCALE = 'eng-Latn-US'

# Spec §6: dimension sort_order is 10, 20, … 130.
DIMENSIONS: tuple[tuple[str, int], ...] = (
    ('gender', 10),
    ('number', 20),
    ('person', 30),
    ('tense', 40),
    ('mood', 50),
    ('nonfinite', 60),
    ('degree', 70),
    ('polarity', 80),
    ('politeness', 90),
    ('voice', 100),
    ('construction', 110),
    ('aspect', 120),
    ('person-variant', 130),
)

# Spec §6: feature sort_order starts at 1 per dimension, in listed order.
FEATURES: tuple[tuple[str, str, int], ...] = (
    ('masculine', 'gender', 1),
    ('feminine', 'gender', 2),
    ('neuter', 'gender', 3),
    ('singular', 'number', 1),
    ('plural', 'number', 2),
    ('person-1', 'person', 1),
    ('person-2', 'person', 2),
    ('person-3', 'person', 3),
    ('present', 'tense', 1),
    ('past', 'tense', 2),
    ('imperfect', 'tense', 3),
    ('future', 'tense', 4),
    ('indicative', 'mood', 1),
    ('subjunctive', 'mood', 2),
    ('imperative', 'mood', 3),
    ('conditional', 'mood', 4),
    ('infinitive', 'nonfinite', 1),
    ('gerund', 'nonfinite', 2),
    ('past-participle', 'nonfinite', 3),
    ('comparative', 'degree', 1),
    ('superlative', 'degree', 2),
    ('negative', 'polarity', 1),
    ('positive', 'polarity', 2),
    ('polite', 'politeness', 1),
    ('passive', 'voice', 1),
    ('causative', 'voice', 2),
    ('te-form', 'construction', 1),
    ('potential', 'construction', 2),
    ('volitional', 'construction', 3),
    ('desiderative', 'construction', 4),
    ('progressive', 'construction', 5),
    ('perfect', 'aspect', 1),
    ('voseo', 'person-variant', 1),
)

ALL_CODES: tuple[str, ...] = tuple(code for code, _ in DIMENSIONS) + tuple(
    code for code, _, _ in FEATURES
)


def canonicalize_expression_text(text: str) -> str:
    return unicodedata.normalize('NFC', text.strip())


def compute_text_hash(canonical_text: str) -> str:
    digest = hashlib.sha256(canonical_text.encode('utf-8')).digest()[:16]
    bits = ''.join(f'{byte:08b}' for byte in digest)
    out = []
    for i in range(0, len(bits), 5):
        group = bits[i:i + 5].ljust(5, '0')
        out.append(_BASE32_ALPHABET[int(group, 2)])
    return ''.join(out)


def build_expression_id(lang_code: str, text_hash: str, homograph_index: int = 1) -> str:
    lang = lang_code.lower()
    if homograph_index > 1:
        return f'{lang}:{text_hash}.{homograph_index}'
    return f'{lang}:{text_hash}'


def locale_to_lang_code(locale_code: str) -> str:
    return locale_code.split('-', 1)[0].lower()


def q(sql: str) -> str:
    return sql.replace("'", "''")


def sql_str(value: str) -> str:
    return f"'{q(value)}'"


@dataclass(frozen=True)
class Expression:
    id: str | int
    lang_code: str
    text: str
    text_hash: str


@dataclass(frozen=True)
class Attestation:
    id: str
    expression_id: str | int
    locale_code: str
    locale_id: int = 0


@dataclass(frozen=True)
class Edge:
    id: str | int
    expression_a_id: str | int
    expression_b_id: str | int


def load_names(path: Path) -> dict[str, dict[str, str]]:
    data = json.loads(path.read_text(encoding='utf-8'))
    if not isinstance(data, dict):
        raise ValueError(f'{path} must be a JSON object keyed by code')
    expected_codes = set(ALL_CODES)
    actual_codes = set(data)
    missing = sorted(expected_codes - actual_codes)
    extra = sorted(actual_codes - expected_codes)
    if missing or extra:
        parts = []
        if missing:
            parts.append(f'missing codes: {", ".join(missing)}')
        if extra:
            parts.append(f'unexpected codes: {", ".join(extra)}')
        raise ValueError('; '.join(parts))

    names: dict[str, dict[str, str]] = {}
    for code in ALL_CODES:
        value = data[code]
        if not isinstance(value, dict):
            raise ValueError(f'{code} must map to a locale object')
        locales = set(value)
        expected_locales = set(LOCALES)
        if locales != expected_locales:
            raise ValueError(
                f'{code} must have exactly locale keys {", ".join(LOCALES)}; '
                f'got {", ".join(sorted(locales))}'
            )
        row: dict[str, str] = {}
        for locale in LOCALES:
            text = value[locale]
            if not isinstance(text, str) or not canonicalize_expression_text(text):
                raise ValueError(f'{code}.{locale} must be a non-empty string')
            row[locale] = canonicalize_expression_text(text)
        names[code] = row
    return names


def find_or_create_expression(
    expressions: dict[tuple[str, str], Expression],
    lang_code: str,
    text: str,
) -> Expression:
    key = (lang_code, text)
    existing = expressions.get(key)
    if existing is not None:
        return existing
    text_hash = compute_text_hash(text)
    created = Expression(
        id=build_expression_id(lang_code, text_hash),
        lang_code=lang_code,
        text=text,
        text_hash=text_hash,
    )
    expressions[key] = created
    return created


def build_seed(names: dict[str, dict[str, str]]) -> tuple[
    list[Expression],
    list[Attestation],
    list[Edge],
    dict[str, str],
]:
    expressions: dict[tuple[str, str], Expression] = {}
    attestations: dict[tuple[str, str], Attestation] = {}
    edges: dict[tuple[str, str], Edge] = {}
    name_expression_ids: dict[str, str] = {}
    locale_expression_ids: dict[tuple[str, str], str] = {}

    for code in ALL_CODES:
        for locale in LOCALES:
            text = names[code][locale]
            lang_code = locale_to_lang_code(locale)
            expression = find_or_create_expression(expressions, lang_code, text)
            locale_expression_ids[(code, locale)] = expression.id
            att_key = (locale, expression.id)
            if att_key not in attestations:
                attestations[att_key] = Attestation(
                    id=f'morph-att:{locale}:{expression.id}',
                    expression_id=expression.id,
                    locale_code=locale,
                )
        eng_id = locale_expression_ids[(code, ENG_LOCALE)]
        name_expression_ids[code] = eng_id
        for locale in LOCALES:
            if locale == ENG_LOCALE:
                continue
            other_id = locale_expression_ids[(code, locale)]
            lo, hi = (eng_id, other_id) if eng_id < other_id else (other_id, eng_id)
            pair = (lo, hi)
            if pair not in edges:
                edges[pair] = Edge(
                    id=f'morph-edge:{lo}:{hi}',
                    expression_a_id=lo,
                    expression_b_id=hi,
                )

    self_check(names, expressions, attestations, locale_expression_ids)
    sorted_expressions = sorted(expressions.values(), key=lambda item: (item.lang_code, item.text, str(item.id)))
    expression_ids = {str(item.id): index for index, item in enumerate(sorted_expressions, start=1)}
    locale_ids = {code: index for index, code in enumerate(sorted(LOCALES), start=1)}
    canonical_expressions = [
        Expression(id=expression_ids[str(item.id)], lang_code=item.lang_code, text=item.text, text_hash=item.text_hash)
        for item in sorted_expressions
    ]
    canonical_attestations = [
        Attestation(id='', expression_id=expression_ids[str(item.expression_id)], locale_code=item.locale_code, locale_id=locale_ids[item.locale_code])
        for item in sorted(attestations.values(), key=lambda item: (item.locale_code, str(item.expression_id)))
    ]
    canonical_edges = [
        Edge(id=index, expression_a_id=min(expression_ids[str(item.expression_a_id)], expression_ids[str(item.expression_b_id)]), expression_b_id=max(expression_ids[str(item.expression_a_id)], expression_ids[str(item.expression_b_id)]))
        for index, item in enumerate(sorted(edges.values(), key=lambda item: (str(item.expression_a_id), str(item.expression_b_id))), start=1)
    ]
    canonical_names = {code: expression_ids[str(expression_id)] for code, expression_id in name_expression_ids.items()}
    return (
        canonical_expressions,
        canonical_attestations,
        canonical_edges,
        canonical_names,
    )


def self_check(
    names: dict[str, dict[str, str]],
    expressions: dict[tuple[str, str], Expression],
    attestations: dict[tuple[str, str], Attestation],
    locale_expression_ids: dict[tuple[str, str], str],
) -> None:
    if len(DIMENSIONS) != 13:
        raise AssertionError(f'expected 13 dimensions, got {len(DIMENSIONS)}')
    expected_features = {code for code, _, _ in FEATURES}
    if len(expected_features) != 33:
        raise AssertionError(f'expected 33 features, got {len(expected_features)}')
    if set(names) != set(ALL_CODES):
        raise AssertionError('names.json codes do not match spec §6')

    for locale in LOCALES:
        expression_id = locale_expression_ids[('plural', locale)]
        if (locale, expression_id) not in attestations:
            raise AssertionError(f'plural missing attestation for {locale}')

    gender_cmn = expressions[('cmn', names['gender']['cmn-Hans-CN'])]
    if names['gender']['cmn-Hans-CN'] != names['gender']['cmn-Hant-TW']:
        raise AssertionError('gender Hans/Hant should share cmn text 性')
    if locale_expression_ids[('gender', 'cmn-Hans-CN')] != gender_cmn.id:
        raise AssertionError('gender Hans should reuse the shared cmn 性 expression')
    if locale_expression_ids[('gender', 'cmn-Hant-TW')] != gender_cmn.id:
        raise AssertionError('gender Hant should reuse the shared cmn 性 expression')

    jpn_gender = expressions[('jpn', names['gender']['jpn-Jpan-JP'])]
    if jpn_gender.id == gender_cmn.id:
        raise AssertionError('jpn 性 must be a different expression from cmn 性')

    polite_hans = locale_expression_ids[('polite', 'cmn-Hans-CN')]
    politeness_hans = locale_expression_ids[('politeness', 'cmn-Hans-CN')]
    if polite_hans != politeness_hans:
        raise AssertionError('cmn 敬体 should be shared by politeness and polite')


def render_sql(
    expressions: list[Expression],
    attestations: list[Attestation],
    edges: list[Edge],
    name_expression_ids: dict[str, str],
) -> str:
    lines: list[str] = [
        '-- Morphological form-feature seed.',
        '-- Generated by scripts/morphology/generate-form-feature-seed.py. Do not hand-edit hashes.',
        '-- Spec: docs/superpowers/specs/2026-08-18-morphological-form-edges-design.md §6, §7.3',
        '',
        '-- 1. Name expressions',
    ]
    for expression in expressions:
        lines.append(
            'INSERT OR IGNORE INTO expressions (id, language_id, text, homograph_index, pos_mask) '
            f'VALUES ({expression.id}, (SELECT id FROM languages WHERE code = {sql_str(expression.lang_code)}), '
            f'{sql_str(expression.text)}, 1, 0);'
        )

    lines.extend(['', '-- 2. Locale attestations'])
    for attestation in attestations:
        lines.append(
            'INSERT OR IGNORE INTO expression_locale_links (expression_id, locale_id) '
            f'VALUES ({attestation.expression_id}, {attestation.locale_id});'
        )

    lines.extend(['', '-- 3. Translation edges (source=seed)'])
    for edge in edges:
        lines.append(
            'INSERT OR IGNORE INTO expression_edges '
            '(id, expression_a_id, expression_b_id, relation_mask, score, created_by) '
            f'VALUES ({edge.id}, {edge.expression_a_id}, {edge.expression_b_id}, 1, 0, NULL);'
        )

    lines.extend(['', '-- 4. Morphological dimensions'])
    for code, sort_order in DIMENSIONS:
        lines.append(
            'INSERT OR IGNORE INTO morphological_dimensions '
            '(code, name_expression_id, sort_order) '
            f'VALUES ({sql_str(code)}, {name_expression_ids[code]}, {sort_order});'
        )

    lines.extend(['', '-- 5. Morphological features'])
    for code, dimension_code, sort_order in FEATURES:
        lines.append(
            'INSERT OR IGNORE INTO morphological_features '
            '(code, dimension_code, name_expression_id, sort_order) '
            f'VALUES ({sql_str(code)}, {sql_str(dimension_code)}, '
            f'{name_expression_ids[code]}, {sort_order});'
        )

    lines.append('')
    return '\n'.join(lines)


def generate(names_path: Path) -> str:
    names = load_names(names_path)
    expressions, attestations, edges, name_expression_ids = build_seed(names)
    return render_sql(expressions, attestations, edges, name_expression_ids)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--names',
        type=Path,
        default=DEFAULT_NAMES_PATH,
        help='path to names.json (default: scripts/morphology/names.json)',
    )
    parser.add_argument(
        '-o',
        '--output',
        type=Path,
        help='also write SQL to this file',
    )
    args = parser.parse_args(argv)

    try:
        sql = generate(args.names)
    except (OSError, ValueError, AssertionError, json.JSONDecodeError) as exc:
        print(f'Error: {exc}', file=sys.stderr)
        return 1

    sys.stdout.write(sql)
    if not sql.endswith('\n'):
        sys.stdout.write('\n')
    if args.output is not None:
        args.output.write_text(sql if sql.endswith('\n') else sql + '\n', encoding='utf-8')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
