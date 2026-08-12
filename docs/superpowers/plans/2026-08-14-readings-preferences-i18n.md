# Expression Readings + User Preferences + i18n Catalog Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Plan 1-4 之上合併實作三個獨立的小領域:Expression readings(§9.2、§13.2)、User preferences(§11、§13.3)、以及 `scripts/i18n` catalog 的 Language Locale code 遷移(§16.6)。

**Architecture:** 三個領域互相獨立,共用一次 schema migration(migration 0005: `expression_readings` + `user_preferences`)與一次回歸驗證。Readings 依附 Expression domain(需呼叫 `createLocaleAttestation` 確保佐證存在);Preferences 依附 `language_locales` 表;兩者均只需 Plan 1-3 的基礎表。i18n catalog 遷移純屬 scripts 層,不涉及後端程式碼。

**Tech Stack:** Hono 4 + TypeScript + Cloudflare Workers + D1(SQLite);Zod 4(偏好驗證);Vitest;Python 3(`scripts/i18n`)。

## Global Constraints

以下為各 task 隱含必須遵守的規則,不再逐 task 重複:

### Readings(§9.2)

- `expression_readings` 表欄位逐字抄自 spec §9.2:`id TEXT PRIMARY KEY`、`expression_id`／`language_locale_code TEXT NOT NULL`、`scheme TEXT NOT NULL`、`value TEXT NOT NULL`、`source_id`／`source_ref`(nullable,`source_ref` CHECK)、`created_by`、`created_at`;`UNIQUE(expression_id, language_locale_code, scheme, value, source_id, source_ref)`;四條 FK。
- Scheme grammar:`^[a-z][a-z0-9-]*(?::[a-z][a-z0-9-]*)?$`(§9.2)。有效例:`ipa`、`pinyin`、`wade-giles`、`phonics:synthetic`。
- 建立 reading 時**必須在同一原子操作**建立 `source_id`／`source_ref` 完全相同的 locale attestation(皆為 NULL 時亦同);重複資料回傳既有記錄(§9.2)。實作方式:先呼叫 `createLocaleAttestation`(Plan 3,冪等),再建立 reading。
- 穩定錯誤碼:`INVALID_READING_SCHEME`、`INVALID_LANGUAGE_LOCALE_CODE`、`EXPRESSION_NOT_FOUND`、`INVALID_SOURCE`(§14)。

### Preferences(§11)

- `user_preferences` 表:`(user_id, preference_key)` PK、`value_json TEXT NOT NULL`、`updated_at`、FK `user_id → users(id)` with `ON DELETE CASCADE`(§11)。
- 後端以 key registry 維護允許的 preference 及 Zod schema(§11)。首個 key:`language.locales`,值 `{"primary": "...", "secondary": "..."}`。
- `primary` 必填;`secondary` 可省略但不能是 `null`,且不能與 primary 相同;兩者必須引用已存在的 Language Locale(§11)。
- 匿名偏好保存於前端 localStorage,不寫入 D1(§11)。
- 穩定錯誤碼:`UNKNOWN_PREFERENCE_KEY`、`INVALID_LANGUAGE_PREFERENCE`(§14)。
- Routes:`GET /preferences`(回所有偏好)、`PUT /preferences/language.locales`(驗證 + upsert);未知 key 回 `UNKNOWN_PREFERENCE_KEY`(§13.3)。

### i18n Catalog(§16.6)

- 保留 `scripts/i18n/`,將 locale code 從舊格式(`en-Latn`、`cmn-Hant`、`cmn-Hans`、`es-ES`、`ja-JP`)改成完整 Language Locale(`eng-Latn-US`、`cmn-Hant-TW`、`cmn-Hans-CN`、`spa-Latn-ES`、`jpn-Jpan-JP`)。
- 更新 `SOURCE_LANGUAGE_CODE`、`validate_locale_code` regex、JSON 檔名、測試。
- artifact SQL(`artifacts/system-ui/system-ui.sql`)的完整重寫依賴 Plan 7(UI localization 新表),本 plan 只更新 locale code、不重生成 SQL artifact。

### 通用

- API prefix 一律 `/api/v2`;回應一律 `{ success, data?, error?, message? }`;列表用 `paginated(c, items, total, skip, limit)`(AGENTS.md、§13)。
- 所有查詢必須穩定排序並有數量上限(§4.11)。
- schema 變更必須同時新增 migration 並更新 `schema.sql`,並同步 migration-lock(AGENTS.md)。
- migration 使用 `IF NOT EXISTS`、`schema.sql` 不使用(repo 既有慣例)。
- 不新增 `any`;新程式碼不加註解。不修改 `web/`、`apple/`。
- 整合測試依賴 127.0.0.1:8788 的 worker 與已 rebuild 的本地 D1。單檔測試用 `npx vitest run tests/<file>.test.ts`。
- `backend/node_modules/.bin/wrangler` 是本地 wrangler binary;不要用 `npx wrangler`。
- 已知既有失敗:`auth.test.ts`(`reuses an existing expression...`)、`expressionsIntegration.test.ts`(locale seed 不匹配)——不修。

---

## File Structure

