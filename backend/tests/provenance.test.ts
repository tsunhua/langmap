import type { Database } from '../src/db/database';
import { describe, expect, it } from 'vitest';
import { SourceError } from '../src/services/sources';
import { resolveSource } from '../src/services/provenance';

function fakeDatabase(existingSource: { id: number } | null) {
  return {
    prepare(sql: string) {
      return {
        bind(..._args: unknown[]) {
          return {
            first: async <T>() => {
              if (sql === 'SELECT id FROM sources WHERE type = ? AND name = ?') return existingSource as T;
              if (sql === 'INSERT INTO sources (type, name) VALUES (?, ?) RETURNING id') return { id: 7 } as T;
              return null as T;
            },
          };
        },
      };
    },
  } as unknown as import('../src/db/database').Database;
}

describe('resolveSource', () => {
  it('resolves an existing named source to its integer id', async () => {
    await expect(resolveSource(fakeDatabase({ id: 12 }), { type: 'publication', name: 'Dictionary' })).resolves.toBe(12);
  });

  it('creates a missing source and returns the new integer id', async () => {
    await expect(resolveSource(fakeDatabase(null), { type: 'url', name: '某辭典' })).resolves.toBe(7);
  });

  it('returns null when no source is supplied', async () => {
    await expect(resolveSource(fakeDatabase(null))).resolves.toBeNull();
  });

  it('propagates SourceError for an invalid source input', async () => {
    await expect(resolveSource(fakeDatabase(null), { type: 'wiki', name: 'x' })).rejects.toBeInstanceOf(SourceError);
  });
});
