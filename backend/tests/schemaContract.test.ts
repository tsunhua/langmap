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

  it('does not contain obsolete identity tables', () => {
    for (const table of ['languoids', 'language_subtags', 'language_varieties', 'language_profiles', 'language_locations']) {
      expect(schema).not.toMatch(new RegExp(`CREATE TABLE ${table}`));
    }
  });
});
