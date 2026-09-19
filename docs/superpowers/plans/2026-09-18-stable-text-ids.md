# 稳定文字标识（stable text keys）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 expression 的对外标识（页面 URL 与 API 路径参数）从内部整数 id 切换为稳定自然文字 key（`lang_code + text + homograph_index`），使公开链接对 id 重编号（D1→PG 迁移）免疫。

**Architecture:** 后端新增 `expressionKeys` 解析服务，`/expressions/*` 端点在数字 id 之外接受双段文字 key（`/:lang/:text`）；前端路由改用 `/mapping/:lang/:text`，旧数字 URL 由 route guard 解析后 `router.replace` 转址。API 回应保留数字 id 供内部操作（split `edge_ids` 等）；各 payload 补齐 `homograph_index` 供前端组 key。

**Tech Stack:** Hono + Cloudflare Workers D1（backend）、Vue 3 + vue-router 4 + axios + vitest（web）、vitest（backend）。

**Spec:** `docs/superpowers/specs/2026-09-18-stable-text-ids-design.md`（含 §1 修订的后缀消歧规则，以本计划代码为准）。

## Global Constraints

- Key 解析规则（两侧必须一致）：对 decode 后的 text，取最后一条 `~(\d+)$` 为 `homograph_index`，其余为文本本体；无后缀即 1。构造时 `homograph_index > 1` 或文本匹配 `~\d+$` 则必须追加 `~{N}`。
- `lang_code` 格式：`/^[A-Za-z0-9-]+$/`，查找前转小写。
- key 查找 SQL 必须 hit 现有 UNIQUE index：`WHERE l.code=? AND e.text=? AND e.homograph_index=?`（`expressions` join `languages`）。
- split 的 body `edge_ids`、`POST /:id/mappings` 的 body `target_expression_id` 维持数字 id，不改。
- 数字单段路由（`/expressions/:id`、`/mapping/:id`）保留并继续工作（API 双形式；页面转址）。
- 错误码沿用现有 envelope：key 格式无效 → 400 `INVALID_EXPRESSION_KEY`；找不到 → 404 `EXPRESSION_NOT_FOUND`。
- 测试命令：backend 一律 `cd backend && npx vitest run <file>`；web 一律 `cd web && npx vitest run <file>`。每个 task 结束前该 task 的相关测试文件必须全绿。
- 所有 commit message 结尾附 `Co-Authored-By: Claude <noreply@anthropic.com>`。
- 注意：主 workspace 有未提交的 D1→PG 迁移改动，本计划在 worktree（HEAD `d168790`）上执行，勿参照主 workspace 的未提交文件内容。

---

### Task 1: backend expressionKeys 解析服务

**Files:**
- Modify: `backend/src/services/expressions.ts:7`（导出 `EXPRESSION_COLUMNS`）
- Create: `backend/src/services/expressionKeys.ts`
- Test: `backend/tests/expressionKeys.test.ts`

**Interfaces:**
- Consumes: `ExpressionRow`（`backend/src/types/expression.ts`）
- Produces:
  - `interface ExpressionKey { lang_code: string; text: string; homograph_index: number }`
  - `parseExpressionKey(lang: string, text: string): ExpressionKey | null`
  - `resolveExpressionKey(db: D1Database, key: ExpressionKey): Promise<ExpressionRow | null>`

- [ ] **Step 1: Write the failing test**

创建 `backend/tests/expressionKeys.test.ts`（`fakeD1` helper 复制自 `backend/tests/expressions.test.ts:19-42` 的现有惯例）：

```typescript
import { describe, expect, it } from 'vitest';
import { parseExpressionKey, resolveExpressionKey } from '../src/services/expressionKeys';
import type { ExpressionRow } from '../src/types/expression';

type Handler = () => unknown;

type D1Mock = import('@cloudflare/workers-types').D1Database & {
  sqlLog: string[];
};

function fakeD1(handlers: Record<string, Handler>): D1Mock {
  const sqlLog: string[] = [];
  const prepare = (sql: string) => {
    sqlLog.push(sql);
    const handler = handlers[sql] ?? Object.entries(handlers).find(
      ([registered]) => registered.replace(/\s+/g, ' ').trim() === sql.replace(/\s+/g, ' ').trim(),
    )?.[1];
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
  const batch = async (statements: Array<{ run(): Promise<unknown> }>) => Promise.all(statements.map((statement) => statement.run()));
  return { prepare, batch, sqlLog } as unknown as D1Mock;
}

const EXPRESSION_COLUMNS = 'e.id, e.language_id, l.code AS lang_code, e.text, e.homograph_index, e.pos_mask, e.source_id, e.created_by, e.created_at';
const RESOLVE_SQL = `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code=? AND e.text=? AND e.homograph_index=?`;

describe('parseExpressionKey', () => {
  it('parses a plain key as homograph 1', () => {
    expect(parseExpressionKey('en', 'hello')).toEqual({ lang_code: 'en', text: 'hello', homograph_index: 1 });
  });

  it('parses a trailing homograph suffix', () => {
    expect(parseExpressionKey('en', 'hello~2')).toEqual({ lang_code: 'en', text: 'hello', homograph_index: 2 });
  });

  it('takes only the last suffix so literal tildes survive', () => {
    expect(parseExpressionKey('en', 'hello~2~1')).toEqual({ lang_code: 'en', text: 'hello~2', homograph_index: 1 });
    expect(parseExpressionKey('en', 'spa~1~3')).toEqual({ lang_code: 'en', text: 'spa~1', homograph_index: 3 });
  });

  it('lowercases the language code', () => {
    expect(parseExpressionKey('EN', 'hello')?.lang_code).toBe('en');
  });

  it('rejects invalid language codes', () => {
    expect(parseExpressionKey('en-US extra', 'hello')).toBeNull();
    expect(parseExpressionKey('e:n', 'hello')).toBeNull();
    expect(parseExpressionKey('', 'hello')).toBeNull();
  });

  it('rejects a zero homograph suffix', () => {
    expect(parseExpressionKey('en', 'hello~0')).toBeNull();
  });

  it('keeps a trailing tilde without digits as text', () => {
    expect(parseExpressionKey('en', 'hello~')).toEqual({ lang_code: 'en', text: 'hello~', homograph_index: 1 });
  });
});

describe('resolveExpressionKey', () => {
  it('finds an expression by natural key', async () => {
    const row: ExpressionRow = {
      id: 7, language_id: 1, lang_code: 'en', text: 'hello', homograph_index: 2,
      pos_mask: 0, source_id: null, created_by: 1, created_at: '2026-08-12 00:00:00',
    };
    const db = fakeD1({ [RESOLVE_SQL]: () => row });
    const result = await resolveExpressionKey(db, { lang_code: 'en', text: 'hello', homograph_index: 2 });
    expect(result).toEqual(row);
  });

  it('returns null when no row matches', async () => {
    const db = fakeD1({ [RESOLVE_SQL]: () => null });
    const result = await resolveExpressionKey(db, { lang_code: 'en', text: 'missing', homograph_index: 1 });
    expect(result).toBeNull();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run tests/expressionKeys.test.ts`
Expected: FAIL — `Cannot find module '../src/services/expressionKeys'`

- [ ] **Step 3: Write minimal implementation**

`backend/src/services/expressions.ts:7` 把 `const EXPRESSION_COLUMNS = ...` 改为 `export const EXPRESSION_COLUMNS = ...`（一行改动）。

