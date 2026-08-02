# 華語內容標籤遷移設計：zh-* → cmn-*

日期：2026-08-02
範圍：`scripts/v2/language_seed_profiles.json`、`backend/migrations/`、`scripts/i18n/`、`web/src/locales/`、相關測試。

## 背景與問題

現況三個互相纏繞的缺陷：

1. **content tag 不精確**：`languages` 以 `zh-Hans` / `zh-Hant` 標註華語詞句（共 523 條 expressions），但 `zh` 是 IANA macrolanguage，涵蓋粵（`yue`）、閩南（`nan`）、客家（`hak`）、吳（`wuu`）。兩列的 `variety_key` 皆為 `glotto:mand1415`（Mandarin Chinese），實際只是華語。

2. **顯示名與範圍衝突**：`zh-Hant` 的 `name` 為「中文」，是涵蓋全體漢語的上位概念，卻綁定單一 Mandarin languoid。

3. **代表城市語意錯置**：`glotto:mand1415` 掛有 Hong Kong。該地口語為粵語，`yue-Hant` 已正確持有 Hong Kong 與 Macau 兩點。此為既有錯誤，與本次遷移一併修正。

規格 `2026-07-26-language-codes-and-community-ui-i18n.md:152` 早已要求華語內容使用 `cmn-Hant-TW` 對應 `glotto:mand1415`，實作未跟上。IANA 註冊表確認 `cmn` 為正式 language subtag（`language|cmn|["Mandarin Chinese"]`），`zh` 為其 macrolanguage prefix。

## 決策

`zh-*` 前綴在 **content tag 與 UI locale 兩層皆廢除**，統一改用 `cmn-*`。

UI locale 層額外需要入站別名映射，原因：瀏覽器 `Accept-Language` 與 `navigator.language` 只會送出 `zh-TW`、`zh-Hant`、`zh-CN` 等，永不送 `cmn-*`。若 `available` 僅剩 `cmn-Hant`，`resolveLocale` 的 fallback chain 無法命中，中文使用者將全部落到 `en`。

此決策偏離既有規格 L159（UI locale 沿用 `zh-Hant-TW` 生態系慣例），該行需同步更新。

## 設計

### A. 資料源：seed profiles

`scripts/v2/language_seed_profiles.json`：

- `languages`：`zh-Hans` → `cmn-Hans`（name「华语」，name_en「Mandarin Chinese (Simplified)」）；`zh-Hant` → `cmn-Hant`（name「華語」，name_en「Mandarin Chinese (Traditional)」）。`glottocode` 維持 `mand1415`。兩者新增 `alternate_names` 欄位收容各政體自稱。
- `online_code_migrations.mappings`：既有四筆 `zh-Hans-CN` / `zh-Hant-TW` / `zh-Hant-HK` / `zh-Hant-MO` 的 canonical 改指 `cmn-*`；另新增 `zh-Hans` → `cmn-Hans`、`zh-Hant` → `cmn-Hant` 兩筆 `canonicalize`。舊 code 必須留在 mappings，否則 `language_migration.validate_manifest` 報 unmapped observed codes。多筆映射到同一 canonical 需全部為 `canonicalize` action。
- `locations`：新增 Singapore（Hans），移除 `glotto:mand1415` 的 Hong Kong。結果為 Beijing、Singapore（Hans）與 Taipei（Hant）。

兩者主名皆用「華語／华语」，只差字形。此名稱選擇的理由是**自稱軸線綁政體，不綁字形**：

| 政體 | 字形 | 通行自稱 |
|---|---|---|
| 中國大陸 | 簡體 | 普通话 |
| 新加坡 | 簡體 | 华语 |
| 馬來西亞華人 | 簡體 | 华语 |
| 臺灣 | 繁體 | 國語 / 華語 |

`cmn-Hans` 同時涵蓋大陸與新加坡（其代表城市正是 Beijing 與 Singapore），因此不能命名為「普通话」—— 那專指大陸標準語，會對新加坡使用者貼錯標籤。「华语」是跨政體的中性自稱，新加坡官方「講華語運動」即用此名，大陸亦通用。

兩者皆不用「中文」，因為那是涵蓋粵、閩、客、吳的上位概念。

### A2. alternate_names 收容各政體自稱

主名取中性稱法會丟失「普通话」、「國語」等實際通行的自稱，因此一併寫入 `alternate_names_json`：

- `cmn-Hans`：`["普通话", "国语", "汉语"]`
- `cmn-Hant`：`["國語", "漢語"]`

`sync_language_registry.py:313` 目前硬編碼 `"alternate_names_json": "[]"`，需改為讀取 seed 的 `alternate_names` 欄位並以 `json.dumps(..., ensure_ascii=False, separators=(",", ":"))` 序列化，缺欄位時維持 `[]`。此變更對其他語言條目無影響（皆未提供該欄位）。

`ui_locales.native_name` 現為「简体中文」/「繁體中文」，同步改為「华语」/「華語」，與 `languages.name` 一致。

### B. 資料庫 migration

新增 `backend/migrations/0015_migrate_mandarin_content_tags.sql`，以 `0012_canonicalize_language_content_profiles.sql` 為結構範本，該檔已完成同型遷移。必要步驟：

