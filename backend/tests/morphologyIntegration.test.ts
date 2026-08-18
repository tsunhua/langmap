import { describe, expect, it } from 'vitest';
import type {
  CreateFormEdgeResult,
  ExpressionFormEdgesDto,
  MorphologicalDimensionDto,
} from '../src/types/morphology';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';
const API = `${BASE_URL}/api/v2/morphological-features`;
const EXPRESSIONS = `${BASE_URL}/api/v2/expressions`;

async function fetchDimensions(query = ''): Promise<{ status: number; dimensions: MorphologicalDimensionDto[] }> {
  const res = await fetch(`${API}${query}`);
  const body = (await res.json()) as { data?: { dimensions?: MorphologicalDimensionDto[] } };
  return { status: res.status, dimensions: body.data?.dimensions ?? [] };
}

function findFeature(dimensions: MorphologicalDimensionDto[], code: string) {
  for (const dimension of dimensions) {
    const feature = dimension.features.find((item) => item.code === code);
    if (feature) return { dimension, feature };
  }
  return undefined;
}

describe('GET /morphological-features', () => {
  it('returns 13 dimensions with features nested under the right parent', async () => {
    const { status, dimensions } = await fetchDimensions('?ui_locale=cmn-Hans-CN');
    expect(status).toBe(200);
    expect(dimensions).toHaveLength(13);
    const orders = dimensions.map((d) => d.sort_order);
    expect(orders).toEqual([...orders].sort((a, b) => a - b));
    const found = findFeature(dimensions, 'plural');
    expect(found?.dimension.code).toBe('number');
    expect(found?.feature.sort_order).toBe(2);
  });

  it('resolves plural names for the five seed locales and English fallback', async () => {
    const names: Record<string, string | undefined> = {};
    for (const locale of ['cmn-Hans-CN', 'cmn-Hant-TW', 'jpn-Jpan-JP', 'spa-Latn-ES']) {
      const { dimensions } = await fetchDimensions(`?ui_locale=${locale}`);
      names[locale] = findFeature(dimensions, 'plural')?.feature.name;
    }
    expect(names['cmn-Hans-CN']).toBe('复数');
    expect(names['cmn-Hant-TW']).toBe('複數');
    expect(names['jpn-Jpan-JP']).toBe('複数');
    expect(names['spa-Latn-ES']).toBe('plural');

    const none = await fetchDimensions();
    expect(findFeature(none.dimensions, 'plural')?.feature.name).toBe('plural');
    expect(findFeature(none.dimensions, 'plural')?.feature.name_en).toBe('plural');
  });

  it('ignores invalid ui_locale instead of returning 400', async () => {
    const { status, dimensions } = await fetchDimensions('?ui_locale=not-a-locale');
    expect(status).toBe(200);
    expect(findFeature(dimensions, 'plural')?.feature.name).toBe('plural');
  });
});

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      username: `morph-tester-${unique}`,
      email: `morph-${unique}@example.com`,
      password: 'pass1234',
    }),
  });
  expect(response.status).toBe(201);
  return ((await response.json()) as { data: { token: string } }).data.token;
}

async function createExpression(token: string, text: string, lang = 'spa'): Promise<string> {
  const response = await fetch(EXPRESSIONS, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({ lang_code: lang, text }),
  });
  expect([200, 201]).toContain(response.status);
  return ((await response.json()) as { data: { expression: { id: string } } }).data.expression.id;
}

