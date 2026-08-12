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
): Promise<string> {
  const type = source.type;
  if (!SOURCE_TYPES.includes(type as SourceType)) throw new SourceError('INVALID_SOURCE');
  const name = source.name.trim();
  if (!name) throw new SourceError('INVALID_SOURCE');
  const existing = await db
    .prepare('SELECT id FROM sources WHERE type = ? AND name = ?')
    .bind(type, name)
    .first<{ id: string }>();
  if (existing) return existing.id;
  const id = crypto.randomUUID();
  await db
    .prepare('INSERT INTO sources (id, type, name) VALUES (?, ?, ?)')
    .bind(id, type, name)
    .run();
  return id;
}