| 檔案 | 責任 | 動作 |
|---|---|---|
| `backend/migrations/0005_readings_preferences.sql` | `expression_readings` + `user_preferences` DDL(IF NOT EXISTS) | Create |
| `backend/schema.sql` | 與 0005 等價的本地全量 schema | Modify |
| `backend/tests/schemaContract.test.ts` | 斷言新表欄位/CHECK/FK | Modify |
| `scripts/db/migration-lock.json` | 記錄 0005(sync 更新) | Modify |
| `backend/src/services/readings.ts` | `ReadingError`、`validateReadingScheme`、`createReading` | Create |
| `backend/src/routes/expressions.ts` | 新增 `POST /:id/readings` | Modify |
| `backend/src/services/preferences.ts` | `PreferenceError`、`getPreferences`、`putPreference`、key registry + Zod | Create |
| `backend/src/routes/preferences.ts` | `GET /`、`PUT /language.locales` | Create |
| `backend/src/routes/index.ts` | 註冊 `preferences` route | Modify |
| `backend/tests/readings.test.ts` | readings service 單元測試 | Create |
| `backend/tests/readingsIntegration.test.ts` | readings API 整合測試 | Create |
| `backend/tests/preferences.test.ts` | preferences service 單元測試 | Create |
| `backend/tests/preferencesIntegration.test.ts` | preferences API 整合測試 | Create |
| `scripts/i18n/generate-i18n-sql.py` | `SOURCE_LANGUAGE_CODE`、`validate_locale_code` | Modify |
| `scripts/i18n/cmn-Hans.json` → `cmn-Hans-CN.json` | 改名 | Rename |
| `scripts/i18n/cmn-Hant.json` → `cmn-Hant-TW.json` | 改名 | Rename |
| `scripts/i18n/es-ES.json` → `spa-Latn-ES.json` | 改名 | Rename |
| `scripts/i18n/ja-JP.json` → `jpn-Jpan-JP.json` | 改名 | Rename |
| `scripts/i18n/test_generate_bundle.py` | 更新 locale code 引用 | Modify |

---

## Task 1: Schema —— `expression_readings` + `user_preferences`

把 §9.2／§11 的兩張表寫進 migration 0005 與 `schema.sql`,更新契約測試與 migration-lock,並重建本地 D1。

**Files:**
- Create: `backend/migrations/0005_readings_preferences.sql`
- Modify: `backend/schema.sql`
- Modify: `backend/tests/schemaContract.test.ts`
- Modify: `scripts/db/migration-lock.json`

- [ ] **Step 1: 建立 migration 0005**

Create `backend/migrations/0005_readings_preferences.sql`:

```sql
-- Expression readings + user preferences (spec §9.2, §11).

CREATE TABLE IF NOT EXISTS expression_readings (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  scheme TEXT NOT NULL,
  value TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (expression_id, language_locale_code, scheme, value, source_id, source_ref),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS user_preferences (
  user_id INTEGER NOT NULL,
  preference_key TEXT NOT NULL,
  value_json TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, preference_key),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

- [ ] **Step 2: 更新 `backend/schema.sql`**

在檔頭 DROP 區塊,於 `DROP TABLE IF EXISTS expression_locale_attestations;` 之前加入(FK 相依:readings → expressions/locales/sources;preferences → users):

```sql
DROP TABLE IF EXISTS expression_readings;
DROP TABLE IF EXISTS user_preferences;
```

在檔尾(現有 `expression_split_moves` 表之後)新增(無 `IF NOT EXISTS`):

```sql

-- Expression readings + user preferences (spec §9.2, §11).

