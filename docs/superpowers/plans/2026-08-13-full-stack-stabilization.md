# LangMap Full-Stack Stabilization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 讓 LangMap Web、Worker、本地 D1 與維護腳本可完整啟動，修復有證據的品質問題，並為所有目前核心功能建立可重複的測試與瀏覽器驗收證據。

**Architecture:** 保留 `Vue 3 → /api/v2 → Hono Worker → 本地 D1` 架構。工作以基線、啟動與資料生命週期、後端契約、前端核心流程、跨切面品質、瀏覽器驗收及最終回歸為獨立驗收單位；每個單位只處理被測試或執行證據指向的最小範圍。

**Tech Stack:** Vue 3、TypeScript、Vite、Pinia、Vitest、Vue Test Utils、Hono、Cloudflare Workers、Wrangler、D1、Python unittest

**Source Spec:** `docs/superpowers/specs/2026-08-13-full-stack-stabilization-design.md`

## Global Constraints

- 只處理 `web/`、`backend/`、本地 D1、`scripts/` 與直接相關文件；不得修改或測試 `apple/`。
- 不得連接、遷移、寫入或部署遠端／production Cloudflare 資源；Wrangler 只允許本地操作與 deploy dry-run。
- 本輪允許重建 repo 專屬本地 D1；不得保留或依賴重建前的本地開發資料。
- 不新增產品功能，不實作舊 PRD 中未落地的功能，不做無證據的大型重構或 major dependency upgrade。
- API prefix 維持 `/api/v2`，一般回應維持 `{ success, data?, error?, message? }`。
- schema 變更只有在實際缺陷要求時成立，且必須同步 migration、`schema.sql`、migration lock、型別、測試、相容與回退說明。
- 前端 API 統一經 `web/src/api/client.ts`；頁面、composable 與 API 型別需保持一致。
- 查詢、圖遍歷與佈局必須有穩定排序，並處理循環、重複、分頁及數量上限。
- 前端視覺沿用 `web/src/assets/atlas.css` token、低圓角與 `lucide-vue-next`；觸控目標至少 44px，複雜視覺保留文字替代。
- 所有目前核心功能都必須有自動化證據；具 UI 的核心功能另需真實瀏覽器驗收。
- 不提交 secret、`.dev.vars`、`node_modules/`、`.wrangler/` 或無關生成產物。
- 每項修改必須可追溯到失敗、執行期證據、量測、無障礙問題或明確規範風險。

## Plan Format

本計畫刻意聚焦 WHAT：每項任務定義交付結果、責任範圍、依賴與驗收證據，不預先指定函式內容、演算法步驟或逐行修改方式。實作時仍須遵循 Surgical Changes，並在最接近缺陷的既有測試層補上回歸證據。

## File Responsibility Map

| 責任區 | 主要現有檔案／目錄 | 本輪允許的成果 |
|---|---|---|
| 本地啟動與構建 | `dev.sh`、`build.sh`、`web/vite.config.ts`、兩個 `package.json` | 啟動、停止、proxy、構建與診斷行為可靠；只修改被基線證實有問題的入口 |
| D1 生命週期 | `scripts/db/`、`scripts/db/tests/`、`backend/migrations/`、`backend/schema.sql` | 重建、驗證、migration lock、schema、seed 與索引一致且安全 |
| Worker API | `backend/src/index.tsx`、`backend/src/routes/`、`backend/src/services/`、`backend/src/utils/`、`backend/src/types*` | API 契約、權限、驗證、排序、分頁、錯誤與 Workers 行為正確 |
| Worker 測試 | `backend/tests/` | 每個核心後端領域的成功路徑與關鍵拒絕路徑有證據 |
| Web 應用 | `web/src/pages/`、`components/`、`composables/`、`stores/`、`api/`、`router.ts`、`App.vue` | 核心流程、狀態、競態、響應式、鍵盤與錯誤回饋正確 |
| Web 測試 | 與來源共置的 `*.test.ts`、`web/src/test/` | 核心頁面與跨模組邊界的高價值自動化覆蓋 |
| 文件 | `README.md`、本規格與本計畫 | 啟動、驗證與已知限制和實際行為一致 |

## Dependency Order

1. Task 1 建立共同基線與缺口清單。
2. Task 2 使本地 D1 與完整啟動成為可信測試環境。
3. Task 3 關閉後端與資料契約缺口。
4. Task 4–6 依賴 Task 3 的穩定 API，可分領域推進但各自獨立驗收。
5. Task 7 依賴功能正確性基線，避免把功能缺陷誤判成效能或規範問題。
6. Task 8 依賴完整應用可用，負責真實瀏覽器證據與最後一輪 UX 修正。
7. Task 9 只在前述任務通過後執行，形成單一最終品質閘門。

