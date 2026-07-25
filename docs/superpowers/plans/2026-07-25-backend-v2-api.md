# backend_v2 API 實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 v2 Hono API endpoints,讓前端原型可以串接真實資料。本地 wrangler dev 可跑。

**Architecture:** Hono app（仿 v1 結構）+ Cloudflare Workers D1。路由按資源拆分：expressions、mappings、handbooks、languages、feed、search。Auth 復用 v1 的 JWT 模式。回應格式用 v1 的 response helpers。DB queries 用 D1 直接查詢（不用 service layer,保持簡單）。

**Tech Stack:** Hono 4, TypeScript, Cloudflare Workers, D1, jose (JWT)。

**前置:** Plan A 已完成——`backend_v2/schema.sql` 已建,v2 D1 已有遷移資料（91K expressions, 112K edges, 4 handbooks）。

---

## File Structure

```
backend_v2/
├── src/
│   ├── index.tsx              # Hono app entry, mount routes
│   ├── types.ts               # Bindings type, Variables type
│   ├── middleware/
│   │   └── auth.ts            # requireAuth, optionalAuth
│   ├── utils/
│   │   └── response.ts        # success, created, badRequest, notFound, paginated, etc.
│   └── routes/
│       ├── index.ts           # mount all routers under /api/v2
│       ├── expressions.ts     # GET /:id, GET /:id/mappings, GET /search
│       ├── mappings.ts        # POST /:id/vote
│       ├── contributions.ts   # POST /batch
│       ├── handbooks.ts       # CRUD + sections
│       ├── languages.ts       # list, detail, expressions
│       ├── feed.ts            # hot, new
│       └── search.ts          # global search
├── schema.sql                 # already exists
├── wrangler.jsonc             # already exists
└── package.json               # already exists
```

---

## Task 1: App scaffolding + auth + response utils

**Files:**
- Create: `backend_v2/src/index.tsx`
- Create: `backend_v2/src/types.ts`
- Create: `backend_v2/src/middleware/auth.ts`
- Create: `backend_v2/src/utils/response.ts`
- Create: `backend_v2/src/routes/index.ts`
- Create: `backend_v2/src/routes/_stub.ts` (temporary stub route for smoke test)
- Modify: `backend_v2/package.json` (add dependencies)

- [ ] **Step 1: Install dependencies**

```bash
cd backend_v2
npm install hono jose zod
npm install -D wrangler @cloudflare/workers-types
```

- [ ] **Step 2: Create `src/types.ts`**

```ts
export interface Bindings {
  DB: D1Database;
  ASSETS: { fetch: typeof fetch };
  SECRET_KEY: string;
}

export interface Variables {
  user?: { id: number; username: string; role: string };
}
```

- [ ] **Step 3: Create `src/utils/response.ts`**

```ts
import { Context } from 'hono';

export function success(c: Context, data: unknown, message?: string, status = 200) {
  return c.json({ success: true, data, message }, status);
}

export function created(c: Context, data: unknown, message?: string) {
  return success(c, data, message, 201);
}

export function badRequest(c: Context, error: string, message?: string) {
  return c.json({ success: false, error, message }, 400);
}

export function notFound(c: Context, resource: string) {
  return c.json({ success: false, error: 'not_found', message: `${resource} not found` }, 404);
}

export function unauthorized(c: Context) {
  return c.json({ success: false, error: 'unauthorized', message: 'Authentication required' }, 401);
}

export function forbidden(c: Context) {
  return c.json({ success: false, error: 'forbidden', message: 'Insufficient permissions' }, 403);
}

export function paginated(c: Context, items: unknown[], total: number, skip: number, limit: number) {
  return success(c, { items, total, skip, limit, hasMore: skip + limit < total });
}
```

- [ ] **Step 4: Create `src/middleware/auth.ts`**

```ts
import { Context, Next } from 'hono';
import { jwtVerify } from 'jose';
import { unauthorized } from '../utils/response';

export async function requireAuth(c: Context, next: Next) {
  const auth = c.req.header('Authorization');
  if (!auth?.startsWith('Bearer ')) return unauthorized(c);
  try {
    const { payload } = await jwtVerify(auth.slice(7), new TextEncoder().encode(c.env.SECRET_KEY));
    c.set('user', { id: payload.id as number, username: payload.username as string, role: payload.role as string });
    await next();
  } catch {
    return unauthorized(c);
  }
}

export async function optionalAuth(c: Context, next: Next) {
  const auth = c.req.header('Authorization');
  if (auth?.startsWith('Bearer ')) {
    try {
      const { payload } = await jwtVerify(auth.slice(7), new TextEncoder().encode(c.env.SECRET_KEY));
      c.set('user', { id: payload.id as number, username: payload.username as string, role: payload.role as string });
    } catch { /* ignore */ }
  }
  await next();
}
```