CREATE TABLE expression_readings (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  scheme TEXT NOT NULL,
  value TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (expression_id, language_locale_code, scheme, value, source_id, source_ref),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE user_preferences (
  user_id INTEGER NOT NULL,
  preference_key TEXT NOT NULL,
  value_json TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, preference_key),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

- [ ] **Step 3: 更新 `backend/tests/schemaContract.test.ts`**

在既有 describe 內、`does not contain obsolete identity tables` 之前新增兩個 it:

```ts
  it('defines expression_readings with scheme, value and provenance uniqueness', () => {
    expect(schema).toMatch(/CREATE TABLE expression_readings[\s\S]*?scheme TEXT NOT NULL[\s\S]*?value TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expression_readings[\s\S]*?UNIQUE \(expression_id, language_locale_code, scheme, value, source_id, source_ref\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_readings[\s\S]*?CHECK \(source_ref IS NULL OR source_id IS NOT NULL\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_readings[\s\S]*?FOREIGN KEY \(expression_id\) REFERENCES expressions\(id\)[\s\S]*?FOREIGN KEY \(language_locale_code\) REFERENCES language_locales\(code\)/s);
  });

  it('defines user_preferences with composite key and cascade delete', () => {
    expect(schema).toMatch(/CREATE TABLE user_preferences[\s\S]*?PRIMARY KEY \(user_id, preference_key\)/s);
    expect(schema).toMatch(/CREATE TABLE user_preferences[\s\S]*?FOREIGN KEY \(user_id\) REFERENCES users\(id\) ON DELETE CASCADE/s);
  });
```

- [ ] **Step 4: 同步 migration-lock**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && python3 - <<'EOF'
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

Expected: 5 筆。再跑一次 `update=False` 確認無錯。

- [ ] **Step 5: 跑 schemaContract 測試**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/schemaContract.test.ts
```

Expected: 全部 PASS(既有 11 + 新增 2 = 13)。

- [ ] **Step 6: 重建本地 D1**

確保 8788 沒有 worker(`kill $(pgrep -f "wrangler dev")` if needed)。

```bash
cd /Users/share.lim/Documents/GitHub/langmap && python3 scripts/db/manage.py local rebuild
```

- [ ] **Step 7: 跑 scripts 驗證**

```bash
python3 -m unittest scripts.db.tests.test_verify
python3 scripts/db/tests/test_local_rebuild.py
```

- [ ] **Step 8: Commit**

```bash
git add backend/migrations/0005_readings_preferences.sql backend/schema.sql backend/tests/schemaContract.test.ts scripts/db/migration-lock.json
git commit -m "feat(db): add expression readings and user preferences tables"
```

---

## Task 2: Readings service + route(`POST /:id/readings`)

建立 reading 時先確保對應的 locale attestation 存在(呼叫 Plan 3 的 `createLocaleAttestation`),再驗證 scheme grammar 並 find-or-create reading。

**Files:**
- Create: `backend/src/services/readings.ts`
- Modify: `backend/src/routes/expressions.ts`(新增 `POST /:id/readings`)
- Create: `backend/tests/readings.test.ts`
- Create: `backend/tests/readingsIntegration.test.ts`

**Interfaces:**
- Consumes: `D1Database`;Plan 3 的 `createLocaleAttestation`／`ExpressionError` from `services/expressions`;Plan 2 的 `findOrCreateSource`／`SourceError` from `services/sources`。
- Produces:
  - `class ReadingError extends Error { constructor(public code: string) }`
  - `validateReadingScheme(scheme: string): boolean`
  - `createReading(db, input: { expression_id: string; language_locale_code: string; scheme: string; value: string; source?: { type: string; name: string; ref?: string }; created_by: number }): Promise<{ reading: ReadingRow; created: boolean }>`
  - Task 4 的 route 依賴 `createReading`。

- [ ] **Step 1: 寫失敗的單元測試**

Create `backend/tests/readings.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { ReadingError, createReading, validateReadingScheme } from '../src/services/readings';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const prepare = (sql: string) => {
    const handler = handlers[sql];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          async first<T>() { return (await run()) as T; },
          async run() { return handler ? await handler() : { success: true }; },
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

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(() => '', (e: unknown) => String((e as { code?: string }).code ?? ''));
}

describe('validateReadingScheme', () => {
  it('accepts valid schemes', () => {
    expect(validateReadingScheme('ipa')).toBe(true);
    expect(validateReadingScheme('pinyin')).toBe(true);
    expect(validateReadingScheme('wade-giles')).toBe(true);
    expect(validateReadingScheme('phonics:synthetic')).toBe(true);
  });

  it('rejects invalid schemes', () => {
    expect(validateReadingScheme('')).toBe(false);
    expect(validateReadingScheme('IPA')).toBe(false);
    expect(validateReadingScheme('a b')).toBe(false);
    expect(validateReadingScheme('1abc')).toBe(false);
  });
});

describe('createReading', () => {
  it('creates a reading after ensuring attestation exists', async () => {
    const mockReading = {
      id: 'r1', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit', source_id: null, source_ref: null,
      created_by: 1, created_at: '2026-08-14',
    };
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS NULL AND source_ref IS NULL':
        () => null,
      'INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, NULL, NULL, ?)':
        () => ({ success: true }),
      'SELECT id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by, created_at FROM expression_readings WHERE expression_id = ? AND language_locale_code = ? AND scheme = ? AND value = ? AND source_id IS NULL AND source_ref IS NULL':
        () => null,
      'INSERT INTO expression_readings (id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, NULL, NULL, ?)':
        () => ({ success: true }),
      'SELECT id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by, created_at FROM expression_readings WHERE id = ?':
        () => mockReading,
    });
    const result = await createReading(db, {
      expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit', created_by: 1,
    });
    expect(result.created).toBe(true);
    expect(result.reading.scheme).toBe('ipa');
  });

  it('reuses an existing reading on duplicate', async () => {
    const existing = {
      id: 'r-old', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit', source_id: null, source_ref: null,
      created_by: 1, created_at: '2026-08-14',
    };
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS NULL AND source_ref IS NULL':
        () => ({ id: 'att-old' }),
      'SELECT id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by, created_at FROM expression_readings WHERE expression_id = ? AND language_locale_code = ? AND scheme = ? AND value = ? AND source_id IS NULL AND source_ref IS NULL':
        () => existing,
    });
    const result = await createReading(db, {
      expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 't͡sit', created_by: 1,
    });
    expect(result.created).toBe(false);
    expect(result.reading.id).toBe('r-old');
  });

  it('rejects an invalid scheme with INVALID_READING_SCHEME', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
    });
    expect(await captureAsyncCode(() => createReading(db, {
      expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'Invalid', value: 'x', created_by: 1,
    }))).toBe('INVALID_READING_SCHEME');
  });

  it('rejects an empty value with VALIDATION_FAILED', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
    });
    expect(await captureAsyncCode(() => createReading(db, {
      expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: '  ', created_by: 1,
    }))).toBe('VALIDATION_FAILED');
  });

  it('rejects a missing expression with EXPRESSION_NOT_FOUND', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => null,
    });
    expect(await captureAsyncCode(() => createReading(db, {
      expression_id: 'nan:missing', language_locale_code: 'nan-Hant-TW',
      scheme: 'ipa', value: 'x', created_by: 1,
    }))).toBe('EXPRESSION_NOT_FOUND');
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/readings.test.ts
```

Expected: FAIL(`Cannot find module '../src/services/readings'`)。

- [ ] **Step 3: 建立 `backend/src/services/readings.ts`**

```ts
import type { D1Database } from '@cloudflare/workers-types';

