import { describe, expect, it } from 'vitest';
import type { D1Database } from '@cloudflare/workers-types';
import { APPROVED_PIVOT_LANGUAGES } from '../src/utils/limits';
import {
  DEFAULT_EXACT_MATCH_LIMITS,
  ExactMatchInput,
  findExactTranslation,
  hasPassingEdge,
} from '../src/services/translation/exactMatch';

type Row = Record<string, unknown>;

interface FakeSetup {
  locale?: Row | null;
  direct?: Row[];
  twoHop?: Row[];
  markers?: Row[];
}

interface StatementLogEntry {
  sql: string;
  args: unknown[];
}

const TARGET_LOCALE = 'jpn-Jpan-JP';
const LOCALE_ROW = { locale_id: 30, lang_code: 'jpn' };

function fakeD1(setup: FakeSetup, log: StatementLogEntry[] = []): D1Database {
  const route = (sql: string): Row[] => {
    if (/FROM language_locales/.test(sql)) return setup.locale ? [setup.locale] : [];
    if (/JOIN expression_edges edge1 ON/.test(sql)) return setup.twoHop ?? [];
    if (/JOIN expression_edges edge ON/.test(sql)) return setup.direct ?? [];
    if (/FROM expression_edge_sources es/.test(sql)) return setup.markers ?? [];
    return [];
  };
  return {
    prepare(sql: string) {
      return {
        bind(...args: unknown[]) {
          log.push({ sql, args });
          return {
            async all<T>() {
              return { results: route(sql) as T[] };
            },
            async first<T>() {
              return (route(sql)[0] ?? null) as T;
            },
          };
        },
      };
    },
  } as unknown as D1Database;
}

function input(overrides: Partial<ExactMatchInput> = {}): ExactMatchInput {
  return {
    canonicalText: 'Hello',
    sourceLangCode: 'eng',
    targetLocaleCode: TARGET_LOCALE,
    limits: DEFAULT_EXACT_MATCH_LIMITS,
    ...overrides,
  };
}

describe('hasPassingEdge', () => {
  it('accepts a positive score or at least one provenance marker', () => {
    expect(hasPassingEdge({ score: 1, markerCount: 0 })).toBe(true);
    expect(hasPassingEdge({ score: 0, markerCount: 1 })).toBe(true);
    expect(hasPassingEdge({ score: 0, markerCount: 0 })).toBe(false);
  });
});

describe('findExactTranslation — direct match', () => {
  it('short-circuits on a qualifying direct edge without invoking AI and with bounded queries', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({
      locale: LOCALE_ROW,
      direct: [{
        edge_id: 11,
        source_expr_id: 1,
        source_text: 'Hello',
        source_lang_code: 'eng',
        target_expr_id: 2,
        target_text: 'こんにちは',
        score: 5,
        marker_count: 1,
      }],
      markers: [{ source_name: 'Cobuild', marker: '1' }],
    }, log);

    const result = await findExactTranslation(db, input());

    expect(result.status).toBe('exact_match');
    if (result.status !== 'exact_match') return;
    expect(result.source).toEqual({ code: 'eng', confidence: 1 });
    expect(result.evidence).toEqual([{
      source_text: 'Hello',
      target_text: 'こんにちは',
      target_locale_code: TARGET_LOCALE,
      path_type: 'direct',
      match_type: 'exact',
      source_markers: ['Cobuild#1'],
    }]);
    expect(result.result).toMatchObject({
      translation: 'こんにちは',
      alternatives: [],
      source_lang_code: 'eng',
      target_locale_code: TARGET_LOCALE,
      evidence_present: true,
      model_only: false,
      resolution: 'exact_lookup',
      generation_skipped: true,
    });
    expect(log.some((entry) => entry.sql.includes('JOIN expression_edges edge1 ON'))).toBe(false);
    expect(log).toHaveLength(3); // locale + direct + edge markers
  });
});

describe('findExactTranslation — two-hop match', () => {
  it('resolves through a pivot when no direct edge exists', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({
      locale: LOCALE_ROW,
      direct: [],
      twoHop: [{
        source_expr_id: 10,
        source_text: '你好',
        source_lang_code: 'cmn',
        pivot_expr_id: 11,
        pivot_text: 'hello',
        pivot_lang_code: 'eng',
        edge1_id: 21,
        edge1_score: 4,
        edge1_markers: 1,
        edge2_id: 22,
        edge2_score: 3,
        edge2_markers: 1,
        target_expr_id: 12,
        target_text: 'こんにちは',
      }],
      markers: [{ source_name: 'Cobuild', marker: '2' }],
    }, log);

    const result = await findExactTranslation(db, input({ canonicalText: '你好', sourceLangCode: 'cmn' }));

    expect(result.status).toBe('exact_match');
    if (result.status !== 'exact_match') return;
    expect(result.evidence[0]).toMatchObject({
      source_text: '你好',
      target_text: 'こんにちは',
      target_locale_code: TARGET_LOCALE,
      path_type: 'two_hop',
      pivot_lang_code: 'eng',
      match_type: 'exact',
    });
    expect(result.result.translation).toBe('こんにちは');
    const markerStatements = log.filter((entry) => /WHERE es\.edge_id = \?/.test(entry.sql));
    expect(markerStatements).toHaveLength(2);
    expect(markerStatements[0].args[0]).toBe(21);
    expect(markerStatements[1].args[0]).toBe(22);
  });
});

