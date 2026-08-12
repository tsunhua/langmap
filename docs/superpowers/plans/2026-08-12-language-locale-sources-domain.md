# Language Locale + Sources Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 greenfield baseline(Plan 1)之上建立 `sources` 與 `language_locales` 表、Language Locale canonical builder、sources service,以及 `GET/POST /language-locales` 三條 API,作為 Expression、Preferences、UI Localization 全部下游領域的基石。

**Architecture:** 分四層推進:(1) schema baseline(migration 0002 + schema.sql + system seeds + migration-lock);(2) Language Locale grammar/canonical builder 與 registry 存在性檢查(放 `languageIdentity.ts`);(3) 兩層 sources model service(`sources.ts`);(4) `languageLocales` 路由(POST 建置、GET 列表、GET 詳情)。Route 不自行拼接或解析 locale code(core invariant 4、§5.1)。

**Tech Stack:** Hono 4 + TypeScript + Cloudflare Workers + D1(SQLite);Vitest(fake D1 單元測試 + 127.0.0.1:8788 整合測試);Python `scripts/db` 管理工具。

## Global Constraints

以下為各 task 隱含必須遵守的規則,不再逐 task 重複:

- `language_locale_code = lang "-" script "-" region ("_" place_segment)*`;`lang=[a-z]{3}`、`script=[A-Z][a-z]{3}`、`region=[A-Z]{2}`、`place_segment=[A-Z][A-Za-z]*`(§7.1)。Place segment 不允許空字串,code 不含尾隨 `_`。
- Language Locale code 只能由後端 canonical builder 生成(§4.4);Route 不得自行拼接或解析 locale code(§5.1)。
- 只含頂層 region 的 locale,`place_path` 是空字串(§7.2)。
- 座標必須成對:`CHECK ((latitude IS NULL) = (longitude IS NULL))`。locale 無座標而 region 有代表點時,詳情 API 回傳 region fallback 並標 `coordinate_source = 'region'`;locale 自身座標標 `coordinate_source = 'locale'`(§7.2)。
- `sources` 兩層模型:`source_id` 指向共享 `sources` row,`source_ref` 為該 row 具體出處;`source_ref` 不得脫離 `source_id`(CHECK);`(type, name)` UNIQUE,service 依 `(type, name)` 查找或建立,caller 不直接傳 `source_id`;`source` 省略時代表使用者直接建立,`created_by` 由認證自動帶入(§7.3、§13.1)。
- `POST /language-locales` 只接受結構化欄位,不接受 caller 傳入 code(§13.1)。
- 重複 locale(同 `lang_code, script_code, region_code, place_path`)→ 409 `LANGUAGE_LOCALE_EXISTS`(§14)。
- 穩定錯誤碼(本 plan 用到):`INVALID_LANG_CODE`、`INVALID_SCRIPT_CODE`、`INVALID_REGION_CODE`、`INVALID_PLACE_SEGMENT`、`INVALID_LANGUAGE_LOCALE_CODE`、`LANGUAGE_LOCALE_EXISTS`、`INVALID_SOURCE`(§14)。資料庫 constraint error 不直接暴露,service/route 要映射成上述 code(§14)。
- API prefix 一律 `/api/v2`;回應一律 `{ success, data?, error?, message? }`;列表用 `utils/response.ts` 的 `paginated(c, items, total, skip, limit)` helper(AGENTS.md、§13)。
- 所有查詢必須穩定排序(`code ASC`)並有數量上限(`limit` clamp 到 `[1, 50]`,預設 20)(§4.11、Plan 1 service)。
- schema 變更必須同時新增 migration 並更新 `schema.sql`,並同步 migration-lock(AGENTS.md)。
- migration 檔名 `\d{4}_[A-Za-z0-9_]+\.sql`、sequence 連續;`schema.sql` 使用 DROP + 無 `IF NOT EXISTS`,migration 使用 `IF NOT EXISTS` 且不含 DROP(repo 既有慣例)。
- 不新增 `any`;新程式碼不加註解(現有檔案註解為既有內容)。不修改 `web/`、`apple/`、`scripts/db/lib/verify.py` 與其測試 fixture。
- 新增中文資料文案(seed locale `name`)使用傳承體中文(AGENTS.md)。
- 整合測試依賴 127.0.0.1:8788 的 worker 與已 rebuild 的本地 D1(`fileParallelism: false` 已設於 `backend/vitest.config.ts`)。單檔測試用 `npx vitest run tests/<file>.test.ts`,不要用 `npm test`(會連帶跑需要 worker 的其他整合檔)。
- `backend/node_modules/.bin/wrangler` 是本地 wrangler binary;不要用 `npx wrangler`(會嘗試上網下載新版)。

---

## File Structure

| 檔案 | 責任 | 動作 |
|---|---|---|
| `backend/migrations/0002_language_locales.sql` | `sources` + `language_locales` DDL + system seeds(IF NOT EXISTS / INSERT OR IGNORE) | Create |
| `backend/schema.sql` | 與 0002 等價的本地全量 schema(DROP + CREATE + seeds) | Modify |
| `backend/tests/schemaContract.test.ts` | 斷言新表欄位/CHECK/FK 與 seed 存在 | Modify |
| `scripts/db/migration-lock.json` | 記錄 0002 的 sequence/size/sha256(用 sync 更新) | Modify |
| `backend/src/types/language.ts` | `SourceType`、`SourceInput`、`LanguageLocaleParts`、`LanguageLocaleRow` 共用型別 | Create |
| `backend/src/services/languageIdentity.ts` | 新增 `buildLanguageLocaleCode`、`parseLanguageLocaleCode`、`assertReferenceCodesExist`、`LanguageLocaleError`(Plan 1 已含 `parseReferenceQuery`/`escapeLike`) | Modify |
| `backend/src/services/sources.ts` | `findOrCreateSource`、`SourceError` | Create |
| `backend/src/routes/languageLocales.ts` | `POST /`、`GET /`、`GET /:code` 三條 handler | Create |
| `backend/src/routes/index.ts` | 註冊 `languageLocales` route | Modify |
| `backend/tests/languageLocales.test.ts` | grammar/builder/existence/sources 單元測試(fake D1) | Create |
| `backend/tests/languageLocalesIntegration.test.ts` | 三條 API 的整合測試(需 worker + rebuilt D1) | Create |

---

