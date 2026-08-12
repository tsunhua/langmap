# Mapping Edges + Manual Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Plan 1-3（ISO registry、language_locales、expressions、locale attestations）之上建立 mapping edge 模型（`expression_edges` 表）、手動拆分審計（`expression_splits`／`expression_split_moves`），以及 `POST/GET /expressions/:id/mappings` 與 `POST /expressions/:id/split` 四條 API。

**Architecture:** 分四層推進:(1) schema baseline(migration 0004 + schema.sql + system-split source seed + migration-lock);(2) mappings service(`mappings.ts`):edge pair canonicalization、find-or-create、batch clique、1-hop graph 查詢(穩定排序 + limit);(3) split service(`splits.ts`):admin-only atomic 7-step split(含 audit、edge endpoint move、homograph 分配);(4) expressions 路由擴充(mappings CRUD + split)。Edge ID 使用 ULID(`utils/ulid.ts`);pair 端點以字典序 canonicalize 後以 UNIQUE 約束去重。

**Tech Stack:** Hono 4 + TypeScript + Cloudflare Workers + D1(SQLite);Vitest(fake D1 單元測試 + 127.0.0.1:8788 整合測試);Python `scripts/db` 管理工具。

## Spec gap decisions（已裁定，不再追問）

1. **Votes 表**:spec §10.1／§10.2 多次提及「保留 edge ID、score 與 votes」,但全 spec 沒有定義 `votes` 表的 DDL;Plan 1 已 DROP 舊 `votes` 表。Split 只替換 edge 的端點 expression、不改 edge ID,因此「votes 不變」是 edge ID 穩定性的自然結果。**本 plan 不建立 votes 表**;待後續 plan 定義 votes 模型時,edge ID 穩定性已保證其引用不被破壞。

2. **Contributions API**:spec §5.2 架構列出 `routes/contributions.ts`、§10.1 提及「Batch contribution」,但 §13 API 契約沒有 `/contributions` 路由。**本 plan 提供 edge 服務層(`createEdge`／`createEdgesBatch`)** 供未來 contributions route 呼叫,並加一條 `POST /expressions/:id/mappings`(§13.2 未明列但為 GET 的自然對偶、split 整合測試需要它建立 edge)。完整的 contributions batch route 留給後續 plan。

3. **Split step 7(重新計算 UI Locale coverage／revision)**:依賴 UI localization 表(Plan 7 尚未建立)。**本 plan 的 split service 在步驟 6 後保留一個 no-op 通知點**,待 Plan 7 接入 localization service 時接線。

## Global Constraints

以下為各 task 隱含必須遵守的規則,不再逐 task 重複:

- `expression_edges` 表欄位逐字抄自 spec §10.1:`id TEXT PRIMARY KEY`、`expression_a_id`／`expression_b_id TEXT NOT NULL`、`score INTEGER NOT NULL DEFAULT 0`、`source TEXT NOT NULL`、`created_by INTEGER`、`created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP`;`CHECK (expression_a_id < expression_b_id)`;`UNIQUE (expression_a_id, expression_b_id)`;三條 FK。
- Edge ID 使用 ULID(`utils/ulid.ts` 的 `ulid()`)(§10.1)。
- Edge pair 一律由 service 層 canonicalize(`[a, b].sort()` 後寫入),route 不自行排序;UNIQUE 約束是去重的最後防線(§10.1「先以字典序 canonicalize pair，再用唯一約束重用既有 edge」)。
- `expression_splits`:`id TEXT PRIMARY KEY`(ULID)、`source_expression_id`／`target_expression_id TEXT NOT NULL`、`created_by INTEGER NOT NULL`、`created_at`;三條 FK(spec §10.2)。
- `expression_split_moves`:`(split_id, edge_id)` 聯合 PK;`previous_a_id`／`previous_b_id`／`new_a_id`／`new_b_id TEXT NOT NULL`;兩條 FK(spec §10.2)。
- Split 只允許 `role === 'admin'` 的使用者;route 層負責權限檢查(spec §10.2「Split 只允許 admin」)。
- Split 是原子操作:驗證 → 分配 homograph_index → 建立 split audit + 新 Expression → 移動 edge 端點 → 寫 move audit。任何驗證、唯一 pair 或寫入失敗都必須整體回滾(spec §10.2)。D1 的 `db.batch()` 提供單一 transaction。
- Split 產生的新 Expression:`source_id` 指向 `system-split` source、`source_ref = 'split:<split_id>'`、`created_by` 為操作 admin;同 `lang_code`、`text`、`text_hash`、`homograph_index = MAX + 1`(spec §10.2 step 2-3、§7.3)。
- Split 不自動複製或搬移 readings、locale attestations、handbook items(spec §10.2)。
- Edge 的 `source` 欄位是純文字標籤(如 `'contribution'`、`'seed'`、`'import'`),**不是** FK 到 `sources` 表(spec §10.1 DDL 無 FK)。
- 穩定錯誤碼(本 plan 用到):`EXPRESSION_NOT_FOUND`、`EXPRESSION_SPLIT_EMPTY`、`EXPRESSION_SPLIT_EDGE_NOT_ADJACENT`、`EXPRESSION_SPLIT_CONFLICT`、`VALIDATION_FAILED`(§14)。DB constraint error 不直接暴露(§14)。
- API prefix 一律 `/api/v2`;回應一律 `{ success, data?, error?, message? }`;列表用 `utils/response.ts` 的 `paginated(c, items, total, skip, limit)`(AGENTS.md、§13)。
- 所有查詢必須穩定排序(mappings:`score DESC, created_at ASC, edge_id ASC`)並有數量上限(`limit` clamp 到 `[1, 50]`,預設 20)(§4.11)。
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
| `backend/migrations/0004_mapping_edges.sql` | `expression_edges` + `expression_splits` + `expression_split_moves` DDL + `system-split` source seed(IF NOT EXISTS / INSERT OR IGNORE) | Create |
| `backend/schema.sql` | 與 0004 等價的本地全量 schema(DROP + CREATE + seeds) | Modify |
| `backend/tests/schemaContract.test.ts` | 斷言新表欄位/CHECK/FK 與 system-split source 存在 | Modify |
| `scripts/db/migration-lock.json` | 記錄 0004 的 sequence/size/sha256(用 sync 更新) | Modify |
| `backend/src/types/mapping.ts` | `EdgeRow`、`EdgeWithNeighborRow`、`SplitRow`、`SplitMoveRow` 共用型別 | Create |
| `backend/src/services/mappings.ts` | `MappingError`、`canonicalizeEdgePair`、`createEdge`、`createEdgesBatch`、`getExpressionMappings` | Create |
| `backend/src/services/splits.ts` | `SplitError`、`splitExpression` | Create |
| `backend/src/routes/expressions.ts` | 新增 `POST /:id/mappings`、`GET /:id/mappings`、`POST /:id/split` | Modify |
| `backend/tests/mappings.test.ts` | mappings service 單元測試(fake D1) | Create |
| `backend/tests/splits.test.ts` | split service 單元測試(fake D1) | Create |
| `backend/tests/mappingsIntegration.test.ts` | mappings + split API 整合測試(需 worker + rebuilt D1) | Create |

