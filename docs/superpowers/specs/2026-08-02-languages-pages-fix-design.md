# 語言列表與詳情頁修復設計

> 更新：本文件中以 `languages` 單表作為語言模型的決策，已由 [2026-08-03-language-variety-profile-model-design.md](./2026-08-03-language-variety-profile-model-design.md) 取代；頁面佈局與無障礙相關決策仍有效。

日期：2026-08-02
範圍：`web/src/pages/LanguageList.vue`、`web/src/pages/LanguageDetail.vue` 及其子組件、`backend/src/routes/languages.ts`。

## 背景與問題

`/languages` 與 `/language/:code` 存在資料錯誤與排版瑕疵：

1. **`expression_count` 恆為 0**：列表與詳情查詢 `LEFT JOIN language_stats`，但該表無任何流程維護，63 個語言全部回傳 0（zh-Hans 實際有 261 條詞句）。列表「按數量排序」因此失效、StatBox 顯示 0。
2. **詳情回應形狀不符**：`GET /languages/:code` 回傳 `{ language: {...}, mapped_expression_count }`，但前端讀 `lang.name`/`lang.code`/`lang.representative_cities`，全部 `undefined`，導致標題、代碼徽章、代表城市全空白。
3. **列表 `region_name` 恆為 `-`**：後端只回傳 `region_code`，`LanguageCard` 期望 `region_name`。
4. **詳情副標題欄位不存在**：前端讀 `family`/`status_text`/`region_name`，API 未回傳，副標題永遠空白。
5. **詳情詞句行冗餘**：每行重複顯示同一語言徽章（如 zh-Hans）。
6. **列表 name / name_en 無間距**：兩者為相鄰 inline span，文字黏在一起。

## 設計

### A. 後端 `expression_count` 改即時計算

移除對 `language_stats` 的依賴，改用關聯子查詢：

```sql
(SELECT COUNT(*) FROM expressions WHERE language_code = l.code) AS expression_count
```

套用於列表（`GET /`）與詳情（`GET /:code`）兩處查詢。`language_stats` 表保留不動，避免 schema 變更；63 個語言的子查詢對 D1 可接受。

### B. 後端詳情回應扁平化

`GET /languages/:code` 改回傳扁平結構，與列表一致：

```
{ code, name, name_en, description, direction, base_language,
  script_code, region_code, variety_key, glottocode, origin,
  expression_count, representative_cities, mapped_expression_count }
```

不再巢狀於 `language` 鍵下。前端 `detail()` 與頁面讀取不需改動即正確。無測試覆蓋舊形狀（已確認 `backend/tests` 無相關斷言）。

### C. 詳情副標題接真實欄位

`LanguageDetail.vue` 的 `subtitle` 改由 `name_en · script_code · glottocode` 組成，例如 `Chinese (Simplified) · Hans · mand1415`。空欄位略過。

### D. 列表第三欄改為 script / 方向

`LanguageCard.vue` 以 `script_code`（如 Hans、Hant）與方向標記（`direction === 'rtl'` 時顯示 `RTL`）取代 `region_name`。後端列表已回傳 `script_code` 與 `direction`，無需改動。

### E. 詳情詞句行移除語言徽章

`ExpressionRow.vue` 新增 `showLanguage?: boolean`（預設 `true`）；`LanguageDetail` 傳 `false`，並透過 class 調整 grid 欄寬，讓文字欄展開。`Search.vue` 維持預設 `true`（搜尋結果跨語言，徽章有意義）。

### F. 列表 name / name_en 堆疊

`LanguageCard.vue` 的 `.nm`（原生名稱）與 `.en`（英文名稱）改 `display: block` 上下堆疊，原生名稱在上、英文小字 muted 在下。

## 非目標

- 不變更 `language_stats` 表或 schema。
- 不重寫頁框、StatBox、搜尋/排序工具列；沿用 `atlas.css` tokens。
- 不動 `apple/`、其他 `web/` 頁面。
- 不修補歷史資料（expression 數量即時計算即正確）。

## 驗證

- `cd web && npm run build` 通過。
- `curl /api/v2/languages` 確認 `expression_count` 非零、排序生效。
- `curl /api/v2/languages/zh-Hans` 確認扁平形狀與 `expression_count`。
- 檢查 `/languages` 與 `/language/zh-Hans` 桌面與行動 viewport。
