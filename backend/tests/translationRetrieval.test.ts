import { describe, expect, it, vi } from 'vitest';
import type { Database } from '../src/db/database';
import { DEFAULT_RETRIEVAL_LIMITS, retrieveEvidence, type RetrievalRequest } from '../src/services/translation/retrieval';

type Row = Record<string, unknown>;
interface Call { sql: string; args: unknown[] }
function database(handler: (call: Call) => Row[] | Promise<Row[]>, calls: Call[] = []): Database {
  return { prepare(sql: string) { return { bind(...args: unknown[]) {
    const call = { sql, args }; calls.push(call);
    return { async all<T>() { return { results: await handler(call) as T[] }; }, async first<T>() { return (await handler(call))[0] as T ?? null; } };
  } }; } } as unknown as Database;
}
const locale = { locale_id: 30, language_id: 7, lang_code: 'jpn' };
const request = (patch: Partial<RetrievalRequest> = {}): RetrievalRequest => ({
  fullText: 'Hello', spans: [], sourceLangCode: 'eng', targetLocaleCode: 'jpn-Jpan-JP', targetLocale: locale, ...patch,
});
const candidate = (patch: Row = {}): Row => ({ root_index: 0, expression_id: 1, expression_text: 'Hello', match_type: 'exact', similarity: 1, ...patch });
const path = (patch: Row = {}): Row => ({
  root_index: 0, source_text: 'Hello', match_type: 'exact', similarity: 1, locale_rank: 0,
  target_expr_id: 2, target_text: 'こんにちは', edge1_id: 11, edge1_score: 1, edge1_markers: 1,
  edge2_id: null, edge2_score: 0, edge2_markers: 0, ...patch,
});
function route(options: { candidates?: Row[]; fallback?: Row[]; direct?: Row[]; twoHop?: Row[]; markers?: Row[]; locales?: Row[] } = {}) {
  return ({ sql }: Call): Row[] => {
    if (sql.includes('JOIN expression_edges edge1 ON')) return options.twoHop ?? [];
    if (sql.includes('JOIN expression_edges edge ON')) return options.direct ?? [path()];
    if (sql.includes('FROM expression_locale_links ell')) return options.locales ?? [{ expression_id: 2, locale_code: 'jpn-Jpan-JP' }];
    if (sql.includes('FROM expression_edge_sources es JOIN sources')) return options.markers ?? [{ edge_id: 11, source_name: 'Dictionary', marker: '1' }];
    if (sql.includes('fuzzy_allowed')) return options.fallback ?? [];
    if (sql.includes('WITH roots(')) return options.candidates ?? [candidate()];
    return [];
  };
}
describe('translation retrieval', () => {
  it('batches exact roots and skips spelling fallback when all roots match', async () => {
    const calls: Call[] = [];
    const output = await retrieveEvidence(database(route(), calls), request());
    expect(output.items[0]).toMatchObject({ source_text: 'Hello', target_text: 'こんにちは', source_markers: ['Dictionary#1'], reference_locale_codes: ['jpn-Jpan-JP'] });
    expect(calls.some(call => call.sql.includes('fuzzy_allowed'))).toBe(false);
    expect(calls.length).toBeLessThanOrEqual(5);
  });
  it('searches the whole sentence and unique keyword roots in one exact query', async () => {
    const calls: Call[] = [];
    const spans = ['World', 'World'].map(text => ({ start: 6, end: 11, text, confidence: 1, reason: 'keyword' as const }));
    await retrieveEvidence(database(route({ candidates: [candidate(), candidate({ root_index: 1 })] }), calls), request({ fullText: 'Hello world', spans }));
    expect(calls[0].args).toEqual([0, 'Hello world', 1, 'World', 'eng']);
  });
  it('ranks the requested locale above high-score foreign locale candidates', async () => {
    const output = await retrieveEvidence(database(route({ direct: [
      path({ locale_rank: 2, edge1_score: 100, target_expr_id: 3, target_text: 'Other region' }),
      path({ edge1_id: 12, edge1_score: 1, target_text: 'Requested region' }),
    ] })), request());
    expect(output.items[0].target_text).toBe('Requested region');
  });
  it('keeps a requested-locale two-hop path ahead of foreign direct paths', async () => {
    const output = await retrieveEvidence(database(route({
      direct: [path({ locale_rank: 2, target_text: 'Other region' })],
      twoHop: [path({ edge1_id: 21, edge2_id: 22, edge2_score: 1, edge2_markers: 1, pivot_lang_code: 'spa', target_text: 'Requested region' })],
    })), request());
    expect(output.items[0]).toMatchObject({ target_text: 'Requested region', path_type: 'two_hop', pivot_lang_code: 'spa' });
  });
  it('skips pivots when sufficient requested-locale direct paths fill the root quota', async () => {
    const calls: Call[] = [];
    await retrieveEvidence(database(route({ direct: [path()] }), calls), request({ limits: { ...DEFAULT_RETRIEVAL_LIMITS, maxPathsPerRoot: 1 } }));
    expect(calls.some(call => call.sql.includes('JOIN expression_edges edge1 ON'))).toBe(false);
  });
  it('rejects unproven edges and unapproved pivot paths', async () => {
    const output = await retrieveEvidence(database(route({
      direct: [path({ edge1_score: 0, edge1_markers: 0 })],
      twoHop: [path({ edge2_id: 22, edge2_score: 2, edge2_markers: 1, pivot_lang_code: 'ita' })],
    })), request());
    expect(output.retrieval_status).toBe('no_match');
  });
  it('caps fuzzy needles and excludes short needles and the full multiword sentence', async () => {
    const calls: Call[] = [];
    const words = ['At', 'Station', 'Tomorrow', 'Ticket', 'Hotel', 'Coffee'];
    await retrieveEvidence(database(route({ candidates: [], fallback: [] }), calls), request({
      fullText: 'Meet at the station tomorrow',
      spans: words.map(text => ({ start: 0, end: text.length, text, reason: 'keyword', confidence: 1 })),
    }));
    const fallback = calls.find(call => call.sql.includes('fuzzy_allowed'))!;
    const enabled = fallback.args.filter(value => value === true);
    expect(enabled).toHaveLength(3);
    expect(fallback.args[3]).toBe(false);
    expect(fallback.args[7]).toBe(false);
    expect(fallback.sql).toContain('e.text % r.root_text');
    expect(fallback.sql).toContain('>= 0.55');
  });
  it('keeps approximate references distinct from exact evidence', async () => {
    const output = await retrieveEvidence(database(route({ candidates: [], fallback: [candidate({ match_type: 'fuzzy', similarity: 0.7 })], direct: [path({ match_type: 'fuzzy', similarity: 0.7 })] })), request({ fullText: 'Helo' }));
    expect(output.items[0].match_type).toBe('fuzzy');
  });
  it('caps serialized references and records omissions', async () => {
    const output = await retrieveEvidence(database(route({ direct: [path(), path({ edge1_id: 12, target_expr_id: 3, target_text: 'A'.repeat(300) })] })), request({ limits: { ...DEFAULT_RETRIEVAL_LIMITS, maxEvidenceSerializedBytes: 300 } }));
    expect(output.items).toHaveLength(1);
    expect(output.omitted_count).toBe(1);
  });
  it('deduplicates repeated paths while retaining different provenance paths', async () => {
    const output = await retrieveEvidence(database(route({ direct: [path(), path(), path({ edge1_id: 12 })] })), request());
    expect(output.items).toHaveLength(2);
  });
  it('returns degraded promptly at the deadline and starts no new queries afterward', async () => {
    vi.useFakeTimers();
    try {
      let finish: (rows: Row[]) => void = () => {};
      const calls: Call[] = [];
      const db = database(() => new Promise<Row[]>(resolve => { finish = resolve; }), calls);
      const pending = retrieveEvidence(db, request({ limits: { ...DEFAULT_RETRIEVAL_LIMITS, timeoutMs: 10 } }));
      await vi.advanceTimersByTimeAsync(11);
      expect((await pending).retrieval_status).toBe('failed');
      finish([candidate()]);
      await Promise.resolve(); await Promise.resolve();
      expect(calls).toHaveLength(1);
    } finally { vi.useRealTimers(); }
  });
  it('caller cancellation rejects instead of generating a degraded response', async () => {
    const controller = new AbortController();
    const pending = retrieveEvidence(database(() => new Promise(() => {})), request({ signal: controller.signal }));
    controller.abort();
    await expect(pending).rejects.toMatchObject({ name: 'AbortError' });
  });
  it('a rejected database query degrades, and an unknown source performs no lookup', async () => {
    expect((await retrieveEvidence(database(async () => { throw new Error('offline'); }), request())).degraded).toBe(true);
    const calls: Call[] = [];
    expect((await retrieveEvidence(database(route(), calls), request({ sourceLangCode: '' }))).retrieval_status).toBe('no_match');
    expect(calls).toHaveLength(0);
  });
});
