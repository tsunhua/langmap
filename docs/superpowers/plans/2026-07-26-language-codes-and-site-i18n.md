# 全站語言代碼與本站 i18n 開發計劃

> 依據：`docs/superpowers/specs/2026-07-26-language-codes-and-community-ui-i18n.md`
>
> 本計劃只實作 LangMap 本站的多語介面與全站語言代碼統一；外部網站翻譯 API 僅保留 `project_id` 擴展縫，不在本期建立。

## 實作狀態（2026-07-26）

已完成可運行版本：Glottolog/BCP47 驗證與 pinned release tooling、一次性 migration manifest verifier、project-scoped locale/message API、bundle/workbench/batch/archive、`en-US`/`zh-Hant-TW`/`zh-Hans-CN` source catalogs、vue-i18n runtime、LangSwitcher、catalog check/sync、全站 production 文案遷移與完整 frontend/backend/tooling 測試。

本地或遠端 D1 啟動前必須先執行 `cd backend && npm run db:migrate:local`（部署環境使用 `npm run db:migrate:remote`）；未套用 `0006_project_scoped_localization.sql` 時，locale API 不可使用舊版 `ui_locales` schema。

## 目標與交付物

- 所有 `language_code`、詞句、搜尋、匯入、地圖、手冊與 i18n 使用同一套 BCP47 + Glottolog 規則。
- Glottolog 是 languoid 的唯一來源；BCP47 是內容語言標籤；不建立本地新語言、不建立 alias 表、不建立本地分類關係表。
- 內建來源語系固定為 `en-US`，介面翻譯直接建立在既有 `expressions`、`expression_edges`、`votes` 上。
- 既有 UI locale 以 `project_id` 隔離，現階段唯一值為 `langmap-web`。
- 交付 schema/migration、匯入工具、後端 API、前端 runtime/lang-switch/翻譯工作台、測試與遷移報告。

## 實作原則

- 先建立可驗證的語言碼邊界，再遷移資料；舊碼只在一次性 migration manifest 中出現，runtime 不解析舊 alias。
- API、repository、cache key 一律顯式帶 `projectId`；不得以未帶 project filter 的查詢作為捷徑。
- 翻譯品質只由既有 mapping score 決定：候選依 `score DESC, created_at ASC, id ASC` 取最高者；不增加審核流程。
- 優先沿用現有 expression/mapping/vote 實作，避免新增平行的翻譯資料模型。

## Phase 0：盤點與契約凍結

**目的：** 在改 schema 前列出所有語言碼入口，避免遷移後仍殘留舊格式。

- [ ] 建立欄位與呼叫點清單：`languages.code`、`expressions.language_code`、API request/response、搜尋篩選、import scripts、地圖/手冊資料、前端 locale store。
- [ ] 固定 IANA Language Subtag Registry snapshot 與 Glottolog 5.3 CLDF release；記錄來源版本、Zenodo DOI 與 CC BY 4.0 attribution。
- [ ] 將規格中的 BCP47 parser/validator、Glottolog lookup、canonicalization 規則寫成共用 TypeScript 介面，不只依賴 `Intl.getCanonicalLocales()`。
- [ ] 凍結 `langmap-web`、`en`、`nan-Hant-x-chao1238`、`und-x-<glottocode>` 等 fixture，供後續測試共用。
- [ ] 建立遷移 manifest 初稿：舊碼 → canonical code；無法映射的資料列要輸出錯誤清單並阻止正式遷移。

**主要檔案：** `backend/src/utils/`、`backend/src/types.ts`、`scripts/`、`backend/tests/`。

## Phase 1：Glottolog 與語言資料基礎

**目的：** 讓資料庫能表達完整 languoid identity，並可重現地更新 Glottolog release。

