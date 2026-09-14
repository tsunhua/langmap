# 詞句翻譯 tab 與生成式翻譯流程設計

> 日期：2026-09-14
>
> 狀態：需求已確認；待施工
>
> 關聯：[CONTEXT.md](../../../CONTEXT.md)、[ADR 0006](../../adr/0006-generated-translation-boundary.md)

## 1. 摘要

LangMap 新增一個登入後才可見的「詞句翻譯」tab。使用者輸入一段受長度限制的純文字，選定目標 `language_locale`，系統先以完整輸入做精確匹配快徑：若 canonical graph 已有合格的直接或兩跳對照，直接回傳既有目標文字，不呼叫 AI。沒有可用的完整精確匹配時，才以 Workers AI 分析來源語言與不確定片段，再從 LangMap canonical graph 做完整輸入加上片段的檢索。檢索最多一跳直接對照，或經一個核准中介語言的兩跳對照；需要生成時才由 LLM 以目標 locale 生成純文字譯文。

請求與結果均為暫態資料。系統不因生成結果自動建立 `expression`、`expression_edge`、來源標記或 AI provenance。使用者若確認結果，可只把一個主要譯文預填到既有 `/contribute` 流程，編輯並明確送出後才成為一般使用者貢獻。

第一版固定使用 Cloudflare Workers AI binding 與 `@cf/zai-org/glm-4.7-flash`；路由不依賴大型通用 LLM SDK。前端使用獨立的 `fetch` 串流客戶端，不沿用現有 Axios 的 15 秒 timeout。

## 2. 背景與現有限制

1. 現有 `/translate` 與 `/translate/:code` 是介面文案翻譯工作台，後端 API 在 `/api/v2/localization/...`。新功能不能與這組頁面共用同一路由語意。
2. 現有 `/api/v2/expressions/search` 是 prefix range 搜尋；`/api/v2/expressions/:id/graph` 是給圖譜頁面的 BFS，會在每一跳套用 `target_language`，因此會阻斷需要 pivot 的兩跳路徑，也不適合作為翻譯熱路徑。
3. canonical graph 的節點是已存在的詞句；檢索只能讀取它們，不能把模型產物當成 canonical knowledge。
4. Worker 目前只有 D1、R2、Assets 與 secret binding，沒有 Workers AI binding。新增 binding 後必須重新產生 `worker-configuration.d.ts`，不可手寫或硬編 secret。
5. 現有 `POST /api/v2/contributions` 會對輸入 expressions 建立 complete clique；翻譯確認流程只能提交一個來源／目標 pair，不能把 alternatives 一起送出。
6. Cloudflare Workers HTTP response 可以在 client 仍連線時串流；本功能仍須用明確的 body、候選數量、AI 輸出與時間上限，避免無界緩衝或失控成本。

## 3. 目標

- 提供獨立、可理解且可鍵盤操作的詞句翻譯入口。
- 支援來源語言自動偵測，也允許使用者搜尋並修正來源語言；目標必須是精確的 `language_locale`。
- 先對完整輸入執行精確匹配快徑；快徑沒有合格結果時，才由 planner 找出最多八個低把握片段，再對完整輸入與片段批次檢索。
- 檢索最多兩跳，第二跳只可使用十個固定核准中介語言，且兩條 edge 都必須通過品質門檻。
- 精確匹配快徑直接回傳 canonical 目標文字；需要生成時才以單次 POST 回應狀態、來源判定、檢索參考與譯文 delta，在可接受延遲內即使檢索或 planner 降級，仍能產生 model-only 譯文。
- 給出可核對的檢索路徑；沒有任何證據時明確標示「僅模型生成」，有證據時以證據本身說明，不增加「LangMap 輔助」徽章。
- 讓使用者在確認、編輯後才可進入既有貢獻流程，且不新增 AI 永久 provenance。
- 初始 beta 使用 Workers AI 的每日免費 Neurons 配額；配額耗盡時清楚回報並等待 UTC 重設，不自動換模型。

## 4. 非目標

- 不建立翻譯歷史、收藏、分享連結、背景工作、輪詢 job 或翻譯結果資料表。
- 不自動新增或更新 `expressions`、`expression_edges`、`expression_locale_links`、`expression_sources`、`expression_edge_sources` 或 votes。
- 不在本版使用網路搜尋、外部字典、embedding、Vectorize 或 RAG 服務；檢索來源限於 LangMap canonical graph。
- 不提供自由格式的 style prompt、語氣滑桿、system prompt 編輯或 HTML/Markdown 輸出。
- 不實作多 provider 自動 failover，也不因模型無法涵蓋某一 locale 而偷偷換模型。
- 不在本版更新隱私政策或建立逐次 AI 輔助事件稽核模型；這是已知 launch risk，不得因此省略最低限度的內容與 secret 保護。
- 不改動 `apple/` SwiftUI 客戶端。

