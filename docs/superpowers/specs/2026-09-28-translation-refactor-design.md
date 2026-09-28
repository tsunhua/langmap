# 詞句翻譯重構：即時譯文、locale 選詞與按詞查閱

> 日期：2026-09-28
>
> 狀態：已實作並完成本機驗證；未部署。
>
> 關聯：[原翻譯設計](2026-09-14-expression-translation-design.md)、[ADR 0006](../../adr/0006-generated-translation-boundary.md)

## 需求與當前事實

使用者要求解決翻譯慢、畫面雜亂與重複、指定 locale 的詞語未優先採用，以及 AI 接口延遲。參考 Google 翻譯的原文／譯文工作區，並依使用者要求，點擊譯文中的詞或短語後才顯示參考內容。

施工前程式碼已確認下列問題（已在本次重構修正）：

- `generation.ts` 使用 `stream: false`，等待整段 completion 後才呼叫一次 `onDelta`。前端收到的是 NDJSON，但上游沒有逐段輸出譯文。
- `orchestrator.ts` 在一般 assisted 路徑依序等待 planner、檢索、generation；已指定來源語言也呼叫 planner。同一模型承擔兩次 AI 請求。
- `retrieval.ts` 依序遍歷 roots 與候選，每次等待 direct、必要時再等待 two-hop；metadata 雖部分批次讀取，整個流程仍有多次串行資料庫往返。
- `exactMatch.ts` 與 `retrieval.ts` 先按目標語言、路徑、score 等排序及截斷，最後才取得 target expression 的 locale links。指定 locale 沒有參與候選 SQL 排名。
- exact 快徑的 `localeShape` 僅比較語言、script、orthography，忽略 region 與 place；沒有 locale metadata 也被當成 compatible。
- `TranslationProgress.vue` 預設展開，重複展示譯文與 evidence；`TranslationResult.vue` 再展示整句及 alternatives；`EvidenceList.vue` 再展示 evidence。
- assisted result 的 alternatives 直接從 evidence 的 target text 取得；片段的譯詞可能被當成整句的替代翻譯。

以上是施工前的流程與契約問題。實測結果及仍未驗證的範圍見下方「實作結果」；不承諾固定秒數。

## 方案選擇

1. **建議：生成前保留小而有界的 locale 詞典檢索，譯文真串流，詳情按需載入。** 可以同時改善指定 locale 用詞、等待時間與畫面。已指定來源的一般請求只需一次生成 AI 呼叫。
2. 先純 AI 翻譯，事後才查詞典。首字可能更快，但無法讓已生成的句子優先使用詞典中的 locale 用詞；需要重譯才能補救。
3. 保留現有 AI planner 串行流程，只整理 UI。改動較小，但保留雙 AI 請求與主要等待來源。

採用方案 1。trigram 補查只用於缺少精確候選的短片段，至少 3 字元、最多 64 字元、similarity 至少 0.55；最多補 3 個 roots，每 root 至多 3 個候選，不拿整句全庫相似度當主要召回。沿用已有 GIN 索引，不新增 GiST。0.55 是起始取捨，並非跨語言通用的最佳門檻。

現有身份正規化、edge 品質門檻、核准 pivot、取消請求與貢獻入口繼續復用。暫不擴充供應商或建立翻譯歷史。

## 畫面與互動