---

### Task 1: 建立基線、核心覆蓋清單與問題登錄

**Outcome**

- 取得修正前的環境、Git、Web、Backend、DB、build、bundle 與瀏覽器健康基線。
- 將每項失敗分類為產品、測試、環境、文件或受限驗證問題。
- 將規格第 6 節的 21 個核心領域映射到現有測試證據，列出真正缺口。

**Scope**

- 只讀檢查與執行結果；此任務不修改產品程式。
- 結果記錄於本計畫對應 task 的執行註記與最終交付摘要。

**Produces**

- 可重現的基線結果。
- 有優先級、重現證據與責任模組的問題清單。
- 後續 Task 2–8 的實際修改邊界。

**Acceptance**

- [ ] 環境版本、工作區狀態、依賴狀態及生成目錄狀態已記錄。
- [ ] Web、Backend、DB、整體 build 與本地啟動相關基線均已嘗試並保留真實結果。
- [ ] Vite 產物 raw/gzip 大小、console/network 錯誤與兩個標準 viewport 已記錄。
- [ ] 21 個核心領域都有「現有證據」或「待補缺口」，沒有未分類領域。
- [ ] 未以 skip、忽略錯誤或降低斷言改變基線。

---

### Task 2: 交付可靠的本地 D1 與完整啟動生命週期

**Consumes:** Task 1 的啟動、DB 與工具鏈問題清單。

**Outcome**

- repo 專屬本地 D1 能從目前來源可靠重建並通過完整驗證。
- `./dev.sh` 能啟動 Worker 與 Vite，正確處理 fingerprint、port、bootstrap 失敗與 repo-owned process 清理。
- Web 入口、Worker API、Vite proxy、SPA 直接路由及停止流程可重複驗收。

**Scope**

- `dev.sh`、`build.sh`、`scripts/db/`、相關測試與必要啟動文件。
- `backend/migrations/`、`backend/schema.sql` 只有在 Task 1 證實資料契約缺陷時進入範圍。

**Produces**

- 後續整合測試共用的可信本地環境。
- 對啟動、重建、驗證與程序清理的回歸證據。

**Acceptance**

- [ ] DB Python 測試全部通過。
- [ ] `local rebuild`、`local verify` 與 schema contract 通過。
- [ ] fingerprint hit、miss、force rebuild、bootstrap failure、port forwarding 及精準 cleanup 均有測試證據。
- [ ] Vite 與 Worker 可同時保持運作，`/api/v2` proxy 可用。
- [ ] 停止後沒有本 repo 殘留服務，也沒有影響其他程序。

---

### Task 3: 關閉 Worker、API 與 D1 核心契約缺口

**Consumes:** Task 1 問題清單、Task 2 本地 Worker 與 D1。

**Outcome**

- 所有目前掛載的 API 群組均符合驗證、權限、回應 envelope、穩定排序、分頁、重複與 not-found 契約。
- 語言參照、地域形式、語言內容、詞句、佐證、讀音、映射、拆分、動態、手冊、偏好、貢獻與介面在地化均有成功與關鍵拒絕路徑證據。
- 500 response 不洩漏例外、SQL、secret 或 token。

**Scope**

- `backend/src/routes/`、`services/`、`utils/`、`types*`、`backend/tests/`。
- 只處理 Task 1 暴露的失敗與規格測試矩陣中的後端缺口。

**Produces**

- 可供 Web 任務依賴的穩定 `/api/v2` 契約。
- Backend 全量測試通過證據。

**Acceptance**

- [ ] 每個掛載 route group 至少有一項整合測試證據。
- [ ] 認證、一般使用者、作者與管理員邊界均被驗證。
- [ ] 所有 list endpoint 的限制、offset、total/hasMore 與穩定 tie-breaker 被驗證。
- [ ] 映射遍歷、clique、投票與同形拆分的循環、去重、移動及 revision 契約被驗證。
- [ ] Backend 全量 Vitest 在共用本地 Worker/D1 下串行通過。

---

### Task 4: 交付 Web 基礎、探索與語言流程的完整證據

**Consumes:** Task 3 的穩定 API 契約。

**Outcome**

- App shell、router、404、認證、首頁動態、搜尋、語言列表、語言詳情及地域形式建立均有直接自動化證據。
- 各頁面正確區分 loading、content、empty、error；快速查詢或 route 變更不會被舊回應覆蓋。
- 搜尋與載入更多失敗不會破壞既有成功內容。

**Scope**