async function postFormEdge(
  token: string | undefined,
  formId: string,
  body: { lemma_expression_id?: unknown; features?: unknown },
  query = '',
): Promise<{ status: number; payload: { success?: boolean; error?: string; data?: CreateFormEdgeResult } }> {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (token) headers.authorization = `Bearer ${token}`;
  const response = await fetch(`${EXPRESSIONS}/${encodeURIComponent(formId)}/form-edges${query}`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
  return { status: response.status, payload: (await response.json()) as { success?: boolean; error?: string; data?: CreateFormEdgeResult } };
}

async function getFormEdges(id: string, query = ''): Promise<{ status: number; data?: ExpressionFormEdgesDto; error?: string }> {
  const response = await fetch(`${EXPRESSIONS}/${encodeURIComponent(id)}/form-edges${query}`);
  const payload = (await response.json()) as { data?: ExpressionFormEdgesDto; error?: string };
  return { status: response.status, data: payload.data, error: payload.error };
}

describe('POST/GET /expressions/:id/form-edges', () => {
  it('creates a same-language form edge and lists both directions', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const lemmaId = await createExpression(token, `gato-${unique}`);
    const formId = await createExpression(token, `gatas-${unique}`);

    const created = await postFormEdge(token, formId, {
      lemma_expression_id: lemmaId,
      features: ['feminine', 'plural'],
    });
    expect(created.status).toBe(201);
    expect(created.payload.data?.created).toBe(true);
    expect(created.payload.data?.lemma).toMatchObject({ id: lemmaId, text: `gato-${unique}`, lang_code: 'spa' });
    expect(created.payload.data?.features.map((item) => item.code)).toEqual(['feminine', 'plural']);

    const asForm = await getFormEdges(formId);
    expect(asForm.status).toBe(200);
    expect(asForm.data?.as_form).toHaveLength(1);
    expect(asForm.data?.as_form[0]?.lemma.id).toBe(lemmaId);
    expect(asForm.data?.as_form[0]?.features.map((item) => item.code)).toEqual(['feminine', 'plural']);
    expect(asForm.data?.as_lemma).toEqual([]);
    expect(asForm.data?.as_form_truncated).toBe(false);
    expect(asForm.data?.as_form_omitted_count).toBe(0);

    const asLemma = await getFormEdges(lemmaId);
    expect(asLemma.status).toBe(200);
    expect(asLemma.data?.as_lemma).toHaveLength(1);
    expect(asLemma.data?.as_lemma[0]?.form.id).toBe(formId);
    expect(asLemma.data?.as_form).toEqual([]);
  });

  it('rejects reverse, self, and cross-language edges', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const lemmaId = await createExpression(token, `gato-rej-${unique}`);
    const formId = await createExpression(token, `gatas-rej-${unique}`);
    const engId = await createExpression(token, `cat-${unique}`, 'eng');
    await postFormEdge(token, formId, { lemma_expression_id: lemmaId, features: ['plural'] });

    const reverse = await postFormEdge(token, lemmaId, { lemma_expression_id: formId });
    expect(reverse.status).toBe(400);
    expect(reverse.payload.error).toBe('FORM_EDGE_MUTUAL');

    const self = await postFormEdge(token, formId, { lemma_expression_id: formId });
    expect(self.status).toBe(400);
    expect(self.payload.error).toBe('FORM_EDGE_SELF');

    const cross = await postFormEdge(token, formId, { lemma_expression_id: engId });
    expect(cross.status).toBe(400);
    expect(cross.payload.error).toBe('FORM_EDGE_CROSS_LANGUAGE');
  });

  it('unions features on find-or-create and rejects unknown codes', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const lemmaId = await createExpression(token, `gato-union-${unique}`);
    const formId = await createExpression(token, `gatas-union-${unique}`);

    const first = await postFormEdge(token, formId, {
      lemma_expression_id: lemmaId,
      features: ['feminine', 'plural'],
    });
    expect(first.status).toBe(201);

    const again = await postFormEdge(token, formId, {
      lemma_expression_id: lemmaId,
      features: ['plural'],
    });
    expect(again.status).toBe(200);
    expect(again.payload.data?.created).toBe(false);
    expect(again.payload.data?.edge_id).toBe(first.payload.data?.edge_id);
    expect(again.payload.data?.features.map((item) => item.code)).toEqual(['feminine', 'plural']);

    const unknown = await postFormEdge(token, formId, {
      lemma_expression_id: lemmaId,
      features: ['not-a-feature'],
    });
    expect(unknown.status).toBe(400);
    expect(unknown.payload.error).toBe('FORM_FEATURE_UNKNOWN');
    const afterUnknown = await getFormEdges(formId);
    expect(afterUnknown.data?.as_form[0]?.features.map((item) => item.code)).toEqual(['feminine', 'plural']);
  });

  it('requires auth to create a form edge', async () => {
    const res = await postFormEdge(undefined, 'spa:fake', { lemma_expression_id: 'spa:other' });
    expect(res.status).toBe(401);
  });

  it('resolves feature names with ui_locale=cmn-Hant-TW', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const lemmaId = await createExpression(token, `gato-name-${unique}`);
    const formId = await createExpression(token, `gatas-name-${unique}`);
    await postFormEdge(token, formId, { lemma_expression_id: lemmaId, features: ['feminine', 'plural'] });

    const listed = await getFormEdges(formId, '?ui_locale=cmn-Hant-TW');
    expect(listed.status).toBe(200);
    const names = new Map((listed.data?.as_form[0]?.features ?? []).map((item) => [item.code, item.name]));
    expect(names.get('plural')).toBe('複數');
    expect(names.get('feminine')).toBe('陰性');
    expect(listed.data?.as_form[0]?.lemma.language_name).toBe('西班牙語');
  });

  it('returns 404 when the expression is missing', async () => {
    const listed = await getFormEdges('spa:does-not-exist');
    expect(listed.status).toBe(404);
    expect(listed.error).toBe('EXPRESSION_NOT_FOUND');
  });
});

