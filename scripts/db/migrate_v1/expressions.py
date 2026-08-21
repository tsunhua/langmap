from __future__ import annotations

import json
import re

from .identity import build_expression_id, canonicalize_text, compute_text_hash
from .mapping import map_expression_locale, map_language_code


RUNTIME_OWNERS = {'system', 'langmap', 'ai', 'opus'}
LATIN_TEXT_RE = re.compile(r'^[\W_\d]*[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ\W_\d]*$', re.UNICODE)


def is_user_expression(row: dict[str, object], users_by_name: dict[str, int], included_ids: set[str] | None = None) -> bool:
    # Handbook renders can reference system/dictionary expressions, but UI
    # translation rows (langmap.* tags) must never become content expressions.
    tags = row.get('tags')
    if isinstance(tags, str) and 'langmap.' in tags:
        return False
    if included_ids and str(row.get('id')) in included_ids:
        return True
    owner = row.get('created_by')
    if owner in RUNTIME_OWNERS:
        return False
    if isinstance(owner, int) or (isinstance(owner, str) and owner.isdigit()):
        return int(owner) in set(users_by_name.values())
    return isinstance(owner, str) and owner in users_by_name


def _created_by(owner: object, users_by_name: dict[str, int]) -> int | None:
    if isinstance(owner, int) or (isinstance(owner, str) and owner.isdigit()):
        return int(owner)
    return users_by_name.get(str(owner)) if owner is not None else None


def reading_for(v1_code: str, expression_id: str, value: str, created_by: int | None) -> dict[str, object] | None:
    schemes = {
        'nan-TW-POJ': ('nan-Latn_Pehoeji-TW', 'poj'),
        'nan-TW-TL': ('nan-Latn_Tailo-TW', 'tailo'),
    }
    locale = schemes.get(v1_code)
    if locale is None:
        return None
    language_locale_code, scheme = locale
    return {
        'id': f'v1-reading:{expression_id}:{scheme}',
        'expression_id': expression_id,
        'language_locale_code': language_locale_code,
        'scheme': scheme,
        'value': value,
        'source_id': None,
        'source_ref': None,
        'created_by': created_by,
    }


def migrate_expressions(rows: list[dict[str, object]], users_by_name: dict[str, int], included_ids: set[str] | None = None) -> dict[str, object]:
    used_ids: set[str] = set()
    expressions: list[dict[str, object]] = []
    attestations: list[dict[str, object]] = []
    readings: list[dict[str, object]] = []
    expression_map: dict[str, str] = {}
    text_map_rank: dict[str, int] = {}
    report = {'skipped': 0, 'dropped_owner': 0, 'dropped_unmapped': 0}

    for row in rows:
        if not is_user_expression(row, users_by_name, included_ids):
            report['dropped_owner'] += 1
            continue
        v1_code = str(row.get('language_code') or '')
        v2_lang = map_language_code(v1_code)
        if v2_lang is None:
            report['dropped_unmapped'] += 1
            continue
        text = canonicalize_text(str(row.get('text') or ''))
        if not text:
            report['skipped'] += 1
            continue

        text_hash = compute_text_hash(text)
        locale = map_expression_locale(v1_code)
        if locale == 'nan-Hant-CN_LufengJiazi' and LATIN_TEXT_RE.fullmatch(text):
            locale = 'nan-Latn-CN_LufengJiazi'
        index = 1
        expression_id = build_expression_id(v2_lang, text_hash, index)
        while expression_id in used_ids:
            index += 1
            expression_id = build_expression_id(v2_lang, text_hash, index)
        used_ids.add(expression_id)
        created_by = _created_by(row.get('created_by'), users_by_name)
        tags = row.get('tags') or '[]'
        if not isinstance(tags, str):
            tags = json.dumps(tags, ensure_ascii=False)
        expression = {
            'id': expression_id,
            'lang_code': v2_lang,
            'text': text,
            'text_hash': text_hash,
            'homograph_index': index,
            'description': str(row.get('desc') or ''),
            'tags_json': tags,
            'source_id': None,
            'source_ref': f"v1:{row.get('id')}",
            'review_status': row.get('review_status') or 'pending',
            'created_by': created_by,
            'created_at': row.get('created_at') or 'CURRENT_TIMESTAMP',
            'updated_at': row.get('updated_at') or row.get('created_at') or 'CURRENT_TIMESTAMP',
        }
        expressions.append(expression)
        expression_map[str(row.get('id'))] = expression_id
        text_key = f'text:{text}'
        # Handbook prose references text, so prefer the Traditional Chinese
        # source expression when identical text exists in several locales.
        rank = {'cmn-Hant-TW': 0, 'cmn-Hans-CN': 1, 'yue-Hant-HK': 2}.get(locale or '', 10)
        if text_key not in text_map_rank or rank < text_map_rank[text_key]:
            expression_map[text_key] = expression_id
            text_map_rank[text_key] = rank
        if locale is not None:
            expression_map[f'text:{locale}:{text}'] = expression_id

        if locale is not None:
            attestations.append({
                'id': f'v1-attestation:{expression_id}:{locale}',
                'expression_id': expression_id,
                'language_locale_code': locale,
                'source_id': None,
                'source_ref': f"v1:{row.get('id')}",
                'created_by': created_by,
            })
        reading = reading_for(v1_code, expression_id, text, created_by)
        if reading is not None:
            readings.append(reading)

    return {
        'expressions': expressions,
        'attestations': attestations,
        'readings': readings,
        'expression_map': expression_map,
        'report': report,
    }
