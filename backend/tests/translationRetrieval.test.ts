import { describe, expect, it } from 'vitest';
import type { D1Database } from '@cloudflare/workers-types';
import {
  APPROVED_PIVOT_LANGUAGES,
  MAX_DIRECT_PATHS_PER_ROOT,
  MAX_EVIDENCE_TOTAL,
  MAX_PREFIX_CANDIDATES_PER_ROOT,
} from '../src/utils/limits';
import {
  DEFAULT_RETRIEVAL_LIMITS,
  retrieveEvidence,
  type RetrievalLimits,
  type RetrievalRequest,
} from '../src/services/translation/retrieval';
import { edgePassesSql } from '../src/services/translation/exactMatch';

type Row = Record<string, unknown>;
type Handler = (sql: string, args: unknown[]) => Row[] | Promise<Row[]>;

interface StatementLog {
  sql: string;
  args: unknown[];
}

function fakeD1(handler: Handler, log: StatementLog[] = []): D1Database {
  return {
    prepare(sql: string) {
      return {
        bind(...args: unknown[]) {
          log.push({ sql, args });
          return {
            async all<T>() {
              return { results: ((await handler(sql, args)) ?? []) as T[] };
            },
            async first<T>() {
              return ((await handler(sql, args))?.[0] ?? null) as T;
            },
          };
        },
      };
    },
  } as unknown as D1Database;
}

interface RouteSetup {
  locale?: Row | null;
  exact?: Row[] | ((args: unknown[]) => Row[]);
  prefix?: Row[] | ((args: unknown[]) => Row[]);
  direct?: Row[] | ((args: unknown[]) => Row[]);
  twoHop?: Row[] | ((args: unknown[]) => Row[]);
  edgeMarkers?: Row[] | ((args: number[]) => Row[]);
}

function route(setup: RouteSetup): Handler {
  return (sql, args) => {
    if (/FROM language_locales ll/.test(sql)) return setup.locale ? [setup.locale] : [];
    if (/JOIN expression_edges edge1 ON/.test(sql)) {
      return typeof setup.twoHop === 'function' ? setup.twoHop(args) : setup.twoHop ?? [];
    }
    if (/JOIN expression_edges edge ON/.test(sql)) {
      return typeof setup.direct === 'function' ? setup.direct(args) : setup.direct ?? [];
    }
    if (/FROM expression_edge_sources es/.test(sql)) {
      return typeof setup.edgeMarkers === 'function' ? setup.edgeMarkers(args as number[]) : setup.edgeMarkers ?? [];
    }
    if (/JOIN languages sl ON sl.id = e.language_id/.test(sql)) {
      if (/e\.text = \?/.test(sql)) return typeof setup.exact === 'function' ? setup.exact(args) : setup.exact ?? [];
      const prefixRows = typeof setup.prefix === 'function' ? setup.prefix(args) : (setup.prefix ?? []);
      const limit = Number(args[args.length - 1]);
      return Number.isFinite(limit) ? prefixRows.slice(0, limit) : prefixRows;
    }
    return [];
  };
}

const TARGET_LOCALE = 'jpn-Jpan-JP';
const LOCALE_ROW = { id: 30, language_id: 7, lang_code: 'jpn' };

function expr(id: number, text: string): Row {
  return { expression_id: id, expression_text: text };
}

function directRow(overrides: Row = {}): Row {
  return {
    edge_id: 11,
    score: 1,
    marker_count: 0,
    target_expr_id: 999,
    target_text: 'こんにちは',
    ...overrides,
  };
}

function twoHopRow(overrides: Row = {}): Row {
  return {
    pivot_expr_id: 555,
    pivot_text: 'pivot',
    pivot_lang_code: 'eng',
    edge1_id: 21,
    edge1_score: 1,
    edge1_markers: 0,
    edge2_id: 22,
    edge2_score: 1,
    edge2_markers: 0,
    target_expr_id: 777,
    target_text: 'こんにちは',
    ...overrides,
  };
}

function markerRow(edgeId: number): Row {
  return { edge_id: edgeId, source_name: 'Cobuild', marker: '1' };
}

function rootTextsUpperCase(): string[] {
  return Array.from({ length: 9 }, (_, index) => `R${index}`);
}

function span(text: string): RetrievalRequest['spans'][number] {
  return { start: 0, end: text.length, text, reason: 'unknown_term', confidence: 0.9 };
}

