import { readFileSync } from 'fs';
import { describe, expect, it } from 'vitest';

const schema = readFileSync(new URL('../schema.sql', import.meta.url), 'utf8');

describe('greenfield schema contract', () => {
  it('defines the reference registry tables with the spec columns', () => {
    expect(schema).toMatch(/CREATE TABLE languages[\s\S]*?code TEXT PRIMARY KEY[\s\S]*?name_en TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE languages[\s\S]*?name_expression_id TEXT REFERENCES expressions\(id\)/s);
    expect(schema).toMatch(/CREATE TABLE scripts[\s\S]*?code TEXT PRIMARY KEY[\s\S]*?direction TEXT NOT NULL CHECK \(direction IN \('ltr', 'rtl'\)\)/s);
    expect(schema).toMatch(/CREATE TABLE regions[\s\S]*?code TEXT PRIMARY KEY[\s\S]*?CHECK \(\(latitude IS NULL\) = \(longitude IS NULL\)\)/s);
  });

  it('keeps the users table for auth', () => {
    expect(schema).toMatch(/CREATE TABLE users/);
  });

  it('defines the sources table for two-layer provenance', () => {
    expect(schema).toMatch(/CREATE TABLE sources[\s\S]*?type TEXT NOT NULL CHECK \(type IN \('publication', 'url', 'system'\)\)[\s\S]*?UNIQUE \(type, name\)/s);
    expect(schema).toMatch(/CREATE TABLE sources[\s\S]*?FOREIGN KEY \(created_by\) REFERENCES users\(id\)/s);
  });

  it('defines language_locales with the spec columns and checks', () => {
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?code TEXT PRIMARY KEY/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?name TEXT NOT NULL[\s\S]*?name_en TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?name_expression_id TEXT REFERENCES expressions\(id\)/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?UNIQUE \(lang_code, script_code, region_code, place_path\)/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?CHECK \(\(latitude IS NULL\) = \(longitude IS NULL\)\)/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?CHECK \(source_ref IS NULL OR source_id IS NOT NULL\)/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?FOREIGN KEY \(lang_code\) REFERENCES languages\(code\)[\s\S]*?FOREIGN KEY \(script_code\) REFERENCES scripts\(code\)[\s\S]*?FOREIGN KEY \(region_code\) REFERENCES regions\(code\)[\s\S]*?FOREIGN KEY \(source_id\) REFERENCES sources\(id\)/s);
  });

  it('seeds the three system locales', () => {
    expect(schema).toMatch(/eng-Latn-US/);
    expect(schema).toMatch(/cmn-Hant-TW/);
    expect(schema).toMatch(/cmn-Hans-CN/);
  });

  it('defines expressions with identity fields and hash constraints', () => {
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?id TEXT PRIMARY KEY/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?text_hash TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?homograph_index INTEGER NOT NULL DEFAULT 1 CHECK \(homograph_index >= 1\)/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?UNIQUE \(lang_code, text, homograph_index\)[\s\S]*?UNIQUE \(lang_code, text_hash, homograph_index\)/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?CHECK \(source_ref IS NULL OR source_id IS NOT NULL\)/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?FOREIGN KEY \(lang_code\) REFERENCES languages\(code\)[\s\S]*?FOREIGN KEY \(source_id\) REFERENCES sources\(id\)/s);
  });

  it('defines expression_locale_attestations with provenance and uniqueness', () => {
    expect(schema).toMatch(/CREATE TABLE expression_locale_attestations[\s\S]*?id TEXT PRIMARY KEY/s);
    expect(schema).toMatch(/CREATE TABLE expression_locale_attestations[\s\S]*?language_locale_code TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expression_locale_attestations[\s\S]*?UNIQUE \(expression_id, language_locale_code, source_id, source_ref\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_locale_attestations[\s\S]*?CHECK \(source_ref IS NULL OR source_id IS NOT NULL\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_locale_attestations[\s\S]*?FOREIGN KEY \(expression_id\) REFERENCES expressions\(id\)[\s\S]*?FOREIGN KEY \(language_locale_code\) REFERENCES language_locales\(code\)[\s\S]*?FOREIGN KEY \(source_id\) REFERENCES sources\(id\)/s);
  });

  it('defines expression_edges with pair ordering check and uniqueness', () => {
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?id TEXT PRIMARY KEY/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?score INTEGER NOT NULL DEFAULT 0/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?source TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?CHECK \(expression_a_id < expression_b_id\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?UNIQUE \(expression_a_id, expression_b_id\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?FOREIGN KEY \(expression_a_id\) REFERENCES expressions\(id\)[\s\S]*?FOREIGN KEY \(expression_b_id\) REFERENCES expressions\(id\)/s);
  });

  it('defines expression_splits and expression_split_moves audit tables', () => {
    expect(schema).toMatch(/CREATE TABLE expression_splits[\s\S]*?source_expression_id TEXT NOT NULL[\s\S]*?target_expression_id TEXT NOT NULL[\s\S]*?created_by INTEGER NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expression_splits[\s\S]*?FOREIGN KEY \(source_expression_id\) REFERENCES expressions\(id\)[\s\S]*?FOREIGN KEY \(target_expression_id\) REFERENCES expressions\(id\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_split_moves[\s\S]*?split_id TEXT NOT NULL[\s\S]*?edge_id TEXT NOT NULL[\s\S]*?PRIMARY KEY \(split_id, edge_id\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_split_moves[\s\S]*?previous_a_id[\s\S]*?new_a_id/s);
  });

  it('seeds the system-split source for split provenance', () => {
    expect(schema).toMatch(/system-split/);
  });

  it('defines expression_readings with scheme, value and provenance uniqueness', () => {
    expect(schema).toMatch(/CREATE TABLE expression_readings[\s\S]*?scheme TEXT NOT NULL[\s\S]*?value TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expression_readings[\s\S]*?UNIQUE \(expression_id, language_locale_code, scheme, value, source_id, source_ref\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_readings[\s\S]*?CHECK \(source_ref IS NULL OR source_id IS NOT NULL\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_readings[\s\S]*?FOREIGN KEY \(expression_id\) REFERENCES expressions\(id\)[\s\S]*?FOREIGN KEY \(language_locale_code\) REFERENCES language_locales\(code\)/s);
  });

  it('defines user_preferences with composite key and cascade delete', () => {
    expect(schema).toMatch(/CREATE TABLE user_preferences[\s\S]*?PRIMARY KEY \(user_id, preference_key\)/s);
    expect(schema).toMatch(/CREATE TABLE user_preferences[\s\S]*?FOREIGN KEY \(user_id\) REFERENCES users\(id\) ON DELETE CASCADE/s);
  });

  it('defines ui_locales with status, revision and activation tracking', () => {
    expect(schema).toMatch(/CREATE TABLE ui_locales[\s\S]*?PRIMARY KEY \(project_id, language_locale_code\)/s);
    expect(schema).toMatch(/CREATE TABLE ui_locales[\s\S]*?CHECK \(status IN \('draft', 'active', 'archived'\)\)/s);
    expect(schema).toMatch(/CREATE TABLE ui_locales[\s\S]*?mapping_revision INTEGER NOT NULL DEFAULT 0/s);
    expect(schema).toMatch(/CREATE TABLE ui_locales[\s\S]*?CHECK \(activation_source IN \('system', 'auto', 'manual'\)\)/s);
  });

  it('defines ui_messages with source expression FK', () => {
    expect(schema).toMatch(/CREATE TABLE ui_messages[\s\S]*?source_expression_id TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE ui_messages[\s\S]*?PRIMARY KEY \(project_id, message_key\)/s);
    expect(schema).toMatch(/CREATE TABLE ui_messages[\s\S]*?FOREIGN KEY \(source_expression_id\) REFERENCES expressions\(id\)/s);
  });

  it('seeds eng-Latn-US as the system source UI locale for langmap-web', () => {
    expect(schema).toMatch(/langmap-web.*eng-Latn-US.*active.*system/s);
  });

  it('defines votes with generic target and bounded vote value', () => {
    expect(schema).toMatch(/CREATE TABLE votes[\s\S]*?target_id TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE votes[\s\S]*?CHECK \(vote IN \(-1, 1\)\)/s);
    expect(schema).toMatch(/CREATE TABLE votes[\s\S]*?UNIQUE \(user_id, target_type, target_id\)/s);
  });

  it('does not contain obsolete identity tables', () => {
    for (const table of ['languoids', 'language_subtags', 'language_varieties', 'language_profiles', 'language_locations']) {
      expect(schema).not.toMatch(new RegExp(`CREATE TABLE ${table}`));
    }
  });
});
