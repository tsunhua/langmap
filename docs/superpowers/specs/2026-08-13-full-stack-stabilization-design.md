# LangMap 主線全棧穩定化設計規格

**日期：** 2026-08-13  
**狀態：** 待實作  
**範圍：** `web/`、`backend/`、本地 D1、`scripts/` 與直接相關文件

## 1. 背景

LangMap 主線目前由 Vue 3 Web、Hono Cloudflare Worker、D1 與資料維護腳本組成。近期已完成語言代碼、詞句身份、映射、地域佐證、讀音、介面在地化及偏好設定等多輪改造；本輪不再擴張產品功能，而是以目前磁碟上的實作為準，完成一次可重複、具證據的本地全棧啟動、品質補強與回歸驗證。

現況體檢已確認：

- Git 工作區在設計開始時乾淨，主線分支與遠端對齊。
- `web/` 已具備 Vitest、Vue Test Utils、型別檢查、i18n 檢查與 Vite build。
- `backend/` 已具備服務單元測試、Worker 整合測試與 schema contract 測試；整合測試依賴 `127.0.0.1:8788` 與共用本地 D1，必須串行執行。
- `scripts/db/tests/` 已覆蓋 migration lock、fingerprint、重建交換、安全清理、production 防護與驗證流程。
- 後端核心領域的自動化覆蓋較完整；前端主要集中在映射圖與少數語言元件，多個完整頁面與跨頁流程仍缺少直接測試。
- 倉庫存在獨立 `apple/` SwiftUI 客戶端；本輪明確排除。

## 2. 目標

1. 從乾淨的本地狀態可靠重建 D1，並以單一入口完整啟動 Vite 與 Worker。
2. 執行所有現有且可在本地重複的靜態檢查、單元測試、整合測試、資料庫驗證、構建與瀏覽器驗收。
3. 修復由失敗紀錄、執行期錯誤、效能證據、無障礙檢查或瀏覽器觀察證實的問題。
4. 為每項目前已實作的核心功能建立明確測試證據，補齊高風險空白，但不追求與產品風險無關的行數覆蓋率。
5. 保持 API、資料模型、視覺系統與本地開發入口一致；讓後續開發者能依文件重現驗證結果。

## 3. 非目標

- 不修改或測試 `apple/`。
- 不連接、遷移、寫入或部署任何遠端／production Cloudflare 資源。
- 不新增產品功能，不實作舊 PRD 中尚未落地的收藏、匯出等項目。
- 不做無量測依據的大型重構、資料模型重設或主要依賴版本升級。
- 不以消除所有相依套件警告為由改變產品行為；安全問題需按可利用性與影響分級處理。
- 不手動修改 `web/dist/`、`backend/public/` 或 `.wrangler/` 內容。

## 4. 設計原則

### 4.1 證據驅動

每項程式修改至少對應下列一種證據：

- 可重複的測試、型別檢查、構建或啟動失敗；
- 瀏覽器 console、network、版面或鍵盤操作錯誤；
- 可重現的資料一致性、權限、排序、分頁、循環或重複問題；
- 可量測的 bundle、請求、渲染或 D1 查詢問題；
- 明確違反本專案規範或 Cloudflare Workers 生產規範的高風險做法。

只有程式風格偏好、未證實的效能猜測或與本輪目標無關的重構，不構成修改理由。

### 4.2 外部契約優先

- 保留 `Vue 3 → /api/v2 → Hono Worker → 本地 D1` 資料流。
- 一般 API 回應維持 `{ success, data?, error?, message? }`。
- 前端請求統一經 `web/src/api/client.ts`，不得另寫 base URL。
- schema 若因實際缺陷必須調整，需同時新增 migration、更新 `backend/schema.sql`、migration lock、型別與契約測試，並說明回退方式。
- 查詢、圖遍歷與佈局需維持穩定排序，並處理循環、重複、分頁與數量上限。

### 4.3 最小而可回歸的修改

先以失敗測試或最小重現鎖定問題，再修改最接近原因的模組。資料問題回到來源、匯入腳本、migration 或 service 修正；不得在頁面硬編碼例外。每批修正完成後先跑相關測試，再進入全量回歸。

