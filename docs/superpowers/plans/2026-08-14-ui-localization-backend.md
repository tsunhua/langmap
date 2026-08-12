# UI Localization Backend Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Plan 1-5 之上實作 UI localization 後端領域:`ui_locales` 與 `ui_messages` 表、English source message seeding、coverage 計算、auto/manual activation、per-key fallback bundle,以及 §13.4 的 8 條 localization API。

**Architecture:** 分五層推進:(1) schema baseline(migration 0006: `ui_locales` + `ui_messages` + `system-ui` source + `eng-Latn-US` locale seed + `local.py` 重新載入 UI SQL);(2) UI seed script(`generate-ui-seed.py`:讀取 `en.ts`、計算 Expression hash、產生 seed SQL);(3) localization domain service(`localizationDomain.ts`:coverage 計算、activation logic、recalculate + revision bump);(4) bundle + routes(`localization.ts` route:8 條 API,含 per-key fallback bundle resolution);(5) 回歸驗證。

**Tech Stack:** Hono 4 + TypeScript + D1;Zod 4;Vitest;Python 3(seed script + hashlib)。

## Global Constraints

- `ui_locales` 表逐字抄自 spec §12.1:`(project_id, language_locale_code)` PK、`status CHECK ('draft','active','archived')`、`mapping_revision INTEGER DEFAULT 0`、`activation_source CHECK ('system','auto','manual')`、`activated_at`／`activated_by`／`created_by`／timestamps。不存 `native_name`／`direction`／`fallback_code`(§12.1)。
- `eng-Latn-US` 作 `langmap-web` source UI Locale,固定 active + `activation_source = 'system'`,不可封存或降級(§12.1)。
- `ui_messages` 表(spec 無完整 DDL,由本 plan 設計):`(project_id, message_key)` PK、`source_expression_id TEXT NOT NULL FK→expressions(id)`、`source_text TEXT NOT NULL`、`placeholders_json TEXT NOT NULL DEFAULT '[]'`、`status CHECK ('active','inactive')`。
- English source Expression 的 `source_id = 'system-ui'`、`source_ref = 'ui:<project_id>:<message_key>:<revision>'`(§12.2、§7.3)。
- Coverage = translated_active_keys / total_active_keys(§12.3)。Candidate 必須滿足 6 條件(直接 mapping、lang_code 匹配、locale attestation 存在、edge score ≥ 0、placeholder set 一致、非 fallback)。Candidate 選擇:edge score DESC、edge created_at ASC、target Expression ID ASC(§12.3)。`total_active_keys = 0` 時 coverage = 0(§12.3)。
- Activation:Draft coverage ≥ 0.60 → auto active(`activation_source = 'auto'`);Admin 可手動啟用 draft(`activation_source = 'manual'`);Active 不自動降級;Admin 可封存;Archived 不接受翻譯、不參與 bundle(§12.4)。
- 事件觸發 coverage/revision 重算:translation mapping 新增、UI message 啟用/退役、split edge move(§12.4)。本 plan 實作 mapping 新增後的重算;split 的接線在 service 層保留 hook。
- Per-key fallback:primary active candidate ?? secondary active candidate ?? English source text。不做其他 fallback。Fallback 不計 coverage(§12.5)。Bundle 回傳 `resolved_from`(§12.5)。
- API routes(§13.4):8 條,prefix `/api/v2/localization/projects/:projectId`。登入者未傳 query 時使用已保存 preference;匿名者未傳 query 時使用 English(§13.4)。Query 永遠經 Language Locale validator。
- 穩定錯誤碼:`UI_LOCALE_NOT_ACTIVE`、`UI_LOCALE_ARCHIVED`、`UI_LOCALE_ALREADY_ACTIVE`(§14)。
- 所有查詢穩定排序 + 數量上限(§4.11)。
- migration 使用 `IF NOT EXISTS`、`schema.sql` 不使用(repo 慣例)。
- 不新增 `any`;新程式碼不加註解。不修改 `web/`、`apple/`。
- 整合測試依賴 127.0.0.1:8788 worker + 已 rebuild D1。
- 已知既有失敗:`auth.test.ts` × 1、`expressionsIntegration.test.ts` × 2。

---

## File Structure

| 檔案 | 責任 | 動作 |
|---|---|---|
| `backend/migrations/0006_ui_localization.sql` | `ui_locales` + `ui_messages` DDL + `system-ui` source + `eng-Latn-US` locale seed | Create |
| `backend/schema.sql` | 與 0006 等價 | Modify |
| `backend/tests/schemaContract.test.ts` | 斷言新表 | Modify |
| `scripts/db/migration-lock.json` | 記錄 0006 | Modify |
| `scripts/db/lib/local.py` | 重新載入 UI seed SQL | Modify |
| `scripts/i18n/generate-ui-seed.py` | 讀 en.ts → 產生 ui-seed SQL(Expressions + ui_messages) | Create |
| `scripts/i18n/artifacts/system-ui/system-ui.sql` | 生成的 seed SQL(commit) | Overwrite |
| `backend/src/services/localizationDomain.ts` | coverage、activation、recalculate、bundle resolution | Create |
| `backend/src/routes/localization.ts` | 8 條 API endpoint | Create |
| `backend/src/routes/index.ts` | 註冊 localization route | Modify |
| `backend/tests/localizationDomain.test.ts` | service 單元測試 | Create |
| `backend/tests/localizationIntegration.test.ts` | API 整合測試 | Create |

---

## Task 1: Schema —— `ui_locales` + `ui_messages` + system seeds

**Files:**
- Create: `backend/migrations/0006_ui_localization.sql`
- Modify: `backend/schema.sql`、`backend/tests/schemaContract.test.ts`
- Modify: `scripts/db/migration-lock.json`
- Modify: `scripts/db/lib/local.py`

- [x] **Step 1: 建立 migration 0006**

Create `backend/migrations/0006_ui_localization.sql`:

```sql
-- UI localization tables (spec §12.1, §12.2).

CREATE TABLE IF NOT EXISTS ui_locales (
  project_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'archived')),
  mapping_revision INTEGER NOT NULL DEFAULT 0,
  activation_source TEXT
    CHECK (activation_source IN ('system', 'auto', 'manual')),
  activated_at TEXT,
  activated_by INTEGER,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, language_locale_code),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (activated_by) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS ui_messages (
  project_id TEXT NOT NULL,
  message_key TEXT NOT NULL,
  source_expression_id TEXT NOT NULL,
  source_text TEXT NOT NULL,
  placeholders_json TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, message_key),
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-ui', 'system', 'LangMap UI source copy');

INSERT OR IGNORE INTO ui_locales (project_id, language_locale_code, status, mapping_revision, activation_source, activated_at)
VALUES ('langmap-web', 'eng-Latn-US', 'active', 0, 'system', CURRENT_TIMESTAMP);
```