## 5. 領域模型與生命週期

以下術語須與 `CONTEXT.md` 一致：

| 實體 | 生命週期與邊界 |
| --- | --- |
| 翻譯請求（Translation Request） | 登入使用者送出的暫態 `{text, source_lang_code?, source_locale_code?, target_locale_code}`。只存在 request 記憶體與前端狀態，不寫入 canonical 表。 |
| 翻譯結果（Translation Result） | 主要譯文、零至兩個參考 alternatives、來源語言、目標 locale、檢索證據與 `model_only` 狀態。完成、取消或離開頁面即失去；不視為 expression 或 mapping。 |
| 精確匹配快徑（Exact Translation Fast Path） | 完整輸入經既有 expression identity 正規化後，命中 source expression，並以合格的 direct 或單一核准 pivot two-hop path 解析到 target locale expression。按穩定排名直接回傳 canonical target text，不呼叫 planner 或 generation；片段命中、prefix 命中或沒有合格 edge 均不符合。 |
| 檢索證據（Retrieval Evidence） | 來自 canonical graph 的直接 edge 或一個核准 pivot 的兩條 edge，含可展示的文字、locale、路徑與來源標記摘要。被模型採用不會創建任何 row。 |
| 核准中介語言（Approved Pivot Language） | 固定 ISO 639-3：`eng`、`cmn`、`jpn`、`spa`、`fra`、`deu`、`por`、`kor`、`rus`、`arb`。只可出現在兩跳中間；不能讓模型動態宣告新的 pivot。 |
| AI 輔助貢獻（AI-assisted Contribution） | 從結果頁把一個主要譯文預填到既有貢獻頁，使用者可編輯、檢查並明確送出。確認區說明 AI 輔助；送出後仍是使用者貢獻，第一版不保存永久 AI 標記。 |

此邊界由 [ADR 0006](../../adr/0006-generated-translation-boundary.md) 固化。配額計數若需要持久化，只能保存 user、時間窗與計數等營運資料，不能保存原文、譯文或 prompt。

## 6. 使用者流程

### 6.1 進入與登入

1. TopNav 桌面與 mobile drawer 都新增「詞句翻譯」連結；只在 auth store 已確認有使用者時渲染。尚未完成 auth hydration 時預設隱藏，避免匿名閃現入口。
2. 匿名使用者看不到入口。直接開啟 `/translate` 時由 router auth guard 導向 `/auth?return=%2Ftranslate`（保留回跳位置）；API 仍以 `401 AUTH_REQUIRED` 為權威。登入後回到翻譯頁，不保存文字到 URL。
3. 原介面文案工作台搬到 `/ui-translation` 與 `/ui-translation/:code`。舊路徑不加 redirect alias；`/translate` 從此只代表詞句翻譯，`/translate/:code` 不保留為舊工作台入口。介面文案 API 與工作台功能本身不變。

### 6.2 填寫請求

1. 來源語言欄預設為「自動偵測」，可搜尋 language registry 的語言名稱或 ISO 639-3 code；使用者選定後以該 code 覆蓋模型偵測。一般請求只選語言，不要求來源 locale。
2. 目標欄使用可搜尋、分頁的 `language_locales` picker；所有可成功解析的 `language_locales` row 都可選（現行 schema 沒有通用的 active flag），不限於 `ui_locales.status='active'`。提交時傳精確 canonical locale code。
3. 文字欄是單一 textarea，接受純文字、換行與有意義標點。外層空白可修剪，內部換行與標點必須保留；不執行、不渲染 HTML/Markdown 指令。
4. 前端以 Unicode grapheme cluster 顯示 `0 / 500` 計數；超過 500 個可見字元時即時阻止提交。後端以等價 Unicode 計數作權威檢查，另限制 text UTF-8 不超過 8 KiB，整個 JSON body 不超過 16 KiB。
5. 允許一般空白（含 `\n`、`\r\n`、tab），拒絕空字串、NUL 與其他不可接受控制字元；辨識到 HTML tag 或 fenced Markdown 時回 `PLAIN_TEXT_ONLY`，不嘗試清理後送給模型。
6. 送出按鈕在輸入、來源與目標通過驗證後啟用。請求進行中顯示取消按鈕；再次送出會先取消前一筆，前端以 request sequence 丟棄 stale stream。