创建 `backend/src/services/expressionKeys.ts`：

```typescript
import type { D1Database } from '@cloudflare/workers-types';
import { EXPRESSION_COLUMNS } from './expressions';
import type { ExpressionRow } from '../types/expression';

export interface ExpressionKey { lang_code: string; text: string; homograph_index: number }

const LANG_CODE_PATTERN = /^[A-Za-z0-9-]+$/;

/**
 * Parses the decoded path segments of an expression key. The homograph suffix
 * is the LAST `~<digits>` run in the text segment, so texts that literally end
 * in `~2` are addressed as `~2~1` (see the spec's suffix disambiguation rule).
 */
export function parseExpressionKey(lang: string, text: string): ExpressionKey | null {
  if (!LANG_CODE_PATTERN.test(lang)) return null;
  const match = /^(.*)~(\d+)$/s.exec(text);
  if (!match) return { lang_code: lang.toLowerCase(), text, homograph_index: 1 };
  const homographIndex = Number(match[2]);
  if (!Number.isSafeInteger(homographIndex) || homographIndex < 1) return null;
  return { lang_code: lang.toLowerCase(), text: match[1], homograph_index: homographIndex };
}

export async function resolveExpressionKey(db: D1Database, key: ExpressionKey): Promise<ExpressionRow | null> {
  const row = await db.prepare(
    `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code=? AND e.text=? AND e.homograph_index=?`,
  ).bind(key.lang_code, key.text, key.homograph_index).first<ExpressionRow>();
  return row ?? null;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run tests/expressionKeys.test.ts`
Expected: PASS（全部用例）

- [ ] **Step 5: Commit**

```bash
git add backend/src/services/expressionKeys.ts backend/src/services/expressions.ts backend/tests/expressionKeys.test.ts
git commit -m "feat(api): add expression text-key parsing and resolution

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 2: backend key-form 路由与 split target key

**Files:**
- Modify: `backend/src/routes/expressions.ts`
- Modify: `backend/src/services/splits.ts`
- Test: `backend/tests/expressionKeyRoutes.test.ts`

**Interfaces:**
- Consumes: `parseExpressionKey` / `resolveExpressionKey` / `ExpressionKey`（Task 1）；现有 services（`getExpression`、`getMappingGraph`、`createEdge`、`splitExpression` 等）
- Produces:
  - `GET /expressions/:lang/:text`（与 `/:id` 等价的全部 7 个端点的 key 形式）
  - `splitExpression` 回应增加 `target: { lang_code: string; text: string; homograph_index: number }`
  - 内部 helper `resolveTarget(c, form)`（不导出）

- [ ] **Step 1: Write the failing test**

创建 `backend/tests/expressionKeyRoutes.test.ts`（`fakeD1` helper 同 Task 1 复制现有惯例）：

```typescript
import { describe, expect, it } from 'vitest';
import { Hono } from 'hono';
import expressions from '../src/routes/expressions';
import { splitExpression } from '../src/services/splits';

type Handler = () => unknown;

type D1Mock = import('@cloudflare/workers-types').D1Database & { sqlLog: string[] };

function fakeD1(handlers: Record<string, Handler>): D1Mock {
  const sqlLog: string[] = [];
  const prepare = (sql: string) => {
    sqlLog.push(sql);
    const handler = handlers[sql] ?? Object.entries(handlers).find(
      ([registered]) => registered.replace(/\s+/g, ' ').trim() === sql.replace(/\s+/g, ' ').trim(),
    )?.[1];
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
  const batch = async (statements: Array<{ run(): Promise<unknown> }>) => Promise.all(statements.map((statement) => statement.run()));
  return { prepare, batch, sqlLog } as unknown as D1Mock;
}

const EXPRESSION_COLUMNS = 'e.id, e.language_id, l.code AS lang_code, e.text, e.homograph_index, e.pos_mask, e.source_id, e.created_by, e.created_at';
const KEY_SQL = `SELECT ${EXPRESSION_COLUMNS} FROM expressions e JOIN languages l ON l.id=e.language_id WHERE l.code=? AND e.text=? AND e.homograph_index=?`;
const LOCALE_LINKS_SQL = 'SELECT x.expression_id,x.locale_id,l.code AS language_locale_code,l.name AS locale_display_name FROM expression_locale_links x JOIN language_locales l ON l.id=x.locale_id WHERE x.expression_id=? ORDER BY l.code';
const READINGS_SQL = 'SELECT r.expression_id, r.locale_id, l.code AS language_locale_code, l.name AS locale_display_name, r.scheme, r.value, r.source_id FROM expression_readings r JOIN language_locales l ON l.id=r.locale_id WHERE r.expression_id=? ORDER BY l.code,r.scheme,r.value';
const POS_SQL = 'SELECT code,name_en FROM parts_of_speech WHERE (? & (1 << bit_index)) != 0 ORDER BY sort_order';
const SOURCES_SQL = 'SELECT source_id,source_marker FROM expression_sources WHERE expression_id=? ORDER BY source_id,source_marker';

function keyDb(row: unknown) {
  return fakeD1({
    [KEY_SQL]: () => row,
    [LOCALE_LINKS_SQL]: () => ({ results: [] }),
    [READINGS_SQL]: () => ({ results: [] }),
    [POS_SQL]: () => ({ results: [] }),
    [SOURCES_SQL]: () => ({ results: [] }),
  });
}

function app(db: D1Mock) {
  const application = new Hono<{ Bindings: { DB: import('@cloudflare/workers-types').D1Database; SECRET_KEY: string } }>();
  application.route('/expressions', expressions);
  return application;
}

const row = {
  id: 7, language_id: 1, lang_code: 'en', text: 'hello', homograph_index: 1,
  pos_mask: 0, source_id: null, created_by: 1, created_at: '2026-08-12 00:00:00',
};

describe('GET /expressions/:lang/:text', () => {
  it('resolves an expression by text key', async () => {
    const response = await app(keyDb(row)).request('http://example.test/expressions/en/hello', undefined, { DB: keyDb(row), SECRET_KEY: 'test' });
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { expression: { id: string; homograph_index: number } } };
    expect(body.data.expression.id).toBe('7');
    expect(body.data.expression.homograph_index).toBe(1);
  });

  it('parses the homograph suffix', async () => {
    const db = keyDb({ ...row, id: 9, homograph_index: 2 });
    const response = await app(db).request('http://example.test/expressions/en/hello~2', undefined, { DB: db, SECRET_KEY: 'test' });
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { expression: { id: string; homograph_index: number } } };
    expect(body.data.expression.id).toBe('9');
    expect(body.data.expression.homograph_index).toBe(2);
  });

  it('keeps encoded slashes inside the text segment', async () => {
    const db = keyDb({ ...row, text: 'hello/world' });
    const response = await app(db).request('http://example.test/expressions/en/hello%2Fworld', undefined, { DB: db, SECRET_KEY: 'test' });
    expect(response.status).toBe(200);
    const body = await response.json() as { data: { expression: { text: string } } };
    expect(body.data.expression.text).toBe('hello/world');
  });

  it('returns 404 when the key does not resolve', async () => {
    const db = keyDb(null);
    const response = await app(db).request('http://example.test/expressions/en/missing', undefined, { DB: db, SECRET_KEY: 'test' });
    expect(response.status).toBe(404);
    const body = await response.json() as { error: string };
    expect(body.error).toBe('EXPRESSION_NOT_FOUND');
  });

  it('returns 400 for an invalid language segment', async () => {
    const db = keyDb(row);
    const response = await app(db).request('http://example.test/expressions/e%3An/hello', undefined, { DB: db, SECRET_KEY: 'test' });
    expect(response.status).toBe(400);
    const body = await response.json() as { error: string };
    expect(body.error).toBe('INVALID_EXPRESSION_KEY');
  });
});

