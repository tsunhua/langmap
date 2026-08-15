# Plan: Localized Language Names — Backend

- **Date**: 2026-08-15
- **Status**: Draft
- **Spec**: `docs/superpowers/specs/2026-08-15-localized-language-names-design.md`
- **Plan family**: 此為三份計畫的第一份。第二份（seed／同步資料）與第三份（前端）依序完成後才整體驗收。

## Goal

後端完成「語言／locale 名稱本地化」的資料模型與解析入口：

1. schema 增列 `languages.name_expression_id`、`language_locales.name_expression_id`（nullable，REFERENCES expressions(id)），migration 0019 與 `schema.sql` 同步。
2. 新增共用批次解析服務 `localizedName.ts`：依 primary／secondary UI locale 解析 identity 的顯示名稱，回退鏈與候選排序依 spec。
3. 既有公開 API 一律接收 `ui_locale` 與 `secondary_ui_locale`。依 spec §6.1：language summary 的 `name` 改為解析後名稱（`name_en` 不變）、locale 新增 `display_name`（保留自稱 `name` 與 `name_en`）、expression 資料新增 `language_name`。

seed 資料（canonical expression、translation edge、attestation、binding）**不在本計畫**，屬第二份 seed 計畫，經 `scripts/language-reference` 與 `scripts/db` 流程落地。本計畫驗證以 fakeD1 為主；種子資料落地前 `name_expression_id` 全為 NULL，回退鏈仍安全（name_en／自稱／code）。

## Architecture

```
                 ┌────────────────────────────────────────────┐
                 │  resolveLocalizedNames(db, requests, hints) │  ← 共用批次解析器
                 │   · loadIdentities      (languages/locales) │
                 │   · parseLocaleHints    (valid + dedup)     │
                 │   · loadCandidateMap    (1 個 locale 1 次 SQL)│
                 │   · fallback per kind                       │
                 └────────────────────────────────────────────┘
                       ▲              ▲
        resolveLanguageNames      resolveLocaleNames  (convenience wrappers)
                       │              │
   routes / services: mappingGraph, languageContent, languageLocales,
                      languageRegistry, handbooks, feed, search
```

候選選取（spec §5.2）單一 SQL、一次取回、JS 依 `source_id` 取第一個 row，保持 spec 穩定排序（`e.score DESC, e.created_at ASC, t.id ASC`）與「distinct codes、不得逐節點查詢」的約束。

## Tech Stack

- Hono + TypeScript + Cloudflare Workers + D1（現有後端堆疊，無新依賴）。
- 測試沿用 Vitest + fakeD1（`languageContent.test.ts` 樣板）；僅 migration 相關驗證用 `scripts/db/manage.py`。

## Risks and Uncertainties

| Risk | Impact | Mitigation |
|---|---|---|
| SQLite `ALTER TABLE ADD COLUMN ... REFERENCES` 在 D1 不支援 | migration 套用失敗 | 先在本機 rebuild 驗證；若失敗改為 `0008` 式的整表重建 migration |
| 候選 SQL 的 `JOIN expressions src ON src.id = e.a OR src.id = e.b` 對「雙端點都在 source 集合」的邊產生重複 row | 同一邊被兩次當候選 | JS 依 `source_id` 去重取首個；新增測試覆蓋 |
| resolver 的 SQL 常數與測試重複 | 漂移 | 沿用既有測試慣例（如 `languageContent.test.ts` 複製 SQL 字串）並以 substring keying 綁定 |
| 前端現有欄位（如 `name`、`name_en`）語意被誤改 | 破壞既有消費端 | language summary 的 `name` 依 spec §6.1 改為解析後名稱（既有 self-name 查詢即解析之一，現有測試相容）；`name_en` 與 locale 自稱 `name` 語意不變；locale 新增 `display_name` |
| 未知／格式無效 locale 參數造成 400/500 | 違反 spec 容忍規則 | `parseLocaleHints` 過濾後只對有效 locale 查詢；無效一律回退 |
| 真實資料整合測試需 seed 才完整 | 本計畫驗收偏弱 | 整合測試只驗「無 seed 下的回退行為」；seed 依賴斷言移入第二份計畫 |

