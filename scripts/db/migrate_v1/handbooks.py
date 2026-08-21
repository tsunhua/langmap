from __future__ import annotations

import re

from .mapping import map_expression_locale


EXPR_TAG_RE = re.compile(r'\{\{(?P<body>[^{}]+)\}\}')
HEADING_RE = re.compile(r'^(?P<marks>#{2,6})\s+(?P<title>.+?)\s*$')


def clean_section_title(title: str) -> str:
    """Keep heading text readable when v1 embedded an expression tag in it."""
    def replace(match: re.Match[str]) -> str:
        body = match.group('body').strip()
        if body.startswith('text:'):
            return body[5:].split('|', 1)[0].strip()
        return body

    return EXPR_TAG_RE.sub(replace, title).strip()


def expression_refs(line: str) -> list[str]:
    refs: list[str] = []
    for match in EXPR_TAG_RE.finditer(line):
        body = match.group('body').strip()
        if body.startswith('text:'):
            refs.append(f"text:{body[5:].split('|', 1)[0].strip()}")
        elif body.isdigit():
            refs.append(body)
        else:
            refs.append(f'text:{body}')
    return refs


def parse_sections(content: str) -> list[tuple[str | None, list[str], int]]:
    sections: list[tuple[str | None, list[str], int]] = []
    title: str | None = None
    level = 0
    refs: list[str] = []

    def flush() -> None:
        nonlocal title, refs
        if title is not None or refs:
            sections.append((title, refs, level))
        refs = []

    for line in content.splitlines():
        heading = HEADING_RE.match(line)
        if heading:
            heading_level = len(heading.group('marks'))
            # V1 uses level-2 headings as the handbook's real sections and
            # deeper headings as subheadings inside that section. Preserve
            # those subheading expressions instead of creating empty-looking
            # top-level sections for them.
            if heading_level >= 2:
                flush()
                title = clean_section_title(heading.group('title'))
                level = heading_level
            refs.extend(expression_refs(heading.group('title')))
            continue
        refs.extend(expression_refs(line))
    flush()
    return sections


def migrate_handbooks(
    handbook_rows: list[dict[str, object]],
    page_rows: list[dict[str, object]],
    expr_map: dict[str, str],
    users_by_id: dict[int, int] | None = None,
) -> dict[str, object]:
    handbooks: list[dict[str, object]] = []
    sections: list[dict[str, object]] = []
    items: list[dict[str, object]] = []
    report = {'dropped_free_text': 0, 'skipped_unmapped_items': 0, 'skipped_users': 0}
    users_by_id = users_by_id or {}

    pages_by_handbook: dict[object, list[dict[str, object]]] = {}
    for page in page_rows:
        pages_by_handbook.setdefault(page.get('handbook_id'), []).append(page)

    for handbook in handbook_rows:
        user_id = int(handbook.get('user_id') or 0)
        if users_by_id and user_id not in users_by_id:
            report['skipped_users'] += 1
            continue
        handbook_id = f"v1-handbook:{handbook.get('id')}"
        handbook_language_profile = map_expression_locale(str(handbook.get('source_lang') or ''))
        handbooks.append({
            'id': handbook_id,
            'user_id': users_by_id.get(user_id, user_id),
            'title': str(handbook.get('title') or ''),
            'language_profile_code': handbook_language_profile,
            'visibility': 'public' if handbook.get('is_public') in (1, '1', True) else 'private',
            'status': handbook.get('status') or 'published',
            'score': int(handbook.get('score') or 0),
            'created_at': handbook.get('created_at') or 'CURRENT_TIMESTAMP',
            'updated_at': handbook.get('updated_at') or handbook.get('created_at') or 'CURRENT_TIMESTAMP',
        })
        pages = sorted(pages_by_handbook.get(handbook.get('id'), []), key=lambda row: int(row.get('sort_order') or 0))
        contents = [str(page.get('content') or '') for page in pages] or [str(handbook.get('content') or '')]
        position = 0
        for content in contents:
            section_rows = parse_sections(content)
            section_ids: list[tuple[int, str]] = []
            for title, refs, level in section_rows:
                section_id = f'{handbook_id}:section:{position}'
                parent_id = next((sid for prior_level, sid in reversed(section_ids) if prior_level < level), None)
                sections.append({'id': section_id, 'handbook_id': handbook_id, 'title': title, 'position': position, 'parent_section_id': parent_id})
                section_ids.append((level, section_id))
                section_ids = [(prior_level, sid) for prior_level, sid in section_ids if prior_level <= level]
                for item_position, ref in enumerate(refs):
                    expression_id = expr_map.get(
                        f'text:{handbook_language_profile}:{ref[5:]}'
                        if handbook_language_profile and ref.startswith('text:')
                        else ref,
                    )
                    if expression_id is None:
                        report['skipped_unmapped_items'] += 1
                        continue
                    items.append({'section_id': section_id, 'expression_id': expression_id, 'position': item_position})
                position += 1

    return {'handbooks': handbooks, 'sections': sections, 'items': items, 'report': report}