- [x] **Step 2: 更新 `backend/schema.sql`**

READ 當前檔案。在 DROP 區塊,`DROP TABLE IF EXISTS ui_messages;` 之前加入:

```sql
DROP TABLE IF EXISTS ui_messages;
DROP TABLE IF EXISTS ui_locales;
```

注意:現有的 `DROP TABLE IF EXISTS ui_messages;` 和 `DROP TABLE IF EXISTS ui_locales;` 可能已在 DROP 區塊(從舊 schema 遺留)。確認它們存在;如果已存在就保持原位,不要重複加。

在檔尾(最後一張表之後)新增(無 `IF NOT EXISTS`):

```sql

-- UI localization tables (spec §12.1, §12.2).

CREATE TABLE ui_locales (
  project_id TEXT NOT NULL,
  language_locale_code TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'active', 'archived')),
  mapping_revision INTEGER NOT NULL DEFAULT 0,
  activation_source TEXT
    CHECK (activation_source IN ('system', 'auto', 'manual')),
  activated_at TEXT,
  activated_by INTEGER,
  created_by INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, language_locale_code),
  FOREIGN KEY (language_locale_code) REFERENCES language_locales(code),
  FOREIGN KEY (activated_by) REFERENCES users(id),
  FOREIGN KEY (created_by) REFERENCES users(id)
);

CREATE TABLE ui_messages (
  project_id TEXT NOT NULL,
  message_key TEXT NOT NULL,
  source_expression_id TEXT NOT NULL,
  source_text TEXT NOT NULL,
  placeholders_json TEXT NOT NULL DEFAULT '[]',
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'inactive')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (project_id, message_key),
  FOREIGN KEY (source_expression_id) REFERENCES expressions(id)
);

INSERT OR IGNORE INTO sources (id, type, name) VALUES
  ('system-ui', 'system', 'LangMap UI source copy');

INSERT OR IGNORE INTO ui_locales (project_id, language_locale_code, status, mapping_revision, activation_source, activated_at)
VALUES ('langmap-web', 'eng-Latn-US', 'active', 0, 'system', CURRENT_TIMESTAMP);
```

- [x] **Step 3: 更新 `backend/tests/schemaContract.test.ts`**

在 `does not contain obsolete identity tables` 之前新增:

```ts
  it('defines ui_locales with status, revision and activation tracking', () => {
    expect(schema).toMatch(/CREATE TABLE ui_locales[\s\S]*?PRIMARY KEY \(project_id, language_locale_code\)/s);
    expect(schema).toMatch(/CREATE TABLE ui_locales[\s\S]*?CHECK \(status IN \('draft', 'active', 'archived'\)\)/s);
    expect(schema).toMatch(/CREATE TABLE ui_locales[\s\S]*?mapping_revision INTEGER NOT NULL DEFAULT 0/s);
    expect(schema).toMatch(/CREATE TABLE ui_locales[\s\S]*?CHECK \(activation_source IN \('system', 'auto', 'manual'\)\)/s);
  });

  it('defines ui_messages with source expression FK', () => {
    expect(schema).toMatch(/CREATE TABLE ui_messages[\s\S]*?source_expression_id TEXT NOT NULL/s);
    expect(schema).toMatch(/CREATE TABLE ui_messages[\s\S]*?PRIMARY KEY \(project_id, message_key\)/s);
    expect(schema).toMatch(/CREATE TABLE ui_messages[\s\S]*?FOREIGN KEY \(source_expression_id\) REFERENCES expressions\(id\)/s);
  });

  it('seeds eng-Latn-US as the system source UI locale for langmap-web', () => {
    expect(schema).toMatch(/langmap-web.*eng-Latn-US.*active.*system/s);
  });
```

- [x] **Step 4: 同步 migration-lock**

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

Expected: 6 entries.

- [x] **Step 5: 更新 `scripts/db/lib/local.py` 重新載入 UI seed SQL**

READ `scripts/db/lib/local.py`。找到執行 schema + language-registry SQL 的區塊(Plan 1 Task 4 移除了 `system_ui_sql_path` 載入)。在 `language_registry_sql_path` 載入之後加回:

```python
        executor.execute_file(temp_state_dir, paths.system_ui_sql_path)
```

注意:Task 2 會生成新的 `system-ui.sql`。如果 Task 2 尚未執行,先暫時加一行 pass-through 或在 rebuild 時容忍檔案不存在。最安全的做法:先跑 Task 2 再啟用此行。本 Step 先修改程式碼,Step 8 rebuild 時 Task 2 的 SQL 已就緒。

- [x] **Step 6: 跑 schemaContract 測試**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/schemaContract.test.ts
```

Expected: 全 PASS(既有 13 + 新增 3 = 16)。

- [x] **Step 7: 跑 scripts 驗證(不 rebuild,僅 verify schema)**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && python3 -m unittest scripts.db.tests.test_verify
```

- [x] **Step 8: Commit(不含 rebuild——Task 2 生成 SQL 後統一 rebuild)**

```bash
git add backend/migrations/0006_ui_localization.sql backend/schema.sql backend/tests/schemaContract.test.ts scripts/db/migration-lock.json scripts/db/lib/local.py
git commit -m "feat(db): add ui_locales and ui_messages tables with system-ui source"
```

---

## Task 2: UI message seed script(`generate-ui-seed.py`)

讀取 `web/src/locales/en.ts`,為每個 message key 計算 English Expression hash,生成 seed SQL。

**Files:**
- Create: `scripts/i18n/generate-ui-seed.py`
- Overwrite: `scripts/i18n/artifacts/system-ui/system-ui.sql`

- [x] **Step 1: 建立 `scripts/i18n/generate-ui-seed.py`**