- `web/src/App.vue`、`router.ts`、`pages/Auth.vue`、`HomeFeed.vue`、`Search.vue`、`LanguageList.vue`、`LanguageDetail.vue`。
- 直接依賴的 nav、language、ui components、stores、composables、API 模組與測試。

**Produces**

- 基礎導覽與內容探索流程的元件／頁面測試證據。
- 與後端 response envelope 一致的前端錯誤處理。

**Acceptance**

- [ ] 所有 router entry、`/map` redirect、unknown route 與重新整理行為有證據。
- [ ] 註冊、登入、目前使用者、登出及受限操作回饋有證據。
- [ ] 首頁 hot/new、搜尋、篩選、分頁、空白與錯誤狀態有證據。
- [ ] 語言搜尋、詳情、script query、代表城市、地域形式建立與 server 回傳 code 有證據。
- [ ] 相關 Web Vitest、i18n check 與 build 通過。

---

### Task 5: 交付詞句、映射與貢獻流程的完整證據

**Consumes:** Task 3 的詞句、映射、投票、拆分與貢獻 API 契約。

**Outcome**

- 詞句詳情、地域佐證、讀音、映射圖、層級列表、投票、同形拆分、快速新增與批次貢獻具備頁面級及元件級證據。
- 圖譜在循環、多父節點、跨邊、1–3 hops、折疊、拖曳、縮放、全螢幕及大型分支下保持穩定。
- 行動版文字列表能完整替代複雜圖譜操作。

**Scope**

- `web/src/pages/MappingDetail.vue`、`Contribute.vue`。
- `web/src/components/mapping/`、expression/language 依賴、相關 composables、API 模組與測試。

**Produces**

- LangMap 核心詞句與語義關係流程的自動化回歸層。
- 圖譜視覺與文字替代的一致狀態契約。

**Acceptance**

- [ ] 詞句詳情與證據清單的成功、空白、404 與錯誤狀態有證據。
- [ ] 圖模型、佈局、viewport、drag、toolbar、inspector 及 hierarchy list 測試通過。
- [ ] 投票失敗不偽造成功，同形拆分只搬移所選 edges 並在成功後刷新。
- [ ] 批次貢獻驗證至少兩個詞句、clique、重複 pair 與地域形式輸入。
- [ ] 相關 Web Vitest 與 build 通過。

---

### Task 6: 交付手冊、地圖與介面在地化流程的完整證據

**Consumes:** Task 3 的手冊、地域資料、偏好與 localization API 契約。

**Outcome**

- 手冊列表、詳情、建立、編輯、章節／詞句排序、私人權限與刪除具備直接測試證據。
- MapLens 對有座標、缺座標、route 變更、marker 選取、第三方圖磚失敗與 Leaflet cleanup 有明確行為。
- 語系選擇、primary/secondary fallback、匿名持久化、登入同步、翻譯工作臺、覆蓋率、啟用及封存權限具備直接證據。

**Scope**

- `web/src/pages/Handbook*.vue`、`MapLens.vue`、`TranslateWorkbench.vue`。
- handbook/nav/localization components、localization store、相關 composables、API 模組與測試。

**Produces**

- 策展、地理呈現及 UI localization 三組可獨立回歸的前端契約。

**Acceptance**

- [ ] 手冊公開／私人、作者／管理員、排序、編輯與 inspector 狀態有證據。
- [ ] MapLens 的資料、marker、錯誤替代內容與資源清理有證據。
- [ ] 語系切換、fallback、`<html lang>`、方向、重新整理持久化與鍵盤 listbox 有證據。
- [ ] 翻譯工作臺的搜尋、dirty 計數、提交、刷新、權限與錯誤狀態有證據。
- [ ] 相關 Web Vitest、i18n check 與 build 通過。

---

### Task 7: 關閉安全、Workers、效能與相依套件風險

**Consumes:** Task 1 的效能／安全基線與 Task 2–6 的功能正確性結果。

**Outcome**

- Worker 沒有高風險的全域可變狀態、floating promise、未驗證 request body、binding 誤用、敏感日誌或不一致例外邊界。
- 首頁、搜尋、語言列表、詞句詳情、映射圖與手冊列表沒有已證實的 N+1、無界查詢或缺少穩定索引問題。
- 初始 Web entry 未無理由增長超過基線 5%；地圖與圖譜維持按路由載入，listener、watcher 與 async request 有正確生命週期。
- 相依套件風險已有可利用性、影響與處置結論，不以破壞性升級換取表面清零。

**Scope**

- Task 1 指向的 Worker、SQL、Web async lifecycle、build configuration 與 package metadata。
- 不進行未被量測支持的通用重構。