---

## Task 1: Greenfield schema —— `expression_edges` + `expression_splits` + `expression_split_moves`

把 §10.1／§10.2 的三張表與 split 專用 system source 寫進 migration 0004 與 `schema.sql`,更新契約測試與 migration-lock,並重建本地 D1。

**Files:**
- Create: `backend/migrations/0004_mapping_edges.sql`
- Modify: `backend/schema.sql`
- Modify: `backend/tests/schemaContract.test.ts`
- Modify: `scripts/db/migration-lock.json`(以 sync 更新,不手編)

**Interfaces:**
- Consumes: Plan 1-3 的 `backend/schema.sql`、`backend/migrations/0001-0003_*.sql`、`scripts/db/migration-lock.json`、`scripts/db/lib/migrations.sync_migration_lock`。
- Produces: `expression_edges`、`expression_splits`、`expression_split_moves` 三張表;`system-split` system source row。Task 2-4 的 service／route／整合測試依賴這些表存在。

- [x] **Step 1: 建立 migration 0004**

Create `backend/migrations/0004_mapping_edges.sql`:

```sql
-- Mapping edges + split audit tables (spec §10.1, §10.2).

CREATE TABLE IF NOT EXISTS expression_edges (
  id TEXT PRIMARY KEY,
  expression_a_id TEXT NOT NULL,
  expression_b_id TEXT NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (expression_a_id < expression_b_id),
  UNIQUE (expression_a_id, expression_b_id),
  FOREIGN KEY (expression_a_id) REFERENCES expressions(id),
  FOREIGN KEY (expression_b_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS expression_splits (
  id TEXT PRIMARY KEY,
  source_expression_id TEXT NOT NULL,
  target_expression_id TEXT NOT NULL,
  created_by INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (target_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS expression_split_moves (
  split_id TEXT NOT NULL,
  edge_id TEXT NOT NULL,
  previous_a_id TEXT NOT NULL,
  previous_b_id TEXT NOT NULL,
  new_a_id TEXT NOT NULL,
  new_b_id TEXT NOT NULL,
  PRIMARY KEY (split_id, edge_id),
  FOREIGN KEY (split_id) REFERENCES expression_splits(id),
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-split', 'system', 'LangMap split expressions');
```

- [x] **Step 2: 更新 `backend/schema.sql`**

在檔頭 DROP 區塊,於 `DROP TABLE IF EXISTS expression_edges;` 之前插入兩行(split 相依於 edges,move 相依於 split;順序:move → split → edges):

```sql
DROP TABLE IF EXISTS expression_split_moves;
DROP TABLE IF EXISTS expression_splits;
```

注意:現有的 `DROP TABLE IF EXISTS expression_edges;` 已在第 10 行,保持在原位。

在檔尾(現有 `expression_locale_attestations` 表之後)新增(無 `IF NOT EXISTS`,repo 慣例):

```sql
-- Mapping edges + split audit tables (spec §10.1, §10.2).

CREATE TABLE expression_edges (
  id TEXT PRIMARY KEY,
  expression_a_id TEXT NOT NULL,
  expression_b_id TEXT NOT NULL,
  score INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (expression_a_id < expression_b_id),
  UNIQUE (expression_a_id, expression_b_id),
  FOREIGN KEY (expression_a_id) REFERENCES expressions(id),
  FOREIGN KEY (expression_b_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE expression_splits (
  id TEXT PRIMARY KEY,
  source_expression_id TEXT NOT NULL,
  target_expression_id TEXT NOT NULL,
  created_by INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (target_expression_id) REFERENCES expressions(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE expression_split_moves (
  split_id TEXT NOT NULL,
  edge_id TEXT NOT NULL,
  previous_a_id TEXT NOT NULL,
  previous_b_id TEXT NOT NULL,
  new_a_id TEXT NOT NULL,
  new_b_id TEXT NOT NULL,
  PRIMARY KEY (split_id, edge_id),
  FOREIGN KEY (split_id) REFERENCES expression_splits(id),
  FOREIGN KEY (edge_id) REFERENCES expression_edges(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-split', 'system', 'LangMap split expressions');
```

- [x] **Step 3: 更新 `backend/tests/schemaContract.test.ts`**

在既有 describe 內、`does not contain obsolete identity tables` 之前新增三個 it:

```ts
  it('defines expression_edges with pair ordering check and uniqueness', () => {
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?id TEXT PRIMARY KEY/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?score INTEGER NOT NULL DEFAULT 0/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?source TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?CHECK \(expression_a_id < expression_b_id\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?UNIQUE \(expression_a_id, expression_b_id\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_edges[\s\S]*?FOREIGN KEY \(expression_a_id\) REFERENCES expressions\(id\)[\s\S]*?FOREIGN KEY \(expression_b_id\) REFERENCES expressions\(id\)/s);
  });

  it('defines expression_splits and expression_split_moves audit tables', () => {
    expect(schema).toMatch(/CREATE TABLE expression_splits[\s\S]*?source_expression_id TEXT NOT NULL[\s\S]*?target_expression_id TEXT NOT NULL[\s\S]*?created_by INTEGER NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE expression_splits[\s\S]*?FOREIGN KEY \(source_expression_id\) REFERENCES expressions\(id\)[\s\S]*?FOREIGN KEY \(target_expression_id\) REFERENCES expressions\(id\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_split_moves[\s\S]*?split_id TEXT NOT NULL[\s\S]*?edge_id TEXT NOT NULL[\s\S]*?PRIMARY KEY \(split_id, edge_id\)/s);
    expect(schema).toMatch(/CREATE TABLE expression_split_moves[\s\S]*?previous_a_id[\s\S]*?new_a_id/s);
  });

  it('seeds the system-split source for split provenance', () => {
    expect(schema).toMatch(/system-split/);
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

Expected: 印出 0001、0002、0003、0004 四筆;`migrations` 陣列變四筆、metadata 保持不變。

再跑一次同段程式(改 `update=False`)確認無 "unlocked migration" 錯誤。

- [x] **Step 5: 跑 schemaContract 測試**

```bash
cd backend && npx vitest run tests/schemaContract.test.ts
```

Expected: 全部 it PASS(既有 8 + 新增 3 = 11 個)。

- [x] **Step 6: 重建本地 D1**

先確認 8788 沒有 worker 占用(若有,`kill $(pgrep -f "wrangler dev")`,等 `lsof -iTCP:8788` 清空)。然後從 repo root:

```bash
python3 scripts/db/manage.py local rebuild
```

Expected: 回 `{"status": "rebuilt", ...}`。

- [x] **Step 7: 跑 scripts 驗證確認 schema invariant 未破壞**

```bash
python3 -m unittest scripts.db.tests.test_verify
python3 scripts/db/tests/test_local_rebuild.py
```

Expected: 兩者皆 OK。

- [x] **Step 8: Commit**

```bash
git add backend/migrations/0004_mapping_edges.sql backend/schema.sql backend/tests/schemaContract.test.ts scripts/db/migration-lock.json
git commit -m "feat(db): add mapping edges and split audit tables"
```

Commit 後 `git status --short` 應為空或僅有預期之外的新檔(如有,停下回報)。

---

## Task 2: Mappings service(`createEdge` / `createEdgesBatch` / `getExpressionMappings`)

Edge pair canonicalization、find-or-reuse(單條 + batch clique)、1-hop graph 查詢。Route 層不自行排序 pair。

**Files:**
- Create: `backend/src/types/mapping.ts`
- Create: `backend/src/services/mappings.ts`
- Test: `backend/tests/mappings.test.ts`

**Interfaces:**
- Consumes: `D1Database`;`ulid` from `utils/ulid`;`parseReferenceQuery`／`escapeLike` from `services/languageIdentity`;Task 1 的 `expression_edges` 表。
- Produces:
  - `canonicalizeEdgePair(a: string, b: string): [string, string]`
  - `createEdge(db, input: { expression_a_id: string; expression_b_id: string; source: string; created_by: number }): Promise<{ edge: EdgeRow; created: boolean }>`
  - `createEdgesBatch(db, input: { expression_ids: string[]; source: string; created_by: number }): Promise<{ edges: EdgeRow[]; created_count: number }>`
  - `getExpressionMappings(db, expression_id: string, query: { limit: number; offset: number }): Promise<{ items: EdgeWithNeighborRow[]; total: number }>`
  - `class MappingError extends Error { constructor(public code: string) }`
  - Task 3 的 `splitExpression` 依賴 `getExpressionMappings` 的查詢能力(實際 split 直接查 edges 表以取得完整 edge row);Task 4 的 route 依賴以上全部。

- [x] **Step 1: 建立共用型別**

Create `backend/src/types/mapping.ts`:

```ts
export interface EdgeRow {
  id: string;
  expression_a_id: string;
  expression_b_id: string;
  score: number;
  source: string;
  created_by: number | null;
  created_at: string;
}

export interface EdgeWithNeighborRow {
  edge_id: string;
  neighbor_id: string;
  neighbor_lang_code: string;
  neighbor_text: string;
  score: number;
  source: string;
  created_at: string;
}

export interface SplitRow {
  id: string;
  source_expression_id: string;
  target_expression_id: string;
  created_by: number;
  created_at: string;
}

export interface SplitMoveRow {
  split_id: string;
  edge_id: string;
  previous_a_id: string;
  previous_b_id: string;
  new_a_id: string;
  new_b_id: string;
}
```

- [x] **Step 2: 寫失敗的單元測試**

Create `backend/tests/mappings.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import {
  MappingError,
  canonicalizeEdgePair,
  createEdge,
  createEdgesBatch,
  getExpressionMappings,
} from '../src/services/mappings';
import type { EdgeRow } from '../src/types/mapping';

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
  return { prepare, batch: async (stmts: unknown[]) => {
    const results: unknown[] = [];
    for (const s of stmts as Array<{ run?: () => Promise<unknown> }>) {
      results.push(s?.run ? await s.run() : { success: true });
    }
    return results;
  } } as unknown as import('@cloudflare/workers-types').D1Database;
}

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(
    () => '',
    (error: unknown) => String((error as { code?: string }).code ?? ''),
  );
}

describe('canonicalizeEdgePair', () => {
  it('sorts two expression ids into ascending order', () => {
    expect(canonicalizeEdgePair('nan:bbb', 'eng:aaa')).toEqual(['eng:aaa', 'nan:bbb']);
    expect(canonicalizeEdgePair('eng:aaa', 'nan:bbb')).toEqual(['eng:aaa', 'nan:bbb']);
  });

  it('throws VALIDATION_FAILED for identical endpoints', () => {
    expect(() => canonicalizeEdgePair('nan:aaa', 'nan:aaa')).toThrow();
  });
});

describe('createEdge', () => {
  const mockEdge: EdgeRow = {
    id: '01HX', expression_a_id: 'eng:aaa', expression_b_id: 'nan:bbb',
    score: 0, source: 'contribution', created_by: 1, created_at: '2026-08-13 00:00:00',
  };

  it('creates a new edge with canonicalized pair', async () => {
    let inserted = false;
    const db = fakeD1({
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE expression_a_id = ? AND expression_b_id = ?':
        () => null,
      'INSERT INTO expression_edges (id, expression_a_id, expression_b_id, source, created_by) VALUES (?, ?, ?, ?, ?)':
        () => { inserted = true; return { success: true }; },
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE id = ?':
        () => mockEdge,
    });
    const result = await createEdge(db, { expression_a_id: 'nan:bbb', expression_b_id: 'eng:aaa', source: 'contribution', created_by: 1 });
    expect(result.created).toBe(true);
    expect(result.edge.expression_a_id).toBe('eng:aaa');
    expect(result.edge.expression_b_id).toBe('nan:bbb');
    expect(inserted).toBe(true);
  });

  it('reuses an existing edge when pair already exists', async () => {
    let inserted = false;
    const db = fakeD1({
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE expression_a_id = ? AND expression_b_id = ?':
        () => mockEdge,
      'INSERT INTO expression_edges (id, expression_a_id, expression_b_id, source, created_by) VALUES (?, ?, ?, ?, ?)':
        () => { inserted = true; return { success: true }; },
    });
    const result = await createEdge(db, { expression_a_id: 'eng:aaa', expression_b_id: 'nan:bbb', source: 'contribution', created_by: 1 });
    expect(result.created).toBe(false);
    expect(result.edge.id).toBe('01HX');
    expect(inserted).toBe(false);
  });

  it('rejects identical endpoints with VALIDATION_FAILED', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => createEdge(db, { expression_a_id: 'nan:aaa', expression_b_id: 'nan:aaa', source: 'x', created_by: 1 }))).toBe('VALIDATION_FAILED');
  });
});

