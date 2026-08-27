# 詞典匯入 staging 讀取優化設計

## 狀態

本文件描述待實作設計。範圍限於本機詞典匯入器的 staging 讀取、canonical D1 寫入快取、進度觀測與 CLI 安全預設；不搬移 staging 根目錄，也不修改線上 API 或資料模型。

## 背景

`scripts/dictionary/import_with_progress.py` 會把單一 Structured JSONL 載入 `/Volumes/DATA/langmap-staging-parts` 的 SQLite，再由 `local_import.py` 寫入本地 canonical D1。`/Volumes/DATA` 是 USB 上的 Tuxera NTFS synchronous mount。

實測顯示，28.3 MB 輸入會展開為 241 MB staging、66,573 occurrences、66,573 clusters 與 66,573 members。匯入程序長時間維持低 CPU，stack sample 幾乎全部停在 SQLite B-tree table lookup 的 `pread()`。目前 `_load_rows()` 依索引排序後讀取非 covering rows，並讓每個 occurrence JOIN 含大型 `raw_json` 的 `input_entries`，在小型 SQLite page cache 下產生大量外接磁碟隨機讀取。

## 目標

- 將 staging 大量讀取改成順序 table scan，避免索引到資料表的逐列跳轉。
- 移除 occurrence 對 `input_entries` 的逐列 JOIN，保留每筆資料的 source identity。
- 移除 staging SQL 層不必要的排序，同時維持 canonical ID 與寫入結果可重現。
- 顯示 stage、normalize、cluster、staging load 與 D1 write 的限頻進度及分階段耗時。
- 在單次匯入生命週期內快取 schema、language、locale、source 與 POS lookup。
- 無參數執行時只列狀態；只有明確 action 才能匯入。

## 非目標

- 不把 staging 搬到內建 APFS 磁碟。
- 不新增 covering index 或其他 staging schema index。
- 不改變 canonical schema、migration 或 API 契約。
- 不引入跨資料庫或跨程序的全域 cache。
- 不在本次工作處理 AI reconciliation 或跨詞典 cluster 合併。

## 採用方案

採用「順序掃描 + Python 對照表 + 單次匯入快取」。不採用 covering index，因為它會增加 staging 容量、外接 NTFS 寫入與建索引時間；不只調整 SQLite cache 或 mmap，因為那不能消除逐列 lookup，且大型詞典仍可能超出快取。

## Staging 載入

`local_import.py` 將以一個清楚的 staging snapshot 邊界載入四類資料：

1. `input_entries NOT INDEXED`：建立 `entry_key → dictionary_key` 對照表。
2. `lexical_occurrences NOT INDEXED`：不 JOIN、不在 SQL 排序，只保留通過既有語言與錯誤條件的 rows。
3. `lexical_clusters NOT INDEXED`：不在 SQL 排序。
4. `cluster_members NOT INDEXED`：在 Python 依 cluster 分組，不依賴 SQL row order。

occurrence 不再攜帶 JOIN 產生的 `dictionary_key` 欄位。需要 source 時，以 occurrence 的 `entry_key` 查詢 entry source map。找不到 entry source 屬於 staging 完整性錯誤，必須以含 entry key 的明確例外停止匯入，不可默默回退成泛用 source。

## 排序與可重現性

移除的是 staging 大型 row 的 SQL 排序，不移除 canonical 寫入的 determinism：

- expression cluster 仍沿用 Python 的 `(lang_code, canonical_text, headword priority, cluster_key)` 排序；因此原本 clusters SQL `ORDER BY` 是重複工作。
- cluster members 的來源選擇使用集合後的明確排序；member 載入順序不影響結果。
- occurrence table scan 只負責載入。locale links、readings 與 edges 在寫入前按輕量穩定鍵排序，不能依賴 SQLite table row order 或 Python dict 的偶然插入順序。
- 同一 staging、同一 canonical 初始資料與同一程式版本，必須產生相同 expression／edge 關係與穩定的新增順序。

## Canonical D1 單次快取

匯入期間建立 connection-scoped cache，生命週期不超過一次 `import_release_to_local_d1()` 呼叫：

- table columns；
- language code → language ID 或 unknown；
- locale code → locale ID；
- `(source type, source name)` → source ID；
- POS code set → bitmask。

cache 只保存由同一 D1 connection 讀寫的結果。匯入結束即丟棄，避免另一個資料庫或後續 schema 變更讀到舊值。既有 conflict-safe insert／upsert 與 foreign-key 行為保持不變。

## 進度與耗時

loader、normalizer、cluster builder 與 local importer 以可選 callback 回報結構化事件。沒有 callback 時維持現有函式可用性。

事件至少包含：

- `phase`；
- 已處理 rows 或 entries；
- 可得時包含 total；
- 該 phase 自開始後的 elapsed seconds。

`import_with_progress.py` 對事件做限頻輸出：phase 切換必須立即顯示；同一 phase 只在固定 row 間隔或完成時更新。輸出使用純文字與 flush，不依賴 TTY 控制碼，便於終端、日誌與測試捕捉。

每檔成功 state 另保存 `phase_seconds`，至少區分：

- `stage`；
- `normalize`；
- `cluster`；
- `staging_load`；
- `d1_write`；
- `total`。

失敗輸出需保留最後 phase，讓使用者能區分 staging I/O、normalization 與 D1 write 問題。

## CLI 安全契約

無參數執行 `import_with_progress.py` 時，只列出全部檔案及狀態並成功退出，不呼叫 staging 或 D1 寫入。`--list` 與無參數等價。

只有以下明確 action 可以匯入：

- `--next`；
- `--all`；
- `--only FRAG`；
- `--force FRAG`。

互斥或矛盾 action 由 argparse 拒絕。`--limit` 只限制已由明確 action 選出的工作集，不能單獨啟動匯入。

## 錯誤與中斷

- staging snapshot 缺少 entry source 時立即失敗，錯誤包含 release 與 entry key。
- progress callback 的顯示層不得改變交易邊界或吞掉匯入例外。
- D1 寫入仍使用單一 transaction；失敗或中斷由 connection close／rollback 保持原子性。
- staging 清理維持既有 `--keep-staging` 契約。

## 測試 seam 與驗收

測試只透過公開 seam 驗證：

1. `import_release_to_local_d1()`：固定 fixture 的 expressions、locale links、readings、edges 與 homograph 結果不變；progress phase 完整且有單調 processed counts；相同輸入維持可重現結果。
2. staging snapshot loader：多 entry／多 source fixture 能正確把 occurrence 對應到 dictionary source，缺失 entry source 明確失敗。
3. `import_with_progress.main(argv)`：無參數與 `--list` 不呼叫匯入；每一個明確 action 能選出預期工作集。

效能驗收使用固定 staging fixture，比較修改前後：

- 記錄 staging bytes、rows、各 phase seconds 與總時間；
- 使用 `EXPLAIN QUERY PLAN` 確認三張大型 staging 表採 table scan，而非按非 covering index 取完整 row；
- 不以易受磁碟 cache 影響的單一毫秒門檻作單元測試；
- 在 `/Volumes/DATA` 代表性檔案實測時，`staging_load` 不得再長時間維持索引跳表的 `pread()` stack pattern。

## 相容性與回退

函式新增參數一律為 optional keyword，既有呼叫端不需立即修改。資料 schema 不變，因此回退只需還原 Python 程式；既有 state、JSONL、staging 與 canonical D1 均不需 migration。