## Task List

### T1: Migration 0019 + schema.sql + contract test + migration lock

成功標準：本機 `rebuild` 後 schema 含新欄位、migration lock 同步、`npm test` 的 schemaContract 通過。

1. 新增 `backend/migrations/0019_language_name_expression_id.sql`：

```sql
-- Bind each language and language locale to the canonical expression that
-- carries its primary name, enabling locale-scoped name resolution.
-- (spec: 2026-08-15-localized-language-names-design.md)
-- Nullable: rows without a canonical expression fall back to name_en /
-- self-name / code. Canonical expressions themselves arrive with the seed
-- data (second plan) via scripts/language-reference + scripts/db.
ALTER TABLE languages ADD COLUMN name_expression_id TEXT REFERENCES expressions(id);
ALTER TABLE language_locales ADD COLUMN name_expression_id TEXT REFERENCES expressions(id);
```

2. `backend/schema.sql`：

```sql
CREATE TABLE languages (
    code TEXT PRIMARY KEY,
    name_en TEXT NOT NULL,
    name_expression_id TEXT REFERENCES expressions(id)
);

CREATE TABLE language_locales (
  code TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  script_code TEXT NOT NULL,
  region_code TEXT NOT NULL,
  place_path TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL,
  name_en TEXT NOT NULL,
  name_expression_id TEXT REFERENCES expressions(id),
  latitude REAL,
  ...
);
```

> SQLite 允許 FK 向前參照（`expressions` 在 `languages` 之後建立）。`name_expression_id` 均為 nullable，故既有 INSERT 不受影響。

3. `backend/tests/schemaContract.test.ts` 新增測試（既有 regex 因 `[\s\S]*?` 仍匹配）：

```ts
it('adds name_expression_id to languages and language_locales', () => {
  expect(schema).toMatch(/CREATE TABLE languages[\s\S]*?name_expression_id TEXT REFERENCES expressions\(id\)/s);
  expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?name_expression_id TEXT REFERENCES expressions\(id\)/s);
});
```

4. 同步 migration lock：

```bash
cd scripts/db && python3 -c "
from lib import migrations, paths
p = paths.ProjectPaths.discover()
migrations.sync_migration_lock(p.migrations_dir, p.migration_lock_path, update=True, baseline_created_at='', git_commit='')
print('lock updated')"
```

5. 重建本機 D1 並驗證：

```bash
cd scripts/db && ./manage.sh local rebuild && ./manage.sh local verify
cd ../.. && cd backend && npm test
```

### T2: `localizedName.ts` 共用批次解析器 + 測試

成功標準：解析器單元測試全綠；fakeD1 下覆蓋 spec 的合格候選、穩定選擇、回退鏈、批次去重、容忍無效 locale。

新增 `backend/src/services/localizedName.ts`：