interface SearchHit {
  id: string;
  text: string;
  form_of: Array<{
    lemma: { id: string; text: string; lang_code: string };
    features: Array<{ code: string; name: string }>;
  }>;
}

interface MappingGraphSnapshot {
  nodes: Array<{ expression_id: string }>;
  edges: Array<{ edge_id: string }>;
}

async function searchExpressions(q: string, extra = ''): Promise<{ status: number; items: SearchHit[] }> {
  const response = await fetch(`${EXPRESSIONS}/search?q=${encodeURIComponent(q)}${extra}`);
  const payload = (await response.json()) as { data?: { items?: SearchHit[] } };
  return { status: response.status, items: payload.data?.items ?? [] };
}

async function getMappingGraph(id: string): Promise<{ status: number; data?: MappingGraphSnapshot }> {
  const response = await fetch(`${EXPRESSIONS}/${encodeURIComponent(id)}/mappings?hops=1`);
  const payload = (await response.json()) as { data?: MappingGraphSnapshot };
  return { status: response.status, data: payload.data };
}

async function postMapping(
  token: string,
  fromId: string,
  targetId: string,
): Promise<{ status: number; edgeId?: string }> {
  const response = await fetch(`${EXPRESSIONS}/${encodeURIComponent(fromId)}/mappings`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({ target_expression_id: targetId, source: 'contribution' }),
  });
  const payload = (await response.json()) as { data?: { edge?: { id: string } } };
  return { status: response.status, edgeId: payload.data?.edge?.id };
}

async function getAdminToken(): Promise<string> {
  const username = `morph-admin-${Date.now()}`;
  const res = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username, email: `${username}@example.com`, password: 'pass1234' }),
  });
  const body = (await res.json()) as { data: { token: string; user: { id: number; username: string } } };
  const fs = await import('node:fs');
  const dbFile = fs.readdirSync('.wrangler/state/v3/d1/miniflare-D1DatabaseObject').find((f) => f.endsWith('.sqlite'));
  if (!dbFile) throw new Error('D1 sqlite not found');
  const { DatabaseSync } = await import('node:sqlite');
  const db = new DatabaseSync(`.wrangler/state/v3/d1/miniflare-D1DatabaseObject/${dbFile}`);
  db.exec(`UPDATE users SET role = 'admin' WHERE id = ${body.data.user.id}`);
  db.close();
  const { SignJWT } = await import('jose');
  const secretKey = process.env.SECRET_KEY
    ?? fs.readFileSync('.dev.vars', 'utf8').match(/SECRET_KEY="([^"]+)"/)?.[1]
    ?? 'dev-secret-change-me-before-deploy';
  return await new SignJWT({ id: body.data.user.id, username: body.data.user.username, role: 'admin' })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(new TextEncoder().encode(secretKey));
}