describe('findExactTranslation — non short-circuit cases', () => {
  it('does not short-circuit on a fragment exact match', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({ locale: LOCALE_ROW, direct: [], twoHop: [] }, log);
    const result = await findExactTranslation(db, input({ canonicalText: 'Hello world' }));
    expect(result).toEqual({ status: 'no_match' });
    expect(log.filter((e) => e.sql.includes('JOIN expression_edges edge ON')).at(-1)?.sql).toContain('e.text = ?');
  });

  it('does not short-circuit on a prefix match', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({ locale: LOCALE_ROW, direct: [], twoHop: [] }, log);
    const result = await findExactTranslation(db, input());
    expect(result).toEqual({ status: 'no_match' });
    const statements = log.filter((e) => e.sql.includes('JOIN expression_edges edge ON'));
    expect(statements.every((e) => e.sql.includes('e.text = ?') && !/LIKE|PREFIX/i.test(e.sql))).toBe(true);
  });

  it('does not admit a target without an exact locale link', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({ locale: LOCALE_ROW, direct: [], twoHop: [] }, log);
    const result = await findExactTranslation(db, input());
    expect(result).toEqual({ status: 'no_match' });
    const directStatement = log.find((e) => e.sql.includes('JOIN expression_edges edge ON'));
    expect(directStatement?.sql).toContain('JOIN expression_locale_links ell ON ell.expression_id = tgt.id AND ell.locale_id = ?');
  });

  it('discards edges that fail the quality predicate', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({
      locale: LOCALE_ROW,
      direct: [{
        edge_id: 5,
        source_expr_id: 1,
        source_text: 'Hello',
        source_lang_code: 'eng',
        target_expr_id: 2,
        target_text: 'こんにちは',
        score: 0,
        marker_count: 0,
      }],
      twoHop: [],
    }, log);
    const result = await findExactTranslation(db, input());
    expect(result).toEqual({ status: 'no_match' });
    const directStatement = log.find((e) => e.sql.includes('JOIN expression_edges edge ON'));
    expect(directStatement?.sql).toContain('edge.score > 0');
    expect(directStatement?.sql).toContain('expression_edge_sources');
  });
});

describe('findExactTranslation — source resolution', () => {
  it('reports ambiguous candidates when an unspecified source spans multiple languages', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({
      locale: LOCALE_ROW,
      direct: [
        {
          edge_id: 11, source_expr_id: 1, source_text: 'Hello', source_lang_code: 'eng',
          target_expr_id: 2, target_text: 'こんにちは', score: 5, marker_count: 1,
        },
        {
          edge_id: 12, source_expr_id: 3, source_text: 'Hello', source_lang_code: 'deu',
          target_expr_id: 4, target_text: 'Guten Tag', score: 4, marker_count: 1,
        },
      ],
    }, log);
    const result = await findExactTranslation(db, input({ sourceLangCode: null }));
    expect(result.status).toBe('ambiguous');
    if (result.status !== 'ambiguous') return;
    expect(result.candidates).toEqual([
      { code: 'deu', confidence: 0.5 },
      { code: 'eng', confidence: 0.5 },
    ]);
    expect(log.some((entry) => entry.sql.includes('JOIN expression_edges edge1 ON'))).toBe(false);
  });

  it('resolves a single inferred source language with confidence 1', async () => {
    const db = fakeD1({
      locale: LOCALE_ROW,
      direct: [
        {
          edge_id: 11, source_expr_id: 1, source_text: 'Hello', source_lang_code: 'eng',
          target_expr_id: 2, target_text: 'こんにちは', score: 5, marker_count: 1,
        },
        {
          edge_id: 13, source_expr_id: 5, source_text: 'Hello', source_lang_code: 'eng',
          target_expr_id: 6, target_text: 'Hello!', score: 3, marker_count: 1,
        },
      ],
    });
    const result = await findExactTranslation(db, input({ sourceLangCode: null }));
    expect(result.status).toBe('exact_match');
    if (result.status !== 'exact_match') return;
    expect(result.source).toEqual({ code: 'eng', confidence: 1 });
  });

  it('returns no_match when the target locale does not resolve', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({ locale: null }, log);
    const result = await findExactTranslation(db, input());
    expect(result).toEqual({ status: 'no_match' });
    expect(log).toHaveLength(1);
  });

  it('returns no_match for empty canonical text without querying', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({ locale: LOCALE_ROW, direct: [], twoHop: [] }, log);
    const result = await findExactTranslation(db, input({ canonicalText: '   ' }));
    expect(result).toEqual({ status: 'no_match' });
    expect(log).toHaveLength(0);
  });
});

