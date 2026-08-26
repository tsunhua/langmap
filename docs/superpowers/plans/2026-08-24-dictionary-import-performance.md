# 詞典全量匯入效能紀錄

## 目標

把約 511 萬筆 Structured JSONL v2 詞典記錄重新匯出後，完成 normalization、cluster 建立及本機 D1 匯入。舊 staging 資料不保留；中斷後允許刪除中間庫並從 JSONL 重建。線上 D1 空間預算改為 5GB 以內，完整抽取欄位仍只在可重建的 staging 保存。

## 基準與判定

代表性 2,000 筆 normalization 測試：

| 實作 | SQL 查詢數 | 時間 |
| --- | ---: | ---: |
| 舊版：逐 entry 查三張子表 | 6,001 | 0.350 秒 |
| 新版：四個循序 cursor | 4 | 0.048 秒 |

查詢數降低 1,500.25 倍，該樣本端到端加速 7.24 倍。字典測試目前為 44 項全數通過。

## 保留的改善

- normalization 以 `rowid` 依序掃描 entry、pronunciation、sense、form，避免約 1,500 萬次子查詢。
- 明確使用 `NOT INDEXED` 執行全表循序掃描，避免 SQLite 誤用不適合全量處理的索引。
- normalization 依穩定 cursor 分批寫入，提交間隔可由 `--commit-every` 調整；全量執行採 50,000 筆。
- cluster 直接由唯一的 claim-based cluster key 寫入，不再以 `GROUP BY` 建立大型暫存排序。
- 本機 D1 使用單一 SQLite 連線與集合式 SQL 匯入，避免經 Wrangler 逐 statement 執行數百萬次。
- `reconcile run` 在雙 pass 均通過高信心門檻後，會把 accepted pairs 寫回
  staging 的 `lexical_clusters`、`cluster_members` 與 occurrence cluster key；
  `local-import` 因而直接使用合併後的 expression identity，並把相關 binding 標成
  `ai_merged`。
- D1 完全移除逐 object `dictionary_release_objects` journal；release membership
  只保留在 binding/evidence 表中。兩個與 composite primary key 完全重複的
  release/claim indexes 也一併移除，既有資料庫透過
  `0036_dictionary_remove_redundant_indexes.sql` 增量清理。
- `--fast` 僅用於可重建的 staging DB；關閉 rollback/WAL，讓中斷後可立即刪除重跑，不等待大型 rollback。
- 本地 D1 的 `local-import --packed` 使用整數鍵 catalog：`dictionary_terms`、
  `dictionary_edges`、`dictionary_readings` 與語言／locale codebook、詞性 bitmask；claim、cluster、AI
  判定及其他抽取欄位不複製到線上。API 讀取透過 compatibility views 合併一般
  LangMap 資料，通用寫入仍保留原表。
- hashing、staging 與 normalization 都輸出週期性進度，便於辨識停滯與實際處理速率。

## 放棄的嘗試

- pronunciation 額外索引：在外接磁碟建立約耗時 57 分鐘，而既有複合主鍵已涵蓋相同查找前綴，故不保留。
- DELETE journal 全量寫入：中斷後產生 128 MB hot journal，SQLite 回滾超過 35 分鐘，故不再用於可重建的全量 staging。
- 單純切換 `journal_mode=OFF`：2,113 筆小樣本未量到穩定加速，因此不把它視為吞吐量改善；只保留其免回滾特性。

## 全量執行與驗收

1. 建立全新的外接磁碟 staging DB，使用 `stage --fast`；全量交易只作診斷，不作正式匯入。
2. 正式流程使用 `scripts/dictionary/incremental_import.py`，按檔案大小由小到大，每部獨立完成 normalization、cluster 與 packed append。
3. （可選）在完整 staging release 上執行 `reconcile run`；只有雙 pass、高信心且無 blocker 的候選會自動合併。單檔增量流程不做跨檔案 AI 合併。
4. 建立全新的 Miniflare D1，套用所有 migration。
5. 每部成功後立即更新 `dictionary_dataset_state`；匯入不建立逐物件發布審計，也不把 binding/evidence 複製到線上。
6. 每部核對 packed term、edge、reading、POS 增量、compatibility view 查詢，以及 `PRAGMA foreign_key_check`。

高速 staging 中斷後不保證可恢復；單檔增量流程只需重跑當部 JSONL，已成功的 release 會由 state JSON + D1 release ID 跳過。本機 D1 同樣視為可丟棄開發資料。

## 增量流程基準（2026-08-25）

正式執行以 `/Volumes/DATA/langmap-structured-jsonl` 為輸入，預設 `batch-size=5000`、`commit-every=20000`。每部 stdout JSON 會記錄輸入 bytes、entry/s、MB/s、D1 前後計數與檔案耗時；先以最小檔案建立冷啟動基準，再持續小檔案優先。

## 空間量測（2026-08-24）

代表性 Arabic shard（257,882 個線上詞句、203,498 條 mapping、75,155 個 reading）：

| 匯入形態 | SQLite 檔案 |
| --- | ---: |
| 原本通用表、binding/evidence 及索引 | 618MB |
| 移除線上 claim/evidence、短 ID | 約 96MB |
| `--packed` catalog + compatibility views | 43MB |

以目前全量／shard 比例線性估算，`--packed` 約 4.0GB；加入整數語言／locale codebook
後約 3.65–3.8GB，另加一般 LangMap 基礎表仍低於 5GB。此估算不把可刪除的 staging SQLite 計入常駐線上資料；完整 JSONL 仍可
保留在離線工作區或於匯入驗證後清理。
