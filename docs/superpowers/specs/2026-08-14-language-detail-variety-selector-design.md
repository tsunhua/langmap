# 語言詳情頁：變體選擇交互與顯示優化規格

> **狀態：待實作。** 變體（Language Locale）選擇區由扁平按鈕列改為「script 分段 + 變體 chips」雙層結構，並修掉標題區的重複顯示。

**日期：** 2026-08-14
**範圍：** `web/src/pages/LanguageDetail.vue`、`web/src/locales/en.ts`、`scripts/i18n/cmn-Hant-TW.json`、`web/src/pages/LanguageDetail.test.ts`
**資料策略：** 零後端改動；前端重組顯示與交互

## 1. 摘要

語言詳情頁的變體選擇區目前是一行扁平按鈕（`全部` + 每個 locale 一個按鈕），按鈕內疊「本地名稱 + 完整代碼」兩行；同時標題區的副標題會顯示 `cmn-Hant-TW · Taiwan Mandarin`，與 badge、標題重複。本次把變體選擇改為兩層：第一層是 **script 分段控制**（全部 / 各 script），第二層是**該 script 下的變體 chips**。script 只做瀏覽組織，詞句篩選仍以具體 locale 為準（沿用現有 `?locale=` 查詢），因此**不需要任何後端改動**。

## 2. 現況與問題

```text
[← Languages]
臺灣華語(TW)            [cmn-Hant-TW]
[All cmn-Hant-TW] [華語(TW) cmn-Hant-TW] [普通话(CN) cmn-Hans-CN]
cmn-Hant-TW · Taiwan Mandarin          ← 重複顯示
[Expressions 2] [Mapped 1]
```

1. **顯示重複**：副標題 `cmn-Hant-TW · Taiwan Mandarin` 與 badge、標題重複；未選變體時副標題又變成 `cmn-Hant-TW`，與 badge 重複。
2. **扁平清單不表達結構**：變體由 `script_code × region_code × place_path` 三維組成，但按鈕看不出「這個變體在 *script* 還是 *region* 維度上不同」。對華語使用者「傳承體 vs 简体」是最有感的分野。
3. **資訊層次**：每個按鈕塞「名稱 + 完整代碼」兩行；「全部」按鈕掛著語言代碼，容易被誤認成一個變體。
4. **擴展性**：多 script × 多地區 × 地方變體時，一行扁平按鈕會變成一堵牆。
5. **無障礙**：選中狀態只有 `.on` class，沒有 `aria-pressed`；次要文字 9px 偏小。

## 3. 目標

1. 變體選擇改為雙層結構：script 分段 + 變體 chips。
2. 修掉標題區的重複顯示：副標題只在選中變體時顯示英文名。
3. 維持詞句篩選行為不變（具體 locale 篩選、`?locale=` URL 深鏈）。
4. 補上無障礙狀態（`aria-pressed`、radiogroup 語意）。
5. 零後端改動；沿用 `atlas.css` tokens，不另起視覺系統。

## 4. 非目標

- 不新增後端 script 層級篩選參數；詞句篩選仍只接受具體 locale code。
- script 選中狀態**不**同步進 URL（使用者已確認）；URL 維持只有 `?locale=`。
- 不動 `backend/`、`apple/`、`web/` 舊版頁面與其他元件。
- 不重新設計整頁視覺；只動變體選擇區與標題區。

## 5. 設計

### 5.1 版面結構

```text
[← Languages]
華語(TW)                 [cmn-Hant-TW]
Taiwan Mandarin                       ← 副標題：只選中變體時顯示英文名
[全部 | 傳承體 | 简体]                 ← script 分段；僅 >1 種 script 時出現
[華語]  [普通话]                       ← 變體 chips（主行：名稱）
[傳承體 · TW]  [简体 · CN]             ← （次行：script 名 · 地區代碼）
[Expressions 2] [Mapped 1]
[搜尋⋯]  [Popular | Latest | Alphabetical]
```

### 5.2 script 分段（第一層）