- [ ] **Step 5: Create stub route `src/routes/_stub.ts`**

```ts
import { Hono } from 'hono';
import { success } from '../utils/response';

const stub = new Hono();

stub.get('/health', (c) => success(c, { status: 'ok', version: 'v2' }));

export default stub;
```

- [ ] **Step 6: Create `src/routes/index.ts`**

```ts
import { Hono } from 'hono';
import stub from './_stub';

const api = new Hono();
api.route('/', stub);
export default api;
```

- [ ] **Step 7: Create `src/index.tsx`**

```ts
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import api from './routes';
import type { Bindings, Variables } from './types';

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

app.use('*', cors());
app.route('/api/v2', api);

export default app;
```

- [ ] **Step 8: Smoke test**

```bash
cd backend_v2
npx wrangler dev --port 8789
# In another terminal:
curl http://localhost:8789/api/v2/health
# Expected: {"success":true,"data":{"status":"ok","version":"v2"}}
```

- [ ] **Step 9: Commit**

```bash
git add backend_v2/src/
git commit -m "feat(v2-api): scaffolding with auth, response utils, health endpoint"
```

---

## Task 2: Languages API

**Files:**
- Create: `backend_v2/src/routes/languages.ts`
- Modify: `backend_v2/src/routes/index.ts` (mount)

- [ ] **Step 1: Write test — list languages**

用 curl 手動驗證（v2 目前無 test framework 設定）:

```bash
# 載入 languages 到 v2 D1（已在 Plan A 完成）
curl "http://localhost:8789/api/v2/languages"
# Expected: list of 32 languages
```

- [ ] **Step 2: Create `src/routes/languages.ts`**

```ts
import { Hono } from 'hono';
import { success, notFound, paginated } from '../utils/response';
import type { Bindings } from '../types';

const languages = new Hono<{ Bindings: Bindings }>();

// GET /api/v2/languages — list all languages with expression counts
languages.get('/', async (c) => {
  const search = c.req.query('search') || '';
  const sort = c.req.query('sort') || 'count'; // count | alpha

  let query = `SELECT l.*, COALESCE(s.expression_count, 0) as expression_count
    FROM languages l LEFT JOIN language_stats s ON l.code = s.language_code`;
  const params: string[] = [];

  if (search) {
    query += ` WHERE l.name LIKE ? OR l.code LIKE ?`;
    params.push(`%${search}%`, `%${search}%`);
  }

  query += sort === 'alpha' ? ` ORDER BY l.name` : ` ORDER BY expression_count DESC, l.name`;

  const { results } = await c.env.DB.prepare(query).bind(...params).all();
  return success(c, results);
});

// GET /api/v2/languages/:code — language detail
languages.get('/:code', async (c) => {
  const code = c.req.param('code');
  const lang = await c.env.DB.prepare(
    `SELECT l.*, COALESCE(s.expression_count, 0) as expression_count
     FROM languages l LEFT JOIN language_stats s ON l.code = s.language_code
     WHERE l.code = ?`
  ).bind(code).first();
  if (!lang) return notFound(c, 'Language');

  const mappedCount = await c.env.DB.prepare(
    `SELECT COUNT(DISTINCT e.id) as count FROM expressions e
     INNER JOIN expression_edges ed ON e.id = ed.expression_a_id OR e.id = ed.expression_b_id
     WHERE e.language_code = ?`
  ).bind(code).first<{ count: number }>();

  return success(c, { ...lang, mapped_expression_count: mappedCount?.count || 0 });
});

// GET /api/v2/languages/:code/expressions — expressions in a language
languages.get('/:code/expressions', async (c) => {
  const code = c.req.param('code');
  const sort = c.req.query('sort') || 'new';
  const limit = Math.min(parseInt(c.req.query('limit') || '50'), 100);
  const offset = parseInt(c.req.query('offset') || '0');

  let orderBy = 'e.created_at DESC';
  if (sort === 'alpha') orderBy = 'e.text';
  if (sort === 'hot') orderBy = 'mapping_count DESC, e.text';

  const { results } = await c.env.DB.prepare(
    `SELECT e.*,
      (SELECT COUNT(*) FROM expression_edges ed
       WHERE e.id = ed.expression_a_id OR e.id = ed.expression_b_id) as mapping_count
     FROM expressions e
     WHERE e.language_code = ?
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`
  ).bind(code, limit, offset).all();

  const { count: total } = await c.env.DB.prepare(
    `SELECT COUNT(*) as count FROM expressions WHERE language_code = ?`
  ).bind(code).first<{ count: number }>();

  return paginated(c, results, total, offset, limit);
});

export default languages;
```

