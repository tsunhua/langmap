import { describe, expect, it } from 'vitest';
import { CANDIDATE_SQL, parseLocaleHints, resolveLanguageNames, resolveLocaleNames, resolveLocalizedNames, resolveNamesByExpressionIds } from '../src/services/localizedName';

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

const CANONICAL_JPN = 'eng:xzhosbwt57wpynfjjjwng6ddhi';
const RIKYU = 'cmn:hkke3wzynd2lehwvcuqfvvvh4a';
const KYUGO = 'cmn:yigtj7ofv3bw4svpyfze3x4adq';
const ZHONGWEN = 'cmn:6q2zdme4dnc4v7u2tg6jzfu4rq';
const PLURAL_EN = 'eng:plural-name';

describe('parseLocaleHints', () => {
  it('trims and drops invalid or duplicate locales', () => {
    expect(parseLocaleHints(' cmn-Hans-CN ', 'bad-code')).toEqual({ primary: 'cmn-Hans-CN' });
    expect(parseLocaleHints('cmn-Hans-CN', 'cmn-Hans-CN')).toEqual({ primary: 'cmn-Hans-CN' });
    expect(parseLocaleHints(undefined, '')).toEqual({});
  });
});

describe('resolveLocalizedNames', () => {
  it('resolves the primary locale candidate', async () => {
    const db = fakeD1([
      { sql: 'FROM languages WHERE code IN', handler: () => ({ results: [{ code: 'jpn', name_expression_id: CANONICAL_JPN, name_en: 'Japanese', name: null }] }) },
      { sql: 'FROM expressions WHERE id IN', handler: () => ({ results: [{ id: CANONICAL_JPN, text: 'Japanese' }] }) },
      { sql: 'lang_code FROM language_locales WHERE code = ?', handler: () => ({ lang_code: 'cmn' }) },
      { sql: 'src.id AS source_id', handler: () => ({ results: [{ source_id: CANONICAL_JPN, target_id: RIKYU, target_text: '日语', score: 0, created_at: '2026-08-01' }] }) },
    ]);
    const map = await resolveLocalizedNames(db, [{ kind: 'language', langCode: 'jpn', identityCode: 'jpn' }], parseLocaleHints('cmn-Hans-CN', 'cmn-Hant-TW'));
    expect(map.get('jpn')).toEqual({ lang_code: 'jpn', name: '日语', name_en: 'Japanese', resolved_from: 'primary' });
  });

  it('falls back to the secondary locale when the primary has no candidate', async () => {
    const db = fakeD1([
      { sql: 'FROM languages WHERE code IN', handler: () => ({ results: [{ code: 'jpn', name_expression_id: CANONICAL_JPN, name_en: 'Japanese', name: null }] }) },
      { sql: 'FROM expressions WHERE id IN', handler: () => ({ results: [{ id: CANONICAL_JPN, text: 'Japanese' }] }) },
      { sql: 'lang_code FROM language_locales WHERE code = ?', handler: () => ({ lang_code: 'cmn' }) },
      { sql: 'src.id AS source_id', handler: (params: unknown[]) => (params[2] === 'cmn-Hans-CN' ? { results: [] } : { results: [{ source_id: CANONICAL_JPN, target_id: KYUGO, target_text: '日語', score: 0, created_at: '2026-08-01' }] }) },
    ]);
    const map = await resolveLocalizedNames(db, [{ kind: 'language', langCode: 'jpn', identityCode: 'jpn' }], parseLocaleHints('cmn-Hans-CN', 'cmn-Hant-TW'));
    expect(map.get('jpn')?.name).toBe('日語');
    expect(map.get('jpn')?.resolved_from).toBe('secondary');
  });

  it('enforces candidate eligibility and stable selection in SQL', async () => {
    expect(CANDIDATE_SQL).toContain('e.score >= 0');
    expect(CANDIDATE_SQL).toContain('t.lang_code = ?');
    expect(CANDIDATE_SQL).toContain('EXISTS (SELECT 1 FROM expression_locale_attestations a WHERE a.expression_id = t.id AND a.language_locale_code = ?)');
    expect(CANDIDATE_SQL).toContain('ORDER BY src.id ASC, e.score DESC, e.created_at ASC, t.id ASC');
  });

  it('picks the stable winner (score DESC, created_at ASC, target id ASC) from a tie', async () => {
    const db = fakeD1([
      { sql: 'FROM languages WHERE code IN', handler: () => ({ results: [{ code: 'cmn', name_expression_id: ZHONGWEN, name_en: 'Mandarin Chinese', name: null }] }) },
      { sql: 'FROM expressions WHERE id IN', handler: () => ({ results: [{ id: ZHONGWEN, text: 'Mandarin Chinese' }] }) },
      { sql: 'lang_code FROM language_locales WHERE code = ?', handler: () => ({ lang_code: 'cmn' }) },
      { sql: 'src.id AS source_id', handler: () => ({ results: [
        { source_id: ZHONGWEN, target_id: 'cmn:x', target_text: '普通话A', score: 1, created_at: '2026-08-01' },
        { source_id: ZHONGWEN, target_id: 'cmn:y', target_text: '普通话B', score: 1, created_at: '2026-08-02' },
      ] }) },
    ]);
    const map = await resolveLocalizedNames(db, [{ kind: 'language', langCode: 'cmn', identityCode: 'cmn' }], parseLocaleHints('cmn-Hans-CN', undefined));
    expect(map.get('cmn')?.name).toBe('普通话A');
  });

  it('batches distinct identity codes into a single candidate query', async () => {
    const db = fakeD1([
      { sql: 'FROM languages WHERE code IN', handler: () => ({ results: [
        { code: 'jpn', name_expression_id: CANONICAL_JPN, name_en: 'Japanese', name: null },
        { code: 'cmn', name_expression_id: ZHONGWEN, name_en: 'Mandarin Chinese', name: null },
      ] }) },
      { sql: 'FROM expressions WHERE id IN', handler: () => ({ results: [
        { id: CANONICAL_JPN, text: 'Japanese' },
        { id: ZHONGWEN, text: 'Mandarin Chinese' },
      ] }) },
      { sql: 'lang_code FROM language_locales WHERE code = ?', handler: () => ({ lang_code: 'cmn' }) },
      { sql: 'src.id AS source_id', handler: () => ({ results: [
        { source_id: CANONICAL_JPN, target_id: RIKYU, target_text: '日语', score: 0, created_at: '2026-08-01' },
        { source_id: ZHONGWEN, target_id: 'cmn:z', target_text: '普通话', score: 0, created_at: '2026-08-01' },
      ] }) },
    ]);
    const map = await resolveLocalizedNames(db, [
      { kind: 'language', langCode: 'jpn', identityCode: 'jpn' },
      { kind: 'language', langCode: 'cmn', identityCode: 'cmn' },
    ], parseLocaleHints('cmn-Hans-CN', undefined));
    expect(map.get('jpn')?.name).toBe('日语');
    expect(map.get('cmn')?.name).toBe('普通话');
  });

  it('falls back for unknown codes and NULL bindings without erroring', async () => {
    const db = fakeD1([
      { sql: 'FROM languages WHERE code IN', handler: () => ({ results: [] }) },
    ]);
    const map = await resolveLocalizedNames(db, [{ kind: 'language', langCode: 'zzz', identityCode: 'zzz' }], parseLocaleHints('cmn-Hans-CN', undefined));
    expect(map.get('zzz')).toEqual({ lang_code: 'zzz', name: 'zzz', name_en: 'zzz', resolved_from: 'fallback' });
  });
});