送出後先執行完整輸入的精確匹配快徑。快徑命中時不進入「分析詞句」或「生成譯文」，只顯示檢索與結果；未命中才進入 planner 與片段檢索。

### 6.3 結果與確認

1. 進度依序呈現「分析詞句」、「檢索參考」、「生成譯文」三階段。每個階段有可讀狀態文字，不依賴顏色或動畫。
2. 主要譯文以 delta 串流顯示；完成後可複製、重試或重新編輯輸入。輸出一律當純文字顯示。
3. 有至少一條合格證據時顯示可展開的「檢索參考」，列出來源片段、目標候選與 `來源 → 目標` 或 `來源 → pivot → 目標` 路徑；不顯示內部整數 ID，也不增加「LangMap 輔助」徽章。
4. 沒有證據，或檢索逾時而降級時，在結果附近顯示「僅模型生成」。這是 provenance 狀態，不是品質分數。
5. 精確匹配快徑命中時顯示「精確匹配」狀態與檢索路徑，不顯示「僅模型生成」，也不顯示 AI 輔助確認。若 canonical candidate 已是使用者要求的現有對照，預設不提供重複貢獻按鈕；使用者改寫主要譯文後仍可進入貢獻流程。
6. 若檢索得到不同且排名足夠的目標文字，可顯示最多兩個「參考譯法」alternative；第一版 alternatives 只來自證據候選，不額外呼叫第二次 LLM。它們留在本次頁面狀態，不會自動進入貢獻。
7. 「送入貢獻」只帶一個使用者選定的主要譯文與來源／目標 locale，透過記憶體中的暫態 prefill state 開啟 `/contribute`，不把原文或譯文放入 query string。需要 AI 的結果在貢獻頁顯示 AI 輔助確認文字；精確匹配結果不顯示該提示。使用者可修改兩列內容後才按既有送出按鈕；alternatives 不一併提交。

## 7. 前端資訊架構與可及性

### 7.1 路由與模組

- 新頁面建議命名為 `ExpressionTranslation.vue`，路由固定為 `/translate`；頁面只負責組合表單、串流狀態、結果與貢獻 prefill。
- `TranslateWorkbench.vue` 搬成語意清楚的 `UiTranslationWorkbench.vue`（或等價檔名），路由改為 `/ui-translation`、`/ui-translation/:code`；現有 `web/src/api/localization.ts` 契約維持不變。
- 新增 `web/src/api/translation.ts` 的型別與 `web/src/composables/useTranslationStream.ts`。串流使用 `fetch` + `AbortController` 解析 NDJSON，不改動共用 Axios 15 秒 timeout。
- 可重用的視圖拆成 `TranslationForm`、`TranslationProgress`、`TranslationResult`、`EvidenceList`；語言選擇沿用或薄封裝現有 language/locale picker，避免另建一套 registry 查詢。
- 新 UI 字串使用獨立 i18n namespace（例如 `phraseTranslate`），不與舊工作台的 `translate` key 混用；缺少譯文時依現有 fallback 規則顯示。

### 7.2 視覺與互動

- 沿用 `web/src/assets/atlas.css` 的暖紙張背景、陶土色 accent、藍色關係線與低圓角；不新增另一套色彩、陰影或圓角 token。
- 表單採 content-first 直向流程；寬螢幕可把語言控制並排，結果與證據在其下方；小螢幕改為單欄，不讓長詞句撐破容器（Grid/Flex 子項設 `min-width: 0`）。
- 所有欄位都有可見 label、錯誤訊息與 focus 樣式；placeholder 不代替 accessible name。送出、取消、複製、展開、送入貢獻等觸控目標至少 44px。
- 驗證錯誤在欄位旁 inline 顯示，並在表單頂端提供可 focus 的錯誤摘要；串流階段使用 `role="status"`/`aria-live="polite"`，失敗使用 `role="alert"`。
- 進度與結果不因每個 delta 改變頁面主要布局；證據區預留穩定空間，避免 Cumulative Layout Shift。動畫只用於狀態回饋，尊重 `prefers-reduced-motion`。
- 桌面與行動手動檢查至少 375、768、1024、1440px viewport；鍵盤可完成選擇、提交、取消、展開證據與送入貢獻。