```python
#!/usr/bin/env python3
"""Generate seed SQL for UI messages from web/src/locales/en.ts.

Creates English Expressions (eng:{text_hash}) and ui_messages rows for the
langmap-web project. Output: artifacts/system-ui/system-ui.sql.

Each Expression gets source_id='system-ui', source_ref='ui:langmap-web:{key}:1'.
"""
from __future__ import annotations

import base64
import hashlib
import json
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
EN_TS_PATH = PROJECT_ROOT / "web" / "src" / "locales" / "en.ts"
OUTPUT_PATH = Path(__file__).resolve().parent / "artifacts" / "system-ui" / "system-ui.sql"
PROJECT_ID = "langmap-web"
LANG_CODE = "eng"


def compute_text_hash(text: str) -> str:
    digest = hashlib.sha256(text.encode("utf-8")).digest()[:16]
    return base64.b32encode(digest).decode("ascii").lower().rstrip("=")


def parse_en_ts(content: str) -> dict[str, str]:
    lines = content.splitlines()
    stack: list[str] = []
    result: dict[str, str] = {}
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("//") or stripped.startswith("*"):
            continue
        if stripped.startswith("export ") or stripped == "} as const":
            continue
        if stripped in ("},", "}", "};"):
            if stack:
                stack.pop()
            continue
        key_match = re.match(r"^(\w+)\s*:\s*", stripped)
        if not key_match:
            continue
        key = key_match.group(1)
        rest = stripped[key_match.end():]
        if rest.startswith("{"):
            stack.append(key)
        elif rest.startswith("'") or rest.startswith('"'):
            q = rest[0]
            val_match = re.match(rf"^{re.escape(q)}((?:[^{re.escape(q)}\\]|\\.)*){re.escape(q)}\s*,?\s*$", rest)
            if val_match and stack:
                val = val_match.group(1).replace(f"\\{q}", q)
                result[".".join(stack + [key])] = val
    return result


def extract_placeholders(text: str) -> list[str]:
    return sorted(set(re.findall(r"\{(\w+)\}", text)))


def sql_str(s: str) -> str:
    return "'" + s.replace("'", "''") + "'"


def main() -> int:
    content = EN_TS_PATH.read_text(encoding="utf-8")
    messages = parse_en_ts(content)
    if not messages:
        print("ERROR: no messages parsed from en.ts", file=sys.stderr)
        return 1

    lines = [
        "-- AUTO-GENERATED by scripts/i18n/generate-ui-seed.py. Do not edit.",
        f"-- {len(messages)} UI messages for project '{PROJECT_ID}'.",
        "",
    ]

    for key in sorted(messages):
        text = messages[key]
        text_hash = compute_text_hash(text)
        expr_id = f"{LANG_CODE}:{text_hash}"
        placeholders = json.dumps(extract_placeholders(text))

        lines.append(f"-- {key}")
        lines.append(
            f"INSERT OR IGNORE INTO expressions (id, lang_code, text, text_hash, homograph_index, "
            f"description, tags_json, source_id, source_ref, review_status, created_by) "
            f"VALUES ({sql_str(expr_id)}, {sql_str(LANG_CODE)}, {sql_str(text)}, {sql_str(text_hash)}, "
            f"1, '', '[]', 'system-ui', {sql_str(f'ui:{PROJECT_ID}:{key}:1')}, 'approved', NULL);"
        )
        lines.append(
            f"INSERT OR IGNORE INTO ui_messages (project_id, message_key, source_expression_id, "
            f"source_text, placeholders_json, status) "
            f"VALUES ({sql_str(PROJECT_ID)}, {sql_str(key)}, {sql_str(expr_id)}, {sql_str(text)}, "
            f"{sql_str(placeholders)}, 'active');"
        )
        lines.append("")

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUTPUT_PATH} ({len(messages)} messages)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [x] **Step 2: 驗證 hash 與 TS 實作一致**

```bash
python3 -c "
import hashlib, base64
digest = hashlib.sha256(b'hello').digest()[:16]
h = base64.b32encode(digest).decode('ascii').lower().rstrip('=')
print(h)
print(h == 'ftze3os7wcrq4jxihmvmlopcty')
"
```

Expected: `ftze3os7wcrq4jxihmvmlopcty` then `True`。

- [x] **Step 3: 跑生成器**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && python3 scripts/i18n/generate-ui-seed.py
```

Expected: `wrote .../system-ui.sql (N messages)` where N ≈ 200。

- [x] **Step 4: 驗證生成的 SQL 可被 SQLite 接受**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && python3 -c "
import sqlite3, glob
path = sorted(glob.glob('backend/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/*.sqlite'))[0]
con = sqlite3.connect(path)
sql = open('scripts/i18n/artifacts/system-ui/system-ui.sql').read()
con.executescript(sql)
count = con.execute('SELECT COUNT(*) FROM ui_messages WHERE project_id = ?', ('langmap-web',)).fetchone()[0]
print(f'ui_messages: {count}')
sample = con.execute('SELECT message_key, source_expression_id, source_text FROM ui_messages LIMIT 3').fetchall()
for row in sample:
    print(row)
con.close()
"
```

Expected: count ≈ 200;sample rows show key/expression_id/text。

- [x] **Step 5: Rebuild 本地 D1(含新 UI seed)**

確保 8788 沒有 worker:

```bash
kill $(pgrep -f "wrangler dev") 2>/dev/null; sleep 1
cd /Users/share.lim/Documents/GitHub/langmap && python3 scripts/db/manage.py local rebuild
```

Expected: `"status": "rebuilt"`。

- [x] **Step 6: 跑 scripts 驗證**

```bash
python3 -m unittest scripts.db.tests.test_verify
python3 scripts/db/tests/test_local_rebuild.py
```

- [x] **Step 7: Commit**

```bash
git add scripts/i18n/generate-ui-seed.py scripts/i18n/artifacts/system-ui/system-ui.sql
git commit -m "feat(scripts): generate UI message seed SQL from en.ts with Expression hashes"
```

---

## Task 3: Localization domain service(`localizationDomain.ts`)

Core domain logic:coverage 計算、activation、recalculate + revision bump、bundle resolution。

**Files:**
- Create: `backend/src/services/localizationDomain.ts`
- Create: `backend/tests/localizationDomain.test.ts`

**Interfaces:**
- Consumes: `D1Database`;`createEdge` from `services/mappings`;`getPreferences` from `services/preferences`;`parseLanguageLocaleCode` from `services/languageIdentity`。
- Produces:
  - `class LocalizationError extends Error { constructor(public code: string) }`
  - `computeCoverage(db, projectId, languageLocaleCode): Promise<{ coverage: number; total: number; translated: number }>`
  - `recalculateLocale(db, projectId, languageLocaleCode): Promise<void>`
  - `activateLocale(db, projectId, code, source: 'auto'|'manual', userId: number): Promise<void>`
  - `archiveLocale(db, projectId, code, userId): Promise<void>`
  - `resolveBundle(db, projectId, primary?: string, secondary?: string): Promise<BundleEntry[]>`

- [ ] **Step 1: 寫失敗的單元測試**

Create `backend/tests/localizationDomain.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { LocalizationError, computeCoverage, resolveBundle } from '../src/services/localizationDomain';

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

