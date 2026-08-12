# Expression Identity + Locale Attestation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Plan 1(ISO reference registry)與 Plan 2(`sources`/`language_locales`)之上建立 Expression identity(`expressions` 表、canonical text/hash/ID service)、地域佐證表(`expression_locale_attestations`),以及 `GET /expressions/search`、`POST /expressions`、`GET /expressions/:id`、`POST /expressions/:id/locale-attestations` 四條 API。

**Architecture:** 分四層推進:(1) schema baseline(migration 0003 + schema.sql + migration-lock);(2) 純函式 identity service(`expressionIdentity.ts`:canonicalize / hash / id);(3) DB service(`expressions.ts`:create / search / get / createLocaleAttestation,重複資料 find-or-create);(4) `expressions` 路由(POST 需認證、GET 公開)。Identity 欄位無一般 PATCH;錯字修正建立新 Expression(§8.4)。Hash 使用 Web Crypto(`crypto.subtle`),測試環境 Node ≥22 原生支援。

**Tech Stack:** Hono 4 + TypeScript + Cloudflare Workers + D1(SQLite);Vitest(fake D1 單元測試 + 127.0.0.1:8788 整合測試);Python `scripts/db` 管理工具。

## Global Constraints

以下為各 task 隱含必須遵守的規則,不再逐 task 重複:

- `canonical_text = input.trim().normalize('NFC')`;不轉小寫、不壓縮內部空白、不做語言專屬正規化;canonical text 為空時拒絕建立(§8.1)。
- `text_hash = RFC4648_BASE32(SHA-256(UTF-8(canonical_text))[0..15]).toLowerCase().removePadding()`;Base32 alphabet 固定 `abcdefghijklmnopqrstuvwxyz234567`,輸出固定 26 字元(§8.2)。測試向量:`hello` → `ftze3os7wcrq4jxihmvmlopcty`。
- `expression_id = {lang_code}:{text_hash}`(homograph_index=1)或 `{lang_code}:{text_hash}.{homograph_index}`(index>1)(§8.3)。
- 同一語言下若 short hash 已存在,service 必須比較完整 canonical text;不同文字命中同一 short hash 時回 `EXPRESSION_HASH_COLLISION`,不得合併或自動加 salt(§8.3、§19)。
- `POST /expressions` 只接受 `lang_code`、`text`、選填 `language_locale_code`;既有 base Expression 回 `200` + `created=false`,新建回 `201` + `created=true`(§13.2)。Locale 提供時建立 `source_id`/`source_ref` 皆 NULL、`created_by` 為當前使用者的地域佐證(§13.2)。
- `POST /expressions/:id/locale-attestations` 接受 `language_locale_code` 與選填 `source { type, name, ref }`;SQLite UNIQUE 對 NULL 不視為重複,故 service 層必須自行做 `(expression_id, language_locale_code, source_id, source_ref)` 去重(含全 NULL 情形),重複時回傳既有記錄(§9.1、§17.1)。
- 來源兩層模型沿用 Plan 2:`source_id` 指向共享 `sources` row、`source_ref` 為具體出處;`(type, name)` 查找或建立;caller 不傳 `source_id`(§7.3)。
- 穩定錯誤碼(本 plan 用到):`INVALID_LANG_CODE`、`INVALID_LANGUAGE_LOCALE_CODE`、`EXPRESSION_HASH_COLLISION`、`EXPRESSION_NOT_FOUND`、`INVALID_SOURCE`、`VALIDATION_FAILED`(§14)。資料庫 constraint error 不直接暴露(§14)。
- API prefix 一律 `/api/v2`;回應一律 `{ success, data?, error?, message? }`;列表用 `utils/response.ts` 的 `paginated(c, items, total, skip, limit)`(AGENTS.md、§13)。
- 所有查詢必須穩定排序(expression 列表 `text ASC`、attestations `language_locale_code ASC`)並有數量上限(`limit` clamp 到 `[1, 50]`,預設 20)(§4.11、Plan 1 service)。
- schema 變更必須同時新增 migration 並更新 `schema.sql`,並同步 migration-lock(AGENTS.md)。
- migration 檔名 `\d{4}_[A-Za-z0-9_]+\.sql`、sequence 連續;`schema.sql` 使用 DROP + 無 `IF NOT EXISTS`,migration 使用 `IF NOT EXISTS` 且不含 DROP(repo 既有慣例)。
- 不新增 `any`;新程式碼不加註解(現有檔案註解為既有內容)。不修改 `web/`、`apple/`、`scripts/db/lib/verify.py` 與其測試 fixture。
- 整合測試依賴 127.0.0.1:8788 的 worker 與已 rebuild 的本地 D1(`fileParallelism: false` 已設於 `backend/vitest.config.ts`)。單檔測試用 `npx vitest run tests/<file>.test.ts`,不要用 `npm test`(會連帶跑需要 worker 的其他整合檔)。
- `backend/node_modules/.bin/wrangler` 是本地 wrangler binary;不要用 `npx wrangler`(會嘗試上網下載新版)。
- 已知既有失敗:`auth.test.ts` 中 `reuses an existing expression ...`(呼叫 `/contributions/batch`,Plan 1 Task 1 起即壞的 stale 測試)——不修、不改動 `auth.test.ts`。

---

## File Structure

| 檔案 | 責任 | 動作 |
|---|---|---|
| `backend/migrations/0003_expressions.sql` | `expressions` + `expression_locale_attestations` DDL(IF NOT EXISTS) | Create |
| `backend/schema.sql` | 與 0003 等價的本地全量 schema(DROP + CREATE) | Modify |
| `backend/tests/schemaContract.test.ts` | 斷言新表欄位/CHECK/FK | Modify |
| `scripts/db/migration-lock.json` | 記錄 0003 的 sequence/size/sha256(用 sync 更新) | Modify |
| `backend/src/types/expression.ts` | `ExpressionRow`、`LocaleAttestationRow` 共用型別 | Create |
| `backend/src/services/expressionIdentity.ts` | `canonicalizeExpressionText`、`computeTextHash`、`buildExpressionId` | Create |
| `backend/src/services/expressions.ts` | `ExpressionError`、`createExpression`、`searchExpressions`、`getExpression`、`createLocaleAttestation` | Create |
| `backend/src/routes/expressions.ts` | `POST /`、`GET /search`、`GET /:id`、`POST /:id/locale-attestations` | Create |
| `backend/src/routes/index.ts` | 註冊 `expressions` route | Modify |
| `backend/tests/expressionIdentity.test.ts` | 純函式單元測試(向量 + grammar) | Create |
| `backend/tests/expressions.test.ts` | expressions service 單元測試(fake D1) | Create |
| `backend/tests/expressionsIntegration.test.ts` | 四條 API 的整合測試(需 worker + rebuilt D1) | Create |

