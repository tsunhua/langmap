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
    expect(sql).toContain('ev_managed.edge_id = ed.id');
    expect(sql).toContain('ev_active.edge_id = ed.id');
    expect(sql).toContain('active_release_id');
    expect(sql).not.toContain("e.source = 'dictionary'");
  });

  it('keeps the compatibility predicate while the ownership journal is absent', () => {
    const sql = releaseObjectEligibilityPredicate('reading', 'r.id');
    expect(sql).toBe('(1 = 1)');
    expect(dictionaryManagedObjectPredicate('edge', 'direct_edge.id')).toContain('direct_edge.id');
    expect(dictionaryManagedObjectPredicate('edge', 'direct_edge.id')).toContain("direct_edge.source = 'dictionary'");
  });

  it('makes promotion a no-op after removing per-object ownership', async () => {
    const db = {
      prepare: vi.fn(),
    } as unknown as import('@cloudflare/workers-types').D1Database;
    await promoteManagedObject(db, 'reading', 'r-1', { kind: 'user', userId: 7 });
    expect(db.prepare).not.toHaveBeenCalled();
  });
});