- [ ] **Step 3: Mount in `src/routes/index.ts`**

```ts
import { Hono } from 'hono';
import stub from './_stub';
import languages from './languages';

const api = new Hono();
api.route('/', stub);
api.route('/languages', languages);
export default api;
```

- [ ] **Step 4: Verify with curl**

```bash
curl "http://localhost:8789/api/v2/languages" | head -c 200
curl "http://localhost:8789/api/v2/languages/cmn"
curl "http://localhost:8789/api/v2/languages/cmn/expressions?limit=3"
```

- [ ] **Step 5: Commit**

```bash
git add backend_v2/src/routes/languages.ts backend_v2/src/routes/index.ts
git commit -m "feat(v2-api): languages endpoints (list, detail, expressions)"
```

---

## Task 3: Expressions API

**Files:**
- Create: `backend_v2/src/routes/expressions.ts`
- Modify: `backend_v2/src/routes/index.ts` (mount)

- [ ] **Step 1: Create `src/routes/expressions.ts`**

```ts
import { Hono } from 'hono';
import { success, notFound, paginated } from '../utils/response';
import type { Bindings } from '../types';

const expressions = new Hono<{ Bindings: Bindings }>();

// GET /api/v2/expressions/search — search for expression picker
expressions.get('/search', async (c) => {
  const q = c.req.query('q') || '';
  const lang = c.req.query('lang') || '';
  const limit = Math.min(parseInt(c.req.query('limit') || '10'), 50);

  let query = `SELECT id, text, language_code FROM expressions WHERE 1=1`;
  const params: (string | number)[] = [];

  if (q) {
    query += ` AND text LIKE ?`;
    params.push(`%${q}%`);
  }
  if (lang) {
    query += ` AND language_code = ?`;
    params.push(lang);
  }
  query += ` ORDER BY text LIMIT ?`;
  params.push(limit);

  const { results } = await c.env.DB.prepare(query).bind(...params).all();
  return success(c, results);
});

// GET /api/v2/expressions/:id — expression detail
expressions.get('/:id', async (c) => {
  const id = parseInt(c.req.param('id'));
  const expr = await c.env.DB.prepare(
    `SELECT e.*, l.name as language_name
     FROM expressions e LEFT JOIN languages l ON e.language_code = l.code
     WHERE e.id = ?`
  ).bind(id).first();
  if (!expr) return notFound(c, 'Expression');
  return success(c, expr);
});

// GET /api/v2/expressions/:id/mappings — all mappings (1-3 hops)
expressions.get('/:id/mappings', async (c) => {
  const id = parseInt(c.req.param('id'));
  const hops = Math.min(parseInt(c.req.query('hops') || '1'), 3);

  // Direct mappings (1 hop)
  const { results: direct } = await c.env.DB.prepare(
    `SELECT ed.id as edge_id, ed.score,
      CASE WHEN ed.expression_a_id = ? THEN ed.expression_b_id ELSE ed.expression_a_id END as expression_id,
      e.text, e.language_code, l.name as language_name
     FROM expression_edges ed
     INNER JOIN expressions e ON e.id = CASE WHEN ed.expression_a_id = ? THEN ed.expression_b_id ELSE ed.expression_a_id END
     LEFT JOIN languages l ON e.language_code = l.code
     WHERE ed.expression_a_id = ? OR ed.expression_b_id = ?
     ORDER BY ed.score DESC`
  ).bind(id, id, id, id).all();

  let allMappings = direct.map((d: any) => ({ ...d, hops: 1 }));

  if (hops >= 2) {
    // 2nd hop: neighbors of neighbors (excluding self and direct)
    const directIds = new Set([id, ...direct.map((d: any) => d.expression_id)]);
    const { results: second } = await c.env.DB.prepare(
      `SELECT DISTINCT
        CASE WHEN ed.expression_a_id IN (SELECT value FROM json_each(?))
          THEN ed.expression_b_id ELSE ed.expression_a_id END as expression_id,
        e.text, e.language_code, l.name as language_name, ed.score
       FROM expression_edges ed
       INNER JOIN expressions e ON e.id = CASE WHEN ed.expression_a_id IN (SELECT value FROM json_each(?))
         THEN ed.expression_b_id ELSE ed.expression_a_id END
       LEFT JOIN languages l ON e.language_code = l.code
       WHERE (ed.expression_a_id IN (SELECT value FROM json_each(?))
           OR ed.expression_b_id IN (SELECT value FROM json_each(?)))
       ORDER BY ed.score DESC LIMIT 100`
    ).bind(
      JSON.stringify([...directIds]),
      JSON.stringify([...directIds]),
      JSON.stringify([...directIds]),
      JSON.stringify([...directIds])
    ).all();

    allMappings.push(...second
      .filter((s: any) => !directIds.has(s.expression_id))
      .map((s: any) => ({ ...s, hops: 2, edge_id: null }))
    );
  }

  return success(c, allMappings);
});

export default expressions;
```

