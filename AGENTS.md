# LangMap

> 開源、社區驅動的多語詞句地圖。

- AI 回覆使用中文。
- 新增中文文件與介面文案使用傳承體中文；編輯既有內容時沿用原語體。
- 遵循 Simplicity First、Surgical Changes、Goal-Driven Execution：先確認需求，只改必要範圍，完成後驗證。

## 當前主線

- 前端：`web/`，Vue 3 + TypeScript + Vite + Pinia + Tailwind CSS。
- 後端：`backend/`，Hono + TypeScript + Cloudflare Workers + D1。
- API prefix：`/api/v2`，一般回應格式為 `{ success, data?, error?, message? }`。
- `apple/` 是獨立 SwiftUI 客戶端，不要在 Web/API 任務中順手修改。

## 目錄

```text
web/src/          pages / components / composables / stores / api / assets
backend/src/      index.tsx / routes / utils / types.ts
backend/tests/    Vitest 整合測試
backend/migrations/ D1 增量 migration
backend/schema.sql  新資料庫完整 schema
docs/superpowers/    specs / plans
scripts/             資料匯入與維護
```

## 指令

```bash
./dev.sh                 # Web :5173 + API :8788
./build.sh               # build web → backend/public
cd web && npm run build
cd backend && npm test
```

- 後端整合測試依賴 `127.0.0.1:8788` 與本地 D1，執行前先啟動 Worker。
- `web/dist/`、`backend/public/`、`.wrangler/` 是生成或本地狀態，不要手動修改。

## 程式規範

- Vue 使用 `<script setup lang="ts">`；避免新增 `any`。
- 頁面負責組合，重用視圖放 component，重用邏輯放 composable。
- 前端 API 統一經 `web/src/api/client.ts`，不要寫死 base URL。
- 後端新路由放 `backend/src/routes/`，使用 `utils/response.ts` 的回應 helper。
- API 契約變更時同步更新型別、composable、測試及相關規格。
- schema 變更同時新增 migration 並更新 `schema.sql`。
- 資料問題回到來源、registry seed、匯入腳本或 migration 修正，不在前端寫死例外。
- 查詢、圖遍歷與佈局必須有穩定排序，並處理循環、重複與數量上限。
- 註釋只解釋 WHY，不重述程式碼。

## 前端設計

- 沿用 `web/src/assets/atlas.css` 的 tokens、暖紙張背景、陶土色主色、藍色關係線與低圓角。
- 不另起顏色、陰影或圓角系統；不因 Tailwind 已安裝而機械式重寫 scoped CSS。
- 圖示沿用 `lucide-vue-next`，不要手寫 SVG path。
- 行動版不是桌面版的等比例縮小；觸控目標至少 44px。
- Grid/Flex 子元素注意 `min-width: 0`，避免長詞句撐破容器。
- 互動元件需支援鍵盤、可見 focus 與 accessible name。
- 地圖、圖譜等複雜視覺需提供列表或文字替代。
- 動效只用於狀態與操作回饋，並尊重 `prefers-reduced-motion`。

## Domain

- `language`：ISO 639-3 語言 registry；以整數 `id` 作內部引用，`code` 作穩定公開識別。
- `language_locale`：精確的書寫系統／地區／地點 profile；詞句可透過 `expression_locale_links` 連到零至多個 locale。
- `expression`：單一語言中的詞或句，綁定 `language_id`；ID 為整數。詞典匯入將同一 `(language_id, text)` 合併為 `homograph_index = 1` 的單一列，不依來源增量配號。
- `mapping` / `expression_edge`：兩個 expression 的直接語義關係；端點採排序後的整數 ID。
- 來源標記（source marker）：詞典自己的 homograph 編號以 `(source_id, source_marker)` 保留在 `expression_sources`（expression 層）與 `expression_edge_sources`（edge 層）。同來源不同編號＝不同含義；跨來源編號不互宣稱相同，不建立 sense 實體。
- 詞典匯入、合併身份、來源標記的變更集中在 `scripts/dictionary/langmap_dictionary/`；改動必須同步 `backend/schema.sql`、migration、pytest 與 mappingGraph 型別。
- 語言、locale、script 與 region 的名稱本身也是 expression；registry 列僅保留其 canonical English expression 的整數引用，譯名透過 direct edge 加完整 locale link 解析。
- `handbook`：學習手冊。
- `/mapping/:id` 以 expression ID 為中心展示關係，不要混淆詞句節點與映射邊。

## 本地 D1 與 registry

- `backend/schema.sql` 是 greenfield canonical schema；`scripts/language-reference/generate.py` 產生 language registry、reference locale 與名稱 expression/edge seed。
- `./dev.sh --rebuild` 會重建本地 D1，並清除手動匯入的資料。需要保留 local 匯入時，先確認其可重跑的來源／腳本，再重建。
- `scripts/db/import_v2_canonical.py` 是從 v2 SQLite 匯出產生可重跑 canonical 匯入 SQL 的工具；變更匯入範圍時優先修正它，而非手動補前端或資料庫例外。
- production D1 依 `docs/runbooks/database-migrations.md` 的 plan/apply 流程操作；不得以直接 remote migration apply 取代該流程。

