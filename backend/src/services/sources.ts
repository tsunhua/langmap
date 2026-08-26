import type { D1Database } from '@cloudflare/workers-types';
import type { SourceType } from '../types/language';

const SOURCE_TYPES: readonly SourceType[] = ['publication', 'url', 'system'];

export class SourceError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'SourceError';
  }
}

export async function findOrCreateSource(
  db: D1Database,
  source: { type: string; name: string },
): Promise<number> {
  const type = source.type;
  if (!SOURCE_TYPES.includes(type as SourceType)) throw new SourceError('INVALID_SOURCE');
  const name = source.name.trim();
  if (!name) throw new SourceError('INVALID_SOURCE');
  const existing = await db
    .prepare('SELECT id FROM sources WHERE type = ? AND name = ?')
    .bind(type, name)
    .first<{ id: number }>();
  if (existing) return existing.id;
  const created = await db
    .prepare('INSERT INTO sources (type, name) VALUES (?, ?) RETURNING id')
    .bind(type, name)
    .first<{ id: number }>();
  if (!created) throw new SourceError('SOURCE_CREATE_FAILED');
  return created.id;
}
