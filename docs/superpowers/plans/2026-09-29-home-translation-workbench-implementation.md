# 首頁整合詞句翻譯工作台實作計畫

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking.

**Goal:** 首頁以預設搜尋的「搜尋／翻譯」分頁提供入口；搜尋沿用既有搜尋頁，翻譯原地顯示。動態只顯示在搜尋分頁，翻譯分頁不顯示；加入首頁導覽、開放訪客翻譯並保留限流保護。

**Architecture:** 新增 `TranslationWorkbench.vue`，搬入既有翻譯頁的狀態與事件處理，復用表單、結果、串流 composable 和投稿預填。首頁預設顯示搜尋框及動態；切換至翻譯時掛載工作台並在原地顯示結果，動態隨之卸載。搜尋仍走既有 `/search`，`/translate` 重導首頁。後端復用 `optionalAuth` 與錯誤 envelope，加入 Cloudflare Rate Limit binding；不另建狀態 store、搜尋 API、限流資料庫或翻譯管線。

**Tech Stack:** Vue 3、TypeScript、Vue Router、Pinia、atlas tokens、Hono、Cloudflare Workers、Wrangler。

**Spec:** [已通過的設計規格](../specs/2026-09-29-home-translation-workbench-design.md)

**Status:** 2026-09-30 首頁與翻譯工作台版面修正完成，524 個 UI key 的五語系檢查、前端建置、`git diff --check` 及 Wrangler dry-run 通過。正式部署至 `langmap.io` 成功，Worker version `43b5cadf-37e1-4e10-98ca-28f50a61c655`；正式站回讀確認搜尋分頁顯示動態、翻譯分頁不顯示動態，390×844 行動版頂部間距已收斂，搜尋按鈕獨立位於大型輸入框下方；翻譯來源與目標選單均顯示語言名稱及代碼，目標清單能以語言名稱搜尋。實際 AI 翻譯請求、隔離 PostgreSQL 整合測試及 960／961px 斷點仍未驗證。

## 使用者後續修正（2026-09-29）

- 首頁採用搜尋／翻譯雙分頁，搜尋預設；搜尋模式為置中單一搜尋框，翻譯模式才顯示既有工作台。這項確認取代 Task 3 原先「首頁直接顯示完整工作台」的畫面方案。
- 搜尋框提交只帶 `q` 至既有 `/search`；使用者在搜尋頁選既有語言或使用最近選擇，不在首頁加入語言控制。
- 英文 UI 直接以 registry 的 canonical English expression 顯示語言名稱；英文目標 locale 不得用一般詞句關聯猜名稱，避免 Japanese 被錯配為 “Day”。
- 後續首頁回饋更新了搜尋方案：首頁直接提供可搜尋的語言選擇；搜尋按鈕要求選定語言，並以 `q` 和 `lang` 前往 `/search`。首頁不再顯示長主標題／副標題，搜尋控制放大並與按鈕合併；Search／Translate 使用更清晰的分段選取狀態。
- 清單中 `ara`、`pus` 原先因 locale code 被當成英文名稱而混亂；ISO 639-3 canonical names 現在由生成 overlay、importer 及 API 名稱解析共用，保留 locale profile 自己的名稱。
- 2026-09-30 首頁視覺後續收斂：保留全頁點陣背景，首頁不使用不透明底板；搜尋與翻譯欄位保留各自的實底；Search／Translate 使用透明文字分頁與細底線選取狀態。首頁搜尋將語言選擇獨立置頂、放大全寬搜尋框，搜尋按鈕獨佔下一行。
- 搜尋與翻譯模式各加一行簡短標題和用途說明。依最新指示，原首頁動態恢復在搜尋框下方，只在搜尋模式掛載；翻譯模式不載入動態。
- 翻譯工作台收斂為來源語言、目標 locale、文字輸入與翻譯按鈕；結果只在送出後顯示於按鈕下方，點擊譯文詞句時顯示直接關聯 mapping。

## Global Constraints

