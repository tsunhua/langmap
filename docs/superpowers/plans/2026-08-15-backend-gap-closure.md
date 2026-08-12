# Backend Gap Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 補齊 spec 明確要求但 greenfield 重建（§16）遺漏的後端能力，讓 §15 前端有穩固地基：votes 表與 vote 端點、contribution batch、split 的 coverage 重算、workbench 的逐 key messages/candidates、以及 §15.4 的語言內容列表。

**Architecture:** 五個獨立缺口，依「schema → service → route」順序推進，彼此無耦合故可各自 review：(1) `votes` 表 + vote service/route，補回 §10 承諾的 vote 保留語義；(2) `contributions.ts` route，把既有 `createEdgesBatch` 暴露為 §13 的 batch 端點；(3) split step 7 接線，讓 `splitExpression` 完成後通知 localization service；(4) workbench 回應擴充為逐 key candidates，支撐 §15.5；(5) `languages.ts` route，提供「只含有內容的語言」列表與該語言的 expressions。

**Tech Stack:** Hono 4 + TypeScript + Cloudflare Workers + D1；Vitest；Python 3（migration lock 同步）。

## Global Constraints

- 本 plan 只補 spec 有依據的缺口。**handbook 與 feed 領域已由使用者裁定「延後」**，不在本 plan 範圍：不建表、不建 route、不修前端相關頁面。
- `votes` 表沿用舊 schema 的泛型 `(target_type, target_id)` 形狀，但 `target_id` 必須能承載 edge ID（ULID，TEXT）。Vote 只透過 localization service 通知受影響 locale（spec §5.3：「Mapping vote 只能透過此 service 通知受影響 locale，不得在 route 內複製 coverage SQL」）。
- Split step 7「重新計算受影響 UI Locale coverage／revision」（spec §10.2）必須實作；目前 `splits.ts` 完全沒有這段。
- 新增錯誤碼須併入 spec §14 表格（§14 寫「至少定義」，故擴充合規）：`VOTE_INVALID_VALUE`、`VOTE_TARGET_NOT_FOUND`、`CONTRIBUTION_TOO_FEW_EXPRESSIONS`、`UI_LOCALE_NOT_FOUND`、`UI_LOCALE_SYSTEM_LOCKED`（後兩者是 Plan 6 已實作但未登錄的）。
- migration 使用 `IF NOT EXISTS`；`backend/schema.sql` **不**使用 `IF NOT EXISTS`（repo 慣例）。兩者必須產生等價 schema。
- SQLite/D1：所有欄位定義在前，`CHECK`／`UNIQUE`／`FOREIGN KEY` 表級約束在後，否則 `near "xxx": syntax error`。
- Hono 4 是 `c.req.param('id')`（回傳 `string | undefined`，strict 下需 `?? ''`），**不是** `c.param('id')`。
- fake-D1 單元測試以 SQL 字串作為 handler 的**精確 key**，故 service 內所有 SQL 必須寫成**單行**，並抽成 module-level `const` 避免與測試漂移。參考 `backend/src/services/localizationDomain.ts` 的 `CANDIDATE_SQL` 作法。
- 不新增 `any`；新程式碼不加註解。不修改 `web/`、`apple/`。
- 列表查詢一律穩定排序 + 數量上限（spec §4.11）。
- 回應格式 `{ success, data?, error?, message? }`；列表用 `paginated(c, items, total, skip, limit)`。
- 單檔測試用 `cd backend && npx vitest run tests/<file>.test.ts`，**不用** `npm test`。
- wrangler 用 `backend/node_modules/.bin/wrangler`，**不用** `npx wrangler`。
- 整合測試依賴 `127.0.0.1:8788` worker + 已 rebuild 的本地 D1。
- 已知既有失敗，**不要修**：`auth.test.ts` × 1（呼叫本 plan Task 2 才會建立的 `/contributions/batch`——Task 2 完成後這個會自動變綠）、`expressionsIntegration.test.ts` × 2（locale `nan-Hant-CN`／`nan-Hant-TW` 未 seed）。

---

## File Structure

| 檔案 | 責任 | 動作 |
|---|---|---|
| `backend/migrations/0007_votes.sql` | `votes` 表 DDL | Create |
| `backend/schema.sql` | 與 0007 等價 | Modify |
| `backend/tests/schemaContract.test.ts` | 斷言 `votes` 表 | Modify |
| `scripts/db/migration-lock.json` | 記錄 0007 | Modify |
| `backend/src/services/votes.ts` | vote upsert／撤回、edge 存在性驗證、通知 localization | Create |
| `backend/tests/votes.test.ts` | vote service 單元測試 | Create |
| `backend/src/routes/contributions.ts` | `POST /contributions/batch` | Create |
| `backend/src/routes/index.ts` | 註冊 contributions、languages | Modify |
| `backend/src/services/localizationDomain.ts` | 新增 `recalculateForExpressions` | Modify |
| `backend/src/services/splits.ts` | step 7 接線 | Modify |
| `backend/src/services/workbench.ts` | 逐 key candidates 組裝 | Create |
| `backend/tests/workbench.test.ts` | workbench service 單元測試 | Create |
| `backend/src/routes/localization.ts` | workbench 回應擴充、vote 端點 | Modify |
| `backend/src/services/languageContent.ts` | 有內容的語言列表、語言的 expressions | Create |
| `backend/tests/languageContent.test.ts` | 單元測試 | Create |
| `backend/src/routes/languages.ts` | `GET /languages`、`GET /languages/:code`、`GET /languages/:code/expressions` | Create |
| `backend/tests/contributionsIntegration.test.ts` | batch + vote 整合測試 | Create |
| `backend/tests/languagesIntegration.test.ts` | languages 整合測試 | Create |
| `docs/superpowers/specs/2026-08-11-language-code-redesign-design.md` | §14 補錯誤碼 | Modify |

---

## Task 1: `votes` 表與 vote service

補回 spec §10 承諾的 vote 語義。Vote 以泛型 `(target_type, target_id)` 指向 edge ID，故 split 更換 edge 端點時 vote 自然不受影響（edge ID 不變）。

**Files:**
- Create: `backend/migrations/0007_votes.sql`
- Modify: `backend/schema.sql`、`backend/tests/schemaContract.test.ts`、`scripts/db/migration-lock.json`
- Create: `backend/src/services/votes.ts`、`backend/tests/votes.test.ts`

**Interfaces:**
- Consumes: `D1Database`。
- Produces:
  - `class VoteError extends Error { constructor(public code: string) }`
  - `castVote(db, input: { target_type: 'edge'; target_id: string; vote: number; user_id: number }): Promise<{ score: number; user_vote: number }>`
  - `getVoteScore(db, targetType: string, targetId: string): Promise<number>`

- [ ] **Step 1: 建立 migration 0007**

Create `backend/migrations/0007_votes.sql`:

```sql
-- Vote records referencing mapping edges by ID (spec 10.1).

CREATE TABLE IF NOT EXISTS votes (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  vote INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (target_type IN ('edge')),
  CHECK (vote IN (-1, 1)),
  UNIQUE (user_id, target_type, target_id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_votes_target ON votes (target_type, target_id);
```

注意：`CHECK (target_type IN ('edge'))` 目前只允許 edge，未來擴充再放寬。`vote` 只允許 ±1，撤回以刪除列表達。

- [ ] **Step 2: 更新 `backend/schema.sql`**

READ 當前檔案。在 DROP 區塊確認是否已有 `DROP TABLE IF EXISTS votes;`（舊 schema 遺留）。若有，保持原位不重複加；若無，加在 `DROP TABLE IF EXISTS users;` 之前。

在檔尾（`ui_messages` 的 INSERT 之後）新增（無 `IF NOT EXISTS`）：

```sql

-- Vote records referencing mapping edges by ID (spec 10.1).

CREATE TABLE votes (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  target_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  vote INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (target_type IN ('edge')),
  CHECK (vote IN (-1, 1)),
  UNIQUE (user_id, target_type, target_id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_votes_target ON votes (target_type, target_id);
```

- [ ] **Step 3: 更新 `backend/tests/schemaContract.test.ts`**

在 `does not contain obsolete identity tables` 之前新增：

```ts
  it('defines votes with generic target and bounded vote value', () => {
    expect(schema).toMatch(/CREATE TABLE votes[\s\S]*?target_id TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE votes[\s\S]*?CHECK \(vote IN \(-1, 1\)\)/s);
    expect(schema).toMatch(/CREATE TABLE votes[\s\S]*?UNIQUE \(user_id, target_type, target_id\)/s);
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
    print(entry['sequence'], entry['filename'])
EOF
```

Expected: 7 entries，第 7 筆是 `0007_votes.sql`。

- [ ] **Step 5: 寫失敗的 vote service 單元測試**

