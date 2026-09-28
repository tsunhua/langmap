import { describe, expect, it } from 'vitest';
import { canonicalizeExpressionText } from '../src/services/expressionIdentity';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

const INTEGER_ID = /^[1-9]\d*$/;

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

async function createExpression(token: string, text: string, lang = 'nan'): Promise<string> {
  const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({ lang_code: lang, text }),
  });
  const body = (await res.json()) as { data: { expression: { id: string } } };
  return body.data.expression.id;
}

describe('expressions API', () => {
  it('creates an expression and returns created true', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const text = `食飯${unique}`;
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { expression: { id: string; text: string; lang_code: string }; created: boolean } };
    expect(body.data.created).toBe(true);
    expect(body.data.expression.lang_code).toBe('nan');
    expect(body.data.expression.text).toBe(canonicalizeExpressionText(text));
    expect(body.data.expression.id).toMatch(INTEGER_ID);
  });

  it('reuses an existing expression on duplicate submission', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const text = `重複詞句${unique}`;
    const submit = () =>
      fetch(`${BASE_URL}/api/v2/expressions`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ lang_code: 'nan', text }),
      });
    const first = await submit();
    const second = await submit();
    expect(first.status).toBe(201);
    expect(second.status).toBe(200);
    const firstBody = (await first.json()) as { data: { expression: { id: string }; created: boolean } };
    const secondBody = (await second.json()) as { data: { expression: { id: string }; created: boolean } };
    expect(firstBody.data.expression.id).toBe(secondBody.data.expression.id);
    expect(secondBody.data.created).toBe(false);
  });

  it('requires auth to create an expression', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ lang_code: 'nan', text: '食' }),
    });
    expect(res.status).toBe(401);
  });

  it('rejects an unknown lang_code', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'zzz', text: '食' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANG_CODE');
  });

  it('rejects empty text', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text: '   ' }),
    });
    expect(res.status).toBe(400);
  });

  it('searches expressions by text', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const text = `搜尋目標${unique}`;
    await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text }),
    });
    const res = await fetch(`${BASE_URL}/api/v2/expressions/search?q=${encodeURIComponent(`搜尋目標${unique}`)}`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: { items: Array<{ text: string; id: string }>; total: number; hasMore: boolean };
    };
    expect(body.data.total).toBeGreaterThanOrEqual(1);
    expect(body.data.items.some((item) => item.text === canonicalizeExpressionText(text))).toBe(true);
  });

  it('honors stable alphabetical search ordering', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions/search?q=&limit=50`);
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ id: string; text: string; homograph_index: number }> } };
    const keys = body.data.items.map((item) => `${item.text}\u0000${String(item.homograph_index).padStart(8, '0')}\u0000${item.id.padStart(16, '0')}`);
    expect(keys).toEqual([...keys].sort());
  });

  it('ranks exact, prefix and contained matches before paginating within a language', async () => {
    const token = await registerToken();
    const q = `站${crypto.randomUUID().replaceAll('-', '')}`;
    const expected = [q, `${q}乙`, `${q}甲`, `${q}甲乙`, `甲${q}`, `丙${q}甲`, `甲${q}乙`];
    for (const text of [...expected].reverse()) await createExpression(token, text);
    await createExpression(token, q, 'eng');

    const items: Array<{ id: string; text: string; lang_code: string }> = [];
    for (const offset of [0, 3, 6]) {
      const params = new URLSearchParams({ q, lang_code: 'nan', limit: '3', offset: String(offset) });
      const response = await fetch(`${BASE_URL}/api/v2/expressions/search?${params}`);
      expect(response.status).toBe(200);
      const body = await response.json() as {
        data: { items: typeof items; total: number; hasMore: boolean };
      };
      expect(body.data.total).toBe(expected.length);
      expect(body.data.hasMore).toBe(offset + 3 < expected.length);
      expect(body.data.items).toHaveLength(Math.min(3, expected.length - offset));
      items.push(...body.data.items);
    }
    expect(items.map((item) => item.text)).toEqual(expected.map(canonicalizeExpressionText));
    expect(items.every((item) => item.lang_code === 'nan')).toBe(true);
    expect(new Set(items.map((item) => item.id)).size).toBe(expected.length);
  });

  it('finds case-insensitive substrings in the middle of Latin text', async () => {
    const token = await registerToken();
    const q = `needle${crypto.randomUUID().replaceAll('-', '')}`;
    const text = `Before ${q.toUpperCase()} after`;
    const id = await createExpression(token, text, 'eng');
    const params = new URLSearchParams({ q: q.toLowerCase(), lang_code: 'eng' });
    const response = await fetch(`${BASE_URL}/api/v2/expressions/search?${params}`);
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { items: Array<{ id: string; text: string }>; total: number } };
    expect(body.data.total).toBe(1);
    expect(body.data.items).toEqual([expect.objectContaining({ id, text: canonicalizeExpressionText(text) })]);
  });

  it('finds one- and two-character Chinese substrings', async () => {
    const token = await registerToken();
    const id = await createExpression(token, `附近有車站${crypto.randomUUID().slice(0, 8)}`);
    for (const q of ['車站', '站']) {
      const params = new URLSearchParams({ q, lang_code: 'nan', limit: '50' });
      const response = await fetch(`${BASE_URL}/api/v2/expressions/search?${params}`);
      expect(response.status).toBe(200);
      const body = await response.json() as { data: { items: Array<{ id: string }> } };
      expect(body.data.items.some((item) => item.id === id)).toBe(true);
    }
  });

  it.each(['%', '_', '\\'])('treats %s as a literal character rather than a pattern', async (character) => {
    const token = await registerToken();
    const marker = crypto.randomUUID().replaceAll('-', '');
    const q = `針${character}線${marker}`;
    const id = await createExpression(token, `前${q}後`);
    await createExpression(token, `前針X線${marker}後`);
    await createExpression(token, `前針線${marker}後`);
    const params = new URLSearchParams({ q, lang_code: 'nan' });
    const response = await fetch(`${BASE_URL}/api/v2/expressions/search?${params}`);
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { items: Array<{ id: string }>; total: number } };
    expect(body.data.total).toBe(1);
    expect(body.data.items.map((item) => item.id)).toEqual([id]);
  });

  it('uses ids to break equal-text ties across languages without a language filter', async () => {
    const token = await registerToken();
    const q = `同詞${crypto.randomUUID().replaceAll('-', '')}`;
    const first = await createExpression(token, q, 'eng');
    const second = await createExpression(token, q);
    const ids: string[] = [];
    for (const offset of [0, 1]) {
      const params = new URLSearchParams({ q, limit: '1', offset: String(offset) });
      const response = await fetch(`${BASE_URL}/api/v2/expressions/search?${params}`);
      expect(response.status).toBe(200);
      const body = await response.json() as { data: { items: Array<{ id: string }>; total: number } };
      expect(body.data.total).toBe(2);
      ids.push(...body.data.items.map((item) => item.id));
    }
    expect(ids).toEqual([first, second]);
  });

  it('returns 404 for a missing expression', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions/999999999999`);
    expect(res.status).toBe(404);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('EXPRESSION_NOT_FOUND');
  });

  it('links a locale via language_locale_code at creation', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text: `有查證${unique}`, language_locale_code: 'nan-Hant-CN' }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { expression: { id: string } } };
    const detailRes = await fetch(`${BASE_URL}/api/v2/expressions/${body.data.expression.id}`);
    const detail = (await detailRes.json()) as { data: { locales: Array<{ language_locale_code: string }> } };
    expect(detail.data.locales).toHaveLength(1);
    expect(detail.data.locales[0].language_locale_code).toBe('nan-Hant-CN');
  });

  it('adds and dedups a locale link', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const id = await createExpression(token, `去重測驗${unique}`);
    const post = () =>
      fetch(`${BASE_URL}/api/v2/expressions/${id}/locales`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ language_locale_code: 'nan-Hant-TW' }),
      });
    const first = await post();
    const second = await post();
    expect(first.status).toBe(201);
    expect(second.status).toBe(200);
    const firstBody = (await first.json()) as { data: { locale: { language_locale_code: string }; created: boolean } };
    const secondBody = (await second.json()) as { data: { locale: { language_locale_code: string }; created: boolean } };
    expect(firstBody.data.created).toBe(true);
    expect(secondBody.data.created).toBe(false);
    expect(secondBody.data.locale.language_locale_code).toBe('nan-Hant-TW');

    const detailRes = await fetch(`${BASE_URL}/api/v2/expressions/${id}`);
    const detail = (await detailRes.json()) as { data: { locales: Array<{ language_locale_code: string }> } };
    expect(detail.data.locales).toHaveLength(1);
    expect(detail.data.locales[0].language_locale_code).toBe('nan-Hant-TW');
  });

  it('rejects a locale link for an unknown locale', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const id = await createExpression(token, `錯誤查證${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${id}/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'nan-Hant-ZZ' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });
});