- 新增中文文案使用傳承體中文；`en.ts` 中全部 524 個訊息鍵都必須在 UI locale CSV 提供簡中、繁中、英文、日文及西班牙文，檢查器驗證完整度與英文來源一致。沿用 `atlas.css`、scoped CSS 與 Lucide，不新增視覺系統或依賴。
- 桌面翻譯左右雙欄，768px 以下上下排列；自然頁面捲動。導覽與搜尋表單沿用現有 **960px** 斷點。
- 觸控目標至少 44px，支援鍵盤、可見 focus、accessible name、reduced motion，長文字不得水平溢出。
- 翻譯保留 500 graphemes、8KiB text、16KiB body 上限；查詢只要求非空文字，不要求目標 locale、不套用翻譯上限。
- 訪客限流為每 IP 每 60 秒 10 次；屬於 Cloudflare location 內的最佳努力突發限流，不是精確全域配額。
- 沒有指定搜尋語言時保留既有最近語言行為；沒有可用語言才提示選擇。明確但無效的語言不能默默換成其他語言。
- 投稿仍要求登入；訪客不顯示建立 locale 入口。不修改 `apple/`、schema、feed API、翻譯供應商或資料持久化。
- 保留既有 fetch 串流 API；一般 API 經 `api/client.ts`。不把原文、譯文或 token 加入 log 或翻譯 URL。

---

## File Map

| 檔案 | 責任 |
| --- | --- |
| `backend/wrangler.jsonc`、`backend/worker-configuration.d.ts` | 正式限流設定及產生的 binding 型別 |
| `backend/src/routes/translation.ts` | optional auth、訪客限流、429／503；保留原管線 |
| `backend/tests/translationRoute.test.ts` | 可注入 limiter 的 route 測試；授權與限流契約 |
| `backend/tests/translationIntegration.test.ts` | 對啟動中的 Worker 驗證公開端點；不能在此注入 binding |
| 新增 `web/src/components/translation/TranslationWorkbench.vue` | 搬入翻譯頁狀態、來源確認、重試、取消、投稿處理 |
| `TranslationForm.vue`、`TranslationResult.vue`（同目錄） | 共用輸入、查詢／清除動作、雙欄；投稿可見性 |
| `web/src/composables/useTranslationStream.ts` | HTTP 錯誤的重試資訊，保留取消與競態處理 |
| `web/src/locales/en.ts`、`scripts/i18n/ui-locales.csv` | 英文來源目錄及在地化文案，既有 fallback |
| `web/src/pages/HomeFeed.vue` → `HomeView.vue` | 首頁簡介、工作台、查詢路由，不再載入 feed |
| 刪除 `web/src/pages/ExpressionTranslation.vue` | 搬移完成後刪除舊頁，避免兩套流程 |
| `web/src/router.ts`、`web/src/components/nav/TopNav.vue`、`web/src/pages/Search.vue` | 首頁 tab、舊路徑、可見搜尋表單及 URL 同步 |
| 既有相關 `*.test.ts` | 移轉頁面案例、補齊此次契約與回歸驗證 |

`TranslationProgress.vue` 已接收 `error.message`，直接傳入在地化訊息即可，不必再改其介面。優先使用現有測試檔與 fixtures。

## Task 1: 公開翻譯與訪客限流

**Files:** `backend/wrangler.jsonc`、`backend/worker-configuration.d.ts`、`backend/src/routes/translation.ts`、`backend/tests/translationRoute.test.ts`、`backend/tests/translationIntegration.test.ts`。

**Interfaces:**

- `optionalAuth` 有效 token 才設定 `user`；缺少／無效 token 按訪客處理。
- `TRANSLATION_GUEST_LIMITER.limit({ key: string }): Promise<{ success: boolean }>`。
- `429`：既有 `tooManyRequests(c, 'RATE_LIMITED', message, 60)`，`Retry-After: 60`。
- `503`：`{ success: false, error: 'TRANSLATION_UNAVAILABLE', message, retryable: true }`。
- 成功保持既有 NDJSON 與取消契約；所有回應保持 `Cache-Control: no-store`。

- [x] **1. 加入正式 `ratelimits` 設定並產生型別**