```ts
import type { D1Database } from '@cloudflare/workers-types';
import { parseLanguageLocaleCode } from './languageIdentity';

export type IdentityKind = 'language' | 'locale';

export interface LocalizedNameRequest {
  kind: IdentityKind;
  langCode: string;
  identityCode: string;
}

export interface LocalizedNameResult {
  lang_code: string;
  name: string;
  name_en: string;
  resolved_from: 'primary' | 'secondary' | 'fallback';
}

export interface LocaleHints {
  primary?: string;
  secondary?: string;
}

interface IdentityRow {
  code: string;
  name_expression_id: string | null;
  name_en: string;
  name: string | null;
}

interface CandidateRow {
  source_id: string;
  target_id: string;
  target_text: string;
  score: number;
  created_at: string;
}

const IDENTITY_LANGUAGE_SQL =
  'SELECT code, name_expression_id, name_en, NULL AS name FROM languages WHERE code IN (SELECT value FROM json_each(?))';
const IDENTITY_LOCALE_SQL =
  'SELECT code, name_expression_id, name_en, name FROM language_locales WHERE code IN (SELECT value FROM json_each(?))';
const LOCALE_LANG_SQL = 'SELECT lang_code FROM language_locales WHERE code = ?';
export const CANDIDATE_SQL = `SELECT src.id AS source_id, t.id AS target_id, t.text AS target_text, e.score, e.created_at
FROM expression_edges e
JOIN expressions src ON src.id = e.expression_a_id OR src.id = e.expression_b_id
JOIN expressions t ON t.id = CASE WHEN e.expression_a_id = src.id THEN e.expression_b_id ELSE e.expression_a_id END
WHERE src.id IN (SELECT value FROM json_each(?))
  AND e.score >= 0
  AND t.lang_code = ?
  AND EXISTS (SELECT 1 FROM expression_locale_attestations a WHERE a.expression_id = t.id AND a.language_locale_code = ?)
