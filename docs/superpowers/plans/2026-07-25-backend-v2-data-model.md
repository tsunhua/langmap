# backend_v2 資料模型 + 遷移 實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 v2 資料模型(廢 meanings/組、改 pairwise edges;加讚/踩/評分;簡化手冊),把舊資料遷移到**本地** v2 D1 並驗證;遠端重建之後再做。

**Architecture:** 新 schema 丟棄 `meanings`/`expression_meaning`/`collections`/`collection_items`/舊 `handbooks`/`handbook_pages`;新增 `expression_edges`(直接映射)、`votes`(讚/踩,映射+手冊共用)、簡化 `handbooks`/`handbook_sections`/`handbook_section_items`。遷移以 TS 腳本(`better-sqlite3`)讀舊本地 D1 sqlite,用純函式把「組→完全圖」「Markdown→章節+有序詞句」轉換,emit v2 SQL,載入本地 v2 D1。純函式有 vitest 單元測試;整合用真實 dump 驗證計數。

**Tech Stack:** TypeScript, better-sqlite3, vitest, wrangler (Cloudflare D1)。

**相關文件:** `CONTEXT.md`(詞彙表)、`docs/adr/0001-mappings-form-cliques-from-batch-contributions.md`、`docs/adr/0002-reimagined-site-structure.md`。

---

## File Structure

- `backend_v2/schema.sql` — v2 完整 schema(保留 + 捨棄 + 新增)。
- `backend_v2/wrangler.jsonc` — v2 後端的 wrangler 設定(D1 binding `langmap-v2`,local-first)。
- `backend_v2/package.json` — 暫時只需要遷移/測試用依賴(wrangler、better-sqlite3、vitest);Hono app 留到下一份計畫。
- `scripts/v2/package.json` — 遷移工具依賴(better-sqlite3、vitest、tsx)。
- `scripts/v2/lib/edges.ts` — 純函式:一組 expression ids → 完全圖邊集合。
- `scripts/v2/lib/handbook.ts` — 純函式:Markdown → 章節 + 有序詞句標記。
- `scripts/v2/lib/edges.test.ts`、`handbook.test.ts` — vitest 單元測試。
- `scripts/v2/migrate.ts` — 遷移 runner:讀舊 sqlite、emit v2 SQL。
- `scripts/v2/README.md` — 操作步驟(同步、遷移、驗證)。

---

## Task 0: 遠端舊資料同步到本地

**Goal:** 把遠端 D1 的舊資料匯出並載入本地舊 D1,確保本地有一份完整的舊資料可供 Task 5/6 遷移使用。

**Files:** 無新建檔案,只跑命令。

- [ ] **Step 1: 匯出遠端 D1**

```bash
cd backend
npx wrangler d1 export langmap --remote --output remote-old.sql
```

Expected: 產生 `backend/remote-old.sql`,內容為舊 schema 的 INSERT 語句。若檔案為空或報錯,確認 `--remote` flag 有作用(需登入 Wrangler)。

- [ ] **Step 2: 重建本地舊 D1 並載入**

```bash
cd backend
npx wrangler d1 execute langmap --local --file=../scripts/init-db.sql
npx wrangler d1 execute langmap --local --file=./remote-old.sql
```

Expected: 兩條命令無報錯。若 `remote-old.sql` 不存在(Step 1 失敗),此步會中斷。

- [ ] **Step 3: 補種子資料**

```bash
cd backend
npx wrangler d1 execute langmap --local --file=../scripts/002_populate_languages.sql
npx wrangler d1 execute langmap --local --file=../scripts/028_migrate_ui_locales.sql
```

Expected: 種子資料補齊(若遠端 export 已含則為 no-op)。

- [ ] **Step 4: 驗證本地舊 D1 資料完整**

```bash
cd backend
npx wrangler d1 execute langmap --local --command="SELECT count(*) AS expressions FROM expressions"
npx wrangler d1 execute langmap --local --command="SELECT count(*) AS meanings FROM meanings"
npx wrangler d1 execute langmap --local --command="SELECT count(*) AS handbooks FROM handbooks"
npx wrangler d1 execute langmap --local --command="SELECT count(*) AS languages FROM languages"
```

Expected: 各表 count > 0。記下數字,Task 6 會用來比對遷移後的 v2 計數。

