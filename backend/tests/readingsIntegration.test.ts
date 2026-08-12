import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: `tester-${unique}`, email: `${unique}@example.com`, password: 'pass1234' }),
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

describe('readings API', () => {
  it('creates a reading for a seeded locale', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const id = await createExpression(token, `讀音測試${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${id}/readings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW', scheme: 'pinyin', value: 't͡sit' }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { reading: { scheme: string; value: string }; created: boolean } };
    expect(body.data.created).toBe(true);
    expect(body.data.reading.scheme).toBe('pinyin');
  });

  it('reuses an existing reading on duplicate', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const id = await createExpression(token, `重複讀音${unique}`);
    const post = () =>
      fetch(`${BASE_URL}/api/v2/expressions/${id}/readings`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW', scheme: 'ipa', value: 'tsiʔ' }),
      });
    const first = await post();
    const second = await post();
    expect(first.status).toBe(201);
    expect(second.status).toBe(200);
    const firstBody = (await first.json()) as { data: { reading: { id: string }; created: boolean } };
    const secondBody = (await second.json()) as { data: { reading: { id: string }; created: boolean } };
    expect(firstBody.data.reading.id).toBe(secondBody.data.reading.id);
    expect(secondBody.data.created).toBe(false);
  });

  it('rejects an invalid scheme', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const id = await createExpression(token, `錯誤讀音${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${id}/readings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW', scheme: 'Invalid', value: 'x' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_READING_SCHEME');
  });

  it('requires auth', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions/nan:fake/readings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW', scheme: 'ipa', value: 'x' }),
    });
    expect(res.status).toBe(401);
  });
});