const READING_COLUMNS = `id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by, created_at`;
const EXPRESSION_COLUMNS = `id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at`;
const SCHEME_RE = /^[a-z][a-z0-9-]*(?::[a-z][a-z0-9-]*)?$/;

export class ReadingError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'ReadingError';
  }
}

export function validateReadingScheme(scheme: string): boolean {
  return SCHEME_RE.test(scheme);
}

export async function createReading(
  db: D1Database,
  input: {
    expression_id: string;
    language_locale_code: string;
    scheme: string;
    value: string;
    source?: { type: string; name: string; ref?: string };
    created_by: number;
  },
): Promise<{ reading: ReadingRow; created: boolean }> {
  const trimmedValue = input.value.trim();
  if (!trimmedValue) throw new ReadingError('VALIDATION_FAILED');
  if (!validateReadingScheme(input.scheme)) throw new ReadingError('INVALID_READING_SCHEME');

  const expression = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(input.expression_id)
    .first();
  if (!expression) throw new ReadingError('EXPRESSION_NOT_FOUND');

  const locale = await db.prepare('SELECT 1 FROM language_locales WHERE code = ?').bind(input.language_locale_code).first();
  if (!locale) throw new ReadingError('INVALID_LANGUAGE_LOCALE_CODE');

  const { createLocaleAttestation } = await import('./expressions');
  await createLocaleAttestation(db, {
    expression_id: input.expression_id,
    language_locale_code: input.language_locale_code,
    ...(input.source ? { source: input.source } : {}),
    created_by: input.created_by,
  });

  const { findOrCreateSource } = await import('./sources');
  const { SourceError } = await import('./sources');
  let sourceId: string | null = null;
  let sourceRef: string | null = null;
  if (input.source) {
    try {
      sourceId = await findOrCreateSource(db, { type: input.source.type, name: input.source.name });
    } catch (error) {
      if (error instanceof SourceError) throw new ReadingError(error.code);
      throw error;
    }
    sourceRef = typeof input.source.ref === 'string' && input.source.ref.trim() ? input.source.ref.trim() : null;
  }

  const lookup = sourceId
    ? `SELECT ${READING_COLUMNS} FROM expression_readings WHERE expression_id = ? AND language_locale_code = ? AND scheme = ? AND value = ? AND source_id = ? AND source_ref = ?`
    : `SELECT ${READING_COLUMNS} FROM expression_readings WHERE expression_id = ? AND language_locale_code = ? AND scheme = ? AND value = ? AND source_id IS NULL AND source_ref IS NULL`;
  const bindArgs = sourceId
    ? [input.expression_id, input.language_locale_code, input.scheme, trimmedValue, sourceId, sourceRef]
    : [input.expression_id, input.language_locale_code, input.scheme, trimmedValue];
  const existing = await db.prepare(lookup).bind(...bindArgs).first<ReadingRow>();
  if (existing) return { reading: existing, created: false };

  const id = crypto.randomUUID();
  await db
    .prepare(
      sourceId
        ? `INSERT INTO expression_readings (id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
        : `INSERT INTO expression_readings (id, expression_id, language_locale_code, scheme, value, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, NULL, NULL, ?)`,
    )
    .bind(
      id, input.expression_id, input.language_locale_code, input.scheme, trimmedValue,
      ...(sourceId ? [sourceId, sourceRef, input.created_by] : [input.created_by]),
    )
    .run();

  const reading = await db
    .prepare(`SELECT ${READING_COLUMNS} FROM expression_readings WHERE id = ?`)
    .bind(id)
    .first<ReadingRow>();
  return { reading: reading as ReadingRow, created: true };
}
```

Note: `ReadingRow` type — add to `backend/src/types/expression.ts`:

```ts
export interface ReadingRow {
  id: string;
  expression_id: string;
  language_locale_code: string;
  scheme: string;
  value: string;
  source_id: string | null;
  source_ref: string | null;
  created_by: number | null;
  created_at: string;
}
```

- [ ] **Step 4: 跑單元測試確認通過**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/readings.test.ts
```

Expected: 全部 PASS(7)。若 fake D1 SQL key 不匹配,以實作為準調整測試。

- [ ] **Step 5: 在 `backend/src/routes/expressions.ts` 新增 `POST /:id/readings`**

READ the current file first. Add import:
```ts
import { ReadingError, createReading } from '../services/readings';
```

Add handler (using the same Hono instance variable name as existing handlers):

```ts
languageLocales.post('/:id/readings', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const languageLocaleCode = typeof body?.language_locale_code === 'string' ? body.language_locale_code.trim() : '';
    const scheme = typeof body?.scheme === 'string' ? body.scheme.trim() : '';
    const value = typeof body?.value === 'string' ? body.value : '';
    if (!languageLocaleCode || !scheme || !value) {
      return badRequest(c, 'VALIDATION_FAILED', 'language_locale_code, scheme and value are required');
    }
    let source: { type: string; name: string; ref?: string } | undefined;
    if (body?.source != null) {
      const s = body.source;
      if (typeof s !== 'object' || s === null || typeof s.type !== 'string' || typeof s.name !== 'string') {
        return badRequest(c, 'INVALID_SOURCE', 'source requires type and name');
      }
      source = { type: s.type, name: s.name };
      if (typeof s.ref === 'string') source.ref = s.ref;
    }
    try {
      const result = await createReading(c.env.DB, {
        expression_id: id,
        language_locale_code: languageLocaleCode,
        scheme,
        value,
        ...(source ? { source } : {}),
        created_by: user?.id ?? 0,
      });
      return result.created ? created(c, result, 'Reading created') : success(c, result, 'Reading already exists');
    } catch (error) {
      if (error instanceof ReadingError) {
        if (error.code === 'EXPRESSION_NOT_FOUND') return c.json({ success: false, error: error.code, message: 'Expression not found' }, 404);
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Create reading error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create reading');
  }
});
```

- [ ] **Step 6: 寫整合測試並啟動 worker 測試**

Create `backend/tests/readingsIntegration.test.ts`:

```ts
import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: `tester-${unique}`, email: `${unique}@example.com`, password: 'pass1234' }),
  });
  const body = (await response.json()) as { data: { token: string } };
  return body.data.token;
}