describe('createEdgesBatch', () => {
  it('creates a clique from 3 expressions and dedups pairs', async () => {
    let insertCount = 0;
    const db = fakeD1({
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE expression_a_id = ? AND expression_b_id = ?':
        () => null,
      'INSERT INTO expression_edges (id, expression_a_id, expression_b_id, source, created_by) VALUES (?, ?, ?, ?, ?)':
        () => { insertCount += 1; return { success: true }; },
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE id = ?':
        () => ({
          id: `edge-${insertCount}`, expression_a_id: 'a', expression_b_id: 'b',
          score: 0, source: 'contribution', created_by: 1, created_at: '2026-08-13',
        }),
    });
    const result = await createEdgesBatch(db, { expression_ids: ['nan:a', 'nan:b', 'nan:c'], source: 'contribution', created_by: 1 });
    expect(result.edges).toHaveLength(3);
    expect(insertCount).toBe(3);
  });

  it('rejects fewer than 2 expression ids', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => createEdgesBatch(db, { expression_ids: ['nan:a'], source: 'x', created_by: 1 }))).toBe('VALIDATION_FAILED');
  });
});

describe('getExpressionMappings', () => {
  it('returns edges with neighbor info ordered by score desc then created_at then edge id', async () => {
    const items = [
      { edge_id: 'e2', neighbor_id: 'nan:b', neighbor_lang_code: 'nan', neighbor_text: '飯', score: 5, source: 'contribution', created_at: '2026-08-13' },
      { edge_id: 'e1', neighbor_id: 'eng:c', neighbor_lang_code: 'eng', neighbor_text: 'rice', score: 5, source: 'contribution', created_at: '2026-08-12' },
    ];
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expression_edges WHERE expression_a_id = ? OR expression_b_id = ?': () => ({ total: 2 }),
      'SELECT e.id AS edge_id, n.id AS neighbor_id, n.lang_code AS neighbor_lang_code, n.text AS neighbor_text, e.score, e.source, e.created_at FROM expression_edges e JOIN expressions n ON n.id = CASE WHEN e.expression_a_id = ? THEN e.expression_b_id ELSE e.expression_a_id END WHERE e.expression_a_id = ? OR e.expression_b_id = ? ORDER BY e.score DESC, e.created_at ASC, e.id ASC LIMIT ? OFFSET ?':
        () => ({ results: items }),
    });
    const result = await getExpressionMappings(db, 'nan:a', { limit: 20, offset: 0 });
    expect(result.total).toBe(2);
    expect(result.items[0].edge_id).toBe('e2');
    expect(result.items[0].neighbor_text).toBe('飯');
  });

  it('returns empty for an expression with no edges', async () => {
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM expression_edges WHERE expression_a_id = ? OR expression_b_id = ?': () => ({ total: 0 }),
      'SELECT e.id AS edge_id, n.id AS neighbor_id, n.lang_code AS neighbor_lang_code, n.text AS neighbor_text, e.score, e.source, e.created_at FROM expression_edges e JOIN expressions n ON n.id = CASE WHEN e.expression_a_id = ? THEN e.expression_b_id ELSE e.expression_a_id END WHERE e.expression_a_id = ? OR e.expression_b_id = ? ORDER BY e.score DESC, e.created_at ASC, e.id ASC LIMIT ? OFFSET ?':
        () => ({ results: [] }),
    });
    const result = await getExpressionMappings(db, 'nan:lonely', { limit: 20, offset: 0 });
    expect(result.total).toBe(0);
    expect(result.items).toHaveLength(0);
  });
});
```

- [x] **Step 3: 跑測試確認失敗**

```bash
cd backend && npx vitest run tests/mappings.test.ts
```

Expected: FAIL(`Cannot find module '../src/services/mappings'`)。

- [x] **Step 4: 建立 `backend/src/services/mappings.ts`**

```ts
import type { D1Database } from '@cloudflare/workers-types';
import type { EdgeRow, EdgeWithNeighborRow } from '../types/mapping';
import { ulid } from '../utils/ulid';

const EDGE_COLUMNS = `id, expression_a_id, expression_b_id, score, source, created_by, created_at`;

export class MappingError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'MappingError';
  }
}

export function canonicalizeEdgePair(a: string, b: string): [string, string] {
  if (!a || !b || a === b) throw new MappingError('VALIDATION_FAILED');
  return a < b ? [a, b] : [b, a];
}

export async function createEdge(
  db: D1Database,
  input: { expression_a_id: string; expression_b_id: string; source: string; created_by: number },
): Promise<{ edge: EdgeRow; created: boolean }> {
  const [lowId, highId] = canonicalizeEdgePair(input.expression_a_id, input.expression_b_id);

  const existing = await db
    .prepare(`SELECT ${EDGE_COLUMNS} FROM expression_edges WHERE expression_a_id = ? AND expression_b_id = ?`)
    .bind(lowId, highId)
    .first<EdgeRow>();
  if (existing) return { edge: existing, created: false };

  const id = ulid();
  await db
    .prepare('INSERT INTO expression_edges (id, expression_a_id, expression_b_id, source, created_by) VALUES (?, ?, ?, ?, ?)')
    .bind(id, lowId, highId, input.source, input.created_by)
    .run();

  const edge = await db
    .prepare(`SELECT ${EDGE_COLUMNS} FROM expression_edges WHERE id = ?`)
    .bind(id)
    .first<EdgeRow>();
  return { edge: edge as EdgeRow, created: true };
}

export async function createEdgesBatch(
  db: D1Database,
  input: { expression_ids: string[]; source: string; created_by: number },
): Promise<{ edges: EdgeRow[]; created_count: number }> {
  const ids = input.expression_ids;
  if (ids.length < 2) throw new MappingError('VALIDATION_FAILED');

  const edges: EdgeRow[] = [];
  let createdCount = 0;
  for (let i = 0; i < ids.length; i++) {
    for (let j = i + 1; j < ids.length; j++) {
      const result = await createEdge(db, {
        expression_a_id: ids[i],
        expression_b_id: ids[j],
        source: input.source,
        created_by: input.created_by,
      });
      edges.push(result.edge);
      if (result.created) createdCount++;
    }
  }
  return { edges, created_count: createdCount };
}