使用已安裝 Wrangler 支援的正式欄位，不使用 `unsafe.bindings`：

```json
"ratelimits": [{
  "name": "TRANSLATION_GUEST_LIMITER",
  "namespace_id": "20260929",
  "simple": { "limit": 10, "period": 60 }
}]
```

`20260929` 為本計畫選用的 namespace；部署前核對帳戶內無其他用途共用此 ID。同 ID 會共用計數器；日後需要環境隔離時使用不同 ID，這次不新增環境設定。

```bash
(cd backend && npx wrangler types worker-configuration.d.ts)
(cd backend && npm run types:check)
```

各命令以 repo root 為起點，括號讓目錄切換不影響下一個命令。第二個命令只核對 Wrangler 設定與 Env 宣告一致，**不等於後端 TypeScript 編譯檢查**。
本次同步將 `types:check` 改為 Wrangler 預設 runtime 型別模式，與原有生成檔一致，避免為新增 binding 刪除整份 runtime 宣告。

- [x] **2. 使用 optional auth，先限流再讀 body**

移除 `requireTranslationAuth`，改用既有 `optionalAuth`。訪客區塊置於 handler 開頭：

```ts
if (!c.get('user')) {
  const ip = c.req.header('CF-Connecting-IP') || 'unknown';
  try {
    const { success: allowed } = await c.env.TRANSLATION_GUEST_LIMITER.limit({
      key: 'translate:guest:' + ip,
    });
    if (!allowed) return tooManyRequests(c, 'RATE_LIMITED', 'Please try again in 60 seconds.', 60);
  } catch {
    return c.json({ success: false, error: 'TRANSLATION_UNAVAILABLE',
      message: 'Translation is temporarily unavailable.', retryable: true }, 503);
  }
}
```

只使用 Cloudflare 的客戶端 IP header；缺少時共用 `unknown` bucket，不採信 `X-Forwarded-For`，也不跳過限制。有效登入者不呼叫訪客 limiter。沿用 body/text 驗證、locale resolution、canonicalization、orchestrator 與 stream cancellation；不改管線。

- [x] **3. 更新 route fixture 與契約案例**

在 `translationRoute.test.ts` 的 `PostOptions` 加 `limiter?: RateLimit | null`；undefined 使用預設放行 binding，null 模擬 binding 缺失，其他值可傳拒絕或拋錯 binding：

```ts
TRANSLATION_GUEST_LIMITER: options.limiter === undefined ? {
  limit: async () => ({ success: true }),
} : options.limiter ?? undefined,
```

保留既有 authenticated fixtures，將未登入 401 案例改為訪客成功取得 NDJSON；成功案例沿用既有 orchestrator stream mock，不能讓 reset 後的 mock 回 undefined。補齊以下斷言：

| 情境 | 必須斷言 |
| --- | --- |
| 無 token／無效 token、limiter 放行 | 能進入原管線，limiter 使用正確 IP key |
| limiter 拒絕 | 429、RATE_LIMITED、Retry-After=60、no-store；orchestrator 未呼叫、回應不含原文 |
| limiter 拋錯／缺失 | 503、TRANSLATION_UNAVAILABLE、no-store；orchestrator 未呼叫 |
| 有效登入 | limiter 未呼叫，保留原驗證／stream 流程 |
| 缺少 IP header | 使用固定 `translate:guest:unknown` key |

限流拒絕案例沿用 `post()` helper：

```ts
const limit = vi.fn(async () => ({ success: false }));
const response = await post({ token: null, limiter: { limit },
  headers: { 'CF-Connecting-IP': '192.0.2.1' } });
expect(response.status).toBe(429);
expect(response.headers.get('Retry-After')).toBe('60');
expect(await jsonError(response)).toBe('RATE_LIMITED');
expect(limit).toHaveBeenCalledWith({ key: 'translate:guest:192.0.2.1' });
expect(runTranslationMock).not.toHaveBeenCalled();
```