Create `backend/tests/votes.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { VoteError, castVote, getVoteScore } from '../src/services/votes';

type Handler = (args: unknown[]) => unknown;

function fakeD1(handlers: Record<string, Handler>) {
  const prepare = (sql: string) => {
    const handler = handlers[sql];
    return {
      bind(...args: unknown[]) {
        const run = async () => (handler ? handler(args) : { results: [] });
        return {
          async first<T>() { return (await run()) as T; },
          async run() { return handler ? await handler(args) : { success: true }; },
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

const EDGE_EXISTS_SQL = 'SELECT 1 FROM expression_edges WHERE id = ?';
const SCORE_SQL = 'SELECT COALESCE(SUM(vote), 0) AS score FROM votes WHERE target_type = ? AND target_id = ?';

describe('castVote', () => {
  it('rejects a vote value outside -1 and 1', async () => {
    const db = fakeD1({});
    await expect(
      castVote(db, { target_type: 'edge', target_id: 'e1', vote: 5, user_id: 1 }),
    ).rejects.toMatchObject({ code: 'VOTE_INVALID_VALUE' });
  });

  it('rejects a vote against a missing edge', async () => {
    const db = fakeD1({ [EDGE_EXISTS_SQL]: () => null });
    await expect(
      castVote(db, { target_type: 'edge', target_id: 'nope', vote: 1, user_id: 1 }),
    ).rejects.toMatchObject({ code: 'VOTE_TARGET_NOT_FOUND' });
  });

  it('returns the recomputed score after upserting a vote', async () => {
    const db = fakeD1({
      [EDGE_EXISTS_SQL]: () => ({ 1: 1 }),
      [SCORE_SQL]: () => ({ score: 3 }),
    });
    const result = await castVote(db, { target_type: 'edge', target_id: 'e1', vote: 1, user_id: 7 });
    expect(result.score).toBe(3);
    expect(result.user_vote).toBe(1);
  });
});

describe('getVoteScore', () => {
  it('returns 0 when there are no votes', async () => {
    const db = fakeD1({ [SCORE_SQL]: () => ({ score: 0 }) });
    expect(await getVoteScore(db, 'edge', 'e1')).toBe(0);
  });
});
```

- [ ] **Step 6: 跑測試確認失敗**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/votes.test.ts
```

Expected: FAIL（module not found）。

- [ ] **Step 7: 建立 `backend/src/services/votes.ts`**

```ts
import type { D1Database } from '@cloudflare/workers-types';

export class VoteError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'VoteError';
  }
}

const EDGE_EXISTS_SQL = 'SELECT 1 FROM expression_edges WHERE id = ?';

const SCORE_SQL = 'SELECT COALESCE(SUM(vote), 0) AS score FROM votes WHERE target_type = ? AND target_id = ?';

const UPSERT_SQL = 'INSERT INTO votes (id, user_id, target_type, target_id, vote) VALUES (?, ?, ?, ?, ?) ON CONFLICT(user_id, target_type, target_id) DO UPDATE SET vote = excluded.vote, updated_at = CURRENT_TIMESTAMP';

export async function getVoteScore(
  db: D1Database,
  targetType: string,
  targetId: string,
): Promise<number> {
  const row = await db
    .prepare(SCORE_SQL)
    .bind(targetType, targetId)
    .first<{ score: number }>();
  return row?.score ?? 0;
}

export async function castVote(
  db: D1Database,
  input: { target_type: 'edge'; target_id: string; vote: number; user_id: number },
): Promise<{ score: number; user_vote: number }> {
  if (input.vote !== 1 && input.vote !== -1) throw new VoteError('VOTE_INVALID_VALUE');

  const target = await db.prepare(EDGE_EXISTS_SQL).bind(input.target_id).first();
  if (!target) throw new VoteError('VOTE_TARGET_NOT_FOUND');

  await db
    .prepare(UPSERT_SQL)
    .bind(crypto.randomUUID(), input.user_id, input.target_type, input.target_id, input.vote)
    .run();

  const score = await getVoteScore(db, input.target_type, input.target_id);
  return { score, user_vote: input.vote };
}
```

- [ ] **Step 8: 跑測試確認通過**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/votes.test.ts tests/schemaContract.test.ts
```

Expected: votes 4 PASS；schemaContract 17 PASS（既有 16 + 新增 1）。

- [ ] **Step 9: Commit**

```bash
git add backend/migrations/0007_votes.sql backend/schema.sql backend/tests/schemaContract.test.ts scripts/db/migration-lock.json backend/src/services/votes.ts backend/tests/votes.test.ts
git commit -m "feat(db): add votes table and vote service"
```

---

## Task 2: Contribution batch route

`createEdgesBatch` 已存在於 `backend/src/services/mappings.ts`（Plan 4），但沒有 route 暴露它。spec §5.2 明列 `backend/src/routes/contributions.ts`，§17.1 要求「Contribution clique 與 duplicate pair reuse」，§18 人工驗收第 3 項是「Batch contribution 建立 clique」。

本 task 完成後，既有的 `backend/tests/auth.test.ts` 那 1 個已知失敗會自動變綠（它呼叫的正是 `/contributions/batch`）。

**Files:**
- Create: `backend/src/routes/contributions.ts`
- Modify: `backend/src/routes/index.ts`
- Create: `backend/tests/contributionsIntegration.test.ts`

**Interfaces:**
- Consumes: `createExpression`／`ExpressionError` from `services/expressions`；`createEdgesBatch`／`MappingError` from `services/mappings`；`recalculateForExpressions` 尚未存在（Task 3 才建），故本 task **不呼叫它**。
- Produces: `POST /api/v2/contributions/batch`。

- [ ] **Step 1: 建立 `backend/src/routes/contributions.ts`**

一次 batch = 多個 expression（每個可帶 optional locale）+ 它們之間的完全圖 edge。

```ts
import { Hono } from 'hono';
import { requireAuth } from '../middleware/auth';
import { badRequest, created, internalError, unauthorized } from '../utils/response';
import { ExpressionError, createExpression } from '../services/expressions';
import { MappingError, createEdgesBatch } from '../services/mappings';
import type { Bindings, Variables } from '../types';

const contributions = new Hono<{ Bindings: Bindings; Variables: Variables }>();

interface ExpressionInput {
  lang_code: string;
  text: string;
  language_locale_code?: string;
}

function parseExpressionInputs(raw: unknown): ExpressionInput[] {
  if (!Array.isArray(raw)) return [];
  const out: ExpressionInput[] = [];
  for (const item of raw) {
    const entry = item as { lang_code?: unknown; text?: unknown; language_locale_code?: unknown };
    const langCode = typeof entry?.lang_code === 'string' ? entry.lang_code.trim() : '';
    const text = typeof entry?.text === 'string' ? entry.text : '';
    if (!langCode || !text.trim()) continue;
    const localeCode = typeof entry?.language_locale_code === 'string' ? entry.language_locale_code.trim() : '';
    out.push({ lang_code: langCode, text, ...(localeCode ? { language_locale_code: localeCode } : {}) });
  }
  return out;
}

contributions.post('/batch', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (!user) return unauthorized(c);
    const body = await c.req.json().catch(() => ({}));
    const inputs = parseExpressionInputs((body as { expressions?: unknown })?.expressions);

    if (inputs.length < 2) {
      return badRequest(c, 'CONTRIBUTION_TOO_FEW_EXPRESSIONS', 'At least two valid expressions are required');
    }

    const expressionIds: string[] = [];
    const expressions: unknown[] = [];
    try {
      for (const input of inputs) {
        const result = await createExpression(c.env.DB, { ...input, created_by: user.id });
        expressionIds.push(result.expression.id);
        expressions.push({ expression: result.expression, created: result.created });
      }
    } catch (error) {
      if (error instanceof ExpressionError) return badRequest(c, error.code, error.code);
      throw error;
    }

    const uniqueIds = Array.from(new Set(expressionIds));
    if (uniqueIds.length < 2) {
      return badRequest(c, 'CONTRIBUTION_TOO_FEW_EXPRESSIONS', 'Expressions resolved to fewer than two distinct entries');
    }

    try {
      const edgeResult = await createEdgesBatch(c.env.DB, {
        expression_ids: uniqueIds,
        source: 'contribution',
        created_by: user.id,
      });
      return created(
        c,
        {
          expressions,
          edges: edgeResult.edges,
          created_edge_count: edgeResult.created_count,
        },
        'Contribution batch created',
      );
    } catch (error) {
      if (error instanceof MappingError) return badRequest(c, error.code, error.code);
      throw error;
    }
  } catch (error) {
    console.error('Contribution batch error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create contribution batch');
  }
});

export default contributions;
```

注意：`uniqueIds` 去重是必要的——兩個輸入可能 canonicalize 成同一個 Expression（重用），此時 `createEdgesBatch` 會因 `a === b` 拋 `VALIDATION_FAILED`。

- [ ] **Step 2: 在 `backend/src/routes/index.ts` 註冊**

READ current file。加入 import：

```ts
import contributions from './contributions';
```

並在 `api.route('/preferences', preferences);` 之後註冊：

```ts
api.route('/contributions', contributions);
```

- [ ] **Step 3: 寫整合測試**

Create `backend/tests/contributionsIntegration.test.ts`:

```ts
import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';

async function registerToken(): Promise<string> {
  const unique = Math.random().toString(36).slice(2, 10);
  const response = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: `contrib-${unique}`, email: `contrib-${unique}@example.com`, password: 'pass1234' }),
  });
  const body = (await response.json()) as { data: { token: string } };
  return body.data.token;
}

describe('contributions API', () => {
  it('requires auth', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ expressions: [] }),
    });
    expect(res.status).toBe(401);
  });

  it('rejects a batch with fewer than two expressions', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ expressions: [{ lang_code: 'eng', text: 'lonely' }] }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('CONTRIBUTION_TOO_FEW_EXPRESSIONS');
  });

  it('creates a clique from three expressions', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 8);
    const res = await fetch(`${BASE_URL}/api/v2/contributions/batch`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({
        expressions: [
          { lang_code: 'eng', text: `water-${unique}` },
          { lang_code: 'cmn', text: `水-${unique}` },
          { lang_code: 'nan', text: `水泉-${unique}` },
        ],
      }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as {
      data: { expressions: unknown[]; edges: unknown[]; created_edge_count: number };
    };
    expect(body.data.expressions).toHaveLength(3);
    expect(body.data.edges).toHaveLength(3);
    expect(body.data.created_edge_count).toBe(3);
  });

  it('reuses duplicate pairs on a repeated batch', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 8);
    const payload = {
      expressions: [
        { lang_code: 'eng', text: `reuse-${unique}` },
        { lang_code: 'cmn', text: `重用-${unique}` },
      ],
    };
    const post = () =>
      fetch(`${BASE_URL}/api/v2/contributions/batch`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify(payload),
      });

    const first = (await (await post()).json()) as { data: { created_edge_count: number } };
    const second = (await (await post()).json()) as { data: { created_edge_count: number } };
    expect(first.data.created_edge_count).toBe(1);
    expect(second.data.created_edge_count).toBe(0);
  });
});
```

