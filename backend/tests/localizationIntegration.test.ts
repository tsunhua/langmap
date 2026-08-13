import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

const PROJECT = 'langmap-web';
const API = `${BASE_URL}/api/v2/localization/projects/${PROJECT}`;
const D1_DIR = '.wrangler/state/v3/d1/miniflare-D1DatabaseObject';

interface RegisteredUser {
  token: string;
  id: number;
  username: string;
}

async function register(prefix: string): Promise<RegisteredUser> {
  const unique = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: `${prefix}-${unique}`, email: `${prefix}-${unique}@example.com`, password: 'pass1234' }),
  });
  const body = (await response.json()) as { data: { token: string; user: { id: number; username: string } } };
  return { token: body.data.token, id: body.data.user.id, username: body.data.user.username };
}

async function registerToken(): Promise<string> {
  return (await register('tester')).token;
}

async function getAdminToken(): Promise<string> {
  const user = await register('admin');
  const fs = await import('node:fs');
  const dbFile = fs.readdirSync(D1_DIR).find((f) => f.endsWith('.sqlite'));
  if (!dbFile) throw new Error('D1 sqlite not found');
  const { DatabaseSync } = await import('node:sqlite');
  const db = new DatabaseSync(`${D1_DIR}/${dbFile}`);
  db.exec(`UPDATE users SET role = 'admin' WHERE id = ${user.id}`);
  db.close();
  const { SignJWT } = await import('jose');
  const secretKey = process.env.SECRET_KEY
    ?? fs.readFileSync('.dev.vars', 'utf8').match(/SECRET_KEY="([^"]+)"/)?.[1]
    ?? 'dev-secret-change-me-before-deploy';
  return await new SignJWT({ id: user.id, username: user.username, role: 'admin' })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(new TextEncoder().encode(secretKey));
}

async function ensureLocale(token: string, code: string): Promise<number> {
  const res = await fetch(`${API}/locales`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({ language_locale_code: code }),
  });
  await res.text();
  return res.status;
}

