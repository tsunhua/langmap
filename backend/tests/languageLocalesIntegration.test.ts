import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      username: `tester-${unique}`,
      email: `${unique}@example.com`,
      password: 'pass1234',
    }),
  });
  const body = (await response.json()) as { data: { token: string } };
  return body.data.token;
}

describe('language locales API', () => {
  it('lists seeded locales paginated', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales?limit=2`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      success: boolean;
      data: { items: Array<{ code: string }>; total: number; limit: number; skip: number; hasMore: boolean };
    };
    expect(body.success).toBe(true);
    expect(body.data.items.length).toBeLessThanOrEqual(2);
    expect(body.data.total).toBeGreaterThanOrEqual(3);
  });

  it('filters by lang_code', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales?lang_code=cmn`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { items: Array<{ code: string }> } };
    expect(body.data.items.map((item) => item.code).sort()).toEqual(['cmn-Hans-CN', 'cmn-Hant-TW']);
  });

  it('returns a seeded locale with region fallback coordinate', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales/eng-Latn-US`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: { code: string; name_en: string; coordinate_source: string | null; resolved_latitude: number | null };
    };
    expect(body.data.code).toBe('eng-Latn-US');
    expect(body.data.name_en).toBe('English (US)');
    expect(body.data.coordinate_source).toBe('region');
    expect(typeof body.data.resolved_latitude).toBe('number');
  });

  it('rejects a malformed code', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales/eng-Latn`);
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });

  it('returns 404 for a valid-but-missing locale', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales/zzz-Zzzz-ZZ`);
    expect(res.status).toBe(404);
  });

  it('requires auth to create a locale', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ lang_code: 'nan', script_code: 'Hant', region_code: 'TW', name: '閩南語', name_en: 'Southern Min' }),
    });
    expect(res.status).toBe(401);
  });

  it('creates a locale with place segments', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).replace(/[^a-z]/g, '').slice(0, 6);
    const res = await fetch(`${BASE_URL}/api/v2/language-locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({
        lang_code: 'nan',
        script_code: 'Hant',
        region_code: 'CN',
        place_segments: ['Quanzhou', `Nanan${unique}`],
        name: '閩南語',
        name_en: `Quanzhou Southern Min ${unique}`,
      }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as {
      data: { code: string; place_path: string; name: string; name_en: string };
    };
    expect(body.data.code).toBe(`nan-Hant-CN_Quanzhou_Nanan${unique}`);
    expect(body.data.place_path).toBe(`Quanzhou_Nanan${unique}`);
    expect(body.data.name).toBe('閩南語');
    expect(body.data.name_en).toBe(`Quanzhou Southern Min ${unique}`);
  });

  it('returns 409 for a duplicate locale', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/language-locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'eng', script_code: 'Latn', region_code: 'US', name: 'English (US)', name_en: 'English (US)' }),
    });
    expect(res.status).toBe(409);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('LANGUAGE_LOCALE_EXISTS');
  });

  it('rejects a lang code that is not in the registry', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/language-locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'zzz', script_code: 'Latn', region_code: 'US', name: 'Nope', name_en: 'Nope' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANG_CODE');
  });

  it('rejects a malformed place segment', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/language-locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', script_code: 'Hant', region_code: 'TW', place_segments: ['lowercase'], name: 'x', name_en: 'y' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_PLACE_SEGMENT');
  });

  it('searches locales by name', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales?q=Taiwan`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { items: Array<{ code: string }> } };
    expect(body.data.items.some((item) => item.code === 'cmn-Hant-TW')).toBe(true);
  });
});
