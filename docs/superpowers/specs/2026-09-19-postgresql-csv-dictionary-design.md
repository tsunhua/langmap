# PostgreSQL-only 與 CSV 詞典匯入設計

## 狀態與目標

本設計取代 LangMap 的 D1／SQLite 資料庫與 Structured JSONL staging 流程。正式資料已遷移至 PostgreSQL；本工作**不包含**資料搬遷、D1 回填或歷史資料比對。

完成後，PostgreSQL 是唯一的應用程式與詞典匯入資料庫，詞典的可重跑來源是 `dictionary` 專案中版本控制的 canonical CSV 與 manifest。LangMap 僅保留跨平台的 CSV→PostgreSQL 匯入器。

本設計刻意分成兩個可獨立驗收的子專案：

1. PG-only runtime：移除 D1／SQLite 運行依賴與過時管理鏈路。
2. CSV dictionary supply chain：建立 CSV 契約、將輸出物移至 `dictionary`，並直接匯入 PostgreSQL。

兩者的共同前置條件是已存在可連線的 PostgreSQL。CSV 匯入可在 PG-only runtime 完成前先以直連資料庫測試；正式切換則先完成 runtime，再移除舊詞典鏈路。

## 非目標

- 不遷移、驗證或重建已遷移的 D1 正式資料。
- 不保留 D1 可執行 migration、Time Travel、mirror、SQLite snapshot 或 dual-write 回退通道。
- 不保留 Structured JSONL 作為 LangMap 匯入格式；若 exporter 內部仍需要其他暫存格式，必須留在 `dictionary` 專案且不成為 LangMap 的資料契約。
- 不在本次重新設計 expression、edge、來源標記或 registry 的既有 domain schema。

## PG-only runtime

### 執行期邊界

Worker 保留 R2、AI 與 Hyperdrive，移除 `d1_databases` binding。`backend/src/db/pgDatabase.ts` 成為唯一執行期資料庫 adapter；服務與 routes 改依賴本專案定義的 `Database`／`PreparedStatement` 最小介面，而非 `D1Database`。

這一介面只保留目前服務實際使用的 `prepare(...).bind(...).first/all/run` 與 `batch`。PG adapter 必須在其公開型別與註釋中不再提及 D1。保留介面是為了把 Worker route/service 與 `pg` client lifecycle 隔離，不是為了支援第二種資料庫。

SQL 從 SQLite 方言逐步改為原生 PostgreSQL（參數、UPSERT、JSON、case-insensitive search、時間與 pagination）。轉譯層只可作為同一變更中的暫時相容步驟；所有已被轉換的 query 都不得再依賴 SQLite semantics，且最後必須刪除通用 SQLite→PG regex 轉譯。

### Schema 與本機環境

新增 PostgreSQL baseline schema 與 PostgreSQL-only migration runner，供新本機資料庫及未來環境建立使用。它不執行歷史 `backend/migrations/0001...0045` 中的 SQLite DDL；現有 PostgreSQL 已處於正確基線，僅接受新 PG migration。

開發文件以 `DATABASE_URL` 為唯一連線設定。macOS 文件提供 Homebrew 安裝、初始化、`brew services` 與 `createdb` 範例；不把 Homebrew、Docker、`psql` 可執行檔或特定 shell 作為 runtime／匯入器條件。`dev.sh` 不再建立 `.wrangler/state`、執行 D1 migration 或尋找 SQLite 檔案。

### 清理範圍與保存原則

在完成 PostgreSQL baseline 與 integration test 替換後，刪除 D1 專用的 `backend/schema.sql`、`backend/migrations/`、`scripts/db/` 中的 D1 migration／production／snapshot／restore／delta 工具及其測試 fixtures，並刪除 D1 專用的 README、package scripts、`dev.sh` 分支與 runbooks。