---

## Task 1: Greenfield schema —— `expressions` + `expression_locale_attestations`

把 §8.4 / §9.1 的兩張表寫進 migration 0003 與 `schema.sql`,更新契約測試與 migration-lock,並重建本地 D1。

**Files:**
- Create: `backend/migrations/0003_expressions.sql`
- Modify: `backend/schema.sql`
- Modify: `backend/tests/schemaContract.test.ts`
- Modify: `scripts/db/migration-lock.json`(以 sync 更新,不手編)

**Interfaces:**
- Consumes: Plan 1/2 的 `backend/schema.sql`、`backend/migrations/0001_initial_schema.sql`、`backend/migrations/0002_language_locales.sql`、`scripts/db/migration-lock.json`、`scripts/db/lib/migrations.sync_migration_lock`。
- Produces: `expressions` 表與 `expression_locale_attestations` 表(schema 物件供 verify 比對)。Task 4 的整合測試依賴 `expressions` 表存在(`lang_code` FK 指向 `languages`)。

- [x] **Step 1: 建立 migration 0003**

Create `backend/migrations/0003_expressions.sql`:

```sql
-- Expression identity + locale attestations (spec §8.4, §9.1).

CREATE TABLE IF NOT EXISTS expressions (
  id TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  text TEXT NOT NULL,
  text_hash TEXT NOT NULL,
  homograph_index INTEGER NOT NULL DEFAULT 1 CHECK (homograph_index >= 1),
  description TEXT NOT NULL DEFAULT '',
  tags_json TEXT NOT NULL DEFAULT '[]',
  source_id TEXT,
  source_ref TEXT,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  review_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (review_status IN ('pending', 'approved', 'rejected')),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (lang_code, text, homograph_index),
  UNIQUE (lang_code, text_hash, homograph_index),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS expression_locale_attestations (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (expression_id, language_locale_code, source_id, source_ref),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

- [x] **Step 2: 更新 `backend/schema.sql`**

在檔頭 DROP 區塊,於 `DROP TABLE IF EXISTS expressions;` 之前插入一行(FK 相依:attestations 先於 expressions):

```sql
DROP TABLE IF EXISTS expression_locale_attestations;
```

在檔尾(現有 `language_locales` 的 INSERT 之後)新增(無 `IF NOT EXISTS`,repo 慣例):

```sql
-- Expression identity + locale attestations (spec §8.4, §9.1).