`translationIntegration.test.ts` 是 HTTP smoke test，不可寫成注入 binding。將原登入必選案例改成「訪客空 body 回 VALIDATION_FAILED，而非 AUTH_REQUIRED」，保持 non-AI 用途；成功串流由 route fixture 與最終實際流程驗證。

- [x] **4. 驗證後端改動**

```bash
(cd backend && npm test -- tests/translationRoute.test.ts tests/translationValidation.test.ts)
```

完成條件：訪客串流、限流／服務失敗、登入者及既有驗證案例通過。`translationRoute.test.ts` 與 `translationValidation.test.ts` 共 52 項通過。整合測試因缺隔離資料庫仍待 Task 4，不碰已設定的 Hyperdrive。

## Task 2: 搬移工作台並補齊共用輸入

**Files:** 新增 `TranslationWorkbench.vue`；修改 `TranslationForm.vue`、`TranslationResult.vue`、`useTranslationStream.ts`、`web/src/locales/en.ts`、`scripts/i18n/ui-locales.csv`；相關既有測試。

**Interfaces:**

- 保持 `TranslationFormValue = { sourceLangCode: string | null; targetLocaleCode: string; text: string }`。
- Form 新增 `search: []` emit；清除使用既有 `update:modelValue`，不新增第二份文字狀態。
- 沿用 Form 目前 `:allow-create="false"`；訪客可選既有 locale，但不能建立新 locale。
- Workbench emits `search: [value: TranslationFormValue]`，擁有既有翻譯狀態。
- Result 新增 `allowContribute?: boolean = false`；工作台依 `auth.isLoggedIn` 傳值。

- [x] **1. 搬入原翻譯頁，移除翻譯登入閘門**

搬入 `form`、`lastInput`、`useTranslationStream()`、來源確認、retry、edit、投稿預填與 template，根節點用 `section`。移除 `authorized` 與登入重導；保留焦點回移、請求取消、late response guard、exact lookup 不重複投稿規則。`sendToContribute()` 入口也檢查登入，不能只靠按鈕隱藏。

```vue
<TranslationForm :model-value="form" :allow-locale-create="auth.isLoggedIn"
  @update:model-value="onFormUpdate" @search="emit('search', { ...form })" />
<TranslationResult :allow-contribute="auth.isLoggedIn" />
```

以上展示新介面；實作時保留原本所有 props／slots／handlers，更新仍經 `onFormUpdate()` reset 舊結果。

- [x] **2. 加入查詢、清除，分開驗證**

查詢按鈕使用 `type="button"`，只以非空文字判斷；不送翻譯 request、不觸發目標 locale 錯誤。翻譯仍走既有 submit、graphemes／bytes／target 驗證。避免單純輸入或查詢時出現「缺少目標 locale」；目標錯誤在翻譯提交後呈現。

```ts
function onSearch() {
  if (!props.modelValue.text.trim()) return
  emit('search')
}
function clearText() {
  update({ text: '' })
}
```

清除保留來源／目標選擇，經既有更新流程取消請求、清空舊結果並移回 textarea focus。目標 picker 沿用現有 `:allow-create="false"`；來源 language 和目標 locale 各自選擇，不加入猜測 locale 的交換邏輯。

- [x] **3. 改雙欄 CSS，內容自然增高**

```css
.translation-workspace { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); }
.source-pane, .target-pane { min-width: 0; }
@media (max-width: 768px) {
  .translation-workspace { grid-template-columns: minmax(0, 1fr); }
}
```

spacing、邊框、focus 沿用 tokens。譯文保留換行並可折行；不加固定高度、獨立捲動容器或動畫框架。保留複製、替代譯法、詞句點擊、證據與取消操作。

- [x] **4. 正規化 HTTP 錯誤與文案**

在 `readErrorEnvelope()` 取得錯誤物件後，JSON `retry_after_seconds` 有效值優先；缺少時只接受 `Retry-After` 正整數秒數。`429 / RATE_LIMITED` 設 `retryable=true`；`503 / TRANSLATION_UNAVAILABLE` 保留 body retryable。無有效秒數時顯示「請稍後再試」，不產生 NaN 倒數、不自動重送。

