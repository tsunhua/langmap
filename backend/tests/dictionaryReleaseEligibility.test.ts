import { describe, expect, it, vi } from 'vitest';
import {
  activeReleasePredicate,
  dictionaryManagedObjectPredicate,
  edgeEligibilityPredicate,
  promoteManagedObject,
  releaseObjectEligibilityPredicate,
} from '../src/services/dictionaryReleaseEligibility';

describe('dictionary release eligibility SQL', () => {
  it('uses the dataset state pointer for active releases', () => {
    const sql = activeReleasePredicate('b.release_id');
    expect(sql).toContain('dictionary_dataset_state');
    expect(sql).toContain("ds.dataset_key = 'managed-dictionaries'");
    expect(sql).toContain('ds.active_release_id = b.release_id');
  });

  it('allows unmanaged or active evidence edges', () => {
    const sql = edgeEligibilityPredicate('ed');
    expect(sql).toContain('expression_edge_evidence');
    expect(sql).toContain('dictionary_release_objects');
    expect(sql).toContain("ro_created.object_kind = 'edge'");
    expect(sql).toContain('ev.edge_id = ed.id');
    expect(sql).toContain('active_release_id');
    expect(sql).not.toContain("e.source = 'dictionary'");
  });

  it('keeps object kinds and aliases closed', () => {
    const sql = releaseObjectEligibilityPredicate('reading', 'r.id');
    expect(sql).toContain("ro_created.object_kind = 'reading'");
    expect(sql).toContain('ro_created.object_id = r.id');
    expect(sql).toContain("ro_active.object_kind = 'reading'");
    expect(dictionaryManagedObjectPredicate('edge', 'direct_edge.id')).toContain('direct_edge.id');
  });

  it('promotes only unpromoted historical created ownership rows', async () => {
    const run = vi.fn(async () => ({ success: true }));
    const db = {
      prepare: vi.fn(() => ({ bind: vi.fn(() => ({ run })) })),
    } as unknown as import('@cloudflare/workers-types').D1Database;
    await promoteManagedObject(db, 'reading', 'r-1', { kind: 'user', userId: 7 });
    expect(run).toHaveBeenCalledOnce();
    const prepareSql = (db.prepare as ReturnType<typeof vi.fn>).mock.calls[0][0] as string;
    expect(prepareSql).toContain("object_action = 'created'");
    expect(prepareSql).toContain('promoted_at IS NULL');
    expect((db.prepare as ReturnType<typeof vi.fn>).mock.results[0].value.bind).toBeDefined();
  });
});