- [ ] **Step 5: Commit**

```bash
git add backend/remote-old.sql
git commit -m "chore(v2-migrate): add remote D1 export for local migration"
```

備註:若 `remote-old.sql` 太大不想入 git,可改加進 `.gitignore` 並跳過此步。

---

## Task 1: v2 schema

**Files:**
- Create: `backend_v2/schema.sql`

- [ ] **Step 1: 寫 schema**

內容 = `scripts/init-db.sql` 的「保留表逐字複製」+「捨棄表不寫」+「新增表」。完整檔案:

```sql
-- LangMap v2 schema
-- Usage: cd backend_v2 && npx wrangler d1 execute langmap-v2 --local --file=../backend_v2/schema.sql
-- ⚠ 會 DROP 表,僅本地/重建遠端用。

--------------------------------------------------------------------------------
-- 0. 清空
--------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS expressions_ai;
DROP TRIGGER IF EXISTS expressions_ad;
DROP TRIGGER IF EXISTS expressions_au;
DROP TABLE IF EXISTS handbook_section_items;
DROP TABLE IF EXISTS handbook_sections;
DROP TABLE IF EXISTS handbooks;
DROP TABLE IF EXISTS votes;
DROP TABLE IF EXISTS expression_edges;
DROP TABLE IF EXISTS expressions_fts;
DROP TABLE IF EXISTS language_stats;
DROP TABLE IF EXISTS ui_locales;
DROP TABLE IF EXISTS email_verification_tokens;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS expression_versions;
DROP TABLE IF EXISTS expressions;
DROP TABLE IF EXISTS languages;

--------------------------------------------------------------------------------
-- 1. 保留表(與 v1 相同)
--------------------------------------------------------------------------------

CREATE TABLE languages (
    id INTEGER PRIMARY KEY NOT NULL,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    direction TEXT DEFAULT 'ltr',
    is_active INTEGER DEFAULT 0,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    group_name TEXT,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_languages_code ON languages(code);
CREATE INDEX idx_languages_name ON languages(name);
CREATE INDEX idx_languages_is_active ON languages(is_active);
CREATE INDEX idx_languages_active_name ON languages(is_active, name);

CREATE TABLE expressions (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    language_code TEXT NOT NULL,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    tags TEXT,
    source_type TEXT DEFAULT 'user',
    source_ref TEXT,
    review_status TEXT DEFAULT 'pending',
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    "desc" TEXT DEFAULT NULL
);
CREATE INDEX idx_expressions_text ON expressions(text);
CREATE INDEX idx_expressions_language_code ON expressions(language_code);
CREATE INDEX idx_expressions_tags ON expressions(tags);
CREATE INDEX idx_expressions_created_by ON expressions(created_by);
CREATE INDEX idx_expressions_lang_text ON expressions(language_code, text);

CREATE TABLE expression_versions (
    id INTEGER PRIMARY KEY NOT NULL,
    expression_id INTEGER NOT NULL,
    text TEXT NOT NULL,
    audio_url TEXT,
    region_name TEXT,
    region_latitude TEXT,
    region_longitude TEXT,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    "desc" TEXT DEFAULT NULL
);
CREATE INDEX idx_expression_versions_expression_id ON expression_versions(expression_id);
CREATE INDEX idx_expr_versions_id_created ON expression_versions(expression_id, created_at DESC);

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    email_verified INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

CREATE TABLE email_verification_tokens (
    token TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    expires_at TEXT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX idx_email_verification_tokens_user_id ON email_verification_tokens(user_id);
CREATE INDEX idx_email_verification_tokens_expires_at ON email_verification_tokens(expires_at);

CREATE TABLE language_stats (
    language_code TEXT PRIMARY KEY,
    expression_count INTEGER DEFAULT 0
);

CREATE TABLE ui_locales (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    language_code TEXT UNIQUE NOT NULL,
    locale_json TEXT NOT NULL,
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_ui_locales_language_code ON ui_locales(language_code);

--------------------------------------------------------------------------------
-- 2. 全文搜尋 FTS5(保留)
--------------------------------------------------------------------------------
CREATE VIRTUAL TABLE expressions_fts USING fts5(
    text, content='expressions', content_rowid='id', tokenize='unicode61'
);
CREATE TRIGGER expressions_ai AFTER INSERT ON expressions BEGIN
    INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;
CREATE TRIGGER expressions_ad AFTER DELETE ON expressions BEGIN
    INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text);
END;
CREATE TRIGGER expressions_au AFTER UPDATE ON expressions BEGIN
    INSERT INTO expressions_fts(expressions_fts, rowid, text) VALUES ('delete', old.id, old.text);
    INSERT INTO expressions_fts(rowid, text) VALUES (new.id, new.text);
END;

--------------------------------------------------------------------------------
-- 3. 新增:直接映射(edges)、讚/踩、簡化手冊
--------------------------------------------------------------------------------

-- 直接映射(pairwise)。id = `${min(a,b)}-${max(a,b)}`,保證無向 + 唯一。
CREATE TABLE expression_edges (
    id TEXT PRIMARY KEY NOT NULL,
    expression_a_id INTEGER NOT NULL,
    expression_b_id INTEGER NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    source TEXT NOT NULL DEFAULT 'batch',
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(expression_a_id, expression_b_id),
    FOREIGN KEY (expression_a_id) REFERENCES expressions(id),
    FOREIGN KEY (expression_b_id) REFERENCES expressions(id)
);
CREATE INDEX idx_edges_a ON expression_edges(expression_a_id);
CREATE INDEX idx_edges_b ON expression_edges(expression_b_id);
CREATE INDEX idx_edges_score ON expression_edges(score DESC);

-- 讚/踩:映射 + 手冊共用一張表。
CREATE TABLE votes (
    id TEXT PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,
    target_type TEXT NOT NULL,
    target_id TEXT NOT NULL,
    vote INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, target_type, target_id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX idx_votes_target ON votes(target_type, target_id);
CREATE INDEX idx_votes_user ON votes(user_id);

-- 簡化手冊:標題 + 章節 + 有序詞句。無 Markdown、無正文。
CREATE TABLE handbooks (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    visibility TEXT NOT NULL DEFAULT 'public',
    score INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
CREATE INDEX idx_handbooks_visibility_created ON handbooks(visibility, created_at DESC);
CREATE INDEX idx_handbooks_score ON handbooks(score DESC);
CREATE INDEX idx_handbooks_user ON handbooks(user_id);

CREATE TABLE handbook_sections (
    id INTEGER PRIMARY KEY NOT NULL,
    handbook_id INTEGER NOT NULL,
    title TEXT,
    position INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE
);
CREATE INDEX idx_sections_handbook_position ON handbook_sections(handbook_id, position);

CREATE TABLE handbook_section_items (
    id INTEGER PRIMARY KEY NOT NULL,
    section_id INTEGER NOT NULL,
    expression_id INTEGER NOT NULL,
    position INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(section_id, expression_id),
    FOREIGN KEY (section_id) REFERENCES handbook_sections(id) ON DELETE CASCADE,
    FOREIGN KEY (expression_id) REFERENCES expressions(id)
);
CREATE INDEX idx_items_section_position ON handbook_section_items(section_id, position);
```

