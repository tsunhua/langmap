# 語言詳情頁：變體選擇交互與顯示優化規格

> **狀態：待實作。** 變體（Language Locale）選擇區由扁平按鈕列改為「連動雙下拉」（變體 × 其他），並修掉標題區的重複顯示、把 locale 名稱修正為純名稱。

**日期：** 2026-08-14
**範圍：** `web/src/pages/LanguageDetail.vue`、`web/src/locales/en.ts`、`scripts/i18n/cmn-Hant-TW.json`、`web/src/pages/LanguageDetail.test.ts`、`backend/migrations/0013_*.sql`、`backend/schema.sql`
**資料策略：** 一筆資料修正 migration（locale `name` 純名稱）+ 前端重組顯示與交互

## 1. 摘要

語言詳情頁的變體選擇區目前是一行扁平按鈕（`全部` + 每個 locale 一個按鈕），按鈕內疊「本地名稱 + 完整代碼」兩行；同時標題區的副標題會顯示 `cmn-Hant-TW · Taiwan Mandarin`，與 badge、標題重複。本次把變體選擇改為**兩個連動的原生下拉**：左邊是「變體」維度（script，如 傳承體/简体），右邊是「其他」維度（如 `TW`/`CN`）。選項由 `lang.locales` 動態切分「語言 · 變體 · 其他」三維，不寫死「地區」語意。詞句篩選仍以具體 locale 為準（沿用現有 `?locale=` 查詢），**不需要任何後端 API 改動**。

## 2. 現況與問題

```text
[← Languages]
Mandarin Chinese        [cmn]
[全部 cmn] [華語(TW) cmn-Hant-TW] [普通话(CN) cmn-Hans-CN]
cmn-Hant-TW · Taiwan Mandarin          ← 重複顯示
[Expressions 2] [Mapped 1]
```

1. **顯示重複**：副標題 `cmn-Hant-TW · Taiwan Mandarin` 與 badge、標題重複；未選變體時副標題又變成 `cmn-Hant-TW`，與 badge 重複。
2. **扁平清單不表達結構**：變體由 `script_code × region_code × place_path` 多維組成，但按鈕看不出「這個變體在 *script* 還是 *region* 維度上不同」。對華語使用者「傳承體 vs 简体」是最有感的分野。
3. **資訊層次**：每個按鈕塞「名稱 + 完整代碼」兩行；「全部」按鈕掛著語言代碼，容易被誤認成一個變體。
4. **名稱內含結構**：seed 的 locale `name` 是 `華語(TW)`/`普通话(CN)`/`閩南語（臺灣）` 這類帶後綴名稱，等於把 script/region 結構硬塞進顯示名；改為純名稱後，結構資訊由選擇器承擔。
5. **擴展性**：多 script × 多地區 × 地方變體時，一行扁平按鈕會變成一堵牆。

## 3. 目標

1. 變體選擇改為連動雙下拉：左「變體」（script）、右「其他」（動態切分自 locales）。
2. 修掉標題區的重複顯示：副標題只在選中變體時顯示英文名。
3. 資料修正：locale `name` 改純名稱（資料層，非顯示層剝離）。
4. 維持詞句篩選行為不變（具體 locale 篩選、`?locale=` URL 深鏈）。
5. 補上無障礙（隱藏 label、focus-visible、44px 觸控目標）。
6. 零後端 API 改動；沿用 `atlas.css` tokens，不另起視覺系統。

## 4. 非目標

- 不新增後端 script/region 層級篩選參數；詞句篩選仍只接受具體 locale code。
- 下拉狀態**不**進 URL；URL 維持只有 `?locale=`。
- 不動 `backend/` 的 API 邏輯、`apple/`、`web/` 舊版頁面與其他元件。
- 不重新設計整頁視覺；只動變體選擇區與標題區。
- 不做自訂 combobox；用原生 `<select>`（行動版原生體驗、零 JS 依賴）。

## 5. 設計

### 5.1 版面結構

```text
[← Languages]
華語                     [cmn-Hant-TW]
Taiwan Mandarin                       ← 副標題：只選中變體時顯示英文名，不含代碼
[全部變體 ▾]  [TW ▾]                  ← 連動雙下拉（無視覺 label；label 隱藏給螢幕閱讀器）
[Expressions 2] [Mapped 1]
[搜尋⋯]  [Popular | Latest | Alphabetical]
```

- 桌面：兩下拉並排；行動版（≤640px）垂直堆疊、全寬。
- 下拉按鈕文字自明（「全部變體」「全部」是下拉內的選項文字，不是外掛提示）。

### 5.2 維度切分（語言 · 變體 · 其他）

從 `lang.locales` 動態切分，不寫死「地區」語意：

- **變體維度** = `script_code`（如 `Hant`/`Hans`/`Latn`/`Jpan`），去重後依 locales 順序（後端 `ORDER BY code ASC`）穩定排列。
- **其他維度** = locale code 中 script 之後的剩餘部分，目前實質為 `region_code`（`TW`/`CN`/`US`/`ES`/`JP`）；未來有 `place_path` 時以 `${region_code}/${place_path}` 表達。
- 左下拉第一項「全部變體」（`value=''`）；右下拉第一項「全部」（`value=''`），其餘為該維度去重後的值。

### 5.3 連動行為