describe('computeCoverage', () => {
  it('returns 0 coverage when there are no active messages', async () => {
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM ui_messages WHERE project_id = ? AND status = ?': () => ({ total: 0 }),
      'SELECT lang_code FROM language_locales WHERE code = ?': () => ({ lang_code: 'cmn' }),
    });
    const result = await computeCoverage(db, 'langmap-web', 'cmn-Hant-TW');
    expect(result.coverage).toBe(0);
    expect(result.total).toBe(0);
  });

  it('computes coverage from translated keys with valid candidates', async () => {
    const db = fakeD1({
      'SELECT COUNT(*) AS total FROM ui_messages WHERE project_id = ? AND status = ?': () => ({ total: 3 }),
      'SELECT lang_code FROM language_locales WHERE code = ?': () => ({ lang_code: 'cmn' }),
      'SELECT m.message_key, m.placeholders_json, m.source_text, t.id AS target_id, t.text AS target_text, e.id AS edge_id, e.score, e.created_at FROM ui_messages m JOIN expression_edges e ON e.expression_a_id = m.source_expression_id OR e.expression_b_id = m.source_expression_id JOIN expressions t ON t.id = CASE WHEN e.expression_a_id = m.source_expression_id THEN e.expression_b_id ELSE e.expression_a_id END WHERE m.project_id = ? AND m.status = ? AND e.score >= 0 AND t.lang_code = ? AND EXISTS (SELECT 1 FROM expression_locale_attestations WHERE expression_id = t.id AND language_locale_code = ?) ORDER BY m.message_key ASC, e.score DESC, e.created_at ASC, t.id ASC':
        () => ({
          results: [
            { message_key: 'a.key', placeholders_json: '[]', source_text: 'Hello', target_id: 'cmn:t1', target_text: '你好', edge_id: 'e1', score: 0, created_at: '2026-01-01' },
            { message_key: 'b.key', placeholders_json: '[]', source_text: 'World', target_id: 'cmn:t2', target_text: '世界', edge_id: 'e2', score: 0, created_at: '2026-01-01' },
          ],
        }),
    });
    const result = await computeCoverage(db, 'langmap-web', 'cmn-Hant-TW');
    expect(result.total).toBe(3);
    expect(result.translated).toBe(2);
    expect(result.coverage).toBeCloseTo(2 / 3);
  });
});

describe('resolveBundle', () => {
  it('falls back to English source when no active locale matches', async () => {
    const db = fakeD1({
      'SELECT message_key, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? ORDER BY message_key ASC':
        () => ({
          results: [
            { message_key: 'greeting', source_text: 'Hello', placeholders_json: '[]' },
          ],
        }),
      'SELECT status FROM ui_locales WHERE project_id = ? AND language_locale_code = ?': () => null,
    });
    const bundle = await resolveBundle(db, 'langmap-web');
    expect(bundle[0].key).toBe('greeting');
    expect(bundle[0].text).toBe('Hello');
    expect(bundle[0].resolved_from).toBe('source');
  });
});
```

- [ ] **Step 2: 跑測試確認失敗**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/localizationDomain.test.ts
```

Expected: FAIL(module not found)。

- [ ] **Step 3: 建立 `backend/src/services/localizationDomain.ts`**

