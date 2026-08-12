import { describe, expect, it } from 'vitest';

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const BASE_URL = 'http://127.0.0.1:8788';

describe('v2 auth smoke', () => {
  it('exposes a health endpoint under /api/v2', async () => {
    const response = await fetch(`${BASE_URL}/api/v2/auth/health`);
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.success).toBe(true);
  });

  it('reuses an existing expression instead of creating a duplicate when the same text/lang is submitted again', async () => {
    const unique = Math.random().toString(36).slice(2, 10);
    const registerResponse = await fetch(`${BASE_URL}/api/v2/auth/register`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        username: `tester-${unique}`,
        email: `${unique}@example.com`,
        password: 'pass1234',
      }),
    });

    expect(registerResponse.status).toBe(201);
    const registerBody = await registerResponse.json();
    const token = registerBody.data.token;

    const zhText = `測試詞句-${unique}`;
    const enText = `Test expression ${unique}`;
    const submit = () => fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        expressions: [
          { lang_code: 'cmn', text: zhText },
          { lang_code: 'eng', text: enText },
        ],
      }),
    });

    expect((await submit()).status).toBe(201);
    expect((await submit()).status).toBe(201);

    const searchResponse = await fetch(
      `${BASE_URL}/api/v2/expressions/search?q=${encodeURIComponent(zhText)}&lang_code=cmn`,
    );
    expect(searchResponse.status).toBe(200);
    const searchBody = await searchResponse.json();
    expect(searchBody.data.items).toHaveLength(1);
    expect(searchBody.data.items[0].text).toBe(zhText);
  });
});