- [ ] **Step 2: Mount in `src/routes/index.ts`**

```ts
import expressions from './expressions';
// add: api.route('/expressions', expressions);
```

- [ ] **Step 3: Verify with curl**

```bash
curl "http://localhost:8789/api/v2/expressions/15529"
curl "http://localhost:8789/api/v2/expressions/15529/mappings"
curl "http://localhost:8789/api/v2/expressions/15529/mappings?hops=2"
curl "http://localhost:8789/api/v2/expressions/search?q=hello&lang=en"
```

- [ ] **Step 4: Commit**

```bash
git add backend_v2/src/routes/expressions.ts backend_v2/src/routes/index.ts
git commit -m "feat(v2-api): expressions endpoints (detail, mappings, search)"
```

---

## Task 4: Mappings vote + Contributions batch

**Files:**
- Create: `backend_v2/src/routes/mappings.ts`
- Create: `backend_v2/src/routes/contributions.ts`
- Modify: `backend_v2/src/routes/index.ts`

- [ ] **Step 1: Create `src/routes/mappings.ts`**

```ts
import { Hono } from 'hono';
import { success, badRequest, notFound } from '../utils/response';
import { requireAuth } from '../middleware/auth';
import type { Bindings, Variables } from '../types';

const mappings = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// POST /api/v2/mappings/:id/vote — upvote or downvote a mapping
mappings.post('/:id/vote', requireAuth, async (c) => {
  const edgeId = c.req.param('id');
  const user = c.get('user')!;
  const { direction } = await c.req.json<{ direction: 'up' | 'down' }>();
  if (direction !== 'up' && direction !== 'down') return badRequest(c, 'invalid_direction');

  const vote = direction === 'up' ? 1 : -1;

  // Upsert vote
  const existing = await c.env.DB.prepare(
    `SELECT id, vote FROM votes WHERE user_id = ? AND target_type = 'mapping' AND target_id = ?`
  ).bind(user.id, edgeId).first<{ id: number; vote: number }>();

  let voteDelta = vote;
  if (existing) {
    if (existing.vote === vote) {
      // Toggle off
      await c.env.DB.prepare(`DELETE FROM votes WHERE id = ?`).bind(existing.id).run();
      voteDelta = -vote;
    } else {
      // Change vote
      await c.env.DB.prepare(`UPDATE votes SET vote = ? WHERE id = ?`).bind(vote, existing.id).run();
      voteDelta = vote * 2;
    }
  } else {
    const voteId = `${user.id}-mapping-${edgeId}`;
    await c.env.DB.prepare(
      `INSERT INTO votes (id, user_id, target_type, target_id, vote) VALUES (?, ?, 'mapping', ?, ?)`
    ).bind(voteId, user.id, edgeId, vote).run();
  }

  // Update edge score
  await c.env.DB.prepare(
    `UPDATE expression_edges SET score = score + ? WHERE id = ?`
  ).bind(voteDelta, edgeId).run();

  const edge = await c.env.DB.prepare(
    `SELECT score FROM expression_edges WHERE id = ?`
  ).bind(edgeId).first<{ score: number }>();

  return success(c, { score: edge?.score || 0 });
});

export default mappings;
```

- [ ] **Step 2: Create `src/routes/contributions.ts`**