function input(overrides: Partial<RetrievalRequest> = {}, limits?: RetrievalLimits): RetrievalRequest {
  return {
    fullText: 'Hello',
    spans: [],
    sourceLangCode: 'eng',
    targetLocaleCode: TARGET_LOCALE,
    ...overrides,
    ...(limits ? { limits } : {}),
  };
}

describe('retrieveEvidence — candidate resolution', () => {
  it('prefers exact matches and never runs the prefix fallback when exact exists', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [expr(1, 'Hello')],
      prefix: [expr(2, 'Hello friend'), expr(3, 'Hellos')],
      direct: [directRow({ edge_id: 11, target_text: 'こんにちは' })],
    }), log);
    const result = await retrieveEvidence(db, input());
    expect(result.degraded).toBe(false);
    expect(result.items).toHaveLength(1);
    expect(result.items[0]).toMatchObject({
      source_text: 'Hello',
      target_text: 'こんにちは',
      match_type: 'exact',
      path_type: 'direct',
    });
    expect(log.some((entry) => /e\.text >= \?/.test(entry.sql))).toBe(false);
    const candidate = log.find((entry) => /e\.text = \?/.test(entry.sql));
    expect(candidate?.args).toEqual(['Hello', 'eng']);
  });

  it('falls back to at most three prefix candidates per root and bounds every query', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [],
      prefix: [expr(1, 'Hello a'), expr(2, 'Hello b'), expr(3, 'Hello c'), expr(4, 'Hello d'), expr(5, 'Hello e')],
      direct: (args) => {
        const id = Number(args[1]);
        return [directRow({ edge_id: 100 + id, target_text: `T${id}` })];
      },
    }), log);
    const result = await retrieveEvidence(db, input({ fullText: 'Hello' }));
    expect(result.degraded).toBe(false);
    expect(result.items).toHaveLength(3);
    expect(result.omitted_count).toBe(0);
    const directCalls = log.filter((entry) => /JOIN expression_edges edge ON/.test(entry.sql));
    expect(directCalls).toHaveLength(MAX_PREFIX_CANDIDATES_PER_ROOT);
    const prefix = log.find((entry) => /e\.text >= \?/.test(entry.sql));
    expect(prefix?.args[3]).toBe(MAX_PREFIX_CANDIDATES_PER_ROOT);
    for (const entry of log.filter((e) => /JOIN expression_edges/.test(e.sql))) {
      expect(entry.sql).toContain('LIMIT ?');
    }
  });

  it('deduplicates roots by canonical text so a duplicate planner span is not re-queried', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [expr(1, 'Hello')],
      direct: [directRow({ target_text: 'X' })],
    }), log);
    const result = await retrieveEvidence(db, input({ spans: [span('Hello'), span('  hello  ')] }));
    expect(result.items).toHaveLength(1);
    expect(log.filter((entry) => /e\.text = \?/.test(entry.sql))).toHaveLength(1);
  });
});

describe('retrieveEvidence — path shape', () => {
  it('prioritizes direct paths before two-hop and skips two-hop when direct already fills the quota', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [expr(1, 'Hello')],
      direct: [
        directRow({ edge_id: 11, score: 1, target_text: 'A' }),
        directRow({ edge_id: 12, score: 1, target_text: 'B' }),
        directRow({ edge_id: 13, score: 1, target_text: 'C' }),
      ],
    }), log);
    const result = await retrieveEvidence(db, input());
    expect(result.items.map((item) => item.target_text)).toEqual(['A', 'B', 'C']);
    expect(log.some((entry) => /JOIN expression_edges edge1 ON/.test(entry.sql))).toBe(false);
  });

  it('opens the two-hop query only when direct paths are insufficient, with direct ranked first', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [expr(1, '你好')],
      direct: [directRow({ edge_id: 11, score: 1, target_text: 'A' })],
      twoHop: [twoHopRow({ pivot_lang_code: 'eng', edge1_score: 9, edge2_score: 8, target_text: 'Z' })],
    }), log);
    const result = await retrieveEvidence(db, input({ fullText: '你好', sourceLangCode: 'cmn' }));
    expect(log.some((entry) => /JOIN expression_edges edge1 ON/.test(entry.sql))).toBe(true);
    expect(result.items.map((item) => item.target_text)).toEqual(['A', 'Z']);
    expect(result.items[1].path_type).toBe('two_hop');
    expect(result.items[1].pivot_lang_code).toBe('eng');
  });

  it('writes the direct and two-hop queries against the shared quality predicate fragment', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({ locale: LOCALE_ROW, exact: [expr(1, 'Hello')] }), log);
    await retrieveEvidence(db, input());
    const direct = log.find((entry) => /JOIN expression_edges edge ON/.test(entry.sql));
    const twoHop = log.find((entry) => /JOIN expression_edges edge1 ON/.test(entry.sql));
    expect(direct?.sql).toContain(edgePassesSql('edge'));
    expect(twoHop?.sql).toContain(edgePassesSql('edge1'));
    expect(twoHop?.sql).toContain(edgePassesSql('edge2'));
    expect(twoHop?.sql).toContain('JOIN expression_locale_links ell ON ell.expression_id = tgt.id AND ell.locale_id = ?');
    expect(twoHop?.sql).not.toContain('ell.expression_id = piv.id');
  });
});

