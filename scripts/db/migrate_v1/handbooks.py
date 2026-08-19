from __future__ import annotations

import re


EXPR_TAG_RE = re.compile(r'\{\{(?P<body>[^{}]+)\}\}')
HEADING_RE = re.compile(r'^#{2,6}\s+(.+?)\s*$')


def parse_sections(content: str) -> list[tuple[str | None, list[str]]]:
    sections: list[tuple[str | None, list[str]]] = []
    title: str | None = None
    refs: list[str] = []

    def flush() -> None:
        nonlocal title, refs
        if title is not None or refs:
            sections.append((title, refs))
        refs = []

    for line in content.splitlines():
        heading = HEADING_RE.match(line)
        if heading:
            flush()
            title = heading.group(1).strip()
            continue
        for match in EXPR_TAG_RE.finditer(line):
            body = match.group('body').strip()
            if body.startswith('text:'):
                text = body[5:].split('|', 1)[0].strip()
                refs.append(f'text:{text}')
            elif body.isdigit():
                refs.append(body)
            else:
                refs.append(f'text:{body}')
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
        handbooks.append({
            'id': handbook_id,
            'user_id': users_by_id.get(user_id, user_id),
            'title': str(handbook.get('title') or ''),
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
            for title, refs in parse_sections(content):
                section_id = f'{handbook_id}:section:{position}'
                sections.append({'id': section_id, 'handbook_id': handbook_id, 'title': title, 'position': position})
                for item_position, ref in enumerate(refs):
                    expression_id = expr_map.get(ref)
                    if expression_id is None:
                        report['skipped_unmapped_items'] += 1
                        continue
                    items.append({'section_id': section_id, 'expression_id': expression_id, 'position': item_position})
                position += 1

    return {'handbooks': handbooks, 'sections': sections, 'items': items, 'report': report}