```ts
import { Hono } from 'hono';
import { success, badRequest } from '../utils/response';
import { requireAuth } from '../middleware/auth';
import { edgesForGroup } from '../../scripts/v2/lib/edges';
import type { Bindings, Variables } from '../types';

const contributions = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// FNV-1a hash (same as v1 for idempotent expression creation)
function fnv1a(str: string): number {
  let hash = 0x811c9dc5;
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i);
    hash = (hash * 0x01000193) >>> 0;
  }
  return hash;
}

// POST /api/v2/contributions/batch — submit N expressions → N(N-1)/2 edges
contributions.post('/batch', requireAuth, async (c) => {
  const user = c.get('user')!;
  const { expressions: exprs } = await c.req.json<{
    expressions: { lang: string; text: string; region?: string }[];
  }>();

  if (!exprs || exprs.length < 2) return badRequest(c, 'need_at_least_2_expressions');
  if (exprs.length > 50) return badRequest(c, 'too_many_expressions');

  const exprIds: number[] = [];
  const statements: D1Statement[] = [];

  // Upsert each expression
  for (const e of exprs) {
    const id = fnv1a(`${e.text}|${e.lang}`);
    exprIds.push(id);
    statements.push(
      c.env.DB.prepare(
        `INSERT OR IGNORE INTO expressions (id, text, language_code, region_name, source_type, created_by, review_status)
         VALUES (?, ?, ?, ?, 'user', ?, 'pending')`
      ).bind(id, e.text, e.lang, e.region || null, user.username)
    );
  }

  // Generate clique edges
  const edges = edgesForGroup(exprIds);
  for (const edge of edges) {
    statements.push(
      c.env.DB.prepare(
        `INSERT OR IGNORE INTO expression_edges (id, expression_a_id, expression_b_id, score, source, created_by)
         VALUES (?, ?, ?, 0, 'batch', ?)`
      ).bind(edge.id, edge.a, edge.b, user.username)
    );
  }

  await c.env.DB.batch(statements);

  return success(c, {
    expressionCount: exprIds.length,
    mappingCount: edges.length,
    expressionIds: exprIds,
  });
});

export default contributions;
```

- [ ] **Step 3: Mount routes**

```ts
import mappings from './mappings';
import contributions from './contributions';
// add: api.route('/mappings', mappings);
// add: api.route('/contributions', contributions);
```

- [ ] **Step 4: Verify with curl**

```bash
# Vote (needs auth token — use dev token or skip if not logged in)
curl -X POST http://localhost:8789/api/v2/mappings/15529-178901311/vote \
  -H "Content-Type: application/json" \
  -d '{"direction":"up"}'

# Batch contribution
curl -X POST http://localhost:8789/api/v2/contributions/batch \
  -H "Content-Type: application/json" \
  -d '{"expressions":[{"lang":"en","text":"Hello"},{"lang":"cmn","text":"你好"},{"lang":"ja","text":"こんにちは"}]}'
```

- [ ] **Step 5: Commit**

```bash
git add backend_v2/src/routes/mappings.ts backend_v2/src/routes/contributions.ts backend_v2/src/routes/index.ts
git commit -m "feat(v2-api): mapping vote + batch contribution endpoints"
```

---

## Task 5: Handbooks API

**Files:**
- Create: `backend_v2/src/routes/handbooks.ts`
- Modify: `backend_v2/src/routes/index.ts`

- [ ] **Step 1: Create `src/routes/handbooks.ts`**