describe('resolveLanguageNames / resolveLocaleNames', () => {
  it('returns empty maps for empty inputs', async () => {
    const db = fakeD1([]);
    expect((await resolveLanguageNames(db, [], {})).size).toBe(0);
    expect((await resolveLocaleNames(db, [], {})).size).toBe(0);
  });

  it('resolves language names and self-named locale names', async () => {
    const db = fakeD1([
      { sql: 'FROM languages WHERE code IN', handler: () => ({ results: [{ code: 'jpn', name_expression_id: CANONICAL_JPN, name_en: 'Japanese', name: null }] }) },
      { sql: 'FROM expressions WHERE id IN', handler: () => ({ results: [{ id: CANONICAL_JPN, text: 'Japanese' }] }) },
      { sql: 'FROM language_locales WHERE code IN', handler: () => ({ results: [{ code: 'jpn-Jpan-JP', name_expression_id: null, name_en: 'Japanese (Japan)', name: '日本語' }] }) },
      { sql: 'lang_code FROM language_locales WHERE code = ?', handler: () => ({ lang_code: 'cmn' }) },
      { sql: 'src.id AS source_id', handler: () => ({ results: [{ source_id: CANONICAL_JPN, target_id: RIKYU, target_text: '日语', score: 0, created_at: '2026-08-01' }] }) },
    ]);
    const langs = await resolveLanguageNames(db, ['jpn', 'eng'], parseLocaleHints('cmn-Hans-CN', undefined));
    expect(langs.get('jpn')).toBe('日语');
    expect(langs.get('eng')).toBe('eng');
    const locales = await resolveLocaleNames(db, ['jpn-Jpan-JP'], parseLocaleHints('cmn-Hans-CN', undefined));
    expect(locales.get('jpn-Jpan-JP')).toBe('日本語');
  });
});

describe('resolveNamesByExpressionIds', () => {
  it('resolves a known name_expression_id via the primary locale', async () => {
    const db = fakeD1([
      { sql: 'FROM expressions WHERE id IN', handler: () => ({ results: [{ id: PLURAL_EN, text: 'plural' }] }) },
      { sql: 'lang_code FROM language_locales WHERE code = ?', handler: () => ({ lang_code: 'cmn' }) },
      { sql: 'src.id AS source_id', handler: () => ({ results: [{ source_id: PLURAL_EN, target_id: 'cmn:plural', target_text: '复数', score: 0, created_at: '2026-08-01' }] }) },
    ]);
    const map = await resolveNamesByExpressionIds(db, [PLURAL_EN], parseLocaleHints('cmn-Hans-CN', undefined));
    expect(map.get(PLURAL_EN)).toEqual({ name: '复数', name_en: 'plural' });
  });

  it('falls back to the English expression text when no translation exists', async () => {
    const db = fakeD1([
      { sql: 'FROM expressions WHERE id IN', handler: () => ({ results: [{ id: PLURAL_EN, text: 'plural' }] }) },
      { sql: 'lang_code FROM language_locales WHERE code = ?', handler: () => ({ lang_code: 'cmn' }) },
      { sql: 'src.id AS source_id', handler: () => ({ results: [] }) },
    ]);
    const map = await resolveNamesByExpressionIds(db, [PLURAL_EN], parseLocaleHints('cmn-Hans-CN', undefined));
    expect(map.get(PLURAL_EN)).toEqual({ name: 'plural', name_en: 'plural' });
  });

  it('skips missing expressions so the caller can fall back to code', async () => {
    const db = fakeD1([
      { sql: 'FROM expressions WHERE id IN', handler: () => ({ results: [] }) },
    ]);
    const map = await resolveNamesByExpressionIds(db, ['eng:missing'], {});
    expect(map.has('eng:missing')).toBe(false);
  });
});