## 5. 執行架構

### 5.1 階段 A：建立不可修改的基線

在修正前記錄：

- Node、npm、Python、Wrangler 版本；
- Git 狀態及現有生成目錄狀態；
- Web 測試、i18n 檢查、型別檢查與 build 結果；
- DB 腳本單元測試、migration lock 與本地 D1 status；
- Worker 整合測試的先決條件與既有失敗；
- Vite build 各輸出檔案的原始大小與 gzip 大小；
- 本地啟動時間、瀏覽器 console/network 錯誤及核心頁面可用性。

基線失敗不得直接改成忽略、跳過或降低斷言；必須先判斷是產品缺陷、測試缺陷、環境缺陷或過時文件。

### 5.2 階段 B：本地資料與完整啟動

1. 執行 DB 腳本測試，確認安全防護有效。
2. 使用 `scripts/db/manage.sh local status` 判斷 fingerprint。
3. 本輪已獲准在必要時執行 `local rebuild`；重建只作用於 repo 專屬本地 D1 狀態。
4. 執行 `local verify`，確認 migration、schema、registry、seed 與索引一致。
5. 透過 `./dev.sh` 啟動 Worker 與 Vite，使用獨立執行 session 保持服務存活。
6. 驗證 `http://127.0.0.1:8788/api/v2` 相關 API、`http://localhost:5173`、Vite `/api/v2` proxy、SPA 路由與服務停止清理。

任何端口占用、殘留 pid、secret 缺失或 bootstrap 失敗，都需提供可操作訊息，且不得誤殺其他 repo 的程序。

### 5.3 階段 C：定向修正與覆蓋補齊

修正順序按風險排列：

1. 資料遺失、安全、權限或遠端誤操作風險；
2. schema、API 契約、核心資料流與啟動阻斷；
3. 使用者可見的錯誤、無回饋狀態及不可操作流程；
4. 穩定排序、分頁、重複、循環與競態；
5. 無障礙、行動版溢出與鍵盤操作；
6. 經量測確認的 bundle、渲染、請求或查詢效能問題；
7. 與實際行為不符的必要文件。

每項缺陷先增加或收緊能重現缺陷的測試；只有純文件、無法穩定自動化的瀏覽器相容性或工具鏈環境問題可用明確手動重現取代。

### 5.4 階段 D：全量回歸

完成所有自動化驗證後，以匿名使用者、一般登入使用者及管理員權限覆蓋關鍵流程，再檢查桌面與行動 viewport、鍵盤操作、console、network、資料持久化及重新整理行為。最後執行整體 build 與 Wrangler dry-run；dry-run 只驗證打包，不得發布。

## 6. 核心功能測試矩陣

「核心功能已測試」定義為：每個下列領域至少有一項可重複的自動化測試證明主要成功路徑與關鍵拒絕路徑；具使用者介面的領域另需真實瀏覽器驗收。既有測試可作為證據，缺少的情境才新增測試。