- [ ] **Step 2: 驗證 schema 可建立**

```bash
cd backend_v2
npx wrangler d1 execute langmap-v2 --local --file=./schema.sql
npx wrangler d1 execute langmap-v2 --local --command="SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
```
Expected: 看到 `expression_edges`、`votes`、`handbooks`、`handbook_sections`、`handbook_section_items`,且**沒有** `meanings`、`expression_meaning`、`collections`、`collection_items`、`handbook_pages`。

- [ ] **Step 3: Commit**

```bash
git add backend_v2/schema.sql
git commit -m "feat(v2): add v2 schema (edges, votes, simplified handbooks)"
```

---

## Task 2: backend_v2 / scripts/v2 專案骨架

**Files:**
- Create: `backend_v2/wrangler.jsonc`、`backend_v2/package.json`
- Create: `scripts/v2/package.json`、`scripts/v2/tsconfig.json`

- [ ] **Step 1: `backend_v2/wrangler.jsonc`**

仿 `backend/wrangler.jsonc`,但 D1 binding 改成新資料庫、先不綁 R2/DO(`database_id` 之後用 `wrangler d1 create` 產生再填):

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "langmap-backend-v2",
  "compatibility_date": "2025-08-03",
  "compatibility_flags": ["nodejs_compat"],
  "main": "./src/index.tsx",
  "assets": { "directory": "./public", "binding": "ASSETS" },
  "d1_databases": [
    { "binding": "DB", "database_name": "langmap-v2", "database_id": "REPLACE_AFTER_CREATE" }
  ],
  "observability": { "logs": { "enabled": true, "head_sampling_rate": 1, "invocation_logs": true, "persist": true } }
}
```

- [ ] **Step 2: `backend_v2/package.json`**

```json
{
  "name": "langmap-backend-v2",
  "private": true,
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy"
  },
  "dependencies": { "hono": "^4.0.0", "wrangler": "^4.0.0" }
}
```

- [ ] **Step 3: `scripts/v2/package.json`**

```json
{
  "name": "langmap-migrate-v2",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "vitest run",
    "migrate": "tsx migrate.ts"
  },
  "dependencies": { "better-sqlite3": "^11.0.0" },
  "devDependencies": { "tsx": "^4.0.0", "vitest": "^2.0.0", "@types/better-sqlite3": "^7.0.0" }
}
```

- [ ] **Step 4: `scripts/v2/tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022", "module": "ESNext", "moduleResolution": "Bundler",
    "strict": true, "esModuleInterop": true, "skipLibCheck": true
  },
  "include": ["*.ts", "lib/**/*.ts"]
}
```

- [ ] **Step 5: 安裝 + 驗證空測試會跑**

```bash
cd scripts/v2 && npm install && npx vitest run
```
Expected: `No test files found` 或 0 個測試(環境可跑)。

- [ ] **Step 6: Commit**

```bash
git add backend_v2/wrangler.jsonc backend_v2/package.json scripts/v2/
git commit -m "chore(v2): scaffold backend_v2 + migration tooling"
```

---

## Task 3: 純函式 — 組 → 完全圖邊

**Files:**
- Create: `scripts/v2/lib/edges.ts`
- Test: `scripts/v2/lib/edges.test.ts`

- [ ] **Step 1: 寫測試**

```ts
// edges.test.ts
import { describe, it, expect } from 'vitest';
import { edgesForGroup } from './edges';