工作台 computed 顯示 `phraseTranslate.rateLimited`（`{seconds}`）、無秒數時沿用 `phraseTranslate.errorRateLimited`，以及 `phraseTranslate.unavailable`，傳給既有 Progress／Result。重試使用原 `lastInput`，錯誤不清空輸入。

新增 `home.title`、`home.subtitle`、`home.search`、`phraseTranslate.clearText` 及上述錯誤 keys，**同時**更新 `en.ts` 英文來源與 CSV。完整補入原先缺少的 82 個翻譯工作台訊息鍵、其他 5 個使用中訊息鍵，以及所有五種已配置 locale 的文案；`i18n:check` 驗證每個 `en.ts` key 都有五種完整翻譯，英文欄與 source catalog 相符。翻譯工作台依 API 錯誤代碼顯示本地化錯誤，不顯示原始英文 server message。保留仍被其他功能引用的 feed keys。

- [x] **5. 移轉既有測試，核對工作台契約**

將 `ExpressionTranslation.test.ts` 的頁面互動案例移至 `components/translation/TranslationWorkbench.test.ts`，移除登入重導預期，保留來源確認、串流、重試、投稿預填案例。補訪客看不到投稿／建立 locale、翻譯不導航。Form 測試補「未選目標仍能查詢」「501 graphemes 可查詢但不可翻譯」「清除保留語言並移除結果」；stream 測試補 429 header／無 header／503 及晚到回應不覆蓋新狀態。

```bash
(cd web && npm test -- src/components/translation/TranslationWorkbench.test.ts src/components/translation/TranslationForm.test.ts src/components/translation/TranslationResult.test.ts src/composables/useTranslationStream.test.ts)
(cd web && npm run i18n:check)
```

## Task 3: 接入首頁、導覽與搜尋

**Files:** `HomeFeed.vue` → `HomeView.vue`、`router.ts`、`TopNav.vue`、`Search.vue`；刪除 `ExpressionTranslation.vue`；`HomeFeed.test.ts` → `HomeView.test.ts`、`TopNav.test.ts`、`Search.test.ts`。

**Interfaces:** 首頁搜尋表單導向 `/search?q=...`，不猜測或傳入 `lang`；Search 保持搜尋狀態與 API 的唯一所有者。TopNav 只維護表單草稿，在 Search 路由以 URL 同步，不新增跨元件 store。

- [x] **1. 替換首頁內容並接查詢事件**

移除 `useFeed()`、request token、動態列表與 feed 狀態。首頁以簡潔簡介、搜尋／翻譯 tab、搜尋框與翻譯模式組合：

```ts
function searchExpressions() {
  const q = query.value.trim()
  if (!q) return
  void router.push({ path: '/search', query: { q } })
}
```

以 `role=tablist` 實作兩個可鍵盤操作的模式，預設 `search`。搜尋模式只渲染單一搜尋框；翻譯模式才掛載 `TranslationWorkbench`，傳入 `showSearchAction=false` 隱藏重複搜尋按鈕。搜尋不猜 lang；由 Search 保留最近語言／無語言提示。不可把 target locale 當搜尋 language。

- [x] **2. 更新路由與首頁 tab**

```ts
{ path: '/', component: () => import('./pages/HomeView.vue') },
{ path: '/translate', redirect: { path: '/', query: {} } },
```

舊路徑 query 不含翻譯預填契約，不帶入文字。搬移完成後刪除舊翻譯頁及其 import。桌面和抽屜新增首頁 link，active 條件 `route.path === '/'` 與 `aria-current="page"`；移除獨立翻譯 link。

- [x] **3. 對齊搜尋顯示、URL 同步與必選提示**

| 路由／寬度 | 可見搜尋表單 |
| --- | --- |
| 首頁，所有寬度 | 首頁工作台；TopNav 和抽屜不顯示搜尋 |
| `/search`，>960px | TopNav；隱藏 Search 頁內表單 |
| `/search`，≤960px | Search 頁內表單；抽屜不重複搜尋 |
| 其他路由 | 保持既有桌面 TopNav／行動抽屜搜尋 |