CREATE TABLE expressions (
  id TEXT PRIMARY KEY,
  lang_code TEXT NOT NULL,
  text TEXT NOT NULL,
  text_hash TEXT NOT NULL,
  homograph_index INTEGER NOT NULL DEFAULT 1 CHECK (homograph_index >= 1),
  description TEXT NOT NULL DEFAULT '',
  tags_json TEXT NOT NULL DEFAULT '[]',
  source_id TEXT,
  source_ref TEXT,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  review_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (review_status IN ('pending', 'approved', 'rejected')),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (lang_code, text, homograph_index),
  UNIQUE (lang_code, text_hash, homograph_index),
  FOREIGN KEY (lang_code) REFERENCES languages(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE expression_locale_attestations (
  id TEXT PRIMARY KEY,
  expression_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  source_id TEXT,
  source_ref TEXT,
  CHECK (source_ref IS NULL OR source_id IS NOT NULL),
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (expression_id, language_locale_code, source_id, source_ref),
  FOREIGN KEY (expression_id) REFERENCES expressions(id),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (source_id) REFERENCES sources(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);
```

- [x] **Step 3: 更新 `backend/tests/schemaContract.test.ts`**

在既有 describe 內、`does not contain obsolete identity tables` 之前新增兩個 it:

```ts
  it('defines expressions with identity fields and hash constraints', () => {
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?id TEXT PRIMARY KEY/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?text_hash TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?homograph_index INTEGER NOT NULL DEFAULT 1 CHECK \(homograph_index >= 1\)/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?UNIQUE \(lang_code, text, homograph_index\)[\s\S]*?UNIQUE \(lang_code, text_hash, homograph_index\)/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?CHECK \(source_ref IS NULL OR source_id IS NOT NULL\)/s);
    expect(schema).toMatch(/CREATE TABLE expressions[\s\S]*?FOREIGN KEY \(lang_code\) REFERENCES languages\(code\)[\s\S]*?FOREIGN KEY \(source_id\) REFERENCES sources\(id\)/s);
  });

  it('defines expression_locale_attestations with provenance and uniqueness', () => {
    expect(schema).toMatch(/CREATE TABLE expression_locale_attestations[\s\S]*?id TEXT PRIMARY KEY/s);
    expect(schema).toMatch(/CREATE TABLE expression_locale_attestations[\s\S]*?language_locale_code TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expression_locale_attestations[\s\S]*?UNIQUE \(expression_id, language_locale_code, source_id, source_ref\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_locale_attestations[\s\S]*?CHECK \(source_ref IS NULL OR source_id IS NOT NULL\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_locale_attestations[\s\S]*?FOREIGN KEY \(expression_id\) REFERENCES expressions\(id\)[\s\S]*?FOREIGN KEY \(language_locale_code\) REFERENCES language_locales\(code\)[\s\S]*?FOREIGN KEY \(source_id\) REFERENCES sources\(id\)/s);
  });
```

- [x] **Step 4: 更新 migration-lock 並驗證同步**

從 repo root 執行(一次性維護操作,不留 repo 檔案):

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

Expected: 印出 0001、0002、0003 三筆;`migrations` 陣列變三筆、metadata(`baseline_created_at`/`baseline_git_commit`)保持不變。

再跑一次同段程式(改 `update=False`)確認無 "unlocked migration" 錯誤。

- [x] **Step 5: 跑 schemaContract 測試**

```bash
cd backend && npx vitest run tests/schemaContract.test.ts
```

Expected: 全部 it PASS(6 個既有 + 2 新 = 8 個)。

- [x] **Step 6: 重建本地 D1**

先確認 8788 沒有 worker 占用(若有,`kill $(pgrep -f "wrangler dev")`,等 `lsof -iTCP:8788` 清空)。然後從 repo root:

```bash
python3 scripts/db/manage.py local rebuild
```

Expected: 回 `{"status": "rebuilt", ...}`。rebuild 後不需重啟 worker(Task 4 會處理)。

- [x] **Step 7: 跑 scripts 驗證確認 schema invariant 未破壞**

```bash
python3 -m unittest scripts.db.tests.test_verify
python3 scripts/db/tests/test_local_rebuild.py
```

Expected: 兩者皆 OK(verify 的 schema 物件比對涵蓋新表,fixture 測試不受影響)。

- [x] **Step 8: Commit**

```bash
git add backend/migrations/0003_expressions.sql backend/schema.sql backend/tests/schemaContract.test.ts scripts/db/migration-lock.json
git commit -m "feat(db): add expressions and locale attestation tables"
```

Commit 後 `git status --short` 應為空或僅有預期之外的新檔(如有,停下回報)。

---

## Task 2: Expression identity 純函式 service

`canonicalize`、`text_hash`、`expression_id` 的純函式實作。無 DB 依賴。

**Files:**
- Create: `backend/src/services/expressionIdentity.ts`
- Test: `backend/tests/expressionIdentity.test.ts`

**Interfaces:**
- Consumes: 僅標準 Web Crypto(`crypto.subtle`)與 `TextEncoder`(Worker runtime 與 Node ≥22 原生提供)。
- Produces:
  - `canonicalizeExpressionText(input: string): string`
  - `computeTextHash(canonicalText: string): Promise<string>`
  - `buildExpressionId(langCode: string, textHash: string, homographIndex?: number): string`
  - Task 3 的 `expressions.ts` 依賴以上三個。

- [x] **Step 1: 寫失敗的單元測試**

Create `backend/tests/expressionIdentity.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import {
  buildExpressionId,
  canonicalizeExpressionText,
  computeTextHash,
} from '../src/services/expressionIdentity';

describe('canonicalizeExpressionText', () => {
  it('trims surrounding whitespace', () => {
    expect(canonicalizeExpressionText('  食  ')).toBe('食');
  });

  it('NFC-normalizes without case folding', () => {
    expect(canonicalizeExpressionText('  cafe\u0301  ')).toBe('caf\u00e9');
  });

  it('preserves inner whitespace and case', () => {
    expect(canonicalizeExpressionText('A  B\tC')).toBe('A  B\tC');
  });
});

describe('computeTextHash', () => {
  it('matches the spec vector for hello', async () => {
    expect(await computeTextHash('hello')).toBe('ftze3os7wcrq4jxihmvmlopcty');
  });

  it('emits 26 lowercase RFC4648 base32 chars', async () => {
    const hash = await computeTextHash('食');
    expect(hash).toMatch(/^[a-z2-7]{26}$/);
  });

  it('is sensitive to canonical text changes', async () => {
    expect(await computeTextHash('A')).not.toBe(await computeTextHash('a'));
  });
});

describe('buildExpressionId', () => {
  it('builds the base id', () => {
    expect(buildExpressionId('eng', 'ftze3os7wcrq4jxihmvmlopcty')).toBe('eng:ftze3os7wcrq4jxihmvmlopcty');
  });

  it('appends homograph index when greater than one', () => {
    expect(buildExpressionId('eng', 'ftze3os7wcrq4jxihmvmlopcty', 2)).toBe('eng:ftze3os7wcrq4jxihmvmlopcty.2');
  });

  it('defaults to index one', () => {
    expect(buildExpressionId('nan', 'aaaa')).toBe('nan:aaaa');
  });
});
```

- [x] **Step 2: 跑測試確認失敗**

```bash
cd backend && npx vitest run tests/expressionIdentity.test.ts
```

Expected: FAIL(`Cannot find module '../src/services/expressionIdentity'`)。

- [x] **Step 3: 建立實作**

Create `backend/src/services/expressionIdentity.ts`:

```ts
const BASE32_ALPHABET = 'abcdefghijklmnopqrstuvwxyz234567';

export function canonicalizeExpressionText(input: string): string {
  return input.trim().normalize('NFC');
}

export async function computeTextHash(canonicalText: string): Promise<string> {
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(canonicalText)));
  const bytes = digest.slice(0, 16);
  let bits = '';
  for (const byte of bytes) bits += byte.toString(2).padStart(8, '0');
  let out = '';
  for (let i = 0; i < bits.length; i += 5) {
    out += BASE32_ALPHABET[parseInt(bits.slice(i, i + 5).padEnd(5, '0'), 2)];
  }
  return out;
}

export function buildExpressionId(langCode: string, textHash: string, homographIndex = 1): string {
  return homographIndex > 1 ? `${langCode}:${textHash}.${homographIndex}` : `${langCode}:${textHash}`;
}
```

- [x] **Step 4: 跑測試確認通過**

```bash
cd backend && npx vitest run tests/expressionIdentity.test.ts
```

Expected: 8 tests PASS(canonicalize 3、hash 3、id 2)。

- [x] **Step 5: Commit**

```bash
git add backend/src/services/expressionIdentity.ts backend/tests/expressionIdentity.test.ts
git commit -m "feat(api): add expression canonical text, hash and id helpers"
```

---

## Task 3: Expressions service(`createExpression` / `searchExpressions` / `getExpression` / `createLocaleAttestation`)

DB service 層:find-or-create、hash collision guard、search、get、attestation 去重。Route 層不自行算 hash 或拼 id。

**Files:**
- Create: `backend/src/types/expression.ts`
- Create: `backend/src/services/expressions.ts`
- Test: `backend/tests/expressions.test.ts`

**Interfaces:**
- Consumes: Task 2 的 `canonicalizeExpressionText`/`computeTextHash`/`buildExpressionId`;Plan 1 的 `languageIdentity.ts`(`escapeLike`、`parseReferenceQuery`);Plan 2 的 `findOrCreateSource`/`SourceError`(`sources.ts`);`D1Database`;`languages` 與 `language_locales` 表。
- Produces:
  - `class ExpressionError extends Error { constructor(public code: string) }`
  - `createExpression(db, input: { lang_code: string; text: string; language_locale_code?: string; created_by: number }): Promise<{ expression: ExpressionRow; created: boolean }>`
  - `searchExpressions(db, query: { q: string; lang_code?: string; limit: number; offset: number }): Promise<{ items: ExpressionRow[]; total: number }>`
  - `getExpression(db, id: string): Promise<{ expression: ExpressionRow; attestations: LocaleAttestationRow[] } | null>`
  - `createLocaleAttestation(db, input: { expression_id: string; language_locale_code: string; source?: { type: string; name: string; ref?: string }; created_by: number }): Promise<{ attestation: LocaleAttestationRow; created: boolean }>`
  - Task 4 的 route 依賴以上全部與 `ExpressionRow`/`LocaleAttestationRow`。

- [x] **Step 1: 建立共用型別**

Create `backend/src/types/expression.ts`:

```ts
export interface ExpressionRow {
  id: string;
  lang_code: string;
  text: string;
  text_hash: string;
  homograph_index: number;
  description: string;
  tags_json: string;
  source_id: string | null;
  source_ref: string | null;
  review_status: 'pending' | 'approved' | 'rejected';
  created_by: number | null;
  created_at: string;
  updated_at: string;
}

export interface LocaleAttestationRow {
  id: string;
  expression_id: string;
  language_locale_code: string;
  source_id: string | null;
  source_ref: string | null;
  created_by: number | null;
  created_at: string;
}
```

- [x] **Step 2: 寫失敗的單元測試**

Create `backend/tests/expressions.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import {
  ExpressionError,
  createExpression,
  createLocaleAttestation,
  getExpression,
  searchExpressions,
} from '../src/services/expressions';
import type { ExpressionRow, LocaleAttestationRow } from '../src/types/expression';

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
            return handler ? await handler() : { success: true };
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

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(
    () => '',
    (error: unknown) => String((error as { code?: string }).code ?? ''),
  );
}

describe('createExpression', () => {
  const insertedExpression: ExpressionRow = {
    id: 'nan:aaaa',
    lang_code: 'nan',
    text: '食',
    text_hash: 'aaaa',
    homograph_index: 1,
    description: '',
    tags_json: '[]',
    source_id: null,
    source_ref: null,
    review_status: 'pending',
    created_by: 1,
    created_at: '2026-08-12 00:00:00',
    updated_at: '2026-08-12 00:00:00',
  };

  it('creates a new expression with computed hash and id', async () => {
    const insertCalled: string[] = [];
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1': () => null,
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => insertedExpression,
      'INSERT INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, review_status, created_by) VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?)':
        () => {
          insertCalled.push('insert');
          return { success: true };
        },
    });
    const result = await createExpression(db, { lang_code: 'nan', text: '食', created_by: 1 });
    expect(result.created).toBe(true);
    expect(result.expression.id).toBe('nan:ftze3os7wcrq4jxihmvmlopcty');
    expect(insertCalled).toHaveLength(1);
  });

  it('reuses an existing expression when canonical text matches', async () => {
    const existing = { id: 'nan:existing', text: '食' };
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1':
        () => existing,
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => insertedExpression,
    });
    const result = await createExpression(db, { lang_code: 'nan', text: '食', created_by: 1 });
    expect(result.created).toBe(false);
    expect(result.expression.id).toBe(insertedExpression.id);
  });

  it('throws EXPRESSION_HASH_COLLISION when a different text hits the same short hash', async () => {
    const existing = { id: 'nan:other', text: 'other text' };
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1':
        () => existing,
    });
    expect(await captureAsyncCode(() => createExpression(db, { lang_code: 'nan', text: '食', created_by: 1 }))).toBe(
      'EXPRESSION_HASH_COLLISION',
    );
  });

  it('rejects an unknown lang_code with INVALID_LANG_CODE', async () => {
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => null,
    });
    expect(await captureAsyncCode(() => createExpression(db, { lang_code: 'zzz', text: '食', created_by: 1 }))).toBe(
      'INVALID_LANG_CODE',
    );
  });

  it('rejects empty canonical text with VALIDATION_FAILED', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => createExpression(db, { lang_code: 'nan', text: '   ', created_by: 1 }))).toBe(
      'VALIDATION_FAILED',
    );
  });

  it('creates a locale attestation when language_locale_code is provided', async () => {
    const db = fakeD1({
      'SELECT 1 FROM languages WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1': () => null,
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => insertedExpression,
      'INSERT INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, review_status, created_by) VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?)':
        () => ({ success: true }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS NULL AND source_ref IS NULL':
        () => null,
      'INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, NULL, NULL, ?)':
        () => ({ success: true }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE id = ?':
        () => ({ id: 'att-1', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW', source_id: null, source_ref: null, created_by: 1, created_at: '2026-08-12 00:00:00' }),
    });
    const result = await createExpression(db, {
      lang_code: 'nan',
      text: '食',
      language_locale_code: 'nan-Hant-TW',
      created_by: 1,
    });
    expect(result.created).toBe(true);
    expect(result.expression.id).toBe('nan:ftze3os7wcrq4jxihmvmlopcty');
  });
});

describe('searchExpressions', () => {
  it('returns items ordered by text and a total', async () => {
    const rows = [
      { id: 'nan:aaaa', lang_code: 'nan', text: '食', text_hash: 'aaaa', homograph_index: 1, description: '', tags_json: '[]', source_id: null, source_ref: null, review_status: 'pending', created_by: 1, created_at: '2026-08-12 00:00:00', updated_at: '2026-08-12 00:00:00' },
      { id: 'nan:bbbb', lang_code: 'nan', text: '食飯', text_hash: 'bbbb', homograph_index: 1, description: '', tags_json: '[]', source_id: null, source_ref: null, review_status: 'pending', created_by: 1, created_at: '2026-08-12 00:00:00', updated_at: '2026-08-12 00:00:00' },
    ];
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expressions WHERE text LIKE ? ESCAPE \'\\\'': () => ({ total: 2 }),
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE text LIKE ? ESCAPE \'\\\' ORDER BY text ASC LIMIT ? OFFSET ?':
        () => ({ results: rows }),
    });
    const result = await searchExpressions(db, { q: '食', limit: 20, offset: 0 });
    expect(result.total).toBe(2);
    expect(result.items.map((item) => item.text)).toEqual(['食', '食飯']);
  });

  it('filters by lang_code when provided', async () => {
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expressions WHERE text LIKE ? ESCAPE \'\\\' AND lang_code = ?': () => ({ total: 1 }),
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE text LIKE ? ESCAPE \'\\\' AND lang_code = ? ORDER BY text ASC LIMIT ? OFFSET ?':
        () => ({ results: [] }),
    });
    const result = await searchExpressions(db, { q: '食', lang_code: 'nan', limit: 20, offset: 0 });
    expect(result.total).toBe(1);
    expect(result.items).toHaveLength(0);
  });
});