## Task 1: Greenfield schema —— `sources` + `language_locales` + system seeds

把 §7.2 / §7.3 的兩張表與三個系統 seed locale 寫進 migration 0002 與 `schema.sql`,更新契約測試與 migration-lock,並重建本地 D1。

**Files:**
- Create: `backend/migrations/0002_language_locales.sql`
- Modify: `backend/schema.sql`
- Modify: `backend/tests/schemaContract.test.ts`
- Modify: `scripts/db/migration-lock.json`(以 sync 更新,不手編)

**Interfaces:**
- Consumes: Plan 1 的 `backend/schema.sql`(users、languages、scripts、regions)、`backend/migrations/0001_initial_schema.sql`、`scripts/db/migration-lock.json`、`scripts/db/lib/migrations.sync_migration_lock`。
- Produces: `sources` 表與 `language_locales` 表(schema 物件供 verify 比對);3 筆 seed locale(`eng-Latn-US`、`cmn-Hant-TW`、`cmn-Hans-CN`)與 1 筆 system source(`system-seed`);Task 4 的整合測試依賴這些 seed 存在。

- [x] **Step 1: 建立 migration 0002**

Create `backend/migrations/0002_language_locales.sql`:

```sql
-- Language locale + sources tables (spec §7.2, §7.3).

CREATE TABLE IF NOT EXISTS sources (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('publication', 'url', 'system')),
  name TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (type, name),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS language_locales (
  code TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  script_code TEXT NOT NULL,
  region_code TEXT NOT NULL,
  place_path TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL,
  name_en TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (lang_code, script_code, region_code, place_path),
  CHECK ((latitude IS NULL) = (longitude IS NULL)),
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (script_code) REFERENCES scripts(code),
  FOREIGN KEY (region_code) REFERENCES regions(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-seed', 'system', 'LangMap system seeds');

INSERT OR IGNORE INTO language_locales
  (code, lang_code, script_code, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('eng-Latn-US', 'eng', 'Latn', 'US', '', 'English (US)', 'English (US)', 'system-seed', 'seed:system-seed:1'),
  ('cmn-Hant-TW', 'cmn', 'Hant', 'TW', '', '臺灣華語', 'Taiwan Mandarin', 'system-seed', 'seed:system-seed:1'),
  ('cmn-Hans-CN', 'cmn', 'Hans', 'CN', '', '简体中文', 'Simplified Chinese', 'system-seed', 'seed:system-seed:1');
```

- [x] **Step 2: 更新 `backend/schema.sql`**

在檔頭 DROP 區塊的最後(`DROP TABLE IF EXISTS users;` 之前)加入兩行(順序:先 `language_locales` 再 `sources`,因 FK 相依):

```sql
DROP TABLE IF EXISTS language_locales;
DROP TABLE IF EXISTS sources;
```

在 `CREATE TABLE regions (...)` 與其三個 index 之後、檔尾,新增(無 `IF NOT EXISTS`,repo 慣例):

```sql
-- Language locale + sources tables (spec §7.2, §7.3).

CREATE TABLE sources (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('publication', 'url', 'system')),
  name TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (type, name),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE language_locales (
  code TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  script_code TEXT NOT NULL,
  region_code TEXT NOT NULL,
  place_path TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL,
  name_en TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  source_id TEXT,
  source_ref TEXT,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (lang_code, script_code, region_code, place_path),
  CHECK ((latitude IS NULL) = (longitude IS NULL)),
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (script_code) REFERENCES scripts(code),
  FOREIGN KEY (region_code) REFERENCES regions(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-seed', 'system', 'LangMap system seeds');

INSERT OR IGNORE INTO language_locales
  (code, lang_code, script_code, region_code, place_path, name, name_en, source_id, source_ref)
VALUES
  ('eng-Latn-US', 'eng', 'Latn', 'US', '', 'English (US)', 'English (US)', 'system-seed', 'seed:system-seed:1'),
  ('cmn-Hant-TW', 'cmn', 'Hant', 'TW', '', '臺灣華語', 'Taiwan Mandarin', 'system-seed', 'seed:system-seed:1'),
  ('cmn-Hans-CN', 'cmn', 'Hans', 'CN', '', '简体中文', 'Simplified Chinese', 'system-seed', 'seed:system-seed:1');
```

- [x] **Step 3: 更新 `backend/tests/schemaContract.test.ts`**

在既有 describe 內、`keeps the users table for auth` 之後新增三個 it:

```ts
  it('defines the sources table for two-layer provenance', () => {
    expect(schema).toMatch(/CREATE TABLE sources[\s\S]*?type TEXT NOT NULL CHECK \(type IN \('publication', 'url', 'system'\)\)[\s\S]*?UNIQUE \(type, name\)/s);
    expect(schema).toMatch(/CREATE TABLE sources[\s\S]*?FOREIGN KEY \(created_by\) REFERENCES users\(id\)/s);
  });

  it('defines language_locales with the spec columns and checks', () => {
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?code TEXT PRIMARY KEY/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?name TEXT NOT NULL[\s\S]*?name_en TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?UNIQUE \(lang_code, script_code, region_code, place_path\)/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?CHECK \(\(latitude IS NULL\) = \(longitude IS NULL\)\)/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?CHECK \(source_ref IS NULL OR source_id IS NOT NULL\)/s);
    expect(schema).toMatch(/CREATE TABLE language_locales[\s\S]*?FOREIGN KEY \(lang_code\) REFERENCES languages\(code\)[\s\S]*?FOREIGN KEY \(script_code\) REFERENCES scripts\(code\)[\s\S]*?FOREIGN KEY \(region_code\) REFERENCES regions\(code\)[\s\S]*?FOREIGN KEY \(source_id\) REFERENCES sources\(id\)/s);
  });

  it('seeds the three system locales', () => {
    expect(schema).toMatch(/eng-Latn-US/);
    expect(schema).toMatch(/cmn-Hant-TW/);
    expect(schema).toMatch(/cmn-Hans-CN/);
  });
```

- [x] **Step 4: 更新 migration-lock 並驗證同步**

從 repo root 執行(此為一次性維護操作,不留 repo 檔案):

```bash
python3 - <<'EOF'
import sys
from pathlib import Path
sys.path.insert(0, str(Path('scripts/db')))
from lib.migrations import sync_migration_lock
lock = sync_migration_lock(
    Path('backend/migrations'),
    Path('scripts/db/migration-lock.json'),
    update=True,
    baseline_created_at='ignored',
    git_commit='ignored',
)
for entry in lock['migrations']:
    print(entry['sequence'], entry['filename'], entry['sha256'])
EOF
```

