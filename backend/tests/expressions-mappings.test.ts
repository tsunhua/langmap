import { describe, expect, it } from 'vitest';

const BASE_URL = 'http://127.0.0.1:8788';

const json = (res: Response) => res.json();

async function register(prefix: string): Promise<string> {
  const res = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      username: `graph-${prefix}`,
      email: `${prefix}@example.com`,
      password: 'pass1234',
    }),
  });
  expect(res.status).toBe(201);
  const body = await json(res);
  return body.data.token as string;
}

async function contribute(token: string, texts: string[]): Promise<number[]> {
  const res = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({
      expressions: texts.map((t) => ({ lang: 'en-US', text: t })),
    }),
  });
  expect(res.status).toBe(200);
  const body = await json(res);
  return body.data.expressionIds as number[];
}

async function mappings(id: number, hops: number) {
  const res = await fetch(`${BASE_URL}/api/v2/expressions/${id}/mappings?hops=${hops}`);
  expect(res.status).toBe(200);
  return json(res);
}

describe('GET /api/v2/expressions/:id/mappings (graph)', () => {
  it('returns a graph object and respects hops param', async () => {
    const token = await register(`hops-${Date.now()}`);
    const u = Math.random().toString(36).slice(2, 8);

    // Layer 1 clique around A
    const [a, b, c] = await contribute(token, [`${u}-A`, `${u}-B`, `${u}-C`]);
    // Layer 2 reachable via B
    const [, d, e] = await contribute(token, [`${u}-B`, `${u}-D`, `${u}-E`]);
    // Layer 3 reachable via D
    const [, f] = await contribute(token, [`${u}-D`, `${u}-F`]);

    const one = await mappings(a, 1);
    expect(one.data).toMatchObject({
      root_id: expect.any(Number),
      requested_hops: expect.any(Number),
      nodes: expect.any(Array),
      edges: expect.any(Array),
      truncated: expect.any(Boolean),
    });

    const assertGraphInvariants = (body: any, hops: number) => {
      const graph = body.data;
      expect(graph.root_id).toBe(a);
      const nodeIds = graph.nodes.map((n: any) => n.expression_id);
      expect(new Set(nodeIds).size).toBe(nodeIds.length);
      const edgeIds = graph.edges.map((e: any) => e.edge_id);
      expect(new Set(edgeIds).size).toBe(edgeIds.length);

      const root = graph.nodes.find((n: any) => n.expression_id === a);
      expect(root).toBeDefined();
      expect(root.depth).toBe(0);

      const idSet = new Set(nodeIds);
      for (const e of graph.edges) {
        expect(idSet.has(e.source_id)).toBe(true);
        expect(idSet.has(e.target_id)).toBe(true);
      }

      const maxDepth = Math.max(...graph.nodes.map((n: any) => n.depth));
      expect(maxDepth).toBeLessThanOrEqual(hops);
      return graph;
    };

    const g1 = assertGraphInvariants(one, 1);
    const oneIds = new Set(g1.nodes.map((n: any) => n.expression_id));
    expect(oneIds.has(b)).toBe(true);
    expect(oneIds.has(c)).toBe(true);
    expect(oneIds.has(d)).toBe(false);

    const two = await mappings(a, 2);
    const g2 = assertGraphInvariants(two, 2);
    const twoIds = new Set(g2.nodes.map((n: any) => n.expression_id));
    expect(twoIds.has(d)).toBe(true);
    expect(twoIds.has(e)).toBe(true);
    // A 2-hop edge must not all originate from the root.
    const depth2Edges = g2.edges.filter((e: any) => e.depth === 2);
    expect(depth2Edges.length).toBeGreaterThan(0);
    expect(depth2Edges.some((e: any) => e.source_id !== a)).toBe(true);

    const three = await mappings(a, 3);
    const g3 = assertGraphInvariants(three, 3);
    const threeIds = new Set(g3.nodes.map((n: any) => n.expression_id));
    expect(threeIds.has(f)).toBe(true);
    const fNode = g3.nodes.find((n: any) => n.expression_id === f);
    expect(fNode.depth).toBe(3);
    expect(g3.requested_hops).toBe(3);
  });

  it('defaults hops to 1 and clamps out of range', async () => {
    const token = await register(`def-${Date.now()}`);
    const u = Math.random().toString(36).slice(2, 8);
    const [a] = await contribute(token, [`${u}-X`, `${u}-Y`]);

    const bodyDefault = await json(await fetch(`${BASE_URL}/api/v2/expressions/${a}/mappings`));
    expect(bodyDefault.data.requested_hops).toBe(1);

    const bodyHigh = await json(await fetch(`${BASE_URL}/api/v2/expressions/${a}/mappings?hops=9`));
    expect(bodyHigh.data.requested_hops).toBe(3);

    const bodyLow = await json(await fetch(`${BASE_URL}/api/v2/expressions/${a}/mappings?hops=0`));
    expect(bodyLow.data.requested_hops).toBe(1);

    const bodyJunk = await json(await fetch(`${BASE_URL}/api/v2/expressions/${a}/mappings?hops=abc`));
    expect(bodyJunk.data.requested_hops).toBe(1);
  });

  it('rejects expression creation with an unregistered language code', async () => {
    const token = await register(`unreg-expr-${Date.now()}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        text: 'not allowed',
        language_profile_code: 'en-x-unlisted',
      }),
    });
    expect(res.status).toBe(400);
    const body = await json(res);
    expect(body.error).toBe('INVALID_LANGUAGE_PROFILE_CODE');
  });

  it('stores an explicit expression variation classification', async () => {
    const token = await register(`variation-${Date.now()}`);
    const text = `shared-${Math.random().toString(36).slice(2, 8)}`;
    const created = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        text,
        language_profile_code: 'en',
        variation_status: 'shared',
      }),
    });
    expect(created.status).toBe(201);
    const createdBody = await json(created);

    const detail = await fetch(`${BASE_URL}/api/v2/expressions/${createdBody.data.expressionId}`);
    expect(detail.status).toBe(200);
    const detailBody = await json(detail);
    expect(detailBody.data.variation_status).toBe('shared');

    const invalid = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        text: `${text}-invalid`,
        language_profile_code: 'en',
        variation_status: 'unknown',
      }),
    });
    expect(invalid.status).toBe(400);
    expect((await json(invalid)).error).toBe('invalid_variation_status');
  });

  it('rejects contribution batch with any unregistered language code', async () => {
    const token = await register(`unreg-contrib-${Date.now()}`);
    const res = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        expressions: [
          { lang: 'en-US', text: 'known' },
          { lang: 'en-x-unlisted', text: 'unknown' },
        ],
      }),
    });
    expect(res.status).toBe(400);
    const body = await json(res);
    expect(body.error).toBe('INVALID_LANGUAGE_PROFILE_CODE');
  });

  it('responds 404 for a missing root expression', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions/999999999/mappings?hops=1`);
    expect(res.status).toBe(404);
    const body = await json(res);
    expect(body.success).toBe(false);
  });
});
