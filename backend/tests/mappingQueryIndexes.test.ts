import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const schema = readFileSync(new URL('../schema.sql', import.meta.url), 'utf8');
const migration = readFileSync(new URL('../migrations/0031_mapping_query_indexes.sql', import.meta.url), 'utf8');
const performanceMigration = readFileSync(new URL('../migrations/0033_api_performance_indexes.sql', import.meta.url), 'utf8');

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

  it('defines the feed and user activity indexes with stable tie-breakers', () => {
    const indexes = [
      'idx_expression_edges_score_feed',
      'idx_expressions_created_by_at',
      'idx_expression_edges_created_by_at',
      'idx_handbooks_user_created_at',
      'idx_votes_user_created_at',
    ];

    for (const index of indexes) {
      expect(schema).toContain(index);
      expect(performanceMigration).toContain(`CREATE INDEX IF NOT EXISTS ${index}`);
    }

    expect(schema).toMatch(/idx_expression_edges_score_feed[\s\S]*?ON expression_edges\(score DESC, created_at DESC, id ASC\)/);
    expect(schema).toMatch(/idx_expressions_created_by_at[\s\S]*?ON expressions\(created_by, created_at DESC, id ASC\)/);
    expect(schema).toMatch(/idx_expression_edges_created_by_at[\s\S]*?ON expression_edges\(created_by, created_at DESC, id ASC\)/);
    expect(schema).toMatch(/idx_handbooks_user_created_at[\s\S]*?ON handbooks\(user_id, created_at DESC, id ASC\)/);
    expect(schema).toMatch(/idx_votes_user_created_at[\s\S]*?ON votes\(user_id, created_at DESC, target_id\)/);
  });
});