describe('localization API', () => {
  it('lists UI locales including the seeded eng-Latn-US', async () => {
    const res = await fetch(`${API}/locales`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: Array<{ language_locale_code: string; status: string; activation_source: string }> };
    const eng = body.data.find((l) => l.language_locale_code === 'eng-Latn-US');
    expect(eng).toBeTruthy();
    expect(eng!.status).toBe('active');
    expect(eng!.activation_source).toBe('system');
  });

  it('returns English source messages when no locale preference', async () => {
    const res = await fetch(`${API}/messages`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { messages: Array<{ key: string; text: string; resolved_from: string }> } };
    expect(body.data.messages.length).toBeGreaterThan(10);
    const cancelMsg = body.data.messages.find((m) => m.key === 'common.cancel');
    expect(cancelMsg).toBeTruthy();
    expect(cancelMsg!.text).toBe('Cancel');
    expect(cancelMsg!.resolved_from).toBe('source');
  });

  it('creates a draft UI locale', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW' }),
    });
    if (res.status === 400) {
      const conflictBody = (await res.json()) as { error: string };
      expect(conflictBody.error).toBe('UI_LOCALE_EXISTS');
      return;
    }
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { status: string; language_locale_code: string } };
    expect(body.data.status).toBe('draft');
    expect(body.data.language_locale_code).toBe('cmn-Hant-TW');
  });

  it('gets workbench coverage for a locale', async () => {
    const token = await registerToken();
    const createStatus = await ensureLocale(token, 'cmn-Hans-CN');
    expect([201, 400]).toContain(createStatus);
    const res = await fetch(`${API}/workbench/cmn-Hans-CN`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { locale: { status: string }; coverage: { total: number; translated: number; coverage: number } } };
    expect(body.data.locale.status).toBe('draft');
    expect(body.data.coverage.total).toBeGreaterThan(0);
    expect(body.data.coverage.translated).toBe(0);
    expect(body.data.coverage.coverage).toBe(0);
  });

  it('returns paged workbench messages with candidate slots', async () => {
    const token = await registerToken();
    const createStatus = await ensureLocale(token, 'cmn-Hans-CN');
    expect([201, 400]).toContain(createStatus);
    const res = await fetch(`${API}/workbench/cmn-Hans-CN?limit=5`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: {
        total: number;
        limit: number;
        skip: number;
        messages: Array<{ key: string; source_text: string; placeholders: string[]; candidates: unknown[] }>;
      };
    };
    expect(body.data.limit).toBe(5);
    expect(body.data.skip).toBe(0);
    expect(body.data.total).toBeGreaterThan(5);
    expect(body.data.messages).toHaveLength(5);
    const keys = body.data.messages.map((m) => m.key);
    expect([...keys].sort()).toEqual(keys);
    expect(Array.isArray(body.data.messages[0].candidates)).toBe(true);
  });

  it('filters workbench messages by query', async () => {
    const token = await registerToken();
    await ensureLocale(token, 'cmn-Hans-CN');
    const res = await fetch(`${API}/workbench/cmn-Hans-CN?q=cancel&limit=50`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { messages: Array<{ key: string; source_text: string }> } };
    expect(body.data.messages.length).toBeGreaterThan(0);
    for (const message of body.data.messages) {
      expect(`${message.key} ${message.source_text}`.toLowerCase()).toContain('cancel');
    }
  });

  it('creates a translation mapping', async () => {
    const token = await registerToken();
    const sourceMsg = await fetch(`${API}/messages`).then((r) => r.json()) as { data: { messages: Array<{ key: string; text: string }> } };
    const cancelKey = sourceMsg.data.messages.find((m) => m.key === 'common.cancel');
    expect(cancelKey).toBeTruthy();

    const exprRes = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'cmn', text: '取消' }),
    });
    const exprBody = (await exprRes.json()) as { data: { expression: { id: string } } };

    const res = await fetch(`${API}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ message_key: 'common.cancel', target_expression_id: exprBody.data.expression.id }),
    });
    expect([200, 201]).toContain(res.status);
    const body = (await res.json()) as { success: boolean; data: { created: boolean } };
    expect(body.success).toBe(true);
    if (res.status === 201) expect(body.data.created).toBe(true);
  });

  it('rejects an unknown message key for a translation mapping', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ message_key: 'no.such.key', target_expression_id: 'cmn-0000000000000000-1' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('MESSAGE_KEY_NOT_FOUND');
  });

  it('processes an empty-safe batch mapping request', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/mappings/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ mappings: [{ message_key: 'no.such.key', target_expression_id: 'cmn-0000000000000000-1' }] }),
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { count: number; results: unknown[] } };
    expect(body.data.count).toBe(0);
    expect(body.data.results).toEqual([]);
  });

  it('rejects a batch mapping request without mappings', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/mappings/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ mappings: [] }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('VALIDATION_FAILED');
  });

  it('forbids non-admin users from activating a locale', async () => {
    const token = await registerToken();
    await ensureLocale(token, 'cmn-Hant-TW');
    const res = await fetch(`${API}/locales/cmn-Hant-TW/activate`, {
      method: 'POST',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(403);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('FORBIDDEN');
  });

  it('lets an admin manually activate a draft locale below threshold', async () => {
    const adminToken = await getAdminToken();
    const code = 'cmn-Hant-TW';
    await ensureLocale(adminToken, code);
    const res = await fetch(`${API}/locales/${code}/activate`, {
      method: 'POST',
      headers: { authorization: `Bearer ${adminToken}` },
    });
    expect([200, 400]).toContain(res.status);
    const body = (await res.json()) as { error?: string; data?: { activated: boolean } };
    if (res.status === 400) {
      expect(body.error).toBe('UI_LOCALE_ALREADY_ACTIVE');
    } else {
      expect(body.data!.activated).toBe(true);
    }

    const workbench = await fetch(`${API}/workbench/${code}`, {
      headers: { authorization: `Bearer ${adminToken}` },
    });
    const wbBody = (await workbench.json()) as { data: { locale: { status: string; activation_source: string } } };
    expect(wbBody.data.locale.status).toBe('active');
    expect(wbBody.data.locale.activation_source).toBe('manual');
  });

  it('returns 404 when activating a locale that does not exist', async () => {
    const adminToken = await getAdminToken();
    const res = await fetch(`${API}/locales/zzz-Zzzz-ZZ/activate`, {
      method: 'POST',
      headers: { authorization: `Bearer ${adminToken}` },
    });
    expect(res.status).toBe(404);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('NOT_FOUND');
  });

  it('refuses to archive the system-locked locale', async () => {
    const adminToken = await getAdminToken();
    const res = await fetch(`${API}/locales/eng-Latn-US/archive`, {
      method: 'POST',
      headers: { authorization: `Bearer ${adminToken}` },
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('UI_LOCALE_SYSTEM_LOCKED');
  });

  it('forbids non-admin users from archiving a locale', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/locales/eng-Latn-US/archive`, {
      method: 'POST',
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(403);
  });

  it('rejects an invalid locale code when creating', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'eng-Latn' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });

  it('rejects an invalid primary locale query on messages', async () => {
    const res = await fetch(`${API}/messages?primary=eng-Latn`);
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });

  it('requires auth to create locale', async () => {
    const res = await fetch(`${API}/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW' }),
    });
    expect(res.status).toBe(401);
  });
});

describe('mapping vote API', () => {
  async function createEdge(token: string): Promise<{ edgeId: string; sourceExpressionId: string }> {
    const unique = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
    const ids: string[] = [];
    for (const [lang, text] of [['eng', `vote-src-${unique}`], ['cmn', `投票-${unique}`]] as const) {
      const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ lang_code: lang, text }),
      });
      const body = (await res.json()) as { data: { expression: { id: string } } };
      ids.push(body.data.expression.id);
    }
    const mappingRes = await fetch(`${BASE_URL}/api/v2/expressions/${encodeURIComponent(ids[0])}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ target_expression_id: ids[1], source: 'community' }),
    });
    const mappingBody = (await mappingRes.json()) as { data: { edge: { id: string } } };
    return { edgeId: mappingBody.data.edge.id, sourceExpressionId: ids[0] };
  }

  it('records a vote and flips it without double counting', async () => {
    const token = await registerToken();
    const { edgeId, sourceExpressionId } = await createEdge(token);

    const up = await fetch(`${API}/votes`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ edge_id: edgeId, vote: 1 }),
    });
    expect(up.status).toBe(200);
    const upBody = (await up.json()) as { data: { score: number; user_vote: number } };
    expect(upBody.data.score).toBe(1);
    expect(upBody.data.user_vote).toBe(1);

    const mappings = await fetch(`${BASE_URL}/api/v2/expressions/${encodeURIComponent(sourceExpressionId)}/edges`);
    const mappingsBody = (await mappings.json()) as { data: { items: Array<{ edge_id: string; score: number }> } };
    expect(mappingsBody.data.items.find((item) => item.edge_id === edgeId)?.score).toBe(1);

    const down = await fetch(`${API}/votes`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ edge_id: edgeId, vote: -1 }),
    });
    expect(down.status).toBe(200);
    const downBody = (await down.json()) as { data: { score: number } };
    expect(downBody.data.score).toBe(-1);
  });

  it('rejects an out-of-range vote value', async () => {
    const token = await registerToken();
    const { edgeId } = await createEdge(token);
    const res = await fetch(`${API}/votes`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ edge_id: edgeId, vote: 5 }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('VOTE_INVALID_VALUE');
  });

  it('returns 404 when voting on an unknown edge', async () => {
    const token = await registerToken();
    const res = await fetch(`${API}/votes`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ edge_id: 'no-such-edge', vote: 1 }),
    });
    expect(res.status).toBe(404);
  });

  it('requires authentication', async () => {
    const res = await fetch(`${API}/votes`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ edge_id: 'whatever', vote: 1 }),
    });
    expect(res.status).toBe(401);
  });
});
