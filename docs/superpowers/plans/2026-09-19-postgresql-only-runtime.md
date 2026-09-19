# PostgreSQL-only Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓 LangMap Web/API 與本機開發完全以 PostgreSQL 運作，移除 D1、SQLite 與其過時 scripts 文件。

**Architecture:** Worker 只經 Hyperdrive 使用 PostgreSQL；後端依賴本地 `Database` contract，而不依賴 Cloudflare D1 型別。新 PostgreSQL baseline 與 migration runner 服務新環境；舊 D1 schema、migration 與操作流程隨相依 scripts 一起退役。

**Tech Stack:** Vue/Vite、Hono、Cloudflare Workers、Hyperdrive、PostgreSQL、TypeScript、Vitest、Python（僅 PG 管理工具）。

**Spec:** `docs/superpowers/specs/2026-09-19-postgresql-csv-dictionary-design.md`

## Global Constraints

- PostgreSQL 已是正式資料基線；不搬遷、不回填、不建立 dual-write。
- macOS 文件以 Homebrew PostgreSQL 為本機選項；程式不依賴 Homebrew 或 `psql`。
- 保留使用者既有未提交變更；刪除前需完成 scripts keep/move/delete inventory。
- 歷史 ADR、已完成 spec/plan 可保留歷史敘述；現行入口與 runbook 不得指向 D1/SQLite。

---

### Task 1: 建立 runtime database contract 與 PG query 基線

**Files:**
- Modify: `backend/src/db/pgDatabase.ts`, `backend/src/index.tsx`, `backend/src/types.ts`
- Modify: `backend/src/services/**/*.ts`, `backend/src/routes/**/*.ts`, `backend/tests/**/*.test.ts`
- Create: `backend/src/db/database.ts`, `backend/tests/pgDatabase.test.ts`

**Produces:** `Database`、`PreparedStatement` 與 `BatchStatement` 本地型別；Worker 注入 PG handle，所有服務不再 import `D1Database`。

- [ ] **Step 1: 以型別測試定義最小 contract**

```ts
export interface Database { prepare(sql: string): PreparedStatement; batch(items: BatchStatement[]): Promise<unknown[]> }
```

- [ ] **Step 2: 改造 PG adapter 與注入邊界**

移除 D1-shaped 註釋與 cast；將 routes/services/tests 改用 `Database`，並保留 request-scoped PG client lifecycle。

- [ ] **Step 3: 將 SQLite 方言依賴逐項改成 PG SQL**

以 `rg` 列出 `INSERT OR IGNORE`、`COLLATE NOCASE`、`json_*`、`CURRENT_TIMESTAMP` 等用法；每種先加 adapter/integration test，再改 query。所有使用點移除後刪除 regex SQL translator。

- [ ] **Step 4: 驗證與提交**

Run: `cd backend && npm test -- --run pgDatabase`

Run: `cd backend && npm run types:check`

Commit: `refactor(backend): remove D1 database contract`

### Task 2: 建立 PostgreSQL baseline、migration 與 integration harness

**Files:**
- Create: `backend/postgres/schema.sql`, `backend/postgres/migrations/`, `scripts/postgres/manage.py`, `scripts/postgres/README.md`
- Modify: `backend/package.json`, `backend/tests/vitest.config.ts`（若實際路徑為 `backend/vitest.config.ts`，使用既有檔）
- Delete: `backend/schema.sql`, `backend/migrations/`（Task 4 完成後）

**Produces:** 可由空 PostgreSQL database 建立的 baseline、只接受新 PG migration 的 runner、測試用獨立 database lifecycle。

- [ ] **Step 1: 從已遷移 PG schema 取得 canonical baseline**

不要串接 SQLite migration。以 schema-only dump 或受控 introspection 建立 `backend/postgres/schema.sql`，並在空 database 套用後比對 tables、constraints、indexes、extensions 與 application query contract。

- [ ] **Step 2: 寫入 migration runner 與 metadata table**

Runner 以 `DATABASE_URL` 和檔案 checksum 記錄 PG migration；同一 migration checksum 改變即失敗，transactional migration 在失敗時 rollback。

- [ ] **Step 3: 將 integration tests 指向隔離 PG database**

