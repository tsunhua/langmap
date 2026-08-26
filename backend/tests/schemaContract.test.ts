import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const schema = readFileSync(new URL('../schema.sql', import.meta.url), 'utf8');

describe('canonical integer schema contract', () => {
  it('uses integer identity keys and canonical language relationships', () => {
    expect(schema).toMatch(/CREATE TABLE languages[\s\S]*?id INTEGER PRIMARY KEY AUTOINCREMENT[\s\S]*?code TEXT NOT NULL UNIQUE/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?id INTEGER PRIMARY KEY AUTOINCREMENT[\s\S]*?language_id INTEGER NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?id INTEGER PRIMARY KEY AUTOINCREMENT[\s\S]*?language_id INTEGER NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?pos_mask INTEGER NOT NULL DEFAULT 0/s);
    expect(schema).toMatch(/CREATE UNIQUE INDEX idx_language_locales_identity/);
  });

  it('uses compact locale, reading, edge and vote tables', () => {
    expect(schema).toMatch(/CREATE TABLE expression_locale_links[\s\S]*?PRIMARY KEY \(expression_id, locale_id\)[\s\S]*?WITHOUT ROWID/s);
    expect(schema).toMatch(/CREATE TABLE expression_readings[\s\S]*?PRIMARY KEY \(expression_id, locale_id, scheme, value\)[\s\S]*?WITHOUT ROWID/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?relation_mask INTEGER NOT NULL DEFAULT 1/s);
    expect(schema).toMatch(/CREATE TABLE edge_votes[\s\S]*?PRIMARY KEY \(user_id, edge_id\)[\s\S]*?WITHOUT ROWID/s);
    expect(schema).toMatch(/CREATE TABLE handbook_votes[\s\S]*?PRIMARY KEY \(user_id, handbook_id\)[\s\S]*?WITHOUT ROWID/s);
  });

  it('defines handbook, morphology, split and UI integer foreign keys', () => {
    expect(schema).toMatch(/CREATE TABLE handbooks[\s\S]*?language_locale_id INTEGER/s);
    expect(schema).toMatch(/CREATE TABLE handbook_sections[\s\S]*?id INTEGER PRIMARY KEY AUTOINCREMENT/s);
    expect(schema).toMatch(/CREATE TABLE handbook_section_items[\s\S]*?PRIMARY KEY \(section_id, position\)[\s\S]*?WITHOUT ROWID/s);
    expect(schema).toMatch(/CREATE TABLE expression_form_edges[\s\S]*?id INTEGER PRIMARY KEY AUTOINCREMENT/s);
    expect(schema).toMatch(/CREATE TRIGGER trg_expression_form_edges_no_reverse/);
    expect(schema).toMatch(/CREATE TABLE expression_split_moves[\s\S]*?PRIMARY KEY \(split_id, edge_id\)[\s\S]*?WITHOUT ROWID/s);
    expect(schema).toMatch(/CREATE TABLE ui_locales[\s\S]*?locale_id INTEGER NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE ui_messages[\s\S]*?source_expression_id INTEGER NOT NULL/s);
  });

  it('keeps POS bits stable and removes release and packed tables', () => {
    expect(schema).toMatch(/CREATE TABLE parts_of_speech[\s\S]*?bit_index INTEGER NOT NULL UNIQUE[\s\S]*?CHECK \(bit_index BETWEEN 0 AND 62\)/s);
    for (const table of [
      'dictionary_dataset_releases', 'dictionary_dataset_state',
      'dictionary_expression_bindings', 'expression_edge_evidence',
      'expression_pos_attestations', 'dictionary_languages', 'dictionary_locales',
      'dictionary_terms', 'dictionary_readings', 'dictionary_edges',
    ]) expect(schema).not.toMatch(new RegExp(`CREATE TABLE ${table}`));
    expect(schema).not.toMatch(/CREATE VIEW all_expression_rows/);
  });

  it('keeps only the canonical explicit indexes and reverse form trigger', () => {
    for (const index of [
      'idx_language_locales_identity', 'idx_expressions_language_created',
      'idx_expression_locale_links_locale', 'idx_expression_edges_b_id',
      'idx_edge_votes_edge', 'idx_handbook_votes_handbook',
      'idx_handbooks_visibility_created', 'idx_handbooks_visibility_score',
      'idx_handbook_sections_parent', 'idx_expression_form_edges_lemma_id',
      'idx_ui_messages_source_expression',
    ]) expect(schema).toContain(index);
    for (const removed of [
      'idx_expression_edges_score_feed', 'idx_expression_edges_created_by_at',
      'idx_handbook_section_items_section', 'idx_expression_form_edges_form_id',
      'idx_votes_target', 'idx_users_username', 'idx_users_email',
    ]) expect(schema).not.toContain(removed);
  });
});
