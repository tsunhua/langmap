# Canonical 字典逐部線上發布 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended)
> or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 把以 canonical D1（0039+ integer storage）逐部匯入的詞典，以受管 apply 安全發布到 production `langmap-v2`，逐部可驗證、可回退。

**Architecture:** 本地 D1 以「遠程匯出資料」為基底重建，使 expression 整數 ID 空間與 production 一致；每部詞典經
`import_with_progress.py` 合併進 local，再由 per-source delta 匯出器產生明確 ID 的 `INSERT OR IGNORE` SQL，
透過 `scripts/db` 的 plan/apply gate 套用。不做 `__pycache__` 手動編輯、不走直接 `wrangler d1 execute --remote` 當發布手段。

## 背景事實（已驗證）

- production `langmap-v2`：expression 10,807（base，MAX(id) 11,263）、`language_locales` 19、`sources` 2（皆 system）、publication sources = 0。
- local D1（generator seed 基底）：`language_locales` 34、base expression 10,857（與 production 差異 333/383 組 identity）、MAX(id) 371,948。
- 兩邊 base 不一致 ⇒ 不能直接搬 local 既有資料；必須以遠程為基底重放，ID 才能對齊。
- migration `0039_canonical_integer_storage` 已移除 release／claim／packed 表；現行 canonical 用 `expression_sources`／
  `expression_edge_sources`（0042）保留來源標記。故 runbook 的 `--dictionary-artifact-manifest` 發布線在現行 schema 下已失效。
- `production.py` 的 apply 已有 `approved_data_migration` 執行邏輯（`d1 execute --remote --file`），只缺 plan 帶入參數。

## 非目標

- 不恢復 release／binding／evidence 模型；不把詞典 bundle 進 migration。
- 不做跨檔案 AI 高信心合併；本次只發布「同源逐部」匯入結果（與 README 增量模式一致）。
- 不修改已發布 migration；不改 remote baseline 以外的 production schema。
- 不動 `apple/`；不更動前端 display 語系邏輯。

## 發布機制

1. **基底對齊**：把 `scripts/db/state/backup/remote-2026-08-29.sql`（`wrangler d1 export --remote`）灌進本地 fresh D1，
   local == remote（ID 完全一致）。
2. **逐部導入**：`import_with_progress.py --only <frag>` 在 local 合併；sha state 續跑。
3. **delta 匯出**：新工具 `scripts/db/export_dictionary_delta.py`——以「導入前 local 快照.sqlite → 導入後 local.sqlite」逐表差集，
   僅輸出該部新增 rows（明確整數 ID、`INSERT OR IGNORE`），並依 FK 排序：`sources → language_locales → expressions →
   expression_sources → expression_locale_links → expression_readings → expression_edges → expression_edge_sources`。
   空值欄位用 `NULL`；所有值以 SQL literal 轉義；支援 partition 語句數（預設 5,000）避免單檔過大。
4. **受管 apply**：`manage.sh production plan --approved-data-migration <relative.sql>` 把檔案寫入 plan；
   `production apply`（既有 bookmark→migrate→data→reference→verify 順序）執行該檔並 post-apply 驗證。
5. **verify**：production inventory 對照 local 的 publication source counts（expressions/edges/sources/locales）一致。

## Task 1: production plan 支援 approved data migration

**Files:**
- Modify: `scripts/db/manage.py`（`plan` 加 `--approved-data-migration`）
- Modify: `scripts/db/lib/production.py`（`plan_production` 接受並記錄 relative path + sha256；apply 端已有執行故只補 plan 端與文件化）
- Test: `scripts/db/tests/test_manage.py`
- Test: `scripts/db/tests/test_production_inventory.py`

- [ ] **Step 1**: 寫失敗測試——`production plan --approved-data-migration X.sql` 產出 plan 含
      `approved_data_migration`（repo-relative）、`migration_checksums` 之外的 sha256；拒絕絕對路徑／`..` 逃逸／不存在。
- [ ] **Step 2**: 實作 `plan_production(..., approved_data_migration=None)`；`_resolve_managed_artifact` 已存在（repo 內 + is_file），
      補 sha256 與 plan JSON 欄位；manage CLI 把 arg 傳入。
- [ ] **Step 3**: 跑 `python3 -m pytest scripts/db/tests -q`；預期 PASS。

## Task 2: delta 匯出工具

**Files:**
- Create: `scripts/db/export_dictionary_delta.py`
- Create: `scripts/db/tests/test_export_dictionary_delta.py`
- Create: `scripts/db/state/backup/README.md`（標記 backup 是 gitignored 操作暫存）

- [ ] **Step 1**: 寫失敗測試——合成前後兩份小型 sqlite（相同 remote base + 注入幾列），斷言 delta 只含新增、
      排序正確、`NULL` 正確、字串/數字/浮點 literal 正確、FK 依賴先行。
- [ ] **Step 2**: 實作：先 dump 前後各表 rows（依 PK），差集照 FK 順序輸出；使用 `INSERT OR IGNORE INTO ... VALUES (...)`，
      chunk 切割；`--limit` 供測試。
- [ ] **Step 3**: 跑 `python3 -m unittest discover -s scripts/db/tests -p 'test_*.py'`。

## Task 3: 基底重建 local（operator 授權後）

- [ ] **Step 1**: 複製一份 remote export 供 fresh local 用；以 `wrangler d1 export` 的快照建立 fresh D1 檔（含 migration 表與資料）。
- [ ] **Step 2**: 比對 local vs production inventory：`languages` 7,858、`locale` 19、`expressions` 10,807、`sources` 2、`managed_ui_edges` 1,366 完全一致。
- [ ] **Step 3**: 記錄 `scripts/db/state/backup/` 之 remote/local 指紋（sha256）。

## Task 4: 逐部導入與發布

- [ ] 依序：Cantonese Oxford → Thai → Arabic → Simplified Chinese Japanese → Traditional Chinese English → …（以 `--only`
      fragment 精確命中，並 exclude 已屬 system 的檔）。
- [ ] 每部：導入 local → `export_dictionary_delta.py` 產 delta.sql → `manage.sh production plan --approved-data-migration
      scripts/db/state/backup/delta/<source>.sql --database-name langmap-v2` → operator 審核欄位（git_commit、counts、pour checksum）
      → `manage.sh production apply --plan <plan.json> --database-name langmap-v2 --confirm-production langmap-v2`。
- [ ] 每部 apply 後跑 `manage.sh production inventory` 對照 local counts；任意 preflight/verify 失敗立即停止並查看 bookmark。

## 驗收

- 每個 publication source 在 production 的 expressions/edges/sources/locales count 與 local 一致。
- production 仍可查詢既有 base（system/sources 不變、`managed_ui_edges` 1,366 不變）。
- plan 產出後 apply 前無 database 變更；失敗不會影響已發布部分（bookmark 可用於 restore）。
- git diff --check 乾淨；未提交改動保留。

## Commit

- 每個 task 一個 Conventional Commit（`feat(db):` / `test(db):` / `chore(db):`），只 commit 該 task 檔案。