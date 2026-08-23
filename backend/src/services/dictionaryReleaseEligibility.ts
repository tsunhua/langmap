import type { D1Database } from '@cloudflare/workers-types';

export type EdgeAlias = 'e' | 'ed' | 'g' | 'direct_edge';
export type ManagedObjectKind = 'expression' | 'reading' | 'locale_attestation' | 'pos_attestation';
export type ManagedObjectKindWithEdge = ManagedObjectKind | 'edge';
export type ManagedObjectIdSql = 'e.id' | 'r.id' | 'a.id' | 'pa.id';
export type ManagedObjectIdSqlWithEdge = ManagedObjectIdSql | 'e.id' | 'ed.id' | 'g.id' | 'direct_edge.id';
export type ReleaseIdSql = 'b.release_id' | 'ev.release_id' | 'pa.release_id' | 'ro.release_id';

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
      SELECT 1 FROM dictionary_release_objects ro_created
      WHERE ro_created.object_kind = 'edge'
        AND ro_created.object_id = ${edgeId}
        AND ro_created.object_action = 'created'
        AND ro_created.promoted_at IS NULL
    )
    OR EXISTS (
      SELECT 1 FROM expression_edge_evidence ev
      WHERE ev.edge_id = ${edgeId}
        AND ${activeReleaseMembership('ev.release_id')}
    )
  )`;
}

export function releaseObjectEligibilityPredicate(
  kind: ManagedObjectKind,
  objectIdSql: ManagedObjectIdSql,
): string {
  return `(
    NOT EXISTS (
      SELECT 1 FROM dictionary_release_objects ro_created
      WHERE ro_created.object_kind = '${kind}'
        AND ro_created.object_id = ${objectIdSql}
        AND ro_created.object_action = 'created'
        AND ro_created.promoted_at IS NULL
    )
    OR EXISTS (
      SELECT 1 FROM dictionary_release_objects ro_active
      WHERE ro_active.object_kind = '${kind}'
        AND ro_active.object_id = ${objectIdSql}
        AND ${activeReleaseMembership('ro_active.release_id')}
    )
  )`;
}

/** Historical ownership guard used by immutable split operations. */
export function dictionaryManagedObjectPredicate(
  kind: ManagedObjectKindWithEdge,
  objectIdSql: ManagedObjectIdSqlWithEdge,
): string {
  return `(EXISTS (
    SELECT 1 FROM dictionary_release_objects ro_managed
    WHERE ro_managed.object_kind = '${kind}'
      AND ro_managed.object_id = ${objectIdSql}
      AND ro_managed.object_action = 'created'
  ))`;
}

export async function promoteManagedObject(
  db: D1Database,
  kind: ManagedObjectKindWithEdge,
  objectId: string,
  actor: PromotionActor,
): Promise<void> {
  const actorKind = actor.kind;
  const actorId = actor.kind === 'user' ? actor.userId : null;
  await db.prepare(
    `UPDATE dictionary_release_objects
     SET promoted_at = CURRENT_TIMESTAMP,
         promotion_actor_kind = ?,
         promoted_by = ?
     WHERE object_kind = ?
       AND object_id = ?
       AND object_action = 'created'
       AND promoted_at IS NULL`,
  ).bind(actorKind, actorId, kind, objectId).run();
}