- [ ] 擴充 `languages`：`languoid_id`、`base_language`、`script_code`、`source_version`；保留 `code` 作 BCP47 canonical tag。
- [ ] 建立精簡 `languoids` 表：Glottocode、名稱、level、ISO 639-3、parent、地理資訊、status、source_version；不加入 names/aliases/relations/provisional 欄位。
- [ ] 重建 `languages` 以加入 `languoid_id` foreign key；為 `expressions.language_code` 與 `ui_locales.code` 加入 `languages(code)` foreign key。
- [ ] 新增 Glottolog release 匯入腳本：讀取官方 CLDF，驗證 Glottocode、parent 及唯一性後以 transaction upsert；固定排序並輸出新增、更新、retired、衝突統計。
- [ ] Glottolog 更新先產生版本 diff；release 中消失的項目標記 `retired`，不得靜默改指另一個 languoid。
- [ ] 由版本控制內的 manifest 產生 `languages` content tags；只允許 languoid level 為 language/dialect 的項目建立可用詞句語言。
- [ ] 實作 canonical tag 驗證：BCP47 registry + 本地 Glottolog lookup；使用 `x-<glottocode>` 時必須位於尾端且 Glottocode 存在於 pinned release。
- [ ] 對未收錄語言拒絕建立本地 ID，錯誤訊息指向提交 Glottolog 的流程；不提供 create-language API。
- [ ] 新增並測試語言查詢 API：
  - [ ] `GET /api/v2/languages?q=&level=&script=&limit=&cursor=`
  - [ ] `GET /api/v2/languages/:code`
  - [ ] `GET /api/v2/languoids/:id`
- [ ] 語言 picker 搜尋 preferred name、既有中英文名稱、BCP47、Glottocode、ISO 639-3；使用固定排序、cursor 分頁與數量上限。

**驗證：** Glottocode 格式、`nan-Hant-x-chao1238` round-trip、`cmn-Hant-TW`、未知/錯誤 x-extension 均有單元測試。

## Phase 2：一次性全站語言碼遷移

**目的：** 將現有資料全部收斂至 canonical BCP47，不在 runtime 維護相容層。

- [ ] 完成舊碼盤點與 manifest review，以 `keep`、`canonicalize`、`map-to-glottolog`、`manual-review` 分類，禁止以 regex 猜測 script、region 或 Glottocode。
- [ ] 實作 migration：先驗證全量，再以 transaction 更新 `languages.code`、`expressions.language_code` 及所有引用欄位。
- [ ] 對無法映射、重複 canonical code、缺少 Glottolog 對應的資料輸出報告並 fail fast；不得靜默轉成 `und`。
- [ ] 更新 schema、seed、import/export、search index、API 型別與文件中的範例碼。
- [ ] API response 新增 nested `language` 物件；遷移期間保留既有 `language_code`、`language_name`，不在本計劃中移除。
- [ ] 遷移完成後移除 alias runtime、舊碼 fallback、舊欄位相容分支；保留 manifest 作為歷史記錄。
- [ ] 執行資料完整性檢查：expression ID 與 URL 不變，expression 數量、mapping 邊數、vote 數、語言統計與遷移前一致。

**主要檔案：** `backend/schema.sql`、`backend/migrations/`、`scripts/v2/`、相關 routes/repositories/tests。

## Phase 3：本站 i18n 資料與後端 API

**目的：** 建立最小的 project-scoped locale/message catalog，翻譯仍是 expression mapping。

- [ ] 新增/遷移 `ui_locales`：複合主鍵 `(project_id, code)`、fallback composite FK、`mapping_revision`、status 與 actor 欄位；seed 永遠 active 的 `('langmap-web','en')`。
- [ ] 若現有 `ui_locales.locale_json` 有資料，先轉成 `langmap-web` expressions/mappings，再移除欄位。
- [ ] 新增/遷移 `ui_messages`：`(project_id, key)` 唯一、source expression、placeholder/plural metadata、source hash、status。
- [ ] 為每個 message key 建立獨立 `source_type='ui_i18n'`、`source_ref='<project-id>:<message-key>'` expression，避免相同文字在不同上下文混用。
- [ ] `ui_i18n` template expressions 預設排除於一般 feed/search；重用既有自然詞句時保留原 `source_type`。
- [ ] 實作公開 API；locale list 只回 active locales，`en` 優先，其餘依 `native_name`、`code` 穩定排序：
  - [ ] `GET /api/v2/localization/projects/:projectId/locales`
  - [ ] `GET /api/v2/localization/projects/:projectId/locales/:code/messages`