export async function getExpressionMappings(
  db: D1Database,
  expressionId: string,
  query: { limit: number; offset: number },
): Promise<{ items: EdgeWithNeighborRow[]; total: number }> {
  const countRow = await db
    .prepare('SELECT COUNT(*) AS total FROM expression_edges WHERE expression_a_id = ? OR expression_b_id = ?')
    .bind(expressionId, expressionId)
    .first<{ total: number }>();

  const { results } = await db
    .prepare(
      `SELECT e.id AS edge_id, n.id AS neighbor_id, n.lang_code AS neighbor_lang_code, n.text AS neighbor_text, e.score, e.source, e.created_at FROM expression_edges e JOIN expressions n ON n.id = CASE WHEN e.expression_a_id = ? THEN e.expression_b_id ELSE e.expression_a_id END WHERE e.expression_a_id = ? OR e.expression_b_id = ? ORDER BY e.score DESC, e.created_at ASC, e.id ASC LIMIT ? OFFSET ?`,
    )
    .bind(expressionId, expressionId, expressionId, query.limit, query.offset)
    .all<EdgeWithNeighborRow>();
  return { items: results, total: countRow?.total ?? 0 };
}
```

- [x] **Step 5: 跑測試確認通過**

```bash
cd backend && npx vitest run tests/mappings.test.ts
```

Expected: 全部 PASS(canonicalizeEdgePair 2、createEdge 3、createEdgesBatch 2、getExpressionMappings 2 = 9)。若某個 it 因 fake D1 SQL 字串與實作不一致而失敗,以實作(Step 4)的 SQL 為準調整測試裡的 handler key,再重跑。

- [x] **Step 6: Commit**

```bash
git add backend/src/types/mapping.ts backend/src/services/mappings.ts backend/tests/mappings.test.ts
git commit -m "feat(api): add mapping edge service with pair canonicalization and graph query"
```

---

## Task 3: Split service(`splitExpression`)

Admin-only atomic split:驗證 → 分配 homograph_index → 建立 split audit + 新 Expression → 移動 edge 端點 → 寫 move audit。D1 `batch()` 提供單一 transaction 保證。

**Files:**
- Create: `backend/src/services/splits.ts`
- Test: `backend/tests/splits.test.ts`

**Interfaces:**
- Consumes: `D1Database`;`ulid` from `utils/ulid`;`buildExpressionId`／`computeTextHash` from `services/expressionIdentity`;Task 2 的 `EdgeRow`;Task 1 的三張表與 `system-split` source;`expressions`／`expression_edges`／`expression_splits`／`expression_split_moves` 表。
- Produces:
  - `class SplitError extends Error { constructor(public code: string) }`
  - `splitExpression(db, input: { source_expression_id: string; edge_ids: string[]; created_by: number }): Promise<{ split_id: string; target_expression_id: string; moved_edge_count: number }>`
  - Task 4 的 split route 依賴此函式。

- [x] **Step 1: 寫失敗的單元測試**

Create `backend/tests/splits.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { SplitError, splitExpression } from '../src/services/splits';

type Handler = () => unknown;

function fakeD1(handlers: Record<string, Handler>, batchResult?: unknown) {
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
  return {
    prepare,
    batch: async () => batchResult ?? [{ success: true }],
  } as unknown as import('@cloudflare/workers-types').D1Database;
}

function captureAsyncCode(fn: () => Promise<unknown>): Promise<string> {
  return fn().then(
    () => '',
    (error: unknown) => String((error as { code?: string }).code ?? ''),
  );
}

const sourceExpression = {
  id: 'nan:aaaa', lang_code: 'nan', text: '食', text_hash: 'aaaa',
  homograph_index: 1, description: '', tags_json: '[]', source_id: null,
  source_ref: null, review_status: 'pending', created_by: 1,
  created_at: '2026-08-13', updated_at: '2026-08-13',
};

describe('splitExpression', () => {
  it('rejects empty edge_ids with EXPRESSION_SPLIT_EMPTY', async () => {
    const db = fakeD1({});
    expect(await captureAsyncCode(() => splitExpression(db, { source_expression_id: 'nan:aaaa', edge_ids: [], created_by: 1 }))).toBe('EXPRESSION_SPLIT_EMPTY');
  });

  it('rejects when source expression is missing with EXPRESSION_NOT_FOUND', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => null,
    });
    expect(await captureAsyncCode(() => splitExpression(db, { source_expression_id: 'nan:missing', edge_ids: ['01EDGE'], created_by: 1 }))).toBe('EXPRESSION_NOT_FOUND');
  });

  it('rejects when an edge does not touch the source expression with EXPRESSION_SPLIT_EDGE_NOT_ADJACENT', async () => {
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => sourceExpression,
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE id IN (?)': () => ({ results: [] }),
    });
    expect(await captureAsyncCode(() => splitExpression(db, { source_expression_id: 'nan:aaaa', edge_ids: ['01EDGE'], created_by: 1 }))).toBe('EXPRESSION_SPLIT_EDGE_NOT_ADJACENT');
  });

  it('splits edges and creates target expression with next homograph index', async () => {
    const edges = [
      { id: '01EDGE1', expression_a_id: 'eng:bbb', expression_b_id: 'nan:aaaa', score: 3, source: 'contribution', created_by: 1, created_at: '2026-08-13' },
    ];
    const db = fakeD1({
      'SELECT id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at FROM expressions WHERE id = ?':
        () => sourceExpression,
      'SELECT id, expression_a_id, expression_b_id, score, source, created_by, created_at FROM expression_edges WHERE id IN (?)':
        () => ({ results: edges }),
      'SELECT MAX(homograph_index) AS max_idx FROM expressions WHERE lang_code = ? AND text_hash = ?':
        () => ({ max_idx: 1 }),
    });
    const result = await splitExpression(db, { source_expression_id: 'nan:aaaa', edge_ids: ['01EDGE1'], created_by: 5 });
    expect(result.target_expression_id).toBe('nan:aaaa.2');
    expect(result.moved_edge_count).toBe(1);
  });
});
```

- [x] **Step 2: 跑測試確認失敗**

```bash
cd backend && npx vitest run tests/splits.test.ts
```

Expected: FAIL(`Cannot find module '../src/services/splits'`)。

- [x] **Step 3: 建立 `backend/src/services/splits.ts`**

```ts
import type { D1Database, D1PreparedStatement } from '@cloudflare/workers-types';
import type { EdgeRow } from '../types/mapping';
import { buildExpressionId } from './expressionIdentity';

const EXPRESSION_COLUMNS = `id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by, created_at, updated_at`;
const EDGE_COLUMNS = `id, expression_a_id, expression_b_id, score, source, created_by, created_at`;

export class SplitError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'SplitError';
  }
}

