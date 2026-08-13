# LangMap 全棧穩定化驗收補救規格

**日期：** 2026-08-13  
**狀態：** 待實作  
**來源規格：** [`2026-08-13-full-stack-stabilization-design.md`](./2026-08-13-full-stack-stabilization-design.md)  
**驗收基準：** `git diff 6df3ffc...HEAD`  
**範圍：** 語言列表與詳情契約、前端非同步共用模式、瀏覽器驗收證據及最終交付文件

## 1. 背景

全棧穩定化候選版本已通過 DB、Web、Backend、i18n、build、Wrangler dry-run 及本地啟動的主要自動化命令，但程式與交付證據尚未滿足來源規格的完成定義。

本輪驗收已重現下列缺口：

- 語言列表只取得固定數量後在前端搜尋與排序，未使用後端分頁契約。
- 語言詳情的搜尋、`hot`／`new`／`alpha` 排序及 locale 選擇未傳至 API；控制項會改變選中狀態，資料卻仍使用預設排序。
- 語言詳情仍以舊 `profiles`／數字 expression ID 契約組合新 `locales`／字串 ID 回應，產生 Vue prop warnings。
- 語言列表與詳情缺少完整的 loading、empty、error、分頁失敗保留內容及過時回應防護證據；語言詳情沒有直接頁面測試。
- Task 8 紀錄只覆蓋匿名路由 smoke test，未涵蓋一般使用者、管理員及各 UI 核心流程。
- 最終紀錄落後候選 HEAD，亦未交付 21 個核心領域矩陣、build size 對照、query plan、dependency risk 及完整剩餘風險。
- 固定差異 `git diff --check 6df3ffc...HEAD` 尚未通過。

因此，本規格是來源規格的補救增量；只有本規格與來源規格的未完成驗收項目同時通過，才能把全棧穩定化標記為完成。

## 2. 目標

1. 使語言列表與語言詳情的前端行為完整對齊 `/api/v2/languages` 契約。
2. 統一語言、詞句與共用列元件的 TypeScript 資料形狀，消除執行期 prop warnings 與新增的 `any`。
3. 讓搜尋、排序、locale、分頁及 route 變更具備可重複的競態與錯誤回歸證據。
4. 補齊匿名、一般使用者及管理員的真實瀏覽器驗收矩陣。
5. 產出與候選最終 HEAD 一致、可重現且不誇大通過範圍的交付紀錄。

## 3. 非目標

- 不修改或測試 `apple/`。
- 不新增收藏、匯出或其他產品功能。
- 不重設 expression、language locale 或 mapping 資料模型。
- 不連接、遷移、寫入或部署遠端／production Cloudflare 資源。
- 不為消除判斷性 code smell 進行跨領域大型重構。
- 不以降低斷言、忽略 warning、增加 skip 或只更新文件的方式宣告產品缺口已修復。

## 4. 語言內容 API 契約

### 4.1 語言列表

`GET /api/v2/languages` 維持一般分頁 envelope，支援：

| 參數 | 契約 |
|---|---|
| `q` | 以語言 code、使用者名稱或英文名稱搜尋；空字串表示不篩選 |
| `sort` | `count` 或 `alpha`；未知值回退至 `count` |
| `limit` | 使用既有 bounded limit |
| `offset` | 非負整數 |

Web 必須把目前的搜尋與排序送至 API。新查詢或排序從 `offset=0` 重新載入；載入更多使用目前已成功載入的筆數作 offset。不得先固定取得 100 筆再假裝是完整資料集。

### 4.2 語言詳情

`GET /api/v2/languages/:code` 回傳的語言地域形式欄位以 `locales` 為唯一契約，不再由頁面讀取舊 `profiles` 欄位。locale 選項由 `locales[].code` 依 API 的穩定排序直接呈現；同一 script 可有多個 region 或 place locale。

語言詳情的基礎身份是 ISO 639-3 `lang_code`，不得將 locale 排序第一筆的名稱當成語言名稱。頁面以「全部」及每個完整 locale 的切換按鈕呈現地域形式；選取 locale 時，頁面標題及副標題以該 locale 的名稱與 code 呈現。不得以較粗粒度的 script 任意選擇地域形式。

系統 seed 的 locale 本地名稱須與 code 的地域標示一致：`cmn-Hans-CN` 為「普通话(CN)」、`cmn-Hant-TW` 為「華語(TW)」、`nan-Hant-CN` 為「閩南語(CN)」。此類資料修正須同時更新 migration 與完整 schema，不在前端覆寫。

URL query `locale` 使用完整 locale code，例如 `cmn-Hant-TW`、`nan-Hant-CN_Quanzhou_Nanan`。空值表示全部地域形式。未知或不屬於該語言的 locale 不得造成 500；頁面需回到全部地域形式，並以測試固定所選行為。