describe('retrieveEvidence — pivot allowlist', () => {
  it('only accepts approved pivots that differ from source and target language, asserted via SQL binds', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [expr(1, '你好')],
      direct: [],
      twoHop: [
        twoHopRow({ pivot_lang_code: 'zho', target_text: 'Z' }),
        twoHopRow({ pivot_lang_code: 'jpn', target_text: 'Z' }),
        twoHopRow({ pivot_lang_code: 'cmn', target_text: 'Z' }),
        twoHopRow({ pivot_lang_code: 'spa', target_text: 'Z' }),
      ],
    }), log);
    const result = await retrieveEvidence(db, input({ fullText: '你好', sourceLangCode: 'cmn' }));
    expect(result.items.map((item) => item.pivot_lang_code)).toEqual(['spa']);
    const twoHop = log.find((entry) => /JOIN expression_edges edge1 ON/.test(entry.sql));
    expect(twoHop?.sql).toContain('pl.code IN (');
    expect(twoHop?.sql).toContain('pl.code <> ?');
    expect(twoHop?.args).toHaveLength(2 + APPROVED_PIVOT_LANGUAGES.length + 2 + 1);
    expect(twoHop?.args.slice(2)).toEqual([...APPROVED_PIVOT_LANGUAGES, 'jpn', 'cmn', MAX_DIRECT_PATHS_PER_ROOT]);
  });
});

describe('retrieveEvidence — language constraints', () => {
  it('supports same-language locale conversion with an exact target locale link', async () => {
    const log: StatementLog[] = [];
    const locale = { id: 40, language_id: 2, lang_code: 'cmn' };
    const db = fakeD1(route({
      locale,
      exact: [expr(1, '你好')],
      direct: [directRow({ target_text: '你哋好' })],
    }), log);
    const result = await retrieveEvidence(db, input({ fullText: '你好', sourceLangCode: 'cmn', targetLocaleCode: 'cmn-Hant-TW' }));
    expect(result.degraded).toBe(false);
    expect(result.items).toHaveLength(1);
    expect(result.items[0].target_text).toBe('你哋好');
    const direct = log.find((entry) => /JOIN expression_edges edge ON/.test(entry.sql));
    expect(direct?.args[0]).toBe(40);
  });

  it('requires an exact expression_locale_links row on the target or yields nothing', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [expr(1, 'Hello')],
      direct: [],
      twoHop: [],
    }), log);
    const result = await retrieveEvidence(db, input());
    expect(result).toEqual({ items: [], omitted_count: 0, degraded: true });
    const direct = log.find((entry) => /JOIN expression_edges edge ON/.test(entry.sql));
    expect(direct?.sql).toContain('JOIN expression_locale_links ell ON ell.expression_id = tgt.id AND ell.locale_id = ?');
  });
});

describe('retrieveEvidence — quality predicate', () => {
  it('rejects an edge with zero score and no provenance markers', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [expr(1, 'Hello')],
      direct: [directRow({ score: 0, marker_count: 0 })],
    }), log);
    const result = await retrieveEvidence(db, input());
    expect(result).toEqual({ items: [], omitted_count: 0, degraded: true });
    const direct = log.find((entry) => /JOIN expression_edges edge ON/.test(entry.sql));
    expect(direct?.sql).toContain(edgePassesSql('edge'));
  });

  it('accepts an edge whose marker summary alone satisfies the quality gate', async () => {
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [expr(1, 'Hello')],
      direct: [directRow({ score: 0, marker_count: 1 })],
      edgeMarkers: [markerRow(11)],
    }));
    const result = await retrieveEvidence(db, input());
    expect(result.degraded).toBe(false);
    expect(result.items).toHaveLength(1);
    expect(result.items[0].source_markers).toEqual(['Cobuild#1']);
  });

  it('rejects a two-hop path where either edge fails the quality check', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [expr(1, 'Hello')],
      twoHop: [twoHopRow({ edge1_score: 5, edge1_markers: 1, edge2_score: 0, edge2_markers: 0 })],
    }), log);
    const result = await retrieveEvidence(db, input());
    expect(result).toEqual({ items: [], omitted_count: 0, degraded: true });
    const twoHop = log.find((entry) => /JOIN expression_edges edge1 ON/.test(entry.sql));
    expect(twoHop?.sql).toContain(edgePassesSql('edge1'));
    expect(twoHop?.sql).toContain(edgePassesSql('edge2'));
  });
});