| 領域 | 必測核心行為 | 自動化層級 | 瀏覽器驗收 |
|---|---|---|---|
| 本地啟動與程序生命週期 | fingerprint hit/miss、強制重建、bootstrap 失敗阻止啟動、port 傳遞、只清理本 repo 程序 | Python 單元／腳本整合 | 首頁與 API 同時可用；停止後兩個服務均退出 |
| Migration 與本地 D1 | migration 順序與 checksum、lock 防竄改、原子重建、失敗回復、schema/seed/index/registry 驗證 | Python 單元＋schema contract＋本地 verify | 不適用 |
| App shell、路由與 404 | 所有 router entry 可解析、`/map` redirect、未知路徑 404、導覽與 scroll 行為不崩潰 | Router／元件測試 | 直接開啟及重新整理主要路由均成功 |
| 認證與權限 | 註冊、登入、目前使用者、登出／token 清除、未登入拒絕、一般使用者與管理員權限差異 | Backend 整合＋Pinia／頁面測試 | 註冊或登入後導覽更新；受限操作具有正確回饋 |
| 首頁動態 | `hot`／`new` 穩定排序、載入、空白與錯誤狀態、卡片導覽 | Backend 整合＋頁面測試 | 桌面與行動版切換排序並進入詞句頁 |
| 搜尋 | 空查詢、文字搜尋、語言篩選、分頁／載入更多、無結果、載入更多失敗保留既有結果 | Backend 整合＋頁面測試 | 輸入、篩選、載入更多與結果導覽 |
| 語言參照與語言列表 | ISO language/script/region 查詢、只列有內容語言、搜尋、分頁與穩定順序 | Service／Backend 整合＋API／頁面測試 | 語言列表搜尋與卡片導覽 |
| 語言詳情與地域形式 | 大小寫 code、地域形式與座標來源、詞句列表、script query、搜尋、排序、空白／錯誤 | Service／Backend 整合＋頁面測試 | 切換 script、搜尋詞句、代表城市與長文字不溢出 |
| 地域形式建立 | code grammar、參照存在性、來源、重複衝突、認證、結構化表單與 server 回傳 code | Service／Backend 整合＋元件測試 | 建立對話框鍵盤操作、驗證錯誤及成功採用回傳值 |
| 詞句 | canonicalization、穩定 ID、建立／重用、未知語言、空文字、詳情、404、地域佐證與來源去重 | Service／Backend 整合＋API 測試 | 詞句詳情載入、證據顯示與新增成功／失敗回饋 |
| 讀音標記 | scheme/value 驗證、地域形式、來源、去重、缺少詞句、認證 | Service＋Backend 整合＋元件測試 | 證據列表穩定分組並顯示讀音 |
| 映射與圖譜 | 建邊／去重、鄰居排序、1–3 hops、循環、跨邊、折疊、佈局穩定、拖曳、縮放、節點選取、列表替代 | Service／Backend 整合＋模型／元件測試 | 桌面圖譜及行動列表、跳數、全螢幕、鍵盤與導航 |
| 讚／踩 | 認證、值域、首次投票、翻轉、不重複計分、未知目標 | Backend 整合＋元件測試 | 票數與狀態即時更新，失敗可見且不偽造成功 |
| 同形拆分 | 僅管理員、空 edge、非相鄰 edge、搬移而非複製、audit、revision 更新 | Service＋Backend 整合＋對話框測試 | 警告、選取限制、提交狀態與完成後重新載入 |
| 批次貢獻 | 至少兩個詞句、完整 clique、重複 pair 重用、認證、地域形式輸入 | Backend 整合＋頁面測試 | 新增／移除列、驗證、成功導向及錯誤回饋 |
| 手冊 | 公開列表、搜尋、hot/new、詳情、私人權限、建立、編輯、章節與詞句排序、刪除、作者／管理員權限 | Backend 整合＋頁面／元件測試 | 建立至檢視完整流程、編輯排序、詞句 inspector 與錯誤狀態 |
| 地圖鏡頭 | 地域座標載入、缺座標資料、marker、選取相關詞句、route id 更新與 Leaflet 清理 | 頁面測試（mock Leaflet） | 地圖載入、marker 導覽、無座標／網路錯誤替代內容 |
| 介面在地化 | locale 列表、訊息 fallback、primary/secondary 偏好、匿名持久化、登入同步、方向與 `<html lang>` | Domain／Backend 整合＋store／元件測試 | 切換語系、重新整理持久化、fallback 與鍵盤選擇 |
| 翻譯工作臺 | 建立 draft locale、分頁／搜尋、candidate、覆蓋率、提交 mapping、自動／手動啟用、archive 權限與 system lock | Domain／Backend 整合＋頁面測試 | 選擇 locale、編輯、dirty 計數、提交、失敗回饋與狀態刷新 |
| API 錯誤契約 | 400/401/403/404/409/500 envelope 一致；500 不洩漏例外、SQL、secret 或 token | Helper／Backend 整合 | 錯誤頁與 role=alert 可讀，無未處理 promise |
| 響應式與無障礙 | 44px 觸控目標、可見 focus、accessible name、表單 label、dialog/listbox 鍵盤、reduced motion、圖譜文字替代 | 元件測試＋靜態檢查 | 1440×900、390×844；鍵盤完成主要讀取與提交流程 |