## 8. API 契約

### 8.1 Endpoint

`POST /api/v2/translate`

這是一次性 action endpoint，不代表持久化 Translation resource。路由掛在 `backend/src/routes/`，使用 `requireAuth` 與 `utils/response.ts`。所有請求與回應加 `Cache-Control: no-store`，不進 edge/browser cache。

### 8.2 Request

```json
{
  "text": "輸入的詞或句子",
  "source_lang_code": null,
  "source_locale_code": null,
  "target_locale_code": "jpn-Jpan-JP"
}
```

- `text` 必填；非空純文字，最多 500 grapheme clusters、8 KiB UTF-8。
- `source_lang_code` 可省略或為 `null` 代表自動偵測；若有值必須是已註冊 ISO 639-3 code，且使用者選擇優先於模型偵測。
- `source_locale_code` 只在來源 locale/script 需要消歧時選填，且其 language 必須等於 `source_lang_code`；一般來源 picker 不要求此欄位。
- `target_locale_code` 必填，必須精確對應 `language_locales.code`。不存在、格式錯誤或與 source locale 不相容時，不開啟串流，直接回 400/404。
- Request body 受 16 KiB 上限約束；不可接受控制字元、HTML tag 或 fenced Markdown 回 `VALIDATION_FAILED` / `PLAIN_TEXT_ONLY`。

### 8.3 Stream response

驗證、auth 與配額通過後回 `200 OK`，`Content-Type: application/x-ndjson; charset=utf-8`。每行都是既有 API envelope；成功事件形如 `{"success":true,"data":{...}}`，錯誤事件形如 `{"success":false,"error":"...","message":"..."}`。精確匹配快徑也使用同一串流契約，但可在 evidence 後立即送 result；不得轉發 provider 原始 chunk 或 chain-of-thought。

`data.type` 事件如下：

| type | 欄位 | 說明 |
| --- | --- | --- |
| `status` | `stage: analyzing \| retrieving \| generating`、`mode: exact_lookup \| assisted`、`request_id` | 階段開始；精確快徑只送 `retrieving`，分析事件應在回應建立後盡快送出。 |
| `source_language` | `code`、`confidence`、可選 `candidates` | 最終採用的來源語言。使用者明確選取時 confidence 為 `1`。 |
| `source_confirmation_required` | `candidates`、`reason` | 自動偵測低於設定門檻，要求使用者選取 language（或同語言 script 的 source locale）後重送；送出此事件即正常結束本串流，不進入生成。 |
| `evidence` | `items`、`omitted_count`、`degraded` | 檢索完成或逾時。items 為已排序、去重、受上限約束的可展示路徑。 |
| `translation_delta` | `text` | 主要譯文的純文字增量；前端按收到的順序串接。 |
| `result` | `translation`、`alternatives`、`source_lang_code`、`target_locale_code`、`evidence_present`、`model_only`、`resolution: exact_lookup \| assisted`、`generation_skipped`、`request_id` | 唯一完成事件；`alternatives` 最多兩項。精確快徑為 `resolution=exact_lookup`、`generation_skipped=true`、`model_only=false`。 |
| `error` | `code`、`retryable`、可選 `retry_after_seconds`、`reset_at` | 串流開始後的失敗；前端保留可重試的輸入，不把 partial text 當完成結果。 |

Evidence item 至少包含 `source_text`、`target_text`、`target_locale_code`、`path_type`（`direct` 或 `two_hop`）、可選 `pivot_lang_code`、`match_type`（`exact` 或 `prefix`）與來源標記摘要。分數可用於排序，但不向使用者承諾為翻譯品質百分比。

### 8.4 HTTP 狀態與錯誤

- `400 VALIDATION_FAILED`、`PLAIN_TEXT_ONLY`、`INVALID_LANG_CODE`、`INVALID_LANGUAGE_LOCALE_CODE`：請求格式或欄位錯誤。
- `401 AUTH_REQUIRED`：未登入；不回傳任何翻譯內容。
- `404 TARGET_LOCALE_NOT_FOUND`：目標 locale 不存在。
- `409 SOURCE_LANGUAGE_AMBIGUOUS`：可在不開串流時直接回候選；若已送出階段事件，則使用 `source_confirmation_required`。
- `429 TRANSLATION_RATE_LIMITED`：超過每分鐘或每日 user quota；帶 `Retry-After`，每日限制另帶 UTC `reset_at`。
- `503 AI_DAILY_QUOTA_EXHAUSTED`：Workers AI 帳戶每日免費 Neurons 用盡；不自動換模型，帶 UTC `reset_at`。
- `502 AI_PROVIDER_FAILED`、`504 TRANSLATION_TIMEOUT`、`413 TRANSLATION_OUTPUT_TOO_LARGE`：生成失敗、逾時或超過輸出上限；可重試時 `retryable=true`。

