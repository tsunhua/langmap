# Canonical 字典逐部線上發布 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended)
> or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 把以 canonical D1（0039+ integer storage）逐部匯入的詞典，以受管 apply 安全發布到 production `langmap-v2`，逐部可驗證、可回退。

**Architecture:** 本地 mirror 以「遠程匯出資料」為基底建立一次，使 expression 整數 ID 空間與 production 一致，
之後**增量維護**：每部詞典經 `import_with_progress.py` 合併進 mirror，per-source delta 匯出器產生明確 ID 的
`INSERT OR IGNORE` SQL，透過 `scripts/db` 的 plan/apply gate 套用到 production，**apply 成功後把同一份 delta
replay 回 mirror**，使兩邊維持一致。回滾靠 D1 Time Travel bookmark（apply 自動抓），mirror 不負責備份。
production 目前只有受管 delta 在寫（community 未上線），不存在外部漂移，故不需每次全量 export；
僅在 restore-from-bookmark（production 倒回）或 mirror 與 production 不一致偵測到時才重新全量 export。
不做 `__pycache__` 手動編輯、不走直接 `wrangler d1 execute --remote` 當發布手段。

## 背景事實（已驗證）

- production `langmap-v2`：已發布 5 部（粵英口語、粵英牛津、泰、阿、Crown v4），expression 756,027、`language_locales` 21、`managed_ui_edges` 1,366 不變。
- local dev D1（generator seed 基底）ID 空間與 production 不一致（MAX(id) 37 萬），不能直接搬既有資料。
- migration `0039_canonical_integer_storage` 已移除 release／claim／packed 表；現行 canonical 用 `expression_sources`／
  `expression_edge_sources`（0042）保留來源標記。故 runbook 的 `--dictionary-artifact-manifest` 發布線在現行 schema 下已失效。
- `production.py` 的 apply 已有 `approved_data_migration` 執行邏輯（`d1 execute --remote --file`／split `--command`），plan 已帶入參數。

## 非目標

- 不恢復 release／binding／evidence 模型；不把詞典 bundle 進 migration。
- 不做跨檔案 AI 高信心合併；本次只發布「同源逐部」匯入結果（與 README 增量模式一致）。
- 不修改已發布 migration；不改 remote baseline 以外的 production schema。
- 不動 `apple/`；不更動前端 display 語系邏輯。

## 發布機制

1. **首次基底對齊**：`wrangler d1 export --remote` 一次，把快照灌進 fresh mirror SQLite，local mirror == production（ID 完全一致）。
2. **逐部導入**：`import_with_progress.py --only <frag> --d1 <mirror>` 在 mirror 合併；sha state 續跑。
3. **delta 匯出**：`scripts/db/export_dictionary_delta.py`——以「導入前 mirror 快照.sqlite → 導入後 mirror.sqlite」逐表差集，
   僅輸出該部新增 rows（明確整數 ID、`INSERT OR IGNORE`），並依 FK 排序：`sources → language_locales → expressions →
   expression_sources → expression_locale_links → expression_readings → expression_edges → expression_edge_sources`。
   空值欄位用 `NULL`；所有值以 SQL literal 轉義；支援 partition 語句數（預設 5,000）避免單檔過大。
4. **受管 apply**：`manage.sh production plan --approved-data-migration <relative.sql>` 把檔案寫入 plan；
   `production apply`（既有 bookmark→migrate→data→reference→verify 順序）執行該檔並 post-apply 驗證；
   apply 成功後把**同一份 delta replay 回 mirror**（`sqlite3 <mirror> < delta.sql`），維持 mirror == production。
5. **verify**：production inventory 對照 mirror 的 publication source counts（expressions/edges/sources/locales）一致。

> **mirror 增量維護**：production 只有受管 delta 在寫，apply 後 replay delta 即可維持兩邊一致（`sqlite_sequence`
> 隨 max(id) 自動對齊）。**不需要每次全量 export**（遠端庫會愈來愈大、下載愈慢）。僅在下列情況重新全量 export：
> restore-from-bookmark（production 倒回，mirror 需同步倒）、mirror 與 production count 不一致、或 mirror 遺失。

## Task 3: 基底建立 mirror（operator 授權後，僅首次）

- [ ] **Step 1**: `wrangler d1 export --remote` 建立 factory 快照；灌進 fresh mirror SQLite（含 migration 表與資料）。
- [ ] **Step 2**: 比對 mirror vs production inventory：languages／locale／expressions／sources／managed_ui_edges 完全一致。
- [ ] **Step 3**: 記錄 `scripts/db/state/backup/` 之 remote/local 指紋（sha256）。
- [ ] **Step 4**: 寫入本文發布機制之增量維護規則（replay delta 回 mirror），取代「每次重建」舊規矩。

## Task 4: 逐部導入與發布

- [ ] 依序：Cantonese → Thai → Arabic → Simplified Chinese Japanese → 已發布；續接 Simplified Chinese Thesaurus → …（以 `--only`
      fragment 精確命中，並 exclude 已屬 system 的檔）。
- [ ] 每部：導入 mirror → `export_dictionary_delta.py` 產 delta.sql → `manage.sh production plan --approved-data-migration
      scripts/db/state/backup/delta/<source>.sql --database-name langmap-v2` → operator 審核欄位（git_commit、counts、pour checksum）
      → `manage.sh production apply --plan <plan.json> --database-name langmap-v2 --confirm-production langmap-v2` → replay delta 回 mirror。
- [ ] 每部 apply 後跑 `manage.sh production inventory` 對照 mirror counts；任意 preflight/verify 失敗立即停止並查看 bookmark。

## 驗收

- 每個 publication source 在 production 的 expressions/edges/sources/locales count 與 local 一致。
- production 仍可查詢既有 base（system/sources 不變、`managed_ui_edges` 1,366 不變）。
- plan 產出後 apply 前無 database 變更；失敗不會影響已發布部分（bookmark 可用於 restore）。
- git diff --check 乾淨；未提交改動保留。

## Commit

- 每個 task 一個 Conventional Commit（`feat(db):` / `test(db):` / `chore(db):`），只 commit 該 task 檔案。