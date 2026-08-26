import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const schema = readFileSync(new URL('../schema.sql', import.meta.url), 'utf8');

function explicitIndexes(): string[] {
  return [...schema.matchAll(/CREATE (?:UNIQUE )?INDEX (\w+)/g)].map((match) => match[1]);
}

describe('canonical query indexes', () => {
  it('has the required adjacency, identity and list indexes', () => {
    const indexes = explicitIndexes();
    for (const name of [
      'idx_language_locales_identity', 'idx_expressions_language_created',
      'idx_expression_locale_links_locale', 'idx_expression_edges_b_id',
      'idx_edge_votes_edge', 'idx_handbook_votes_handbook',
      'idx_handbooks_visibility_created', 'idx_handbooks_visibility_score',
      'idx_handbook_sections_parent', 'idx_expression_form_edges_lemma_id',
      'idx_ui_messages_source_expression',
    ]) expect(indexes).toContain(name);
  });

  it('does not recreate removed feed, creator, source or mirror indexes', () => {
    const indexes = explicitIndexes();
    for (const name of [
      'idx_expression_edges_a_id', 'idx_expression_edges_score_feed',
      'idx_expression_edges_created_at', 'idx_expression_edges_created_by_at',
      'idx_expressions_created_at', 'idx_expressions_created_by_at',
      'idx_handbooks_user_created_at', 'idx_handbook_section_items_section',
      'idx_expression_form_edges_form_id', 'idx_expression_form_edge_features_feature_code',
    ]) expect(indexes).not.toContain(name);
  });

  it('uses integer columns for all high-volume adjacency paths', () => {
    expect(schema).toMatch(/CREATE INDEX idx_expression_edges_b_id ON expression_edges\(expression_b_id\)/);
    expect(schema).toMatch(/CREATE INDEX idx_expression_locale_links_locale ON expression_locale_links\(locale_id, expression_id\)/);
    expect(schema).toMatch(/CREATE INDEX idx_expressions_language_created ON expressions\(language_id, created_at DESC\)/);
  });
});