ORDER BY src.id ASC, e.score DESC, e.created_at ASC, t.id ASC`;

export function parseLocaleHints(primary: string | undefined, secondary: string | undefined): LocaleHints {
  return {
    primary: primary && primary.trim() ? primary.trim() : undefined,
    secondary: secondary && secondary.trim() ? secondary.trim() : undefined,
  };
}

function parseLocaleCodes(hints: LocaleHints): string[] {
  const seen = new Set<string>();
  const codes: string[] = [];
  for (const value of [hints.primary, hints.secondary]) {
    if (!value) continue;
    if (!parseLanguageLocaleCode(value) || seen.has(value)) continue;
    seen.add(value);
    codes.push(value);
  }
  return codes;
}

async function loadIdentities(db: D1Database, requests: readonly LocalizedNameRequest[]): Promise<Map<string, IdentityRow>> {
  const languageCodes = [...new Set(requests.filter((r) => r.kind === 'language').map((r) => r.identityCode))];
  const localeCodes = [...new Set(requests.filter((r) => r.kind === 'locale').map((r) => r.identityCode))];
  const identities = new Map<string, IdentityRow>();
  if (languageCodes.length > 0) {
    const { results } = await db.prepare(IDENTITY_LANGUAGE_SQL).bind(JSON.stringify(languageCodes)).all<IdentityRow>();
    for (const row of results) identities.set(row.code, row);
  }
  if (localeCodes.length > 0) {
    const { results } = await db.prepare(IDENTITY_LOCALE_SQL).bind(JSON.stringify(localeCodes)).all<IdentityRow>();
    for (const row of results) identities.set(row.code, row);
  }
  return identities;
}

async function loadLocaleLangCodes(db: D1Database, localeCodes: readonly string[]): Promise<Map<string, string>> {
  const langCodes = new Map<string, string>();
  for (const localeCode of localeCodes) {
    const row = await db.prepare(LOCALE_LANG_SQL).bind(localeCode).first<{ lang_code: string }>();
    if (row) langCodes.set(localeCode, row.lang_code);
  }
  return langCodes;
}

async function loadCandidateMap(
  db: D1Database,
  sourceIds: readonly string[],
  langCode: string,
  localeCode: string,
): Promise<Map<string, string>> {
  if (sourceIds.length === 0 || !langCode) return new Map();
  const { results } = await db.prepare(CANDIDATE_SQL).bind(JSON.stringify(sourceIds), langCode, localeCode).all<CandidateRow>();
  const selected = new Map<string, string>();
  for (const row of results) {
    if (selected.has(row.source_id)) continue;
    selected.set(row.source_id, row.target_text);
  }
  return selected;
}

function fallbackName(kind: IdentityKind, row: IdentityRow | undefined, identityCode: string): string {
  if (!row) return identityCode;
  if (kind === 'language') return row.name_en || identityCode;
  return row.name || row.name_en || identityCode;
}

export async function resolveLocalizedNames(
  db: D1Database,
  requests: readonly LocalizedNameRequest[],
  hints: LocaleHints,
): Promise<Map<string, LocalizedNameResult>> {
  const results = new Map<string, LocalizedNameResult>();
  if (requests.length === 0) return results;

  const identities = await loadIdentities(db, requests);
  const localeCodes = parseLocaleCodes(hints);
  const sourceIds = [
    ...new Set(requests.map((r) => identities.get(r.identityCode)?.name_expression_id).filter((id): id is string => Boolean(id))),
  ];

  const localeLangCodes = localeCodes.length > 0 ? await loadLocaleLangCodes(db, localeCodes) : new Map<string, string>();
  const primaryMap = localeCodes.length > 0
    ? await loadCandidateMap(db, sourceIds, localeLangCodes.get(localeCodes[0]) ?? '', localeCodes[0])
    : new Map<string, string>();
  const secondaryMap = localeCodes.length > 1
    ? await loadCandidateMap(db, sourceIds, localeLangCodes.get(localeCodes[1]) ?? '', localeCodes[1])
    : new Map<string, string>();

  for (const request of requests) {
    const row = identities.get(request.identityCode);
    const expressionId = row?.name_expression_id;
    const resolved = expressionId ? (primaryMap.get(expressionId) ?? secondaryMap.get(expressionId)) : undefined;
    results.set(request.identityCode, {
      lang_code: request.langCode,
      name: resolved ?? fallbackName(request.kind, row, request.identityCode),
      name_en: row?.name_en ?? request.identityCode,
      resolved_from:
        expressionId && primaryMap.has(expressionId)
          ? 'primary'
          : expressionId && secondaryMap.has(expressionId)
            ? 'secondary'
            : 'fallback',
    });
  }
  return results;
}

export async function resolveLanguageNames(
  db: D1Database,
  langCodes: readonly string[],
  hints: LocaleHints,
): Promise<Map<string, string>> {
  const distinct = [...new Set(langCodes.map((c) => c.trim()).filter(Boolean))];
  if (distinct.length === 0) return new Map();
  const resolved = await resolveLocalizedNames(
    db,
    distinct.map((code) => ({ kind: 'language' as const, langCode: code, identityCode: code })),
    hints,
  );
  return new Map([...resolved].map(([code, result]) => [code, result.name]));
}

export async function resolveLocaleNames(
  db: D1Database,
  localeCodes: readonly string[],
  hints: LocaleHints,
): Promise<Map<string, string>> {
  const distinct = [...new Set(localeCodes.map((c) => c.trim()).filter(Boolean))];
  if (distinct.length === 0) return new Map();
  const resolved = await resolveLocalizedNames(
    db,
    distinct.map((code) => ({ kind: 'locale' as const, langCode: '', identityCode: code })),
    hints,
  );
  return new Map([...resolved].map(([code, result]) => [code, result.name]));
}
```

新增 `backend/tests/localizedName.test.ts`（predicate 型 fakeD1，SQL 以 substring keying）：

```ts
import { describe, expect, it } from 'vitest';
import { CANDIDATE_SQL, parseLocaleHints, resolveLanguageNames, resolveLocaleNames, resolveLocalizedNames } from '../src/services/localizedName';

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
      { sql: 'lang_code FROM language_locales WHERE code = ?', handler: () => ({ lang_code: 'cmn' }) },
      { sql: 'src.id AS source_id', handler: () => ({ results: [{ source_id: CANONICAL_JPN, target_id: RIKYU, target_text: '日语', score: 0, created_at: '2026-08-01' }] }) },
    ]);
    const map = await resolveLocalizedNames(db, [{ kind: 'language', langCode: 'jpn', identityCode: 'jpn' }], parseLocaleHints('cmn-Hans-CN', 'cmn-Hant-TW'));
    expect(map.get('jpn')).toEqual({ lang_code: 'jpn', name: '日语', name_en: 'Japanese', resolved_from: 'primary' });
  });

  it('falls back to the secondary locale when the primary has no candidate', async () => {
    const db = fakeD1([
      { sql: 'FROM languages WHERE code IN', handler: () => ({ results: [{ code: 'jpn', name_expression_id: CANONICAL_JPN, name_en: 'Japanese', name: null }] }) },
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
```