每個 suite 使用明確 test URL/database，套用 baseline，並驗證 unique violation、batch rollback、JSON annotation、case-insensitive search 與 API read/write。

- [ ] **Step 4: 驗證與提交**

Run: `cd backend && npm test`

Commit: `feat(backend): add PostgreSQL schema baseline`

### Task 3: 改造開發、部署與現行文件入口

**Files:**
- Modify: `backend/wrangler.jsonc`, `backend/package.json`, `dev.sh`, `README.md`, `docs/runbooks/dev-database.md`, `docs/runbooks/database-migrations.md`, `docs/design/system/architecture.md`
- Delete: `docs/runbooks/d1-time-travel-restore.md`

**Produces:** Hyperdrive-only Worker config、`DATABASE_URL` 本機入口、可操作的 PG migration/development runbook。

- [ ] **Step 1: 移除 D1 binding 與 D1 package commands**

保留 Hyperdrive、R2、assets、AI；刪除 `d1_databases`、`wrangler d1` scripts 與 D1-only secret/documentation。

- [ ] **Step 2: 簡化 `dev.sh`**

刪除 rebuild、Miniflare D1 state、D1 migration 與 state discovery；在啟動前檢查 `DATABASE_URL`，並以短錯誤訊息指向本機 PG 文件。

- [ ] **Step 3: 更新現行操作文件**

寫明 Homebrew 安裝/啟動/建立 database 範例、`DATABASE_URL`、baseline/migration 指令、備份與 PITR 責任。不得宣稱 D1 restore 可用。

- [ ] **Step 4: 驗證與提交**

Run: `./dev.sh --no-rebuild`（改造後不再接受或需要 rebuild flag）

Run: `git diff --check`

Commit: `docs: document PostgreSQL development workflow`

### Task 4: 完成 scripts 全量 inventory 並移除過時檔案

**Files:**
- Create: `docs/runbooks/scripts-inventory.md`
- Delete/Move: `scripts/db/` D1-only files、`scripts/dictionary/` JSONL/SQLite/D1-only files、相應 tests/fixtures/state/docs
- Modify: `scripts/i18n/`, `scripts/language-reference/`, `scripts/morphology/`, `scripts/wikivoyage/` 的現行入口或 README（只限仍有產品責任者）

**Produces:** 可稽核的 keep/move/delete 表，且 repository 不再有執行期或現行操作鏈路依賴 D1/SQLite。

- [ ] **Step 1: 建立 inventory，再刪除**

對每個 `scripts/` 頂層目錄列出 owner、current consumer、decision、replacement。無 consumer 的 README、state、backup、fixture、test、wrapper 與 module 同組刪除。

- [ ] **Step 2: 先搬移仍必要的通用工具**

仍需 PG registry seed/maintenance 的工具改放 `scripts/postgres/` 或功能目錄；更新 import 與 invocation，確認不再引用 `scripts/db`。

- [ ] **Step 3: 刪除 D1/SQLite 所有流程與死引用**

移除 D1 releases/deltas/mirror/local rebuild、SQLite staging、Miniflare fixtures、過時 runbooks。Wikivoyage 只能改成 CSV output 或整組退役。

- [ ] **Step 4: 驗證與提交**

Run: `rg -n -i 'wrangler d1|d1_databases|sqlite3|\.wrangler/state' README.md dev.sh backend scripts docs/runbooks`

Expected: 僅歷史文件或明確排除項；現行入口為零。

Commit: `chore: remove D1 and SQLite scripts`

### Task 5: 端到端切換驗收

**Files:**
- Modify: `README.md`, `docs/runbooks/dev-database.md`

- [ ] **Step 1: 以乾淨 PG database 走完 baseline、migration、API 啟動**
- [ ] **Step 2: 執行 backend full suite 與 `./build.sh`**
- [ ] **Step 3: 以 smoke API 驗證 expression、mapping、locale registry、readings、handbook**
- [ ] **Step 4: 記錄 PG backup/restore 演練證據與剩餘風險**
- [ ] **Step 5: Commit**

```bash
git commit -m "chore: complete PostgreSQL-only cutover"
```