- 「全部」選項沿用現有 `languageDetail.allScripts` 文案，永遠排在第一位。
- 依 `lang.locales` 的 `script_code` 去重，並依 locale 列表順序（後端已 `ORDER BY code ASC`）穩定排列。
- **只有一種 script 時整個分段控制隱藏**，頁面退化成單層 chips（nan、eng、spa、jpn 現況即是如此）。
- 語意：選中「全部」→ 顯示所有變體 chips；選中某 script → 只顯示該 script 的變體 chips。
- script 只是**瀏覽組織**，不改變詞句篩選本身。未選中任何 chip = 顯示該語言全部詞句（與現況「全部」按鈕的 `locale=''` 等價）。
- 切換 script 時：若目前已選中的變體不屬於新 script → 清除選中（移除 `?locale=`、重新載入詞句）；若屬於，保留選中。
- 無障礙：`role="radiogroup"`，選項用 `role="radio"` + `aria-checked`（單選語意）。

### 5.3 變體 chips（第二層）

- 每個變體一個 chip，兩行：
  - 主行：`locale.name`（本地名，如 `華語`）
  - 次行：`${script 顯示名} · ${locale.region_code}`（如 `傳承體 · TW`）
- 移除現況 chip 上的完整代碼（`cmn-Hant-TW`）—— 選中後 badge 已顯示語言代碼，避免重複；地區與 script 才是「這個變體不同在哪」的結構資訊。
- 不再有獨立的「全部」按鈕；「全部」語意由 chip 全未選中表達。
- 選中：維持現況 `.on` 反白樣式，並補 `aria-pressed="true"`。
- 地區用 `region_code`（`TW`/`CN`），不使用 `regions.name_en`（`Taiwan, Province of China` 過長）。

### 5.4 script 顯示名

`scripts` 表只有 `name_en`（`Han (Traditional variant)`），不適合 chip。前端以 i18n key 提供顯示名，未知 script fallback 到 `script_code`：

| key | en | cmn-Hant-TW |
|---|---|---|
| `languageDetail.scripts.Hant` | Traditional | 傳承體 |
| `languageDetail.scripts.Hans` | Simplified | 简体 |
| `languageDetail.scripts.Latn` | Latin | 拉丁 |
| `languageDetail.scripts.Jpan` | Japanese | 日文 |

### 5.5 標題區（修掉重複）

| 狀態 | 標題 | badge | 副標題 |
|---|---|---|---|
| 未選變體 | `lang.name_en`（現況） | `lang.code`（現況） | **不顯示**（原為 `lang.code`，與 badge 重複） |
| 選中變體 | `locale.name`（現況） | `lang.code`（現況） | `locale.name_en`（原為 `code · name_en`） |

### 5.6 URL 與狀態

- 維持現況：選中變體 → `?locale=<code>`；清除 → 移除參數。
- script 選中狀態為頁內 `ref`，不進 URL；頁面重新整理後回到「全部 script + 依 `?locale=` 選中的變體」（現況行為，`normalizeLocale` 已處理）。
- 未知 locale 清理邏輯（`clearUnknownLocale`）維持。

### 5.7 響應式與樣式

- 沿用現況 `.ld-locales` 的 flex-wrap、44px 觸控目標、focus-visible、`var(--r)` 圓角與 `atlas.css` tokens。
- script 分段與 chips 兩列在窄螢幕自然換行，不做橫向捲動。
- 行動版維持「不是桌面等比縮小」原則：chip 主行完整顯示、次行必要時省略。

## 6. 檔案範圍

| 檔案 | 改動 |
|---|---|
| `web/src/pages/LanguageDetail.vue` | script 分段控制 + chips 重排、副標題邏輯、`aria-pressed`/radiogroup |
| `web/src/locales/en.ts` | 新增 `languageDetail.scripts.*` keys |
| `scripts/i18n/cmn-Hant-TW.json` | 新增對應中文翻譯（依既有 i18n 匯入流程入 DB） |
| `web/src/pages/LanguageDetail.test.ts` | 更新 chips 文字斷言、新增 script 分組與副標題斷言 |

## 7. 驗證

1. `cd web && npm run build`
2. `cd web && npm test`（`LanguageDetail.test.ts`）
3. 手動檢查桌面與行動 viewport：
   - cmn：script 分段顯示（全部 / 傳承體 / 简体），切換後 chips 換組；選中「简体」時原 `cmn-Hant-TW` 選中清除
   - nan：無 script 分段，只有 chips
   - 選中變體 → 副標題顯示英文名且不含代碼；未選 → 無副標題
   - `?locale=cmn-Hant-TW` 深鏈維持正常