執行：`cd backend && npm test -- localizedName`

### T3: mappingGraph 本地化名稱 + 圖譜 route

成功標準：`getMappingGraph` 接受 `locales`，節點 `language_name` 為解析後名稱；既有測試仍綠（其 fakeD1 對未知查詢回空 → 回退 code）。

修改 `backend/src/services/mappingGraph.ts`：

```ts
import type { D1Database } from '@cloudflare/workers-types';
import type { MappingGraphEdge, MappingGraphNode, MappingGraphResponse } from '../types/mapping';
import { resolveLanguageNames, type LocaleHints } from './localizedName';

const DEFAULT_NODE_LIMIT = 200;

interface GraphEdgeRow {
  id: string;
  expression_a_id: string;
  expression_b_id: string;
  score: number;
  created_at: string;
  expression_a_text: string;
  expression_a_lang_code: string;
  expression_b_text: string;
  expression_b_lang_code: string;
}

function toNode(row: GraphEdgeRow, expressionId: string, depth: number, nameMap: ReadonlyMap<string, string>): MappingGraphNode {
  const isA = row.expression_a_id === expressionId;
  const langCode = isA ? row.expression_a_lang_code : row.expression_b_lang_code;
  return {
    expression_id: expressionId,
    text: isA ? row.expression_a_text : row.expression_b_text,
    lang_code: langCode,
    language_name: nameMap.get(langCode) ?? langCode,
    depth,
  };
}

async function loadEdgesForFrontier(db: D1Database, frontier: readonly string[]): Promise<GraphEdgeRow[]> {
  const placeholders = frontier.map(() => '?').join(', ');
  const { results } = await db.prepare(
    `SELECT e.id, e.expression_a_id, e.expression_b_id, e.score, e.created_at,
      a.text AS expression_a_text, a.lang_code AS expression_a_lang_code,
      b.text AS expression_b_text, b.lang_code AS expression_b_lang_code
     FROM expression_edges e
     JOIN expressions a ON a.id = e.expression_a_id
     JOIN expressions b ON b.id = e.expression_b_id
     WHERE e.expression_a_id IN (${placeholders}) OR e.expression_b_id IN (${placeholders})
     ORDER BY e.score DESC, e.created_at ASC, e.id ASC`,
  ).bind(...frontier, ...frontier).all<GraphEdgeRow>();
  return results;
}

export async function getMappingGraph(
  db: D1Database,
  rootId: string,
  hops: 1 | 2 | 3,
  nodeLimit = DEFAULT_NODE_LIMIT,
  locales: LocaleHints = {},
): Promise<MappingGraphResponse | null> {
  const root = await db.prepare(
    'SELECT id, text, lang_code FROM expressions WHERE id = ?',
  ).bind(rootId).first<{ id: string; text: string; lang_code: string }>();
  if (!root) return null;

  const limit = Math.max(1, Math.min(nodeLimit, DEFAULT_NODE_LIMIT));
  const visited = new Set<string>([rootId]);
  const rootNames = await resolveLanguageNames(db, [root.lang_code], locales);
  const nodes: MappingGraphNode[] = [{
    expression_id: root.id,
    text: root.text,
    lang_code: root.lang_code,
    language_name: rootNames.get(root.lang_code) ?? root.lang_code,
    depth: 0,
  }];
  const edges: MappingGraphEdge[] = [];
  const edgeIds = new Set<string>();
  const omitted = new Set<string>();
  const layerCounts: Record<number, number> = { 0: 1 };
  let frontier = [rootId];
  let resolvedHops: 0 | 1 | 2 | 3 = 0;

  for (let depth = 1; depth <= hops && frontier.length > 0; depth++) {
    const rows = await loadEdgesForFrontier(db, frontier);
    const langCodes = [...new Set(rows.flatMap((row) => [row.expression_a_lang_code, row.expression_b_lang_code]))];
    const nameMap = await resolveLanguageNames(db, langCodes, locales);
    const next = new Set<string>();
    const frontierIds = new Set(frontier);
    for (const row of rows) {
      const touchesA = frontierIds.has(row.expression_a_id);
      const touchesB = frontierIds.has(row.expression_b_id);
      if (!touchesA && !touchesB) continue;
      if (!edgeIds.has(row.id)) {
        edgeIds.add(row.id);
        edges.push({ edge_id: row.id, source_id: row.expression_a_id, target_id: row.expression_b_id, score: row.score, depth });
      }
      const neighbors = touchesA && touchesB ? [] : [touchesA ? row.expression_b_id : row.expression_a_id];
      for (const endpoint of neighbors) {
        if (visited.has(endpoint)) continue;
        if (visited.size >= limit) { omitted.add(endpoint); continue; }
        visited.add(endpoint);
        next.add(endpoint);
        nodes.push(toNode(row, endpoint, depth, nameMap));
      }
    }
    if (rows.length > 0) resolvedHops = depth as 1 | 2 | 3;
    layerCounts[depth] = next.size;
    frontier = [...next].sort();
  }

  return {
    root_id: rootId,
    requested_hops: hops,
    resolved_hops: resolvedHops,
    nodes,
    edges,
    layer_counts: layerCounts,
    truncated: omitted.size > 0,
    omitted_count: omitted.size,
  };
}
```

