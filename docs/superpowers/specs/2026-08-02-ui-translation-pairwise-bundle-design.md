# UI 翻譯兩兩配對 Bundle 設計

- 狀態：待實作
- 範圍：`scripts/i18n/` 的 bundle 產生器與產物

## 問題

受管理的 system UI 翻譯（`scripts/i18n/*.json`）經 `generate-bundle.py` 產出
`system-ui.sql` 時，對每個 key × locale 只產生一條邊：`en 源 ↔ 目標語言`。

結果是 `/mapping/:id`（如 en "Alphabetical"）的關係圖呈星形——所有翻譯節點
只連到 en，翻譯彼此之間沒有任何邊。這與「同一 key 的所有翻譯彼此語義等價」的
領域事實不符。

## 目標

同一 UI key 的所有翻譯 expression（含 en 錨點）彼此兩兩建立 `expression_edges`，
構成完整團（clique）。en 仍是 `ui_messages` 的 source 錨點與圖根。

## 非目標

- workbench（`/translate`）手動提交翻譯：維持現狀，不建立團邊。
- manifest schema：不新增 `edge_count`；`translation_count` 維持為翻譯列數。
- 後端 API、web 前端、資料庫 migration：皆不動。
- `generate-i18n-sql.py`（單語系產生器）：不動——單一 locale 無法構成團。

## 設計

改動僅限 `scripts/i18n/generate-bundle.py` 及其測試：

1. `render_bundle_sql` 的 translation 段改為依 key 分組：每個 key 收集節點集合
   `{en 源 expression} ∪ {各 locale 目標 expression}`。
2. 對該集合產出所有無序對的 `expression_edges`（`stable_edge_id` = `min-max`，
   score 0，source `ui_i18n`），取代原本「en↔目標」的單邊。
3. 跨 key 共用 expression（如 en/es/ja 文本相同）產生的重複邊由
   `INSERT OR IGNORE` 去重，SQL 維持冪等。
4. `validate_deterministic_ids` 改為驗證「實際產出的團邊集合」，維持
   expression_id / edge_id 碰撞檢查，並確保渲染與驗證一致。

## 驗證

- 更新 `test_generate_bundle.py`：
  - SQLite 載入產物後，斷言每個 key 的節點集合內任兩點都存在邊。
  - 斷言 `expression_edges` 總數符合團公式 `Σ C(n_key, 2)`（扣掉跨 key 共用
    expression 的收斂）。
  - 冪等性測試（二次執行計數不變）維持。
- 重產 `scripts/i18n/artifacts/system-ui/`，`import-all.sh --local` 重匯入本地 D1。
- `/mapping/8772039352640020` 驗證出現翻譯互連邊。
- `cd backend && npm test` 確認無回歸。

## 連帶效應

`search.alphabetical` 與 `languageDetail.alphabetical` 的 en 源都是
"Alphabetical"（同一 expression 8772039352640020），且 es/ja 翻譯文本相同，
故這兩個 key 的團會共用節點、收斂為聯集團。這正確反映「同一 key 的翻譯彼此
等價」，屬預期行為，不是缺陷。