- [ ] **Step 4: 確保 worker 在 8788 並跑整合測試**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8788/api/v2/auth/health
```

若非 200，啟動：

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && nohup node_modules/.bin/wrangler dev --config wrangler.jsonc --persist-to .wrangler/state --port 8788 > /tmp/langmap-worker-8788.log 2>&1 & disown
```

輪詢 health 到 200 後：

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/contributionsIntegration.test.ts
```

Expected: 4 PASS。連跑兩次都要 PASS（測試用隨機後綴，故天然冪等）。

- [ ] **Step 5: 確認 `auth.test.ts` 的既有失敗已修復**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/auth.test.ts
```

Expected: 全 PASS。這個 route 就是它缺的東西。若仍失敗，READ `tests/auth.test.ts:40-60` 看它送的 payload 形狀，並在報告中說明差異——**不要**為了讓它變綠而改測試。

- [ ] **Step 6: Commit**

```bash
git add backend/src/routes/contributions.ts backend/src/routes/index.ts backend/tests/contributionsIntegration.test.ts
git commit -m "feat(api): add contribution batch endpoint building expression cliques"
```

---

## Task 3: Split step 7 與 vote 的 coverage 重算接線

spec §10.2 step 7 是「重新計算受影響 UI Locale coverage／revision」，目前 `splits.ts` 完全沒有。spec §12.4 也要求「新增 translation mapping、mapping vote、UI message 啟用／退役、split edge move 都必須通知 localization service 重算」。spec §5.3 強調這只能經由 localization service，route 不得複製 coverage SQL。

**Files:**
- Modify: `backend/src/services/localizationDomain.ts`
- Modify: `backend/src/services/splits.ts`
- Modify: `backend/tests/localizationDomain.test.ts`
- Modify: `backend/src/routes/localization.ts`（新增 vote 端點）

**Interfaces:**
- Consumes: `castVote`／`VoteError` from Task 1 的 `services/votes`。
- Produces:
  - `recalculateForExpressions(db, projectId, expressionIds: string[]): Promise<void>` —— 由 expression ID 反查其 lang_code，找出該 project 下同 lang 的所有 UI locale，逐一 `recalculateLocale`。
  - `POST /api/v2/localization/projects/:projectId/votes`。

- [ ] **Step 1: 在 `localizationDomain.test.ts` 新增失敗測試**

在檔案的 import 行把 `recalculateForExpressions` 加進來：

```ts
import { LocalizationError, computeCoverage, recalculateForExpressions, resolveBundle } from '../src/services/localizationDomain';
```

在檔尾新增：

```ts
describe('recalculateForExpressions', () => {
  it('does nothing when the expression list is empty', async () => {
    let prepared = 0;
    const db = {
      prepare(_sql: string) {
        prepared++;
        return {
          bind() {
            return {
              async first() { return null; },
              async run() { return { success: true }; },
              async all() { return { results: [] }; },
            };
          },
        };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;
    await recalculateForExpressions(db, 'langmap-web', []);
    expect(prepared).toBe(0);
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/localizationDomain.test.ts
```

Expected: FAIL（`recalculateForExpressions is not a function`）。

- [ ] **Step 3: 在 `localizationDomain.ts` 實作 `recalculateForExpressions`**

READ 當前檔案。在 module-level SQL const 區塊（`CANDIDATE_SQL` 之後）加入：

```ts
const EXPRESSION_LANGS_SQL = 'SELECT DISTINCT lang_code FROM expressions WHERE id IN (SELECT value FROM json_each(?)) ORDER BY lang_code ASC';

const PROJECT_LOCALES_FOR_LANG_SQL = 'SELECT language_locale_code FROM ui_locales WHERE project_id = ? AND language_locale_code LIKE ? ORDER BY language_locale_code ASC LIMIT 200';
```

在 `recalculateLocale` 之後新增 exported function：

```ts
export async function recalculateForExpressions(
  db: D1Database,
  projectId: string,
  expressionIds: string[],
): Promise<void> {
  const unique = Array.from(new Set(expressionIds.filter((id) => id))).sort();
  if (unique.length === 0) return;

  const { results: langRows } = await db
    .prepare(EXPRESSION_LANGS_SQL)
    .bind(JSON.stringify(unique))
    .all<{ lang_code: string }>();

  const localeCodes = new Set<string>();
  for (const row of langRows) {
    const { results: localeRows } = await db
      .prepare(PROJECT_LOCALES_FOR_LANG_SQL)
      .bind(projectId, `${row.lang_code}-%`)
      .all<{ language_locale_code: string }>();
    for (const locale of localeRows) localeCodes.add(locale.language_locale_code);
  }

  for (const code of Array.from(localeCodes).sort()) {
    await recalculateLocale(db, projectId, code);
  }
}
```

注意：用 `json_each` 而非動態 `IN (?, ?, ?)`，避免 SQL 字串隨參數數量變動而破壞 fake-D1 的 key 比對。D1 支援 `json_each`。

