from __future__ import annotations

import hashlib
from collections import defaultdict
from itertools import combinations


def migrate_mappings(
    expression_meanings: list[dict[str, object]],
    expression_map: dict[str, str],
) -> list[dict[str, object]]:
    """Turn v1 meaning membership into deterministic pairwise v2 edges."""
    by_meaning: dict[str, set[str]] = defaultdict(set)
    for row in expression_meanings:
        expression_id = expression_map.get(str(row.get('expression_id')))
        meaning_id = row.get('meaning_id')
        if expression_id and meaning_id is not None:
            by_meaning[str(meaning_id)].add(expression_id)

    edges: list[dict[str, object]] = []
    for meaning_id, expression_ids in sorted(by_meaning.items()):
        for expression_a_id, expression_b_id in combinations(sorted(expression_ids), 2):
            digest = hashlib.sha256(
                f'{meaning_id}:{expression_a_id}:{expression_b_id}'.encode()
            ).hexdigest()[:32]
            edges.append({
                'id': f'v1-meaning:{digest}',
                'expression_a_id': expression_a_id,
                'expression_b_id': expression_b_id,
                'score': 0,
                'source': 'v1-meaning-migration',
                'created_by': None,
            })
    return edges
