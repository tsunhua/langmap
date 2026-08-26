import type { D1Database } from '@cloudflare/workers-types';
import { findOrCreateSource } from './sources';

export interface SourceInput { type: string; name: string; }

/** Resolve the optional shared source without duplicating source text per row. */
export async function resolveSource(db: D1Database, source?: SourceInput): Promise<number | null> {
  return source ? findOrCreateSource(db, source) : null;
}