### 4.3 語言詞句列表

`GET /api/v2/languages/:code/expressions` 維持分頁 envelope，支援：

| 參數 | 契約 |
|---|---|
| `q` | 搜尋 expression text |
| `sort` | `hot`、`new`、`alpha`；未知值回退至 `hot` |
| `locale` | 可選完整 locale code；只包含至少一項屬於該 locale 的 attestation 的 expression |
| `limit` | 使用既有 bounded limit |
| `offset` | 非負整數 |

locale 篩選以 `expression_locale_attestations` 的既有關係實作，不新增 expression 到 locale 的冗餘欄位。count 與 items 必須使用同一篩選條件；存在多項符合 attestation 時不得重複 expression。

所有排序必須有穩定 tie-breaker。`hot` 依 mapping count 後再以 text、homograph index、ID；`new` 依建立時間後再以 ID；`alpha` 依 text、homograph index、ID。

### 4.4 前端型別

前端 API 層需定義並重用下列資料形狀，不在頁面另寫 `any`：

- `ContentLanguagePageQuery`
- `LanguageExpressionPageQuery`
- `LanguageDetail`
- `LanguageExpressionSummary`

`LanguageExpressionSummary.id` 為字串 expression ID。重用列元件不得要求 API 已不提供的 `language_profile_code`；若列需要顯示語言，使用目前契約中的 `lang_code` 或由呼叫端明確提供顯示值。`showLanguage=false` 時不得仍要求無關的必填 prop。

## 5. Web 狀態與競態

### 5.1 語言列表

頁面需明確區分：

- 首次 loading；
- 有內容；
- 查詢無結果；
- 首次載入 error；
- 載入更多 error，並保留既有內容；
- 已載完，不再顯示載入更多入口。

搜尋需沿用現有 debounce 方式或等價機制。搜尋、排序或重試快速連續發生時，只有最新請求可以寫回資料與 loading/error 狀態。

### 5.2 語言詳情

語言 detail 與 expression page 可各自追蹤 loading/error，但不得共享一個會被並行請求過早清除的 loading flag。

以下操作需從第一頁重新請求並防止過時回寫：

- route `:code` 改變；
- `locale` query 改變；
- 搜尋文字改變；
- 排序改變。

`router.replace()` 造成的 watcher 與直接事件處理不得對同一狀態重複送出請求。頁面卸載後，完成中的舊請求不得更新畫面。

### 5.3 共用 latest-request 模式

目前多個頁面重複 request token、過期判斷與 finally gate。應建立最小、typed 的共用 composable 或 utility，至少支援：

- 產生最新 request 身份；
- 判斷結果是否仍有效；
- 在 route／component 生命週期結束時使舊請求失效；
- 保持各頁既有的內容保留與錯誤呈現策略。

只遷移本輪涉及或可由既有測試安全覆蓋的重複點；不要求一次重寫全站所有非同步流程。

### 5.4 錯誤型別

本輪修改的 Vue／TypeScript 來源不得新增 `any`。未知錯誤以 `unknown` 接收，透過一個 typed error helper 解析 API `message`／`error`，否則使用 i18n fallback。

## 6. 自動化證據

### 6.1 Backend

至少新增或收緊下列整合測試：

- 語言列表 `q`、`count`／`alpha`、limit、offset、total、hasMore 與 tie-breaker。
- 語言詞句 `q`、`hot`／`new`／`alpha` 的結果確實不同且穩定。
- locale 篩選只回傳具有相符 locale attestation 的 expression。
- 多項相符 attestation 不重複 expression，total 與 items 一致。
- 未知語言維持既有 404 envelope；未知 locale 的行為符合第 4.2 節選定契約。

### 6.2 Web API 與 composable

測試需直接斷言 `q`、`sort`、`locale`、`limit`、`offset` 與 `AbortSignal`／request token 被正確傳遞。不得只 mock 一個不檢查參數的成功回應。

### 6.3 頁面

`LanguageList` 與 `LanguageDetail` 均需直接頁面測試，至少涵蓋：

- loading、content、empty、initial error；
- 搜尋／排序重設分頁；
- 載入更多成功及失敗保留既有內容；
- 快速查詢與 route/locale 變更時舊回應不覆蓋新狀態；
- `Latest` 與 `Alphabetical` 實際改變 API 參數及結果，不只改變按鈕 class；
- locale 選項來自 `locales`，URL query 與選中狀態一致；
- 字串 expression ID 導向 `/mapping/:id`；
- 渲染過程沒有 Vue prop warning。

## 7. 真實瀏覽器驗收

瀏覽器結果需以候選最終 HEAD 重跑，記錄 commit、viewport、角色、操作、結果、console、same-origin network、overflow 與受限項目。至少包含：