```ts
import { Hono } from 'hono';
import { success, created, notFound, badRequest, paginated } from '../utils/response';
import { requireAuth, optionalAuth } from '../middleware/auth';
import type { Bindings, Variables } from '../types';

const handbooks = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// GET /api/v2/handbooks — list handbooks
handbooks.get('/', async (c) => {
  const sort = c.req.query('sort') || 'new'; // hot | new
  const search = c.req.query('search') || '';
  const limit = Math.min(parseInt(c.req.query('limit') || '20'), 100);
  const offset = parseInt(c.req.query('offset') || '0');

  let where = 'WHERE h.visibility = \'public\'';
  const params: (string | number)[] = [];

  if (search) {
    where += ` AND h.title LIKE ?`;
    params.push(`%${search}%`);
  }

  const orderBy = sort === 'hot' ? 'h.score DESC, h.updated_at DESC' : 'h.updated_at DESC';

  const { results } = await c.env.DB.prepare(
    `SELECT h.*, u.username as author,
      (SELECT COUNT(*) FROM handbook_sections WHERE handbook_id = h.id) as section_count,
      (SELECT COUNT(*) FROM handbook_section_items i
       INNER JOIN handbook_sections s ON i.section_id = s.id
       WHERE s.handbook_id = h.id) as expression_count
     FROM handbooks h
     LEFT JOIN users u ON h.user_id = u.id
     ${where}
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`
  ).bind(...params, limit, offset).all();

  const { count: total } = await c.env.DB.prepare(
    `SELECT COUNT(*) as count FROM handbooks h ${where}`
  ).bind(...params).first<{ count: number }>();

  return paginated(c, results, total, offset, limit);
});

// GET /api/v2/handbooks/:id — handbook detail with sections
handbooks.get('/:id', async (c) => {
  const id = parseInt(c.req.param('id'));
  const hb = await c.env.DB.prepare(
    `SELECT h.*, u.username as author
     FROM handbooks h LEFT JOIN users u ON h.user_id = u.id
     WHERE h.id = ?`
  ).bind(id).first();
  if (!hb) return notFound(c, 'Handbook');

  const { results: sections } = await c.env.DB.prepare(
    `SELECT * FROM handbook_sections WHERE handbook_id = ? ORDER BY position`
  ).bind(id).all();

  for (const sec of sections as any[]) {
    const { results: items } = await c.env.DB.prepare(
      `SELECT i.position, e.id as expression_id, e.text, e.language_code, e.region_name
       FROM handbook_section_items i
       INNER JOIN expressions e ON i.expression_id = e.id
       WHERE i.section_id = ?
       ORDER BY i.position`
    ).bind(sec.id).all();
    sec.expressions = items;
  }

  return success(c, { ...hb, sections });
});

// POST /api/v2/handbooks — create handbook
handbooks.post('/', requireAuth, async (c) => {
  const user = c.get('user')!;
  const { title, visibility, sections } = await c.req.json<{
    title: string;
    visibility?: string;
    sections: { title: string; expressionIds: number[] }[];
  }>();

  if (!title) return badRequest(c, 'title_required');

  const statements: D1Statement[] = [];

  statements.push(
    c.env.DB.prepare(
      `INSERT INTO handbooks (user_id, title, visibility) VALUES (?, ?, ?)`
    ).bind(user.id, title, visibility || 'public')
  );

  const result = await c.env.DB.batch(statements);
  // Get inserted ID from first statement
  const hbResult = result[0] as any;
  const hbId = hbResult?.meta?.last_row_id;

  // Insert sections
  const secStatements: D1Statement[] = [];
  let position = 0;
  for (const sec of sections || []) {
    secStatements.push(
      c.env.DB.prepare(
        `INSERT INTO handbook_sections (handbook_id, title, position) VALUES (?, ?, ?)`
      ).bind(hbId, sec.title, position++)
    );
  }
  if (secStatements.length > 0) {
    const secResults = await c.env.DB.batch(secStatements);
    // Insert items per section
    for (let i = 0; i < sections.length; i++) {
      const secId = (secResults[i] as any)?.meta?.last_row_id;
      if (!secId || !sections[i].expressionIds.length) continue;
      const itemStmts = sections[i].expressionIds.map((eid, ii) =>
        c.env.DB.prepare(
          `INSERT INTO handbook_section_items (section_id, expression_id, position) VALUES (?, ?, ?)`
        ).bind(secId, eid, ii)
      );
      await c.env.DB.batch(itemStmts);
    }
  }

  return created(c, { id: hbId });
});

// PUT /api/v2/handbooks/:id — update handbook
handbooks.put('/:id', requireAuth, async (c) => {
  const id = parseInt(c.req.param('id'));
  const user = c.get('user')!;
  const hb = await c.env.DB.prepare(`SELECT * FROM handbooks WHERE id = ?`).bind(id).first();
  if (!hb) return notFound(c, 'Handbook');
  if ((hb as any).user_id !== user.id && user.role !== 'admin') return badRequest(c, 'forbidden');

  const { title, visibility, sections } = await c.req.json<{
    title?: string;
    visibility?: string;
    sections?: { id?: number; title: string; expressionIds: number[] }[];
  }>();

  // Update handbook metadata
  if (title || visibility) {
    const sets: string[] = [];
    const vals: any[] = [];
    if (title) { sets.push('title = ?'); vals.push(title); }
    if (visibility) { sets.push('visibility = ?'); vals.push(visibility); }
    vals.push(id);
    await c.env.DB.prepare(`UPDATE handbooks SET ${sets.join(', ')} WHERE id = ?`).bind(...vals).run();
  }

  // Replace sections if provided
  if (sections) {
    await c.env.DB.prepare(`DELETE FROM handbook_sections WHERE handbook_id = ?`).bind(id).run();
    let position = 0;
    for (const sec of sections) {
      const result = await c.env.DB.prepare(
        `INSERT INTO handbook_sections (handbook_id, title, position) VALUES (?, ?, ?)`
      ).bind(id, sec.title, position++).first<{ id: number }>();
      if (result && sec.expressionIds.length) {
        const itemStmts = sec.expressionIds.map((eid, ii) =>
          c.env.DB.prepare(
            `INSERT INTO handbook_section_items (section_id, expression_id, position) VALUES (?, ?, ?)`
          ).bind(result.id, eid, ii)
        );
        await c.env.DB.batch(itemStmts);
      }
    }
  }

  return success(c, { id });
});

// DELETE /api/v2/handbooks/:id
handbooks.delete('/:id', requireAuth, async (c) => {
  const id = parseInt(c.req.param('id'));
  const user = c.get('user')!;
  const hb = await c.env.DB.prepare(`SELECT * FROM handbooks WHERE id = ?`).bind(id).first();
  if (!hb) return notFound(c, 'Handbook');
  if ((hb as any).user_id !== user.id && user.role !== 'admin') return badRequest(c, 'forbidden');

  // CASCADE will handle sections and items
  await c.env.DB.prepare(`DELETE FROM handbooks WHERE id = ?`).bind(id).run();
  return success(c, { deleted: true });
});

// POST /api/v2/handbooks/:id/vote
handbooks.post('/:id/vote', requireAuth, async (c) => {
  const handbookId = c.req.param('id');
  const user = c.get('user')!;
  const { direction } = await c.req.json<{ direction: 'up' | 'down' }>();
  if (direction !== 'up' && direction !== 'down') return badRequest(c, 'invalid_direction');

  const vote = direction === 'up' ? 1 : -1;
  const existing = await c.env.DB.prepare(
    `SELECT id, vote FROM votes WHERE user_id = ? AND target_type = 'handbook' AND target_id = ?`
  ).bind(user.id, handbookId).first<{ id: number; vote: number }>();

  let voteDelta = vote;
  if (existing) {
    if (existing.vote === vote) {
      await c.env.DB.prepare(`DELETE FROM votes WHERE id = ?`).bind(existing.id).run();
      voteDelta = -vote;
    } else {
      await c.env.DB.prepare(`UPDATE votes SET vote = ? WHERE id = ?`).bind(vote, existing.id).run();
      voteDelta = vote * 2;
    }
  } else {
    const voteId = `${user.id}-handbook-${handbookId}`;
    await c.env.DB.prepare(
      `INSERT INTO votes (id, user_id, target_type, target_id, vote) VALUES (?, ?, 'handbook', ?, ?)`
    ).bind(voteId, user.id, handbookId, vote).run();
  }

  await c.env.DB.prepare(`UPDATE handbooks SET score = score + ? WHERE id = ?`).bind(voteDelta, handbookId).run();
  const hb = await c.env.DB.prepare(`SELECT score FROM handbooks WHERE id = ?`).bind(handbookId).first<{ score: number }>();
  return success(c, { score: hb?.score || 0 });
});

export default handbooks;
```