TopNav 的 desktop 條件 `route.path !== '/'`；drawer 條件 `route.path !== '/' && route.path !== '/search'`。Search 表單只在 `min-width: 961px` 隱藏。

TopNav 使用單向 watch（immediate）讀取 `/search` 字串 `q/lang`，處理前進／後退；只有 submit 才 push URL，不建立互相回寫的 watcher。Search 保留現有 debounce／URL 正規化；外部 URL 語言變更與初次載入使用同一個既有 `loadSearchLanguage()` 驗證，晚到語言解析不得覆蓋較新的 URL。URL 明確 lang 不得被 TopNav 的 `applyRememberedSearchLanguage()` 換成最近語言；對 invalid lang 清空選擇並提示，讓使用者明確更正。

Search 在表單**外**增加桌面可見的 `languageMissing` 提示，行動版保留原 control 提示，不重複宣告同一錯誤；TopNav 缺少語言時標示 `language-required`，submit 聚焦可見語言 control，不能聚焦 CSS 隱藏的頁內表單。直接 URL 明確語言無搜尋內容、URL 無語言且沒有最近語言，都保留 q 並能更正。

- [x] **4. 驗證實際接入路徑**

首頁案例不再 mock/期待 feed request；補預設搜尋 tab、搜尋 q 導向、切換翻譯原地呈現，以及舊 `/translate` 重導。導覽／搜尋案例覆蓋 URL 前進後退、無語言提示、明確無效語言、首頁 active，避免頂部草稿覆蓋帶入文字。既有 Search 搜尋／分頁案例繼續通過。

```bash
(cd web && npm test -- src/pages/HomeView.test.ts src/components/nav/TopNav.test.ts src/pages/Search.test.ts)
```

## Task 4: 整體驗收

- [x] **0. 套用首頁簡潔搜尋分頁與語言名稱修正**

首頁以搜尋為預設，以 Search／Translate tab 切換；搜尋採置中單輸入框，翻譯在原頁掛載工作台且隱藏冗餘搜尋動作。重用既有 i18n keys，只精簡 `home.subtitle`。

production 語言清單曾回傳 `name=Day / name_en=Japanese`、`name=Outstanding / name_en=English`。reference generator 的 canonical English 資料確認為 Japanese／English，問題在 `localizedName` 對英文 locale 執行一般 expression-edge 候選解析。跳過該猜測並回傳 canonical English expression；測試確保不執行 candidate query。

檢查：`HomeView`、TranslationForm、TranslationWorkbench 相關測試 41 項通過；`localizedName.test.ts` 17 項通過。第一次檢查發現 CSV 未跳脫英文逗號，以及一個 locale-name fake fixture 命中既有 curated translation，均已修正。

- [x] **1. 建置與文件檢查**

```bash
(cd web && npm run build)
./build.sh
git diff --check
```

各命令以 repo root 為起點；`build.sh` 不部署、不重建資料庫。未追蹤文件另外檢查：

```bash
git diff --no-index --check /dev/null docs/superpowers/specs/2026-09-29-home-translation-workbench-design.md
git diff --no-index --check /dev/null docs/superpowers/plans/2026-09-29-home-translation-workbench-implementation.md
```

exit 1 表示存在 diff，不自動當作格式錯誤；以實際格式診斷判斷。

- [ ] **2. 執行實際 Worker smoke test**

狀態：待有隔離 PostgreSQL 和本地 Worker 時執行。`backend/.dev.vars` 沒有 `DATABASE_URL`，設定中的 Hyperdrive 可能連到遠端資料；整合測試會註冊帳號，故本次不啟動 Worker、不寫入資料。

使用隔離 PostgreSQL 與本地 Worker，確認 limiter binding 可用後執行：

```bash
(cd backend && npm test -- tests/translationIntegration.test.ts)
```

不在 production 跑註冊或 burst 測試；不為 smoke test 增加公開測試端點。429 以 route fixture 驗證，不把最佳努力 limiter 當成第 11 次必定拒絕的精確計數器。