```ts
import type { D1Database } from '@cloudflare/workers-types';

export interface BundleEntry {
  key: string;
  text: string;
  resolved_from: 'primary' | 'secondary' | 'source';
}

export class LocalizationError extends Error {
  constructor(public code: string) {
    super(code);
    this.name = 'LocalizationError';
  }
}

const AUTO_ACTIVATION_THRESHOLD = 0.60;

function extractPlaceholders(text: string): string[] {
    return Array.from(text.matchAll(/\{(\w+)\}/g)).map((m) => m[1]).sort();
}

export async function computeCoverage(
  db: D1Database,
  projectId: string,
  languageLocaleCode: string,
): Promise<{ coverage: number; total: number; translated: number }> {
  const totalRow = await db
    .prepare('SELECT COUNT(*) AS total FROM ui_messages WHERE project_id = ? AND status = ?')
    .bind(projectId, 'active')
    .first<{ total: number }>();
  const total = totalRow?.total ?? 0;
  if (total === 0) return { coverage: 0, total: 0, translated: 0 };

  const langRow = await db
    .prepare('SELECT lang_code FROM language_locales WHERE code = ?')
    .bind(languageLocaleCode)
    .first<{ lang_code: string }>();
  if (!langRow) return { coverage: 0, total, translated: 0 };

  const { results } = await db
    .prepare(
      `SELECT m.message_key, m.placeholders_json, m.source_text,
              t.id AS target_id, t.text AS target_text,
              e.id AS edge_id, e.score, e.created_at
       FROM ui_messages m
       JOIN expression_edges e ON e.expression_a_id = m.source_expression_id OR e.expression_b_id = m.source_expression_id
       JOIN expressions t ON t.id = CASE WHEN e.expression_a_id = m.source_expression_id THEN e.expression_b_id ELSE e.expression_a_id END
       WHERE m.project_id = ? AND m.status = ? AND e.score >= 0 AND t.lang_code = ?
         AND EXISTS (SELECT 1 FROM expression_locale_attestations WHERE expression_id = t.id AND language_locale_code = ?)
       ORDER BY m.message_key ASC, e.score DESC, e.created_at ASC, t.id ASC`,
    )
    .bind(projectId, 'active', langRow.lang_code, languageLocaleCode)
    .all<{
      message_key: string;
      placeholders_json: string;
      source_text: string;
      target_id: string;
      target_text: string;
      edge_id: string;
      score: number;
      created_at: string;
    }>();

  const translatedKeys = new Set<string>();
  for (const row of results) {
    if (translatedKeys.has(row.message_key)) continue;
    const sourcePlaceholders = JSON.parse(row.placeholders_json) as string[];
    const targetPlaceholders = extractPlaceholders(row.target_text);
    if (JSON.stringify(sourcePlaceholders) !== JSON.stringify(targetPlaceholders)) continue;
    translatedKeys.add(row.message_key);
  }

  const translated = translatedKeys.size;
  return { coverage: translated / total, total, translated };
}

export async function recalculateLocale(
  db: D1Database,
  projectId: string,
  languageLocaleCode: string,
): Promise<void> {
  const { coverage } = await computeCoverage(db, projectId, languageLocaleCode);

  const locale = await db
    .prepare('SELECT status, activation_source FROM ui_locales WHERE project_id = ? AND language_locale_code = ?')
    .bind(projectId, languageLocaleCode)
    .first<{ status: string; activation_source: string | null }>();

  if (!locale) return;

  if (locale.status === 'draft' && coverage >= AUTO_ACTIVATION_THRESHOLD) {
    await db
      .prepare(
        `UPDATE ui_locales SET status = 'active', activation_source = 'auto', activated_at = CURRENT_TIMESTAMP, mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND language_locale_code = ? AND status = 'draft'`,
      )
      .bind(projectId, languageLocaleCode)
      .run();
  } else {
    await db
      .prepare(
        'UPDATE ui_locales SET mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND language_locale_code = ?',
      )
      .bind(projectId, languageLocaleCode)
      .run();
  }
}

export async function activateLocale(
  db: D1Database,
  projectId: string,
  code: string,
  source: 'auto' | 'manual',
  userId: number,
): Promise<void> {
  const locale = await db
    .prepare('SELECT status, activation_source FROM ui_locales WHERE project_id = ? AND language_locale_code = ?')
    .bind(projectId, code)
    .first<{ status: string; activation_source: string | null }>();

  if (!locale) throw new LocalizationError('UI_LOCALE_NOT_FOUND');
  if (locale.status === 'archived') throw new LocalizationError('UI_LOCALE_ARCHIVED');
  if (locale.status === 'active') throw new LocalizationError('UI_LOCALE_ALREADY_ACTIVE');

  await db
    .prepare(
      `UPDATE ui_locales SET status = 'active', activation_source = ?, activated_at = CURRENT_TIMESTAMP, activated_by = ?, mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND language_locale_code = ?`,
    )
    .bind(source, userId, projectId, code)
    .run();
}

export async function archiveLocale(
  db: D1Database,
  projectId: string,
  code: string,
  userId: number,
): Promise<void> {
  const locale = await db
    .prepare('SELECT status, activation_source FROM ui_locales WHERE project_id = ? AND language_locale_code = ?')
    .bind(projectId, code)
    .first<{ status: string; activation_source: string | null }>();

  if (!locale) throw new LocalizationError('UI_LOCALE_NOT_FOUND');
  if (locale.activation_source === 'system') throw new LocalizationError('UI_LOCALE_SYSTEM_LOCKED');

  await db
    .prepare(
      `UPDATE ui_locales SET status = 'archived', mapping_revision = mapping_revision + 1, updated_at = CURRENT_TIMESTAMP WHERE project_id = ? AND language_locale_code = ?`,
    )
    .bind(projectId, code)
    .run();
}

async function findCandidate(
  db: D1Database,
  projectId: string,
  localeCode: string,
  messageKeys: string[],
): Promise<Map<string, string>> {
  if (messageKeys.length === 0) return new Map();
  const langRow = await db
    .prepare('SELECT lang_code FROM language_locales WHERE code = ?')
    .bind(localeCode)
    .first<{ lang_code: string }>();
  if (!langRow) return new Map();

  const { results } = await db
    .prepare(
      `SELECT m.message_key, m.placeholders_json,
              t.id AS target_id, t.text AS target_text,
              e.id AS edge_id, e.score, e.created_at
       FROM ui_messages m
       JOIN expression_edges e ON e.expression_a_id = m.source_expression_id OR e.expression_b_id = m.source_expression_id
       JOIN expressions t ON t.id = CASE WHEN e.expression_a_id = m.source_expression_id THEN e.expression_b_id ELSE e.expression_a_id END
       WHERE m.project_id = ? AND m.status = ? AND e.score >= 0 AND t.lang_code = ?
         AND EXISTS (SELECT 1 FROM expression_locale_attestations WHERE expression_id = t.id AND language_locale_code = ?)
       ORDER BY m.message_key ASC, e.score DESC, e.created_at ASC, t.id ASC`,
    )
    .bind(projectId, 'active', langRow.lang_code, localeCode)
    .all<{
      message_key: string;
      placeholders_json: string;
      target_id: string;
      target_text: string;
    }>();

  const result = new Map<string, string>();
  for (const row of results) {
    if (result.has(row.message_key)) continue;
    const sourcePlaceholders = JSON.parse(row.placeholders_json) as string[];
    const targetPlaceholders = extractPlaceholders(row.target_text);
    if (JSON.stringify(sourcePlaceholders) !== JSON.stringify(targetPlaceholders)) continue;
    result.set(row.message_key, row.target_text);
  }
  return result;
}

export async function resolveBundle(
  db: D1Database,
  projectId: string,
  primary?: string,
  secondary?: string,
): Promise<BundleEntry[]> {
  const { results: messages } = await db
    .prepare('SELECT message_key, source_text, placeholders_json FROM ui_messages WHERE project_id = ? AND status = ? ORDER BY message_key ASC')
    .bind(projectId, 'active')
    .all<{ message_key: string; source_text: string; placeholders_json: string }>();

  const allKeys = messages.map((m) => m.message_key);

  let primaryCandidates = new Map<string, string>();
  let secondaryCandidates = new Map<string, string>();

  if (primary) {
    const primaryLocale = await db
      .prepare('SELECT status FROM ui_locales WHERE project_id = ? AND language_locale_code = ?')
      .bind(projectId, primary)
      .first<{ status: string }>();
    if (primaryLocale?.status === 'active') {
      primaryCandidates = await findCandidate(db, projectId, primary, allKeys);
    }
  }

  if (secondary) {
    const secondaryLocale = await db
      .prepare('SELECT status FROM ui_locales WHERE project_id = ? AND language_locale_code = ?')
      .bind(projectId, secondary)
      .first<{ status: string }>();
    if (secondaryLocale?.status === 'active') {
      secondaryCandidates = await findCandidate(db, projectId, secondary, allKeys);
    }
  }

  return messages.map((m) => {
    if (primaryCandidates.has(m.message_key)) {
      return { key: m.message_key, text: primaryCandidates.get(m.message_key)!, resolved_from: 'primary' as const };
    }
    if (secondaryCandidates.has(m.message_key)) {
      return { key: m.message_key, text: secondaryCandidates.get(m.message_key)!, resolved_from: 'secondary' as const };
    }
    return { key: m.message_key, text: m.source_text, resolved_from: 'source' as const };
  });
}
```