- [ ] **Step 2: Mount**

```ts
import handbooks from './handbooks';
// add: api.route('/handbooks', handbooks);
```

- [ ] **Step 3: Verify**

```bash
curl "http://localhost:8789/api/v2/handbooks"
curl "http://localhost:8789/api/v2/handbooks/1539253276"
```

- [ ] **Step 4: Commit**

```bash
git add backend_v2/src/routes/handbooks.ts backend_v2/src/routes/index.ts
git commit -m "feat(v2-api): handbooks CRUD + vote endpoints"
```

---

## Task 6: Feed + Search API

**Files:**
- Create: `backend_v2/src/routes/feed.ts`
- Create: `backend_v2/src/routes/search.ts`
- Modify: `backend_v2/src/routes/index.ts`

- [ ] **Step 1: Create `src/routes/feed.ts`**

```ts
import { Hono } from 'hono';
import { success } from '../utils/response';
import type { Bindings } from '../types';

const feed = new Hono<{ Bindings: Bindings }>();

// GET /api/v2/feed/hot — top mappings by score
feed.get('/hot', async (c) => {
  const limit = Math.min(parseInt(c.req.query('limit') || '20'), 50);

  const { results } = await c.env.DB.prepare(
    `SELECT ed.id, ed.score, ed.source,
      a.id as a_id, a.text as a_text, a.language_code as a_lang,
      b.id as b_id, b.text as b_text, b.language_code as b_lang
     FROM expression_edges ed
     INNER JOIN expressions a ON ed.expression_a_id = a.id
     INNER JOIN expressions b ON ed.expression_b_id = b.id
     WHERE ed.score > 0
     ORDER BY ed.score DESC
     LIMIT ?`
  ).bind(limit).all();

  return success(c, results);
});

// GET /api/v2/feed/new — latest contributions
feed.get('/new', async (c) => {
  const limit = Math.min(parseInt(c.req.query('limit') || '20'), 50);

  const { results } = await c.env.DB.prepare(
    `SELECT 'mapping' as type, ed.id, ed.created_at as created_at, ed.created_by as author,
      a.text as left_text, a.language_code as left_lang,
      b.text as right_text, b.language_code as right_lang
     FROM expression_edges ed
     INNER JOIN expressions a ON ed.expression_a_id = a.id
     INNER JOIN expressions b ON ed.expression_b_id = b.id
     ORDER BY ed.created_at DESC
     LIMIT ?`
  ).bind(limit).all();

  return success(c, results);
});

export default feed;
```

- [ ] **Step 2: Create `src/routes/search.ts`**