async function createExpression(token: string, text: string, lang = 'nan'): Promise<string> {
  const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
    body: JSON.stringify({ lang_code: lang, text }),
  });
  const body = (await res.json()) as { data: { expression: { id: string } } };
  return body.data.expression.id;
}

describe('readings API', () => {
  it('creates a reading for a seeded locale', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const id = await createExpression(token, `讀音測試${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${id}/readings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW', scheme: 'pinyin', value: 't͡sit' }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { reading: { scheme: string; value: string }; created: boolean } };
    expect(body.data.created).toBe(true);
    expect(body.data.reading.scheme).toBe('pinyin');
  });

  it('reuses an existing reading on duplicate', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const id = await createExpression(token, `重複讀音${unique}`);
    const post = () =>
      fetch(`${BASE_URL}/api/v2/expressions/${id}/readings`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW', scheme: 'ipa', value: 'tsiʔ' }),
      });
    const first = await post();
    const second = await post();
    expect(first.status).toBe(201);
    expect(second.status).toBe(200);
    const firstBody = (await first.json()) as { data: { reading: { id: string }; created: boolean } };
    const secondBody = (await second.json()) as { data: { reading: { id: string }; created: boolean } };
    expect(firstBody.data.reading.id).toBe(secondBody.data.reading.id);
    expect(secondBody.data.created).toBe(false);
  });

  it('rejects an invalid scheme', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const id = await createExpression(token, `錯誤讀音${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${id}/readings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW', scheme: 'Invalid', value: 'x' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_READING_SCHEME');
  });

  it('requires auth', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions/nan:fake/readings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW', scheme: 'ipa', value: 'x' }),
    });
    expect(res.status).toBe(401);
  });
});
```

確保 worker 在 8788:

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && nohup node_modules/.bin/wrangler dev --config wrangler.jsonc --persist-to .wrangler/state --port 8788 > /tmp/langmap-worker-8788.log 2>&1 & disown
```