串流已建立後 HTTP status 不能再改寫；此時以最後一個 error envelope 結束，並關閉 stream。

## 9. 後端處理管線

### 9.1 路由層

`translation` route 只做邊界工作：

1. `requireAuth` 取得 user id。
2. 以 bounded body reader 讀取並驗證 JSON、UTF-8/grapheme/控制字元、source/target registry。
3. 執行 server-side distributed quota；先檢查 user quota，再建立串流。
4. 建立 `AbortController` 與 request id；若進入精確快徑，先送 `status: retrieving, mode: exact_lookup`，否則送 `status: analyzing, mode: assisted`。
5. 呼叫 translation orchestrator，把事件映射為標準 envelope；不在 route 寫 SQL 圖遍歷或 provider prompt。

### 9.2 精確匹配快徑

`translationExactMatch` 在 planner 前執行一次受限的完整輸入查詢，讓已存在於 LangMap 的翻譯不必再次付出 AI 延遲與 Neurons 成本：

1. 以既有 `canonicalizeExpressionText` 對完整輸入做 NFC/identity 正規化，但保留原始文字給後續 model path。若使用者指定 source，只查該 language；source 未指定時查所有 language，但只保留能解析到目標 locale 的候選，並以固定上限與 `ORDER BY` 控制跨語言查詢。
2. 先查 source expression 到 target locale expression 的合格 direct edge。direct 沒有結果時，再查一個固定核准 pivot 的合格 two-hop path；不查 prefix、片段、三跳或未核准 pivot。
3. source expression 必須是完整輸入的 exact text；target expression 必須有 `expression_locale_links` 精確連到請求的 target locale；edge 使用 retrieval service 相同的品質 predicate。片段 exact、prefix 命中或只有不合格 edge，不能短路整句生成。
4. direct path 優先於 two-hop；其餘按 match（此處皆 exact）、edge score、provenance marker 數、候選文字長度與 expression/edge id 的穩定順序選出主要文字，最多留下兩個不同 target text 作 alternatives。這個排序不代表模型信心；source expression、path 與 target candidate 的查詢總量必須受與 assisted path 相同的 bounded 上限約束。
5. source 未指定且 exact candidates 涉及多個無法由排名消歧的 source language 時，送 `source_confirmation_required` 並結束串流，不呼叫 AI；使用者選定 source 後重送。只有單一 source language 時可由資料直接送 `source_language`，confidence 為 `1`。
6. 命中後送 `evidence` 與 `result`，`resolution=exact_lookup`、`generation_skipped=true`、`model_only=false`；不呼叫 planner、retrieval fallback 或 generation。此請求仍計入 user request quota，但不消耗 Workers AI Neurons。

### 9.3 Planner

`translationPlanner` 使用同一個 Workers AI model 做一次非串流 structured-output 呼叫。Workers AI JSON mode 目前不能保證 schema，且不支援 streaming，因此回傳後必須由手寫 type guard（或小型既有 validator）逐欄驗證，不能直接信任 JSON。

Planner schema 的語意如下：

```text
source_lang_code: ISO 639-3
source_confidence: 0..1
uncertain_spans: 0..8 items
  start/end: Unicode code-point offsets, start < end
  text: must equal the corresponding input substring
  reason: unknown_term | idiom | proper_noun | domain_term | context_ambiguity
  confidence: 0..1
```

只保留輸入中可驗證、互不重複且不超過八項的 span；重疊片段合併。`reason` 是固定分類，不保存或展示模型推理過程。

- 使用者指定 source 時，planner 只負責 span，不可覆蓋 source code。
- source 未指定且 confidence 低於設定門檻（初始 0.75，需以 benchmark 校準）時，送 `source_confirmation_required`，不猜測後繼檢索。
- structured output 無效、planner 逾時或無法解析時，不重試 planner。若 source 已由使用者指定，仍以完整輸入作唯一檢索根；若 source 也無法從 planner 安全取得，跳過 graph 檢索直接走 model-only generation，避免猜錯語言、增加延遲與成本。

