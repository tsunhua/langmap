import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { parentLocaleCodes, placeholders, samePlaceholders, selectLocalizedRows, validText } from '../src/routes/localization';

describe('localization pure rules', () => {
  it('builds BCP47 parent candidates from most specific to least specific', () => {
    expect(parentLocaleCodes('zh-Hant-TW')).toEqual(['zh-Hant', 'zh']);
    expect(parentLocaleCodes('en')).toEqual([]);
  });

  it('requires exactly the same placeholders, independent of order', () => {
    expect(placeholders('{count} result | {count} results')).toEqual(['count', 'count']);
    expect(samePlaceholders('Hello, {name}', '你好，{name}')).toBe(true);
    expect(samePlaceholders('Hello, {name}', '你好')).toBe(false);
    expect(samePlaceholders('{a} {b}', '{b} {a}', '["a","b"]')).toBe(true);
  });

  it('rejects empty, HTML, control characters and overlong translation text', () => {
    expect(validText('')).toBe(false);
    expect(validText('  ')).toBe(false);
    expect(validText('<b>unsafe</b>')).toBe(false);
    expect(validText('line\u0000break')).toBe(false);
    expect(validText('a'.repeat(4001))).toBe(false);
    expect(validText('正常文字')).toBe(true);
  });

  it('selects locale first, then score, creation time and expression id', () => {
    const rows = [
      { key: 'greeting', locale_code: 'en', text: 'English', score: 100, edge_created_at: '2026-01-01', target_id: 2 },
      { key: 'greeting', locale_code: 'zh-Hant', text: '較早', score: 1, edge_created_at: '2026-01-01', target_id: 9 },
      { key: 'greeting', locale_code: 'zh-Hant', text: '較高分', score: 5, edge_created_at: '2026-01-02', target_id: 8 },
      { key: 'farewell', locale_code: 'zh', text: '再見', score: 0, edge_created_at: '2026-01-01', target_id: 7 },
    ];
    expect(selectLocalizedRows(rows, ['zh-Hant', 'zh', 'en'])).toEqual({ greeting: '較高分', farewell: '再見' });
    expect(selectLocalizedRows([
      { key: 'x', locale_code: 'zh-Hant', text: '後建', score: 2, edge_created_at: '2026-02-01', target_id: 10 },
      { key: 'x', locale_code: 'zh-Hant', text: '先建', score: 2, edge_created_at: '2026-01-01', target_id: 11 },
    ], ['zh-Hant'])).toEqual({ x: '先建' });
  });
});

describe('localization mutation-boundary guard', () => {
  const BASE_URL = 'http://127.0.0.1:8788';

  async function registerUser(username: string): Promise<string> {
    const res = await fetch(`${BASE_URL}/api/v2/auth/register`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ username, email: `${username}@example.com`, password: 'pass1234' }),
    });
    expect(res.status).toBe(201);
    const body = await res.json() as { data: { token: string } };
    return body.data.token;
  }

  it('rejects locale creation with an unregistered language code', async () => {
    const token = await registerUser(`loc-unreg-${Date.now()}`);
    const res = await fetch(`${BASE_URL}/api/v2/localization/projects/langmap-web/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ code: 'en-x-unlisted' }),
    });
    expect(res.status).toBe(400);
    const body = await res.json() as { success: boolean; error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_CODE');
  });

  it('rejects mapping target with an unregistered locale code', async () => {
    const token = await registerUser(`map-unreg-${Date.now()}`);
    const res = await fetch(`${BASE_URL}/api/v2/localization/projects/langmap-web/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ key: 'test-key', locale_code: 'en-x-unlisted', text: 'Hello' }),
    });
    expect(res.status).toBe(400);
    const body = await res.json() as { success: boolean; error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_CODE');
  });
});

describe('localization schema contract', () => {
  const schema = readFileSync(new URL('../schema.sql', import.meta.url), 'utf8');

  it('keeps localization rows project-scoped and does not add alias/name tables', () => {
    expect(schema).toMatch(/CREATE TABLE ui_locales[\s\S]*project_id TEXT NOT NULL/);
    expect(schema).toMatch(/PRIMARY KEY \(project_id, code\)/);
    expect(schema).toMatch(/FOREIGN KEY \(project_id, fallback_code\) REFERENCES ui_locales\(project_id, code\)/);
    expect(schema).toMatch(/CREATE TABLE ui_messages[\s\S]*project_id TEXT NOT NULL/);
    expect(schema).not.toMatch(/language_code_aliases|languoid_names/);
  });
});