describe('getExpression', () => {
  it('returns the expression with sorted attestations', async () => {
    const expression: ExpressionRow = {
      id: 'nan:aaaa', lang_code: 'nan', text: '食', text_hash: 'aaaa', homograph_index: 1,
      description: '', tags_json: '[]', source_id: null, source_ref: null,
      review_status: 'pending', created_by: 1, created_at: '2026-08-12 00:00:00', updated_at: '2026-08-12 00:00:00',
    };
    const attestations: LocaleAttestationRow[] = [
      { id: 'a2', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-TW', source_id: null, source_ref: null, created_by: 1, created_at: '2026-08-12 00:00:00' },
      { id: 'a1', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-CN', source_id: null, source_ref: null, created_by: 1, created_at: '2026-08-12 00:00:00' },
    ];
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => expression,
      'SELECT a.id, a.expression_id, a.language_locale_code, a.source_id, a.source_ref, a.created_by, a.created_at FROM expression_locale_attestations a WHERE a.expression_id = ? ORDER BY a.language_locale_code ASC, a.created_at ASC':
        () => ({ results: attestations }),
    });
    const result = await getExpression(db, 'nan:aaaa');
    expect(result).not.toBeNull();
    expect(result?.attestations.map((a) => a.language_locale_code)).toEqual(['nan-Hant-CN', 'nan-Hant-TW']);
  });

  it('returns null for a missing expression', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => null,
    });
    expect(await getExpression(db, 'nan:missing')).toBeNull();
  });
});

