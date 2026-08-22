import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const schema = readFileSync(new URL('../schema.sql', import.meta.url), 'utf8');
const migration = readFileSync(new URL('../migrations/0031_mapping_query_indexes.sql', import.meta.url), 'utf8');

describe('mapping query indexes', () => {
  it('keeps the greenfield schema and incremental migration aligned', () => {
    const indexes = [
      'idx_expression_edges_a_id',
      'idx_expression_edges_b_id',
      'idx_ui_messages_source_expression',
    ];

    for (const index of indexes) {
      expect(schema).toContain(index);
      expect(migration).toContain(`CREATE INDEX IF NOT EXISTS ${index}`);
    }
  });
});