### 6.1 核心測試不等於全部排列組合

本輪要求每個核心領域均有證據，但不為每個純展示字串、CSS 宣告或第三方函式建立低價值測試。相同契約可用資料驅動測試合併；第三方 Leaflet、D3、Vue 或 Hono 本身的內部行為不重測，只測 LangMap 的整合邊界。

### 6.2 瀏覽器角色與資料

- 匿名：瀏覽、搜尋、語言、詞句、圖譜、公開手冊、語系切換與拒絕受限操作。
- 一般使用者：貢獻、地域形式、讀音、映射、投票、偏好、翻譯提交與自有手冊。
- 管理員：同形拆分、手動啟用與封存介面語系。
- 測試資料只寫入本地 D1；每個會建立資料的情境使用唯一值，並能在重新 rebuild 後重跑。

## 7. 錯誤與競態設計

- 頁面首次載入需明確區分 loading、empty、error 與 content。
- 背景更新或載入更多失敗時保留已成功載入的內容，並提供可見錯誤或重試入口。
- route parameter、搜尋或選取快速變更時，舊回應不得覆蓋新狀態；採 request token 或 `AbortSignal`，沿用現有模組模式。
- 表單提交期間需防重複提交；成功只能在 server 確認後顯示。
- 權限拒絕不得偽裝成不存在，除非既有私密資源契約刻意以 404 防洩漏。
- Worker 只回傳可公開錯誤；內部錯誤記錄不得包含 secret、完整 token 或敏感輸入。
- 啟動與 DB 腳本失敗需 non-zero exit，並指出失敗階段；不得在 bootstrap 未完成時啟動服務。

## 8. 效能與 Workers 檢查

### 8.1 Web

- 記錄 build 前後各 entry/chunk 的 raw 與 gzip 大小；修正不得讓初始入口無理由增加超過 5%。
- 若 Vite 產生 chunk-size warning，先確認是否進入初始載入路徑，再以既有 route lazy loading 或最小 code splitting 修正。
- 地圖與圖譜只在需要的頁面載入；避免重複請求、未清理 listener、失效 watcher 與過時 async 回寫。
- 在測試 viewport 檢查長詞句、窄螢幕、載入骨架及大型圖譜；不得產生頁面級水平溢出。

### 8.2 API 與 D1

- 對首頁、搜尋、語言列表、詞句詳情、映射圖與手冊列表抽查查詢計畫及回應時間；只有可重現的 scan、N+1 或缺索引問題才調整 SQL/schema。
- 所有 list endpoint 都需有限制的 limit、非負 offset、穩定 tie-breaker 與一致 total/hasMore。
- 圖遍歷需限制 hops 與節點數，循環安全且輸入順序不影響結果。
- 檢查 Worker 全域可變狀態、floating promise、request body 驗證、binding 使用、CORS、可觀測性與例外邊界；修正需遵循 Cloudflare 官方當前規範。

### 8.3 相依套件

可執行相依套件安全檢查並記錄結果。修補版本可在測試證明相容時更新；major upgrade、替換框架或只為追新而升級不在本輪範圍。無可利用路徑或只能透過破壞性升級解決的項目需如實列為剩餘風險。

## 9. 驗證命令與順序

最終計畫需使用實際 package scripts，並至少包含以下驗證：

```bash
python3 -m unittest discover -s scripts/db/tests -p 'test_*.py'
./scripts/db/manage.sh local status
./scripts/db/manage.sh local rebuild
./scripts/db/manage.sh local verify

cd web
npm test
npm run i18n:check
npm run build

cd ../backend
npm test
npx wrangler deploy --dry-run

cd ..
./build.sh
git diff --check
```

執行 `backend` 完整測試前必須保持本地 Worker 在 `127.0.0.1:8788` 運作；測試依既有 Vitest 設定串行執行。`./build.sh` 會更新生成目錄，驗證後需區分預期生成差異與來源變更，不得把生成檔當成修正來源。

真實瀏覽器驗收使用：