- [ ] 實作協作 API：
  - [ ] `GET /api/v2/localization/projects/:projectId/workbench/:code`
  - [ ] `POST /api/v2/localization/projects/:projectId/mappings`
  - [ ] `POST /api/v2/localization/projects/:projectId/mappings/batch`
  - [ ] `POST /api/v2/localization/projects/:projectId/locales/:code/archive`
- [ ] mapping 投票沿用既有 vote API，不在 localization namespace 建立第二套 vote route。
- [ ] 實作 bundle 選擇：score、時間、ID 穩定排序；無非負候選時沿 locale fallback；回應包含 `project_id` 與 ETag。
- [ ] eligible mapping/vote 與所有受影響 locale 的 `mapping_revision` 在同一 transaction 原子更新；MVP 不先判斷第一名是否改變。
- [ ] 實作 fallback validator：只能指向 active locale、拒絕循環；bundle 最大深度 5，依明確 fallback、active BCP47 父級、`en` 合併。
- [ ] bundle 加入 `Cache-Control: public, max-age=300, stale-while-revalidate=86400`、project/locale/revision ETag、`If-None-Match` 304；gzip 超過 100 KB 或 active keys 超過 2,000 前不按 scope 拆包。
- [ ] 加入 project scope 權限與錯誤契約；project slug 最長 64 字元，目前只允許 `langmap-web`，未知值回傳 `404 PROJECT_NOT_FOUND`，不建立 projects table、membership 或 project CRUD。
- [ ] 所有 mutation 加入 JWT auth、每帳號/IP rate limit、request/batch/text 上限與 actor 紀錄；一般 log 不記完整譯文。

**測試：** project isolation、unknown project/locale、placeholder/plural validation、直接 mapping、精確 target locale、score tie-break、fallback、ETag/304/revision、批次 100 keys/256 KB 上限、並發重複提交。

## Phase 4：前端 runtime 與上百語系切換

**目的：** 讓本站以 `en` 啟動，並能在 100–500 個 locale 下穩定使用。

- [ ] 安裝並初始化 `vue-i18n`；建立 `web/src/locales/en.ts` source catalog，檢查 key、placeholder、plural pattern 與 `ui_messages`。
- [ ] 建立 localization API client、Pinia store/composable；`LOCALIZATION_PROJECT_ID = 'langmap-web'` 集中管理。
- [ ] 先以內建 `en` mount，再非阻塞載入偏好 bundle；初始化順序為 active localStorage 偏好 → `navigator.languages` 精確/父級匹配 → `en`，禁止 `startsWith` 模糊匹配。
- [ ] 來源語系不下載 bundle；載入失敗仍使用完整英文內建 catalog。
- [ ] 實作 locale fallback chain、`html.lang`/`html.dir` 更新、日期/數字格式化與 cache。
- [ ] cache 規則：並行請求去重、最多三個非來源 bundle、先讀 cache 再背景 revalidate、驗證完整後原子替換，解析失敗清除該 bundle。
- [ ] 重構全站頁面、元件、錯誤訊息、空狀態、表單與 accessibility 文案，移除硬編碼顯示文字。
- [ ] 先遷移 TopNav、Auth、NotFound 與共用狀態，再按高流量頁、其餘頁面完成全站 catalog 化。
- [ ] 實作 LangSwitcher：桌面 popover、行動 bottom sheet、搜尋、最近使用、瀏覽器建議、協助翻譯入口、鍵盤 combobox/listbox、focus return、至少 44px 觸控目標；不用國旗代表語言。
- [ ] locale 空白搜尋先顯示 40 筆、接近底部再增加 40 筆；超過 500 且實測需要後才加入虛擬列表，不預載其他 bundle。
- [ ] 加入 desktop/390px、長字串與 RTL 視覺驗收，沿用 `atlas.css` tokens；地圖/圖譜座標不鏡像。

**主要檔案：** `web/src/locales/`、`web/src/api/`、`web/src/stores/`、`web/src/composables/`、`web/src/components/`。

## Phase 5：社群翻譯工作台

**目的：** 讓使用者直接提交既有 locale 的詞句關聯，由分數決定發佈內容。

