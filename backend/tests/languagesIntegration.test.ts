import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';
const API = `${BASE_URL}/api/v2/languages`;

describe('languages API', () => {
  it('lists only languages that have content', async () => {
    const res = await fetch(`${API}?limit=50`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { total: number; items: Array<{ code: string; name: string; name_en: string; expression_count: number; locale_count: number }> } };
    expect(body.data.items.length).toBeGreaterThan(0);
    expect(body.data.total).toBeLessThan(1000);
    for (const item of body.data.items) expect(item.expression_count + item.locale_count).toBeGreaterThan(0);
  });

  it('filters the language list by query', async () => {
    const res = await fetch(`${API}?q=eng&limit=20`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; name_en: string }> } };
    for (const item of body.data.items) expect(`${item.code} ${item.name_en}`.toLowerCase()).toContain('eng');
  });

  it('returns language detail with locales and coordinate provenance', async () => {
    const res = await fetch(`${API}/cmn`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { code: string; locales: Array<{ code: string; coordinate_source: string | null; latitude: number | null }> } };
    expect(body.data.code).toBe('cmn');
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

  it('returns 404 when listing expressions for an unknown language', async () => {
    expect((await fetch(`${API}/zzz/expressions`)).status).toBe(404);
  });
});
