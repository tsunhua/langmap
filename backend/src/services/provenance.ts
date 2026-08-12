import type { D1Database } from '@cloudflare/workers-types';
import { findOrCreateSource } from './sources';

export interface SourceInput {
  type: string;
  name: string;
  ref?: string;
}

export interface ResolvedProvenance {
  source_id: string | null;
  source_ref: string | null;
}

export const NULL_SAFE_PROVENANCE_PREDICATE = 'source_id IS ? AND source_ref IS ?';

export async function resolveProvenance(
  db: D1Database,
  source?: SourceInput,
): Promise<ResolvedProvenance> {
  if (!source) return { source_id: null, source_ref: null };
  return {
    source_id: await findOrCreateSource(db, source),
    source_ref: source.ref?.trim() || null,
  };
}