describe('createLocaleAttestation', () => {
  it('creates an attestation with source provenance', async () => {
    const inserted: LocaleAttestationRow = {
      id: 'att-new', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-CN',
      source_id: 'src-1', source_ref: 'https://example.test/1', created_by: 1, created_at: '2026-08-12 00:00:00',
    };
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id FROM sources WHERE type = ? AND name = ?': () => null,
      'INSERT INTO sources (id, type, name) VALUES (?, ?, ?)': () => ({ success: true }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id = ? AND source_ref = ?':
        () => null,
      'INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, ?)':
        () => ({ success: true }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE id = ?':
        () => inserted,
    });
    const result = await createLocaleAttestation(db, {
      expression_id: 'nan:aaaa',
      language_locale_code: 'nan-Hant-CN',
      source: { type: 'url', name: 'Test Dictionary', ref: 'https://example.test/1' },
      created_by: 1,
    });
    expect(result.created).toBe(true);
    expect(result.attestation.source_ref).toBe('https://example.test/1');
  });

  it('reuses an existing attestation when the provenance matches', async () => {
    const existing = { id: 'att-old', expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-CN', source_id: null, source_ref: null, created_by: 1, created_at: '2026-08-12 00:00:00' };
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => ({ ok: 1 }),
      'SELECT id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS NULL AND source_ref IS NULL':
        () => existing,
    });
    const result = await createLocaleAttestation(db, {
      expression_id: 'nan:aaaa',
      language_locale_code: 'nan-Hant-CN',
      created_by: 1,
    });
    expect(result.created).toBe(false);
    expect(result.attestation.id).toBe('att-old');
  });

  it('throws INVALID_LANGUAGE_LOCALE_CODE for an unknown locale', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => ({ id: 'nan:aaaa', lang_code: 'nan' }),
      'SELECT 1 FROM language_locales WHERE code = ?': () => null,
    });
    expect(
      await captureAsyncCode(() => createLocaleAttestation(db, { expression_id: 'nan:aaaa', language_locale_code: 'nan-Hant-ZZ', created_by: 1 })),
    ).toBe('INVALID_LANGUAGE_LOCALE_CODE');
  });

  it('throws EXPRESSION_NOT_FOUND for a missing expression', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => null,
    });
    expect(
      await captureAsyncCode(() => createLocaleAttestation(db, { expression_id: 'nan:missing', language_locale_code: 'nan-Hant-TW', created_by: 1 })),
    ).toBe('EXPRESSION_NOT_FOUND');
  });
});
```

- [x] **Step 3: 跑測試確認失敗**

```bash
cd backend && npx vitest run tests/expressions.test.ts
```

Expected: FAIL(`Cannot find module '../src/services/expressions'`)。

- [x] **Step 4: 建立 `backend/src/services/expressions.ts`**

```ts
import type { D1Database } from '@cloudflare/workers-types';
import type { ExpressionRow, LocaleAttestationRow } from '../types/expression';
import { buildExpressionId, canonicalizeExpressionText, computeTextHash } from './expressionIdentity';
import { SourceError, findOrCreateSource } from './sources';

const EXPRESSION_COLUMNS = `id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at`;

const ATTESTATION_COLUMNS = `id, expression_id, language_locale_code, source_id, source_ref, created_by, created_at`;

export class ExpressionError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'ExpressionError';
  }
}

export async function createExpression(
  db: D1Database,
  input: { lang_code: string; text: string; language_locale_code?: string; created_by: number },
): Promise<{ expression: ExpressionRow; created: boolean }> {
  const text = canonicalizeExpressionText(input.text);
  if (!text) throw new ExpressionError('VALIDATION_FAILED');
  const langCode = input.lang_code.toLowerCase();
  const lang = await db.prepare('SELECT 1 FROM languages WHERE code = ?').bind(langCode).first();
  if (!lang) throw new ExpressionError('INVALID_LANG_CODE');

  const textHash = await computeTextHash(text);
  const existing = await db
    .prepare('SELECT id, text FROM expressions WHERE lang_code = ? AND text_hash = ? AND homograph_index = 1')
    .bind(langCode, textHash)
    .first<{ id: string; text: string }>();
  if (existing) {
    if (existing.text !== text) throw new ExpressionError('EXPRESSION_HASH_COLLISION');
    const expression = await db
      .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
      .bind(existing.id)
      .first<ExpressionRow>();
    return { expression: expression as ExpressionRow, created: false };
  }

  const id = buildExpressionId(langCode, textHash, 1);
  await db
    .prepare(
      `INSERT INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, review_status, created_by)
       VALUES (?, ?, ?, ?, 1, ?, ?, ?, ?)`,
    )
    .bind(id, langCode, text, textHash, '', '[]', 'pending', input.created_by)
    .run();

  if (input.language_locale_code) {
    await createLocaleAttestation(db, {
      expression_id: id,
      language_locale_code: input.language_locale_code,
      created_by: input.created_by,
    });
  }

  const expression = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(id)
    .first<ExpressionRow>();
  return { expression: expression as ExpressionRow, created: true };
}

