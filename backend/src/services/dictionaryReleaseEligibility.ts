import type { D1Database } from '@cloudflare/workers-types';

export type EdgeAlias = 'e' | 'ed' | 'g' | 'direct_edge';
export type ManagedObjectKind = 'expression' | 'reading' | 'locale_attestation' | 'pos_attestation';
export type ManagedObjectKindWithEdge = ManagedObjectKind | 'edge';
export type ManagedObjectIdSql = 'e.id' | 'r.id' | 'a.id' | 'pa.id';
export type ManagedObjectIdSqlWithEdge = ManagedObjectIdSql | 'e.id' | 'ed.id' | 'g.id' | 'direct_edge.id';
export type ReleaseIdSql = 'b.release_id' | 'ev.release_id' | 'pa.release_id';

export const MANAGED_DICTIONARY_DATASET_KEY = 'managed-dictionaries';

export async function dictionaryReleaseSchemaAvailable(db: D1Database): Promise<boolean> {
  try {
    const row = await db.prepare(
      "SELECT 1 AS available FROM sqlite_master WHERE type = 'table' AND name = 'dictionary_dataset_state'",
    ).bind().first<{ available: number }>();
    return Boolean(row?.available);
  } catch {
    return false;
  }
}

/**
 * Packed dictionary tables were introduced after the release lifecycle tables.
 * Keep the fast path opt-in so a database caught between those migrations can
 * continue using the compatibility queries.
 */
export async function dictionaryPackedSchemaAvailable(db: D1Database): Promise<boolean> {
  try {
    const row = await db.prepare(
      `SELECT COUNT(*) AS available
       FROM sqlite_master
       WHERE type = 'table'
         AND name IN ('dictionary_languages', 'dictionary_terms', 'dictionary_edges')`,
    ).bind().first<{ available: number }>();
    return Number(row?.available ?? 0) === 3;
  } catch {
    return false;
  }
}

export type PromotionActor =
  | { kind: 'user'; userId: number }
  | { kind: 'system' };

/**
 * The dataset state row is the only visibility switch. Release status is
 * deliberately absent here because a validated release may be inactive.
 */
export function activeReleasePredicate(releaseIdSql: ReleaseIdSql): string {
  return `(EXISTS (SELECT 1 FROM dictionary_dataset_state ds
    WHERE ds.dataset_key = '${MANAGED_DICTIONARY_DATASET_KEY}'
      AND ds.active_release_id = ${releaseIdSql}))`;
}

function activeReleaseMembership(releaseIdSql: string): string {
  return `(${activeReleasePredicate(releaseIdSql as ReleaseIdSql)})`;
}

export function edgeEligibilityPredicate(edgeAlias: EdgeAlias): string {
  const edgeId = `${edgeAlias}.id`;
  return `(
    NOT EXISTS (
      SELECT 1 FROM expression_edge_evidence ev_managed
      WHERE ev_managed.edge_id = ${edgeId}
    )
    OR EXISTS (
      SELECT 1 FROM expression_edge_evidence ev_active
      WHERE ev_active.edge_id = ${edgeId}
        AND ${activeReleaseMembership('ev_active.release_id')}
    )
  )`;
}

export function releaseObjectEligibilityPredicate(
  kind: ManagedObjectKind,
  objectIdSql: ManagedObjectIdSql,
): string {
  // Readings and locale attestations do not carry a release_id.  With the
  // ownership journal removed, their ordinary entity visibility is the only
  // safe predicate; POS visibility is already release-scoped by its table.
  void kind;
  void objectIdSql;
  return '(1 = 1)';
}

/** Managed-edge guard used by immutable split operations. */
export function dictionaryManagedObjectPredicate(
  kind: ManagedObjectKindWithEdge,
  objectIdSql: ManagedObjectIdSqlWithEdge,
): string {
  if (kind !== 'edge') return '(0 = 1)';
  const edgeAlias = objectIdSql.replace(/\.id$/, '');
  return `(${edgeAlias}.source = 'dictionary' OR EXISTS (
    SELECT 1 FROM expression_edge_evidence ev_managed
    WHERE ev_managed.edge_id = ${objectIdSql}
  ))`;
}

export async function promoteManagedObject(
  db: D1Database,
  kind: ManagedObjectKindWithEdge,
  objectId: string,
  actor: PromotionActor,
): Promise<void> {
  // There is no per-object ownership journal.  Ordinary writes remain visible
  // through the base entity tables, while managed edges are scoped by their
  // evidence membership in edgeEligibilityPredicate().
  void db;
  void kind;
  void objectId;
  void actor;
}