**Produces**

- Workers production-practice 檢查結果。
- build size 前後對照、代表性 API／query plan 結果與 dependency risk 結論。

**Acceptance**

- [ ] Cloudflare Workers 生產規範的高風險項目已檢查並關閉或列為剩餘風險。
- [ ] 代表性 list 與 graph 查詢具有限制、穩定順序及合理 query plan。
- [ ] Web build 沒有新的 chunk warning，初始 entry 無未解釋的 >5% 增長。
- [ ] console 無未處理 rejection，route 離開後沒有持續 listener 或過時回寫。
- [ ] dependency audit 結果已分級；任何更新均通過相關與全量測試。

---

### Task 8: 完成真實瀏覽器核心流程、響應式與無障礙驗收

**Consumes:** Task 2 的完整本地環境與 Task 3–7 的候選最終版本。

**Outcome**

- 匿名、一般使用者與管理員三種角色完成規格要求的核心瀏覽器流程。
- 1440×900 與 390×844 均無阻斷、頁面級水平溢出、必要請求失敗或 console error。
- 主要流程可只用鍵盤完成，focus 可見，dialog/listbox 可關閉，觸控目標與 reduced-motion 符合規格。
- 瀏覽器發現的缺陷回到最近責任模組修正，並增加相應自動化證據。

**Scope**

- 所有目前 Web routes 與直接支援核心流程的 UI 元件。
- 不做純審美重設；只修復可用性、無障礙、響應式或錯誤回饋問題。

**Produces**

- 每個具 UI 核心領域的桌面／行動瀏覽器驗收紀錄。
- 鍵盤、reduced-motion、console、network、focus 與 overflow 檢查結果。

**Acceptance**

- [ ] 所有使用者路由均完成直接開啟、導覽與重新整理驗收。
- [ ] 匿名讀取、一般使用者提交、管理員受限操作均完成成功與拒絕路徑。
- [ ] 桌面、行動、鍵盤與 reduced-motion 四組檢查完成。
- [ ] 所有必要 same-origin request 成功，第三方受限項目已明確標記。
- [ ] 發現的每項可修復缺陷都有回歸測試，修正後重新通過對應瀏覽器流程。

---

### Task 9: 執行最終品質閘門並完成交付文件

**Consumes:** Task 1–8 的已驗收成果。

**Outcome**

- 所有自動化、資料庫、構建、dry-run 與瀏覽器驗收在候選最終版本上重新通過。
- README 與必要文件準確描述本地啟動、驗證入口及已知限制。
- 最終交付摘要逐項對應 21 個核心領域，清楚區分通過、受限與剩餘風險。

**Scope**

- 全 repository 驗證；文件只修改與本輪實際行為不一致的部分。
- 不在此任務新增未經前置 task 驗證的大型修正。

**Produces**

- 可重現的最終驗證結果。
- 乾淨、無 secret、無無關檔案的交付工作區。

**Acceptance Command Set**

```bash
python3 -m unittest discover -s scripts/db/tests -p 'test_*.py'
./scripts/db/manage.sh local rebuild
./scripts/db/manage.sh local verify
(cd web && npm test)
(cd web && npm run i18n:check)
(cd web && npm run build)
(cd backend && npm test)
(cd backend && npx wrangler deploy --dry-run)
./build.sh
git diff --check
```

**Acceptance**

- [ ] 上列 command set 全部以成功狀態結束。
- [ ] `./dev.sh` 完整啟動、proxy、SPA routes 與停止清理再次通過。
- [ ] Task 8 瀏覽器矩陣在最終版本上重跑通過。
- [ ] 21 個核心領域逐一具有自動化證據，所有 UI 領域另具瀏覽器證據。
- [ ] build size、Workers、query plan、dependency 與受限驗證結論已納入交付摘要。
- [ ] `git status` 只包含本輪預期來源、測試與文件變更，且不含敏感或生成狀態。

## Completion Definition

本計畫只有在 Task 9 全部通過時完成。任何既有失敗、環境限制、第三方不可用或無法安全修復的項目，都必須以「受限」或「剩餘風險」呈現，不能以忽略、skip 或口頭判斷取代通過證據。

## Plan Self-Review

- 規格的範圍、非目標、架構、錯誤、效能、Workers、測試矩陣、驗證與風險要求均已映射到 Task 1–9。
- 21 個核心領域全部由 Task 2–8 負責，並由 Task 9 統一回歸。
- Task 間依賴與輸出明確；沒有要求平行修改同一中心模組。
- 計畫只定義交付結果與驗收邊界，未預先鎖定實作細節。