export async function splitExpression(
  db: D1Database,
  input: { source_expression_id: string; edge_ids: string[]; created_by: number },
): Promise<{ split_id: string; target_expression_id: string; moved_edge_count: number }> {
  if (!input.edge_ids.length) throw new SplitError('EXPRESSION_SPLIT_EMPTY');

  const source = await db
    .prepare(`SELECT ${EXPRESSION_COLUMNS} FROM expressions WHERE id = ?`)
    .bind(input.source_expression_id)
    .first<{ id: string; lang_code: string; text: string; text_hash: string; homograph_index: number }>();
  if (!source) throw new SplitError('EXPRESSION_NOT_FOUND');

  const placeholders = input.edge_ids.map(() => '?').join(', ');
  const { results: edges } = await db
    .prepare(`SELECT ${EDGE_COLUMNS} FROM expression_edges WHERE id IN (${placeholders})`)
    .bind(...input.edge_ids)
    .all<EdgeRow>();

  if (edges.length !== input.edge_ids.length) throw new SplitError('EXPRESSION_SPLIT_EDGE_NOT_ADJACENT');
  for (const edge of edges) {
    if (edge.expression_a_id !== input.source_expression_id && edge.expression_b_id !== input.source_expression_id) {
      throw new SplitError('EXPRESSION_SPLIT_EDGE_NOT_ADJACENT');
    }
  }

  const maxRow = await db
    .prepare('SELECT MAX(homograph_index) AS max_idx FROM expressions WHERE lang_code = ? AND text_hash = ?')
    .bind(source.lang_code, source.text_hash)
    .first<{ max_idx: number | null }>();
  const nextIndex = (maxRow?.max_idx ?? 0) + 1;
  const targetId = buildExpressionId(source.lang_code, source.text_hash, nextIndex);
  const splitId = crypto.randomUUID();

  const statements: D1PreparedStatement[] = [];

  statements.push(
    db.prepare(
      `INSERT INTO expressions (id, lang_code, text, text_hash, homograph_index, description, tags_json, source_id, source_ref, review_status, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    ).bind(
      targetId, source.lang_code, source.text, source.text_hash, nextIndex,
      source.description ?? '', source.tags_json ?? '[]',
      'system-split', `split:${splitId}`, 'pending', input.created_by,
    ),
  );

  statements.push(
    db.prepare(
      'INSERT INTO expression_splits (id, source_expression_id, target_expression_id, created_by) VALUES (?, ?, ?, ?)',
    ).bind(splitId, input.source_expression_id, targetId, input.created_by),
  );

  for (const edge of edges) {
    const otherId = edge.expression_a_id === input.source_expression_id ? edge.expression_b_id : edge.expression_a_id;
    const [newA, newB] = otherId < targetId ? [otherId, targetId] : [targetId, otherId];

    statements.push(
      db.prepare('UPDATE expression_edges SET expression_a_id = ?, expression_b_id = ? WHERE id = ?').bind(newA, newB, edge.id),
    );

    statements.push(
      db.prepare(
        'INSERT INTO expression_split_moves (split_id, edge_id, previous_a_id, previous_b_id, new_a_id, new_b_id) VALUES (?, ?, ?, ?, ?, ?)',
      ).bind(splitId, edge.id, edge.expression_a_id, edge.expression_b_id, newA, newB),
    );
  }

  try {
    await db.batch(statements);
  } catch (error) {
    const msg = String((error as { message?: string })?.message ?? '');
    if (msg.includes('UNIQUE constraint failed')) throw new SplitError('EXPRESSION_SPLIT_CONFLICT');
    throw error;
  }

  return { split_id: splitId, target_expression_id: targetId, moved_edge_count: edges.length };
}
```

- [x] **Step 4: 跑測試確認通過**

```bash
cd backend && npx vitest run tests/splits.test.ts
```

Expected: 4 tests PASS。

- [x] **Step 5: Commit**

```bash
git add backend/src/services/splits.ts backend/tests/splits.test.ts
git commit -m "feat(api): add expression split service with atomic edge moves and audit"
```

---

## Task 4: Routes —— `POST/GET /:id/mappings` + `POST /:id/split` 與整合測試

`POST /:id/mappings`(需認證,建立 edge)、`GET /:id/mappings`(公開,分頁)、`POST /:id/split`(admin-only)。Route 只負責組合,edge 與 split 邏輯一律交給 service。

**Files:**
- Modify: `backend/src/routes/expressions.ts`(新增三條 handler)
- Create: `backend/tests/mappingsIntegration.test.ts`

**Interfaces:**
- Consumes: Task 2 的 `MappingError`／`createEdge`／`getExpressionMappings`;Task 3 的 `SplitError`／`splitExpression`;Plan 1 的 `parseReferenceQuery`;`requireAuth` middleware;`forbidden`／`paginated`／`created`／`success`／`badRequest`／`notFound`／`internalError` from `utils/response`;`Bindings`／`Variables`。
- Produces:
  - `POST /api/v2/expressions/:id/mappings`(201/200 + `created`;400/401/404)
  - `GET /api/v2/expressions/:id/mappings`(分頁)
  - `POST /api/v2/expressions/:id/split`(200;400/401/403/404)

- [x] **Step 1: 寫整合測試(先失敗)**

Create `backend/tests/mappingsIntegration.test.ts`:

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

describe('mappings API', () => {
  it('creates an edge between two expressions', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(token, `邊測A${unique}`);
    const idB = await createExpression(token, `邊測B${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${idA}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ target_expression_id: idB, source: 'contribution' }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { edge: { expression_a_id: string; expression_b_id: string }; created: boolean } };
    expect(body.data.created).toBe(true);
    const [low, high] = [idA, idB].sort();
    expect(body.data.edge.expression_a_id).toBe(low);
    expect(body.data.edge.expression_b_id).toBe(high);
  });

  it('reuses an existing edge on duplicate submission', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(token, `重用A${unique}`);
    const idB = await createExpression(token, `重用B${unique}`);
    const post = () =>
      fetch(`${BASE_URL}/api/v2/expressions/${idA}/mappings`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
        body: JSON.stringify({ target_expression_id: idB, source: 'contribution' }),
      });
    const first = await post();
    const second = await post();
    expect(first.status).toBe(201);
    expect(second.status).toBe(200);
    const firstBody = (await first.json()) as { data: { edge: { id: string }; created: boolean } };
    const secondBody = (await second.json()) as { data: { edge: { id: string }; created: boolean } };
    expect(firstBody.data.edge.id).toBe(secondBody.data.edge.id);
    expect(secondBody.data.created).toBe(false);
  });

  it('lists mappings for an expression with neighbor info', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(token, `列表A${unique}`);
    const idB = await createExpression(token, `列表B${unique}`);
    await fetch(`${BASE_URL}/api/v2/expressions/${idA}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ target_expression_id: idB, source: 'contribution' }),
    });
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${idA}/mappings`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      data: { items: Array<{ edge_id: string; neighbor_id: string; neighbor_text: string; score: number }>; total: number; hasMore: boolean };
    };
    expect(body.data.total).toBeGreaterThanOrEqual(1);
    expect(body.data.items.some((item) => item.neighbor_id === idB)).toBe(true);
  });

  it('requires auth to create an edge', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/expressions/nan:fake/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ target_expression_id: 'eng:fake', source: 'contribution' }),
    });
    expect(res.status).toBe(401);
  });

  it('rejects identical endpoints', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(token, `同點${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${idA}/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ target_expression_id: idA, source: 'contribution' }),
    });
    expect(res.status).toBe(400);
  });
});