- 桌面以左右原文／譯文兩欄為核心，上方分別放來源語言與目標 locale。行動版上下排列，沿用 atlas tokens。
- 保留明確翻譯按鈕；本次不新增每次輸入都自動呼叫 AI 的行為。生成中可停止、編輯和重新翻譯，新請求取消舊請求。
- 譯文只顯示一次，從第一個有效內容 delta 開始增量更新。進度收斂為一行狀態；完成後保留必要的來源狀態與操作，不顯示分詞 offset、confidence、技術路徑或重複草稿。
- 主結果保留複製與人工貢獻入口。整句替代翻譯只用於完整 exact 且同一指定 locale 的候選，並按需展開；assisted 的片段 evidence 不作為整句 alternatives。
- 完成後以本地分詞提供可點擊的譯文詞語；已檢索且確實出現在譯文中的多詞短語以最長完整匹配優先。拉丁文字匹配須有詞界，標點與空白維持原樣。
- 點擊詞語／短語後，在譯文下方的同一參考區顯示相關對照、可用讀音、實際 locale 與來源；換詞更新同一區塊。提供關閉按鈕、Escape、可見 focus 與鍵盤啟動。一般操作按鈕至少 44px；譯文內詞語保留自然字寬與原始空白，不以最小寬度撐開句子，垂直點選高度維持 44px。
- 生成中先維持可選取的純文字，完成後才建立互動分詞，避免每個 delta 造成詞界與焦點移動。重複詞的 occurrence 以文字位置識別；不宣稱來源／譯文逐詞對齊。
- 優先使用本次 evidence 中與選中目標文字相符的參考。其餘詞透過既有 expression 自然鍵 detail 與一跳 graph API 按需查閱；查不到就顯示沒有詞典參考，不再呼叫 AI 生成來源。
- evidence 是檢索參考，不等於模型已採用該義項；不同 source marker 保持區別，顯示去重不得合併不同來源含義。新譯文、locale 或來源語言變動清除選詞與舊詳情，晚到回應不可覆蓋新狀態。
- 詳情 lookup 以當次頁面記憶體暫存和共用 in-flight request 去重；key 包含 expression identity、語言與相關 locale／內容 revision。離開頁面清除，不新增持久化翻譯內容。

## locale 用詞契約

生成前排名必須作用於 SQL 候選上限之前，精確快徑與片段檢索使用相同政策。由 registry 解析語言、script、region、place 等資料，不能把 code 的字串前綴當成地區等價。

對合格的同義候選，依序優先：

1. 有完整指定 target locale link。
2. 相同 language、script／orthography、region 的其他 place profile。
3. 相同 language、script／orthography 的其他 region。
4. 同語言但 locale 未指定，或其他書寫系統；僅作 fallback。

同層再按完整匹配／片段匹配、direct／two-hop、品質分數、來源與穩定 ID 排序。來源詞義與上下文適配仍是使用條件，不可將不同義項只因 locale 更接近就強制替換。兩跳查詢在指定 locale 的 direct 候選不足時才補充，不能被其他 locale 的 direct 候選提前阻斷。

精確快徑只有完整輸入與完整指定 target locale 都有已證實的合格對照時才免 AI；其他 locale 或 metadata 未知的整句進入 assisted，作為參考並明確區分實際 locale。

生成 prompt 將指定 locale 的適用詞語列為優先用詞，將跨 locale 候選另列為 fallback，傳入 locale 的完整身份與名稱。不要沿用「final translation must be your own」而弱化既有詞典詞面的要求，也不事後以字串取代硬改文法。模型仍可能無法可靠生成特定 locale，因此以真實例句抽查驗收，不能把排序修正當成翻譯品質已獲保證。

## 請求流程與效能

1. 驗證輸入、來源語言與 target locale，使用已解析 registry 資料。
2. 以 locale 優先的完整輸入快徑查詢；合格命中零次 AI 呼叫。
3. 已指定或已由完整輸入安全解析來源時，直接用本地 `Intl.Segmenter` 建立有界檢索 roots，包含原文及相鄰短語；去重、穩定排序並保留現有數量上限。ISO 639-3 到 segmenter locale 的映射須明確處理，不靠例外猜測語言。
4. 來源為自動偵測且無安全判定時，才呼叫精簡 detector。只回傳來源語言與把握度，本地負責檢索分詞；低把握要求使用者選來源。一般明確來源請求一次 AI，自動偵測至多 detector 加 generation 兩次。
5. 批次讀取 roots 候選與直接對照，僅對不足的 roots 讀取核准兩跳。合併 metadata 查詢；只有不能批次化的獨立查詢才使用有界並行，避免無界 `Promise.all` 增加資料庫負載。
6. 沿用 2 秒檢索預算並補齊實際等待邊界。過期或取消後不啟動新查詢；已啟動查詢的 late result 與 rejection 都安全收尾。檢索失敗／無匹配可生成，但不能偽裝成有 locale 證據。
7. generation 使用供應商支援的 `stream: true`，僅轉送文字內容 delta；忽略 reasoning、role 與 usage chunk。以 finish reason 與累積輸出限制判定完成，截斷、空輸出、timeout、取消與中途 provider error 不得發成功 result。
8. 保留 SDK 零重試與現有有界生成 timeout。對實際 provider 支援的 thinking／reasoning 參數先驗證再調整，不因型別有欄位就認定 provider 接受；不單靠縮短 timeout 假裝提速。