### production 詞典發布

- canonical schema（migration 0039 起）已移除 release/claim/packed 表；詞典逐部以 `import_with_progress.py` merge 進「mirror」，再以受管 `approved_data_migration` 發布。
- **structured JSONL 由獨立 exporter 產出**：`/Users/lim/Documents/Code/tsunhua/dictionary`（`dictionary-jsonl-export`）把 Apple bundle CSV 轉成 `/Volumes/DATA/langmap-structured-jsonl/`。exporter 的 parser ／ profile 改變屬於該 repo，發布前抽查攔下的資料問題多半要回源到這裡修正並重新匯出，不是在 langmap 側硬編例外。
- **不要求 production 資料基線**：本地 SQLite 只作 staging、品質檢查與 delta 產生，不要求與 production 全庫 counts 或整數 ID 空間一致，也不因 counts 不一致而全量 export。發布依據是 immutable source artifact、checksum-locked approved delta、production identity/schema preflight、bookmark 與來源範圍 postflight。
- **自然鍵 delta**：以 `export_dictionary_source_delta.py` 按 source key 匯出可重跑 SQL；staging 整數 ID 只作包內暫存 join key，production 以 language code、expression identity、locale code、source name 與 edge endpoints 解析實際 ID。staging 全庫 manifest 不傳入 `--dictionary-postflight-manifest`。來源 artifact 修正改變了 identity（如 packed gloss 拆分）時，重發布加 `--replace`：delta 先刪該 source 擁有的 rows 再重插，工具會在其他 source 共用其 owned expressions 時拒絕。
- 每部流程：staging import → 品質 gate → 產生並 checksum source delta → `manage.sh production plan --approved-data-migration <delta>` → `production apply`（先 bookmark）→ source-scoped verify。全量 export 只用於事故調查、restore 後製作離線副本或明確要求，不是發布前置條件。
- **每次發布後須刷新 `language_statistics`**：delta 只寫 expressions/edges/readings，不會更新統計表；否則 `/languages` 與語言列表停滯在舊 counts。刷新語句（`INSERT OR REPLACE ... SELECT ... FROM languages l`）在 apply 後對 production 執行。
- **發布前由 agent 抽查**：對即將發布的詞典抽樣 insight——逐一檢視 headword 語言、direction、equivalents、readings 是否合理（如 Crown 假名被標 cmn-to-jpn 的錯誤即在抽查中攔下）。任何抽樣異常先回 source 修正，不帶病發布。修正 exporter 後**必須以 `dictionary-jsonl-export` 重新匯出該部 JSONL 再重新抽查**，確認 entry count 不變、readings 合理後才覆寫 `/Volumes/DATA/langmap-structured-jsonl/<部>.jsonl`（先複製 `.pre-tyfix` 備份）。
- **established JSONL 的發音必須乾淨**：繁體常用詞等 bundle 以 `ty_pinyin`／`ty_jyutping`（及 `ty_IPA`）class 標記 headword 發音，exporter 依此輸出 `pinyin`／`jyutping` scheme，並忽略「案／隔／叮」這類同音字提示節點；多音字與雙語辭典的 readings 落在 sense 底層，抽查不得只數 total。發現 CJK 字元出現在 readings 即代表該用 homophone-hint 過濾。
- `import_with_progress.py` 的 state 檔屬 dev D1，發布用 mirror 前要先清掉該檔的殘留「success」記錄，否則會跳過。
- **大資料張力**：D1 單一 execute 有 CPU time limit。超過時把 DELETE 拆成 `.split.sql`（plan 帶 `mode=split`，逐語句 `--command` 執行）；超大 DELETE（十萬 rows 級）再分批（每批約 5 萬 rows）。混合 DELETE+INSERT 的巨型單檔不可靠，先拆。
- **拼音是 reading，不是詞句**：Crown 等 bundle 把拼音混進 equivalents；adapter 對 `zhs-ja.Crown` 把拼音樣式值判為 headword 的 `pinyin` reading，不建 expression 節點。

## 文檔與安全

- 大型改造先更新 `docs/superpowers/specs/`；施工拆解放 `docs/superpowers/plans/`。
- 文件名使用 `YYYY-MM-DD-topic.md`，明確區分已實作、計畫與非目標。
- 跨模組架構決策放 `docs/adr/`；API 變更同步相關文件。
- 詞句詳情圖譜規格：`docs/superpowers/specs/2026-07-26-mapping-detail-graph-optimization.md`。
- 不提交 `.dev.vars`、token、真實 secret、credentials、`node_modules/` 或 `.wrangler/`。

## 驗證與 Git

- 前端變更至少執行 `cd web && npm run build`，並檢查相關桌面與行動 viewport。
- 後端變更執行相關測試；跨前後端變更再執行 `./build.sh` 與完整流程驗證。
- 文件變更執行 `git diff --check` 並檢查連結。
- 保留使用者既有未提交變更，不修改無關檔案。
- Commit 使用簡潔 Conventional Commit，例如 `feat:`、`fix:`、`docs:`。