等 health 200 後跑:

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/readingsIntegration.test.ts
```

Expected: 4 tests PASS。

- [ ] **Step 7: Commit**

```bash
git add backend/src/services/readings.ts backend/src/types/expression.ts backend/src/routes/expressions.ts backend/tests/readings.test.ts backend/tests/readingsIntegration.test.ts
git commit -m "feat(api): add expression readings with scheme validation and attestation linkage"
```

---

## Task 3: Preferences service + routes(`GET /preferences`、`PUT /preferences/language.locales`)

Key registry + Zod schema 驗證、locale 存在性檢查、upsert。

**Files:**
- Create: `backend/src/services/preferences.ts`
- Create: `backend/src/routes/preferences.ts`
- Modify: `backend/src/routes/index.ts`
- Create: `backend/tests/preferences.test.ts`
- Create: `backend/tests/preferencesIntegration.test.ts`

**Interfaces:**
- Consumes: `D1Database`;Zod 4。
- Produces:
  - `class PreferenceError extends Error { constructor(public code: string) }`
  - `getPreferences(db, userId: number): Promise<Record<string, unknown>>`
  - `putPreference(db, userId: number, key: string, value: unknown): Promise<{ key: string; value: unknown }>`
  - `preferences.ts` route: `GET /`、`PUT /language.locales`

- [ ] **Step 1: 寫失敗的單元測試**

Create `backend/tests/preferences.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { PreferenceError, getPreferences, putPreference } from '../src/services/preferences';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const prepare = (sql: string) => {
    const handler = handlers[sql];
    return {
      bind(..._args: unknown[]) {
        const run = async () => (handler ? handler() : { results: [] });
        return {
          async first<T>() { return (await run()) as T; },
          async run() { return handler ? await handler() : { success: true }; },
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

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(() => '', (e: unknown) => String((e as { code?: string }).code ?? ''));
}

describe('getPreferences', () => {
  it('returns an empty object for a user with no preferences', async () => {
    const db = fakeD1({
      'SELECT preference_key, value_json FROM user_preferences WHERE user_id = ?': () => ({ results: [] }),
    });
    const result = await getPreferences(db, 1);
    expect(result).toEqual({});
  });

  it('returns parsed preference values', async () => {
    const db = fakeD1({
      'SELECT preference_key, value_json FROM user_preferences WHERE user_id = ?': () => ({
        results: [
          { preference_key: 'language.locales', value_json: '{"primary":"cmn-Hant-TW"}' },
        ],
      }),
    });
    const result = await getPreferences(db, 1);
    expect(result['language.locales']).toEqual({ primary: 'cmn-Hant-TW' });
  });
});

describe('putPreference', () => {
  it('upserts a valid language.locales preference', async () => {
    let inserted = false;
    const db = fakeD1({
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'INSERT INTO user_preferences (user_id, preference_key, value_json) VALUES (?, ?, ?) ON CONFLICT(user_id, preference_key) DO UPDATE SET value_json = excluded.value_json, updated_at = CURRENT_TIMESTAMP':
        () => { inserted = true; return { success: true }; },
    });
    const result = await putPreference(db, 1, 'language.locales', { primary: 'cmn-Hant-TW' });
    expect(result.key).toBe('language.locales');
    expect(result.value).toEqual({ primary: 'cmn-Hant-TW' });
    expect(inserted).toBe(true);
  });

  it('rejects an unknown key with UNKNOWN_PREFERENCE_KEY', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => putPreference(db, 1, 'unknown.key', {}))).toBe('UNKNOWN_PREFERENCE_KEY');
  });

  it('rejects when primary locale does not exist', async () => {
    const db = fakeD1({
      'SELECT 1 FROM language_locales WHERE code = ?': () => null,
    });
    expect(await captureAsyncCode(() => putPreference(db, 1, 'language.locales', { primary: 'zzz-Zzz-ZZ' }))).toBe('INVALID_LANGUAGE_PREFERENCE');
  });

  it('rejects when secondary equals primary', async () => {
    const db = fakeD1({
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
    });
    expect(await captureAsyncCode(() => putPreference(db, 1, 'language.locales', { primary: 'cmn-Hant-TW', secondary: 'cmn-Hant-TW' }))).toBe('INVALID_LANGUAGE_PREFERENCE');
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/preferences.test.ts
```

Expected: FAIL。

- [ ] **Step 3: 建立 `backend/src/services/preferences.ts`**

```ts
import { z } from 'zod';
import type { D1Database } from '@cloudflare/workers-types';

const PREFERENCE_SCHEMAS: Record<string, z.ZodType> = {
  'language.locales': z
    .object({
      primary: z.string().min(1),
      secondary: z.string().min(1).optional(),
    })
    .refine((data) => !data.secondary || data.secondary !== data.primary, {
      message: 'secondary must differ from primary',
    }),
};

export class PreferenceError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'PreferenceError';
  }
}

export async function getPreferences(
  db: D1Database,
  userId: number,
): Promise<Record<string, unknown>> {
  const { results } = await db
    .prepare('SELECT preference_key, value_json FROM user_preferences WHERE user_id = ?')
    .bind(userId)
    .all<{ preference_key: string; value_json: string }>();
  const out: Record<string, unknown> = {};
  for (const row of results) {
    try {
      out[row.preference_key] = JSON.parse(row.value_json);
    } catch {
      // skip malformed JSON
    }
  }
  return out;
}

export async function putPreference(
  db: D1Database,
  userId: number,
  key: string,
  value: unknown,
): Promise<{ key: string; value: unknown }> {
  const schema = PREFERENCE_SCHEMAS[key];
  if (!schema) throw new PreferenceError('UNKNOWN_PREFERENCE_KEY');

  const parsed = schema.safeParse(value);
  if (!parsed.success) throw new PreferenceError('INVALID_LANGUAGE_PREFERENCE');
  const validated = parsed.data as { primary: string; secondary?: string };

  if (key === 'language.locales') {
    const locales = [validated.primary, ...(validated.secondary ? [validated.secondary] : [])];
    for (const code of locales) {
      const row = await db.prepare('SELECT 1 FROM language_locales WHERE code = ?').bind(code).first();
      if (!row) throw new PreferenceError('INVALID_LANGUAGE_PREFERENCE');
    }
  }

  const json = JSON.stringify(validated);
  await db
    .prepare(
      'INSERT INTO user_preferences (user_id, preference_key, value_json) VALUES (?, ?, ?) ON CONFLICT(user_id, preference_key) DO UPDATE SET value_json = excluded.value_json, updated_at = CURRENT_TIMESTAMP',
    )
    .bind(userId, key, json)
    .run();

  return { key, value: validated };
}
```

- [ ] **Step 4: 跑單元測試確認通過**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/preferences.test.ts
```

Expected: 全部 PASS(6)。若 fake D1 SQL key 不匹配,以實作為準調整測試。

- [ ] **Step 5: 建立 route `backend/src/routes/preferences.ts`**

```ts
import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { badRequest, internalError, success, unauthorized } from '../utils/response';
import { PreferenceError, getPreferences, putPreference } from '../services/preferences';
import type { Bindings, Variables } from '../types';

const preferences = new Hono<{ Bindings: Bindings; Variables: Variables }>();

preferences.get('/', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (!user) return unauthorized(c);
    const result = await getPreferences(c.env.DB, user.id);
    return success(c, result);
  } catch (error) {
    console.error('Get preferences error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to get preferences');
  }
});

preferences.put('/:key', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (!user) return unauthorized(c);
    const key = c.req.param('key') ?? '';
    const body = await c.req.json().catch(() => ({}));
    try {
      const result = await putPreference(c.env.DB, user.id, key, body);
      return success(c, result, 'Preference saved');
    } catch (error) {
      if (error instanceof PreferenceError) return badRequest(c, error.code, error.code);
      throw error;
    }
  } catch (error) {
    console.error('Put preference error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to save preference');
  }
});

export default preferences;
```

Note: Hono's `:key` path param captures the full segment including dots, so `PUT /preferences/language.locales` arrives as `key = 'language.locales'` directly — no conversion needed.

- [ ] **Step 6: 在 `backend/src/routes/index.ts` 註冊**

READ the current file. Add:

```ts
import preferences from './preferences';
```

And register:
```ts
api.route('/preferences', preferences);
```

- [ ] **Step 7: 寫整合測試並跑**

Create `backend/tests/preferencesIntegration.test.ts`:

```ts
import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: `tester-${unique}`, email: `${unique}@example.com`, password: 'pass1234' }),
  });
  const body = (await response.json()) as { data: { token: string } };
  return body.data.token;
}

describe('preferences API', () => {
  it('returns empty preferences for a new user', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/preferences`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: Record<string, unknown> };
    expect(body.data).toEqual({});
  });

  it('saves and retrieves a language.locales preference', async () => {
    const token = await registerToken();
    const putRes = await fetch(`${BASE_URL}/api/v2/preferences/language.locales`, {
      method: 'PUT',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ primary: 'cmn-Hant-TW', secondary: 'eng-Latn-US' }),
    });
    expect(putRes.status).toBe(200);
    const getRes = await fetch(`${BASE_URL}/api/v2/preferences`, {
      headers: { authorization: `Bearer ${token}` },
    });
    const getBody = (await getRes.json()) as { data: { 'language.locales': { primary: string; secondary: string } } };
    expect(getBody.data['language.locales'].primary).toBe('cmn-Hant-TW');
    expect(getBody.data['language.locales'].secondary).toBe('eng-Latn-US');
  });

  it('rejects secondary equal to primary', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/preferences/language.locales`, {
      method: 'PUT',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ primary: 'cmn-Hant-TW', secondary: 'cmn-Hant-TW' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_PREFERENCE');
  });

  it('requires auth', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/preferences`);
    expect(res.status).toBe(401);
  });
});
```

確保 worker 在 8788,跑:

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/preferencesIntegration.test.ts
```