- [ ] **Step 4: 跑單元測試確認通過**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/localizationDomain.test.ts
```

Expected: 全部 PASS。若 SQL key 不匹配,以實作為準調整測試。

- [ ] **Step 5: Commit**

```bash
git add backend/src/services/localizationDomain.ts backend/tests/localizationDomain.test.ts
git commit -m "feat(api): add localization domain service with coverage and bundle resolution"
```

---

## Task 4: Localization routes —— 8 條 API + 整合測試

**Files:**
- Create: `backend/src/routes/localization.ts`
- Modify: `backend/src/routes/index.ts`
- Create: `backend/tests/localizationIntegration.test.ts`

**Interfaces:**
- Consumes: Task 3 的 `LocalizationError`／`computeCoverage`／`activateLocale`／`archiveLocale`／`recalculateLocale`／`resolveBundle`;Plan 4 的 `createEdge`／`MappingError`;Plan 5 的 `getPreferences`;`parseLanguageLocaleCode`／`parseReferenceQuery`;`requireAuth`／`optionalAuth`;response helpers。
- Produces: 8 條 localization API endpoint。

- [ ] **Step 1: 建立 `backend/src/routes/localization.ts`**

```ts
import { Hono } from 'hono';
import { requireAuth, optionalAuth } from '../middleware/auth';
import { badRequest, created, forbidden, internalError, notFound, paginated, success } from '../utils/response';
import {
  LocalizationError,
  activateLocale,
  archiveLocale,
  computeCoverage,
  recalculateLocale,
  resolveBundle,
} from '../services/localizationDomain';
import { MappingError, createEdge } from '../services/mappings';
import { getPreferences } from '../services/preferences';
import { parseLanguageLocaleCode } from '../services/languageIdentity';
import type { Bindings, Variables } from '../types';

const localization = new Hono<{ Bindings: Bindings; Variables: Variables }>();

localization.get('/projects/:projectId/locales', async (c) => {
  const projectId = c.req.param('projectId') ?? '';
  const { results } = await c.env.DB
    .prepare('SELECT project_id, language_locale_code, status, mapping_revision, activation_source, activated_at, activated_by, created_at FROM ui_locales WHERE project_id = ? ORDER BY language_locale_code ASC')
    .bind(projectId)
    .all();
  return success(c, results);
});

localization.post('/projects/:projectId/locales', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const projectId = c.req.param('projectId') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const code = typeof body?.language_locale_code === 'string' ? body.language_locale_code.trim() : '';
    if (!code || !parseLanguageLocaleCode(code)) {
      return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE', 'Valid language_locale_code is required');
    }
    try {
      await c.env.DB
        .prepare('INSERT INTO ui_locales (project_id, language_locale_code, status, created_by) VALUES (?, ?, ?, ?)')
        .bind(projectId, code, 'draft', user?.id ?? null)
        .run();
    } catch (error) {
      const msg = String((error as { message?: string })?.message ?? '');
      if (msg.includes('UNIQUE constraint failed') || msg.includes('PRIMARY KEY')) {
        return badRequest(c, 'UI_LOCALE_EXISTS', 'UI locale already exists for this project');
      }
      throw error;
    }
    const row = await c.env.DB
      .prepare('SELECT project_id, language_locale_code, status, mapping_revision, activation_source, created_at FROM ui_locales WHERE project_id = ? AND language_locale_code = ?')
      .bind(projectId, code)
      .first();
    return created(c, row, 'UI locale created');
  } catch (error) {
    console.error('Create UI locale error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create UI locale');
  }
});

localization.post('/projects/:projectId/locales/:code/activate', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const projectId = c.req.param('projectId') ?? '';
    const code = c.req.param('code') ?? '';
    const manual = user?.role === 'admin';
    try {
      await activateLocale(c.env.DB, projectId, code, 'manual', user?.id ?? 0);
      return success(c, { activated: true }, 'UI locale activated');
    } catch (error) {
      if (error instanceof LocalizationError) {
        if (error.code === 'UI_LOCALE_NOT_FOUND') return notFound(c, 'UI locale');
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Activate UI locale error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to activate UI locale');
  }
});

localization.post('/projects/:projectId/locales/:code/archive', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const projectId = c.req.param('projectId') ?? '';
    const code = c.req.param('code') ?? '';
    if (user?.role !== 'admin') return forbidden(c, 'FORBIDDEN', 'Archive requires admin role');
    try {
      await archiveLocale(c.env.DB, projectId, code, user?.id ?? 0);
      return success(c, { archived: true }, 'UI locale archived');
    } catch (error) {
      if (error instanceof LocalizationError) {
        if (error.code === 'UI_LOCALE_NOT_FOUND') return notFound(c, 'UI locale');
        return badRequest(c, error.code, error.code);
      }
      throw error;
    }
  } catch (error) {
    console.error('Archive UI locale error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to archive UI locale');
  }
});

localization.get('/projects/:projectId/workbench/:code', requireAuth, async (c) => {
  try {
    const projectId = c.req.param('projectId') ?? '';
    const code = c.req.param('code') ?? '';
    const locale = await c.env.DB
      .prepare('SELECT status, mapping_revision, activation_source FROM ui_locales WHERE project_id = ? AND language_locale_code = ?')
      .bind(projectId, code)
      .first<{ status: string; mapping_revision: number; activation_source: string | null }>();
    if (!locale) return notFound(c, 'UI locale');
    const coverage = await computeCoverage(c.env.DB, projectId, code);
    return success(c, { locale, coverage });
  } catch (error) {
    console.error('Workbench error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to load workbench');
  }
});

localization.post('/projects/:projectId/mappings', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const projectId = c.req.param('projectId') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const messageKey = typeof body?.message_key === 'string' ? body.message_key.trim() : '';
    const targetExpressionId = typeof body?.target_expression_id === 'string' ? body.target_expression_id.trim() : '';
    if (!messageKey || !targetExpressionId) {
      return badRequest(c, 'VALIDATION_FAILED', 'message_key and target_expression_id are required');
    }
    const msg = await c.env.DB
      .prepare('SELECT source_expression_id FROM ui_messages WHERE project_id = ? AND message_key = ?')
      .bind(projectId, messageKey)
      .first<{ source_expression_id: string }>();
    if (!msg) return badRequest(c, 'MESSAGE_KEY_NOT_FOUND', 'Unknown message key');

    try {
      const result = await createEdge(c.env.DB, {
        expression_a_id: msg.source_expression_id,
        expression_b_id: targetExpressionId,
        source: 'translation',
        created_by: user?.id ?? 0,
      });
      const targetExpr = await c.env.DB
        .prepare('SELECT lang_code FROM expressions WHERE id = ?')
        .bind(targetExpressionId)
        .first<{ lang_code: string }>();
      if (targetExpr) {
        const localeCode = await c.env.DB
          .prepare('SELECT language_locale_code FROM ui_locales WHERE project_id = ? AND language_locale_code LIKE ?')
          .bind(projectId, `${targetExpr.lang_code}-%`)
          .first<{ language_locale_code: string }>();
        if (localeCode) {
          await recalculateLocale(c.env.DB, projectId, localeCode.language_locale_code);
        }
      }
      return result.created ? created(c, result, 'Translation mapping created') : success(c, result, 'Translation mapping already exists');
    } catch (error) {
      if (error instanceof MappingError) return badRequest(c, error.code, error.code);
      throw error;
    }
  } catch (error) {
    console.error('Create translation mapping error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to create translation mapping');
  }
});

