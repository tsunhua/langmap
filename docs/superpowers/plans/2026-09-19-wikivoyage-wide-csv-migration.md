# Wikivoyage 寬表 CSV 搬遷施工清單

## 目的（WHAT）

把 Wikivoyage 來源流程集中到 `dictionary` 專案，統一產出「每個英語→一個目標
locale 一份」的寬表 CSV；LangMap 僅以 PostgreSQL 匯入並重建 handbook。移除
SQLite／D1 staging、JSONL 中間產物及舊 `scripts/wikivoyage` pipeline。

## 交付物

- dictionary 的 Wikivoyage adapter 與 CLI：固定 snapshot → 寬表 CSV + manifest。
- 寬表契約：`ENTRY_ID`、`NOTE`、`LOCALE_*`、`READING_*`，多 locale 頁面拆成多份
  archive，reading 不再使用 sidecar。
- LangMap PG importer 支援 reading 欄位、manifest source metadata、source-scoped
  冪等清理與同語言 pairwise mapping。
- PG-only Wikivoyage handbook rebuild command。
- 舊 SQLite/D1 Wikivoyage 目錄、入口、測試及過時 runbook 清理。

## Checklist（按依賴執行）

- [x] 更新設計規格，確認一方向一 CSV、Chinese split locale、無 JSONL/sidecar。
- [ ] 在 dictionary 建立 Wikivoyage package，保留既有 parser/catalog/download 規則，
      將 export/quality 改為寬表 CSV。
- [ ] 擴充 dictionary 共用 CSV writer/manifest，加入 reading 欄位契約與 source metadata。
- [ ] 為 Japanese、Cantonese、Chinese split locale 加入 exporter/manifest/no-JSONL 測試。
- [ ] 擴充 `scripts/dictionary/import_mapping_csv_pg.py`：解析 `READING_*`、寫入與
      source-scoped 清理 `expression_readings`，並讀取 manifest source identity。
- [ ] 加入 importer 的寬表 reading、同語言 edge、冪等、刪列與跨 source 測試。
- [ ] 新增 PG-only handbook rebuild，使用 dictionary 的 section catalog，不連 SQLite/D1。
- [ ] 移除 `scripts/wikivoyage` 舊 pipeline 與失效入口；更新 runbook、inventory、README。
- [ ] 執行 dictionary/root 測試、`git diff --check`、`./build.sh`，並以本地 PostgreSQL
      做 `--check`/`--apply` smoke test；確認現有 `dev.sh` 服務仍可用。
- [ ] 只提交本次 owned files；保留使用者既有未提交修改，不納入無關檔案。

## 驗收門檻

1. 每個 archive 僅有 `data.csv` + `manifest.json`，header deterministic，沒有 JSONL
   或 readings sidecar。
2. CSV `--check` 在 checksum、欄位、locale、source metadata 錯誤時 fail closed；
   `--apply` 可冪等重跑，且只清理本 source 的 claims/readings。
3. 同語言不同詞面建立 mapping，不建立 self-edge；reading 不成為 mapping endpoint。
4. handbook rebuild 僅使用 PostgreSQL；舊 `scripts/wikivoyage` 不再提供可執行入口。
5. 測試與 build 通過，文件無過時的 SQLite/D1/JSONL 操作命令。

## 重要假設與回退

- 已遷移的 production 資料不重做；本次只改來源產物、匯入與維護入口。
- `expression_readings` schema 已存在；若欄位約束與寬表不一致，先以 migration/schema
  對齊再提交 importer。
- 來源 parser 的既有 fixture 是行為基準；新 exporter 只改輸出形狀，不改語言判斷。
- 任何無法安全自動轉換的舊 bridge 先保留在歷史 commit 中，不以刪檔掩蓋未遷移依賴。