### 9.4 Retrieval service

`translationRetrieval` 是精確快徑 miss 後使用的輔助服務，直接使用 D1，不呼叫既有 graph HTTP endpoint。它必須 bounded、cycle-safe、批次化且穩定排序。

1. **根集合**：完整輸入永遠是第一根；planner 有效 span 依輸入出現順序加入，最多八個，共最多九根。
2. **文字匹配**：使用現有 `canonicalizeExpressionText` 的 identity 規則做 exact match；沒有 exact 才做 prefix range fallback。每根最多保留三個 prefix candidate。原始輸入交給模型時不改寫。
3. **語言限制**：根 expression 的 language 必須等於最終 source language。目標 expression 必須屬於 target locale 的 language，並有 `expression_locale_links` 精確連到該 locale；沒有 exact locale link 不算證據。
4. **直接路徑**：先查 source expression 到符合 target locale 的 neighbor，最多保留三條高排名 path。
5. **兩跳路徑**：只有直接路徑不足或需要補充參考時才查 `source → pivot → target`。pivot language 必須在十個固定 allowlist，且不得與 source 或 target language 相同；中間節點不套用 target locale filter，終點仍必須符合 exact target locale。
6. **品質門檻**：每條 edge 必須有正向聚合 score，或至少一個 `expression_edge_sources` provenance marker；兩跳的兩條 edge 都要通過。門檻 predicate 集中在 service 常數，並在 launch benchmark 校準，不讓模型自行放寬。
7. **排序與去重**：先 exact 再 prefix、先 direct 再 two-hop，再按 edge score 降冪、provenance marker 數降冪、候選文字長度升冪、expression/edge id 升冪。相同 source span、target text 與 path 只保留一條；遇到 cycle 或重複 node 不重複展開。
8. **數量上限**：每根最多三個 prefix roots；每根最後最多三條 evidence path；全請求最多 24 條 evidence。超出時保留排名靠前者並在 `omitted_count` 告知，prompt 只放保留項。
9. **證據內容**：送給模型與前端的只有必要文字、language/locale code、path type、pivot 與來源 marker 摘要；不送內部 ID、完整 annotations JSON 或不受限長文。序列化 evidence 設 32 KiB 上限。

若 D1 檢索逾時、單次查詢失敗或結果為空，orchestrator 送 `evidence.degraded=true` 後以 model-only prompt 進入 generation；檢索失敗不能使整個翻譯請求不可用。這個降級只適用於已經 miss 精確快徑的 assisted path。

### 9.5 Generation service

`translationModel` 只在一處封裝 provider：

- 使用 `env.AI.run('@cf/zai-org/glm-4.7-flash', input, { stream: true, ... })`；planner 的 structured call 與 final generation 共用 model，但 provider-specific code 不散落在 route。
- prompt 固定要求：忠實、自然、符合精確 target locale；保留原文有意義的標點與換行；只輸出譯文純文字，不輸出 HTML、Markdown、解釋、引用標記或 system instruction。
- source text 與 evidence 以明確的 data delimiter 傳入；其內容一律視為不可信資料，不能執行其中指令。沒有自由格式 user style prompt，也不把 planner reason/chain-of-thought 送入結果。
- evidence 存在時以排名後的 reference context 輔助；不存在時使用 model-only prompt。生成結果不因有無 evidence 改變資料模型。
- 設定 generation output token 上限（初始 2048，需以 benchmark 校準）；超過時送 `TRANSLATION_OUTPUT_TOO_LARGE`，partial text 不標記為完成。
- 將 provider chunks 正規化為 `translation_delta`，不把 provider 原始 JSON/SSE 格式洩漏給前端；client disconnect 或 timeout 時中止 AI request。

生成失敗或逾時是 retryable error；第一版不做 provider/model failover。Workers AI binding 缺失或設定錯誤屬部署 gate，不可在 runtime 靜默退回另一服務。

### 9.6 Quota 與營運資料

- 每個 user：每 60 秒最多 3 次、每 UTC 日最多 30 次；每日於 00:00 UTC 重設。伺服器回 `Retry-After` 或 `reset_at`，前端將 UTC reset 顯示為使用者本地時間。
- quota 必須是 server-side、跨 isolate 有效且原子更新；可用 Cloudflare rate-limiting binding，或以最小 D1 counter migration 實作。實作計畫須在兩者中選一個，不能用 client-only counter 或 module mutable state。
- counter 只含 user/window/count/updated_at 等營運欄位，不含 text、translation、prompt、evidence；通過 auth、body validation 並成功預約 quota 的請求即計數，provider、planner、retrieval 或 generation 失敗不退回計數。
- 指標只記錄 request id、階段 latency、結果類型（evidence/model-only）、錯誤 code、token/Neurons 估算與 quota 狀態；禁止 console log 完整輸入、輸出或 prompt。