- 桌面：1440×900；
- 行動：390×844；
- 一輪滑鼠／觸控等價操作；
- 一輪只用鍵盤操作；
- 一輪 `prefers-reduced-motion`；
- 每輪檢查 console error、未處理 rejection、失敗的 same-origin request、焦點遺失及水平溢出。

## 10. 文件與產物

本輪應交付：

1. 可重現的基線與最終驗證摘要；
2. 只針對已證實問題的程式與測試修改；
3. 核心功能測試矩陣的實際通過／失敗／不適用紀錄；
4. 若啟動或驗證入口與 README 不符，更新最小必要文件；
5. 未能安全修復或受本地環境限制的剩餘風險。

不新增一次性 repository 腳本來包裝單次檢查。可由現有 package script、unittest discovery、DB manager 或瀏覽器完成的工作，直接使用既有入口。

## 11. 驗收標準

### 11.1 必須通過

- 本地 D1 可從 repo 狀態重建並通過 `local verify`。
- `./dev.sh` 可同時啟動 Web 與 Worker，Vite proxy 可呼叫 `/api/v2`，停止時只清理本 repo 程序。
- Web Vitest、i18n check、TypeScript/Vite build 全部通過。
- Backend Vitest（含串行整合測試）全部通過。
- DB Python 測試全部通過。
- `./build.sh` 與 Wrangler deploy dry-run 通過。
- 第 6 節每個核心領域都有自動化證據；所有具 UI 的核心領域另有瀏覽器驗收紀錄。
- 桌面與行動主要流程無阻斷問題、頁面級水平溢出、未處理例外或失敗的必要 same-origin request。
- 鍵盤可完成導覽、搜尋、語系切換、表單與主要圖譜替代列表操作，focus 可見且對話框／選單可關閉。
- API 500 不洩漏內部例外；權限、驗證、not found 與 conflict 使用一致 envelope。
- `git diff --check` 通過，且不包含 secret、`.wrangler/`、`node_modules/` 或無關檔案。

### 11.2 可報告但不得假裝通過

以下情況可列為受限驗證，但必須附原因、已完成的替代檢查與風險：

- 第三方地圖圖磚或套件 registry 因網路限制不可用；
- 瀏覽器／系統缺少特定輔助功能檢查能力；
- 相依套件安全報告只能透過破壞性 major upgrade 解決；
- 本地效能數據受開發模式或硬體影響，無法代表 Cloudflare production latency。

既有失敗、環境限制或「看起來正常」都不能標記為通過。

## 12. 風險與控制

| 風險 | 控制方式 |
|---|---|
| 本地 D1 重建清除開發資料 | 已取得本輪授權；只操作 repo 專屬 local state，絕不使用 remote flag |
| 整合測試共用 D1 互相干擾 | Worker 固定 8788、Vitest file parallelism 關閉、測試值唯一、重建後重跑 |
| 廣泛優化造成回歸 | 先基線、按證據修正、相關測試先行、每批回歸 |
| 舊規格與目前實作不一致 | 以目前 router、route mount、schema 與可執行測試為準；未實作 PRD 功能不納入 |
| 視覺修正另起設計系統 | 僅使用 `atlas.css` token、既有低圓角與 lucide 圖示 |
| 效能優化犧牲可讀性或功能 | 只處理量測到的問題，保留文字替代、穩定輸出與現有契約 |
| 安全檢查意外觸及遠端 | 所有 DB 操作限定 local；Wrangler 只允許 dry-run，不 deploy |

## 13. 最終決策摘要

- 採用「證據驅動的穩定化」，不是測試數量競賽或激進現代化。
- 本輪只處理 Web、Worker、本地 D1、維護腳本與直接文件。
- 所有目前已實作的核心功能都必須出現在測試矩陣；UI 核心功能同時需要自動化證據與真實瀏覽器驗收。
- 允許按需重建本地 D1，但禁止任何遠端資料或部署操作。
- API、schema 與視覺系統預設保持相容；只有證實的缺陷才允許最小變更。
- 完成的定義是全部必要驗證真實通過，並明確列出任何受限驗證與剩餘風險。