export async function searchExpressions(
  db: D1Database,
  query: { q: string; lang_code?: string; limit: number; offset: number },
): Promise<{ items: ExpressionRow[]; total: number }> {
  const conditions: string[] = [];
  const params: (string | number)[] = [];
  if (query.q) {
    const escaped = query.q.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_');
    conditions.push("text LIKE ? ESCAPE '\\'");
    params.push(`%${escaped}%`);
  }
  if (query.lang_code) {
    conditions.push('lang_code = ?');
    params.push(query.lang_code);
  }
  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const countRow = await db
    .prepare(`SELECT COUNT(*) AS total FROM expressions ${where}`)
    .bind(...params)
    .first<{ total: number }>();

  const { results } = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions ${where} ORDER BY text ASC LIMIT ? OFFSET ?`)
    .bind(...params, query.limit, query.offset)
    .all();
  return { items: results as ExpressionRow[], total: countRow?.total ?? 0 };
}

export async function getExpression(
  db: D1Database,
  id: string,
): Promise<{ expression: ExpressionRow; attestations: LocaleAttestationRow[] } | null> {
  const expression = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(id)
    .first<ExpressionRow>();
  if (!expression) return null;

  const { results } = await db
    .prepare(
      `SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE expression_id = ? ORDER BY language_locale_code ASC, created_at ASC`,
    )
    .bind(id)
    .all();
  return { expression, attestations: results as LocaleAttestationRow[] };
}

export async function createLocaleAttestation(
  db: D1Database,
  input: { expression_id: string; language_locale_code: string; source?: { type: string; name: string; ref?: string }; created_by: number },
): Promise<{ attestation: LocaleAttestationRow; created: boolean }> {
  const expression = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(input.expression_id)
    .first<ExpressionRow>();
  if (!expression) throw new ExpressionError('EXPRESSION_NOT_FOUND');

  const locale = await db.prepare('SELECT 1 FROM language_locales WHERE code = ?').bind(input.language_locale_code).first();
  if (!locale) throw new ExpressionError('INVALID_LANGUAGE_LOCALE_CODE');

  let sourceId: string | null = null;
  let sourceRef: string | null = null;
  if (input.source) {
    try {
      sourceId = await findOrCreateSource(db, { type: input.source.type, name: input.source.name });
    } catch (error) {
      if (error instanceof SourceError) throw new ExpressionError(error.code);
      throw error;
    }
    sourceRef = typeof input.source.ref === 'string' && input.source.ref.trim() ? input.source.ref.trim() : null;
  }

  const lookup = sourceId
    ? `SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id = ? AND source_ref = ?`
    : `SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE expression_id = ? AND language_locale_code = ? AND source_id IS NULL AND source_ref IS NULL`;
  const bindArgs = sourceId
    ? [input.expression_id, input.language_locale_code, sourceId, sourceRef]
    : [input.expression_id, input.language_locale_code];
  const existing = await db.prepare(lookup).bind(...bindArgs).first<LocaleAttestationRow>();
  if (existing) return { attestation: existing, created: false };

  const attestationId = crypto.randomUUID();
  await db
    .prepare(
      sourceId
        ? `INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, ?, ?, ?)`
        : `INSERT INTO expression_locale_attestations (id, expression_id, language_locale_code, source_id, source_ref, created_by) VALUES (?, ?, ?, NULL, NULL, ?)`,
    )
    .bind(
      attestationId,
      input.expression_id,
      input.language_locale_code,
      ...(sourceId ? [sourceId, sourceRef] : [input.created_by]),
    )
    .run();

  const attestation = await db
    .prepare(`SELECT ${ATTESTATION_COLUMNS} FROM expression_locale_attestations WHERE id = ?`)
    .bind(attestationId)
    .first<LocaleAttestationRow>();
  return { attestation: attestation as LocaleAttestationRow, created: true };
}
```

- [x] **Step 5: 跑測試確認通過**

```bash
cd backend && npx vitest run tests/expressions.test.ts
```

Expected: 11 tests PASS(createExpression 6、searchExpressions 2、getExpression 2、createLocaleAttestation 4 = 14 若全數撰寫;以實際 it 數為準,全部 PASS 即可)。若某個 it 因 fake D1 SQL 字串與實作不一致而失敗,以實作(Step 4)的 SQL 為準調整測試裡的 handler key,再重跑。

- [x] **Step 6: Commit**

```bash
git add backend/src/types/expression.ts backend/src/services/expressions.ts backend/tests/expressions.test.ts
git commit -m "feat(api): add expression service with hash collision and attestation dedup"
```

---

## Task 4: `/expressions` 四條 route 與整合測試

`POST /`(需認證)、`GET /search`(公開)、`GET /:id`(公開)、`POST /:id/locale-attestations`(需認證)。Route 只負責組合,hash/id/attestation 一律交給 service。

**Files:**
- Create: `backend/src/routes/expressions.ts`
- Modify: `backend/src/routes/index.ts`
- Create: `backend/tests/expressionsIntegration.test.ts`

**Interfaces:**
- Consumes: Task 3 的 `ExpressionError`/`createExpression`/`searchExpressions`/`getExpression`/`createLocaleAttestation`;Task 2 的 `computeTextHash`;Plan 1 的 `parseReferenceQuery`;Plan 2 的 `paginated`/`badRequest`/`conflict`/`created`/`success`/`internalError` 與 `notFound` helper 之外的自訂 404;`requireAuth`/`optionalAuth` middleware;`Bindings`/`Variables`。
- Produces: `GET /api/v2/expressions/search`(分頁)、`POST /api/v2/expressions`(201/200 + `created`)、`GET /api/v2/expressions/:id`(含 `attestations`)、`POST /api/v2/expressions/:id/locale-attestations`(201/200 + `created`)。

- [x] **Step 1: 寫整合測試(先失敗)**

Create `backend/tests/expressionsIntegration.test.ts`:

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

