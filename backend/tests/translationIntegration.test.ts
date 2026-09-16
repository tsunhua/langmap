import { beforeAll, describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';
const KNOWN_TARGET_LOCALE = 'jpn-Jpan-JP';

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      username: `translator-${unique}`,
      email: `${unique}@example.com`,
      password: 'pass1234',
    }),
  });
  const body = (await response.json()) as { data: { token: string } };
  return body.data.token;
}

function translate(token: string | null, body: BodyInit | null): Promise<Response> {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (token) headers.authorization = `Bearer ${token}`;
  return fetch(`${BASE_URL}/api/v2/translate`, { method: 'POST', headers, body });
}

// Every case below fails validation or auth before the pipeline can call Workers AI.
describe('POST /api/v2/translate integration (non-AI paths)', () => {
  let token: string;

  beforeAll(async () => {
    token = await registerToken();
  });

  it('requires authentication', async () => {
    const response = await translate(null, JSON.stringify({ text: '你好', target_locale_code: KNOWN_TARGET_LOCALE }));
    expect(response.status).toBe(401);
    expect(((await response.json()) as { error: string }).error).toBe('AUTH_REQUIRED');
  });

  it('rejects an empty body', async () => {
    const response = await translate(token, '');
    expect(response.status).toBe(400);
    expect(((await response.json()) as { error: string }).error).toBe('VALIDATION_FAILED');
  });

  it('rejects malformed JSON', async () => {
    const response = await translate(token, '{not json');
    expect(response.status).toBe(400);
    expect(((await response.json()) as { error: string }).error).toBe('VALIDATION_FAILED');
  });

  it('rejects more than 500 graphemes', async () => {
    const response = await translate(token, JSON.stringify({ text: 'a'.repeat(501), target_locale_code: KNOWN_TARGET_LOCALE }));
    expect(response.status).toBe(400);
    expect(((await response.json()) as { error: string }).error).toBe('VALIDATION_FAILED');
  });

  it('returns 404 for an unknown target locale', async () => {
    const response = await translate(token, JSON.stringify({ text: '你好', target_locale_code: 'xxx-Yyy-ZZ' }));
    expect(response.status).toBe(404);
    expect(((await response.json()) as { error: string }).error).toBe('TARGET_LOCALE_NOT_FOUND');
  });

  it('rejects HTML/fenced Markdown with PLAIN_TEXT_ONLY', async () => {
    const response = await translate(token, JSON.stringify({ text: '<b>hi</b>', target_locale_code: KNOWN_TARGET_LOCALE }));
    expect(response.status).toBe(400);
    expect(((await response.json()) as { error: string }).error).toBe('PLAIN_TEXT_ONLY');
  });
});