- [ ] **3. 桌面、行動與斷點回讀**

已在本機與線上瀏覽器讀回 1280×720 桌面首頁；正式站 390×844 行動版已確認頂部間距、搜尋按鈕位置、搜尋／翻譯分頁，以及翻譯來源和目標的名稱／代碼呈現。搜尋路由 `q`／`lang` 由 HomeView 測試涵蓋。960／961px 斷點及完整鍵盤與空值狀態仍待截圖驗證；相關 CSS 堆疊斷點已納入程式。

檢查 1280×800、390×844，另核對 960／961px 搜尋切換。確認 feed 不請求、首頁 tab、首頁隱藏全站搜尋、非首頁搜尋入口、無重複表單、語言提示可見、長文字無水平溢出及鍵盤 focus。清除、空白、未選目標與超長內容保持可理解狀態。

- [ ] **4. 完成訪客翻譯流程驗收**

route unit test 與前端 mock 測試已驗證訪客 NDJSON、限流、重試及結果呈現；正式 Worker 已確認 `TRANSLATION_GUEST_LIMITER` binding 為 10 requests/60s。沒有送出 production AI 翻譯請求；該流程仍待隔離 Worker／AI 環境驗收，以免將檢查輸入交給正式供應商或消耗正式用量。

在隔離環境的未登入瀏覽器於首頁選既有目標 locale，送出至少一筆有效翻譯；確認 pathname 不變、NDJSON 逐段顯示、結果能複製、替代／證據可展開、沒有投稿／建立 locale 入口。以既有測試 transport 驗證限流及服務失敗提示，輸入保留、手動重試可用；登入後仍能投稿。

核對取消、清除、修改語言、快速再次提交及離開首頁會 abort 舊請求，晚到結果不覆蓋新狀態。真實隔離 Worker／AI 環境未提供時明確記錄待驗證流程，不能用 mock、建置或 screenshot 代替實際成功驗收。

- [x] **5. 回讀原需求並更新完成狀態**

程式碼已回讀並符合原需求；Worker／AI 實際流程及 960／961px 斷點仍待驗證。已確認 390×844 行動 viewport 的翻譯選單名稱與代碼一致，並記錄正式部署版本；保留使用者其他改動，不自動提交。

- [x] **6. 部署並回讀正式站**

依使用者要求部署至 `langmap.io`。Wrangler 最新回報 version `43b5cadf-37e1-4e10-98ca-28f50a61c655`；部署輸出列出 Cloudflare Rate Limit binding。正式首頁顯示語言搜尋列及搜尋／翻譯分頁；語言清單能搜尋 Arabic 和 Pushto，翻譯來源顯示 `Japanese · jpn`，目標顯示 `Japanese (Japan) · jpn-Jpan-JP`。

## 本次審查修正

- **契約缺口：** 原計畫只改 HTTP integration 的 401，漏改真正 route fixture；現已分開 mock route 與真實 Worker 驗證。
- **可靠性：** 補 429 可重試、503 失敗行為、訪客權限、取消／競態驗收；移除「不得新增／執行測試」限制及只憑建置判定完成的條件。
- **搜尋可用性：** 固定 960px 導覽斷點，提示留在可見區域；區分明確語言、最近語言與無語言，分開查詢和翻譯驗證。
- **國際化完整性：** 原先 `en.ts` 有 523 個 UI key，但 locale CSV 缺 87 個 key，且翻譯工作台原有 82 個 key 不在 CSV；補齊全部五種 locale，並讓 `i18n:check` 驗證 key、locale 欄位與英文來源。
- **減少改動：** 只增加一個工作台、沿用 Progress 訊息介面；不做猜測 locale 的交換、獨立捲動或額外 store。
- **設定與文案：** 使用正式 `ratelimits`，不要求跨環境共用計數器；補英文來源目錄與 i18n 檢查。

## 參考

- [Cloudflare Rate Limiting](https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/)：正式設定、namespace 共用及每 location 最佳努力限制。每 IP 限流保留已確認方案；共用網路的訪客會共用 bucket，不新增身份系統。