describe('split API', () => {
  it('forbids non-admin users from splitting', async () => {
    const token = await registerToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(token, `權限A${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${idA}/split`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ edge_ids: [] }),
    });
    expect(res.status).toBe(403);
  });

  it('rejects empty edge_ids from an admin', async () => {
    const adminToken = await getAdminToken();
    const unique = Math.random().toString(36).slice(2, 10);
    const idA = await createExpression(adminToken, `空邊A${unique}`);
    const res = await fetch(`${BASE_URL}/api/v2/expressions/${idA}/split`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${adminToken}` },
      body: JSON.stringify({ edge_ids: [] }),
    });
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('EXPRESSION_SPLIT_EMPTY');
  });
});

async function getAdminToken(): Promise<string> {
  const res = await fetch(`${BASE_URL}/api/v2/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ username: `admin-${Date.now()}`, email: `admin-${Date.now()}@example.com`, password: 'pass1234' }),
  });
  const body = (await res.json()) as { data: { token: string; user: { id: number } } };
  const fs = await import('node:fs');
  const dbFile = fs.readdirSync('.wrangler/state/v3/d1/miniflare-D1DatabaseObject').find((f) => f.endsWith('.sqlite'));
  if (!dbFile) throw new Error('D1 sqlite not found');
  const { DatabaseSync } = await import('node:sqlite');
  const db = new DatabaseSync(`.wrangler/state/v3/d1/miniflare-D1DatabaseObject/${dbFile}`);
  db.exec(`UPDATE users SET role = 'admin' WHERE id = ${body.data.user.id}`);
  db.close();
  return body.data.token;
}
```

- [x] **Step 2: 確保 worker 在 8788 且資料已 rebuild,跑測試確認失敗**

若 8788 沒有 worker,從 `backend/` 背景啟動(不要用 `./dev.sh`):

```bash
nohup node_modules/.bin/wrangler dev --config backend/wrangler.jsonc --persist-to backend/.wrangler/state --port 8788 > /tmp/langmap-worker-8788.log 2>&1 & disown
```

等待 `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8788/api/v2/auth/health` 回 `200`(約 10 秒)。

```bash
cd backend && npx vitest run tests/mappingsIntegration.test.ts
```

Expected: 全 FAIL(404,route 尚未掛上)。確認失敗後才繼續。

- [x] **Step 3: 在 `backend/src/routes/expressions.ts` 新增三條 handler**

在現有檔案的 import 區塊加入:

```ts
import { forbidden } from '../utils/response';
import { MappingError, createEdge, getExpressionMappings } from '../services/mappings';
import { SplitError, splitExpression } from '../services/splits';
import { parseReferenceQuery } from '../services/languageIdentity';
```

在現有 `POST /:id/locale-attestations` handler 之前(或之後,順序不影響 Hono 路由匹配因為路徑不同)新增三條:

```ts
languageLocales.post('/:id/mappings', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const id = c.param('id');
    const body = await c.req.json().catch(() => ({}));
    const targetExpressionId = typeof body?.target_expression_id === 'string' ? body.target_expression_id.trim() : '';
    const source = typeof body?.source === 'string' ? body.source.trim() : '';
    if (!targetExpressionId || !source) {
      return badRequest(c, 'VALIDATION_FAILED', 'target_expression_id and source are required');
    }
    try {
      const result = await createEdge(c.env.DB, {
        expression_a_id: id,
        expression_b_id: targetExpressionId,
        source,
        created_by: user?.id ?? 0,
      });
      return result.created ? created(c, result, 'Edge created') : success(c, result, 'Edge already exists');
    } catch (error) {
      if (error instanceof MappingError) return badRequest(c, error.code, error.code);
      throw error;
    }
  } catch (error) {
    console.error('Create edge error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create edge');
  }
});

languageLocales.get('/:id/mappings', async (c) => {
  const id = c.param('id');
  const query = parseReferenceQuery({
    q: '',
    limit: c.req.query('limit'),
    offset: c.req.query('skip') ?? c.req.query('offset'),
  });
  const result = await getExpressionMappings(c.env.DB, id, { limit: query.limit, offset: query.offset });
  return paginated(c, result.items, result.total, query.offset, query.limit);
});

languageLocales.post('/:id/split', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    if (user?.role !== 'admin') return forbidden(c, 'FORBIDDEN', 'Split requires admin role');
    const id = c.param('id');
    const body = await c.req.json().catch(() => ({}));
    const edgeIds = Array.isArray(body?.edge_ids) ? body.edge_ids.filter((e: unknown): e is string => typeof e === 'string') : [];
    try {
      const result = await splitExpression(c.env.DB, {
        source_expression_id: id,
        edge_ids: edgeIds,
        created_by: user?.id ?? 0,
      });
      return success(c, result, 'Expression split completed');
    } catch (error) {
      if (error instanceof SplitError) {
        if (error.code === 'EXPRESSION_NOT_FOUND') return c.json({ success: false, error: error.code, message: 'Expression not found' }, 404);
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Split expression error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to split expression');
  }
});
```

- [x] **Step 4: 等 wrangler hot-reload,重跑整合測試**

wrangler dev 會自動 reload `backend/src` 的變更;等 2–3 秒再跑:

```bash
cd backend && npx vitest run tests/mappingsIntegration.test.ts
```

Expected: 全部 PASS(7 個 it:mappings 5 + split 2)。

- [x] **Step 5: 跑 type-check 確認無型別錯誤**

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
    "backend/src/routes/index.ts",
    "backend/src/routes/expressions.ts",
    "backend/src/services/mappings.ts",
    "backend/src/services/splits.ts"
  ]
}
```

Expected: 只可能出現 `utils/response.ts`(status: number 的 overload)與 `types.ts`(`D1Database` global)兩處**既有**錯誤;`mappings.ts`／`splits.ts`／新增的 route handler 不得有新錯誤。

- [x] **Step 6: Commit**

```bash
git add backend/src/routes/expressions.ts backend/tests/mappingsIntegration.test.ts
git commit -m "feat(api): expose mapping edge and split endpoints"
```

Commit 後 `git status --short` 應乾淨。

---

## Task 5: 全量回歸與收尾驗證

驗證整個 Plan 4 沒有破壞既有功能,並完成最終檢查。

**Files:** 無(若有修正在此提交)

- [x] **Step 1: 後端完整測試(已知既有失敗除外)**

worker 在 8788 的前提下:

```bash
cd backend && npm test
```

Expected: 所有 test file 通過,**除了** `auth.test.ts` 中 `reuses an existing expression ...`(Plan 1 起既有的 stale 測試)——該失敗為已知,不回修、不改動 `auth.test.ts`。

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