- 左下拉選擇某變體 → 右下拉只保留該變體下有的「其他」值。
- 若右下拉目前的值不在新候選內 → 重置為「全部」。
- 若候選只剩一個非「全部」值 → **自動選上**（例如 cmn 選「傳承體」→ 右邊只剩 `TW`，自動選中 → 標題立刻變「華語」）。
- 完整選中（兩邊都非「全部」）→ 解析出唯一 locale code → 寫入 `?locale=`；任一邊是「全部」→ 移除參數（不篩選）。
- **只有一種變體時左下拉隱藏**（nan、eng、spa、jpn 現況），只剩右下拉。
- 深鏈（`?locale=cmn-Hans-CN`）→ 反向設定兩下拉值；未知 locale 沿用 `clearUnknownLocale` 清理。

### 5.4 script 顯示名

`scripts` 表只有 `name_en`（`Han (Traditional variant)`），不適合下拉。前端以 i18n key 提供顯示名，未知 script fallback 到 `script_code`：

| key | en | cmn-Hant-TW |
|---|---|---|
| `languageDetail.scripts.Hant` | Traditional | 傳承體 |
| `languageDetail.scripts.Hans` | Simplified | 简体 |
| `languageDetail.scripts.Latn` | Latin | 拉丁 |
| `languageDetail.scripts.Jpan` | Japanese | 日文 |

下拉選項文字格式：`${script 顯示名} (${script_code})`（如 `傳承體 (Hant)`）。

### 5.5 標題區（修掉重複）

| 狀態 | 標題 | badge | 副標題 |
|---|---|---|---|
| 未選變體 | `lang.name_en`（現況） | `lang.code`（現況） | **不顯示**（原為 `lang.code`，與 badge 重複） |
| 選中變體 | `locale.name`（純名稱） | **`locale.code`**（如 `cmn-Hant-TW`；原為 `lang.code`） | `locale.name_en`（原為 `code · name_en`） |

### 5.6 資料修正（migration）

locale `name` 由帶後綴名稱改為純名稱；`name_en` 不變：

| code | 現 name | 新 name | name_en（不變） |
|---|---|---|---|
| `eng-Latn-US` | `English (US)` | `English` | `English (US)` |
| `cmn-Hant-TW` | `華語(TW)` | `華語` | `Taiwan Mandarin` |
| `cmn-Hans-CN` | `普通话(CN)` | `普通话` | `Simplified Chinese` |
| `nan-Hant-CN` | `閩南語(CN)` | `閩南語` | `Min Nan Chinese (China)` |
| `nan-Hant-TW` | `閩南語（臺灣）` | `閩南語` | `Min Nan Chinese (Taiwan)` |
| `spa-Latn-ES` | `Español (España)` | `Español` | `Spanish (Spain)` |
| `jpn-Jpan-JP` | `日本語（日本）` | `日本語` | `Japanese (Japan)` |

- 新 migration `0013_*`：7 筆 `UPDATE`。
- `backend/schema.sql` seed 同步更新（`INSERT OR IGNORE` 的 name 值需與 migration 結果一致，避免新環境不一致）。
- 已知取捨：nan 兩地名的 name 相同，語言列表（`LanguageCard`）與其他未進詳情頁的顯示無法以文字區分 `TW/CN`；詳情頁內由右下拉的 `TW`/`CN` 值區分。

### 5.7 響應式與樣式

- 沿用現況 `.ld-locales` 區塊位置、`atlas.css` tokens（`--border`/`--r`/`--mono`/`--surface`/`--fg`）。
- select：`min-height: 44px`、`appearance: none`、自訂 chevron（CSS border 旋轉）、`focus-visible` outline、hover 邊框加深。
- 行動版（≤640px）：垂直堆疊、全寬；維持 44px 觸控目標。

## 6. 檔案範圍

| 檔案 | 改動 |
|---|---|
| `web/src/pages/LanguageDetail.vue` | 扁平按鈕列 → 連動雙下拉、副標題邏輯、隱藏 label、移除 `allScripts`/`scriptLabel` 用法 |
| `web/src/locales/en.ts` | 移除 `allScripts`/`scriptLabel`；新增 `variantLabel`/`otherLabel`/`allVariants`/`allOthers`/`scripts.*` |
| `scripts/i18n/cmn-Hant-TW.json` | 移除 `allScripts`/`scriptLabel`；新增對應中文翻譯 |
| `web/src/pages/LanguageDetail.test.ts` | 更新為下拉斷言、純名稱 fixture、連動行為斷言 |
| `backend/migrations/0013_pure_locale_names.sql` | 7 筆 name `UPDATE` |
| `backend/schema.sql` | seed 名稱同步為純名稱 |

## 7. 驗證

1. `cd backend && npm test`（既有測試不受 name 影響）
2. `cd web && npm run build`
3. `cd web && npm test`（`LanguageDetail.test.ts`）
4. 手動檢查桌面與行動 viewport：
   - cmn：兩下拉並排（行動堆疊）；選「傳承體」→ 右邊只剩 `TW` 自動選上；標題「華語」、副標題 `Taiwan Mandarin`
   - nan：左下拉隱藏，只剩右下拉；選 `TW`/`CN` 標題皆「閩南語」
   - 未選 → 標題 `Mandarin`、無副標題、badge `cmn`
   - 選中 → badge 為完整 locale code（`cmn-Hant-TW`）
   - `?locale=cmn-Hans-CN` 深鏈 → 兩下拉反向同步、標題「普通话」
