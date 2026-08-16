import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';
const API = `${BASE_URL}/api/v2/languages`;

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      username: `language-tester-${unique}`,
      email: `language-${unique}@example.com`,
      password: 'pass1234',
    }),
  });
  expect(response.status).toBe(201);
  return ((await response.json()) as { data: { token: string } }).data.token;
}

async function createExpression(token: string, text: string, languageLocaleCode: string): Promise<string> {
  const response = await fetch(`${BASE_URL}/api/v2/expressions`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({ lang_code: 'cmn', text, language_locale_code: languageLocaleCode }),
  });
  expect(response.status).toBe(201);
  return ((await response.json()) as { data: { expression: { id: string } } }).data.expression.id;
}

describe('languages API', () => {
  it('lists only languages that have content', async () => {
    const res = await fetch(`${API}?limit=50`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { total: number; items: Array<{ code: string; name: string; name_en: string; expression_count: number; locale_count: number }> } };
    expect(body.data.items.length).toBeGreaterThan(0);
    expect(body.data.total).toBeLessThan(1000);
    for (const item of body.data.items) expect(item.expression_count + item.locale_count).toBeGreaterThan(0);
  });

  it('sorts language summaries alphabetically when requested', async () => {
    const res = await fetch(`${API}?sort=alpha&limit=50`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; name: string }> } };
    const keys = body.data.items.map((item) => `${item.name}\u0000${item.code}`);
    expect(keys).toEqual([...keys].sort());
  });

  it('filters the language list by query', async () => {
    const res = await fetch(`${API}?q=eng&limit=20`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; name_en: string }> } };
    for (const item of body.data.items) expect(`${item.code} ${item.name_en}`.toLowerCase()).toContain('eng');
  });

  it('resolves localized language names from seed via name', async () => {
    const namesFor = async (uiLocale: string) => {
      const res = await fetch(`${API}?limit=300&ui_locale=${uiLocale}`);
      expect(res.status).toBe(200);
      const body = await res.json() as { data: { items: Array<{ code: string; name: string }> } };
      return new Map(body.data.items.map((item) => [item.code, item.name]));
    };
    const hans = await namesFor('cmn-Hans-CN');
    expect(hans.get('jpn')).toBe('日语');
    expect(hans.get('spa')).toBe('西班牙语');
    expect(hans.get('nan')).toBe('闽南语');
    expect(hans.get('cmn')).toBe('普通话');
    const hant = await namesFor('cmn-Hant-TW');
    expect(hant.get('jpn')).toBe('日語');
    expect(hant.get('cmn')).toBe('華語');
    const neutral = await namesFor('eng-Latn-US');
    expect(neutral.get('jpn')).toBe('Japanese');
    const none = await fetch(`${API}?limit=300`);
    const body = await none.json() as { data: { items: Array<{ code: string; name: string }> } };
    expect(new Map(body.data.items.map((item) => [item.code, item.name])).get('cmn')).toBe('Mandarin Chinese');
  });

  it('uses secondary locale when primary is invalid', async () => {
    const res = await fetch(`${API}?limit=300&ui_locale=zzz-Zzzz-ZZ&secondary_ui_locale=cmn-Hans-CN`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; name: string }> } };
    const map = new Map(body.data.items.map((item) => [item.code, item.name]));
    expect(map.get('jpn')).toBe('日语');
  });

  it('resolves locale display_name from seed while keeping self-name', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales/jpn-Jpan-JP?ui_locale=cmn-Hans-CN`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { code: string; display_name: string; name: string } };
    expect(body.data.display_name).toBe('日语（日本）');
    expect(body.data.name).toBe('日本語');
  });

  it('returns language detail with locales and coordinate provenance', async () => {
    const res = await fetch(`${API}/cmn`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { code: string; mapped_expression_count: number; locales: Array<{ code: string; coordinate_source: string | null; latitude: number | null }> } };
    expect(body.data.code).toBe('cmn');
    expect(body.data.mapped_expression_count).toBeGreaterThanOrEqual(0);
    const codes = body.data.locales.map((locale) => locale.code);
    expect([...codes].sort()).toEqual(codes);
    for (const locale of body.data.locales) expect([null, 'locale', 'region']).toContain(locale.coordinate_source);
  });

  it('accepts an uppercase language code', async () => {
    const res = await fetch(`${API}/CMN`);
    expect(res.status).toBe(200);
    expect((await res.json() as { data: { code: string } }).data.code).toBe('cmn');
  });

  it('returns 404 for an unknown language', async () => {
    const res = await fetch(`${API}/zzz`);
    expect(res.status).toBe(404);
    expect((await res.json() as { error: string }).error).toBe('NOT_FOUND');
  });

  it('lists expressions for a language', async () => {
    const res = await fetch(`${API}/eng/expressions?limit=10`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { total: number; items: Array<{ lang_code: string; text: string }> } };
    expect(body.data.total).toBeGreaterThan(0);
    for (const item of body.data.items) expect(item.lang_code).toBe('eng');
  });

  it('honors stable expression sort modes', async () => {
    const [alphaResponse, newResponse] = await Promise.all([
      fetch(`${API}/eng/expressions?sort=alpha&limit=20`),
      fetch(`${API}/eng/expressions?sort=new&limit=20`),
    ]);
    expect(alphaResponse.status).toBe(200);
    expect(newResponse.status).toBe(200);
    const alpha = await alphaResponse.json() as { data: { items: Array<{ id: string; text: string; homograph_index: number }> } };
    const newest = await newResponse.json() as { data: { items: Array<{ id: string; created_at: string }> } };
    const alphaKeys = alpha.data.items.map((item) => `${item.text}\u0000${String(item.homograph_index).padStart(8, '0')}\u0000${item.id}`);
    const newestKeys = newest.data.items.map((item) => `${item.created_at}\u0000${item.id}`);
    expect(alphaKeys).toEqual([...alphaKeys].sort());
    expect(newestKeys).toEqual([...newestKeys].sort((a, b) => {
      const [dateA, idA] = a.split('\u0000');
      const [dateB, idB] = b.split('\u0000');
      return dateA === dateB ? idA.localeCompare(idB) : dateB.localeCompare(dateA);
    }));
  });

  it('filters expressions by the requested locale without duplicates', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const hansText = `漢字篩選${unique}`;
    const hantText = `傳承篩選${unique}`;
    await createExpression(token, hansText, 'cmn-Hans-CN');
    await createExpression(token, hantText, 'cmn-Hant-TW');

    const [hansResponse, hantResponse] = await Promise.all([
      fetch(`${API}/cmn/expressions?q=${encodeURIComponent(unique)}&locale=cmn-Hans-CN&limit=20`),
      fetch(`${API}/cmn/expressions?q=${encodeURIComponent(unique)}&locale=cmn-Hant-TW&limit=20`),
    ]);
    expect(hansResponse.status).toBe(200);
    expect(hantResponse.status).toBe(200);

    const hans = await hansResponse.json() as { data: { total: number; items: Array<{ id: string; text: string }> } };
    const hant = await hantResponse.json() as { data: { total: number; items: Array<{ id: string; text: string }> } };
    expect(hans.data.items.map((item) => item.text)).toEqual([hansText]);
    expect(hant.data.items.map((item) => item.text)).toEqual([hantText]);
    expect(hans.data.total).toBe(1);
    expect(hant.data.total).toBe(1);
    expect(new Set([...hans.data.items, ...hant.data.items].map((item) => item.id)).size).toBe(2);
  });

  it('returns 404 when listing expressions for an unknown language', async () => {
    expect((await fetch(`${API}/zzz/expressions`)).status).toBe(404);
  });
});