describe('edgesForGroup', () => {
  it('3 members → 3 edges', () => {
    expect(edgesForGroup([1, 2, 3])).toEqual([
      { id: '1-2', a: 1, b: 2 },
      { id: '1-3', a: 1, b: 3 },
      { id: '2-3', a: 2, b: 3 },
    ]);
  });
  it('排序後產 id,小 id 在前(無向)', () => {
    const e = edgesForGroup([30, 5]);
    expect(e).toEqual([{ id: '5-30', a: 5, b: 30 }]);
  });
  it('0 或 1 個成員 → 無邊', () => {
    expect(edgesForGroup([])).toEqual([]);
    expect(edgesForGroup([7])).toEqual([]);
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd scripts/v2 && npx vitest run lib/edges.test.ts
```
Expected: FAIL(找不到 `./edges`)。

- [ ] **Step 3: 實作**

```ts
// edges.ts
export interface Edge { id: string; a: number; b: number; }

export function edgesForGroup(memberIds: number[]): Edge[] {
  const ids = [...new Set(memberIds)].sort((x, y) => x - y);
  const out: Edge[] = [];
  for (let i = 0; i < ids.length; i++) {
    for (let j = i + 1; j < ids.length; j++) {
      const a = ids[i], b = ids[j];
      out.push({ id: `${a}-${b}`, a, b });
    }
  }
  return out;
}
```

- [ ] **Step 4: 跑測試確認通過**

```bash
npx vitest run lib/edges.test.ts
```
Expected: 3 passed。

- [ ] **Step 5: Commit**

```bash
git add scripts/v2/lib/edges.ts scripts/v2/lib/edges.test.ts
git commit -m "feat(v2-migrate): group→clique edges helper + tests"
```

---

## Task 4: 純函式 — Markdown → 章節 + 有序詞句

**Files:**
- Create: `scripts/v2/lib/handbook.ts`
- Test: `scripts/v2/lib/handbook.test.ts`

規格:
- 輸入:`markdown: string`、`sourceLang: string`(`{{WORD}}` 預設 lang)、`leadTitle: string`(第一個標題前的內容所屬章節標題)。
- 標題(`/^(#{1,6})\s+(.+)$/`)開新章節,標題 = 標題文字。
- 標記 `` {{...}} `` 依出現順序加入「當前章節」,`(text, lang)` 在章節內去重(留首次)。
- 標記 lang:取 `lang:` 前綴的參數;無則 `sourceLang`。忽略 `mid:`。
- 章節內若無任何標記仍保留(忠實遷移;prose 丟棄)。
- 輸出:`{ title: string; items: { text: string; lang: string }[] }[]`。

- [ ] **Step 1: 寫測試**

```ts
// handbook.test.ts
import { describe, it, expect } from 'vitest';
import { parseHandbook } from './handbook';

describe('parseHandbook', () => {
  it('標題→章節、標記→有序詞句、lang 預設/顯式', () => {
    const md = [
      '前言 {{foo}} 結束',
      '',
      '# 問候',
      '',
      '{{text:你好|lang:cmn}} 和 {{text:Hello|lang:en}}',
    ].join('\n');
    const s = parseHandbook(md, 'en', 'My Handbook');
    expect(s).toEqual([
      { title: 'My Handbook', items: [{ text: 'foo', lang: 'en' }] },
      { title: '問候', items: [
        { text: '你好', lang: 'cmn' },
        { text: 'Hello', lang: 'en' },
      ] },
    ]);
  });
  it('同章節內 (text,lang) 去重', () => {
    const s = parseHandbook('{{a}} {{a}}', 'en', 'T');
    expect(s[0].items).toEqual([{ text: 'a', lang: 'en' }]);
  });
  it('mid 參數被忽略', () => {
    const s = parseHandbook('{{text:x|mid:123}}', 'en', 'T');
    expect(s[0].items).toEqual([{ text: 'x', lang: 'en' }]);
  });
  it('無標記的章節保留為空 items', () => {
    const s = parseHandbook('# 空\n\n只有 prose', 'en', 'T');
    expect(s[0]).toEqual({ title: 'T', items: [] });
    expect(s[1]).toEqual({ title: '空', items: [] });
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
npx vitest run lib/handbook.test.ts
```
Expected: FAIL(找不到 `./handbook`)。

- [ ] **Step 3: 實作**

```ts
// handbook.ts
export interface HandbookItem { text: string; lang: string; }
export interface HandbookSection { title: string; items: HandbookItem[]; }

const TAG_RE = /\{\{(?:text:)?([^|}]+)((?:\|[^}]+)*)\}\}/g;
const HEADING_RE = /^(#{1,6})\s+(.+?)\s*$/;

function parseParams(params: string, sourceLang: string): string {
  // params 如 "|lang:cmn|mid:123" → 取 lang
  const parts = params.split('|').map(s => s.trim()).filter(Boolean);
  for (const p of parts) {
    if (p.startsWith('lang:')) return p.slice(5).trim();
  }
  return sourceLang;
}

export function parseHandbook(markdown: string, sourceLang: string, leadTitle: string): HandbookSection[] {
  const sections: HandbookSection[] = [{ title: leadTitle, items: [] }];
  let cur = sections[0];
  const seen = new Set<string>();

  const pushTag = (text: string, lang: string) => {
    const key = `${text}|${lang}`;
    if (seen.has(key)) return;
    seen.add(key);
    cur.items.push({ text, lang });
  };

  // 逐行掃標題;標記跨行用全文 regex 但需要知道落點 → 改:逐行,先標題判斷,再對該行跑 TAG_RE
  for (const line of markdown.split(/\r?\n/)) {
    const h = line.match(HEADING_RE);
    if (h) {
      cur = { title: h[2], items: [] };
      sections.push(cur);
      seen.clear();
      continue;
    }
    let m: RegExpExecArray | null;
    TAG_RE.lastIndex = 0;
    while ((m = TAG_RE.exec(line)) !== null) {
      const text = m[1].trim();
      const lang = parseParams(m[2] || '', sourceLang);
      pushTag(text, lang);
    }
  }
  return sections;
}
```

- [ ] **Step 4: 跑測試確認通過**

```bash
npx vitest run lib/handbook.test.ts
```
Expected: 4 passed。

- [ ] **Step 5: Commit**

```bash
git add scripts/v2/lib/handbook.ts scripts/v2/lib/handbook.test.ts
git commit -m "feat(v2-migrate): markdown→sections+ordered-items helper + tests"
```

---

## Task 5: 遷移 runner

**Files:**
- Create: `scripts/v2/migrate.ts`
- Create: `scripts/v2/lib/fixture.sql`(小型舊資料樣本,給整合測試用)

runner 行為:
1. 開舊 sqlite(`better-sqlite3`,readonly)。
2. 逐字複製保留表:`languages`、`expressions`、`expression_versions`、`users`、`email_verification_tokens`、`language_stats`、`ui_locales`。
3. `meanings`+`expression_meaning` → `expression_edges`(組→完全圖、跨組去重、`source='migration'`、`score=0`)。
4. 舊 `handbooks`/`handbook_pages` → 新 `handbooks`/`handbook_sections`/`handbook_section_items`(用 `parseHandbook`;tag→expression 用 `(text,lang)` 查 `expressions`,查無則跳過並計數)。
5. 把 `INSERT` 寫到輸出 SQL 檔;stdout 印摘要計數。

- [ ] **Step 1: 寫 fixture(小型舊資料)**

```sql
-- fixture.sql:模擬一小份舊資料(舊 schema),供 migrate 整合驗證
INSERT INTO languages (id, code, name, is_active) VALUES (1, 'cmn', '普通话', 1), (2, 'en', 'English', 1);
INSERT INTO expressions (id, text, language_code, source_type) VALUES
  (101, '吃了吗', 'cmn', 'user'),
  (102, 'Have you eaten?', 'en', 'user'),
  (103, '你好', 'cmn', 'user'),
  (104, 'Hello', 'en', 'user');
INSERT INTO meanings (id) VALUES (9);
INSERT INTO expression_meaning (id, expression_id, meaning_id) VALUES
  ('101-9', 101, 9), ('102-9', 102, 9);
INSERT INTO users (id, username, email, password_hash, role) VALUES (1, 'admin', 'a@b.c', 'x', 'admin');
INSERT INTO handbooks (id, user_id, title, content, source_lang, is_public, has_pages) VALUES
  (1, 1, '問候手冊', '# 問候\n\n{{text:你好|lang:cmn}} 和 {{text:Hello|lang:en}}', 'en', 1, 0);
```

- [ ] **Step 2: 寫 migrate.ts**

```ts
// migrate.ts
import Database from 'better-sqlite3';
import { writeFileSync } from 'node:fs';
import { edgesForGroup } from './lib/edges';
import { parseHandbook } from './lib/handbook';

const [oldPath, outPath = './v2-data.sql'] = process.argv.slice(2);
if (!oldPath) { console.error('用法: tsx migrate.ts <舊 sqlite 路徑> [輸出 sql]'); process.exit(1); }

const old = new Database(oldPath, { readonly: true });
const lines: string[] = [];
const emit = (s: string) => lines.push(s);
const sqlStr = (v: unknown): string => (v === null || v === undefined ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`);

const COPY_TABLES = ['languages', 'expressions', 'expression_versions', 'users', 'email_verification_tokens', 'language_stats', 'ui_locales'];
let copyCounts: Record<string, number> = {};

function copyTable(table: string) {
  const cols = (old.prepare(`PRAGMA table_info(${table})`).all() as any[]).map(c => c.name);
  const rows = old.prepare(`SELECT * FROM ${table}`).all() as any[];
  copyCounts[table] = rows.length;
  for (const row of rows) {
    const vals = cols.map(c => sqlStr(row[c])).join(', ');
    emit(`INSERT INTO ${table} (${cols.join(', ')}) VALUES (${vals});`);
  }
}

// 1. 保留表
emit('-- copied tables');
for (const t of COPY_TABLES) {
  try { copyTable(t); } catch (e) { console.warn(`  跳過 ${t}:${(e as Error).message}`); }
}

// 2. meanings → edges(跨組去重)
emit('-- edges (from meanings)');
const groups = old.prepare(`SELECT meaning_id, expression_id FROM expression_meaning ORDER BY meaning_id, expression_id`).all() as any[];
const byMeaning = new Map<number, number[]>();
for (const r of groups) {
  if (!byMeaning.has(r.meaning_id)) byMeaning.set(r.meaning_id, []);
  byMeaning.get(r.meaning_id)!.push(r.expression_id);
}
const seenEdge = new Set<string>();
let edgeCount = 0;
for (const members of byMeaning.values()) {
  for (const e of edgesForGroup(members)) {
    if (seenEdge.has(e.id)) continue;
    seenEdge.add(e.id);
    emit(`INSERT INTO expression_edges (id, expression_a_id, expression_b_id, score, source) VALUES ('${e.id}', ${e.a}, ${e.b}, 0, 'migration');`);
    edgeCount++;
  }
}

// 3. handbooks → 簡化
emit('-- handbooks (simplified)');
const exprLookup = new Map<string, number>();
(old.prepare(`SELECT id, text, language_code FROM expressions`).all() as any[]).forEach(r => exprLookup.set(`${r.text}|${r.language_code}`, r.id));
const lookupExpr = (text: string, lang: string): number | null => exprLookup.has(`${text}|${lang}`) ? exprLookup.get(`${text}|${lang}`)! : null;

const handbooks = old.prepare(`SELECT * FROM handbooks ORDER BY id`).all() as any[];
let sectionId = 1, itemId = 1;
let hbCount = 0, secCount = 0, itemCount = 0, missingExpr = 0;
for (const hb of handbooks) {
  const vis = hb.is_public ? 'public' : 'private';
  emit(`INSERT INTO handbooks (id, user_id, title, visibility, score, created_at, updated_at) VALUES (${hb.id}, ${hb.user_id}, ${sqlStr(hb.title)}, '${vis}', 0, ${sqlStr(hb.created_at)}, ${sqlStr(hb.updated_at)});`);
  hbCount++;
  let sections;
  if (hb.has_pages) {
    const pages = old.prepare(`SELECT * FROM handbook_pages WHERE handbook_id = ? ORDER BY sort_order, id`).all(hb.id) as any[];
    sections = [];
    for (const p of pages) sections.push(...parseHandbook(p.content || '', hb.source_lang || 'en', p.title));
  } else {
    sections = parseHandbook(hb.content || '', hb.source_lang || 'en', hb.title);
  }
  sections.forEach((sec, si) => {
    emit(`INSERT INTO handbook_sections (id, handbook_id, title, position) VALUES (${sectionId}, ${hb.id}, ${sqlStr(sec.title)}, ${si});`);
    secCount++;
    sec.items.forEach((it, ii) => {
      const eid = lookupExpr(it.text, it.lang);
      if (eid === null) { missingExpr++; return; }
      emit(`INSERT INTO handbook_section_items (id, section_id, expression_id, position) VALUES (${itemId}, ${sectionId}, ${eid}, ${ii});`);
      itemId++; itemCount++;
    });
    sectionId++;
  });
}

old.close();
writeFileSync(outPath, lines.join('\n'));
console.log('── 遷移摘要 ──');
console.log('copied:', copyCounts);
console.log('edges:', edgeCount);
console.log('handbooks:', hbCount, '/ sections:', secCount, '/ items:', itemCount, '/ missing-tags-skipped:', missingExpr);
console.log('輸出:', outPath);
```

- [ ] **Step 3: 整合驗證 — 用 fixture**

```bash
# 1) 本地起一個「舊 schema」D1 並載 fixture
cd backend && npx wrangler d1 execute langmap --local --file=../scripts/init-db.sql
npx wrangler d1 execute langmap --local --file=../scripts/v2/lib/fixture.sql

# 2) 找出本地舊 D1 的 sqlite 檔
OLDDB=$(ls -t .wrangler/state/v3/d1/miniflareD1Database/*/db.sqlite 2>/dev/null | head -1)
echo "舊 sqlite: $OLDDB"

# 3) 跑遷移
cd ../scripts/v2 && npm run migrate -- "$OLDDB/../../$(basename $(dirname $OLDDB))/db.sqlite" ./v2-data.sql 2>/dev/null \
  || npx tsx migrate.ts "$(ls -t ../../backend/.wrangler/state/v3/d1/**/db.sqlite | head -1)" ./v2-data.sql

# 4) 載入 v2 schema + 遷移結果到本地 v2 D1
cd ../../backend_v2 && npx wrangler d1 execute langmap-v2 --local --file=./schema.sql
npx wrangler d1 execute langmap-v2 --local --file=../scripts/v2/v2-data.sql
```
Expected 摘要:`edges: 1`(101↔102)、`handbooks: 1 / sections: 1 / items: 2`(你好、Hello)、`missing-tags-skipped: 0`。

- [ ] **Step 4: 查驗 v2 D1**

```bash
cd backend_v2
npx wrangler d1 execute langmap-v2 --local --command="SELECT count(*) AS edges FROM expression_edges"
npx wrangler d1 execute langmap-v2 --local --command="SELECT count(*) AS items FROM handbook_section_items"
```
Expected: `edges = 1`、`items = 2`。

- [ ] **Step 5: Commit**

```bash
git add scripts/v2/migrate.ts scripts/v2/lib/fixture.sql
git commit -m "feat(v2-migrate): runner (copy + meanings→edges + handbooks→simplified)"
```

---

## Task 6: 整合 — 真實資料遷移、驗證

**Files:**
- Create: `scripts/v2/README.md`(操作步驟 + 驗證結果)
- 此任務不寫程式,只跑程序並記錄結果。
- 前置: Task 0 已完成(遠端資料已同步到本地舊 D1)。

- [ ] **Step 1: 寫 `scripts/v2/README.md`**

內容:完整操作步驟(本地舊 D1 → migrate → v2 本地 D1 → 計數驗證;遠端重建之後再做)。

- [ ] **Step 2: 找舊 sqlite、跑遷移**

```bash
OLDDB=$(ls -t backend/.wrangler/state/v3/d1/miniflareD1Database/*/db.sqlite | head -1)
cd scripts/v2 && npx tsx migrate.ts "$OLDDB" ./v2-data.sql
```
記下摘要:`edges`、`handbooks`、`sections`、`items`、`missing-tags-skipped`。

- [ ] **Step 3: 載入 v2 本地 D1 並驗證計數**

```bash
cd ../backend_v2
npx wrangler d1 execute langmap-v2 --local --file=./schema.sql
npx wrangler d1 execute langmap-v2 --local --file=../scripts/v2/v2-data.sql

npx wrangler d1 execute langmap-v2 --local --command="SELECT count(*) AS expr FROM expressions"
npx wrangler d1 execute langmap-v2 --local --command="SELECT count(*) AS edges FROM expression_edges"
npx wrangler d1 execute langmap-v2 --local --command="SELECT count(*) AS hbs FROM handbooks"
npx wrangler d1 execute langmap-v2 --local --command="SELECT count(*) AS items FROM handbook_section_items"
```
Expected(合理性,非固定值):
- `edges` ≈ Σ(每組 N(N−1)/2);若某表達式同屬多組會跨組去重。
- `missing-tags-skipped` 偏高 → 代表舊手冊標記的 (text,lang) 在 expressions 查不到,需檢查(可能 lang 預設不符或該表達式已刪)。
- `items > 0` 證明手冊遷移有抽出詞句。

- [ ] **Step 4: 抽樣查 edges 正確性**

```bash
cd backend_v2
npx wrangler d1 execute langmap-v2 --local --command="SELECT * FROM expression_edges LIMIT 3"
```
對照舊 `expression_meaning`:任一邊的 a、b 應曾在同一 meaning_id 出現。

- [ ] **Step 5: 記錄結果 + Commit**

把 Step 2 的摘要計數 + Task 0 Step 4 的舊資料計數 寫進 `scripts/v2/README.md` 的「驗證結果」段。
```bash
git add scripts/v2/README.md
git commit -m "docs(v2-migrate): record real-data migration validation"
```

---

## 備註

- **遠端重建**(之後,本計畫之外):`wrangler d1 create langmap-v2`(拿 database_id 填進 `backend_v2/wrangler.jsonc`)→ 遠端跑 `schema.sql` → 遠端載 `v2-data.sql`。本計畫只做到本地驗證。
- **prose 丟失**:舊手冊 Markdown 的非標記文字在遷移中被捨棄(新模型無 prose 欄位)。已記於 ADR-0002。
- **collections 不遷**:v2 砍除收藏功能,`collections`/`collection_items` 不複製。
- **間接映射 / 折疊 / feed** 等查詢邏輯屬於下一份計畫(backend_v2 API)。