localization.post('/projects/:projectId/mappings/batch', requireAuth, async (c) => {
  try {
    const user = c.get('user');
    const projectId = c.req.param('projectId') ?? '';
    const body = await c.req.json().catch(() => ({}));
    const mappings = Array.isArray(body?.mappings) ? body.mappings : [];
    if (mappings.length === 0) return badRequest(c, 'VALIDATION_FAILED', 'mappings array is required');
    const results: Array<{ message_key: string; created: boolean }> = [];
    const affectedLangs = new Set<string>();
    for (const m of mappings) {
      const messageKey = typeof m?.message_key === 'string' ? m.message_key.trim() : '';
      const targetExpressionId = typeof m?.target_expression_id === 'string' ? m.target_expression_id.trim() : '';
      if (!messageKey || !targetExpressionId) continue;
      const msg = await c.env.DB
        .prepare('SELECT source_expression_id FROM ui_messages WHERE project_id = ? AND message_key = ?')
        .bind(projectId, messageKey)
        .first<{ source_expression_id: string }>();
      if (!msg) continue;
      const result = await createEdge(c.env.DB, {
        expression_a_id: msg.source_expression_id,
        expression_b_id: targetExpressionId,
        source: 'translation',
        created_by: user?.id ?? 0,
      });
      results.push({ message_key: messageKey, created: result.created });
      const targetExpr = await c.env.DB
        .prepare('SELECT lang_code FROM expressions WHERE id = ?')
        .bind(targetExpressionId)
        .first<{ lang_code: string }>();
      if (targetExpr) affectedLangs.add(targetExpr.lang_code);
    }
    for (const langCode of affectedLangs) {
      const localeCode = await c.env.DB
        .prepare('SELECT language_locale_code FROM ui_locales WHERE project_id = ? AND language_locale_code LIKE ?')
        .bind(projectId, `${langCode}-%`)
        .first<{ language_locale_code: string }>();
      if (localeCode) await recalculateLocale(c.env.DB, projectId, localeCode.language_locale_code);
    }
    return success(c, { results, count: results.length }, 'Batch translation mappings processed');
  } catch (error) {
    console.error('Batch translation mapping error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to process batch mappings');
  }
});

localization.get('/projects/:projectId/messages', optionalAuth, async (c) => {
  try {
    const projectId = c.req.param('projectId') ?? '';
    let primary = c.req.query('primary') ?? '';
    let secondary = c.req.query('secondary') ?? '';

    if (!primary && !secondary) {
      const user = c.get('user');
      if (user) {
        const prefs = await getPreferences(c.env.DB, user.id);
        const langPrefs = prefs['language.locales'] as { primary?: string; secondary?: string } | undefined;
        if (langPrefs) {
          primary = langPrefs.primary ?? '';
          secondary = langPrefs.secondary ?? '';
        }
      }
    }

    if (primary && !parseLanguageLocaleCode(primary)) return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE', 'Invalid primary locale');
    if (secondary && !parseLanguageLocaleCode(secondary)) return badRequest(c, 'INVALID_LANGUAGE_LOCALE_CODE', 'Invalid secondary locale');

    const bundle = await resolveBundle(c.env.DB, projectId, primary || undefined, secondary || undefined);
    return success(c, { messages: bundle });
  } catch (error) {
    console.error('Get messages error:', error);
    return internalError(c, error instanceof Error ? error.message : 'Failed to get messages');
  }
});