本次保留現有 Workers AI 模型與 OpenAI 相容入口。已回讀官方模型 schema，確認 `chat_template_kwargs.enable_thinking` 的 boolean 支援及預設 true；generation 與 detector 明確設為 false。若實測仍不達標，再比較同輸入、同 locale、同品質要求的替代模型；更換供應商不是本方案的預設必要條件。

## 接入範圍與契約同步

- 後端：`translation` route／types、orchestrator、planner／detector、generation、exactMatch、retrieval 及相關測試。
- 前端：`ExpressionTranslation.vue`、translation components、`useTranslationStream`、translation API 型別、按詞查閱 composable 與 i18n。
- 保留 `POST /api/v2/translate` 與 NDJSON envelope。status 表示當前工作；既有 segmentation 不再是畫面主體；evidence 供生成與按詞查閱；result 的文字須與所有 delta 拼接一致。
- `TranslationResult.alternatives` 在 assisted 回應為空；完整 exact 可保留完整 target 候選。前後端型別、測試與原規格同步，不能留下舊測試仍要求一次性 delta 或片段 alternatives 的矛盾。
- 按詞查閱先復用現有 expression API；只有核對後確定不足才擴充接口。本次不改 canonical schema、dictionary identity 或獨立 Apple 客戶端。
- 既有詞句搜尋未提交變更不納入此次重構；實作與驗證必須保留它們。

## 驗收

### 行為與品質

- 有兩個 target 候選時，完整指定 locale 的低分候選優先於其他 locale 的高分候選；候選很多、SQL LIMIT、生效於兩跳與 place profile 的情境也必須覆蓋。
- `cmn-Hans-CN`／`cmn-Hant-TW`、同 script 不同 region，以及 registry 中實際存在的細分 locale，分別驗證選詞、fast path 與 fallback。對每組取目前詞典有資料的詞句，不建立前端硬編例外。
- 人工指定來源且快徑未命中時只呼叫一次 AI；完整合格快徑零次；自動偵測保留修正與低信心確認。
- 上游第一個文字 delta 到達後，前端在生成結束前顯示內容；reasoning 不外洩，完成的譯文與拼接 delta 一致。
- 整句只顯示一次；初始無全量參考列表；點擊／鍵盤啟動譯詞才顯示該詞參考；連續換詞、重新翻譯與取消不出現舊內容。
- 中英文、多詞短語、重複詞、emoji、換行、RTL 及長內容可正確顯示；桌面與行動 viewport 無溢出，觸控／鍵盤／focus 可用。
- 生成結果保持暫態，只有使用者明確進入並提交原貢獻流程才寫 canonical 資料。

### 效能量測與檢查

記錄 request 至首個可見譯文、generation 首內容 delta、總耗時、detector／檢索耗時、查詢次數與 AI 呼叫次數；不記錄原文、譯文、prompt 或 secret。以相同本地環境、相同模型和固定公開短句／長句／locale fixtures，比較重構前後多次測試的中位數及尾端延遲，分開記錄冷啟動與暖請求。結構驗收要求明確來源從兩次降為一次 AI 呼叫，以及首個可見譯文不再等待 completion；遠端耗時改善以量測結果報告，不預先承諾固定秒數。

執行相關前後端測試、`cd web && npm run build`、`./build.sh` 及真實流程驗證。PostgreSQL 整合測試僅使用隔離資料庫；不得重建現有本地資料庫。最終回讀 UI、請求內容與結果，不能以 mocked tests 取代真實 locale 品質抽查。

草案階段曾遇到 Node 原生 localStorage 與 jsdom 衝突、Vite 拒絕 repo 內共享 CSV 的問題。前端測試以 `NODE_OPTIONS=--no-experimental-webstorage` 使用 jsdom storage；Vite `server.fs.allow` 明確允許 repository root 內的既有共享 catalog。功能基線及更新後測試均已可執行。

## 實作結果