舊文件不以大量逐行改寫假裝仍可用：現行入口文件改指向 PostgreSQL；歷史 ADR、已完成 spec／plan 可保留其歷史敘述。每個候選刪除項目須以 `rg` 確認沒有現行程式、指令、CI 或 runbook 使用；仍服務於 PG 的通用 registry／seed 工具必須先移出 `scripts/db/` 或改名，再刪除 D1 外殼。

### `scripts/` 全量退役審計

本次範圍包含 `scripts/` 中過時的所有檔案，不僅是可執行檔。先為每個頂層子目錄建立 keep／move／delete inventory，依據是目前 PG-only runtime、CSV contract、CI、或仍受支援的資料來源是否引用它。已淘汰流程的 README／操作說明、D1 SQL artifact、SQLite state／backup／import-state、fixture、gold set、snapshot、測試、shell wrapper 與只被淘汰工具引用的 Python module，必須與所屬流程一併刪除。

`scripts/dictionary/README.md` 改為 CSV contract 與跨平台 importer 的唯一操作入口；`scripts/wikivoyage/README.md` 和 pipeline 若仍保留，必須改成輸出 canonical CSV + manifest。`scripts/i18n/`、`scripts/language-reference/`、`scripts/morphology/`、`scripts/wikivoyage/` 等非詞典目錄也要逐項確認，不因名稱無 D1／SQLite 字樣而豁免。它們若輸出 D1 SQL、呼叫被移除的詞典入口、或沒有現行產品責任，即整組刪除；若仍必要，改為 PG／CSV 介面並保留相應測試與最小 README。

不得對 `scripts/` 進行未經 inventory 的廣泛刪除。每一個保留項目須在計劃中寫出使用者（runtime、CI 或 human command），每個刪除項目須列出已同步移除的引用；這可避免把仍被 registry seed 或 handbook 建置使用的工具誤刪。

## CSV 詞典契約

### 來源物與目錄

`dictionary` 專案保存所有 canonical 匯出物，不再只把它們放在外接磁碟或 LangMap staging directory。每個 source snapshot 以如下形式提交：

```text
csv/<source-key>/
  manifest.json
  data.csv
```

`manifest.json` 至少包含 schema version、stable `source_key`、顯示名稱、來源 type／URL／license、exporter version、`data.csv` 的 SHA-256，以及 locale metadata（必要時為 `name`、`name_en`、script、region、orthography、place path）。它是 source metadata 的唯一權威；CSV 不重複來源資料。

CSV 採 UTF-8（允許 BOM）、RFC 4180 quoting。允許的表頭順序固定為：

```text
ENTRY_ID,NOTE,LOCALE_<locale-code>,LOCALE_<locale-code>,...
```

`ENTRY_ID` 必填且在一個 CSV 內唯一；它是 exporter 穩定 entry reference，而不是資料庫 ID。`NOTE` 可省略；以 `|` 分隔的值是此列的來源註記。至少必須有兩個 `LOCALE_<locale-code>` 欄位。locale 欄位按 code bytewise ascending 排列；不可有未知欄位、重複欄位、空白表頭或依語言名稱猜測的欄位。cell 以 `|` 表示多個詞面候選，輸出前以 canonical Unicode NFC、trim 與固定 duplicate removal 正規化。

所有有效 locale code 都以 manifest metadata 補足 registry：不存在的 language、script、region、locale 由 importer 在同一 transaction 建立；metadata 缺少建立所需欄位、code 不符合 grammar、或與既有 registry 定義衝突時 fail closed。不可把 locale code 直接當成使用者可見名稱。

## 匯入器

LangMap 提供 `scripts/dictionary/import_mapping_csv_pg.py`，採 Python 與 `psycopg`，只需要 Python、套件相容的 PostgreSQL driver 和 `DATABASE_URL`，可在 macOS、Linux、Windows 執行。不得依賴 Homebrew、`psql`、shell script、D1 CLI 或 SQLite。

指令接受 manifest 路徑，將同目錄 `data.csv` 視為唯一輸入：

```text
python scripts/dictionary/import_mapping_csv_pg.py --manifest <path>/manifest.json --check
python scripts/dictionary/import_mapping_csv_pg.py --manifest <path>/manifest.json --apply
```