修改 `backend/src/routes/expressions.ts` 的 `GET /:id/mappings`：

```ts
expressions.get('/:id/mappings', async (c) => {
  const id = c.req.param('id') ?? '';
  const rawHops = Number.parseInt(c.req.query('hops') ?? '1', 10);
  if (rawHops < 1 || rawHops > 3 || !Number.isInteger(rawHops)) return badRequest(c, 'INVALID_HOPS', 'hops must be 1, 2, or 3');
  const graph = await getMappingGraph(
    c.env.DB,
    id,
    rawHops as 1 | 2 | 3,
    undefined,
    parseLocaleHints(c.req.query('ui_locale'), c.req.query('secondary_ui_locale')),
  );
  if (!graph) return notFoundCode(c, 'EXPRESSION_NOT_FOUND', 'Expression not found');
  return success(c, graph);
});
```

import 補 `parseLocaleHints`。

`backend/tests/mappingGraphV2.test.ts` 新增（既有測試維持原樣仍須通過）：既有 `import { getMappingGraph } from '../src/services/mappingGraph';` 旁補 `import { parseLocaleHints } from '../src/services/localizedName';`，再新增：

```ts
it('resolves node language names via the shared resolver', async () => {
  const graph = await getMappingGraph(
    fakeD1([
      { id: 'e1', expression_a_id: 'eng:a', expression_b_id: 'nan:root', score: 2, created_at: '2026-08-01', expression_a_text: 'rice', expression_a_lang_code: 'eng', expression_b_text: '食', expression_b_lang_code: 'nan' },
    ]),
    'nan:root', 1, 200, parseLocaleHints('cmn-Hans-CN', undefined),
  );
  // fakeD1 對未知查詢回空 → 每個 lang_code 回退為自身 code
  expect(graph?.nodes.map((node) => node.language_name)).toEqual(['nan', 'eng']);
});
```

執行：`cd backend && npm test -- mappingGraphV2`

### T4: languageContent 本地化名稱（list / detail / expressions）

