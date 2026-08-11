import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

function get(path: string): Promise<Response> {
  return fetch(`${BASE_URL}${path}`);
}

describe('language registry API', () => {
  it('lists languages paginated', async () => {
    const res = await get('/api/v2/language-registry/languages?limit=5');
    expect(res.status).toBe(200);
    const body = await res.json() as {
      success: boolean;
      data: { items: Array<{ code: string }>; total: number; limit: number; skip: number; hasMore: boolean };
    };
    expect(body.success).toBe(true);
    expect(body.data.items.length).toBeLessThanOrEqual(5);
    expect(body.data.total).toBeGreaterThan(1000);
    expect(body.data.limit).toBe(5);
  });

  it('ranks an exact language code match first', async () => {
    const res = await get('/api/v2/language-registry/languages?q=eng');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string }> } };
    expect(body.data.items[0]?.code).toBe('eng');
  });

  it('returns scripts with direction and ranks exact code', async () => {
    const res = await get('/api/v2/language-registry/scripts?q=Latn');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; direction: string }> } };
    expect(body.data.items[0]?.code).toBe('Latn');
    expect(body.data.items[0]?.direction).toBe('ltr');
  });

  it('marks Arab script as rtl', async () => {
    const res = await get('/api/v2/language-registry/scripts?q=Arab');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string; direction: string }> } };
    const arab = body.data.items.find((s) => s.code === 'Arab');
    expect(arab?.direction).toBe('rtl');
  });

  it('lists regions and ranks exact code', async () => {
    const res = await get('/api/v2/language-registry/regions?q=TW');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { items: Array<{ code: string }> } };
    expect(body.data.items[0]?.code).toBe('TW');
  });

  it('clamps limit to max 50', async () => {
    const res = await get('/api/v2/language-registry/languages?limit=999');
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { limit: number } };
    expect(body.data.limit).toBe(50);
  });

  it('paginates by skip', async () => {
    const a = await get('/api/v2/language-registry/languages?limit=5&skip=0');
    const b = await get('/api/v2/language-registry/languages?limit=5&skip=5');
    const ja = await a.json() as { data: { items: Array<{ code: string }> } };
    const jb = await b.json() as { data: { items: Array<{ code: string }> } };
    expect(ja.data.items[0]?.code).not.toBe(jb.data.items[0]?.code);
  });
});
