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
    expect(body.data.expression.text).toBe(text);
    expect(body.data.expression.id.startsWith('nan:')).toBe(true);
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
    expect(body.data.items.some((item) => item.text === text)).toBe(true);
  });

  it('returns 404 for a missing expression', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions/nan:missing000000000000000`);
    expect(res.status).toBe(404);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('EXPRESSION_NOT_FOUND');
  });

  it('creates an expression with an optional locale attestation', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text: `有佐證${unique}`, language_locale_code: 'nan-Hant-CN' }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { expression: { id: string } } };
    const detailRes = await fetch(`${BASE_URL}/api/v2/expressions/${body.data.expression.id}`);
    const detail = (await detailRes.json()) as { data: { attestations: Array<{ language_locale_code: string; source_id: string | null }> } };
    expect(detail.data.attestations).toHaveLength(1);
    expect(detail.data.attestations[0].language_locale_code).toBe('nan-Hant-CN');
    expect(detail.data.attestations[0].source_id).toBeNull();
  });

  it('adds a sourced locale attestation and dedups it', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const createRes = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text: `去重測驗${unique}` }),
    });
    const createBody = (await createRes.json()) as { data: { expression: { id: string } } };
    const id = createBody.data.expression.id;
    const body = {
      language_locale_code: 'nan-Hant-TW',
      source: { type: 'url', name: `Test Source ${unique}`, ref: `https://example.test/${unique}` },
    };
    const post = () =>
      fetch(`${BASE_URL}/api/v2/expressions/${id}/locale-attestations`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify(body),
      });
    const first = await post();
    const second = await post();
    expect(first.status).toBe(201);
    expect(second.status).toBe(200);
    const secondBody = (await second.json()) as { data: { attestation: { id: string }; created: boolean } };
    expect(secondBody.data.created).toBe(false);
  });

  it('rejects an attestation for an unknown locale', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const createRes = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text: `錯誤佐證${unique}` }),
    });
    const createBody = (await createRes.json()) as { data: { expression: { id: string } } };
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${createBody.data.expression.id}/locale-attestations`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'nan-Hant-ZZ' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });
});