Expected: 印出 0001 與 0002 兩筆;`migration-lock.json` 的 `migrations` 陣列變成兩筆、metadata(`baseline_created_at`/`baseline_git_commit`)保持不變。

再跑一次同段程式(改 `update=False`)確認無 "unlocked migration" 錯誤。

- [x] **Step 5: 跑 schemaContract 測試**

```bash
cd backend && npx vitest run tests/schemaContract.test.ts
```

Expected: 4 tests PASS。

- [x] **Step 6: 重建本地 D1 並抽查 seed**

先確認 8788 沒有 worker 占用(若有,`kill $(pgrep -f "wrangler dev")`)。然後從 repo root:

```bash
python3 scripts/db/manage.py local rebuild
python3 - <<'EOF'
import glob, sqlite3
path = sorted(glob.glob('backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/*.sqlite'))[0]
con = sqlite3.connect(path)
print('locales:', con.execute("SELECT code, name_en FROM language_locales ORDER BY code").fetchall())
print('sources:', con.execute("SELECT id, type, name FROM sources").fetchall())
EOF
```

Expected: `manage.py local rebuild` 回 `{"status": "rebuilt", ...}`;locales 3 筆(`cmn-Hans-CN`/`cmn-Hant-TW`/`eng-Latn-US`)、sources 1 筆(`system-seed`)。

- [x] **Step 7: 跑 scripts 驗證確認 schema invariant 未破壞**

```bash
python3 -m unittest scripts.db.tests.test_verify
python3 scripts/db/tests/test_local_rebuild.py
```

Expected: 兩者皆 OK(verify 的 schema 物件比對涵蓋新表,fixture 測試不受影響)。

- [x] **Step 8: Commit**

```bash
git add backend/migrations/0002_language_locales.sql backend/schema.sql backend/tests/schemaContract.test.ts scripts/db/migration-lock.json
git commit -m "feat(db): add sources and language_locales tables with system seeds"
```

Commit 後 `git status --short` 應為空或僅有預期之外的新檔(如有,停下回報)。

---

## Task 2: Language Locale grammar 與 canonical builder service

擴充 `languageIdentity.ts`:locale code 的 parse / build(純函式)與 registry 存在性檢查。Route 層不自行做這些。

**Files:**
- Create: `backend/src/types/language.ts`
- Modify: `backend/src/services/languageIdentity.ts`
- Test: `backend/tests/languageLocales.test.ts`

**Interfaces:**
- Consumes: `D1Database`(來自 `c.env.DB`);既有 `parseReferenceQuery`/`escapeLike`(Plan 1)。
- Produces:
  - `buildLanguageLocaleCode(input: { lang_code: string; script_code: string; region_code: string; place_segments?: string[] }): string`
  - `parseLanguageLocaleCode(code: string): LanguageLocaleParts | null`
  - `assertReferenceCodesExist(db: D1Database, langCode: string, scriptCode: string, regionCode: string): Promise<void>`
  - `class LanguageLocaleError extends Error { constructor(public code: string) }`
  - `LanguageLocaleParts = { lang_code; script_code; region_code; place_segments: string[] }`(來自 `types/language.ts`)
  - Task 3 的 `sources.ts` 不依賴本 task;Task 4 的 route 依賴上述全部。

- [x] **Step 1: 寫失敗的單元測試**

Create `backend/tests/languageLocales.test.ts`(涵蓋本 task 的 grammar 函式與 Task 3 的 sources,先只放 grammar 部分,Step 3 會補 sources 段落):

```ts
import { describe, expect, it } from 'vitest';
import {
  LanguageLocaleError,
  assertReferenceCodesExist,
  buildLanguageLocaleCode,
  parseLanguageLocaleCode,
} from '../src/services/languageIdentity';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const prepare = (sql: string) => {
    const handler = handlers[sql];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          async first<T>() {
            return (await run()) as T;
          },
          async run() {
            return { success: true, meta: { changes: 1 } };
          },
          async all<T>() {
            const result = (await run()) as { results?: unknown };
            return { results: (result?.results ?? []) as T };
          },
        };
      },
    };
  };
  return { prepare } as unknown as import('@cloudflare/workers-types').D1Database;
}

function captureCode(fn: () => void): string {
  try {
    fn();
  } catch (error) {
    return (error as LanguageLocaleError).code;
  }
  return '';
}

async function captureAsyncCode(fn: () => Promise<void>): Promise<string> {
  try {
    await fn();
  } catch (error) {
    return (error as LanguageLocaleError).code;
  }
  return '';
}

describe('parseLanguageLocaleCode', () => {
  it('parses a top-level locale', () => {
    expect(parseLanguageLocaleCode('nan-Hant-TW')).toEqual({
      lang_code: 'nan',
      script_code: 'Hant',
      region_code: 'TW',
      place_segments: [],
    });
  });

  it('parses place segments', () => {
    expect(parseLanguageLocaleCode('nan-Hant-CN_Quanzhou_Nanan')).toEqual({
      lang_code: 'nan',
      script_code: 'Hant',
      region_code: 'CN',
      place_segments: ['Quanzhou', 'Nanan'],
    });
  });

  it('rejects malformed codes', () => {
    for (const bad of [
      '',
      'nan-Hant',
      'nan-hant-TW',
      'nan-Hant-tw',
      'nan-Hant-TW_',
      'nan-Hant-TW_New_York_2',
      'nan-Hant-TW_newyork',
    ]) {
      expect(parseLanguageLocaleCode(bad)).toBeNull();
    }
  });
});

describe('buildLanguageLocaleCode', () => {
  it('builds a code and lowercases lang', () => {
    expect(buildLanguageLocaleCode({ lang_code: 'NAN', script_code: 'Hant', region_code: 'TW' })).toBe('nan-Hant-TW');
  });

  it('joins place segments', () => {
    expect(
      buildLanguageLocaleCode({ lang_code: 'nan', script_code: 'Hant', region_code: 'CN', place_segments: ['Quanzhou', 'Nanan'] })
    ).toBe('nan-Hant-CN_Quanzhou_Nanan');
  });

  it('throws stable error codes for invalid parts', () => {
    expect(captureCode(() => buildLanguageLocaleCode({ lang_code: 'nano', script_code: 'Hant', region_code: 'TW' }))).toBe('INVALID_LANG_CODE');
    expect(captureCode(() => buildLanguageLocaleCode({ lang_code: 'nan', script_code: 'Hantt', region_code: 'TW' }))).toBe('INVALID_SCRIPT_CODE');
    expect(captureCode(() => buildLanguageLocaleCode({ lang_code: 'nan', script_code: 'Hant', region_code: 't' }))).toBe('INVALID_REGION_CODE');
    expect(
      captureCode(() => buildLanguageLocaleCode({ lang_code: 'nan', script_code: 'Hant', region_code: 'TW', place_segments: ['newyork'] }))
    ).toBe('INVALID_PLACE_SEGMENT');
  });
});

describe('assertReferenceCodesExist', () => {
  it('resolves when all reference codes exist', async () => {
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT 1 FROM scripts WHERE code = ?': () => ({ ok: 1 }),
      'SELECT 1 FROM regions WHERE code = ?': () => ({ ok: 1 }),
    });
    await expect(assertReferenceCodesExist(db, 'nan', 'Hant', 'TW')).resolves.toBeUndefined();
  });

  it('throws INVALID_LANG_CODE when the language is missing', async () => {
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => null,
      'SELECT 1 FROM scripts WHERE code = ?': () => ({ ok: 1 }),
      'SELECT 1 FROM regions WHERE code = ?': () => ({ ok: 1 }),
    });
    expect(await captureAsyncCode(() => assertReferenceCodesExist(db, 'zzz', 'Hant', 'TW'))).toBe('INVALID_LANG_CODE');
  });
});
```