describe('search form_of isolation', () => {
  it('attaches form_of on a literal hit and returns [] when there is no form-edge', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const lemmaText = `gato-${unique}`;
    const formText = `gatas-${unique}`;
    const bareText = `sol-${unique}`;
    const lemmaId = await createExpression(token, lemmaText);
    const formId = await createExpression(token, formText);
    await createExpression(token, bareText);
    await postFormEdge(token, formId, { lemma_expression_id: lemmaId, features: ['feminine', 'plural'] });

    const hit = await searchExpressions(formText, '&ui_locale=cmn-Hant-TW');
    expect(hit.status).toBe(200);
    const formHit = hit.items.find((item) => item.id === formId);
    expect(formHit?.text).toBe(formText);
    expect(formHit?.form_of).toHaveLength(1);
    expect(formHit?.form_of[0]?.lemma).toEqual({ id: lemmaId, text: lemmaText, lang_code: 'spa' });
    expect(formHit?.form_of[0]?.features.map((item) => item.code)).toEqual(expect.arrayContaining(['plural', 'feminine']));
    expect(formHit?.form_of[0]?.features.find((item) => item.code === 'plural')?.name).toBe('複數');

    const lemmaHit = hit.items.find((item) => item.id === lemmaId);
    expect(lemmaHit).toBeUndefined();

    const bare = await searchExpressions(bareText);
    expect(bare.status).toBe(200);
    const bareHit = bare.items.find((item) => item.text === bareText);
    expect(bareHit?.form_of).toEqual([]);
  });
});

describe('mapping graph isolation', () => {
  it('does not add form-edge neighbors to the semantic graph', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const formId = await createExpression(token, `gatas-Y-${unique}`);
    const lemmaId = await createExpression(token, `gato-Y-${unique}`);
    await postFormEdge(token, formId, { lemma_expression_id: lemmaId, features: ['feminine', 'plural'] });

    const graph = await getMappingGraph(formId);
    expect(graph.status).toBe(200);
    expect(graph.data?.nodes.map((node) => node.expression_id)).toEqual([formId]);
    expect(graph.data?.edges).toEqual([]);
    expect(graph.data?.nodes.some((node) => node.expression_id === lemmaId)).toBe(false);
  });

  it('leaves an existing semantic graph unchanged after adding a form-edge', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const formId = await createExpression(token, `gatas-sem-${unique}`);
    const neighborId = await createExpression(token, `cat-${unique}`, 'eng');
    const lemmaId = await createExpression(token, `gato-sem-${unique}`);
    const mapped = await postMapping(token, formId, neighborId);
    expect(mapped.status).toBe(201);

    const before = await getMappingGraph(formId);
    expect(before.status).toBe(200);
    const beforeNodes = (before.data?.nodes ?? []).map((node) => node.expression_id).sort();
    const beforeEdges = (before.data?.edges ?? []).map((edge) => edge.edge_id).sort();
    expect(beforeNodes).toEqual([formId, neighborId].sort());

    await postFormEdge(token, formId, { lemma_expression_id: lemmaId, features: ['plural'] });
    const after = await getMappingGraph(formId);
    expect(after.status).toBe(200);
    expect((after.data?.nodes ?? []).map((node) => node.expression_id).sort()).toEqual(beforeNodes);
    expect((after.data?.edges ?? []).map((edge) => edge.edge_id).sort()).toEqual(beforeEdges);
    expect(after.data?.nodes.some((node) => node.expression_id === lemmaId)).toBe(false);
  });
});

describe('split does not move form-edges', () => {
  it('keeps the form-edge on the original expression after a semantic split', async () => {
    const adminToken = await getAdminToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const formId = await createExpression(adminToken, `gatas-split-${unique}`);
    const lemmaId = await createExpression(adminToken, `gato-split-${unique}`);
    const neighborId = await createExpression(adminToken, `cat-split-${unique}`, 'eng');
    const mapped = await postMapping(adminToken, formId, neighborId);
    expect(mapped.status).toBe(201);
    expect(mapped.edgeId).toBeTruthy();
    await postFormEdge(adminToken, formId, { lemma_expression_id: lemmaId, features: ['feminine', 'plural'] });

    const splitRes = await fetch(`${EXPRESSIONS}/${encodeURIComponent(formId)}/split`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${adminToken}` },
      body: JSON.stringify({ edge_ids: [mapped.edgeId] }),
    });
    expect(splitRes.status).toBe(200);
    const splitBody = (await splitRes.json()) as { data?: { target_expression_id?: string } };
    const targetId = splitBody.data?.target_expression_id;
    expect(targetId).toBeTruthy();

    const original = await getFormEdges(formId);
    expect(original.status).toBe(200);
    expect(original.data?.as_form).toHaveLength(1);
    expect(original.data?.as_form[0]?.lemma.id).toBe(lemmaId);

    const target = await getFormEdges(targetId ?? '');
    expect(target.status).toBe(200);
    expect(target.data?.as_form).toEqual([]);
    expect(target.data?.as_lemma).toEqual([]);
  });
});