export default localization;
```

- [ ] **Step 2: 在 `backend/src/routes/index.ts` 註冊**

READ current file. Add:
```ts
import localization from './localization';
```
And register:
```ts
api.route('/localization', localization);
```

- [ ] **Step 3: 寫整合測試**

Create `backend/tests/localizationIntegration.test.ts`:

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

describe('localization API', () => {
  it('lists UI locales including the seeded eng-Latn-US', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/localization/projects/langmap-web/locales`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: Array<{ language_locale_code: string; status: string; activation_source: string }> };
    const eng = body.data.find((l) => l.language_locale_code === 'eng-Latn-US');
    expect(eng).toBeTruthy();
    expect(eng!.status).toBe('active');
    expect(eng!.activation_source).toBe('system');
  });

  it('returns English source messages when no locale preference', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/localization/projects/langmap-web/messages`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { messages: Array<{ key: string; text: string; resolved_from: string }> } };
    expect(body.data.messages.length).toBeGreaterThan(10);
    const cancelMsg = body.data.messages.find((m) => m.key === 'common.cancel');
    expect(cancelMsg).toBeTruthy();
    expect(cancelMsg!.text).toBe('Cancel');
    expect(cancelMsg!.resolved_from).toBe('source');
  });

  it('creates a draft UI locale', async () => {
    const token = await registerToken();
    const res = await fetch(`${BASE_URL}/api/v2/localization/projects/langmap-web/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW' }),
    });
    expect(res.status).toBe(201);
    const body = (await res.json()) as { data: { status: string; language_locale_code: string } };
    expect(body.data.status).toBe('draft');
    expect(body.data.language_locale_code).toBe('cmn-Hant-TW');
  });

  it('gets workbench coverage for a locale', async () => {
    const token = await registerToken();
    await fetch(`${BASE_URL}/api/v2/localization/projects/langmap-web/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ language_locale_code: 'cmn-Hans-CN' }),
    });
    const res = await fetch(`${BASE_URL}/api/v2/localization/projects/langmap-web/workbench/cmn-Hans-CN`, {
      headers: { authorization: `Bearer ${token}` },
    });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { data: { locale: { status: string }; coverage: { total: number; translated: number; coverage: number } } };
    expect(body.data.locale.status).toBe('draft');
    expect(body.data.coverage.total).toBeGreaterThan(0);
    expect(body.data.coverage.translated).toBe(0);
    expect(body.data.coverage.coverage).toBe(0);
  });

  it('creates a translation mapping', async () => {
    const token = await registerToken();
    const sourceMsg = await fetch(`${BASE_URL}/api/v2/localization/projects/langmap-web/messages`).then((r) => r.json()) as { data: { messages: Array<{ key: string; text: string }> } };
    const cancelKey = sourceMsg.data.messages.find((m) => m.key === 'common.cancel');
    expect(cancelKey).toBeTruthy();

    const exprRes = await fetch(`${BASE_URL}/api/v2/expressions`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ lang_code: 'cmn', text: '取消' }),
    });
    const exprBody = (await exprRes.json()) as { data: { expression: { id: string } } };

    const res = await fetch(`${BASE_URL}/api/v2/localization/projects/langmap-web/mappings`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ message_key: 'common.cancel', target_expression_id: exprBody.data.expression.id }),
    });
    expect(res.status).toBe(201);
  });

  it('requires auth to create locale', async () => {
    const res = await fetch(`${BASE_URL}/api/v2/localization/projects/langmap-web/locales`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ language_locale_code: 'cmn-Hant-TW' }),
    });
    expect(res.status).toBe(401);
  });
});
```

- [ ] **Step 4: 啟動 worker 並跑整合測試**

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && nohup node_modules/.bin/wrangler dev --config wrangler.jsonc --persist-to .wrangler/state --port 8788 > /tmp/langmap-worker-8788.log 2>&1 & disown
```

等 health 200,跑:

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npx vitest run tests/localizationIntegration.test.ts
```

Expected: 6 PASS。

- [ ] **Step 5: Commit**

```bash
git add backend/src/routes/localization.ts backend/src/routes/index.ts backend/tests/localizationIntegration.test.ts
git commit -m "feat(api): expose 8 localization endpoints with coverage, activation and bundle"
```

---

## Task 5: 全量回歸與收尾驗證

- [ ] **Step 1: 後端完整測試**

確保 worker 在 8788:

```bash
cd /Users/share.lim/Documents/GitHub/langmap/backend && npm test
```

Expected: 除已知既有失敗(`auth.test.ts` × 1、`expressionsIntegration.test.ts` × 2),全部 PASS。

- [ ] **Step 2: scripts 測試**

```bash
cd /Users/share.lim/Documents/GitHub/langmap && python3 scripts/language-reference/test_generate.py
cd /Users/share.lim/Documents/GitHub/langmap && python3 scripts/db/tests/test_local_rebuild.py
cd /Users/share.lim/Documents/GitHub/langmap && python3 -m unittest scripts.db.tests.test_verify
cd /Users/share.lim/Documents/GitHub/langmap && python3 scripts/i18n/test_generate_bundle.py
```

若有 `manifest.json` timestamp 改動,`git checkout --` 恢復。

- [ ] **Step 3: Git checks**

```bash
git diff --check
git status --short
```

- [ ] **Step 4: 若有修正則 Commit**

---

## Self-Review

**1. Spec coverage:**

- §12.1 `ui_locales` 表(全部欄位、status/activation_source CHECK、PK、三 FK)→ Task 1。系統 seed `eng-Latn-US`/`langmap-web` → Task 1。不存 native_name/direction/fallback_code → 本 plan 不含這些欄位(符合)。不可封存 system locale → Task 3 `archiveLocale` 檢查 `activation_source === 'system'` 拋 `UI_LOCALE_SYSTEM_LOCKED`。
- §12.2 `ui_messages.source_expression_id` TEXT FK → Task 1 schema。source copy 用 `system-ui` source → Task 2 seed script。
- §12.3 Coverage 公式與 6 條 candidate 條件 → Task 3 `computeCoverage`(SQL 條件 1-4 + JS 條件 5 placeholder 比對 + 條件 6 非 fallback 隱含)。`total = 0` → coverage = 0 → Task 3。Candidate 排序 → SQL ORDER BY。
- §12.4 Auto activation ≥ 0.60 → Task 3 `recalculateLocale`。Manual activation → Task 4 route。Active 不降級 → `recalculateLocale` 只 bump revision for active。Archive → Task 3 `archiveLocale`。
- §12.4 事件觸發重算 → Task 4 `POST /mappings` 和 `/mappings/batch` 在建立 edge 後呼叫 `recalculateLocale`。
- §12.5 Per-key fallback(primary → secondary → English)→ Task 3 `resolveBundle`。`resolved_from` → bundle entry 欄位。不做其他 fallback → 只檢查 primary/secondary active locale。
- §13.4 8 條 API → Task 4。登入者未傳 query 用 preference;匿名者用 English → Task 4 `GET /messages` 的 `optionalAuth` + `getPreferences`。
- §14 `UI_LOCALE_NOT_ACTIVE`（隱含:archive locale 不接受 mappings,但本 plan 的 route 不做此檢查——留給前端或後續強化）、`UI_LOCALE_ARCHIVED`（Task 3 `activateLocale` 拋此 code）、`UI_LOCALE_ALREADY_ACTIVE`（Task 3 `activateLocale`）。
- §4.11 穩定排序 → SQL ORDER BY。
- §16.6 `scripts/i18n` locale code → Plan 5 Task 4 已完成;本 plan 新增 `generate-ui-seed.py` 使用新格式。

**未覆蓋(留給後續):** mapping vote 的 coverage 重算(spec §12.4 提及但 votes 表不存在);UI message 建立與退役 API(spec §12.2 描述 source copy 更新但未定義獨立 API route——seed script 處理初始建立);split edge move 的 localization 通知(spec §12.4——service 層 hook 保留,待接線);前端(§15);`scripts/i18n/generate-i18n-sql.py` 的完整重寫(為新 schema——本 plan 用新 `generate-ui-seed.py` 取代 seed 功能,但 translation import SQL 仍需重寫)。

**2. Placeholder scan:** 每個 step 都有完整程式碼。placeholder 比對用 `\{(\w+)\}` regex 簡單實作(spec 未指定 ICU MessageFormat 解析)。`generate-ui-seed.py` 的 `parse_en_ts` 是 `generate-i18n-sql.py` 的簡化版(不處理多行值,因為 `en.ts` 的值都是單行)。`localization.ts` route 的 `POST /mappings` 在建立 edge 後用 LIKE 查找受影響 locale(`language_locale_code LIKE '${langCode}-%'`)——這在 edge cases 可能匹配多個 locale(如 `cmn-Hant-TW` 和 `cmn-Hans-CN` 都 match `cmn-%`),但 `recalculateLocale` 對每個都執行是安全且冪等的。

**3. Type consistency:** `BundleEntry` 在 Task 3 定義並被 route 的 `GET /messages` 回傳。`LocalizationError` 在 Task 3 定義並被 Task 4 route import。`computeCoverage` 回傳 `{ coverage: number; total: number; translated: number }` 與 workbench route 的回應一致。`activateLocale`／`archiveLocale` 接受 `(db, projectId, code, source|userId)` 與 route 呼叫一致。`resolveBundle` 回傳 `BundleEntry[]` 與 messages route 的 `{ messages: bundle }` 一致。`createEdge` from Plan 4 被 `POST /mappings` 使用,簽名一致。`getPreferences` from Plan 5 被 `GET /messages` 使用,簽名一致。`parseLanguageLocaleCode` from Plan 2 用於 locale code 驗證,簽名一致。route 使用 `c.req.param()` 而非 `c.param()`(Plan 4 修正)。