describe('findExactTranslation — ranking and limits', () => {
  it('ranks by score, marker count and text length, then exposes two alternatives', async () => {
    const db = fakeD1({
      locale: LOCALE_ROW,
      direct: [
        { edge_id: 2, source_expr_id: 1, source_text: 'Hello', source_lang_code: 'eng', target_expr_id: 2, target_text: 'A', score: 3, marker_count: 9 },
        { edge_id: 3, source_expr_id: 1, source_text: 'Hello', source_lang_code: 'eng', target_expr_id: 3, target_text: 'B', score: 4, marker_count: 2 },
        { edge_id: 30, source_expr_id: 1, source_text: 'Hello', source_lang_code: 'eng', target_expr_id: 4, target_text: 'BB', score: 4, marker_count: 2 },
        { edge_id: 4, source_expr_id: 1, source_text: 'Hello', source_lang_code: 'eng', target_expr_id: 5, target_text: 'C', score: 4, marker_count: 1 },
        { edge_id: 5, source_expr_id: 1, source_text: 'Hello', source_lang_code: 'eng', target_expr_id: 6, target_text: 'C', score: 2, marker_count: 5 },
        { edge_id: 6, source_expr_id: 1, source_text: 'Hello', source_lang_code: 'eng', target_expr_id: 7, target_text: 'D', score: 3, marker_count: 1 },
        { edge_id: 1, source_expr_id: 1, source_text: 'Hello', source_lang_code: 'eng', target_expr_id: 8, target_text: 'A', score: 5, marker_count: 0 },
      ],
    });
    const result = await findExactTranslation(db, input());
    expect(result.status).toBe('exact_match');
    if (result.status !== 'exact_match') return;
    expect(result.result.translation).toBe('A');
    expect(result.result.alternatives).toEqual(['B', 'BB']);
    expect(result.evidence.map((e) => e.target_text)).toEqual(['A', 'B', 'BB']);
  });

  it('caps alternatives at two distinct target texts', async () => {
    const db = fakeD1({
      locale: LOCALE_ROW,
      direct: ['W', 'X', 'Y', 'Z'].map((text, index) => ({
        edge_id: index + 1,
        source_expr_id: 1,
        source_text: 'Hello',
        source_lang_code: 'eng',
        target_expr_id: index + 10,
        target_text: text,
        score: 1,
        marker_count: 0,
      })),
    });
    const result = await findExactTranslation(db, input());
    expect(result.status).toBe('exact_match');
    if (result.status !== 'exact_match') return;
    expect(result.result.translation).toBe('W');
    expect(result.result.alternatives).toEqual(['X', 'Y']);
  });

  it('bounds every candidate query with LIMIT', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({ locale: LOCALE_ROW, direct: [], twoHop: [] }, log);
    await findExactTranslation(db, input());
    for (const entry of log.filter((e) => e.sql.includes('JOIN expression_edges'))) {
      expect(entry.sql).toContain('LIMIT ?');
    }
  });
});

describe('findExactTranslation — pivot allowlist', () => {
  it('ignores two-hop pivots outside the approved allowlist', async () => {
    const log: StatementLogEntry[] = [];
    const db = fakeD1({
      locale: LOCALE_ROW,
      direct: [],
      twoHop: [{
        source_expr_id: 10,
        source_text: '你好',
        source_lang_code: 'cmn',
        pivot_expr_id: 11,
        pivot_text: 'hello',
        pivot_lang_code: 'zho',
        edge1_id: 21,
        edge1_score: 4,
        edge1_markers: 1,
        edge2_id: 22,
        edge2_score: 3,
        edge2_markers: 1,
        target_expr_id: 12,
        target_text: 'こんにちは',
      }],
    }, log);
    const result = await findExactTranslation(db, input({ canonicalText: '你好', sourceLangCode: 'cmn' }));
    expect(result).toEqual({ status: 'no_match' });
    const twoHop = log.find((e) => e.sql.includes('JOIN expression_edges edge1 ON'));
    expect(twoHop?.sql).toContain('pl.code IN (');
    expect(twoHop?.sql).toContain('pl.code <> ?');
    expect(twoHop?.args).toEqual([
      30, '你好', 'cmn',
      ...APPROVED_PIVOT_LANGUAGES,
      'jpn', 'cmn',
      9,
    ]);
  });
});