- [x] **Step 2: 跑測試確認失敗**

```bash
cd backend && npx vitest run tests/languageLocales.test.ts
```

Expected: FAIL(`Cannot find module '../src/services/languageIdentity'` 的 `buildLanguageLocaleCode`/`parseLanguageLocaleCode`/`assertReferenceCodesExist` 不存在)。

- [x] **Step 3: 建立型別與實作**

Create `backend/src/types/language.ts`:

```ts
export type SourceType = 'publication' | 'url' | 'system';

export interface SourceInput {
  type: SourceType;
  name: string;
  ref?: string;
}

export interface LanguageLocaleParts {
  lang_code: string;
  script_code: string;
  region_code: string;
  place_segments: string[];
}

export interface LanguageLocaleRow {
  code: string;
  lang_code: string;
  script_code: string;
  region_code: string;
  place_path: string;
  name: string;
  name_en: string;
  latitude: number | null;
  longitude: number | null;
  source_id: string | null;
  source_ref: string | null;
  created_by: number | null;
  created_at: string;
}
```

Modify `backend/src/services/languageIdentity.ts`:在既有 `parseReferenceQuery`/`escapeLike` 之外,新增下列 export(import `LanguageLocaleParts` from `../types/language`):

```ts
const LANG_CODE_RE = /^[a-z]{3}$/;
const SCRIPT_CODE_RE = /^[A-Z][a-z]{3}$/;
const REGION_CODE_RE = /^[A-Z]{2}$/;
const PLACE_SEGMENT_RE = /^[A-Z][A-Za-z]*$/;

export class LanguageLocaleError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'LanguageLocaleError';
  }
}

export function buildLanguageLocaleCode(input: {
  lang_code: string;
  script_code: string;
  region_code: string;
  place_segments?: string[];
}): string {
  const lang = input.lang_code.toLowerCase();
  const script = input.script_code;
  const region = input.region_code;
  const segments = input.place_segments ?? [];
  if (!LANG_CODE_RE.test(lang)) throw new LanguageLocaleError('INVALID_LANG_CODE');
  if (!SCRIPT_CODE_RE.test(script)) throw new LanguageLocaleError('INVALID_SCRIPT_CODE');
  if (!REGION_CODE_RE.test(region)) throw new LanguageLocaleError('INVALID_REGION_CODE');
  for (const segment of segments) {
    if (!PLACE_SEGMENT_RE.test(segment)) throw new LanguageLocaleError('INVALID_PLACE_SEGMENT');
  }
  const placePath = segments.join('_');
  return `${lang}-${script}-${region}${placePath ? `_${placePath}` : ''}`;
}

export function parseLanguageLocaleCode(code: string): LanguageLocaleParts | null {
  if (!code) return null;
  const [head, ...segments] = code.split('_');
  const match = /^([a-z]{3})-([A-Z][a-z]{3})-([A-Z]{2})$/.exec(head ?? '');
  if (!match) return null;
  if (segments.some((segment) => segment === '' || !PLACE_SEGMENT_RE.test(segment))) return null;
  return {
    lang_code: match[1],
    script_code: match[2],
    region_code: match[3],
    place_segments: segments,
  };
}

export async function assertReferenceCodesExist(
  db: D1Database,
  langCode: string,
  scriptCode: string,
  regionCode: string,
): Promise<void> {
  const lang = await db.prepare('SELECT 1 FROM languages WHERE code = ?').bind(langCode).first();
  if (!lang) throw new LanguageLocaleError('INVALID_LANG_CODE');
  const script = await db.prepare('SELECT 1 FROM scripts WHERE code = ?').bind(scriptCode).first();
  if (!script) throw new LanguageLocaleError('INVALID_SCRIPT_CODE');
  const region = await db.prepare('SELECT 1 FROM regions WHERE code = ?').bind(regionCode).first();
  if (!region) throw new LanguageLocaleError('INVALID_REGION_CODE');
}
```

- [x] **Step 4: 跑測試確認通過**

```bash
cd backend && npx vitest run tests/languageLocales.test.ts
```

Expected: 本 task 的 8 個 test PASS(parse 3、build 3、assertReferenceCodesExist 2;Task 3 段落尚未加入,Step 6 後總數會增加)。

- [x] **Step 5: Commit**

```bash
git add backend/src/types/language.ts backend/src/services/languageIdentity.ts backend/tests/languageLocales.test.ts
git commit -m "feat(api): add language locale grammar and canonical builder"
```

---

## Task 3: Sources service(`findOrCreateSource`)

兩層來源模型的 service 層:`(type, name)` 查找或建立 `sources` row。

**Files:**
- Create: `backend/src/services/sources.ts`
- Test: Modify `backend/tests/languageLocales.test.ts`(追加 sources describe)

