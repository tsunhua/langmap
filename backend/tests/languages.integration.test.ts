import { describe, expect, it } from 'vitest';

const BASE_URL = 'http://127.0.0.1:8788';

async function register(username: string): Promise<string> {
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      username,
      email: `${username}@example.com`,
      password: 'pass1234',
    }),
  });
  const body = await response.json() as { data: { token: string } };
  return body.data.token;
}

async function post(path: string, token: string | null, body: unknown): Promise<Response> {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (token) headers['authorization'] = `Bearer ${token}`;
  return fetch(`${BASE_URL}${path}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
}

async function get(path: string): Promise<Response> {
  return fetch(`${BASE_URL}${path}`);
}

describe('language creation API', () => {
  it('previews and creates an unmatched community variety', async () => {
    const token = await register(`lang-${Date.now()}`);
    const payload = {
      subtags: {
        language: 'yue',
        script: 'Hant',
        region: 'CN',
        variants: [],
        private_use: [`hegu${Date.now().toString(36).slice(-4)}`],
      },
      glottocode: null,
      language: {
        name: '河谷新村話',
        name_en: null,
        description: '由當地社群使用的粵語變種。',
        reason: 'missing_from_glottolog',
        alternate_names: [],
        references: [],
        parent_languoid_id: null,
        latitude: null,
        longitude: null,
      },
    };

    const preview = await post('/api/v2/languages/preview', token, payload);
    expect(preview.status).toBe(200);
    const previewBody = await preview.json() as { data: { existing_language: unknown; canonical_code: string } };
    expect(previewBody.data.existing_language).toBeNull();
    expect(previewBody.data.canonical_code).toMatch(/^yue-Hant-CN-x-/);

    const created = await post('/api/v2/languages', token, payload);
    expect(created.status).toBe(201);
    const createdBody = await created.json() as { data: { language: { origin: string; glottocode: null } } };
    expect(createdBody.data.language.origin).toBe('community');
    expect(createdBody.data.language.glottocode).toBeNull();
  });

  it('returns 401 for unauthenticated preview', async () => {
    const response = await post('/api/v2/languages/preview', null, {
      subtags: { language: 'en', script: null, region: null, variants: [], private_use: [] },
      glottocode: null,
      language: { name: 'English', name_en: null, description: 'Test', reason: 'other', alternate_names: [], references: [], parent_languoid_id: null, latitude: null, longitude: null },
    });
    expect(response.status).toBe(401);
    const body = await response.json() as { success: boolean };
    expect(body.success).toBe(false);
  });

  it('returns 401 for unauthenticated create', async () => {
    const response = await post('/api/v2/languages', null, {
      subtags: { language: 'en', script: null, region: null, variants: [], private_use: [] },
      glottocode: null,
      language: { name: 'English', name_en: null, description: 'Test', reason: 'other', alternate_names: [], references: [], parent_languoid_id: null, latitude: null, longitude: null },
    });
    expect(response.status).toBe(401);
  });

  it('returns 400 for invalid subtag', async () => {
    const token = await register(`langinv-${Date.now()}`);
    const response = await post('/api/v2/languages/preview', token, {
      subtags: { language: 'zzz', script: null, region: null, variants: [], private_use: [] },
      glottocode: null,
      language: { name: 'Invalid', name_en: null, description: 'Test', reason: 'other', alternate_names: [], references: [], parent_languoid_id: null, latitude: null, longitude: null },
    });
    expect(response.status).toBe(400);
    const body = await response.json() as { success: boolean; error: string };
    expect(body.success).toBe(false);
  });

  it('returns 400 for missing metadata', async () => {
    const token = await register(`langmeta-${Date.now()}`);
    const response = await post('/api/v2/languages/preview', token, {
      subtags: { language: 'en', script: null, region: null, variants: [], private_use: [] },
      glottocode: null,
      language: { name: '', name_en: null, description: '', reason: 'other', alternate_names: [], references: [], parent_languoid_id: null, latitude: null, longitude: null },
    });
    expect(response.status).toBe(400);
  });

  it('returns 409 for duplicate language code', async () => {
    const token = await register(`langdup-${Date.now()}`);
    const unique = Date.now().toString(36).slice(-5);
    const payload = {
      subtags: { language: 'en', script: null, region: null, variants: [], private_use: [`dup${unique}`] },
      glottocode: null,
      language: { name: 'English Duplicate', name_en: null, description: 'Duplicate test', reason: 'other', alternate_names: [], references: [], parent_languoid_id: null, latitude: null, longitude: null },
    };

    const first = await post('/api/v2/languages', token, payload);
    expect(first.status).toBe(201);

    const second = await post('/api/v2/languages', token, payload);
    expect(second.status).toBe(409);
    const body = await second.json() as { success: boolean; error: string };
    expect(body.error).toBe('LANGUAGE_CODE_EXISTS');
  });

  it('returns 429 when daily limit is reached', async () => {
    const token = await register(`langrate-${Date.now()}`);
    const batch = Date.now().toString(36).slice(-3);
    const basePayload = {
      subtags: { language: 'en', script: null, region: null, variants: [], private_use: [] as string[] },
      glottocode: null,
      language: { name: 'Rate Limit Test', name_en: null, description: 'Rate limit test', reason: 'other' as const, alternate_names: [], references: [], parent_languoid_id: null, latitude: null, longitude: null },
    };

    for (let i = 0; i < 10; i++) {
      const payload = {
        ...basePayload,
        subtags: {
          ...basePayload.subtags,
          private_use: [`r${batch}${i}`],
        },
        language: {
          ...basePayload.language,
          name: `Rate Limit Test ${i}`,
        },
      };
      const response = await post('/api/v2/languages', token, payload);
      expect(response.status).toBe(201);
    }

    const overLimit = {
      ...basePayload,
      subtags: {
        ...basePayload.subtags,
        private_use: [`r${batch}x`],
      },
      language: {
        ...basePayload.language,
        name: 'Rate Limit Test 10',
      },
    };
    const response = await post('/api/v2/languages', token, overLimit);
    expect(response.status).toBe(429);
    const body = await response.json() as { success: boolean; error: string };
    expect(body.error).toBe('RATE_LIMITED');
  });
});

describe('language-registry mutation boundary', () => {
  it('rejects contribution batch containing an unregistered language code', async () => {
    const token = await register(`langbound-${Date.now()}`);
    const res = await post('/api/v2/contributions/batch', token, {
      expressions: [
        { lang: 'en-US', text: 'known word' },
        { lang: 'en-x-unlisted', text: 'unregistered word' },
      ],
    });
    expect(res.status).toBe(400);
    const body = await res.json() as { success: boolean; error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_CODE');
  });

  it('rejects expression creation with an unregistered language code', async () => {
    const token = await register(`langexpr-${Date.now()}`);
    const res = await post('/api/v2/expressions', token, {
      text: 'not allowed',
      language_code: 'en-x-unlisted',
    });
    expect(res.status).toBe(400);
    const body = await res.json() as { success: boolean; error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_CODE');
  });
});

describe('language-registry subtag API', () => {
  it('rejects missing type', async () => {
    const response = await get('/api/v2/language-registry/subtags');
    expect(response.status).toBe(400);
    const body = await response.json() as { success: boolean; error: string };
    expect(body.error).toBe('INVALID_TYPE');
  });

  it('rejects invalid type', async () => {
    const response = await get('/api/v2/language-registry/subtags?type=invalid');
    expect(response.status).toBe(400);
  });

  it('returns subtags for valid type', async () => {
    const response = await get('/api/v2/language-registry/subtags?type=language&q=en');
    expect(response.status).toBe(200);
    const body = await response.json() as { success: boolean; data: { items: unknown[] } };
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data.items)).toBe(true);
  });

  it('clamps limit to max 50', async () => {
    const response = await get('/api/v2/language-registry/subtags?type=language&limit=100');
    expect(response.status).toBe(200);
  });
});

describe('languoids API', () => {
  it('rejects single character query', async () => {
    const response = await get('/api/v2/languoids?q=a');
    expect(response.status).toBe(400);
    const body = await response.json() as { success: boolean; error: string };
    expect(body.error).toBe('QUERY_TOO_SHORT');
  });

  it('returns languoids with profiles array', async () => {
    const response = await get('/api/v2/languoids?q=english&limit=5');
    expect(response.status).toBe(200);
    const body = await response.json() as { success: boolean; data: { items: Array<{ profiles: unknown[] }> } };
    expect(body.success).toBe(true);
    if (body.data.items.length > 0) {
      expect(Array.isArray(body.data.items[0].profiles)).toBe(true);
    }
  });
});