成功標準：三個函式接收 locale hints；list／detail 的 `name` 為解析後名稱、locales 各加 `display_name`、expressions items 加 `language_name`，既有測試相容、新測試全綠。

`backend/src/services/languageContent.ts`：

- `LanguageContentSummary.name`：`all()` 後收集 `items.map(i => i.code)`，`resolveLanguageNames(db, codes, parseLocaleHints(uiLocale, secondaryUiLocale))`，逐 item 設 `name = map.get(code) ?? item.name_en`。`name_en` 語意不變。
- `LanguageLocaleSummary` 各加 `display_name: string`；`getLanguageDetail(db, code, hints: LocaleHints = {})` 的 `locales.map(l => ({ ...l, display_name: localeNames.get(l.code) ?? l.name }))` 用 `resolveLocaleNames`（自稱 `name`、`name_en` 保留）。
- `listLanguageExpressions`：query 型別加 `secondaryUiLocale`；結果 item 加 `language_name`（`resolveLanguageNames`）。

`backend/src/routes/languages.ts` 改動（三處都傳 locale）：

```ts
languages.get('/', async (c) => {
  const query = parseQuery(c);
  const sort = c.req.query('sort') === 'alpha' ? 'alpha' : 'count';
  const result = await listLanguagesWithContent(c.env.DB, {
    ...query,
    sort,
    uiLocale: c.req.query('ui_locale') ?? '',
    secondaryUiLocale: c.req.query('secondary_ui_locale') ?? '',
  });
  return paginated(c, result.items, result.total, query.offset, query.limit);
});

languages.get('/:code/expressions', async (c) => {
  const code = (c.req.param('code') ?? '').toLowerCase();
  const query = parseQuery(c);
  const result = await listLanguageExpressions(c.env.DB, code, {
    ...query,
    locale: c.req.query('locale') ?? '',
    sort: parseExpressionSort(c.req.query('sort')),
    secondaryUiLocale: c.req.query('secondary_ui_locale') ?? '',
  });
  if (!result) return notFound(c, 'Language');
  return paginated(c, result.items, result.total, query.offset, query.limit);
});

languages.get('/:code', async (c) => {
  const detail = await getLanguageDetail(
    c.env.DB,
    (c.req.param('code') ?? '').toLowerCase(),
    parseLocaleHints(c.req.query('ui_locale'), c.req.query('secondary_ui_locale')),
  );
  if (!detail) return notFound(c, 'Language');
  return success(c, detail);
});
```

> `name_en` 與 locale 自稱 `name` 語意不變；list／detail 的 `name` 為解析後名稱、locale 新增 `display_name`。`/:code` 現況未傳 `ui_locale`，本次補上。

`backend/tests/languageContent.test.ts` 新增（沿用既有 fakeD1，對 resolver 未知查詢回空 → 回退）：

```ts
it('resolves language name via the shared resolver', async () => {
  const result = await listLanguagesWithContent(db, { q: '', sort: 'count', limit: 20, offset: 0, uiLocale: 'cmn-Hans-CN', secondaryUiLocale: '' });
  expect(result.items[0].name).toBe('Mandarin Chinese'); // 無 binding → name_en 回退
});

it('adds display_name for locales on detail', async () => {
  const detail = await getLanguageDetail(db, 'cmn', parseLocaleHints('cmn-Hans-CN', undefined));
  expect(detail?.name).toBe('Mandarin Chinese');
  expect(detail?.locales[0].display_name).toBe('普通话(CN)'); // 無 binding → 自稱回退
});
```

執行：`cd backend && npm test -- languageContent`

### T5: languageLocales + languageRegistry 本地化名稱

成功標準：locale 列表／詳情新增 `display_name`、languages registry 新增解析後 `name`，未知 locale 參數不 400/500。

