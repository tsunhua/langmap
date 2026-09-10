# Expression 大小寫正規化與 Production D1 合併設計

> 日期：2026-09-10
>
> 狀態：簡化方案已確認，待 implementation plan 與 production operator 審核；尚未修改 production D1

## 1. 背景

目前資料中存在同一語言、同一 `homograph_index` 下僅大小寫不同的 Expression，例如
`CLOSED`、`Closed` 與 `closed`。需要把可大小寫文字統一成 sentence case，合併重複
Expression，並保留原有資料關係。Production expression 規模為幾百萬筆，不能逐筆讀回本機
再產生 mapping。

## 2. 目標

- 先盤點 locale／script 的大小寫能力，再決定可處理範圍。
- 使用不含 production row／ID 的固定 SQL，在 production D1 內以 set-based SQL、keyset 分批完成正規化與合併。
- 合併後保留兩個原 Expression 的全部 mapping 及其他引用。
- 不匯出或上傳大量 production data，不重用本機整數 ID。
- 在發布 SQL 前，只用本地 fixture 與有上限的小樣本驗證 SQL 行為。
- 變更可由 bookmark 回復，並可在 apply 後驗證。

## 3. Locale／script case policy

正規化範圍以精確 `language_locale` 與 `script_code` 判定，不只依 language code。第一版
政策如下：

| policy | locale 範圍 | 行為 |
| --- | --- | --- |
| `none` | `cmn-Hans*`、`cmn-Hant*`、`jpn*`、`kor*`、`nan-Hant*` | 不改 Expression text |
| `cased` | `nan-Latn*` | 參與 sentence-case 與去重 |
| `unknown` | 其餘尚未審核範圍 | 第一版不修改，列入報告 |

判定規則：

1. Expression 有 locale links 時，全部 links 都是 `none` 才跳過；只要有一個 `cased` link
   就可處理。
2. 沒有 locale link 的 Expression 不猜測，先保持不變並列出數量及抽樣。
3. `nan-Hant` 與 `nan-Latn` 必須分開判定；不能因 language code 都是 `nan` 而整體排除
   `nan-Latn`。
4. 同一 Expression 連到多個 locale 時，沿用單一 Expression identity；不能為不同 locale
   產生兩個文字版本。

Apply 前先產生唯讀 audit，至少包含 locale policy、各 policy 的 Expression 數量、無 link
數量、多 locale／混合 policy 數量，以及待處理 duplicate group 數量。Audit 不修改 D1。

## 4. Production SQL migration

### 4.1 執行邊界

沿用 `scripts/db/manage.sh production plan/apply`。`production apply` 在第一次 mutation 前
自動取得並 journal bookmark，接著執行已批准的 SQL data migration；不直接使用 raw
`wrangler d1 execute --remote`。Apply 期間暫停 Expression、mapping 與 Handbook 寫入。

### 4.2 SQL 內容

SQL migration 是固定、資料無關的 SQL package，不包含 production expression 清單、production
ID 或本地資料庫 dump。SQL 在 D1 內建立暫存 migration map（`old_expression_id`、
`survivor_expression_id`、`target_text`），只 materialize `cased` 範圍中需要變更或屬於
duplicate group 的資料。以 Expression `id` 做 keyset 分批，避免單次 statement 超過 D1 CPU
限制；分批檔案仍屬於同一個 operation，並可由同一 plan 重跑。

Case policy 以 SQL 內的固定 `VALUES`／CTE 表達，不從 production 匯出 locale registry。正式
apply 只在 D1 內掃描及更新資料；本機不接收整庫 expressions、edges 或 readings。

執行順序：

1. 建立並索引 migration map。
2. 選定 survivor；優先保留已符合 target text 的 row，其次按穩定引用數與最低 ID 決定。
3. 將 duplicate Expression 的所有 references 改接 survivor，包括：
   - `expression_edges` 兩端；
   - `expression_edge_sources`、`edge_votes`、`expression_split_moves`；
   - `expression_readings`、`expression_locale_links`、`expression_sources`；
   - `handbook_section_items`、`expression_splits`、`expression_form_edges` 及其 features；
   - registry pointers 與 `ui_messages`。
4. 對重接後的 mapping／form edge 合併重複端點，移除 self-edge，保留來源、vote 與 relation
   metadata。
5. 更新 survivor text，刪除已無引用的 duplicate Expression。
6. 刷新 `language_statistics`。

### 4.3 大小寫實作限制

SQL-only 路徑只處理 D1 內可可靠處理的 ASCII case；無大小寫 script 不做變更。非 ASCII
且有大小寫的資料在 audit 中標記為 `unsupported_case`，本次不靜默改寫，也不另開一套
production Worker 流程。若日後需要完整 Unicode sentence-case，另立獨立 spec 與 migration。

## 5. 發布前本地採樣驗證

這是 production SQL 的必要 gate，不需要下載 production 全量資料：

1. 使用 `backend/schema.sql` 建立本地 fixture，覆蓋 `none`、`cased`、`unknown`、無 locale
   link、多 locale、duplicate Expression、duplicate mapping、reading、source 與 Handbook
   reference。
2. 從 production 只執行有上限的抽樣查詢；每個 policy 最多 100 個 Expression，duplicate
   group 最多 200 組，總樣本上限固定。樣本只作驗證，不作 production SQL 生成。
3. 在本地 SQLite 執行與 production 完全相同的固定 SQL package。
4. 驗證 `none` 未改變、`nan-Latn` 可處理、duplicate mapping 已合併、reading／source／
   Handbook references 完整、沒有 orphan 或 self-edge。
5. 採樣報告、SQL checksum、Git commit 一起寫入 production plan；任何 sample failure 都
   禁止進入 apply。

抽樣只允許取得必要欄位及固定數量 rows；禁止使用 production dump、全表 export 或把 sample
之外的線上資料寫入本地 D1。

## 6. 驗證與回復

Postflight 必須確認：

- `none` policy 的 Expression text 與 references 未被意外改動；
- `cased` 範圍不存在 normalized duplicate group；
- `expression_edges`、readings、locale links、sources、Handbook items 無 orphan；
- 沒有 self-edge，mapping 數量變化符合 plan；
- `language_statistics` 已刷新；
- 抽查 `CLOSED`／`Closed`、`nan-Hant`、`nan-Latn` 及 handbook mapping；
- `PRAGMA foreign_key_check` 與完整 production verify 通過。

任何錯誤以 operation journal 中的 bookmark 執行 Time Travel restore；不手動重播或編寫臨時
rollback SQL。

## 7. 非目標

- 不改變 reading 的大小寫或內容。
- 不把無 locale link 的 Expression 以字元集猜測歸類。
- 不為 `cmn-Hans`、`cmn-Hant`、`jpn`、`kor` 或 `nan-Hant` 建立大小寫版本。
- 不在本次 operation 同時匯入新的 Wikivoyage 或 dictionary source。

## 8. 完成條件

Implementation plan 必須涵蓋 locale policy audit、固定 production SQL package、本地 fixture
及 bounded sample gate、分批／續跑、mapping merge、postflight 與 bookmark restore 測試；完成
sample review 與 operator review 前不得對 production D1 執行 apply。