| 角色 | 必測流程 |
|---|---|
| 匿名 | 導覽、首頁 hot/new、搜尋與載入更多、語言列表搜尋／排序／分頁、語言詳情搜尋／排序／locale、詞句與圖譜文字替代、公開手冊、地圖替代狀態、語系切換、受限操作拒絕 |
| 一般使用者 | 登入／登出、批次貢獻、地域形式、佐證、讀音、映射、投票、偏好、翻譯提交、自有手冊建立／編輯／檢視 |
| 管理員 | 同形拆分、介面語系手動啟用與封存，以及一般使用者被拒絕的對照路徑 |

每個具 UI 的核心領域至少有一條真實瀏覽器流程。整體矩陣需包含：

- 1440×900；
- 390×844；
- 滑鼠／觸控等價操作；
- 只用鍵盤完成主要流程；
- `prefers-reduced-motion`；
- 直接開啟與重新整理主要 route；
- console error、未處理 rejection、Vue warning、必要 same-origin request、焦點遺失及頁面級水平溢出檢查。

第三方地圖圖磚失敗可標記為受限，但同源 API、應用程式例外、契約 warning 或未測角色不可列為受限通過。

## 8. 品質與範圍控制

- 修復 `Search.vue` 本輪新增的 `catch (e: any)`。
- 排序 query 的合法值解析使用共用 domain type／parser；SQL ORDER BY 可保留在各 service，避免不必要抽象。
- Worker binding 型別維持由 Wrangler 生成；secret 不進入版本控制。
- 不提交 `web/dist/`、`backend/public/`、`.wrangler/`、`.dev.vars` 或測試產生的本地資料。
- schema 如無必要不變更；locale 篩選優先使用既有表與索引。若 query plan 證實需要索引，才新增 migration、同步 `schema.sql`、migration lock、回退說明與測試。

## 9. 最終交付紀錄

更新 [`2026-08-13-full-stack-stabilization.md`](../plans/2026-08-13-full-stack-stabilization.md) 與 [`2026-08-13-stabilization-progress.md`](../plans/2026-08-13-stabilization-progress.md) 時，以候選最終 HEAD 為準：

1. 每個 checkbox 只能在對應證據存在時勾選；未通過項目保留未勾並列明 blocker。
2. 21 個核心領域逐項記錄自動化證據、瀏覽器證據、結果與剩餘風險。
3. 記錄 Web build 前後 initial entry/chunk raw 與 gzip 對照，解釋任何超過 5% 的增長。
4. 記錄代表性 list／graph query plan、dependency audit 分級及 Cloudflare Workers 檢查結論。
5. 命令結果記錄實際 test 數、migration 數、bundle size、commit SHA 與執行日期，不複製舊結果。
6. 修正文件 whitespace，並確認所有相對連結可解析。

交付摘要需區分「通過」「受限」「未通過」，不得以整體測試綠燈取代缺少的角色或 UI 流程證據。

## 10. 驗收命令

最終候選版本至少執行：

```bash
python3 -m unittest discover -s scripts/db/tests -p 'test_*.py'
python3 -m unittest discover -s scripts/i18n -p 'test_*.py'
./scripts/db/manage.sh local rebuild
./scripts/db/manage.sh local verify

(cd web && npm test)
(cd web && npm run i18n:check)
(cd web && npm run build)

# 保持本地 Worker 在 127.0.0.1:8788 運作
(cd backend && npm test)
(cd backend && npm run types:check)
(cd backend && npx wrangler deploy --dry-run)

./build.sh
git diff --check 6df3ffc...HEAD
```

另以 `./dev.sh --no-rebuild` 驗證 Web、Worker、Vite `/api/v2` proxy、SPA direct route 與停止清理；停止後 5173、8788 不得有本 repo listener。

## 11. 完成定義

本補救規格只有在下列條件全部成立時完成：

- 語言列表與詳情的搜尋、排序、locale、分頁及競態契約均有 backend、Web API/composable、頁面與瀏覽器證據。
- 語言頁不再產生 expression ID 或 language prop 契約 warning。
- 本輪修改的來源沒有新增 `any`，重複 latest-request 邏輯已在必要範圍內收斂。
- 匿名、一般使用者與管理員的瀏覽器矩陣完整，且桌面、行動、鍵盤及 reduced-motion 結果可追溯。
- 21 個核心領域矩陣、build size、query plan、dependency 與 Workers 結論已記錄。
- 所有驗收命令通過，固定差異沒有 whitespace error、secret、無關檔案或生成狀態。
- 來源規格、implementation plan 與進度文件的狀態和候選最終 HEAD 一致。

任何未滿足項目必須保留為未通過或剩餘風險，不得把本規格標記為完成。
