import fs from 'node:fs';
import { SignJWT } from 'jose';
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

async function tokenForMissingUser(): Promise<string> {
  const secretKey = process.env.SECRET_KEY
    ?? fs.readFileSync('.dev.vars', 'utf8').match(/SECRET_KEY="([^"]+)"/)?.[1]
    ?? '';
  return new SignJWT({ id: 2_147_483_647, username: 'missing-user', role: 'user' })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('5m')
    .sign(new TextEncoder().encode(secretKey));
}

describe('preferences API', () => {
  it('returns empty preferences for a new user', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/preferences`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: Record<string, unknown> };
    expect(body.data).toEqual({});
  });

  it('saves and retrieves a language.locales preference', async () => {
    const token = await registerToken();
    const putRes = await fetch(`${BASE_URL}/api/v2/preferences/language.locales`, {
      method: 'PUT',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ primary: 'cmn-Hant-TW', secondary: 'eng-Latn-US' }),
    });
    expect(putRes.status).toBe(200);
    const getRes = await fetch(`${BASE_URL}/api/v2/preferences`, {
      headers: { authorization: `Bearer ${token}` },
    });
    const getBody = (await getRes.json()) as { data: { 'language.locales': { primary: string; secondary: string } } };
    expect(getBody.data['language.locales'].primary).toBe('cmn-Hant-TW');
    expect(getBody.data['language.locales'].secondary).toBe('eng-Latn-US');
  });

  it('rejects secondary equal to primary', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/preferences/language.locales`, {
      method: 'PUT',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ primary: 'cmn-Hant-TW', secondary: 'cmn-Hant-TW' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_PREFERENCE');
  });

  it('requires auth', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/preferences`);
    expect(res.status).toBe(401);
  });

  it('rejects a valid token whose user no longer exists', async () => {
    const token = await tokenForMissingUser();
    const res = await fetch(`${BASE_URL}/api/v2/preferences/language.locales`, {
      method: 'PUT',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ primary: 'cmn-Hant-TW', secondary: 'eng-Latn-US' }),
    });
    expect(res.status).toBe(401);
  });
});