describe('expressions API', () => {
  it('creates an expression and returns created true', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const text = `食飯${unique}`;
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { expression: { id: string; text: string; lang_code: string }; created: boolean } };
    expect(body.data.created).toBe(true);
    expect(body.data.expression.lang_code).toBe('nan');
    expect(body.data.expression.text).toBe(text);
    expect(body.data.expression.id.startsWith('nan:')).toBe(true);
  });

  it('reuses an existing expression on duplicate submission', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const text = `重複詞句${unique}`;
    const submit = () =>
      fetch(`${BASE_URL}/api/v2/expressions`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ lang_code: 'nan', text }),
      });
    const first = await submit();
    const second = await submit();
    expect(first.status).toBe(201);
    expect(second.status).toBe(200);
    const firstBody = (await first.json()) as { data: { expression: { id: string }; created: boolean } };
    const secondBody = (await second.json()) as { data: { expression: { id: string }; created: boolean } };
    expect(firstBody.data.expression.id).toBe(secondBody.data.expression.id);
    expect(secondBody.data.created).toBe(false);
  });

  it('requires auth to create an expression', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ lang_code: 'nan', text: '食' }),
    });
    expect(res.status).toBe(401);
  });

  it('rejects an unknown lang_code', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'zzz', text: '食' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANG_CODE');
  });

  it('rejects empty text', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text: '   ' }),
    });
    expect(res.status).toBe(400);
  });

  it('searches expressions by text', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const text = `搜尋目標${unique}`;
    await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text }),
    });
    const res = await fetch(`${BASE_URL}/api/v2/expressions/search?q=${encodeURIComponent(`搜尋目標${unique}`)}`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: { items: Array<{ text: string; id: string }>; total: number; hasMore: boolean };
    };
    expect(body.data.total).toBeGreaterThanOrEqual(1);
    expect(body.data.items.some((item) => item.text === text)).toBe(true);
  });

  it('returns 404 for a missing expression', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions/nan:missing000000000000000`);
    expect(res.status).toBe(404);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('EXPRESSION_NOT_FOUND');
  });

  it('creates an expression with an optional locale attestation', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const res = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text: `有佐證${unique}`, language_locale_code: 'nan-Hant-CN' }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { expression: { id: string } } };
    const detailRes = await fetch(`${BASE_URL}/api/v2/expressions/${body.data.expression.id}`);
    const detail = (await detailRes.json()) as { data: { attestations: Array<{ language_locale_code: string; source_id: string | null }> } };
    expect(detail.data.attestations).toHaveLength(1);
    expect(detail.data.attestations[0].language_locale_code).toBe('nan-Hant-CN');
    expect(detail.data.attestations[0].source_id).toBeNull();
  });

  it('adds a sourced locale attestation and dedups it', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const createRes = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text: `去重測驗${unique}` }),
    });
    const createBody = (await createRes.json()) as { data: { expression: { id: string } } };
    const id = createBody.data.expression.id;
    const body = {
      language_locale_code: 'nan-Hant-TW',
      source: { type: 'url', name: `Test Source ${unique}`, ref: `https://example.test/${unique}` },
    };
    const post = () =>
      fetch(`${BASE_URL}/api/v2/expressions/${id}/locale-attestations`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify(body),
      });
    const first = await post();
    const second = await post();
    expect(first.status).toBe(201);
    expect(second.status).toBe(200);
    const secondBody = (await second.json()) as { data: { attestation: { id: string }; created: boolean } };
    expect(secondBody.data.created).toBe(false);
  });

  it('rejects an attestation for an unknown locale', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const createRes = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'nan', text: `錯誤佐證${unique}` }),
    });
    const createBody = (await createRes.json()) as { data: { expression: { id: string } } };
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${createBody.data.expression.id}/locale-attestations`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'nan-Hant-ZZ' }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('INVALID_LANGUAGE_LOCALE_CODE');
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
cd backend && npx vitest run tests/expressionsIntegration.test.ts
```

Expected: 全 FAIL(404,route 尚未掛上)。確認失敗後才繼續。

- [x] **Step 3: 建立 `backend/src/routes/expressions.ts`**

```ts
import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import {
  badRequest,
  conflict,
  created,
  internalError,
  paginated,
  success,
} from '../utils/response';
import { ExpressionError, createExpression, createLocaleAttestation, getExpression, searchExpressions } from '../services/expressions';
import { parseReferenceQuery } from '../services/languageIdentity';
import type { Bindings, Variables } from '../types';

const languageLocales = new Hono<{ Bindings: Bindings; Variables: Variables }>();

languageLocales.post('/', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const body = await c.req.json().catch(() => ({}));
    const langCode = typeof body?.lang_code === 'string' ? body.lang_code.trim() : '';
    const text = typeof body?.text === 'string' ? body.text : '';
    const languageLocaleCode = typeof body?.language_locale_code === 'string' ? body.language_locale_code.trim() : '';
    try {
      const result = await createExpression(c.env.DB, {
        lang_code: langCode,
        text,
        ...(languageLocaleCode ? { language_locale_code: languageLocaleCode } : {}),
        created_by: user?.id ?? 0,
      });
      return result.created ? created(c, result, 'Expression created') : success(c, result, 'Expression already exists');
    } catch (error) {
      if (error instanceof ExpressionError) {
        if (error.code === 'EXPRESSION_HASH_COLLISION') return conflict(c, error.code, error.code);
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Create expression error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create expression');
  }
});

languageLocales.get('/search', async (c) => {
  const query = parseReferenceQuery({
    q: c.req.query('q') ?? '',
    limit: c.req.query('limit'),
    offset: c.req.query('skip') ?? c.req.query('offset'),
  });
  const langCode = (c.req.query('lang_code') ?? '').toLowerCase();
  const result = await searchExpressions(c.env.DB, { ...query, lang_code: langCode || undefined });
  return paginated(c, result.items, result.total, query.offset, query.limit);
});

languageLocales.get('/:id', async (c) => {
  const id = c.req.param('id');
  const result = await getExpression(c.env.DB, id);
  if (!result) {
    return c.json({ success: false, error: 'EXPRESSION_NOT_FOUND', message: 'Expression not found' }, 404);
  }
  return success(c, result);
});

languageLocales.post('/:id/locale-attestations', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const id = c.req.param('id');
    const body = await c.req.json().catch(() => ({}));
    const languageLocaleCode = typeof body?.language_locale_code === 'string' ? body.language_locale_code.trim() : '';
    if (!languageLocaleCode) {
      return badRequest(c, 'VALIDATION_FAILED', 'language_locale_code is required');
    }
    let source: { type: string; name: string; ref?: string } | undefined;
    if (body?.source != null) {
      const s = body.source;
      if (typeof s !== 'object' || s === null || typeof s.type !== 'string' || typeof s.name !== 'string') {
        return badRequest(c, 'INVALID_SOURCE', 'source requires type and name');
      }
      if (s.ref != null && typeof s.ref !== 'string') {
        return badRequest(c, 'INVALID_SOURCE', 'source ref must be a string');
      }
      source = { type: s.type, name: s.name };
      if (typeof s.ref === 'string') source.ref = s.ref;
    }
    try {
      const result = await createLocaleAttestation(c.env.DB, {
        expression_id: id,
        language_locale_code: languageLocaleCode,
        ...(source ? { source } : {}),
        created_by: user?.id ?? 0,
      });
      return result.created ? created(c, result, 'Attestation created') : success(c, result, 'Attestation already exists');
    } catch (error) {
      if (error instanceof ExpressionError) {
        if (error.code === 'EXPRESSION_NOT_FOUND') {
          return c.json({ success: false, error: error.code, message: 'Expression not found' }, 404);
        }
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Create attestation error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create attestation');
  }
});

export default languageLocales;
```

