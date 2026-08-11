import { readFileSync } from 'fs';
import { describe, expect, it } from 'vitest';

const schema = readFileSync(new URL('../schema.sql', import.meta.url), 'utf8');

describe('greenfield schema contract', () => {
  it('defines the reference registry tables with the spec columns', () => {
    expect(schema).toMatch(/CREATE TABLE languages[\s\S]*?code TEXT PRIMARY KEY[\s\S]*?name_en TEXT NOT NULL/s);
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

  it('does not contain obsolete identity tables', () => {
    for (const table of ['languoids', 'language_subtags', 'language_varieties', 'language_profiles', 'language_locations']) {
      expect(schema).not.toMatch(new RegExp(`CREATE TABLE ${table}`));
    }
  });
});