Expected: 4 tests PASS。

- [ ] **Step 8: Commit**

```bash
git add backend/src/services/preferences.ts backend/src/routes/preferences.ts backend/src/routes/index.ts backend/tests/preferences.test.ts backend/tests/preferencesIntegration.test.ts
git commit -m "feat(api): add user preferences with language locale validation"
```

---

## Task 4: i18n catalog locale code migration

更新 `scripts/i18n/` 的 locale code 從舊 BCP 47 格式改成完整 Language Locale 格式。不重生成 stale artifact SQL(依賴 Plan 7 的新 UI 表)。

**Files:**
- Modify: `scripts/i18n/generate-i18n-sql.py`
- Rename: `scripts/i18n/cmn-Hans.json` → `scripts/i18n/cmn-Hans-CN.json`
- Rename: `scripts/i18n/cmn-Hant.json` → `scripts/i18n/cmn-Hant-TW.json`
- Rename: `scripts/i18n/es-ES.json` → `scripts/i18n/spa-Latn-ES.json`
- Rename: `scripts/i18n/ja-JP.json` → `scripts/i18n/jpn-Jpan-JP.json`
- Modify: `scripts/i18n/test_generate_bundle.py`(if it references old codes)

- [ ] **Step 1: 改名 JSON 檔案**

```bash
cd /Users/share.lim/Documents/GitHub/langmap
git mv scripts/i18n/cmn-Hans.json scripts/i18n/cmn-Hans-CN.json
git mv scripts/i18n/cmn-Hant.json scripts/i18n/cmn-Hant-TW.json
git mv scripts/i18n/es-ES.json scripts/i18n/spa-Latn-ES.json
git mv scripts/i18n/ja-JP.json scripts/i18n/jpn-Jpan-JP.json
```

- [ ] **Step 2: 更新 `scripts/i18n/generate-i18n-sql.py`**

READ the file. Make these changes:

a. `SOURCE_LANGUAGE_CODE`(line 22):`'en-Latn'` → `'eng-Latn-US'`

b. `validate_locale_code`(line 149-151):更新 regex 接受 Language Locale grammar:
```python
def validate_locale_code(locale_code: str) -> None:
    if not re.match(r'^[a-z]{3}-[A-Z][a-z]{3}-[A-Z]{2}(?:_[A-Z][A-Za-z]*)*$', locale_code):
        raise ValueError(f'invalid language locale code "{locale_code}" (expected format: xxx-Xxxx-XX)')
```

c. Docstring(行 5-8):更新範例:
```python
    python3 scripts/i18n/generate-i18n-sql.py \
      cmn-Hant-TW scripts/i18n/cmn-Hant-TW.json
```

d. Usage string(line 274):`cmn-Hant` → `cmn-Hant-TW`

- [ ] **Step 3: 更新 `scripts/i18n/test_generate_bundle.py`**