- [x] **Step 4: 在 `backend/src/routes/index.ts` 註冊**

完整新內容:

```ts
import { Hono } from 'hono';
import auth from './auth';
import expressions from './expressions';
import languageLocales from './languageLocales';
import languageRegistry from './languageRegistry';

const api = new Hono();
api.route('/auth', auth);
api.route('/language-registry', languageRegistry);
api.route('/language-locales', languageLocales);
api.route('/expressions', expressions);

export default api;
```

- [x] **Step 5: 等 wrangler hot-reload,重跑整合測試**

wrangler dev 會自動 reload `backend/src` 的變更;等 2–3 秒再跑:

```bash
cd backend && npx vitest run tests/expressionsIntegration.test.ts
```

Expected: 全部 PASS(10 個 it)。

- [x] **Step 6: 跑 type-check 確認無型別錯誤**

```bash
web/node_modules/.bin/tsc -p /tmp/tsconfig.langmap-backend-check.json
```

若 `/tmp/tsconfig.langmap-backend-check.json` 不存在,先建立(僅檢查 backend 檔案,不進 repo;把 routes/index.ts 的 import 鏈涵蓋進來即可):

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
    "/Users/lim/Documents/Code/tsunhua/langmap/backend/src/routes/expressions.ts",
    "/Users/lim/Documents/Code/tsunhua/langmap/backend/src/services/expressions.ts",
    "/Users/lim/Documents/Code/tsunhua/langmap/backend/src/services/expressionIdentity.ts"
  ]
}
```

Expected: 只可能出現 `utils/response.ts`(status: number 的 overload)與 `types.ts`(`D1Database` global)兩處**既有**錯誤;`expressions.ts`/`expressionIdentity.ts` 不得有新錯誤。

- [x] **Step 7: Commit**

```bash
git add backend/src/routes/expressions.ts backend/src/routes/index.ts backend/tests/expressionsIntegration.test.ts
git commit -m "feat(api): expose expression create, search, detail and attestation endpoints"
```

Commit 後 `git status --short` 應乾淨。

---

## Task 5: 全量回歸與收尾驗證

驗證整個 Plan 3 沒有破壞既有功能,並完成最終檢查。

**Files:** 無(若有修正在此提交)

- [x] **Step 1: 後端完整測試(已知既有失敗除外)**

worker 在 8788 的前提下:

```bash
cd backend && npm test
```

Expected: 所有 test file 通過,**除了** `auth.test.ts` 中 `reuses an existing expression ...`(呼叫 `/contributions/batch`,Plan 1 Task 1 起既有的 stale 測試,在 HEAD 上即壞,與本 plan 無關)——該失敗為已知,不回修、不改動 `auth.test.ts`。

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

Expected: 全部 OK(若 `test_generate.py` 改動 `manifest.json` 的 `generated_at`,恢復該 artifact 到 HEAD 使 tree 乾淨)。

- [x] **Step 3: 手動抽查新 API(rebuild 後)**

```bash
curl -s 'http://127.0.0.1:8788/api/v2/expressions/search?q=食' | python3 -m json.tool
```

Expected: 回分頁結構 `{ items, total, skip, limit, hasMore }`,items 依 `text ASC` 排序。

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

- §8.1 canonical text(trim + NFC、不轉小寫、不壓縮內部空白、空值拒絕)→ Task 2(canonicalize 測試)+ Task 3(空值 `VALIDATION_FAILED`)。
- §8.2 SHA-256/128/Base32 固定向量與 26 字元 grammar → Task 2(向量 `hello`、26 字元 regex、大小寫敏感)。
- §8.3 Base ID 與 `.2`／`.3` ID 格式 → Task 2(`buildExpressionId`);hash collision guard(比較完整文字、`EXPRESSION_HASH_COLLISION`、不 merge)→ Task 3。
- §8.4 `expressions` 表(全部欄位、`UNIQUE(lang,text,index)`、`UNIQUE(lang,hash,index)`、source_ref CHECK、FK languages/sources/users、無 PATCH)→ Task 1(schema)+ Task 3(service)。
- §9.1 `expression_locale_attestations` 表(UNIQUE 含 source provenance、FK)→ Task 1;service 層去重(含全 NULL)→ Task 3;attestation 排序與來源明細不丟失 → Task 3/4。
- §13.2 `POST /expressions`(lang_code/text/optional locale;200+`created=false`/201+`created=true`)、`GET /expressions/search`、`GET /expressions/:id`、`POST /expressions/:id/locale-attestations` → Task 4。
- §14 穩定錯誤碼:`INVALID_LANG_CODE`/`EXPRESSION_HASH_COLLISION`/`INVALID_LANGUAGE_LOCALE_CODE`/`EXPRESSION_NOT_FOUND`/`INVALID_SOURCE`/`VALIDATION_FAILED`;constraint error 映射而非暴露 → Task 3(service 拋 `ExpressionError`)+ Task 4(route 映射)。
- §17.1 Expression 建立／重用及 optional locale、多來源地域佐證去重與來源明細 → Task 3/4 測試。

**未覆蓋(留給後續 plan):** `expression_readings` 與 readings API(§9.2);`expression_edges`/`expression_splits` 與 mappings/split API(§10、`GET /:id/mappings`);votes 對 edge 的引用(§10.1);preferences(§11、§13.3);UI localization(§12、§13.4);前端(§15);`scripts/i18n` catalog 遷移(§16.6);`expressions_fts`/`handbooks` 等既有表維持現狀。

**2. Placeholder scan:** 每個 step 都有完整程式碼與可執行命令,無 TBD/「implement later」。integration test 的 BASE_URL 沿用既有慣例。fake D1 的 SQL key 與實作 SQL 逐字對應(若執行時因鍵字串差異失敗,以實作為準調整測試,已於 Task 3 Step 5 註明)。

**3. Type consistency:** `canonicalizeExpressionText`/`computeTextHash`/`buildExpressionId` 在 Task 2 定義、Task 3 import,參數與回傳型別一致;`ExpressionError`/`createExpression`/`searchExpressions`/`getExpression`/`createLocaleAttestation` 在 Task 3 定義、Task 4 import;`ExpressionRow`/`LocaleAttestationRow` 在 Task 3 Step 1 定義,欄位名稱與 `EXPRESSION_COLUMNS`/`ATTESTATION_COLUMNS` 字串一致;`paginated(c, items, total, skip, limit)` 呼叫順序與 helper 一致;`buildExpressionId` 的輸出(`nan:{hash}`)與整合測試的 `id.startsWith('nan:')` 一致。
