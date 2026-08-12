import type { D1Database, D1PreparedStatement } from '@cloudflare/workers-types';
import type { EdgeRow } from '../types/mapping';
import { buildExpressionId } from './expressionIdentity';

const EXPRESSION_COLUMNS = `id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at`;
const EDGE_COLUMNS = `id, expression_a_id, expression_b_id, score, source, created_by, created_at`;

export class SplitError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'SplitError';
  }
}

export async function splitExpression(
  db: D1Database,
  input: { source_expression_id: string; edge_ids: string[]; created_by: number },
): Promise<{ split_id: string; target_expression_id: string; moved_edge_count: number }> {
  if (!input.edge_ids.length) throw new SplitError('EXPRESSION_SPLIT_EMPTY');

  const source = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(input.source_expression_id)
    .first<{ id: string; lang_code: string; text: string; text_hash: string; homograph_index: number }>();
  if (!source) throw new SplitError('EXPRESSION_NOT_FOUND');

  const placeholders = input.edge_ids.map(() => '?').join(', ');
  const { results: edges } = await db
    .prepare(`SELECT ${EDGE_COLUMNS} FROM expression_edges WHERE id IN (${placeholders})`)
    .bind(...input.edge_ids)
    .all<EdgeRow>();

  if (edges.length !== input.edge_ids.length) throw new SplitError('EXPRESSION_SPLIT_EDGE_NOT_ADJACENT');
  for (const edge of edges) {
    if (edge.expression_a_id !== input.source_expression_id && edge.expression_b_id !== input.source_expression_id) {
      throw new SplitError('EXPRESSION_SPLIT_EDGE_NOT_ADJACENT');
    }
  }

  const maxRow = await db
    .prepare('SELECT MAX(homograph_index) AS max_idx FROM expressions WHERE lang_code = ? AND text_hash = ?')
    .bind(source.lang_code, source.text_hash)
    .first<{ max_idx: number | null }>();
  const nextIndex = (maxRow?.max_idx ?? 0) + 1;
  const targetId = buildExpressionId(source.lang_code, source.text_hash, nextIndex);
  const splitId = crypto.randomUUID();

  const statements: D1PreparedStatement[] = [];

  statements.push(
    db.prepare(
      `INSERT INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(
      targetId, source.lang_code, source.text, source.text_hash, nextIndex,
      source.description ?? '', source.tags_json ?? '[]',
      'system-split', `split:${splitId}`, 'pending', input.created_by,
    ),
  );

  statements.push(
    db.prepare(
      'INSERT INTO expression_splits (id, source_expression_id, target_expression_id, created_by) VALUES (?, ?, ?, ?)',
    ).bind(splitId, input.source_expression_id, targetId, input.created_by),
  );

  for (const edge of edges) {
    const otherId = edge.expression_a_id === input.source_expression_id ? edge.expression_b_id : edge.expression_a_id;
    const [newA, newB] = otherId < targetId ? [otherId, targetId] : [targetId, otherId];

    statements.push(
      db.prepare('UPDATE expression_edges SET expression_a_id = ?, expression_b_id = ? WHERE id = ?').bind(newA, newB, edge.id),
    );

    statements.push(
      db.prepare(
        'INSERT INTO expression_split_moves (split_id, edge_id, previous_a_id, previous_b_id, new_a_id, new_b_id) VALUES (?, ?, ?, ?, ?, ?)',
      ).bind(splitId, edge.id, edge.expression_a_id, edge.expression_b_id, newA, newB),
    );
  }

  try {
    await db.batch(statements);
  } catch (error) {
    const msg = String((error as { message?: string })?.message ?? '');
    if (msg.includes('UNIQUE constraint failed')) throw new SplitError('EXPRESSION_SPLIT_CONFLICT');
    throw error;
  }

  return { split_id: splitId, target_expression_id: targetId, moved_edge_count: edges.length };
}