describe('retrieveEvidence — cycles, dedupe and stable ordering', () => {
  it('deduplicates identical source/target/path rows and expands a visited root node only once', async () => {
    const log: StatementLog[] = [];
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [expr(1, 'Hello')],
      direct: [
        directRow({ edge_id: 11, score: 3, target_text: 'X' }),
        directRow({ edge_id: 12, score: 1, target_text: 'X' }),
      ],
      twoHop: [
        twoHopRow({ edge1_id: 21, edge1_score: 4, edge2_id: 22, edge2_score: 4, pivot_lang_code: 'cmn', target_text: 'Y' }),
        twoHopRow({ edge1_id: 23, edge1_score: 2, edge2_id: 24, edge2_score: 2, pivot_lang_code: 'cmn', target_text: 'Y' }),
      ],
      edgeMarkers: (edgeIds) => edgeIds.map(markerRow),
    }), log);
    const result = await retrieveEvidence(db, input({ spans: [span('Hello')] }));
    expect(result.items).toHaveLength(2);
    expect(result.items.map((item) => item.target_text)).toEqual(['X', 'Y']);
    expect(result.items[0]).toEqual({
      source_text: 'Hello',
      target_text: 'X',
      target_locale_code: TARGET_LOCALE,
      path_type: 'direct',
      match_type: 'exact',
      source_markers: ['Cobuild#1'],
    });
    expect(result.items[1].source_markers).toEqual(['Cobuild#1', 'Cobuild#1']);
    expect(log.filter((entry) => /JOIN expression_edges edge1 ON/.test(entry.sql))).toHaveLength(1);
  });

  it('orders evidence by exact, direct, score, marker count, text length and ids', async () => {
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: (args) => (String(args[0]) === 'Hello' ? [expr(1, 'Hello')] : []),
      prefix: [expr(2, 'fragment a'), expr(3, 'fragment b')],
      direct: (args) => {
        const id = Number(args[1]);
        if (id === 1) return [directRow({ edge_id: 11, score: 1, target_text: 'A' })];
        if (id === 2) return [directRow({ edge_id: 30, score: 3, target_text: 'C' })];
        return [directRow({ edge_id: 40, score: 2, target_text: 'D' })];
      },
      twoHop: [twoHopRow({ pivot_lang_code: 'cmn', edge1_score: 5, edge2_score: 5, target_text: 'B' })],
    }));
    const result = await retrieveEvidence(db, input({
      fullText: 'Hello',
      spans: [span('squee')],
    }));
    expect(result.degraded).toBe(false);
    expect(result.items.map((item) => item.target_text)).toEqual(['A', 'B', 'C', 'D', 'B']);
    expect(result.items.map((item) => item.match_type)).toEqual(['exact', 'exact', 'prefix', 'prefix', 'prefix']);
    expect(result.items.map((item) => item.path_type)).toEqual(['direct', 'two_hop', 'direct', 'direct', 'two_hop']);
  });
});