- `backend/src/routes/languageLocales.ts` `GET /`：查詢後收集 row codes，`resolveLocaleNames`，逐 row 加 `display_name = map.get(code) ?? row.name`（`name`、`name_en` 保留）。
- `GET /:code`：單一 row 同法加 `display_name`。
- `backend/src/routes/languageRegistry.ts`：`respond()` 於 `table === 'languages'` 時對 items 加 `name`（`resolveLanguageNames`）；scripts／regions 不變。

測試：`backend/tests/languageLocales.test.ts`、`registryIntegration.test.ts` 或新檔 `backend/tests/registryLocalizedName.test.ts` 以 fakeD1 驗證 `display_name`／`name` 附加與回退。執行：`cd backend && npm test -- languageLocales registry`

### T6: handbooks + feed + search 本地化名稱

成功標準：handbook 詳情 items、feed /hot、/new、expressions /search 皆含解析後語言名稱。

- `backend/src/routes/handbooks.ts` `GET /:id`：items 查詢移除 `LEFT JOIN languages l ... l.name_en AS language_name`（改為只取 `e.lang_code`），JS 以 `resolveLanguageNames` 填 `language_name`；handler 讀 `ui_locale`／`secondary_ui_locale`。
- `backend/src/routes/feed.ts` `GET /hot`：rows 附加 `a_language_name`／`b_language_name`；`GET /new` 附加 `left_language_name`／`right_language_name`；兩個 handler 讀 locale params。
- `backend/src/services/expressions.ts` `searchExpressions`：query 加 `hints: LocaleHints`，結果 item 加 `language_name`（型別 `ExpressionRow & { language_name: string }`）。`backend/src/routes/expressions.ts` `GET /search` 傳入 `parseLocaleHints(...)`。
- `backend/src/routes/expressions.ts` `GET /:id`：attestations 與 readings 各 row 依 `language_locale_code` 加 `locale_display_name`（`resolveLocaleNames`；無 binding 回退自稱 `name`）；handler 讀 `ui_locale`／`secondary_ui_locale`。供前端證據清單顯示（spec §6.3「display_name＋完整 code」）。

測試：擴充 `backend/tests/handbooks.test.ts`、`feed.test.ts`、`expressions.test.ts`，fakeD1 驗證附加欄位與回退。執行：`cd backend && npm test -- handbooks feed expressions`

### T7: 完整迴圈與跨前後端驗證

1. `cd backend && npm test`（全數綠）。
2. `cd web && npm run build`（前端契約未動，確保仍通過）。
3. `./build.sh`。
4. `git diff --check`。
5. 依 `feat/20260725/langmap_v2` 分支，分 commit 提交（Surgical Changes）：

```
feat: add name_expression_id columns to languages and language_locales
feat: add shared localized name resolver for languages and locales
feat: localize language names in mapping graph
feat: localize language names in content list and detail APIs
feat: localize names in locale, registry, handbook, feed and search APIs
```

## Repo Hygiene

- 不修改 `apple/`；不觸碰 `web/` 邏輯（僅驗證 build）。
- `web/dist/`、`backend/public/`、`.wrangler/` 為生成物，不手動改。
- migration lock 更新後一併 commit。
- 依 spec §6.1：`name_en` 與 locale 自稱 `name` 語意不變；language summary 的 `name` 改為解析後名稱；locale 新增 `display_name`。

## Final Integration

- 種子資料落地（第二份計畫）後，真實 D1 整合測試（`languagesIntegration.test.ts` 等）補 `jpn → 日语`（cmn-Hans-CN）、`jpn → 日語`（cmn-Hant-TW）、`cmn-Hant-TW 不誤用簡體候選`、secondary 回退、負分拒絕、tie-breaking、batch dedup、NULL／未知 code 安全回退。
- 前端（第三份計畫）切換 primary／secondary locale 驗證 `/mapping/cmn:uatw46tkfaeq2igc7xhtci62km?node=cmn:fg6livf5llbcxn66umfdpwnrnq` 在 cmn-Hans-CN 顯示「日语」，切回英文顯示「Japanese」。
