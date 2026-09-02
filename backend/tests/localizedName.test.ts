import { describe, expect, it } from 'vitest';
import { CANDIDATE_SQL, parseLocaleHints, resolveLanguageNames, resolveLocaleNames, resolveNamesByExpressionIds } from '../src/services/localizedName';

type Handler = (params: unknown[]) => unknown;

function fakeD1(matchers: Array<{ sql: string; match?: (params: unknown[]) => boolean; handler: Handler }>) {
  return {
    prepare(sql: string) {
      const entries = matchers.filter((m) => sql.includes(m.sql));
      return {
        bind(...params: unknown[]) {
          const entry = entries.find((m) => !m.match || m.match(params));
          return {
            async first<T>() { return (entry ? await entry.handler(params) : null) as T; },
            async all<T>() { const result = (entry ? await entry.handler(params) : { results: [] }) as { results?: unknown }; return { results: (result.results ?? []) as T[] }; },
          };
        },
      };
    },
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

const JPN_NAME = 101;
const CMN_NAME = 102;
const SPANISH_NAME = 303;
const PLURAL_EN = 301;
const RIKYU = 201;
const KYUGO = 202;

describe('parseLocaleHints', () => {
  it('trims and drops invalid or duplicate locales', () => {
    expect(parseLocaleHints(' cmn-Hans-CN ', 'bad-code')).toEqual({ primary: 'cmn-Hans-CN' });
    expect(parseLocaleHints('cmn-Hans-CN', 'cmn-Hans-CN')).toEqual({ primary: 'cmn-Hans-CN' });
    expect(parseLocaleHints(undefined, '')).toEqual({});
  });
});

describe('resolveLanguageNames / resolveLocaleNames', () => {
  it('returns empty maps for empty inputs', async () => {
    const db = fakeD1([]);
    expect((await resolveLanguageNames(db, [], {})).size).toBe(0);
    expect((await resolveLocaleNames(db, [], {})).size).toBe(0);
  });

  it('resolves language names through name_expression_ids and falls back to name_en', async () => {
    const db = fakeD1([
      { sql: 'FROM languages WHERE code IN', handler: () => ({ results: [
        { code: 'jpn', name_expression_id: JPN_NAME, name_en: 'Japanese', name: null },
        { code: 'eng', name_expression_id: null, name_en: 'English', name: null },
      ] }) },
      { sql: 'SELECT id, text FROM expressions WHERE id IN', handler: () => ({ results: [{ id: JPN_NAME, text: 'Japanese' }] }) },
      { sql: 'WITH candidate_rows AS', handler: () => ({ results: [{ source_id: JPN_NAME, target_id: RIKYU, target_text: '日语', score: 0 }] }) },
    ]);
    const langs = await resolveLanguageNames(db, ['jpn', 'eng'], parseLocaleHints('cmn-Hans-CN'));
    expect(langs.get('jpn')).toBe('日语');
    expect(langs.get('eng')).toBe('英语');
  });

  it('omits codes with no registry row so callers fall back to the code', async () => {
    const db = fakeD1([
      { sql: 'FROM languages WHERE code IN', handler: () => ({ results: [] }) },
    ]);
    const langs = await resolveLanguageNames(db, ['zzz'], parseLocaleHints('cmn-Hans-CN'));
    expect(langs.has('zzz')).toBe(false);
  });

  it('resolves locale names through the self name or a localized candidate', async () => {
    const db = fakeD1([
      { sql: 'FROM language_locales WHERE code IN', handler: () => ({ results: [
        { code: 'jpn-Jpan-JP', name_expression_id: null, name_en: 'Japanese (Japan)', name: '日本語' },
        { code: 'cmn-Hans-CN', name_expression_id: CMN_NAME, name_en: 'Simplified Chinese', name: '普通话' },
      ] }) },
      { sql: 'SELECT id, text FROM expressions WHERE id IN', handler: () => ({ results: [{ id: CMN_NAME, text: 'Simplified Chinese' }] }) },
      { sql: 'WITH candidate_rows AS', handler: () => ({ results: [{ source_id: CMN_NAME, target_id: KYUGO, target_text: '簡化字', score: 0 }] }) },
    ]);
    const locales = await resolveLocaleNames(db, ['jpn-Jpan-JP', 'cmn-Hans-CN'], parseLocaleHints('cmn-Hant-TW'));
    expect(locales.get('jpn-Jpan-JP')).toBe('日語（日本）');
    expect(locales.get('cmn-Hans-CN')).toBe('簡化字');
  });

  it('batches distinct name_expression_ids into a single candidate query', async () => {
    const db = fakeD1([
      { sql: 'FROM languages WHERE code IN', handler: () => ({ results: [
        { code: 'jpn', name_expression_id: JPN_NAME, name_en: 'Japanese', name: null },
        { code: 'cmn', name_expression_id: CMN_NAME, name_en: 'Mandarin Chinese', name: null },
      ] }) },
      { sql: 'SELECT id, text FROM expressions WHERE id IN', handler: () => ({ results: [
        { id: JPN_NAME, text: 'Japanese (custom)' },
        { id: CMN_NAME, text: 'Mandarin Chinese (custom)' },
      ] }) },
      { sql: 'WITH candidate_rows AS', handler: (params: unknown[]) => {
        expect(JSON.parse(String(params[0]))).toEqual([JPN_NAME, CMN_NAME]);
        return { results: [
          { source_id: JPN_NAME, target_id: RIKYU, target_text: '日语', score: 0 },
          { source_id: CMN_NAME, target_id: KYUGO, target_text: '普通话', score: 0 },
        ] };
      } },
    ]);
    const langs = await resolveLanguageNames(db, ['jpn', 'cmn'], parseLocaleHints('cmn-Hans-CN'));
    expect(langs.get('jpn')).toBe('日语');
    expect(langs.get('cmn')).toBe('普通话');
  });
});

describe('resolveNamesByExpressionIds', () => {
  it('prefers the project name translation before querying mapping candidates', async () => {
    const db = fakeD1([
      { sql: 'SELECT id, text FROM expressions WHERE id IN', handler: () => ({ results: [{ id: SPANISH_NAME, text: 'Spanish' }] }) },
      { sql: 'WITH candidate_rows AS', handler: () => { throw new Error('mapping candidates should not override project translations'); } },
    ]);
    const map = await resolveNamesByExpressionIds(db, [SPANISH_NAME], parseLocaleHints('cmn-Hant-TW'));
    expect(map.get(SPANISH_NAME)).toEqual({ name: '西班牙語', name_en: 'Spanish' });
  });

  it('resolves a known name_expression_id via the primary locale', async () => {
    const db = fakeD1([
      { sql: 'SELECT id, text FROM expressions WHERE id IN', handler: () => ({ results: [{ id: PLURAL_EN, text: 'plural' }] }) },
      { sql: 'WITH candidate_rows AS', handler: () => ({ results: [{ source_id: PLURAL_EN, target_id: RIKYU, target_text: '复数', score: 0 }] }) },
    ]);
    const map = await resolveNamesByExpressionIds(db, [PLURAL_EN], parseLocaleHints('cmn-Hans-CN'));
    expect(map.get(PLURAL_EN)).toEqual({ name: '复数', name_en: 'plural' });
  });

  it('falls back to the English expression text when no translation exists', async () => {
    const db = fakeD1([
      { sql: 'SELECT id, text FROM expressions WHERE id IN', handler: () => ({ results: [{ id: PLURAL_EN, text: 'plural' }] }) },
      { sql: 'WITH candidate_rows AS', handler: () => ({ results: [] }) },
    ]);
    const map = await resolveNamesByExpressionIds(db, [PLURAL_EN], parseLocaleHints('cmn-Hans-CN'));
    expect(map.get(PLURAL_EN)).toEqual({ name: 'plural', name_en: 'plural' });
  });

  it('falls back to the secondary locale when the primary has no candidate', async () => {
    const db = fakeD1([
      { sql: 'SELECT id, text FROM expressions WHERE id IN', handler: () => ({ results: [{ id: JPN_NAME, text: 'Japanese (custom)' }] }) },
      { sql: 'WITH candidate_rows AS', handler: (params: unknown[]) => (params[1] === 'cmn-Hans-CN'
        ? { results: [] }
        : { results: [{ source_id: JPN_NAME, target_id: KYUGO, target_text: '日語', score: 0 }] }) },
    ]);
    const map = await resolveNamesByExpressionIds(db, [JPN_NAME], parseLocaleHints('cmn-Hans-CN', 'cmn-Hant-TW'));
    expect(map.get(JPN_NAME)?.name).toBe('日語');
  });

  it('ignores non-positive and non-integer ids without querying', async () => {
    const db = fakeD1([]);
    const map = await resolveNamesByExpressionIds(db, [0, -1, 1.5, 'bad'], parseLocaleHints('cmn-Hans-CN'));
    expect(map.size).toBe(0);
  });

  it('skips missing expressions so the caller can fall back to the code', async () => {
    const db = fakeD1([
      { sql: 'SELECT id, text FROM expressions WHERE id IN', handler: () => ({ results: [] }) },
    ]);
    const map = await resolveNamesByExpressionIds(db, [9999], parseLocaleHints('cmn-Hans-CN'));
    expect(map.has(9999)).toBe(false);
  });
});

describe('CANDIDATE_SQL contract', () => {
  it('enforces candidate eligibility and locale-link attestation in SQL', () => {
    expect(CANDIDATE_SQL).toContain('e.score >= 0');
    expect(CANDIDATE_SQL).toContain('t.language_id = (SELECT language_id FROM language_locales WHERE code = ?)');
    expect(CANDIDATE_SQL).toContain('FROM expression_locale_links x');
    expect(CANDIDATE_SQL).toContain('UNION ALL');
  });

  it('picks the stable winner (higher score, then lower target id) from ties', async () => {
    const db = fakeD1([
      { sql: 'SELECT id, text FROM expressions WHERE id IN', handler: () => ({ results: [{ id: CMN_NAME, text: 'Mandarin Chinese (custom)' }] }) },
      { sql: 'WITH candidate_rows AS', handler: () => ({ results: [
        { source_id: CMN_NAME, target_id: 220, target_text: '普通话B', score: 0 },
        { source_id: CMN_NAME, target_id: 210, target_text: '普通话A', score: 0 },
      ] }) },
    ]);
    const map = await resolveNamesByExpressionIds(db, [CMN_NAME], parseLocaleHints('cmn-Hans-CN'));
    expect(map.get(CMN_NAME)?.name).toBe('普通话A');
  });

  it('prefers a higher-scoring candidate regardless of target id', async () => {
    const db = fakeD1([
      { sql: 'SELECT id, text FROM expressions WHERE id IN', handler: () => ({ results: [{ id: CMN_NAME, text: 'Mandarin Chinese (custom)' }] }) },
      { sql: 'WITH candidate_rows AS', handler: () => ({ results: [
        { source_id: CMN_NAME, target_id: 210, target_text: '低分', score: 0 },
        { source_id: CMN_NAME, target_id: 200, target_text: '高分', score: 1 },
      ] }) },
    ]);
    const map = await resolveNamesByExpressionIds(db, [CMN_NAME], parseLocaleHints('cmn-Hans-CN'));
    expect(map.get(CMN_NAME)?.name).toBe('高分');
  });
});