**Interfaces:**
- Consumes: `D1Database`;`SourceType` from `types/language`;Task 1 的 `sources` 表。
- Produces:
  - `class SourceError extends Error { constructor(public code: string) }`
  - `findOrCreateSource(db: D1Database, source: { type: string; name: string }): Promise<string>`(回傳 `sources.id`)
  - Task 4 的 POST route 依賴它。

- [x] **Step 1: 在測試檔追加 sources describe(先失敗)**

在 `backend/tests/languageLocales.test.ts` 尾端追加(並在 import 區加 `import { SourceError, findOrCreateSource } from '../src/services/sources';`):

```ts
describe('findOrCreateSource', () => {
  it('returns the existing source id without inserting', async () => {
    let inserted = 0;
    const db = fakeD1({
      'SELECT id FROM sources WHERE type = ? AND name = ?': () => ({ id: 'existing-id' }),
      'INSERT INTO sources (id, type, name) VALUES (?, ?, ?)': () => {
        inserted += 1;
        return { success: true };
      },
    });
    await expect(findOrCreateSource(db, { type: 'url', name: '某辭典' })).resolves.toBe('existing-id');
    expect(inserted).toBe(0);
  });

  it('creates a source when missing and returns a new id', async () => {
    let inserted = 0;
    const db = fakeD1({
      'SELECT id FROM sources WHERE type = ? AND name = ?': () => null,
      'INSERT INTO sources (id, type, name) VALUES (?, ?, ?)': () => {
        inserted += 1;
        return { success: true };
      },
    });
    const id = await findOrCreateSource(db, { type: 'url', name: '某辭典' });
    expect(id).toBeTruthy();
    expect(inserted).toBe(1);
  });

  it('rejects unknown type and empty name with INVALID_SOURCE', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => findOrCreateSource(db, { type: 'wiki', name: 'x' }))).toBe('INVALID_SOURCE');
    expect(await captureAsyncCode(() => findOrCreateSource(db, { type: 'url', name: '   ' }))).toBe('INVALID_SOURCE');
  });
});
```

`captureAsyncCode` 的回傳型別需放寬(它現在回 `Promise<string>`,但 `findOrCreateSource` 回 `Promise<string>`,catch 抓到 `SourceError` 也有 `.code`)。把 helper 改成:

```ts
async function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  try {
    await fn();
  } catch (error) {
    return String((error as { code?: string }).code ?? '');
  }
  return '';
}
```

- [x] **Step 2: 跑測試確認失敗**

```bash
cd backend && npx vitest run tests/languageLocales.test.ts
```

Expected: FAIL(`Cannot find module '../src/services/sources'`)。

- [x] **Step 3: 建立 `backend/src/services/sources.ts`**

```ts
import type { D1Database } from '@cloudflare/workers-types';
import type { SourceType } from '../types/language';

const SOURCE_TYPES: readonly SourceType[] = ['publication', 'url', 'system'];

export class SourceError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'SourceError';
  }
}

export async function findOrCreateSource(
  db: D1Database,
  source: { type: string; name: string },
): Promise<string> {
  const type = source.type;
  if (!SOURCE_TYPES.includes(type as SourceType)) throw new SourceError('INVALID_SOURCE');
  const name = source.name.trim();
  if (!name) throw new SourceError('INVALID_SOURCE');
  const existing = await db
    .prepare('SELECT id FROM sources WHERE type = ? AND name = ?')
    .bind(type, name)
    .first<{ id: string }>();
  if (existing) return existing.id;
  const id = crypto.randomUUID();
  await db
    .prepare('INSERT INTO sources (id, type, name) VALUES (?, ?, ?)')
    .bind(id, type, name)
    .run();
  return id;
}
```

- [x] **Step 4: 跑測試確認通過**

```bash
cd backend && npx vitest run tests/languageLocales.test.ts
```

Expected: 11 tests PASS(8 + sources 3)。

- [x] **Step 5: Commit**

```bash
git add backend/src/services/sources.ts backend/tests/languageLocales.test.ts
git commit -m "feat(api): add two-layer source registry service"
```

---

## Task 4: `/language-locales` 三條 route 與整合測試

`POST /`(需認證,建置 locale)、`GET /`(過濾 + 分頁)、`GET /:code`(詳情 + region fallback coordinate)。Route 只負責組合,locale code 一律交給 service。

**Files:**
- Create: `backend/src/routes/languageLocales.ts`
- Modify: `backend/src/routes/index.ts`
- Create: `backend/tests/languageLocalesIntegration.test.ts`

**Interfaces:**
- Consumes: Task 1 的 seed(`eng-Latn-US` 等)、Task 2 的 `buildLanguageLocaleCode`/`assertReferenceCodesExist`/`parseLanguageLocaleCode`/`LanguageLocaleError`、Task 3 的 `findOrCreateSource`/`SourceError`、Plan 1 的 `paginated`/`badRequest`/`conflict`/`created`/`notFound`/`success`/`internalError`、`requireAuth` middleware。
- Produces: `GET /api/v2/language-locales`(分頁列表)、`GET /api/v2/language-locales/:code`(詳情,含 `coordinate_source`)、`POST /api/v2/language-locales`(201/409/400/401)。回應欄位含 `code`、`lang_code`、`script_code`、`region_code`、`place_path`、`name`、`name_en`、`latitude`、`longitude`、`source_id`、`source_ref`、`created_by`、`created_at`。

- [x] **Step 1: 寫整合測試(先失敗)**

Create `backend/tests/languageLocalesIntegration.test.ts`:

```ts
import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({
      username: `tester-${unique}`,
      email: `${unique}@example.com`,
      password: 'pass1234',
    }),
  });
  const body = (await response.json()) as { data: { token: string } };
  return body.data.token;
}

describe('language locales API', () => {
  it('lists seeded locales paginated', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales?limit=2`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      success: boolean;
      data: { items: Array<{ code: string }>; total: number; limit: number; skip: number; hasMore: boolean };
    };
    expect(body.success).toBe(true);
    expect(body.data.items.length).toBeLessThanOrEqual(2);
    expect(body.data.total).toBeGreaterThanOrEqual(3);
  });

  it('filters by lang_code', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales?lang_code=cmn`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { items: Array<{ code: string }> } };
    expect(body.data.items.map((item) => item.code).sort()).toEqual(['cmn-Hans-CN', 'cmn-Hant-TW']);
  });

  it('returns a seeded locale with region fallback coordinate', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales/eng-Latn-US`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: { code: string; name_en: string; coordinate_source: string | null; latitude: number | null };
    };
    expect(body.data.code).toBe('eng-Latn-US');
    expect(body.data.name_en).toBe('English (US)');
    expect(body.data.coordinate_source).toBe('region');
    expect(typeof body.data.latitude).toBe('number');
  });

  it('rejects a malformed code', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales/eng-Latn`);
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });

  it('returns 404 for a valid-but-missing locale', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales/zzz-Zzz-ZZ`);
    expect(res.status).toBe(404);
  });

  it('requires auth to create a locale', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ lang_code: 'nan', script_code: 'Hant', region_code: 'TW', name: '閩南語', name_en: 'Southern Min' }),
    });
    expect(res.status).toBe(401);
  });

  it('creates a locale with place segments and source', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const res = await fetch(`${BASE_URL}/api/v2/language-locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({
        lang_code: 'nan',
        script_code: 'Hant',
        region_code: 'CN',
        place_segments: ['Quanzhou', `Nanan${unique}`],
        name: '閩南語',
        name_en: `Quanzhou Southern Min ${unique}`,
        source: { type: 'url', name: 'Test Dictionary', ref: `https://example.test/${unique}` },
      }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as {
      data: { code: string; source_id: string | null; source_ref: string | null };
    };
    expect(body.data.code).toBe(`nan-Hant-CN_Quanzhou_Nanan${unique}`);
    expect(body.data.source_id).toBeTruthy();
    expect(body.data.source_ref).toBe(`https://example.test/${unique}`);
  });

  it('returns 409 for a duplicate locale', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/language-locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'eng', script_code: 'Latn', region_code: 'US', name: 'English (US)', name_en: 'English (US)' }),
    });
    expect(res.status).toBe(409);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('LANGUAGE_LOCALE_EXISTS');
  });

  it('rejects a lang code that is not in the registry', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/language-locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'zzz', script_code: 'Latn', region_code: 'US', name: 'Nope', name_en: 'Nope' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANG_CODE');
  });

  it('rejects a malformed place segment', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/language-locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', script_code: 'Hant', region_code: 'TW', place_segments: ['lowercase'], name: 'x', name_en: 'y' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_PLACE_SEGMENT');
  });

  it('searches locales by name', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/language-locales?q=Taiwan`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { items: Array<{ code: string }> } };
    expect(body.data.items.some((item) => item.code === 'cmn-Hant-TW')).toBe(true);
  });
});
```

- [x] **Step 2: 確保 worker 在 8788 且資料已 rebuild,跑測試確認失敗**

若 8788 沒有 worker,從 `backend/` 背景啟動(不要用 `./dev.sh`):

```bash
nohup node_modules/.bin/wrangler dev --config /Users/lim/Documents/Code/tsunhua/langmap/backend/wrangler.jsonc --persist-to /Users/lim/Documents/Code/tsunhua/langmap/backend/.wrangler/state --port 8788 > /tmp/langmap-worker-8788.log 2>&1 & disown
```

等待 `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8788/api/v2/auth/health` 回 `200`(約 10 秒)。

```bash
cd backend && npx vitest run tests/languageLocalesIntegration.test.ts
```

Expected: 全 FAIL(404,route 尚未掛上)。確認失敗後才繼續。

- [x] **Step 3: 建立 `backend/src/routes/languageLocales.ts`**

```ts
import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import {
  badRequest,
  conflict,
  created,
  internalError,
  notFound,
  paginated,
  success,
} from '../utils/response';
import {
  LanguageLocaleError,
  assertReferenceCodesExist,
  buildLanguageLocaleCode,
  escapeLike,
  parseLanguageLocaleCode,
  parseReferenceQuery,
} from '../services/languageIdentity';
import { SourceError, findOrCreateSource } from '../services/sources';
import type { LanguageLocaleRow } from '../types/language';
import type { Bindings, Variables } from '../types';

const LOCALE_COLUMNS = `code, lang_code, script_code, region_code, place_path, name, name_en, latitude, longitude, source_id, source_ref, created_by, created_at`;

const languageLocales = new Hono<{ Bindings: Bindings; Variables: Variables }>();

languageLocales.post('/', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const langCode = typeof body?.lang_code === 'string' ? body.lang_code.trim() : '';
    const scriptCode = typeof body?.script_code === 'string' ? body.script_code.trim() : '';
    const regionCode = typeof body?.region_code === 'string' ? body.region_code.trim() : '';
    const placeSegments = Array.isArray(body?.place_segments)
      ? body.place_segments.filter((segment: unknown): segment is string => typeof segment === 'string')
      : [];
    const name = typeof body?.name === 'string' ? body.name.trim() : '';
    const nameEn = typeof body?.name_en === 'string' ? body.name_en.trim() : '';
    const latitude = typeof body?.latitude === 'number' && Number.isFinite(body.latitude) ? body.latitude : null;
    const longitude = typeof body?.longitude === 'number' && Number.isFinite(body.longitude) ? body.longitude : null;

    if (!langCode || !scriptCode || !regionCode || !name || !nameEn) {
      return badRequest(c, 'VALIDATION_FAILED', 'lang_code, script_code, region_code, name and name_en are required');
    }
    if ((latitude === null) !== (longitude === null)) {
      return badRequest(c, 'VALIDATION_FAILED', 'latitude and longitude must be provided together');
    }

    let code: string;
    try {
      code = buildLanguageLocaleCode({ lang_code: langCode, script_code: scriptCode, region_code: regionCode, place_segments: placeSegments });
      await assertReferenceCodesExist(c.env.DB, langCode.toLowerCase(), scriptCode, regionCode);
    } catch (error) {
      if (error instanceof LanguageLocaleError) return badRequest(c, error.code, error.code);
      throw error;
    }

    let sourceId: string | null = null;
    let sourceRef: string | null = null;
    if (body?.source != null) {
      const source = body.source;
      if (typeof source !== 'object' || source === null || typeof source.type !== 'string' || typeof source.name !== 'string') {
        return badRequest(c, 'INVALID_SOURCE', 'source requires type and name');
      }
      if (source.ref != null && typeof source.ref !== 'string') {
        return badRequest(c, 'INVALID_SOURCE', 'source ref must be a string');
      }
      try {
        sourceId = await findOrCreateSource(c.env.DB, { type: source.type, name: source.name });
      } catch (error) {
        if (error instanceof SourceError) return badRequest(c, error.code, error.code);
        throw error;
      }
      sourceRef = typeof source.ref === 'string' && source.ref.trim() ? source.ref.trim() : null;
    }

    const placePath = placeSegments.join('_');
    const existing = await c.env.DB
      .prepare('SELECT code FROM language_locales WHERE lang_code = ? AND script_code = ? AND region_code = ? AND place_path = ?')
      .bind(langCode.toLowerCase(), scriptCode, regionCode, placePath)
      .first<{ code: string }>();
    if (existing) {
      return conflict(c, 'LANGUAGE_LOCALE_EXISTS', `Language locale ${existing.code} already exists`);
    }

    try {
      await c.env.DB.prepare(
        `INSERT INTO language_locales (code, lang_code, script_code, region_code, place_path, name, name_en, latitude, longitude, source_id, source_ref, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
      )
        .bind(code, langCode.toLowerCase(), scriptCode, regionCode, placePath, name, nameEn, latitude, longitude, sourceId, sourceRef, user?.id ?? null)
        .run();
    } catch (error) {
      if (String((error as { message?: string })?.message ?? '').includes('UNIQUE constraint failed')) {
        return conflict(c, 'LANGUAGE_LOCALE_EXISTS', `Language locale ${code} already exists`);
      }
      throw error;
    }

    const row = await c.env.DB
      .prepare(`SELECT ${LOCALE_COLUMNS} FROM language_locales WHERE code = ?`)
      .bind(code)
      .first<LanguageLocaleRow>();
    return created(c, row, 'Language locale created');
  } catch (error) {
    console.error('Create language locale error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create language locale');
  }
});