```ts
import { Hono } from 'hono';
import { success, paginated } from '../utils/response';
import type { Bindings } from '../types';

const search = new Hono<{ Bindings: Bindings }>();

// GET /api/v2/search/expressions — global search
search.get('/expressions', async (c) => {
  const q = c.req.query('q') || '';
  const lang = c.req.query('lang') || '';
  const sort = c.req.query('sort') || 'new';
  const limit = Math.min(parseInt(c.req.query('limit') || '50'), 100);
  const offset = parseInt(c.req.query('offset') || '0');

  if (!q) return paginated(c, [], 0, 0, limit);

  let orderBy = 'e.created_at DESC';
  if (sort === 'alpha') orderBy = 'e.text';
  if (sort === 'hot') orderBy = 'mapping_count DESC, e.text';

  const langFilter = lang ? `AND e.language_code IN (${lang.split(',').map(l => `'${l}'`).join(',')})` : '';

  const { results } = await c.env.DB.prepare(
    `SELECT e.*,
      (SELECT COUNT(*) FROM expression_edges ed
       WHERE e.id = ed.expression_a_id OR e.id = ed.expression_b_id) as mapping_count
     FROM expressions e
     WHERE e.text LIKE ? ${langFilter}
     ORDER BY ${orderBy}
     LIMIT ? OFFSET ?`
  ).bind(`%${q}%`, limit, offset).all();

  const { count: total } = await c.env.DB.prepare(
    `SELECT COUNT(*) as count FROM expressions e WHERE e.text LIKE ? ${langFilter}`
  ).bind(`%${q}%`).first<{ count: number }>();

  return paginated(c, results, total, offset, limit);
});

export default search;
```

- [ ] **Step 3: Mount**

```ts
import feed from './feed';
import search from './search';
// add: api.route('/feed', feed);
// add: api.route('/search', search);
```

- [ ] **Step 4: Verify**

```bash
curl "http://localhost:8789/api/v2/feed/hot?limit=3"
curl "http://localhost:8789/api/v2/feed/new?limit=3"
curl "http://localhost:8789/api/v2/search/expressions?q=hello&sort=hot"
```

- [ ] **Step 5: Commit**

```bash
git add backend_v2/src/routes/feed.ts backend_v2/src/routes/search.ts backend_v2/src/routes/index.ts
git commit -m "feat(v2-api): feed (hot/new) + global search endpoints"
```

---

## Task 7: Smoke test all endpoints + clean up

- [ ] **Step 1: Full endpoint smoke test**

```bash
# Health
curl http://localhost:8789/api/v2/health

# Languages
curl http://localhost:8789/api/v2/languages | python3 -c "import sys,json;d=json.load(sys.stdin);print(f'{len(d[\"data\"])} languages')"
curl http://localhost:8789/api/v2/languages/cmn

# Expressions
curl "http://localhost:8789/api/v2/expressions/15529" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['data']['text'])"
curl "http://localhost:8789/api/v2/expressions/15529/mappings" | python3 -c "import sys,json;d=json.load(sys.stdin);print(f'{len(d[\"data\"])} mappings')"
curl "http://localhost:8789/api/v2/expressions/search?q=test"

# Feed
curl "http://localhost:8789/api/v2/feed/hot?limit=3"
curl "http://localhost:8789/api/v2/feed/new?limit=3"

# Handbooks
curl "http://localhost:8789/api/v2/handbooks"
curl "http://localhost:8789/api/v2/handbooks/1539253276" | python3 -c "import sys,json;d=json.load(sys.stdin);print(f'{len(d[\"data\"][\"sections\"])} sections')"

# Search
curl "http://localhost:8789/api/v2/search/expressions?q=好&sort=hot&limit=5"
```

- [ ] **Step 2: Remove stub route**

Delete `backend_v2/src/routes/_stub.ts` and remove its import from `routes/index.ts`.

- [ ] **Step 3: Final commit**

```bash
git add -A backend_v2/src/
git commit -m "feat(v2-api): complete API — all 13 endpoints operational"
```

---

## 備註

- **Auth**: vote 和 contribution endpoints 需要 JWT token。開發時可先用 v1 的 register/login 取得 token,或手動在 `requireAuth` 中 bypass。
- **CORS**: 已在 entry 設定 `*`,前端原型可直接串。
- **錯誤處理**: v1 有全局 error handler,v2 暫時用 Hono 預設。若需要可後加。
- ** caching**: v2 暫不做 cache,保持簡單。效能問題之後再加。
- **FTS5**: search endpoints 目前用 LIKE,未用 FTS5（v2 schema 有 FTS 但 D1 的 FTS 限制可能影響）。效能問題之後再優化。