- 後端 10 檔 184 項翻譯測試通過，包含隔離 PostgreSQL schema 中的真 SQL、隔離 Worker API，以及錯誤、取消、低信心、自動／明確來源與逐段串流事件。
- 前端 10 檔 84 項相關測試通過；`npm run build`、`./build.sh`、`i18n:check` 與 `git diff --check` 通過。
- translation services 的 strict TypeScript 檢查通過。額外包含 route 的 ad hoc 檢查仍遇到既有 `middleware/auth.ts` 未定型 generic 與 `utils/response.ts` status 型別問題；本次未擴大修改共用模組。
- 真 Chrome 1280px／390px：原文與譯文左右／上下排列，沒有水平溢出。繁體與簡體完整精確結果各自符合指定 locale；完整 sentence evidence 不再把整句變成一個詞語按鈕；切 locale 清除舊結果。
- 真點選「火車站」時才以自然鍵讀取詳情及一跳對照，顯示實際 locale 與 English 對照。複製、Enter、Escape 返回詞按鈕焦點均通過。真 coffee assisted 在生成尚未完成時已顯示「我想要一杯咖啡」，完成後才建立詞語按鈕。
- 檢索 fixture 的 roots、direct、必要 two-hop、markers、locale metadata 至多 6 次批次 query。prefix／fuzzy 以 `UNION ALL` 分成各自可索引的分支，再套共用候選上限。2 萬列人工 fixture、GIN pending list 整理與統計更新後，真 `EXPLAIN ANALYZE` 確認 prefix 使用既有 `(language_id,text,homograph_index)` B-tree、fuzzy 使用既有 trigram GIN；全部 fixture 以 transaction 回滾。這不是 production corpus 的效能保證。

同一公開短句、同模型與 prompt 的 provider 抽樣：

| 設定 | generation 首內容 delta | generation 總耗時 |
| --- | ---: | ---: |
| 預設 thinking，第 1 次 | 22.050 秒 | 22.223 秒 |
| 預設 thinking，第 2 次 | 9.671 秒 | 9.754 秒 |
| 關閉 thinking，單次對照 | 1.282 秒 | 1.375 秒 |

三次譯文相同，delta 拼接與 result 相等；明確來源只呼叫一次 AI。預設 thinking 的 detector 另一次為 6.921 秒；未以多次抽樣確認關閉 thinking 後的 detector 延遲。此處只是 generation 時段，未包含驗證／資料庫／前端時間；沒有 p50／p95、冷暖分佈或大規模語言品質結論。測量只使用公開測試句，未記錄使用者內容或憑證。

### 限制與後續評估

- 沒有 evidence 短語時依賴 `Intl.Segmenter`，漢語詞界可能不準確；實測簡體「火车站在哪里」有「火车／站在／哪里」的切分。已有 evidence 的最長完整短語會覆蓋平台分詞。未新增語義分詞模型或為特定詞面寫例外。
- 真 provider 驗證聚焦 eng → cmn-Hant-TW；cmn-Hans-CN 與 place 的精確選詞／fallback 已用真 DB 驗證，尚未完成其他低資源語言或所有 locale 的模型品質矩陣。
- 真 AI 取消沒有另追加一次付費呼叫；取消／晚到結果已以回歸測試及真 browser synthetic transport 驗證。
- `pg_trgm` 改善字面容錯召回及執行速度，不理解詞義。相關性主要由精確／前綴／fuzzy 等級、locale、合格 graph path 和上下文適配維持。後續以真實 query 的 top-k 判讀再調門檻。
- 匯入大量資料後需核對統計與 GIN pending list。小表選擇語言索引可能合理；驗收應查看實際查詢的 `EXPLAIN ANALYZE`。GIN pending list 過大會增加搜尋成本，維護依既有 autovacuum／匯入流程處理，不在翻譯 request 中清理索引。

## 參考

- [Google Translate 官方說明](https://support.google.com/translate/answer/6142478?hl=en&co=GENIE.Platform%3DDesktop)：原文輸入、語言選擇與按需查閱詳情。逐詞點擊的具體行為以本次使用者需求為準。
- [Workers AI GLM-4.7-Flash 官方參數](https://developers.cloudflare.com/workers-ai/models/glm-4.7-flash/)：支援串流及 OpenAI 相容 API。文件支援不等於目前環境已量測通過。
- [PostgreSQL pg_trgm](https://www.postgresql.org/docs/current/pgtrgm.html)：相似度與 GIN／GiST 操作支援。
- [PostgreSQL GIN](https://www.postgresql.org/docs/current/gin.html)：pending list 與維護行為。
- [Cloudflare Model Schema API](https://developers.cloudflare.com/api/resources/ai/subresources/models/subresources/schema/methods/get/)：本次模型支援參數以實際 schema 回應核對。