先確保一個 admin token(直接在 sqlite 升級某 user):

```bash
python3 - <<'EOF'
import glob, sqlite3
path = sorted(glob.glob('backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/*.sqlite'))[0]
con = sqlite3.connect(path)
con.execute("UPDATE users SET role='admin' WHERE username=(SELECT username FROM users LIMIT 1)")
con.commit()
print('promoted', con.execute("SELECT username FROM users WHERE role='admin' LIMIT 1").fetchone())
EOF
```

登入取得 token 後:

```bash
curl -s 'http://127.0.0.1:8788/api/v2/expressions/search?q=食' | python3 -m json.tool
curl -s -X POST 'http://127.0.0.1:8788/api/v2/expressions/<ID_A>/mappings' \
  -H 'content-type: application/json' -H "authorization: Bearer <TOKEN>" \
  -d '{"target_expression_id":"<ID_B>","source":"manual"}' | python3 -m json.tool
curl -s "http://127.0.0.1:8788/api/v2/expressions/<ID_A>/mappings" | python3 -m json.tool
```

Expected: edge 建立(201)、列表含 neighbor info、分頁結構正確。

- [x] **Step 4: 文件與空白檢查**

```bash
git diff --check
git status --short
```

Expected: `git diff --check` 無輸出;`git status --short` 乾淨。

- [x] **Step 5: 若有修正則 Commit**

```bash
git add <修正的檔案>
git commit -m "fix(api): <簡述>"
```

若 Step 1–4 全過且無修正,此 step 跳過。

---

## Self-Review

**1. Spec coverage:**

- §10.1 `expression_edges` 表(ULID id、pair CHECK a < b、UNIQUE pair、score default 0、source TEXT NOT NULL、三條 FK)→ Task 1 schema + Task 2 service。
- §10.1 Edge ID 使用 ULID → Task 2 `createEdge` 使用 `utils/ulid.ts` 的 `ulid()`。
- §10.1「先以字典序 canonicalize pair，再用唯一約束重用既有 edge」→ Task 2 `canonicalizeEdgePair` + `createEdge` find-or-reuse。
- §10.2 `expression_splits` 表(source/target/created_by NOT NULL/created_at + 三 FK)→ Task 1。
- §10.2 `expression_split_moves` 表(聯合 PK、previous/new 端點、兩 FK)→ Task 1。
- §10.2 Split 只允許 admin → Task 4 route 檢查 `role === 'admin'`(`forbidden` 403)。
- §10.2 Split 原子操作 7 步驟:驗證(step 1)、MAX homograph_index + 1(step 2)、建立 split audit + 新 Expression with system-split source(step 3)、移動 edge 端點並重排 pair(step 4)、保留 edge ID/score(step 5 隱含於 UPDATE)、寫 move audit(step 6)→ Task 3 `splitExpression`;step 7(UI Locale coverage 重算)→ **no-op 佔位,待 Plan 7 接線**(spec gap decision 3)。
- §10.2 Split 不複製 readings/attestations/handbook items → Task 3 不含此邏輯(符合)。
- §10.2 任何驗證/唯一/寫入失敗必須回滾 → Task 3 使用 D1 `db.batch()`(單一 transaction)。
- §13.2 `GET /expressions/:id/mappings` → Task 4。`POST /expressions/:id/split` → Task 4。`POST /expressions/:id/mappings` → Task 4(**§13.2 未明列但為 GET 的自然對偶,split 測試需要它;已於 spec gap decision 2 裁定**)。
- §13.2 Split body `{ "edge_ids": [...] }` → Task 4 route。
- §14 穩定錯誤碼:`EXPRESSION_SPLIT_EMPTY`(Task 3+4)、`EXPRESSION_SPLIT_EDGE_NOT_ADJACENT`(Task 3+4)、`EXPRESSION_SPLIT_CONFLICT`(Task 3);`EXPRESSION_NOT_FOUND`(沿用 Plan 3);constraint error 映射而非暴露 → Task 3 `db.batch()` catch UNIQUE。
- §4.11 穩定排序(mappings: `score DESC, created_at ASC, edge_id ASC`)與 limit clamp `[1,50]` → Task 2 `getExpressionMappings` + Task 4 route(經 `parseReferenceQuery`)。
- §4.7 Edge pair 端點穩定排序且同 pair 只有一條 edge → Task 2 `canonicalizeEdgePair` + schema UNIQUE。
- §17.1 Split 權限、配置、edge move、pair ordering、vote 保留(votes 不存在故 N/A)、audit、rollback → Task 3+4;Contribution clique 與 duplicate pair reuse → Task 2 `createEdgesBatch` + Task 4 整合測試。

**未覆蓋(留給後續 plan):** votes 表(spec 無 DDL,split 的 edge ID 穩定性已保證其引用不破);contributions batch route(§13 無 API 契約,service 層已備);UI Locale coverage/revision 重算(split step 7,依賴 Plan 7);`POST /:id/readings`(§9.2);preferences(§11、§13.3);UI localization(§12、§13.4);前端(§15);`scripts/i18n` catalog 遷移(§16.6)。

**2. Placeholder scan:** 每個 step 都有完整程式碼與可執行命令,無 TBD/「implement later」。整合測試的 admin token helper(`getAdminToken`)使用 `node:sqlite` 直接升級 user role——這是整合測試的合理 fixture 操作,不是 placeholder。split step 7 的 no-op 在 spec gap decision 3 已明確說明,Task 3 的 `splitExpression` 在 `db.batch()` 後直接 return(無 step 7 呼叫),待 Plan 7 在 return 前插入 localization service 通知。

**3. Type consistency:** `EdgeRow`／`EdgeWithNeighborRow`／`SplitRow`／`SplitMoveRow` 在 Task 1(types/mapping.ts)定義;`MappingError`／`canonicalizeEdgePair`／`createEdge`／`createEdgesBatch`／`getExpressionMappings` 在 Task 2 定義並被 Task 4 import;`SplitError`／`splitExpression` 在 Task 3 定義並被 Task 4 import;`createEdge` 回傳 `{ edge: EdgeRow; created: boolean }` 與 route 的 `created(c, result, ...)` / `success(c, result, ...)` 一致;`splitExpression` 回傳 `{ split_id, target_expression_id, moved_edge_count }` 與 route 的 `success(c, result, ...)` 一致;`paginated(c, items, total, skip, limit)` 呼叫順序與 Plan 1-3 一致;`forbidden(c, error, message)` 簽名與 `utils/response.ts` 一致(403);edge `source` 欄位是純文字(非 FK),在 service/route 中以 string 傳遞,不與 `sources` 表的兩層模型混淆。