## 10. Workers AI、成本與效能基線

### 10.1 Provider 決策

固定使用 `@cf/zai-org/glm-4.7-flash`。Cloudflare model page 將它描述為支援 100+ languages、低延遲、131k context、function calling/reasoning；正式上線前仍須用 LangMap 語言／locale benchmark 驗證，不把供應商描述當成產品品質保證。

依 2026-09-14 查到的官方資料，Workers AI Free 與 Paid Workers 各有每日 10,000 Neurons allocation；Paid 超出後按 Neurons 計費。GLM 4.7 Flash 的頁面列出 input/output 單價。正式上線前重新核對[Workers AI pricing](https://developers.cloudflare.com/workers-ai/platform/pricing/)與[模型頁](https://developers.cloudflare.com/workers-ai/models/glm-4.7-flash/)，規格中的數值不作永久價格承諾。

Beta 策略：帳戶的免費 Neurons 尚未耗盡時正常服務；收到 provider quota exhausted 時回 `AI_DAILY_QUOTA_EXHAUSTED`，顯示下一個 UTC reset，不自動換模型或向使用者收費。若日後要啟用 Paid overage，另立成本與告知決策，不在本版默認開啟。

### 10.2 時間與資源 budget

在 staging fixture 與代表性 locale matrix 量測，首版 acceptance budget 為：

- 精確匹配快徑在驗證後 p95 ≤ 500 ms，且不呼叫任何 AI；user quota 仍照常計數。
- 驗證後的第一個 `status` event p95 < 500 ms。
- planner 最多 2.5 s；無效或逾時立即走完整輸入 fallback，不重試。
- retrieval 最多 2.0 s；逾時即 model-only generation。
- 從 request 開始到送出 `generating` 不超過 6 s。
- generation 最多 9 s；整體正常完成 p95 ≤ 15 s。
- 受限的根、candidate、path、evidence 與 prompt bytes 必須在本 spec 上限內；不得把整個 graph 或輸入無界讀進記憶體。

Workers 可在 client 仍連線時串流，因此不以背景 task 代替回應；所有 AI、D1、timeout 與 abort promise 都必須被 await/處理。部署設定使用 Workers AI binding 與 `wrangler types` 產生的 Env，不把 token 寫入 repo。

## 11. 舊功能搬遷與資料相容

- Router：新增 `/translate` component，將原兩條 route 改為 `/ui-translation`、`/ui-translation/:code`；刪除舊 `/translate/:code` route，不設 redirect。
- Nav：只把新詞句翻譯 link 加到 TopNav 桌面與 mobile drawer，並以 `auth.user` 隱藏匿名入口；舊工作台不新增公開 tab。
- 頁面／測試／所有 `router-link` 與 route assertions 一併更新；localization API path、project id、D1 localization 表不改。
- 翻譯內容本身不需要 schema migration。若配額選 D1 counter，migration 只保存營運計數，且不得與 canonical graph 或 AI provenance 混合；schema、migration、rollback 與測試列入施工計畫。

## 12. 安全與已知風險

- 翻譯 endpoint 一律 auth；route guard 只改善 UX，API 401 才是權威。錯誤訊息不回顯 secret、provider prompt 或不必要的完整輸入。
- 前端與後端都把輸入與 evidence 當資料，不執行 markup 或工具指令；輸出使用 text node/純文字，不使用 `v-html`。
- stream 設 `no-store`；不把文字放 query、localStorage、analytics 或 persistent log。瀏覽器離開頁面即丟棄暫態結果。
- Workers AI 外部資料處理與隱私政策本輪不展開；但實作與 release checklist 必須保留「未更新政策」風險，並確認部署未寫入 secret、完整內容或 prompt。
- Provider 可能對低資源語言輸出品質不足；所有 locale 仍可選，但 benchmark、錯誤率與 model-only 比例要按 locale 觀測，不以沒有 graph evidence 宣稱翻譯不可能。
- 沒有 evidence 不代表譯文錯誤；「僅模型生成」只描述 provenance，不能當信心分數或社群認證。

## 13. 驗證與完成條件

### 13.1 後端

Vitest/Worker runtime 測試至少覆蓋：

- auth、body size、500 grapheme、8 KiB、控制字元、plain-text、source/target locale validation。
- planner valid、invalid、timeout、重疊/錯位 span、source override 與低 confidence confirmation；invalid planner 不重試且仍能 model-only generation。
- 完整輸入 exact direct/two-hop fast path 會在 mock AI 呼叫計數為零時回傳 canonical target；片段 exact、prefix、無 target link、品質不合格與 source ambiguity 不會誤走快徑。
- exact 優先、prefix fallback 最多三項、direct 優先、兩跳 pivot allowlist、同語言 locale conversion、target exact locale link、品質 predicate、cycle/dedup、穩定排序、24 條 evidence cap。
- target filter 不阻斷 pivot；不誤把三跳或未核准語言當證據；D1 timeout 會降級而非失敗。
- NDJSON envelope/order、delta 組裝、abort、provider failure、generation timeout、output cap、user minute/day quota、UTC reset 與 Workers AI account quota error。
- mock AI binding，不在測試使用真實 token 或把 fixture 原文寫入 logs。

### 13.2 前端

- router 新舊路徑、匿名隱藏 nav、直接 URL login return、auth 後顯示 nav。
- source auto/manual、target locale search/select、grapheme counter、inline validation、取消/stale request、三階段進度、model-only 與 evidence panel、retry/copy。
- evidence-derived alternatives 最多兩項，送貢獻只帶主要 pair；prefill 不進 URL，確認文字可見且可編輯。
- keyboard/focus、ARIA live/error、44px targets、純文字輸出、`prefers-reduced-motion` 與 375/768/1024/1440 viewport 手動檢查。
- `cd web && npm run build` 必須通過；`cd backend && npm test` 與需要本地 Worker 的整合流程一併執行。

### 13.3 品質與效能 gate

建立不含 production dump 的固定 fixture 與代表性 locale matrix，至少覆蓋十個 pivot、CJK script conversion、長句、emoji/newline、無 evidence、direct/two-hop evidence。只有在 p95 budget、輸出純文字、locale regression 與錯誤降級通過後，才可把 beta flag 對登入使用者開啟。

## 14. 方案比較與取捨

### A（採用）：直接 Workers AI binding + 專用 bounded retrieval + NDJSON

- 優點：符合 Cloudflare 執行環境、bundle 小、planner JSON 與 final stream 可分開處理、容易控制兩跳與 quota、沒有不必要的 provider abstraction。
- 代價：要自行寫 schema guard、chunk normalization、stream parser 與測試；這些責任集中在少數 service，可用小型純函式測試控制風險。

### B（不採用）：`workers-ai-provider`/Vercel AI SDK

- 優點：現成 provider adapter、stream helper 與部分型別。
- 代價：引入與本需求不匹配的通用抽象；Workers AI JSON mode 仍不能 streaming，且會掩蓋 quota/abort/NDJSON 契約。若未來真的需要多 provider，另立 provider boundary ADR。

### C（不採用）：非同步 job + 持久化結果

- 優點：可承受較長生成、可重試與歷史查詢。
- 代價：違反本版暫態結果邊界，增加 job/result schema、polling、清理與隱私風險，亦無助於首個可見 progress 的延遲。

### D（不採用）：直接重用 mapping graph endpoint

- 優點：看似可少寫 SQL。
- 代價：現有 endpoint 在每一跳套用 target filter，無法正確經 pivot；圖譜的 200 node/三跳語意也不同於翻譯的 bounded path retrieval。翻譯服務應重用穩定排序與 cycle-safe 原則，但不能重用其 HTTP 契約。

## 15. 施工前檢查清單

- [ ] 使用者已確認本 spec 與 ADR 0006；下一步才建立 implementation plan。
- [ ] 以 `wrangler` 加入 Workers AI `AI` binding，重新產生 Env types，確認 staging 可呼叫固定 model。
- [ ] 決定 quota counter 使用既有可用的 Cloudflare rate limit 或最小 D1 migration，並完成資料模型與回退設計。
- [ ] 建立 retrieval fixture、planner schema fixture、locale benchmark 與 p95 measurement harness。
- [ ] 完成前端 `/translate` 新頁面與 `/ui-translation` 搬遷後，再依驗證章節執行 build/test；本 spec 本身不代表功能已上線。