`--check` 會驗證 manifest、checksum、header、locale metadata、cell surface、預計 registry／expression／edge／source 關聯數量，並輸出穩定排序 JSON summary，絕不連線寫入。`--apply` 先完成相同驗證，再用一個 PostgreSQL transaction 建立 registry、同步 source snapshot、更新統計並輸出同格式 summary；任何錯誤 rollback。

對每一列，匯入器擴展各 locale cell 的去重詞面。任意兩個不同 canonical expression（包含相同 language、不同 text）建立一條無方向 direct mapping；完全相同的 expression 不形成自連邊。`NOTE` 寫為該 source marker 專屬的 edge annotation。expression、locale link、edge、source marker 與 annotation 的寫入都必須固定排序。

`--apply` 是 source snapshot synchronization：只替換 manifest `source_key` 擁有的 `expression_sources`、`expression_edge_sources` 與該 source 的 annotations；其他 source 的 ownership、marker、annotation 和共用 expression／edge 完整保留。完成後只刪除無來源 ownership 的孤兒 expression／edge。相同 snapshot 重跑必須冪等；CSV 刪除一列必須只撤回該 source 曾聲明的資料。

## 退役 Structured JSONL 與 D1 詞典工具

CSV format 與 importer 驗收後，刪除或移出 LangMap 的 `manage.py` staging commands、`import_with_progress.py`、`incremental_import.py`、`release_dictionary.py`、`import_next.sh`、`import_structured_jsonl.py`，以及 `langmap_dictionary/` 中僅支援 SQLite staging、D1 local import、packed catalog、reconciliation release 與 SQL delta 的模組／測試。

`export_mapping_csv_jsonl.py`、`export_mapping_csv_sql.py` 及 D1 SQL output tests 不保留；其 CSV schema parsing／surface validation 若仍適用，抽成 importer's format module。CSV exporter、source-specific adapter、全量 CSV archives 與 exporter 測試移至 `dictionary` 專案，並在該 repo 的一次獨立提交中建立 header contract、manifest generator 與 archive policy。Wikivoyage 若仍是產品資料來源，必須在刪除前改輸出 canonical CSV + manifest 或明確標為本次淘汰；不得留下呼叫已刪 incremental importer 的 pipeline。

## 驗收

1. `rg` 對現行 runtime、scripts、CI、README 和 runbook（排除歷史 documents）找不到 D1 binding、Wrangler D1 command、SQLite connection 或 `.wrangler` state 依賴。
2. Homebrew PostgreSQL 可依文件建立本機 database，`dev.sh` 能以 `DATABASE_URL` 啟動 Web 與 Worker；Worker 不要求 D1 binding。
3. PostgreSQL integration suite 覆蓋 API 的 read/write transaction、constraint error、batch rollback、search case handling、JSON annotations 與 migration baseline。
4. `dictionary` repo 每一個支援來源都有提交的 `data.csv` 和 checksum-locked manifest，並通過 header／checksum lint。
5. CSV importer 的 integration tests 覆蓋 `--check` 零寫入、未知 registry 建立、metadata conflict rollback、同語言 pair、跨語言 pair、self-edge 去除、idempotent reapply、同 source 刪列同步，以及兩 source 共用 expression／edge／annotation。
6. 以一個 source 在空 PG database 匯入，再刪除一列重跑；計數與 source ownership 符合 summary，且無不屬於該 source 的資料被刪。

## 風險與回退

不提供 D1 dual-write 或 SQLite snapshot 回退。每次 CSV 變更由 `dictionary` Git commit 與 manifest checksum 可重建；正式資料回退依 PostgreSQL 的備份／point-in-time recovery 政策處理。首次切換前須取得 PostgreSQL backup/restore 演練證據。

CSV source synchronization 的刪除範圍是最高風險點；它必須先用 `--check` 計數與 source-scoped integration test 驗證，並永遠以 `source_key` 篩選，不能以 expression text 或 locale 做寬刪除。