READ the file. Update any references to old locale codes (`en-Latn`、`cmn-Hant`、`cmn-Hans`) to new codes (`eng-Latn-US`、`cmn-Hant-TW`、`cmn-Hans-CN`). If tests reference JSON filenames, update those too.

- [ ] **Step 4: 跑 i18n 測試**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && python3 scripts/i18n/test_generate_bundle.py
```

Expected: PASS。若測試因 stale artifact 引用舊 code 而失敗,更新測試中的 code 引用。

- [ ] **Step 5: Commit**

```bash
git add scripts/i18n/
git commit -m "refactor(i18n): migrate catalog locale codes to full Language Locale format"
```

---

## Task 5: 全量回歸與收尾驗證

**Files:** 無(若有修正在此提交)

- [ ] **Step 1: 後端完整測試**

確保 worker 在 8788:

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npm test
```

Expected: 除了已知既有失敗(`auth.test.ts` × 1、`expressionsIntegration.test.ts` × 2),全部 PASS。

- [ ] **Step 2: scripts 測試**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && python3 scripts/language-reference/test_generate.py
cd /Users/share.lim/Documents/GitHub/langmap && python3 scripts/db/tests/test_local_rebuild.py
cd /Users/share.lim/Documents/GitHub/langmap && python3 -m unittest scripts.db.tests.test_verify
cd /Users/share.lim/Documents/GitHub/langmap && python3 scripts/i18n/test_generate_bundle.py
```

Expected: 全部 OK。

- [ ] **Step 3: 文件與空白檢查**

```bash
git diff --check
git status --short
```

若有 `manifest.json` 被 `test_generate.py` 改了 `generated_at`,`git checkout -- scripts/language-reference/artifacts/manifest.json` 恢復。

- [ ] **Step 4: 若有修正則 Commit**

若 Step 1–3 全過且無修正,此 step 跳過。

---

## Self-Review

**1. Spec coverage:**

- §9.2 `expression_readings` 表(scheme、value、UNIQUE 含 source provenance、四條 FK、source_ref CHECK)→ Task 1。
- §9.2 Scheme grammar `^[a-z][a-z0-9-]*(?::[a-z][a-z0-9-]*)?$` → Task 2 `validateReadingScheme`。
- §9.2「建立 reading 時必須在同一原子操作建立 source_id/source_ref 完全相同的 locale attestation」→ Task 2 `createReading` 先呼叫 `createLocaleAttestation`(Plan 3 冪等函式),再建立 reading。
- §9.2「重複資料回傳既有記錄」→ Task 2 find-or-create(SQLite NULL UNIQUE 的 service 層去重)。
- §13.2 `POST /expressions/:id/readings` → Task 2 route。
- §11 `user_preferences` 表(composite PK、value_json、FK CASCADE)→ Task 1。
- §11 key registry + Zod schema → Task 3 `PREFERENCE_SCHEMAS`。
- §11 `language.locales` value(primary 必填、secondary 選填非 null 不重複、locale 存在性)→ Task 3 Zod refine + DB 檢查。
- §11 匿名偏好 localStorage(不寫 D1)→ 前端職責,本 plan 不涉及(後端只處理登入者)。
- §13.3 `GET /preferences`、`PUT /preferences/language.locales` → Task 3 route(URL 用 `language-locales` 代替點號)。
- §13.3 未知 key → `UNKNOWN_PREFERENCE_KEY` → Task 3 service + route。
- §14 `INVALID_READING_SCHEME`、`UNKNOWN_PREFERENCE_KEY`、`INVALID_LANGUAGE_PREFERENCE` → Task 2 + Task 3。
- §16.6 `scripts/i18n` locale code 遷移 → Task 4。

**未覆蓋(留給後續 plan):** UI localization 後端(§12、§13.4 — ui_locales、ui_messages、coverage、activation、fallback bundle);前端(§15);`scripts/i18n` SQL artifact 完整重寫(依賴 Plan 7 新 UI 表);readings 的列表 API(spec §13.2 只列 POST,readings 查詢由 `GET /:id` detail 一併返回或留給前端從 attestations 推導——spec §15.3 提到 Inspector 顯示 readings,需要 readings 出現在 expression detail。此問題在 spec 中未明確定義 readings 的 GET route,本 plan 也只實作 POST)。

**2. Placeholder scan:** 每個 step 都有完整程式碼與可執行命令。readings service 使用 dynamic import(`await import('./expressions')`)避免循環依賴——這是刻意設計,非 placeholder。preferences route 用 `language-locales`(URL path segment)代替 `language.locales`(含點號)並在 service 層轉換——這是 URL 安全的必要處理。

**3. Type consistency:** `ReadingRow` 加在 `types/expression.ts`(與 `ExpressionRow`／`LocaleAttestationRow` 同檔);`createReading` 回傳 `{ reading: ReadingRow; created: boolean }` 與 route 的 `created`/`success` helper 一致;`PreferenceError`／`getPreferences`／`putPreference` 在 Task 3 定義並被 route import;`putPreference` 回傳 `{ key, value }` 與 route 的 `success(c, result, ...)` 一致;`paginated` 不用於此 plan(兩個 GET 都回單一物件或 flat key map)。route handler 使用 `c.req.param()` 而非 `c.param()`(Plan 4 修正的 Hono 4 API)。
