# 2026-08-13 全棧穩定化：執行進度與基線

> 本檔記錄 [`plans/2026-08-13-full-stack-stabilization.md`](./2026-08-13-full-stack-stabilization.md) 的執行進度、基線量測與已關閉缺口。僅含本輪真實執行結果，不預設未完成工作內容。

## 環境基線

| 項目 | 值 |
|---|---|
| Node | v22.20.0 |
| npm | 10.9.3 |
| Python | 3.9.6 |
| Wrangler | 4.114.0（本地 workerd 支援最新 compatibility date `2026-07-29`） |
| 分支 | `feat/20260725/langmap_v2` |

## 驗證命令集結果（候選最終版本）

| 命令 | 結果 |
|---|---|
| `python3 -m unittest discover -s scripts/db/tests -p 'test_*.py'` | 62 passed ✅ |
| `./scripts/db/manage.sh local rebuild` | rebuilt ✅ |
| `./scripts/db/manage.sh local verify` | ok；9 migrations；schema 無缺漏；counts {languages 7856, scripts 226, regions 249} ✅ |
| `cd web && npm test` | 153 passed ✅ |
| `cd web && npm run i18n:check` | passed（317 keys）✅ |
| `cd web && npm run build` | vue-tsc + vite build OK ✅ |
| `cd backend && npm test` | 199 passed ✅（含串行整合測試） |
| `cd backend && npm run types:check` | up to date ✅ |
| `cd backend && npx wrangler deploy --dry-run` | 755.86 KiB / gzip 125.63 KiB ✅ |
| `./build.sh` | web → backend/public 成功 ✅ |
| `git diff --check` | clean ✅ |

## 已關閉缺口（本輪提交）

| Commit | 範圍 | 缺口 |
|---|---|---|
| `65c1558` | DB / Task 2 | migration-lock 補登 `0008_restore_handbooks`，並新增「repo migrations 須與 committed lock 一致」測試 |
| `0b17ce9` | API / Task 3 | 詞句搜尋、語言列表與語言詞句列表的穩定排序契約（hot/new/alpha、count/alpha）與 `mapped_expression_count` |
| `72665a8` | Worker / Task 7 | 採用 Wrangler 生成 binding 型別、移除版本化 `SECRET_KEY`、compatibility date 校準為 `2026-07-29`、啟用 sampled traces、新增 `types:check` 與 config 回歸測試 |
| `6127025` | Web / Task 4–6 | 核心流程的 loading/empty/error 狀態與競態防護，及頁面/元件級回歸覆蓋（含修補 4 項在途測試與型別問題） |
| `9d4509a` | API / Task 3 | 詞句詳情 500→404 修復（`getExpression` LEFT JOIN sources 造成 `id` 欄位歧義）；整合測試改用分頁 `/edges` 取代圖譜 `/mappings` |
| `a74058a` | DB / Task 3 | 補種 Min Nan 的裸碼代表 locales（`nan-Hant-CN`、`nan-Hant-TW`），對齊 eng/cmn 慣例，修復 create/attestation `INVALID_LANGUAGE_LOCALE_CODE` |

### 原有 5 項既有整合測試失敗（已全部關閉）

| 失敗 | 根因 | 修復 |
|---|---|---|
| `expressionsIntegration` missing expression → 500 | `getExpression` 詳情查詢 LEFT JOIN sources 但未以 `e.` 限定欄位，`id` 歧義導致 SQL 拋例、路由無 try/catch 回 500 | 以 `e.` 限定欄位；missing 現回 404 envelope |
| `expressionsIntegration` create with attestation → 400 | 裸碼 `nan-Hant-CN` 未種子（seed 僅有 place-qualified nan locales） | 補種裸碼 locale |
| `expressionsIntegration` attestation dedup → 400 | 裸碼 `nan-Hant-TW` 未種子 | 補種裸碼 locale |
| `localizationIntegration` vote → `data.items` undefined | 測試 GET `/mappings`（圖譜端點）卻期待分頁清單 | 改 GET `/edges` |
| `mappingsIntegration` list → `data.total` undefined | 同上 | 改 GET `/edges` |

## 受限驗證與剩餘風險

- 本地 workerd 最新支援 `2026-07-29`；`wrangler.jsonc` compatibility date 據此校準。待更新 wrangler 版本附帶支援更新日期的 workerd 後再行調整（已記錄於 `wranglerConfig.test.ts` 註釋）。
- `SECRET_KEY` 改由 `.dev.vars` 提供；已 gitignore，未提交。
- 瀏覽器驗收使用本機系統 Chrome（`channel:'chrome'`）以無頭模式執行；第三方地圖圖磚（MapLens/Leaflet）屬受限驗證，未納入 same-origin 失敗判定。
- 未連接、遷移或部署任何遠端／production 資源；Wrangler 僅 local 操作與 dry-run。

## Task 8：瀏覽器驗收（已完成）

以 Playwright + 系統 Chrome 無頭驗收，涵蓋桌面 1440×900 與行動 390×844、鍵盤流程與 `prefers-reduced-motion`，每輪檢查 console error、未處理例外、same-origin request 失敗與頁面級水平溢出。

**結果：22/22 OK。** 匿名路由（`/`、`/search`、`/languages`、`/language/nan`、`/mapping/:id`、`/handbooks`、`/translate`、`/map`→`/`、`/auth`、404）在兩 viewport 均無 console error、無 same-origin 失敗、無水平溢出；鍵盤可完成搜尋；reduced-motion 下詞句圖譜無錯誤。

驗收發現並修復 3 項缺陷（commit `890193e`）：

| 缺陷 | 根因 | 修復 |
|---|---|---|
| 匿名訪問 `/translate` 觸發 401 並 hard-redirect 至 `/auth` | 路由無 auth guard；client 401 攔截器 hard-redirect；頁面 `onMounted` 無條件呼叫需鑑權的 workbench API | `load()` 改以 `auth.isLoggedIn` 把關；登入提示上提至 workbench 區塊外（原本位於永不載入的 workbench 區塊內，匿名看到空白無回饋狀態） |
| HomeFeed 首次載入 `/favicon.ico` 404（僅桌面首次頁出現，瀏覽器快取） | 無 favicon link，瀏覽器自動請求 | `index.html` 加 `<link rel="icon" href="data:,">` 抑制請求 |
| （回歸覆蓋） | 缺匿名路徑測試 | 新增「匿名不呼叫 workbench API 且顯示登入提示」測試 |