describe('retrieveEvidence — request bounds', () => {
  it('keeps at most three evidence paths per root even when a root yields many candidates', async () => {
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: [],
      prefix: [expr(1, 'aa'), expr(2, 'bb'), expr(3, 'cc')],
      direct: (args) => {
        const id = Number(args[1]);
        return [1, 2, 3].map((k) => directRow({ edge_id: id * 10 + k, target_text: `d${id}-${k}` }));
      },
    }));
    const result = await retrieveEvidence(db, input({ fullText: 'Pre' }));
    expect(result.items).toHaveLength(3);
    expect(result.items.every((item) => item.match_type === 'prefix')).toBe(true);
    expect(result.omitted_count).toBe(0);
  });

  it('caps total evidence at 24 and reports the omitted count', async () => {
    const rootTexts = rootTextsUpperCase();
    const indexById = new Map(rootTexts.map((text, index) => [text, index]));
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: (args) => {
        const index = indexById.get(String(args[0]));
        return index === undefined ? [] : [expr(10 + index, String(args[0]))];
      },
      direct: (args) => {
        const id = Number(args[1]);
        return [1, 2, 3].map((k) => directRow({ edge_id: id * 10 + k, target_expr_id: id * 10 + k, target_text: `t-${id}-${k}` }));
      },
    }));
    const spans = rootTexts.slice(1).map(span);
    const result = await retrieveEvidence(db, input({ fullText: 'R0', spans }));
    expect(result.degraded).toBe(false);
    expect(result.items).toHaveLength(MAX_EVIDENCE_TOTAL);
    expect(result.omitted_count).toBe(rootTexts.length * 3 - MAX_EVIDENCE_TOTAL);
  });

  it('trims serialized evidence to the byte cap without dropping degraded state', async () => {
    const rootTexts = rootTextsUpperCase();
    const indexById = new Map(rootTexts.map((text, index) => [text, index]));
    const longText = 'X'.repeat(2000);
    const db = fakeD1(route({
      locale: LOCALE_ROW,
      exact: (args) => {
        const index = indexById.get(String(args[0]));
        return index === undefined ? [] : [expr(10 + index, String(args[0]))];
      },
      direct: (args) => {
        const id = Number(args[1]);
        return [1, 2, 3].map((k) => directRow({ edge_id: id * 10 + k, target_text: `t-${longText}-${id}-${k}` }));
      },
    }));
    const spans = rootTexts.slice(1).map(span);
    const result = await retrieveEvidence(db, input({ fullText: 'R0', spans }));
    expect(result.degraded).toBe(false);
    expect(result.items.length).toBeGreaterThan(0);
    expect(result.items.length).toBeLessThan(MAX_EVIDENCE_TOTAL);
    expect(result.omitted_count).toBeGreaterThan(rootTexts.length * 3 - MAX_EVIDENCE_TOTAL);
  });
});

describe('retrieveEvidence — degradation and abort', () => {
  it('degrades without throwing when a single D1 query fails', async () => {
    const db = fakeD1((sql) => {
      if (/FROM language_locales ll/.test(sql)) return [LOCALE_ROW];
      if (/JOIN expression_edges edge ON/.test(sql)) throw new Error('D1 failure');
      return [];
    });
    const result = await retrieveEvidence(db, input());
    expect(result).toEqual({ items: [], omitted_count: 0, degraded: true });
  });

  it('degrades when no candidate produces evidence', async () => {
    const db = fakeD1(route({ locale: LOCALE_ROW, exact: [], prefix: [] }));
    const result = await retrieveEvidence(db, input());
    expect(result).toEqual({ items: [], omitted_count: 0, degraded: true });
  });

  it('degrades instead of throwing when the retrieval deadline passes', async () => {
    const db = fakeD1((sql) => {
      if (/FROM language_locales ll/.test(sql)) return [LOCALE_ROW];
      if (/e\.text = \?/.test(sql)) return [expr(1, 'Hello')];
      if (/JOIN expression_edges edge ON/.test(sql)) {
        return new Promise((resolve) => setTimeout(() => resolve([directRow({ target_text: 'X' })]), 40));
      }
      return [];
    });
    const limits = { ...DEFAULT_RETRIEVAL_LIMITS, timeoutMs: 5 };
    const result = await retrieveEvidence(db, input({}, limits));
    expect(result).toEqual({ items: [], omitted_count: 0, degraded: true });
  });

  it('throws AbortError without touching the database when the caller signal is already aborted', async () => {
    const controller = new AbortController();
    controller.abort();
    const log: StatementLog[] = [];
    const db = fakeD1(route({ locale: LOCALE_ROW, exact: [expr(1, 'Hello')] }), log);
    await expect(retrieveEvidence(db, input({ signal: controller.signal })))
      .rejects.toMatchObject({ name: 'AbortError' });
    expect(log).toHaveLength(0);
  });

  it('propagates a caller abort that arrives while a query is in flight', async () => {
    const db = fakeD1((sql) => {
      if (/FROM language_locales ll/.test(sql)) return [LOCALE_ROW];
      if (/e\.text = \?/.test(sql)) return [expr(1, 'Hello')];
      if (/JOIN expression_edges edge ON/.test(sql)) {
        return new Promise((resolve) => setTimeout(() => resolve([directRow({ target_text: 'X' })]), 30));
      }
      return [];
    });
    const controller = new AbortController();
    const pending = retrieveEvidence(db, input({ signal: controller.signal }));
    setTimeout(() => controller.abort(), 5);
    await expect(pending).rejects.toMatchObject({ name: 'AbortError' });
  });
});