- [ ] 建立 `/translate` 與 `/translate/:code`；依規格 11.1，未登入可查看候選與分數，mutation 時要求登入；實作前同步修正規格 8.2 表格中 workbench 的權限標示。
- [ ] 建立 locale workbench：顯示 coverage、無候選、最高分為負數、mapping 總數與近期 mapping/vote。
- [ ] 建立 message editor：顯示 key/description/scope、英文來源、placeholder/plural、目前第一名、全部候選、分數與 tie-break 原因。
- [ ] 提交翻譯時以 exact locale + normalized text 重用或建立 target expression，驗證後建立/重用直接 `expression_edge`，新 edge 分數為 0。
- [ ] 重用既有 vote API 與 score；不新增 translation review/approval 狀態。
- [ ] 工作台與 bundle 共用同一 selector；預覽目前獲勝 expression、勝出理由、投票後變化與 fallback。
- [ ] locale 只可由既有設定/匯入建立；工作台不提供新建語言或新建 locale API。管理員可 archive。
- [ ] coverage 使用「最高 mapping 分數 >= 0 的 active message / active message 總數」；建議達 60% 自動啟用，不逐筆審核。

**測試：** 重複 expression reuse、格式錯誤、批次輸入驗證與失敗回應、score 更新後 bundle 失效、archive locale、權限邊界。

## Phase 6：catalog 同步與全站驗收

- [ ] 建立 `npm run i18n:check` 與 `npm run i18n:sync -- --dry-run`；驗證 key、dynamic-key allowlist、placeholder、plural，並輸出同步摘要。
- [ ] sync 顯式使用 `project_id='langmap-web'`，只允許部署/admin 執行，不提供一般使用者 API。
- [ ] 從 `en.ts` 產生/比對 `ui_messages`；新增 key 建 expression/message，刪除 key 標記 deprecated，不刪歷史資料。
- [ ] source 變更建立新的 contextual source expression；舊 mapping 自然失效，不搬移錯誤翻譯。
- [ ] 純文字最多 4,000 Unicode code points，拒絕任意 HTML、不允許控制字元與動態 property path；受控連結/component 使用 i18n slots。
- [ ] 將 CI 檢查接入：key 唯一、placeholder/plural 一致、API schema、BCP47 + Glottolog valid、missing key、pseudo-locale、無未列入例外的硬編碼 UI 文案。
- [ ] 執行後端測試、前端 build、`./build.sh`；啟動 Worker 後跑整合測試。
- [ ] 以 fixture 與實際匯入資料做 smoke test：`en`、`zh-Hant-TW`、`de` 長字串、`ar` RTL/複數、`ja`、`en-XA`、100/500 locale 搜尋、fallback、離線 cache。
- [ ] 產出遷移報告、Glottolog source version、已知未收錄語言清單與 rollback 操作說明。

## 建議提交順序

1. `feat(data): add glottolog-backed language identity`
2. `chore(data): migrate all language codes to canonical bcp47`
3. `feat(api): add project-scoped localization catalog`
4. `feat(web): add english source catalog and locale runtime`
5. `feat(web): add scalable language switcher`
6. `feat(i18n): add community translation workbench`
7. `test(i18n): add catalog sync and end-to-end coverage`

每個提交都應能獨立通過對應測試；schema/migration 與 API 契約變更需同步更新型別、測試及規格文件。

## 完成定義

- 所有現存語言碼均可由 canonical BCP47 tag 對應至 Glottolog languoid；沒有未處理舊碼或 runtime alias。
- 語言查詢 API 具有固定排序、分頁與上限；新 expression 只能使用 registry 中已啟用的 canonical tag。
- 來源 UI locale 為 `en`；本站所有可見介面文字均來自 catalog 或既有 expression mapping。
- 任一 localization API 查詢都不會跨 `project_id` 讀寫資料；現階段 `langmap-web` 行為完整。
- 翻譯候選按既有 score 穩定選取，無額外審核流程；fallback、cache invalidation、placeholder/plural 驗證均有測試。
- 100+ locale 的切換器通過鍵盤、行動版、RTL 與效能驗收。
- 文件、migration report、schema、API 型別與測試均已更新，且 `git diff --check` 通過。