1. `PRAGMA defer_foreign_keys = ON`。
2. temp table 記錄 `zh-Hans` → `cmn-Hans`、`zh-Hant` → `cmn-Hant`。
3. `INSERT OR IGNORE INTO languages` 先建立 canonical 目標列，再搬 FK 引用。
4. `INSERT ... ON CONFLICT` 合併 `ui_locales`，並更新指向舊 code 的 `fallback_code`。
5. `UPDATE expressions SET language_code`（523 條）。
6. 重算 `language_stats`。
7. `DELETE FROM languages` 舊 code。
8. 收尾以 temp table + `CHECK (ok = 1)` 驗證：無殘留舊 code、`pragma_foreign_key_check` 為空。

`language_locations` 不含 `language_code`，其關聯是 `variety_key` 軟關聯，不需在 migration 處理；城市移除由 registry SQL 重新產製後套用。

注意 `ui_locales.code REFERENCES languages(code)`，且 DB 現有 `zh-Hans` / `zh-Hant` 兩列 UI locale，必須在刪除 `languages` 舊列前完成搬遷。

### C. UI locale 別名層

`web/src/locales/index.ts` 的 `resolveLocale` 加入 macrolanguage 別名解析，在既有 exact match 之後、fallback chain 之前套用：

- `zh-Hant`、`zh-TW`、`zh-HK`、`zh-MO`、`zh-Hant-*` → `cmn-Hant`
- `zh-Hans`、`zh-CN`、`zh-SG`、`zh-Hans-*` → `cmn-Hans`
- 裸 `zh` → `cmn-Hans`

別名只作用於入站解析，不進入 `available`，也不寫入 `localStorage`；儲存與 `document.documentElement.lang` 一律為 canonical `cmn-*`。

### D. i18n 資源檔

- `scripts/i18n/zh-Hant-TW.json` → `cmn-Hant.json`，`zh-Hans-CN.json` → `cmn-Hans.json`。
- `generate-bundle.py:21-22` 的 bundle code 映射、`generate-i18n-sql.py:7,271` 的路徑、`README.md:6-7,29-30,67` 的說明同步更新。
- `scripts/i18n/artifacts/` 需重新產製。

### E. 既有 migration 檔的處理

`0007_seed_first_party_ui_locales.sql` 與 `0008` 引用 `zh-Hant-TW` / `zh-Hans-CN`。**不修改已套用的歷史 migration**，改由新 migration 承接最終狀態，避免既有部署的 migration 校驗不一致。

### F. 測試更新

- `scripts/v2/test_language_data.py:338,346,432,447,462,465`：預期 code 集合改 `cmn-*`。
- `scripts/v2/test_language_data.py`：新增一項斷言，驗證 seed 的 `alternate_names` 會寫入 `alternate_names_json`（`cmn-Hans` 應含「普通话」），並確認未提供該欄位的語言仍為 `[]`。
- `backend/tests/languageCode.test.ts:8-9`：`parseStoredLanguageCode` 案例改 `cmn-Hant-TW` → language `cmn`。
- `backend/tests/localization.test.ts:7`：`parentLocaleCodes('cmn-Hant-TW')` 應為 `['cmn-Hant', 'cmn']`。其餘 `locale_code` 夾具改 `cmn-Hant` / `cmn`。
- `web/src/locales/index.test.ts`：新增別名解析案例（`zh-hant-tw` → `cmn-Hant`）。
- `web/src/stores/localization.test.ts`、`web/src/pages/Contribute.test.ts`、`web/src/pages/TranslateWorkbench.language.test.ts` 的 `zh-Hans` 夾具改 `cmn-Hans`。

## 非目標

- 不改動 `yue`、`nan`、`hak`、`wuu`、`hsn`、`cdo`、`mnp` 等其他漢語系條目。
- 不移除 `und`、`x-emoji`、`x-image` 等 system base。
- 不調整 `language_locations` 的「探索起點」定位（`migrations/0011` 註解）。
- 不引入 `zh` 作為 UI locale 選項供使用者主動選擇。

## 驗證

- `cd scripts/v2 && python3 -m unittest test_language_data`
- `cd backend && npm test`（需先啟動 `127.0.0.1:8788`）
- `cd web && npm run build` 與 `npx vitest run`
- `sqlite3 $DB "SELECT code FROM languages WHERE code LIKE 'zh%'"` 應為空
- `sqlite3 $DB "SELECT language_code, COUNT(*) FROM expressions WHERE language_code LIKE 'cmn%' GROUP BY 1"` 應為 `cmn-Hans|262`、`cmn-Hant|261`
- `curl /api/v2/languages/cmn-Hant` 代表城市應僅 Taipei
- `curl /api/v2/languages/cmn-Hans` 代表城市應為 Beijing、Singapore
- `sqlite3 $DB "SELECT alternate_names_json FROM languages WHERE code='cmn-Hans'"` 應含「普通话」

## 回退

新 migration 為單向。回退需以反向 mapping 撰寫新 migration，並還原 seed 與 i18n 檔名。因 `cmn-*` 與 `zh-*` 為一對一映射，反向操作無資料損失。