describe('split target key fields', () => {
  it('returns the target expression natural key', async () => {
    const db = fakeD1({
      'SELECT e.language_id,e.text,e.homograph_index,e.pos_mask,e.source_id,l.code AS lang_code FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?':
        () => ({ language_id: 1, text: 'hello', homograph_index: 1, pos_mask: 0, source_id: null, lang_code: 'en' }),
      'SELECT id,expression_a_id,expression_b_id FROM expression_edges WHERE id IN (?)':
        () => ({ results: [{ id: 5, expression_a_id: 1, expression_b_id: 7 }] }),
      'SELECT MAX(homograph_index) AS max_idx FROM expressions WHERE language_id=? AND text=?':
        () => ({ max_idx: 1 }),
      'INSERT INTO expressions(language_id,text,homograph_index,pos_mask,source_id,created_by) VALUES(?,?,?,?,?,?) RETURNING id':
        () => ({ id: 9 }),
      'INSERT INTO expression_splits(source_expression_id,target_expression_id,created_by) VALUES(?,?,?) RETURNING id':
        () => ({ id: 3 }),
      'INSERT INTO expression_split_moves(split_id,edge_id) VALUES(?,?)': () => ({ success: true }),
      'UPDATE expression_edges SET expression_a_id=?,expression_b_id=? WHERE id=?': () => ({ success: true }),
    });
    const result = await splitExpression(db, { source_expression_id: 1, edge_ids: [5], created_by: 1 });
    expect(result.target).toEqual({ lang_code: 'en', text: 'hello', homograph_index: 2 });
    expect(result.target_expression_id).toBe(9);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run tests/expressionKeyRoutes.test.ts`
Expected: FAIL — `/expressions/en/hello` 返回 404（无此路由）；split 缺 `target` 字段

- [ ] **Step 3: Implement**

**(a) `backend/src/services/splits.ts`**：把 source 查询（当前第 6 行内的 `SELECT language_id,text,homograph_index,pos_mask,source_id FROM expressions WHERE id=?`）改为 join languages 取 `lang_code`：

```typescript
SELECT e.language_id,e.text,e.homograph_index,e.pos_mask,e.source_id,l.code AS lang_code FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?
```

source 型别加上 `lang_code: string`；返回值增加 target 自然键（新 homograph 为 `max+1`）：

```typescript
return { split_id: split.id, target_expression_id: target.id, moved_edge_count: edges.results.length, target: { lang_code: source.lang_code, text: source.text, homograph_index: (max?.max_idx ?? 0) + 1 } };
```

（该文件是单行压缩风格，保持原风格就地修改。）

**(b) `backend/src/routes/expressions.ts`**：

新增 import 与共享解析 helper（放在 `expressionDto` 定义之后）：

```typescript
import { parseExpressionKey, resolveExpressionKey } from '../services/expressionKeys';

type TargetResult = { id: number } | { response: Response };
type RouteContext = Parameters<Parameters<typeof expressions.get>[1]>[0];

async function resolveTarget(c: RouteContext, form: 'id' | 'key'): Promise<TargetResult> {
  if (form === 'id') {
    const id = numberId(c.req.param('id'));
    return id ? { id } : { response: badRequest(c, 'INVALID_EXPRESSION_ID') };
  }
  const key = parseExpressionKey(c.req.param('lang'), c.req.param('text'));
  if (!key) return { response: badRequest(c, 'INVALID_EXPRESSION_KEY') };
  const row = await resolveExpressionKey(c.env.DB, key);
  return row ? { id: row.id } : { response: notFoundCode(c, 'EXPRESSION_NOT_FOUND', 'Expression not found') };
}
```

然后把现有 7 个 `/:id` 端点的 body 各提取为内部函数，再双注册。以 detail 端点为例（其余 6 个同构：`/:id/graph`、`/:id/locales`、`/:id/readings`、`/:id/mappings`、`/:id/split`、`/:id/edges`，注意保留各自的 middleware：graph 是 `optionalAuth`、其余 mutation 是 `requireAuth`，split 另有 admin 检查）：

```typescript
async function showExpression(c: RouteContext, id: number) {
  const result = await getExpression(c.env.DB, id); if (!result) return notFoundCode(c, 'EXPRESSION_NOT_FOUND', 'Expression not found');
  return success(c, { ...result, expression: expressionDto(result.expression), locales: result.locales.map((row) => ({ ...row, expression_id: serializeIntegerId(row.expression_id), locale_id: serializeIntegerId(row.locale_id) })), readings: result.readings.map((row) => ({ ...row, expression_id: serializeIntegerId(row.expression_id), locale_id: serializeIntegerId(row.locale_id) })), sources: result.sources.map((row) => ({ ...row, source_id: serializeIntegerId(row.source_id) })) });
}

expressions.get('/:id', async (c) => {
  const target = await resolveTarget(c, 'id');
  return 'response' in target ? target.response : showExpression(c, target.id);
});
expressions.get('/:lang/:text', async (c) => {
  const target = await resolveTarget(c, 'key');
  return 'response' in target ? target.response : showExpression(c, target.id);
});
```

对每个端点成对注册（key 形式的路径就是把 `:id` 换成 `:lang/:text`）：

| 现有 | 新增 |
|---|---|
| `expressions.get('/:id', ...)` | `expressions.get('/:lang/:text', ...)` |
| `expressions.get('/:id/graph', optionalAuth, ...)` | `expressions.get('/:lang/:text/graph', optionalAuth, ...)` |
| `expressions.post('/:id/locales', requireAuth, ...)` | `expressions.post('/:lang/:text/locales', requireAuth, ...)` |
| `expressions.post('/:id/readings', requireAuth, ...)` | `expressions.post('/:lang/:text/readings', requireAuth, ...)` |
| `expressions.post('/:id/mappings', requireAuth, ...)` | `expressions.post('/:lang/:text/mappings', requireAuth, ...)` |
| `expressions.post('/:id/split', requireAuth, ...)` | `expressions.post('/:lang/:text/split', requireAuth, ...)` |
| `expressions.get('/:id/edges', ...)` | `expressions.get('/:lang/:text/edges', ...)` |

split 端点的回应增加 target 自然键（回应当前为 `{ ...result, split_id, target_expression_id }`）：

```typescript
return success(c, { ...result, split_id: serializeIntegerId(result.split_id), target_expression_id: serializeIntegerId(result.target_expression_id), target: result.target });
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && npx vitest run tests/expressionKeyRoutes.test.ts tests/expressions.test.ts`
Expected: PASS（新测试与既有测试全绿；既有测试验证数字形式未回归）

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/expressions.ts backend/src/services/splits.ts backend/tests/expressionKeyRoutes.test.ts
git commit -m "feat(api): accept expression text keys on all expression endpoints

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 3: backend payload 补齐 homograph_index

**Files:**
- Modify: `backend/src/services/mappingGraph.ts`（root 与 hop 节点 SELECT、`MappingGraphNode`）
- Modify: `backend/src/routes/feed.ts:11`（feed SELECT）
- Modify: `backend/src/routes/handbooks.ts:20`（handbook items SELECT）
- Test: `backend/tests/mappingGraphV2.test.ts`、`backend/tests/feed.test.ts`（各加断言）

**Interfaces:**
- Consumes: 无新依赖
- Produces（前端 Task 6/8/9/10 依赖）:
  - graph 节点回应增加 `homograph_index: number`
  - feed 行回应增加 `a_homograph_index: number`、`b_homograph_index: number`
  - handbook item 回应增加 `homograph_index: number`

- [ ] **Step 1: Write the failing tests**

`backend/tests/mappingGraphV2.test.ts` 中找到验证节点字段的用例，在现有断言旁加（若无节点断言用例，加一个新 `it`，沿用该文件的 fakeD1 惯例）：

```typescript
it('includes homograph_index on graph nodes', async () => {
  // root SQL mock 的返回行加 homograph_index: 1；邻节点行同
  // 断言 getMappingGraph(...).nodes.every((node) => typeof node.homograph_index === 'number')
});
```

（具体 mock 构造参照该文件现有的 root/邻节点 SQL handler；root SQL 改为含 `e.homograph_index` 后 mock key 必须同步更新。）

`backend/tests/feed.test.ts` 中现有 feed 行断言旁加：

```typescript
expect(body.data[0].a_homograph_index).toBe(1);
expect(body.data[0].b_homograph_index).toBe(1);
```

（该文件 `fakeDb` 的行 mock 加上 `a_homograph_index: 1, b_homograph_index: 1`。）

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && npx vitest run tests/mappingGraphV2.test.ts tests/feed.test.ts`
Expected: FAIL — `homograph_index` / `a_homograph_index` 为 undefined

- [ ] **Step 3: Implement**

`backend/src/services/mappingGraph.ts`：
- root 查询（当前 `SELECT e.id,e.text,l.code AS lang_code,l.name_en AS language_name FROM expressions e JOIN languages l ON l.id=e.language_id WHERE e.id=?`）加 `e.homograph_index`；
- 邻节点 chunk 查询（同列清单，`WHERE e.id IN (...)`）同样加 `e.homograph_index`；
- `NodeRow` 型别加 `homograph_index: number`；
- `MappingGraphNode` interface 加 `homograph_index: number`；
- 两处 `nodes.set(...)` 的节点字面量加 `homograph_index: row.homograph_index`。

`backend/src/routes/expressions.ts` graph 端点的节点序列化（`nodes.map((node) => ({ ...node, expression_id: ... }))`）— spread 已带出 `homograph_index`（number，非 id），无需改动；确认即可。

`backend/src/routes/feed.ts:11` SELECT 列清单加：

```sql
a.homograph_index AS a_homograph_index, b.homograph_index AS b_homograph_index
```

（回应处 `...row` spread 自动带出。）

`backend/src/routes/handbooks.ts:20` items SELECT 的列清单在 `e.text` 后加 `e.homograph_index`，item 序列化处 `{...item, id: serializeIntegerId(item.id), ...}` spread 自动带出。

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && npx vitest run tests/mappingGraphV2.test.ts tests/feed.test.ts tests/expressions.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/services/mappingGraph.ts backend/src/routes/feed.ts backend/src/routes/handbooks.ts backend/tests/mappingGraphV2.test.ts backend/tests/feed.test.ts
git commit -m "feat(api): expose homograph_index on graph nodes, feed rows, handbook items

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 4: backend cacheHeaders 支持 key 形式

**Files:**
- Modify: `backend/src/middleware/cacheHeaders.ts:71-73`
- Test: 确认 `backend/tests/` 是否已有 cacheHeaders 测试文件；无则创建 `backend/tests/cacheHeaders.test.ts`

**Interfaces:**
- Consumes: `getCachePolicy`
- Produces: `/api/v2/expressions/{lang}/{text}[/graph|/edges|/form-edges]` 命中 `EXPRESSION_CACHE`

- [ ] **Step 1: Write the failing test**

```typescript
import { describe, expect, it } from 'vitest';
import { getCachePolicy } from '../src/middleware/cacheHeaders';

describe('expression read cache policy', () => {
  it('caches two-segment expression keys like numeric ids', () => {
    expect(getCachePolicy('https://example.test/api/v2/expressions/en/hello')).not.toBeNull();
    expect(getCachePolicy('https://example.test/api/v2/expressions/en/hello~2/graph')).not.toBeNull();
    expect(getCachePolicy('https://example.test/api/v2/expressions/en/hello/edges')).not.toBeNull();
    expect(getCachePolicy('https://example.test/api/v2/expressions/123')).not.toBeNull();
    expect(getCachePolicy('https://example.test/api/v2/expressions/en/hello/readings')).toBeNull();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && npx vitest run tests/cacheHeaders.test.ts`
Expected: FAIL — 两段 key 路径返回 null（注意 `/readings` 断言本来就应通过）

- [ ] **Step 3: Implement**

`matchesExpressionRead` 追加两段形式（保留现有单段正则）：

```typescript
function matchesExpressionRead(pathname: string): boolean {
  return pathname === '/api/v2/expressions/search'
    || /^\/api\/v2\/expressions\/[^/]+(?:\/mappings|\/edges|\/form-edges)?$/.test(pathname)
    || /^\/api\/v2\/expressions\/[^/]+\/[^/]+(?:\/mappings|\/edges|\/form-edges)?$/.test(pathname);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && npx vitest run tests/cacheHeaders.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/src/middleware/cacheHeaders.ts backend/tests/cacheHeaders.test.ts
git commit -m "fix(api): cache expression reads addressed by text keys

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 5: web expressionUrl 工具

**Files:**
- Create: `web/src/utils/expressionUrl.ts`
- Test: `web/src/utils/expressionUrl.test.ts`

**Interfaces:**
- Consumes: 无
- Produces（Task 6-10 依赖）:
  - `parseExpressionTextSegment(text: string): { text: string; homograph_index: number }`
  - `encodeExpressionTextWithHomograph(text: string, homographIndex?: number): string`
  - `expressionPath(langCode: string, text: string, homographIndex?: number): string`
  - `mapLensPath(langCode: string, text: string, homographIndex?: number): string`

- [ ] **Step 1: Write the failing test**

```typescript
import { describe, expect, it } from 'vitest'
import { encodeExpressionTextWithHomograph, expressionPath, mapLensPath, parseExpressionTextSegment } from './expressionUrl'

describe('parseExpressionTextSegment', () => {
  it('defaults to homograph 1', () => {
    expect(parseExpressionTextSegment('hello')).toEqual({ text: 'hello', homograph_index: 1 })
  })
  it('takes the last suffix', () => {
    expect(parseExpressionTextSegment('hello~2')).toEqual({ text: 'hello', homograph_index: 2 })
    expect(parseExpressionTextSegment('hello~2~1')).toEqual({ text: 'hello~2', homograph_index: 1 })
  })
  it('keeps a trailing tilde without digits', () => {
    expect(parseExpressionTextSegment('hello~')).toEqual({ text: 'hello~', homograph_index: 1 })
  })
})

describe('encodeExpressionTextWithHomograph', () => {
  it('omits the suffix for homograph 1 plain text', () => {
    expect(encodeExpressionTextWithHomograph('hello')).toBe('hello')
  })
  it('appends the suffix for homographs above 1', () => {
    expect(encodeExpressionTextWithHomograph('hello', 2)).toBe('hello~2')
  })
  it('disambiguates texts that end in tilde digits', () => {
    expect(encodeExpressionTextWithHomograph('hello~2', 1)).toBe('hello~2~1')
    expect(encodeExpressionTextWithHomograph('hello~2', 3)).toBe('hello~2~3')
  })
  it('percent-encodes reserved characters', () => {
    expect(encodeExpressionTextWithHomograph('hello world')).toBe('hello%20world')
    expect(encodeExpressionTextWithHomograph('你/好')).toBe('%E4%BD%A0%2F%E5%A5%BD')
  })
})

describe('expressionPath', () => {
  it('builds the canonical mapping path', () => {
    expect(expressionPath('en', 'hello')).toBe('/mapping/en/hello')
    expect(expressionPath('en', 'hello', 2)).toBe('/mapping/en/hello~2')
    expect(expressionPath('nan', '食', 1)).toBe('/mapping/nan/%E9%A3%9F')
  })
  it('round-trips through parseExpressionTextSegment', () => {
    for (const [text, homo] of [['hello', 1], ['hello', 2], ['hello~2', 1], ['hello~2', 2], ['你 好', 3]] as const) {
      const segment = expressionPath('en', text, homo).split('/').pop()!
      const parsed = parseExpressionTextSegment(decodeURIComponent(segment))
      expect(parsed).toEqual({ text, homograph_index: homo })
    }
  })
})

describe('mapLensPath', () => {
  it('builds the map lens path', () => {
    expect(mapLensPath('en', 'hello', 2)).toBe('/map/en/hello~2')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd web && npx vitest run src/utils/expressionUrl.test.ts`
Expected: FAIL — module not found

- [ ] **Step 3: Implement**

```typescript
const TRAILING_HOMOGRAPH = /~\d+$/

export function parseExpressionTextSegment(text: string): { text: string; homograph_index: number } {
  const match = /^(.*)~(\d+)$/s.exec(text)
  if (!match) return { text, homograph_index: 1 }
  return { text: match[1], homograph_index: Number(match[2]) }
}

export function encodeExpressionTextWithHomograph(text: string, homographIndex = 1): string {
  const needsSuffix = homographIndex > 1 || TRAILING_HOMOGRAPH.test(text)
  return needsSuffix ? `${encodeURIComponent(text)}~${homographIndex}` : encodeURIComponent(text)
}

export function expressionPath(langCode: string, text: string, homographIndex = 1): string {
  return `/mapping/${encodeURIComponent(langCode)}/${encodeExpressionTextWithHomograph(text, homographIndex)}`
}

export function mapLensPath(langCode: string, text: string, homographIndex = 1): string {
  return `/map/${encodeURIComponent(langCode)}/${encodeExpressionTextWithHomograph(text, homographIndex)}`
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd web && npx vitest run src/utils/expressionUrl.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add web/src/utils/expressionUrl.ts web/src/utils/expressionUrl.test.ts
git commit -m "feat(web): add expression text-key URL helpers

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 6: web API 层改用 key 参数

**Files:**
- Modify: `web/src/api/expressions.ts`
- Modify: `web/src/api/morphology.ts`
- Modify: `web/src/composables/useExpressions.ts`（仅型别放宽，逻辑不变）
- Test: `web/src/api/expressions.test.ts`、`web/src/api/morphology.test.ts`

**Interfaces:**
- Consumes: `encodeExpressionTextWithHomograph`（Task 5）
- Produces（Task 7-10 依赖）:
  - `interface ExpressionKeyInput { lang_code: string; text: string; homograph_index?: number }`
  - `type ExpressionTarget = ExpressionKeyInput | string | number`（object → key 路径；string/number → 数字 id 路径）
  - `getExpression(target: ExpressionTarget, hints?, signal?)`（key 或数字 id）
  - `getMappingGraph(target: ExpressionTarget, hops?, hints?, targetLanguage?, signal?)`
  - `getExpressionEdges(target: ExpressionTarget, limit?, cursor?, signal?)`
  - `putExpressionLocale(target, localeCode, signal?)` / `deleteExpressionLocale(target, localeCode, signal?)` / `createLocaleAttestation(target, input, signal?)` / `createReading(target, input, signal?)`
  - `splitExpression(target, edgeIds)` 回应型别 `{ target_expression_id: string; target: { lang_code: string; text: string; homograph_index: number } }`
  - `createExpression` 回应型别 `Promise<{ expression: { id: string; lang_code: string; text: string; homograph_index: number }; created: boolean }>`
  - interface 更新：`ExpressionDetail.expression` 加 `homograph_index: number`；`SearchHit` 加 `homograph_index?: number`；`web/src/components/mapping/mappingGraphTypes.ts` 的 `MappingGraphNode` 加 `homograph_index: number`；`api/morphology.ts` 的 `FormEdgeExpressionSummary` 加 `homograph_index?: number`
  - `api/morphology.ts`：`getExpressionFormEdges(target: ExpressionTarget, ...)`、`createFormEdge(target: ExpressionTarget, ...)`

- [ ] **Step 1: Update the failing tests**

`web/src/api/expressions.test.ts` 改写为：

```typescript
import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from './client'
import { getExpression, getExpressionEdges, getMappingGraph, splitExpression } from './expressions'

vi.mock('./client', () => ({ default: { get: vi.fn(), post: vi.fn() } }))

describe('expressions API', () => {
  beforeEach(() => vi.mocked(api.get).mockResolvedValue({ data: { data: { items: [] } } }))

  it('builds text-key paths and unwraps the API envelope', async () => {
    const key = { lang_code: 'en', text: 'first' }
    await getExpression(key)
    expect(api.get).toHaveBeenCalledWith('/expressions/en/first', { params: { _content_revision: 0 }, signal: undefined })

    await getMappingGraph({ lang_code: 'en', text: 'first', homograph_index: 2 }, 2)
    expect(api.get).toHaveBeenLastCalledWith('/expressions/en/first~2/graph', { params: { hops: 2, _content_revision: 0 }, signal: undefined })

    await getExpressionEdges(key, 50, 10)
    expect(api.get).toHaveBeenLastCalledWith('/expressions/en/first/edges', { params: { limit: 50, cursor: 10 }, signal: undefined })
  })

  it('still accepts numeric ids for legacy callers', async () => {
    await getExpression('123456')
    expect(api.get).toHaveBeenCalledWith('/expressions/123456', { params: { _content_revision: 0 }, signal: undefined })
  })

  it('round-trips texts containing tilde digits', async () => {
    await getExpression({ lang_code: 'en', text: 'spa~1' })
    expect(api.get).toHaveBeenCalledWith('/expressions/en/spa~1~1', expect.anything())
  })

  it('submits selected edge IDs to the split endpoint and returns the target key', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: { data: { target_expression_id: '123456', target: { lang_code: 'en', text: 'first', homograph_index: 2 } } } })
    const result = await splitExpression({ lang_code: 'en', text: 'first' }, ['01EDGE', '02EDGE'])
    expect(api.post).toHaveBeenCalledWith('/expressions/en/first/split', { edge_ids: ['01EDGE', '02EDGE'] }, { signal: undefined })
    expect(result.target).toEqual({ lang_code: 'en', text: 'first', homograph_index: 2 })
  })
})
```

`web/src/api/morphology.test.ts` 中 form-edges 路径断言（当前 `/expressions/spa%3Agatas/form-edges`）改为 key 形式：

```typescript
await getExpressionFormEdges({ lang_code: 'spa', text: 'gatas' }, { limit: 50 })
expect(api.get).toHaveBeenLastCalledWith('/expressions/spa/gatas/form-edges', expect.objectContaining({ params: expect.objectContaining({ limit: 50 }) }))
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd web && npx vitest run src/api/expressions.test.ts src/api/morphology.test.ts`
Expected: FAIL — 现实现产出 id 路径

- [ ] **Step 3: Implement `web/src/api/expressions.ts`**

```typescript
import { encodeExpressionTextWithHomograph } from '@/utils/expressionUrl'

export interface ExpressionKeyInput { lang_code: string; text: string; homograph_index?: number }
export type ExpressionTarget = ExpressionKeyInput | string | number

const targetPath = (target: ExpressionTarget) =>
  typeof target === 'object' && target !== null
    ? `/expressions/${encodeURIComponent(target.lang_code)}/${encodeExpressionTextWithHomograph(target.text, target.homograph_index ?? 1)}`
    : `/expressions/${encodeURIComponent(String(target))}`
```

（替换现有 `const path = (id: string | number) => ...`；`path(id)` 调用点全改为 `targetPath(target)`，函数签名 `id: string | number` 全改为 `target: ExpressionTarget`。）接口型别按 Interfaces 清单补 `homograph_index`。`splitExpression` 回应型别改为 `Promise<{ target_expression_id: string; target: { lang_code: string; text: string; homograph_index: number } }>`；`createExpression` 加上显式回应型别。

**`web/src/api/morphology.ts`**：`const path = (id: string) => ...` 改用与上相同的 `targetPath`（从 `./expressions` export `targetPath` 并 import），`getExpressionFormEdges` / `createFormEdge` 参数 `id: string` 改为 `target: ExpressionTarget`；`FormEdgeExpressionSummary` 加 `homograph_index?: number`。

**`web/src/composables/useExpressions.ts`**：`detail(id: string, ...)` 与 `mappingGraph(id: string, ...)` 参数型别改为 `ExpressionTarget`（import 型别），逻辑不变。

**`web/src/components/mapping/mappingGraphTypes.ts`**：`MappingGraphNode` 加 `homograph_index: number`。

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd web && npx vitest run src/api/expressions.test.ts src/api/morphology.test.ts`
Expected: PASS（此时部分页面组件编译可能因型别不匹配报错——它们在 Task 8/9 修复；vitest 按文件运行不受影响。若 `npx vue-tsc --noEmit` 在本 task 报页面错误属预期，留待 Task 9 后统一验证。）

- [ ] **Step 5: Commit**

```bash
git add web/src/api/expressions.ts web/src/api/morphology.ts web/src/composables/useExpressions.ts web/src/components/mapping/mappingGraphTypes.ts web/src/api/expressions.test.ts web/src/api/morphology.test.ts
git commit -m "feat(web): address expression APIs by text key

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 7: web 路由 key 形式与数字转址 guard

**Files:**
- Modify: `web/src/router.ts`
- Modify: `web/src/locales/en.ts:112`（errors 增加 `expressionLinkExpired`）
- Test: `web/src/router.test.ts`

**Interfaces:**
- Consumes: `getExpression`（Task 6）、`expressionPath` / `mapLensPath`（Task 5）
- Produces（Task 8-10 依赖）:
  - 路由 `/mapping/:lang/:text(.+)`、`/map/:lang/:text(.+)`（canonical，params 为 `lang`/`text`）
  - `/mapping/:id`、`/map/:id` 保留并挂 `beforeEnter` 转址 guard
  - i18n key `errors.expressionLinkExpired`

- [ ] **Step 1: Write the failing test**

`web/src/router.test.ts` 的公共入口用例中把 `/mapping/nan%3Aexample`、`/map/nan%3Aexample` 替换为：

```typescript
'/mapping/nan/%E9%A3%9F',
'/mapping/nan/%E9%A3%9F~2',
'/map/nan/%E9%A3%9F',
```

并新增用例：

```typescript
import { vi } from 'vitest'

vi.mock('./api/expressions', () => ({
  getExpression: vi.fn().mockResolvedValue({
    expression: { id: '7', lang_code: 'nan', text: '食', homograph_index: 2 },
    locales: [], attestations: [], readings: [],
  }),
}))

it('redirects legacy numeric mapping urls to text keys', async () => {
  await router.push('/mapping/7')
  expect(router.currentRoute.value.path).toBe('/mapping/nan/%E9%A3%9F~2')
})

it('rejects non-numeric single-segment mapping urls without redirect', async () => {
  await router.push('/mapping/nan%3Aexample')
  expect(router.currentRoute.value.path).toBe('/mapping/nan%3Aexample')
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd web && npx vitest run src/router.test.ts`
Expected: FAIL — `/mapping/nan/食` 不解析；数字路径不转址

- [ ] **Step 3: Implement `web/src/router.ts`**

```typescript
import { getExpression } from './api/expressions'
import { expressionPath, mapLensPath } from './utils/expressionUrl'

const NUMERIC_ID = /^[1-9]\d*$/

function legacyIdRedirect(base: 'mapping' | 'map') {
  return async (to: { params: { id?: string | string[] } }) => {
    const id = Array.isArray(to.params.id) ? to.params.id[0] : to.params.id
    if (!id || !NUMERIC_ID.test(id)) return false
    try {
      const detail = await getExpression(id)
      const e = detail.expression
      const path = base === 'mapping'
        ? expressionPath(e.lang_code, e.text, e.homograph_index)
        : mapLensPath(e.lang_code, e.text, e.homograph_index)
      return { path, replace: true }
    } catch {
      return false // id 已因迁移失效；页面组件显示 linkExpired 错误
    }
  }
}
```

routes 数组改为（保持既有顺序，将 mapping/map 四条放在 `/` 之后）：

```typescript
{ path: '/',                      component: () => import('./pages/HomeFeed.vue') },
{ path: '/mapping/:lang/:text(.+)', component: () => import('./pages/MappingDetail.vue') },
{ path: '/mapping/:id',           component: () => import('./pages/MappingDetail.vue'), beforeEnter: legacyIdRedirect('mapping') },
{ path: '/map/:lang/:text(.+)',   component: () => import('./pages/MapLens.vue') },
{ path: '/map/:id',               component: () => import('./pages/MapLens.vue'), beforeEnter: legacyIdRedirect('map') },
```

`web/src/locales/en.ts:112` errors 对象加：

```typescript
expressionLinkExpired: 'This link uses an outdated address. Search for the expression to find its current page.',
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd web && npx vitest run src/router.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add web/src/router.ts web/src/locales/en.ts web/src/router.test.ts
git commit -m "feat(web): serve expression pages at text-key urls with numeric redirects

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 8: web 连结元件改用 expressionPath

**Files:**
- Modify: `web/src/components/expression/ExpressionRow.vue`
- Modify: `web/src/components/feed/NewContribution.vue`
- Modify: `web/src/components/feed/MappingCard.vue`
- Modify: `web/src/components/mapping/MorphologyPanel.vue`
- Test: `web/src/pages/HomeFeed.test.ts`、`web/src/pages/Search.test.ts`、`web/src/components/mapping/MorphologyPanel.test.ts`

**Interfaces:**
- Consumes: `expressionPath`（Task 5）；payload `homograph_index`（Task 3）
- Produces:
  - `ExpressionRow` props 加 `homograph_index?: number`
  - `NewContribution` props 加 `a_homograph_index?: number`（`a_id`/`b_id`/`id` props 保留但不再用于连结）
  - `MappingCard` props 加 `a_homograph_index?: number`
  - `MorphologyPanel` props：`expressionId: string` 改为 `homographIndex?: number`（搭配既有 `langCode`/`text` props）

- [ ] **Step 1: Update the failing tests**

`web/src/pages/HomeFeed.test.ts`：
- mock 行（第 11 行）改为 `const newRow = { id: 'edge-new', type: 'mapping', a_id: '7', a_homograph_index: 1, a_text: '食', a_lang: 'nan', b_id: '9', b_text: 'eat', b_lang: 'eng' }`
- 断言（第 35 行）改为 `expect(wrapper.find('a[href="/mapping/nan/%E9%A3%9F"]').exists()).toBe(true)`

`web/src/pages/Search.test.ts`：
- `expression(id, text)` helper（第 28 行）改为返回 `{ id, text, lang_code: 'eng', homograph_index: 1, mapping_count: 1 }`；fixture id 值 `'eng:first'` 改为 `'1'`（id 现在只是内部值）
- 断言（第 61 行等）`a[href="/mapping/eng:first"]` 改为 `a[href="/mapping/eng/first"]`

`web/src/components/mapping/MorphologyPanel.test.ts`：
- lemma/form fixture 加 `homograph_index: 1`
- href 断言（第 71、116 行）改为 `/mapping/spa/gato`、`/mapping/spa/gatas`

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd web && npx vitest run src/pages/HomeFeed.test.ts src/pages/Search.test.ts src/components/mapping/MorphologyPanel.test.ts`
Expected: FAIL — 现实现仍产出 id 连结

- [ ] **Step 3: Implement**

`ExpressionRow.vue`：import `expressionPath`；props 加 `homograph_index?: number`；模板第 51 行 `:to="\`/mapping/${id}\`"` 改为 `:to="expressionPath(lang_code ?? '', text, homograph_index ?? 1)"`。

`NewContribution.vue`：props 加 `a_homograph_index?: number`；import `expressionPath`；`<router-link :to="\`/mapping/${a_id || id}\`">` 改为 `<router-link :to="expressionPath(a_lang, a_text, a_homograph_index ?? 1)">`（feed 现只回 mapping 行，a 侧字段必在；`id`/`a_id`/`b_id` props 保留以兼容传入端）。

`MappingCard.vue`：props 加 `a_homograph_index?: number`；`<router-link :to="\`/mapping/${a_id}\`">` 改为 `expressionPath(a_lang, a_text, a_homograph_index ?? 1)`。

`MorphologyPanel.vue`：
- props `expressionId: string` 改为 `homographIndex?: number`；
- `getExpressionFormEdges(props.expressionId, ...)` / `createFormEdge(props.expressionId, ...)` 改传 `{ lang_code: props.langCode, text: props.text, homograph_index: props.homographIndex }`；
- 第 272 行 `:to="\`/mapping/${item.lemma.id}\`"` 改为 `:to="expressionPath(item.lemma.lang_code, item.lemma.text, item.lemma.homograph_index ?? 1)"`；第 282 行同理用 `item.form`。

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd web && npx vitest run src/pages/HomeFeed.test.ts src/pages/Search.test.ts src/components/mapping/MorphologyPanel.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add web/src/components/expression/ExpressionRow.vue web/src/components/feed/NewContribution.vue web/src/components/feed/MappingCard.vue web/src/components/mapping/MorphologyPanel.vue web/src/pages/HomeFeed.test.ts web/src/pages/Search.test.ts web/src/components/mapping/MorphologyPanel.test.ts
git commit -m "feat(web): link expressions by text key in rows, cards, and morphology chips

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 9: web MappingDetail 与 MapLens 页面逻辑

**Files:**
- Modify: `web/src/pages/MappingDetail.vue`
- Modify: `web/src/pages/MapLens.vue`
- Test: `web/src/pages/MappingDetail.behavior.test.ts`、`web/src/pages/MappingDetail.language.test.ts`、`web/src/pages/MapLens.test.ts`

**Interfaces:**
- Consumes: `ExpressionKeyInput` / `ExpressionTarget`（Task 6）、`parseExpressionTextSegment` / `expressionPath` / `mapLensPath`（Task 5）、`errors.expressionLinkExpired`（Task 7）
- Produces: 页面以 `route.params.lang`/`route.params.text` 计算 `key`（`{ lang_code, text, homograph_index } | null`）；所有 API 调用传 key；graph 节点导航以节点 `lang_code`/`text`/`homograph_index` 组路径

- [ ] **Step 1: Update the failing tests**

`web/src/pages/MappingDetail.behavior.test.ts`：
- route mock（第 23-26 行）`params: { id: 'old' }` 改为 `params: { lang: 'eng', text: 'old' }`；
- `expression(id, text)` helper 的 `expression` 字段加 `homograph_index: 1`；`graph()` 的 nodes 加 `homograph_index: 1`；
- `detail` mock 断言改为接收 `{ lang_code: 'eng', text: 'old', homograph_index: 1 }`；
- split 相关用例：`splitExpression` mock 回应改为 `{ target_expression_id: '9', target: { lang_code: 'eng', text: 'old', homograph_index: 2 } }`，`push` 断言改为 `'/mapping/eng/old~2'`；
- quickAdd 相关用例：`createExpression` mock 回应 `expression` 字段加 `lang_code: 'eng'`、`text`、`homograph_index`，`push` 断言改为此 key 路径。

`web/src/pages/MappingDetail.language.test.ts`：route mock 同样改 `params: { lang: 'eng', text: ... }`；detail/graph fixture 补 `homograph_index`。

`web/src/pages/MapLens.test.ts`：route mock `params: { id: 'eng:anchor' }` 改为 `params: { lang: 'eng', text: 'anchor' }`；`route.params.id = 'eng:new'` 的行改为 `route.params = { lang: 'eng', text: 'new' }`（注意 reactive 赋值方式保持一致）；detail/graph fixture 补 `homograph_index`。

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd web && npx vitest run src/pages/MappingDetail.behavior.test.ts src/pages/MappingDetail.language.test.ts src/pages/MapLens.test.ts`
Expected: FAIL — 页面仍从 `route.params.id` 取值

- [ ] **Step 3: Implement `web/src/pages/MappingDetail.vue`**

(a) 替换 `id` computed（第 35 行）：

```typescript
const key = computed(() => {
  const lang = route.params.lang as string | undefined
  const text = route.params.text as string | undefined
  if (!lang || !text) return null
  const parsed = parseExpressionTextSegment(text)
  return { lang_code: lang, text: parsed.text, homograph_index: parsed.homograph_index }
})
const anchorId = computed(() => expr.value?.expression.id ?? null)
```

（vue-router 4 的 params 已 decode，勿再 `decodeURIComponent`。）

(b) 所有 `id.value` 用途替换：
- `load()`/graph 载入（第 154、232 行的 `requestedId`）→ `const requestedKey = key.value`，API 调用传 `key.value`（型别 `ExpressionKeyInput`），race 检查用 `requestedKey === key.value`（同物件引用，computed 快取保证）；
- 节点比较（第 186、191、260、295、395 行）→ `anchorId.value`；
- `watch(id, ...)`（第 219 行）→ `watch(key, ...)`，回调开头处理 null：

```typescript
watch(key, () => {
  if (!key.value) {
    expr.value = null; graph.value = null; loadError.value = t('errors.expressionLinkExpired')
    return
  }
  /* 原有重载逻辑 */
})
```

（初次载入走原有的 onMounted/watch immediate 路径，同样在 `load()` 开头加 `if (!key.value) { loadError.value = t('errors.expressionLinkExpired'); return }`。）

(c) `submitQuickAdd`（第 338-345 行）：

```typescript
const newExpression = (result as { expression?: { id?: string; lang_code?: string; text?: string; homograph_index?: number } }).expression
if (newExpression?.lang_code && newExpression.text) {
  router.push(expressionPath(newExpression.lang_code, newExpression.text, newExpression.homograph_index ?? 1))
}
```

(d) `confirmSplit`（第 370 行）：`router.push(expressionPath(result.target.lang_code, result.target.text, result.target.homograph_index))`。

(e) `navigateToNode`（第 294-297 行）：

```typescript
function navigateToNode(nodeId: string) {
  if (nodeId === anchorId.value) return
  const node = graph.value?.nodes.find((candidate) => candidate.expression_id === nodeId)
  if (node) router.push(expressionPath(node.lang_code, node.text, node.homograph_index))
}
```

(f) 模板：第 438 行 `{{ expr.expression.id }}` 改 `{{ expr.expression.text }}`；第 471 行 `/map/${encodeURIComponent(expr.expression.id)}` 改 `mapLensPath(expr.expression.lang_code, expr.expression.text, expr.expression.homograph_index)`。

**`web/src/pages/MapLens.vue`** 同构：
- `id` computed（第 20 行）→ 同上的 `key` computed；
- `load()`（第 130 行起）：`requestedId` → `requestedKey`；`getExpressionDetail(requestedKey, ...)`、`mappingGraph(requestedKey, 2, ...)`；开头 null key → `loadError.value = t('errors.expressionLinkExpired')` 后 return；
- `anchor` 赋值处保留（detail 含 homograph_index）；
- `Pin` interface（第 36 行）加 `homograph_index: number`，`pins` computed 从 graph 节点取 `homograph_index`；
- 第 89 行 `openMapping(exprId)` 改为依 `exprId` 查 `graph.value.nodes` 后组 `expressionPath`（同 navigateToNode 写法）；
- 模板第 215、230 行 `/mapping/${id}` → `expressionPath(anchor.lang_code, anchor.text, anchor.homograph_index)`；第 244 行 `/mapping/${p.expression_id}` → `expressionPath(p.lang_code, p.text, p.homograph_index)`。

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd web && npx vitest run src/pages/MappingDetail.behavior.test.ts src/pages/MappingDetail.language.test.ts src/pages/MapLens.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add web/src/pages/MappingDetail.vue web/src/pages/MapLens.vue web/src/pages/MappingDetail.behavior.test.ts web/src/pages/MappingDetail.language.test.ts web/src/pages/MapLens.test.ts
git commit -m "feat(web): drive mapping and map pages from text-key routes

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 10: web Handbook 流程

**Files:**
- Modify: `web/src/pages/HandbookView.vue`
- Modify: `web/src/components/handbook/HandbookExpressionInspector.vue`
- Test: `web/src/pages/HandbookView.test.ts`

**Interfaces:**
- Consumes: handbook item / graph 节点的 `homograph_index`（Task 3）、`expressionPath`（Task 5）
- Produces: `HandbookExpressionDetail` 加 `homograph_index?: number`（`HandbookExpressionInspector.vue:9` 定义）

- [ ] **Step 1: Update the failing test**

`web/src/pages/HandbookView.test.ts`：找到 inspector「查看 mapping 页」连结断言（若无则新增一个挂载断言），期望值改为 key 路径，例如 handbook item `{ id: '7', text: '食', lang_code: 'nan', homograph_index: 1 }` → `a[href="/mapping/nan/%E9%A3%9F"]`；相关 detail/graph mock fixture 补 `homograph_index: 1`。

- [ ] **Step 2: Run test to verify it fails**

Run: `cd web && npx vitest run src/pages/HandbookView.test.ts`
Expected: FAIL — 连结仍为 `/mapping/7`

- [ ] **Step 3: Implement**

`HandbookExpressionInspector.vue`：`HandbookExpressionDetail` interface 加 `homograph_index?: number`；第 91 行 `:to="\`/mapping/${expression.id}\`"` 改为 `:to="expressionPath(expression.lang_code, expression.text, expression.homograph_index ?? 1)"`（import helper）。

`HandbookView.vue`：
- detail fulfilled 分支的 `selectedExpression.value = {...}`（约第 312 行）加 `homograph_index: detailResult.value.expression.homograph_index`；
- `selectRelatedExpression` 的 optimistic 字面量（约第 336-342 行）加 `homograph_index: node.homograph_index`；
- `selectExpression` 的 item 字面量（约第 265-273 行）加 `homograph_index: item.homograph_index`（Task 3 已让 handbook item 带此栏）。

- [ ] **Step 4: Run test to verify it passes**

Run: `cd web && npx vitest run src/pages/HandbookView.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add web/src/pages/HandbookView.vue web/src/components/handbook/HandbookExpressionInspector.vue web/src/pages/HandbookView.test.ts
git commit -m "feat(web): link handbook expressions by text key

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

### Task 11: 全域验证

**Files:**
- 无新档案；修正任何前述 task 遗留的编译/测试问题

**Interfaces:**
- Consumes: 全部前序 task
- Produces: 全绿的测试与型别检查

- [ ] **Step 1: 全量测试**

Run: `cd backend && npm test`
Expected: PASS（全部 backend 测试）

Run: `cd web && npm test`
Expected: PASS（全部 web 测试；若 TopNav.test 或其他测试 stub 的 router 只注册了 `/mapping/:id` 而断言受影响，为其 stub 补 `/mapping/:lang/:text` 或更新断言至新路径）

- [ ] **Step 2: 型别检查**

Run: `cd web && npx vue-tsc --noEmit`
Expected: 无错误

Run: `cd backend && npm run types:check`
Expected: 无错误

- [ ] **Step 3: i18n 校验**

Run: `cd web && npm run i18n:check`
Expected: PASS（`errors.expressionLinkExpired` 已进 en.ts；如 check 报其他 locale 缺 key，跑 `npm run i18n:sync` 后重跑 check）

- [ ] **Step 4: 手动 smoke（可选但推荐）**

Run: `cd backend && npx wrangler dev`（另开终端 `cd web && npm run dev`）
验证：`/mapping/en/hello`、homograph 尾缀、旧 `/mapping/123` 自动转址、中文与含 `/` 文字的 URL。

- [ ] **Step 5: Commit（若有修正）**

```bash
git add -A
git commit -m "test: stabilize text-key rollout

Co-Authored-By: Claude <noreply@anthropic.com>"
```