- [ ] **Step 4: 跑測試確認通過**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/localizationDomain.test.ts
```

Expected: 4 PASS（既有 3 + 新增 1）。

- [ ] **Step 5: 在 `splits.ts` 接線 step 7**

READ `backend/src/services/splits.ts`。在檔首 import 區加入：

```ts
import { recalculateForExpressions } from './localizationDomain';
```

把函式簽名的 input 加上 optional project：

```ts
export async function splitExpression(
  db: D1Database,
  input: { source_expression_id: string; edge_ids: string[]; created_by: number; project_id?: string },
): Promise<{ split_id: string; target_expression_id: string; moved_edge_count: number }> {
```

在 `await db.batch(statements);` 的 try/catch **之後**、`return` **之前**插入：

```ts
  await recalculateForExpressions(db, input.project_id ?? 'langmap-web', [input.source_expression_id, targetId]);
```

注意 import 方向：`splits` → `localizationDomain` 是單向的（`localizationDomain` 不 import `splits`），無循環。

- [ ] **Step 6: 在 `localization.ts` 新增 vote 端點**

READ `backend/src/routes/localization.ts`。在 import 區加入：

```ts
import { VoteError, castVote } from '../services/votes';
```

並把 `recalculateForExpressions` 加進既有的 localizationDomain import 清單。

在 `export default localization;` 之前新增：

```ts
localization.post('/projects/:projectId/votes', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (!user) return unauthorized(c);
    const projectId = c.req.param('projectId') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const edgeId = typeof (body as { edge_id?: unknown })?.edge_id === 'string' ? (body as { edge_id: string }).edge_id.trim() : '';
    const voteRaw = (body as { vote?: unknown })?.vote;
    const vote = typeof voteRaw === 'number' ? voteRaw : Number(voteRaw);

    if (!edgeId) return badRequest(c, 'VALIDATION_FAILED', 'edge_id is required');

    try {
      const result = await castVote(c.env.DB, {
        target_type: 'edge',
        target_id: edgeId,
        vote,
        user_id: user.id,
      });

      const edge = await c.env.DB
        .prepare('SELECT expression_a_id, expression_b_id FROM expression_edges WHERE id = ?')
        .bind(edgeId)
        .first<{ expression_a_id: string; expression_b_id: string }>();
      if (edge) {
        await recalculateForExpressions(c.env.DB, projectId, [edge.expression_a_id, edge.expression_b_id]);
      }

      return success(c, result, 'Vote recorded');
    } catch (error) {
      if (error instanceof VoteError) {
        if (error.code === 'VOTE_TARGET_NOT_FOUND') return notFound(c, 'Edge');
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Vote error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to record vote');
  }
});
```

確認 `unauthorized` 已在該檔案的 response import 清單中；若無，加入。

- [ ] **Step 7: 跑相關測試**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/localizationDomain.test.ts tests/votes.test.ts tests/splits.test.ts tests/localizationIntegration.test.ts
```

Expected: 全 PASS。`splits.test.ts` 若使用 fake D1，新增的 `recalculateForExpressions` 呼叫會多打幾個 SQL；若該測試因此失敗，READ 它並在 fake handler 中補上 `EXPRESSION_LANGS_SQL` 回傳 `{ results: [] }` 即可（空結果讓重算變成 no-op）。**不要**移除 step 7 接線。

- [ ] **Step 8: Commit**

```bash
git add backend/src/services/localizationDomain.ts backend/src/services/splits.ts backend/tests/localizationDomain.test.ts backend/src/routes/localization.ts
git commit -m "feat(api): recalculate ui locale coverage after split and vote"
```

---
## Task 4: Workbench 逐 key messages 與 candidates

spec §15.5 要求 workbench 顯示逐 key 的 source text、既有翻譯與 fallback candidate，且「Fallback candidate 只用於預覽，不增加 coverage」。目前 `GET /workbench/:code` 只回 `{ locale, coverage }`，前端 `TranslateWorkbench.vue` 需要 `messages[]`（含 `candidates[]`）才能逐 key 編輯。

把 candidate 組裝抽成獨立 service，理由：`localizationDomain.loadCandidates` 只回 `Map<key, text>`（coverage 用），workbench 需要每個 key 的**多個** candidate 及其 `edge_id`／`score`／`target_expression_id`，責任不同故不擠進 `localizationDomain`。

**Files:**
- Create: `backend/src/services/workbench.ts`
- Create: `backend/tests/workbench.test.ts`
- Modify: `backend/src/routes/localization.ts`
- Modify: `backend/tests/localizationIntegration.test.ts`

**Interfaces:**
- Consumes: `computeCoverage` from `services/localizationDomain`。
- Produces:

```ts
export interface WorkbenchCandidate {
  edge_id: string;
  target_expression_id: string;
  text: string;
  score: number;
  created_at: string;
  placeholders_ok: boolean;
}

export interface WorkbenchMessage {
  key: string;
  source_expression_id: string;
  source_text: string;
  placeholders: string[];
  candidates: WorkbenchCandidate[];
}

export async function loadWorkbenchMessages(
  db: D1Database,
  projectId: string,
  languageLocaleCode: string,
  options: { limit: number; offset: number; q?: string },
): Promise<{ items: WorkbenchMessage[]; total: number }>
```

- [ ] **Step 1: 寫 `backend/tests/workbench.test.ts`（失敗測試）**

沿用 `backend/tests/localizationDomain.test.ts` 的 `fakeD1` helper（複製那 20 行，不要 export 跨檔共用——測試 helper 重複優於耦合）。

```ts
import { describe, expect, it } from 'vitest';
import { loadWorkbenchMessages } from '../src/services/workbench';

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

const COUNT_SQL = 'SELECT COUNT(*) AS total FROM ui_messages WHERE project_id = ? AND status = ? AND (? = \'\' OR message_key LIKE ? ESCAPE \'\\\' OR source_text LIKE ? ESCAPE \'\\\')';
const PAGE_SQL = 'SELECT message_key, source_expression_id, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? AND (? = \'\' OR message_key LIKE ? ESCAPE \'\\\' OR source_text LIKE ? ESCAPE \'\\\') ORDER BY message_key ASC LIMIT ? OFFSET ?';
const LANG_SQL = 'SELECT lang_code FROM language_locales WHERE code = ?';
const CANDIDATES_SQL = 'SELECT m.message_key, m.placeholders_json, t.id AS target_id, t.text AS target_text, e.id AS edge_id, e.score, e.created_at FROM ui_messages m JOIN expression_edges e ON e.expression_a_id = m.source_expression_id OR e.expression_b_id = m.source_expression_id JOIN expressions t ON t.id = CASE WHEN e.expression_a_id = m.source_expression_id THEN e.expression_b_id ELSE e.expression_a_id END WHERE m.project_id = ? AND m.status = ? AND m.message_key IN (SELECT value FROM json_each(?)) AND t.lang_code = ? AND EXISTS (SELECT 1 FROM expression_locale_attestations WHERE expression_id = t.id AND language_locale_code = ?) ORDER BY m.message_key ASC, e.score DESC, e.created_at ASC, t.id ASC LIMIT 500';

describe('loadWorkbenchMessages', () => {
  it('returns messages with empty candidates when the locale has no language row', async () => {
    const db = fakeD1({
      [COUNT_SQL]: () => ({ total: 1 }),
      [PAGE_SQL]: () => ({ results: [{ message_key: 'common.cancel', source_expression_id: 'eng:x1', source_text: 'Cancel', placeholders_json: '[]' }] }),
      [LANG_SQL]: () => null,
    });
    const result = await loadWorkbenchMessages(db, 'langmap-web', 'zzz-Zzzz-ZZ', { limit: 20, offset: 0 });
    expect(result.total).toBe(1);
    expect(result.items[0].key).toBe('common.cancel');
    expect(result.items[0].candidates).toEqual([]);
  });

  it('attaches ordered candidates and flags placeholder mismatches', async () => {
    const db = fakeD1({
      [COUNT_SQL]: () => ({ total: 2 }),
      [PAGE_SQL]: () => ({
        results: [
          { message_key: 'a.key', source_expression_id: 'eng:a', source_text: 'Hello {name}', placeholders_json: '["name"]' },
          { message_key: 'b.key', source_expression_id: 'eng:b', source_text: 'World', placeholders_json: '[]' },
        ],
      }),
      [LANG_SQL]: () => ({ lang_code: 'cmn' }),
      [CANDIDATES_SQL]: () => ({
        results: [
          { message_key: 'a.key', placeholders_json: '["name"]', target_id: 'cmn:a1', target_text: '你好 {name}', edge_id: 'e1', score: 3, created_at: '2026-01-01' },
          { message_key: 'a.key', placeholders_json: '["name"]', target_id: 'cmn:a2', target_text: '哈囉', edge_id: 'e2', score: 1, created_at: '2026-01-02' },
        ],
      }),
    });
    const result = await loadWorkbenchMessages(db, 'langmap-web', 'cmn-Hant-TW', { limit: 20, offset: 0 });
    expect(result.items[0].candidates.map((candidate) => candidate.edge_id)).toEqual(['e1', 'e2']);
    expect(result.items[0].candidates[0].placeholders_ok).toBe(true);
    expect(result.items[0].candidates[1].placeholders_ok).toBe(false);
    expect(result.items[0].placeholders).toEqual(['name']);
    expect(result.items[1].candidates).toEqual([]);
  });

  it('does not query candidates when the page is empty', async () => {
    const seen: string[] = [];
    const db = {
      prepare(sql: string) {
        seen.push(sql);
        return {
          bind() {
            return {
              async first() { return { total: 0 }; },
              async run() { return { success: true }; },
              async all() { return { results: [] }; },
            };
          },
        };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;
    const result = await loadWorkbenchMessages(db, 'langmap-web', 'cmn-Hant-TW', { limit: 20, offset: 0 });
    expect(result.items).toEqual([]);
    expect(seen.some((sql) => sql.includes('json_each'))).toBe(false);
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/workbench.test.ts
```

Expected: FAIL（`Failed to resolve import "../src/services/workbench"`）。

- [ ] **Step 3: 建立 `backend/src/services/workbench.ts`**

所有 SQL 寫成**單行** module-level const，與 Step 1 測試的 key 逐字一致。`escapeLike` 沿用 `services/languageIdentity`（既有 export，見 `languageIdentity.ts:41`），LIKE 一律帶 `ESCAPE '\'`（repo 既有慣例，見 `expressions.ts:73`）。

```ts
import type { D1Database } from '@cloudflare/workers-types';
import { escapeLike } from './languageIdentity';

export interface WorkbenchCandidate {
  edge_id: string;
  target_expression_id: string;
  text: string;
  score: number;
  created_at: string;
  placeholders_ok: boolean;
}

export interface WorkbenchMessage {
  key: string;
  source_expression_id: string;
  source_text: string;
  placeholders: string[];
  candidates: WorkbenchCandidate[];
}

interface MessageRow {
  message_key: string;
  source_expression_id: string;
  source_text: string;
  placeholders_json: string;
}

interface CandidateRow {
  message_key: string;
  placeholders_json: string;
  target_id: string;
  target_text: string;
  edge_id: string;
  score: number;
  created_at: string;
}

const CANDIDATES_PER_PAGE_LIMIT = 500;
const CANDIDATES_PER_KEY_LIMIT = 5;

const COUNT_SQL = "SELECT COUNT(*) AS total FROM ui_messages WHERE project_id = ? AND status = ? AND (? = '' OR message_key LIKE ? ESCAPE '\\' OR source_text LIKE ? ESCAPE '\\')";

const PAGE_SQL = "SELECT message_key, source_expression_id, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? AND (? = '' OR message_key LIKE ? ESCAPE '\\' OR source_text LIKE ? ESCAPE '\\') ORDER BY message_key ASC LIMIT ? OFFSET ?";

const LANG_SQL = 'SELECT lang_code FROM language_locales WHERE code = ?';

const CANDIDATES_SQL = `SELECT m.message_key, m.placeholders_json, t.id AS target_id, t.text AS target_text, e.id AS edge_id, e.score, e.created_at FROM ui_messages m JOIN expression_edges e ON e.expression_a_id = m.source_expression_id OR e.expression_b_id = m.source_expression_id JOIN expressions t ON t.id = CASE WHEN e.expression_a_id = m.source_expression_id THEN e.expression_b_id ELSE e.expression_a_id END WHERE m.project_id = ? AND m.status = ? AND m.message_key IN (SELECT value FROM json_each(?)) AND t.lang_code = ? AND EXISTS (SELECT 1 FROM expression_locale_attestations WHERE expression_id = t.id AND language_locale_code = ?) ORDER BY m.message_key ASC, e.score DESC, e.created_at ASC, t.id ASC LIMIT ${CANDIDATES_PER_PAGE_LIMIT}`;

function parsePlaceholders(placeholdersJson: string): string[] {
  try {
    const parsed: unknown = JSON.parse(placeholdersJson);
    return Array.isArray(parsed) ? (parsed as string[]).slice().sort() : [];
  } catch {
    return [];
  }
}

function extractPlaceholders(text: string): string[] {
  return Array.from(text.matchAll(/\{(\w+)\}/g)).map((match) => match[1]).sort();
}

export async function loadWorkbenchMessages(
  db: D1Database,
  projectId: string,
  languageLocaleCode: string,
  options: { limit: number; offset: number; q?: string },
): Promise<{ items: WorkbenchMessage[]; total: number }> {
  const q = (options.q ?? '').trim();
  const like = q ? `%${escapeLike(q)}%` : '';

  const totalRow = await db
    .prepare(COUNT_SQL)
    .bind(projectId, 'active', q, like, like)
    .first<{ total: number }>();
  const total = totalRow?.total ?? 0;

  const { results: messageRows } = await db
    .prepare(PAGE_SQL)
    .bind(projectId, 'active', q, like, like, options.limit, options.offset)
    .all<MessageRow>();

  const items: WorkbenchMessage[] = messageRows.map((row) => ({
    key: row.message_key,
    source_expression_id: row.source_expression_id,
    source_text: row.source_text,
    placeholders: parsePlaceholders(row.placeholders_json),
    candidates: [],
  }));

  if (items.length === 0) return { items, total };

  const langRow = await db
    .prepare(LANG_SQL)
    .bind(languageLocaleCode)
    .first<{ lang_code: string }>();
  if (!langRow) return { items, total };

  const keys = items.map((item) => item.key);
  const { results: candidateRows } = await db
    .prepare(CANDIDATES_SQL)
    .bind(projectId, 'active', JSON.stringify(keys), langRow.lang_code, languageLocaleCode)
    .all<CandidateRow>();

  const byKey = new Map(items.map((item) => [item.key, item]));
  for (const row of candidateRows) {
    const item = byKey.get(row.message_key);
    if (!item) continue;
    if (item.candidates.length >= CANDIDATES_PER_KEY_LIMIT) continue;
    item.candidates.push({
      edge_id: row.edge_id,
      target_expression_id: row.target_id,
      text: row.target_text,
      score: row.score,
      created_at: row.created_at,
      placeholders_ok:
        JSON.stringify(parsePlaceholders(row.placeholders_json)) === JSON.stringify(extractPlaceholders(row.target_text)),
    });
  }

  return { items, total };
}
```

設計說明（不寫進程式碼註解，只在 plan 說明給 reviewer）：

- candidate 查詢與 `localizationDomain.CANDIDATE_SQL` 的差異是刻意的：這裡**不**過濾 `e.score >= 0`、**不**丟棄 placeholder 不符的 candidate，而是以 `placeholders_ok` 旗標交給前端顯示警示。coverage 仍由 `computeCoverage` 獨立計算，所以「fallback candidate 只用於預覽，不增加 coverage」（spec §15.5）成立。
- `json_each` 使 SQL 字串不隨 key 數量變動，保住 fake-D1 的精確 key 比對（Global Constraints）。
- 兩層上限：整頁 500 列 + 每 key 5 個，避免熱門 key 的 candidate 撐爆回應（spec §4.11）。

- [ ] **Step 4: 跑測試確認通過**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/workbench.test.ts
```

Expected: 3 PASS。若 SQL key 不匹配會表現為 `total` 為 0 或 `candidates` 為空——此時**逐字**比對測試常數與 service 常數，不要改寬測試。

- [ ] **Step 5: 擴充 `GET /workbench/:code` 回應**

READ `backend/src/routes/localization.ts`。在 import 區加入：

```ts
import { loadWorkbenchMessages } from '../services/workbench';
```

把既有的 workbench handler（`localization.get('/projects/:projectId/workbench/:code', ...)`）body 換成：

```ts
  try {
    const projectId = c.req.param('projectId') ?? '';
    const code = c.req.param('code') ?? '';
    const locale = await c.env.DB
      .prepare('SELECT status, mapping_revision, activation_source FROM ui_locales WHERE project_id = ? AND language_locale_code = ?')
      .bind(projectId, code)
      .first<{ status: string; mapping_revision: number; activation_source: string | null }>();
    if (!locale) return notFound(c, 'UI locale');
    const coverage = await computeCoverage(c.env.DB, projectId, code);
    const query = parseWorkbenchQuery(c);
    const messages = await loadWorkbenchMessages(c.env.DB, projectId, code, {
      limit: query.limit,
      offset: query.offset,
      q: query.q,
    });
    return success(c, {
      locale,
      coverage,
      messages: messages.items,
      total: messages.total,
      skip: query.offset,
      limit: query.limit,
    });
  } catch (error) {
    console.error('Workbench error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to load workbench');
  }
```

**不要**用 `parseReferenceQuery`：它把 limit 硬夾在 `MAX_LIMIT = 50`（見 `services/languageIdentity.ts:23`），而 workbench 有 314 個 key，每頁 50 會讓前端得翻 7 頁。改在 `localization.ts` 檔首自備解析器：

```ts
const WORKBENCH_PAGE_LIMIT = 100;
const WORKBENCH_MAX_LIMIT = 200;
const WORKBENCH_MAX_Q = 80;

function parseWorkbenchQuery(c: { req: { query: (key: string) => string | undefined } }): { q: string; limit: number; offset: number } {
  const limitRaw = Number(c.req.query('limit') ?? String(WORKBENCH_PAGE_LIMIT));
  const limit = Math.min(Math.max(Number.isFinite(limitRaw) ? Math.trunc(limitRaw) : WORKBENCH_PAGE_LIMIT, 1), WORKBENCH_MAX_LIMIT);
  const offset = Math.max(parseInt(c.req.query('skip') ?? c.req.query('offset') ?? '0') || 0, 0);
  return { q: (c.req.query('q') ?? '').slice(0, WORKBENCH_MAX_Q), limit, offset };
}
```

放在既有 `const LOCALE_LIST_LIMIT = 200;` 之後。上限仍存在（200），故未違反 spec §4.11。

注意兩點：

1. **不用** `paginated()`：這個端點回的是複合物件（locale + coverage + messages），不是純列表；`paginated` 會把 `locale`／`coverage` 擠掉。分頁欄位手動附在 data 內。
2. 既有整合測試 `gets workbench coverage for a locale` 斷言 `body.data.locale.status` 與 `body.data.coverage.*`，這些鍵未變動，故該測試必須**繼續通過**——若它壞了，是你改壞了形狀。

- [ ] **Step 6: 在 `localizationIntegration.test.ts` 新增整合測試**

在 `describe('localization API', ...)` 內、既有 workbench 測試之後新增：

```ts
  it('returns paged workbench messages with candidate slots', async () => {
    const token = await registerToken();
    const createStatus = await ensureLocale(token, 'cmn-Hans-CN');
    expect([201, 400]).toContain(createStatus);
    const res = await fetch(`${API}/workbench/cmn-Hans-CN?limit=5`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: {
        total: number;
        limit: number;
        skip: number;
        messages: Array<{ key: string; source_text: string; placeholders: string[]; candidates: unknown[] }>;
      };
    };
    expect(body.data.limit).toBe(5);
    expect(body.data.skip).toBe(0);
    expect(body.data.total).toBeGreaterThan(5);
    expect(body.data.messages).toHaveLength(5);
    const keys = body.data.messages.map((m) => m.key);
    expect([...keys].sort()).toEqual(keys);
    expect(Array.isArray(body.data.messages[0].candidates)).toBe(true);
  });

  it('filters workbench messages by query', async () => {
    const token = await registerToken();
    await ensureLocale(token, 'cmn-Hans-CN');
    const res = await fetch(`${API}/workbench/cmn-Hans-CN?q=cancel&limit=50`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { messages: Array<{ key: string; source_text: string }> } };
    expect(body.data.messages.length).toBeGreaterThan(0);
    for (const message of body.data.messages) {
      expect(`${message.key} ${message.source_text}`.toLowerCase()).toContain('cancel');
    }
  });
```

- [ ] **Step 7: 跑測試**

worker 必須在 `127.0.0.1:8788` 執行。

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/workbench.test.ts tests/localizationIntegration.test.ts tests/localizationDomain.test.ts
```

Expected: workbench 3 PASS、localizationDomain 4 PASS、localizationIntegration 18 PASS（既有 16 + 新增 2）。連跑兩次確認**幂等**——第二次仍須全綠（測試不得依賴首次建立的 locale 狀態）。

- [ ] **Step 8: Commit**

```bash
git add backend/src/services/workbench.ts backend/tests/workbench.test.ts backend/src/routes/localization.ts backend/tests/localizationIntegration.test.ts
git commit -m "feat(api): return paged workbench messages with translation candidates"
```

---
## Task 5: 有內容的語言列表與語言內容 route

spec §15.4：「Language List 只顯示已有 Expression、Language Locale 或 active UI Locale 的語言，不把完整 ISO registry 當內容列表。」現況 `GET /language-registry/languages` 回的是完整 ISO 639-3 registry（約 8 千列），語義與此**相反**；前端 `useLanguages.list/detail/expressions` 呼叫的 `/languages`、`/languages/:code`、`/languages/:code/expressions` 三個端點在 greenfield 重建後**完全不存在**。

Language Detail 需 `name_en`、`name`（本地名稱）、Language Locales、Expression／reading 數與地圖點。座標優先用 locale coordinate，缺少時退回 region representative coordinate 並**清楚標示**，無任何座標的 locale 仍須出現在列表（spec §15.4）。故每個 locale 回傳 `coordinate_source: 'locale' | 'region' | null`，由前端據此標示，後端不隱藏無座標 locale。

**Files:**
- Create: `backend/src/services/languageContent.ts`
- Create: `backend/tests/languageContent.test.ts`
- Create: `backend/src/routes/languages.ts`
- Create: `backend/tests/languagesIntegration.test.ts`
- Modify: `backend/src/routes/index.ts`

**Interfaces:**
- Consumes: `escapeLike`、`parseReferenceQuery` from `services/languageIdentity`；`paginated`、`success`、`notFound` from `utils/response`。
- Produces:

```ts
export interface LanguageContentSummary {
  code: string;
  name_en: string;
  name: string;
  expression_count: number;
  locale_count: number;
  active_ui_locale_count: number;
}

export interface LanguageLocaleSummary {
  code: string;
  name: string;
  name_en: string;
  script_code: string;
  region_code: string;
  place_path: string;
  latitude: number | null;
  longitude: number | null;
  coordinate_source: 'locale' | 'region' | null;
}

export interface LanguageDetail {
  code: string;
  name_en: string;
  name: string;
  expression_count: number;
  reading_count: number;
  locales: LanguageLocaleSummary[];
}

export async function listLanguagesWithContent(db, query: { q: string; limit: number; offset: number }): Promise<{ items: LanguageContentSummary[]; total: number }>
export async function getLanguageDetail(db, code: string): Promise<LanguageDetail | null>
export async function listLanguageExpressions(db, code: string, query: { q: string; limit: number; offset: number }): Promise<{ items: ExpressionRow[]; total: number } | null>
```

`name` 的定義：該語言底下 `language_locales` 依 `code ASC` 排序的第一個 `name`（本地名稱）；無 locale 時退回 `name_en`。這是刻意的簡化——spec 未在 `languages` 表定義 endonym 欄位，而 `language_locales.name` 是唯一可得的本地名稱來源。

- [ ] **Step 1: 寫 `backend/tests/languageContent.test.ts`（失敗測試）**

複製前述 `fakeD1` helper，並用單行 SQL 常數作為 key。

```ts
import { describe, expect, it } from 'vitest';
import { getLanguageDetail, listLanguageExpressions, listLanguagesWithContent } from '../src/services/languageContent';

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

const LANGUAGE_ROW_SQL = 'SELECT code, name_en FROM languages WHERE code = ?';
const LANGUAGE_LOCALES_SQL = "SELECT l.code, l.name, l.name_en, l.script_code, l.region_code, l.place_path, l.latitude AS locale_latitude, l.longitude AS locale_longitude, r.latitude AS region_latitude, r.longitude AS region_longitude FROM language_locales l LEFT JOIN regions r ON r.code = l.region_code WHERE l.lang_code = ? ORDER BY l.code ASC LIMIT 500";
const EXPRESSION_COUNT_SQL = 'SELECT COUNT(*) AS total FROM expressions WHERE lang_code = ?';
const READING_COUNT_SQL = 'SELECT COUNT(*) AS total FROM expression_readings WHERE expression_id IN (SELECT id FROM expressions WHERE lang_code = ?)';

describe('getLanguageDetail', () => {
  it('returns null for an unknown language code', async () => {
    const db = fakeD1({ [LANGUAGE_ROW_SQL]: () => null });
    expect(await getLanguageDetail(db, 'zzz')).toBeNull();
  });

  it('labels locale, region and missing coordinates', async () => {
    const db = fakeD1({
      [LANGUAGE_ROW_SQL]: () => ({ code: 'cmn', name_en: 'Mandarin Chinese' }),
      [LANGUAGE_LOCALES_SQL]: () => ({
        results: [
          { code: 'cmn-Hans-CN', name: '简体中文', name_en: 'Simplified Chinese', script_code: 'Hans', region_code: 'CN', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: null, region_longitude: null },
          { code: 'cmn-Hant-TW', name: '臺灣華語', name_en: 'Taiwan Mandarin', script_code: 'Hant', region_code: 'TW', place_path: '', locale_latitude: null, locale_longitude: null, region_latitude: 23.7, region_longitude: 121.0 },
          { code: 'cmn-Hant-TW-tainan', name: '臺南話', name_en: 'Tainan Mandarin', script_code: 'Hant', region_code: 'TW', place_path: 'tainan', locale_latitude: 22.99, locale_longitude: 120.2, region_latitude: 23.7, region_longitude: 121.0 },
        ],
      }),
      [EXPRESSION_COUNT_SQL]: () => ({ total: 7 }),
      [READING_COUNT_SQL]: () => ({ total: 2 }),
    });
    const detail = await getLanguageDetail(db, 'cmn');
    expect(detail!.name).toBe('简体中文');
    expect(detail!.expression_count).toBe(7);
    expect(detail!.reading_count).toBe(2);
    expect(detail!.locales.map((locale) => locale.coordinate_source)).toEqual([null, 'region', 'locale']);
    expect(detail!.locales[2].latitude).toBe(22.99);
    expect(detail!.locales[1].latitude).toBe(23.7);
    expect(detail!.locales[0].latitude).toBeNull();
  });
});

describe('listLanguagesWithContent', () => {
  it('returns paged summaries', async () => {
    const rows = [
      { code: 'cmn', name_en: 'Mandarin Chinese', name: '臺灣華語', expression_count: 3, locale_count: 2, active_ui_locale_count: 1 },
      { code: 'eng', name_en: 'English', name: 'English (US)', expression_count: 300, locale_count: 1, active_ui_locale_count: 1 },
    ];
    const db = {
      prepare(sql: string) {
        return {
          bind() {
            return {
              async first() { return { total: 2 }; },
              async run() { return { success: true }; },
              async all() { return { results: sql.includes('COUNT(*) AS total FROM (') ? [] : rows }; },
            };
          },
        };
      },
    } as unknown as import('@cloudflare/workers-types').D1Database;
    const result = await listLanguagesWithContent(db, { q: '', limit: 20, offset: 0 });
    expect(result.total).toBe(2);
    expect(result.items.map((item) => item.code)).toEqual(['cmn', 'eng']);
  });
});

describe('listLanguageExpressions', () => {
  it('returns null when the language does not exist', async () => {
    const db = fakeD1({ [LANGUAGE_ROW_SQL]: () => null });
    expect(await listLanguageExpressions(db, 'zzz', { q: '', limit: 20, offset: 0 })).toBeNull();
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/languageContent.test.ts
```

Expected: FAIL（無法解析 `../src/services/languageContent`）。

- [ ] **Step 3: 建立 `backend/src/services/languageContent.ts`**

```ts
import type { D1Database } from '@cloudflare/workers-types';
import { escapeLike } from './languageIdentity';

export interface LanguageContentSummary {
  code: string;
  name_en: string;
  name: string;
  expression_count: number;
  locale_count: number;
  active_ui_locale_count: number;
}

export interface LanguageLocaleSummary {
  code: string;
  name: string;
  name_en: string;
  script_code: string;
  region_code: string;
  place_path: string;
  latitude: number | null;
  longitude: number | null;
  coordinate_source: 'locale' | 'region' | null;
}

export interface LanguageDetail {
  code: string;
  name_en: string;
  name: string;
  expression_count: number;
  reading_count: number;
  locales: LanguageLocaleSummary[];
}

export interface LanguageExpressionRow {
  id: string;
  lang_code: string;
  text: string;
  description: string;
  homograph_index: number;
  review_status: string;
  created_at: string;
  reading_count: number;
  mapping_count: number;
}

interface LocaleRow {
  code: string;
  name: string;
  name_en: string;
  script_code: string;
  region_code: string;
  place_path: string;
  locale_latitude: number | null;
  locale_longitude: number | null;
  region_latitude: number | null;
  region_longitude: number | null;
}

const LOCALE_LIST_LIMIT = 500;

const CONTENT_LANGUAGES_SELECT = "SELECT g.code AS code, g.name_en AS name_en, COALESCE((SELECT l2.name FROM language_locales l2 WHERE l2.lang_code = g.code ORDER BY l2.code ASC LIMIT 1), g.name_en) AS name, (SELECT COUNT(*) FROM expressions e WHERE e.lang_code = g.code) AS expression_count, (SELECT COUNT(*) FROM language_locales l3 WHERE l3.lang_code = g.code) AS locale_count, (SELECT COUNT(*) FROM ui_locales u JOIN language_locales l4 ON l4.code = u.language_locale_code WHERE l4.lang_code = g.code AND u.status = 'active') AS active_ui_locale_count FROM languages g WHERE (EXISTS (SELECT 1 FROM expressions e2 WHERE e2.lang_code = g.code) OR EXISTS (SELECT 1 FROM language_locales l5 WHERE l5.lang_code = g.code)) AND (? = '' OR g.code LIKE ? ESCAPE '\\' OR g.name_en LIKE ? ESCAPE '\\')";

const CONTENT_LANGUAGES_COUNT_SQL = `SELECT COUNT(*) AS total FROM (${CONTENT_LANGUAGES_SELECT})`;

const CONTENT_LANGUAGES_PAGE_SQL = `${CONTENT_LANGUAGES_SELECT} ORDER BY expression_count DESC, code ASC LIMIT ? OFFSET ?`;

const LANGUAGE_ROW_SQL = 'SELECT code, name_en FROM languages WHERE code = ?';

const LANGUAGE_LOCALES_SQL = `SELECT l.code, l.name, l.name_en, l.script_code, l.region_code, l.place_path, l.latitude AS locale_latitude, l.longitude AS locale_longitude, r.latitude AS region_latitude, r.longitude AS region_longitude FROM language_locales l LEFT JOIN regions r ON r.code = l.region_code WHERE l.lang_code = ? ORDER BY l.code ASC LIMIT ${LOCALE_LIST_LIMIT}`;

const EXPRESSION_COUNT_SQL = 'SELECT COUNT(*) AS total FROM expressions WHERE lang_code = ?';

const READING_COUNT_SQL = 'SELECT COUNT(*) AS total FROM expression_readings WHERE expression_id IN (SELECT id FROM expressions WHERE lang_code = ?)';

const LANGUAGE_EXPRESSIONS_COUNT_SQL = "SELECT COUNT(*) AS total FROM expressions WHERE lang_code = ? AND (? = '' OR text LIKE ? ESCAPE '\\')";

const LANGUAGE_EXPRESSIONS_PAGE_SQL = "SELECT e.id, e.lang_code, e.text, e.description, e.homograph_index, e.review_status, e.created_at, (SELECT COUNT(*) FROM expression_readings r WHERE r.expression_id = e.id) AS reading_count, (SELECT COUNT(*) FROM expression_edges g WHERE g.expression_a_id = e.id OR g.expression_b_id = e.id) AS mapping_count FROM expressions e WHERE e.lang_code = ? AND (? = '' OR e.text LIKE ? ESCAPE '\\') ORDER BY e.text ASC, e.homograph_index ASC, e.id ASC LIMIT ? OFFSET ?";

function resolveCoordinate(row: LocaleRow): Pick<LanguageLocaleSummary, 'latitude' | 'longitude' | 'coordinate_source'> {
  if (row.locale_latitude !== null && row.locale_longitude !== null) {
    return { latitude: row.locale_latitude, longitude: row.locale_longitude, coordinate_source: 'locale' };
  }
  if (row.region_latitude !== null && row.region_longitude !== null) {
    return { latitude: row.region_latitude, longitude: row.region_longitude, coordinate_source: 'region' };
  }
  return { latitude: null, longitude: null, coordinate_source: null };
}

export async function listLanguagesWithContent(
  db: D1Database,
  query: { q: string; limit: number; offset: number },
): Promise<{ items: LanguageContentSummary[]; total: number }> {
  const q = query.q.trim();
  const like = q ? `%${escapeLike(q)}%` : '';

  const totalRow = await db
    .prepare(CONTENT_LANGUAGES_COUNT_SQL)
    .bind(q, like, like)
    .first<{ total: number }>();

  const { results } = await db
    .prepare(CONTENT_LANGUAGES_PAGE_SQL)
    .bind(q, like, like, query.limit, query.offset)
    .all<LanguageContentSummary>();

  return { items: results, total: totalRow?.total ?? 0 };
}

export async function getLanguageDetail(db: D1Database, code: string): Promise<LanguageDetail | null> {
  const language = await db
    .prepare(LANGUAGE_ROW_SQL)
    .bind(code)
    .first<{ code: string; name_en: string }>();
  if (!language) return null;

  const { results: localeRows } = await db
    .prepare(LANGUAGE_LOCALES_SQL)
    .bind(code)
    .all<LocaleRow>();

  const expressionCount = await db.prepare(EXPRESSION_COUNT_SQL).bind(code).first<{ total: number }>();
  const readingCount = await db.prepare(READING_COUNT_SQL).bind(code).first<{ total: number }>();

  const locales: LanguageLocaleSummary[] = localeRows.map((row) => ({
    code: row.code,
    name: row.name,
    name_en: row.name_en,
    script_code: row.script_code,
    region_code: row.region_code,
    place_path: row.place_path,
    ...resolveCoordinate(row),
  }));

  return {
    code: language.code,
    name_en: language.name_en,
    name: locales[0]?.name ?? language.name_en,
    expression_count: expressionCount?.total ?? 0,
    reading_count: readingCount?.total ?? 0,
    locales,
  };
}

export async function listLanguageExpressions(
  db: D1Database,
  code: string,
  query: { q: string; limit: number; offset: number },
): Promise<{ items: LanguageExpressionRow[]; total: number } | null> {
  const language = await db
    .prepare(LANGUAGE_ROW_SQL)
    .bind(code)
    .first<{ code: string; name_en: string }>();
  if (!language) return null;

  const q = query.q.trim();
  const like = q ? `%${escapeLike(q)}%` : '';

  const totalRow = await db
    .prepare(LANGUAGE_EXPRESSIONS_COUNT_SQL)
    .bind(code, q, like)
    .first<{ total: number }>();

  const { results } = await db
    .prepare(LANGUAGE_EXPRESSIONS_PAGE_SQL)
    .bind(code, q, like, query.limit, query.offset)
    .all<LanguageExpressionRow>();

  return { items: results, total: totalRow?.total ?? 0 };
}
```

三個設計要點（給 reviewer，不寫進程式碼）：

- 「有內容」的判定用 `EXISTS expressions OR EXISTS language_locales`。**不**把 active UI locale 單獨列為條件，因為 `ui_locales.language_locale_code` 外鍵指向 `language_locales`，有 UI locale 必然有 language locale，該條件恆為冗餘。`active_ui_locale_count` 仍作為欄位回傳供前端顯示。
- `CONTENT_LANGUAGES_COUNT_SQL` 以 `SELECT COUNT(*) FROM (<同一 select>)` 包裹，保證 count 與 page 的過濾條件**不可能漂移**；代價是子查詢會被計算兩次，在 `languages` 這種千級表可接受。
- 排序 `expression_count DESC, code ASC`：`code` 是 PK，故排序**全序**穩定（spec §4.11）。
- 三個 route 都用 `parseReferenceQuery`，其 `MAX_LIMIT = 50` 就是本 service 的實質上限，故 service 內**不**再自設 limit 常數（自設會是永遠碰不到的死碼）。若日後語言列表需要一次拉更多，改的是 route 層的解析器，而非在 service 內偷夾。

- [ ] **Step 4: 跑測試確認通過**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/languageContent.test.ts
```

Expected: 4 PASS。

- [ ] **Step 5: 建立 `backend/src/routes/languages.ts`**

```ts
import { Hono } from 'hono';
import { notFound, paginated, success } from '../utils/response';
import { parseReferenceQuery } from '../services/languageIdentity';
import { getLanguageDetail, listLanguageExpressions, listLanguagesWithContent } from '../services/languageContent';
import type { Bindings, Variables } from '../types';

const languages = new Hono<{ Bindings: Bindings; Variables: Variables }>();

function parseQuery(c: { req: { query: (key: string) => string | undefined } }) {
  return parseReferenceQuery({
    q: c.req.query('q') ?? '',
    limit: c.req.query('limit'),
    offset: c.req.query('skip') ?? c.req.query('offset'),
  });
}

languages.get('/', async (c) => {
  const query = parseQuery(c);
  const result = await listLanguagesWithContent(c.env.DB, query);
  return paginated(c, result.items, result.total, query.offset, query.limit);
});

languages.get('/:code', async (c) => {
  const code = (c.req.param('code') ?? '').toLowerCase();
  const detail = await getLanguageDetail(c.env.DB, code);
  if (!detail) return notFound(c, 'Language');
  return success(c, detail);
});

languages.get('/:code/expressions', async (c) => {
  const code = (c.req.param('code') ?? '').toLowerCase();
  const query = parseQuery(c);
  const result = await listLanguageExpressions(c.env.DB, code, query);
  if (!result) return notFound(c, 'Language');
  return paginated(c, result.items, result.total, query.offset, query.limit);
});

export default languages;
```

`code` 一律 `toLowerCase()`：ISO 639-3 code 在 registry 中是小寫，大寫輸入不應誤判為 404。

- [ ] **Step 6: 在 `routes/index.ts` 註冊**

READ `backend/src/routes/index.ts`。加入 import 與 route：

```ts
import languages from './languages';
```

```ts
api.route('/languages', languages);
```

放在 `api.route('/language-locales', languageLocales);` 之後即可。**不要**動 `/language-registry`——它仍是完整 ISO registry 的查詢入口（picker 用），與 `/languages`（有內容的語言）並存是刻意的。

若 Task 2 已完成，此檔應同時已有 `api.route('/contributions', contributions);`；兩者互不衝突。

- [ ] **Step 7: 建立 `backend/tests/languagesIntegration.test.ts`**

```ts
import { describe, expect, it } from 'vitest';

const BASE_URL = process.env.TEST_BASE_URL || 'http://127.0.0.1:8788';
const API = `${BASE_URL}/api/v2/languages`;

describe('languages API', () => {
  it('lists only languages that have content', async () => {
    const res = await fetch(`${API}?limit=50`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: { total: number; items: Array<{ code: string; name: string; name_en: string; expression_count: number; locale_count: number }> };
    };
    expect(body.data.items.length).toBeGreaterThan(0);
    expect(body.data.total).toBeLessThan(1000);
    for (const item of body.data.items) {
      expect(item.expression_count + item.locale_count).toBeGreaterThan(0);
      expect(item.name).toBeTruthy();
      expect(item.name_en).toBeTruthy();
    }
    const eng = body.data.items.find((item) => item.code === 'eng');
    expect(eng).toBeTruthy();
  });

  it('filters the language list by query', async () => {
    const res = await fetch(`${API}?q=eng&limit=20`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { items: Array<{ code: string; name_en: string }> } };
    for (const item of body.data.items) {
      expect(`${item.code} ${item.name_en}`.toLowerCase()).toContain('eng');
    }
  });

  it('returns language detail with locales and coordinate provenance', async () => {
    const res = await fetch(`${API}/cmn`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: {
        code: string;
        name: string;
        name_en: string;
        expression_count: number;
        reading_count: number;
        locales: Array<{ code: string; coordinate_source: string | null; latitude: number | null }>;
      };
    };
    expect(body.data.code).toBe('cmn');
    expect(body.data.locales.length).toBeGreaterThan(0);
    const codes = body.data.locales.map((locale) => locale.code);
    expect([...codes].sort()).toEqual(codes);
    for (const locale of body.data.locales) {
      expect([null, 'locale', 'region']).toContain(locale.coordinate_source);
      if (locale.coordinate_source === null) expect(locale.latitude).toBeNull();
      else expect(typeof locale.latitude).toBe('number');
    }
  });

  it('accepts an uppercase language code', async () => {
    const res = await fetch(`${API}/CMN`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { code: string } };
    expect(body.data.code).toBe('cmn');
  });

  it('returns 404 for an unknown language', async () => {
    const res = await fetch(`${API}/zzz`);
    expect(res.status).toBe(404);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('NOT_FOUND');
  });

  it('lists expressions for a language with stable ordering', async () => {
    const res = await fetch(`${API}/eng/expressions?limit=10`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: { total: number; items: Array<{ id: string; lang_code: string; text: string; reading_count: number; mapping_count: number }> };
    };
    expect(body.data.total).toBeGreaterThan(0);
    for (const item of body.data.items) {
      expect(item.lang_code).toBe('eng');
      expect(typeof item.id).toBe('string');
      expect(typeof item.reading_count).toBe('number');
      expect(typeof item.mapping_count).toBe('number');
    }
    const texts = body.data.items.map((item) => item.text);
    expect([...texts].sort()).toEqual(texts);
  });

  it('returns 404 when listing expressions for an unknown language', async () => {
    const res = await fetch(`${API}/zzz/expressions`);
    expect(res.status).toBe(404);
  });
});
```

注意 `expect(body.data.total).toBeLessThan(1000)` 這條斷言的用意：它是**回歸哨兵**。ISO registry 有數千列語言，若日後有人把 `/languages` 誤接回完整 registry，這條會立刻紅燈。

- [ ] **Step 8: 跑測試**

worker 需在 `127.0.0.1:8788` 執行；`eng` 的 expression 由 UI message seed 建立，故 `/eng/expressions` 必有資料。

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/languageContent.test.ts tests/languagesIntegration.test.ts
```

Expected: languageContent 4 PASS、languagesIntegration 7 PASS。

若 `/languages/cmn` 回 404：確認 `schema.sql` 的 seed 有 `('cmn', 'Mandarin Chinese')`（見 `backend/schema.sql:111-113`），且本地 D1 已 rebuild。

- [ ] **Step 9: Commit**

```bash
git add backend/src/services/languageContent.ts backend/tests/languageContent.test.ts backend/src/routes/languages.ts backend/tests/languagesIntegration.test.ts backend/src/routes/index.ts
git commit -m "feat(api): add language content list, detail and expression endpoints"
```

---
## Task 6: 補齊 spec §14 錯誤碼清單

§14 寫「至少定義」，故擴充合規。目的是讓錯誤碼清單與實作**不再漂移**：Plan 6 已實作但未登錄的兩個，加上本 plan 新增的三個。

**Files:**
- Modify: `docs/superpowers/specs/2026-08-11-language-code-redesign-design.md`

- [ ] **Step 1: 更新 §14 code block**

READ spec 的 §14（約 line 595-620）。在 code block 內 `UI_LOCALE_ALREADY_ACTIVE` 之後補上五行：

```text
UI_LOCALE_NOT_FOUND
UI_LOCALE_SYSTEM_LOCKED
VOTE_INVALID_VALUE
VOTE_TARGET_NOT_FOUND
CONTRIBUTION_TOO_FEW_EXPRESSIONS
```

不要重排既有行的順序，只追加——降低 diff 噪音。

- [ ] **Step 2: 驗證清單與實作一致**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && for code in $(sed -n '/^## 14/,/^```$/p' docs/superpowers/specs/2026-08-11-language-code-redesign-design.md | grep -E '^[A-Z_]+$'); do rg -q "$code" backend/src || echo "MISSING IN CODE: $code"; done
```

Expected: 無輸出。若有輸出，代表 spec 列了實作沒有的 code——回報，**不要**為了讓檢查過關而亂加程式碼。

- [ ] **Step 3: 檢查文件**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && git diff --check
```

Expected: 無輸出。

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/specs/2026-08-11-language-code-redesign-design.md
git commit -m "docs(spec): register vote, contribution and ui locale error codes"
```

---

## Task 7: 全量回歸

**Files:** 無（僅執行驗證）

- [ ] **Step 1: Rebuild 本地 D1 並重啟 worker**

migration 0007 需套用。停掉既有 worker 後：

```bash
cd /Users/share.lim/Documents/GitHub/langmap && ./scripts/db/manage.sh local rebuild && ./scripts/db/manage.sh local verify
```

入口是 `scripts/db/manage.sh`（轉呼 `scripts/db/manage.py`，subcommand 為 `local status|rebuild|verify`）。**不要**手工 `wrangler d1 execute` 拼湊，也不要直接跑 `scripts/db/lib/local.py`——它是 library，沒有 CLI。

重啟 worker（背景執行，保持在 `127.0.0.1:8788`）：

```bash
cd /Users/share.lim/Documents/GitHub/langmap && ./dev.sh
```

- [ ] **Step 2: 後端全量測試**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npm test
```

Expected：全綠，或**僅**剩 `expressionsIntegration.test.ts` × 2（locale `nan-Hant-CN`／`nan-Hant-TW` 未 seed）。

特別注意：`auth.test.ts` 原本那 1 個失敗（呼叫 `/contributions/batch`）在 Task 2 之後**必須變綠**。若仍紅，是 Task 2 的 route 沒接上或路徑不符，回頭修 Task 2，**不要**改測試。

- [ ] **Step 3: scripts 測試**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && python3 -m pytest scripts -q
```

Expected: 全綠（`test_generate` 6、`test_local_rebuild` 5、`test_verify` 7、`test_generate_bundle` 9）。`test_local_rebuild` 對 `local.py` 載入的 SQL 檔**數量與順序**敏感——若 Task 1 動了 `scripts/db/lib/local.py`，這裡會紅，此時 READ 該測試並修正斷言的索引，而非改回 `lib/local.py`。

- [ ] **Step 4: 前端 build 未受影響**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/web && npm run build
```

Expected: 成功。本 plan 未改 `web/`，故這只是確認沒有意外污染。**提醒**：這個綠燈是假的——前端仍用 `language_profile_code` 與 `expression_id: number`，TypeScript 不知後端契約已變。真正的契約對齊是後續 Plan 8 的工作，不在本 plan 範圍。

- [ ] **Step 5: 確認工作區乾淨**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && git status --short && git log --oneline -8
```

Expected: 無未追蹤／未提交的預期外檔案；7 個 task 各自的 commit 都在。

- [ ] **Step 6: 標記完成**

在本 plan 各 task 的 checkbox 打勾後：

```bash
git add docs/superpowers/plans/2026-08-15-backend-gap-closure.md
git commit -m "docs(plan): mark backend gap closure complete"
```

---

## Self-Review

寫完這份 plan 後的自我檢查，供執行者與 reviewer 使用。

**與 spec 的對應**

| Task | spec 依據 | 是否逾越 spec |
|---|---|---|
| 1 votes | §2.4、§10、§17.1、§18 | 否。`target_type` 泛型形狀沿用舊 schema，CHECK 先只放 `'edge'`，未來擴充不需改形狀。 |
| 2 contribution batch | §13 | 否。復用既有 `createEdgesBatch`，未新增領域邏輯。 |
| 3 split step 7 + vote 通知 | §10.2 step 7、§12.4、§5.3 | 否。重算一律經 localization service。 |
| 4 workbench messages | §15.5 | 否。`placeholders_ok` 是旗標而非過濾，coverage 仍由 `computeCoverage` 獨立計算，符合「fallback candidate 不增加 coverage」。 |
| 5 languages routes | §15.4 | 否。`name` 取自 `language_locales.name` 是既有欄位，未新增 endonym 欄位。 |
| 6 錯誤碼 | §14「至少定義」 | 否。 |

**已知會踩的坑（已在步驟中預先處理）**

1. fake-D1 以 SQL 字串為精確 key ⇒ 所有 SQL 單行 + module-level const；Task 4／5 的測試常數與實作常數必須逐字一致。這是 Plan 6 真實踩過的坑（測試用單行、實作用多行模板字串，永遠匹配不到而假通過）。
2. `json_each` 取代動態 `IN (?, ?, ?)` ⇒ SQL 字串不隨參數數量變動（Task 3、Task 4）。
3. Task 4 **不用** `paginated()`：回應是複合物件，`paginated` 會擠掉 `locale`／`coverage`，且既有整合測試斷言那兩個鍵。
4. Task 5 count 與 page 共用同一 SELECT 字串 ⇒ 過濾條件不可能漂移。
5. `scripts/db/lib/local.py` 若被 Task 1 改動，`test_local_rebuild.py` 的索引斷言會錯位——Plan 6 已發生過一次（`calls[2]` → `calls[:3]` + `calls[3]`）。Task 7 Step 3 明確要求修測試而非退回實作。

**刻意排除**

- handbook（三張表 + `handbook_sections` + `handbook_section_items`）與 feed（`/feed/hot`、`/feed/new`）：使用者裁定延後，且 spec 從未定義其資料模型，需另開 spec。
- `/search/expressions`：前端路徑寫錯而已，`/expressions/search` 已存在，屬 Plan 8 前端修正範圍。
- 前端型別遷移（`expression_id: number` → `string`、`language_profile_code` → `lang_code`，15 個非測試檔案）：Plan 8。

**Review 時最該質疑的三點**

1. Task 5 的「有內容」判定用 `EXISTS expressions OR EXISTS language_locales`。若 registry seed 為**所有** ISO 語言都建了 language locale，這個條件會退化為「全部語言」，`total < 1000` 的哨兵會紅。執行 Task 5 Step 8 時務必看 `total` 的實際值；若異常大，回報而不要放寬斷言。
2. Task 1 的 `votes.target_id` 沒有 FK 指向 `expression_edges(id)`（泛型 `target_type` 無法用單一 FK 表達），存在性改由 service 驗證。這是刻意取捨——若 reviewer 認為應改成 `edge_votes` 專表 + 真 FK，那是合理的替代設計，需回頭改 spec 措辭。
3. Task 4 每 key 上限 5 個 candidate 是拍的數字，spec 未規定。若前端 §15.5 需要顯示更多，改常數即可，但別移除上限。
