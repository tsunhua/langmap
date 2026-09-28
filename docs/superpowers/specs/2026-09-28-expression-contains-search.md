# 詞句包含搜尋與結果排序

狀態：已實作；既有資料庫需執行 migration 才會取得搜尋索引。

## API 契約

`GET /api/v2/expressions/search` 保留 `q`、`lang_code`、`limit`、`offset`
與既有分頁回應。主搜尋頁與詞句選擇器共用此 API。

- 非空 `q` 沿用詞句正規化與驗證，再以 PostgreSQL `ILIKE` 比對整個詞句中
  的任意連續片段，不區分大小寫。`%`、`_` 與反斜線按字面比對。
- 結果先按完全匹配、前綴匹配、其他包含匹配排序；同級按字元長度升冪、
  文字、`homograph_index`、整數 ID 升冪排序。排序在資料庫分頁前完成。
- 空白 `q` 沿用文字、`homograph_index`、ID 的升冪排序。
- `lang_code` 仍為可選的單一語言篩選；總數與結果使用同一個條件。
- 例如搜尋「車站」時，「車站」先於「車站入口」，後者先於「最近的車站在哪裡」。

## PostgreSQL 與接入

Baseline 與 [migration](../../../backend/postgres/migrations/2026-09-28-expression-contains-search.sql)
同步建立 `pg_trgm` extension 及 `expressions.text` 的 GIN trigram 索引。
既有資料庫依 [管理流程](../../../scripts/postgres/README.md) 執行
`python3 scripts/postgres/manage.py migrate`；執行帳號需有安裝 extension
與建立索引的權限。短查詢若沒有可提取的 trigram，仍可能掃描較多資料。

本次只調整詞句文字搜尋；不包含拼寫容錯、讀音搜尋、去聲調或繁簡轉換，
不改變詞句身份、翻譯檢索與語言詳情頁的獨立列表查詢。

## 驗證

使用隔離 PostgreSQL 與本機 Worker 驗證：句中包含、大小寫、字面特殊字元、
正規化、三層排序與同級長度、語言篩選、空查詢及跨頁總數／去重。