languageLocales.get('/', async (c) => {
  const q = c.req.query('q') ?? '';
  const langCode = (c.req.query('lang_code') ?? '').toLowerCase();
  const scriptCode = c.req.query('script_code') ?? '';
  const regionCode = (c.req.query('region_code') ?? '').toUpperCase();
  const query = parseReferenceQuery({
    q,
    limit: c.req.query('limit'),
    offset: c.req.query('skip') ?? c.req.query('offset'),
  });

  const conditions: string[] = [];
  const params: (string | number)[] = [];
  if (langCode) {
    conditions.push('lang_code = ?');
    params.push(langCode);
  }
  if (scriptCode) {
    conditions.push('script_code = ?');
    params.push(scriptCode);
  }
  if (regionCode) {
    conditions.push('region_code = ?');
    params.push(regionCode);
  }
  if (query.q) {
    const escaped = escapeLike(query.q);
    conditions.push("(code LIKE ? ESCAPE '\\' OR name LIKE ? ESCAPE '\\' OR name_en LIKE ? ESCAPE '\\')");
    params.push(`%${escaped}%`, `%${escaped}%`, `%${escaped}%`);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const countRow = await c.env.DB
    .prepare(`SELECT COUNT(*) AS total FROM language_locales ${where}`)
    .bind(...params)
    .first<{ total: number }>();
  const { results } = await c.env.DB
    .prepare(`SELECT ${LOCALE_COLUMNS} FROM language_locales ${where} ORDER BY code ASC LIMIT ? OFFSET ?`)
    .bind(...params, query.limit, query.offset)
    .all();
  return paginated(c, results as LanguageLocaleRow[], countRow?.total ?? 0, query.offset, query.limit);
});

languageLocales.get('/:code', async (c) => {
  const code = c.req.param('code');
  if (!parseLanguageLocaleCode(code)) {
    return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE', 'Malformed language locale code');
  }
  const row = await c.env.DB
    .prepare(`SELECT ${LOCALE_COLUMNS} FROM language_locales WHERE code = ?`)
    .bind(code)
    .first<LanguageLocaleRow>();
  if (!row) return notFound(c, 'Language locale');

  let coordinate_source: 'locale' | 'region' | null = null;
  let latitude = row.latitude;
  let longitude = row.longitude;
  if (latitude === null || longitude === null) {
    const region = await c.env.DB
      .prepare('SELECT latitude, longitude FROM regions WHERE code = ?')
      .bind(row.region_code)
      .first<{ latitude: number | null; longitude: number | null }>();
    if (region && region.latitude !== null && region.longitude !== null) {
      latitude = region.latitude;
      longitude = region.longitude;
      coordinate_source = 'region';
    }
  } else {
    coordinate_source = 'locale';
  }
  return success(c, { ...row, latitude, longitude, coordinate_source });
});

export default languageLocales;
```

- [x] **Step 4: 在 `backend/src/routes/index.ts` 註冊**

完整新內容:

```ts
import { Hono } from 'hono';
import auth from './auth';
import languageLocales from './languageLocales';
import languageRegistry from './languageRegistry';

const api = new Hono();
api.route('/auth', auth);
api.route('/language-registry', languageRegistry);
api.route('/language-locales', languageLocales);

export default api;
```

- [x] **Step 5: 等 wrangler hot-reload,重跑整合測試**

wrangler dev 會自動 reload `backend/src` 的變更;等 2–3 秒再跑:

```bash
cd backend && npx vitest run tests/languageLocalesIntegration.test.ts
```

Expected: 12 tests PASS。

- [x] **Step 6: 跑 type-check 確認無型別錯誤**

```bash
web/node_modules/.bin/tsc -p /tmp/tsconfig.langmap-backend-check.json
```

若 `/tmp/tsconfig.langmap-backend-check.json` 不存在,先建立(僅檢查 backend 檔案,不進 repo):

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "resolveJsonModule": true,
    "allowJs": false,
    "types": []
  },
  "files": [
    "/Users/lim/Documents/Code/tsunhua/langmap/backend/src/routes/index.ts",
    "/Users/lim/Documents/Code/tsunhua/langmap/backend/src/routes/languageLocales.ts",
    "/Users/lim/Documents/Code/tsunhua/langmap/backend/src/routes/languageRegistry.ts",
    "/Users/lim/Documents/Code/tsunhua/langmap/backend/src/services/languageIdentity.ts",
    "/Users/lim/Documents/Code/tsunhua/langmap/backend/src/services/sources.ts"
  ]
}
```

Expected: 只可能出現 `utils/response.ts`(status: number 的 overload)與 `types.ts`(`D1Database` global)兩處**既有**錯誤;`languageLocales.ts`/`languageIdentity.ts`/`sources.ts` 不得有新錯誤。

- [x] **Step 7: Commit**

```bash
git add backend/src/routes/languageLocales.ts backend/src/routes/index.ts backend/tests/languageLocalesIntegration.test.ts
git commit -m "feat(api): expose read-only and create language locale endpoints"
```

Commit 後 `git status --short` 應乾淨。

---

## Task 5: 全量回歸與收尾驗證

驗證整個 Plan 2 沒有破壞既有功能,並完成最終檢查。

**Files:** 無(若有修正在此提交)

- [x] **Step 1: 後端完整測試(已知既有失敗除外)**

worker 在 8788 的前提下:

```bash
cd backend && npm test
```

Expected: 所有 test file 通過,**除了** `auth.test.ts` 中 `reuses an existing expression ...`(呼叫 `/contributions/batch`,Task 1 起既有的 stale 測試,在 HEAD 上即壞,與本 plan 無關)——該失敗為已知,不回修、不改動 `auth.test.ts`。

- [x] **Step 2: scripts 測試**

從 repo root:

```bash
python3 scripts/language-reference/test_generate.py
python3 scripts/db/tests/test_local_rebuild.py
python3 scripts/db/tests/test_fingerprint.py
python3 scripts/db/tests/test_manage.py
python3 -m unittest scripts.db.tests.test_verify
python3 -m unittest scripts.db.tests.test_migrations
python3 -m unittest scripts.db.tests.test_dev_sh
```

Expected: 全部 OK。

- [x] **Step 3: 手動抽查新 API(rebuild 後)**

```bash
curl -s 'http://127.0.0.1:8788/api/v2/language-locales?limit=3' | python3 -m json.tool
curl -s 'http://127.0.0.1:8788/api/v2/language-locales/eng-Latn-US' | python3 -m json.tool
```

Expected: 列表回 3+ 筆、`total >= 3`、`hasMore` 依筆數正確;詳情回 `name_en: "English (US)"` 且 `coordinate_source: "region"`。

- [x] **Step 4: 文件與空白檢查**

```bash
git diff --check
git status --short
```

Expected: `git diff --check` 無輸出;`git status --short` 乾淨(無未提交變更)。

- [x] **Step 5: 若有修正則 Commit**

```bash
git add <修正的檔案>
git commit -m "fix(api): <簡述>"
```

若 Step 1–4 全過且無修正,此 step 跳過。

---

## Self-Review

**1. Spec coverage:**

- §7.1 grammar(`lang-[a-z]{3}`、`script-[A-Z][a-z]{3}`、`region-[A-Z]{2}`、`place_segment-[A-Z][A-Za-z]*`、`_` 分層、top-level place_path 空字串)→ Task 2(build/parse 正反例測試) + Task 1(schema `place_path NOT NULL DEFAULT ''`)。
- §7.2 `language_locales` 表(全部欄位、UNIQUE(lang,script,region,place)、座標成對 CHECK、source_ref CHECK、五條 FK)→ Task 1。
- §7.2 coordinate fallback(`coordinate_source='region'`/`'locale'`)→ Task 4 `GET /:code`。
- §7.3 `sources` 表(`type` CHECK、UNIQUE(type,name)、FK users)、兩層 source model、`(type,name)` 查找或建立、caller 不傳 `source_id`、source_ref 不脫離 source_id → Task 1(schema) + Task 3(service) + Task 4(POST 組合)。
- §13.1 `GET/POST /language-locales` 與 `GET /:code`;POST 接受結構化欄位不接受 code;`source` 選填含 type/name/ref;省略時 `created_by` 由認證帶入 → Task 4。
- §14 穩定錯誤碼:`INVALID_LANG_CODE`/`INVALID_SCRIPT_CODE`/`INVALID_REGION_CODE`(Task 2+4)、`INVALID_PLACE_SEGMENT`(Task 2+4)、`INVALID_LANGUAGE_LOCALE_CODE`(Task 4)、`LANGUAGE_LOCALE_EXISTS`(Task 4)、`INVALID_SOURCE`(Task 3+4);constraint error 映射而非暴露 → Task 4 POST 的 UNIQUE catch。
- §4.4 canonical builder 只在 service、route 不拼接 → Task 2 + Task 4 結構。
- §4.11 穩定排序(`code ASC`)與 limit clamp `[1,50]` → Task 4 列表(經 `parseReferenceQuery`)。
- §16.6 的 system locale seed(`eng-Latn-US`/`cmn-Hant-TW`/`cmn-Hans-CN`)→ Task 1(seed 建表時一併寫入;`scripts/i18n` catalog 遷移**不在**本 plan,留給後續 plan)。
- §17.3 fresh D1 rebuild 成功 + schema.sql/migration/fingerprint 一致 → Task 1 rebuild + Task 5。
- §17.1 grammar 成功/失敗、代表座標成對與 coordinate source、sources 查找或建立/兩層驗證/空名拒絕 → Task 2/3 單元 + Task 4 整合。

**未覆蓋(留給後續 plan):** `language_locales` 的 `name`/`name_en` 更新 API(本 plan 只有建立與讀取,spec 未定義更新 route);Expression/readings/attestations(§8、§9);mapping/split(§10);preferences(§11、§13.3);UI localization(§12、§13.4);前端(§15);`scripts/i18n` catalog 遷移(§16.6)。

**2. Placeholder scan:** 每個 step 都有完整程式碼與可執行命令,無 TBD/「implement later」。integration test 的 BASE_URL 沿用既有慣例。

**3. Type consistency:** `buildLanguageLocaleCode`/`parseLanguageLocaleCode`/`assertReferenceCodesExist`/`LanguageLocaleError` 在 Task 2 定義並被 Task 4 import,參數與回傳型別一致;`findOrCreateSource`/`SourceError` 在 Task 3 定義並被 Task 4 import;`LanguageLocaleRow` 在 Task 1 的 schema 欄位順序與 Task 4 `LOCALE_COLUMNS` 字串一致;`paginated(c, items, total, skip, limit)` 的呼叫順序與 Plan 1 helper 一致(`skip=query.offset`,`limit=query.limit`)。seed 的 `source_ref`(`seed:system-seed:1`)與 §7.3 的 `seed:<system_id>:<version>` 格式一致。
