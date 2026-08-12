import { describe, expect, it } from 'vitest';
import { resolveProvenance } from '../src/services/provenance';

function fakeD1() {
  return {
    prepare(sql: string) {
      return {
        bind(..._args: unknown[]) {
          return {
            first: async <T>() =>
              (sql === 'SELECT id FROM sources WHERE type = ? AND name = ?'
                ? { id: 'src-dict' }
                : null) as T,
            run: async () => ({ success: true }),
          };
        },
      };
    },
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

describe('resolveProvenance', () => {
  it('represents a named source without a ref as a NULL-safe pair', async () => {
    await expect(resolveProvenance(fakeD1(), {
      type: 'publication',
      name: 'Dictionary',
    })).resolves.toEqual({ source_id: 'src-dict', source_ref: null });
  });

  it('returns a NULL pair when no source is supplied', async () => {
    await expect(resolveProvenance(fakeD1())).resolves.toEqual({ source_id: null, source_ref: null });
  });
});
