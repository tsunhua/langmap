# LangMap

> 開源、社區驅動的多語詞句地圖。

- AI 回覆使用中文。
- 新增中文文件與介面文案使用傳承體中文；編輯既有內容時沿用原語體。
- 遵循 Simplicity First、Surgical Changes、Goal-Driven Execution：先確認需求，只改必要範圍，完成後驗證。

## 當前主線

- 前端：`web/`，Vue 3 + TypeScript + Vite + Pinia + Tailwind CSS。
- 後端：`backend/`，Hono + TypeScript + Cloudflare Workers + PostgreSQL。
- API prefix：`/api/v2`，一般回應格式為 `{ success, data?, error?, message? }`。
- `apple/` 是獨立 SwiftUI 客戶端，不要在 Web/API 任務中順手修改。

## 目錄

```text
web/src/          pages / components / composables / stores / api / assets
backend/src/      index.tsx / routes / utils / types.ts
backend/tests/    Vitest 整合測試
backend/postgres/migrations/ PostgreSQL 增量 migration
backend/postgres/schema.sql  PostgreSQL 完整 schema
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

- 後端整合測試依賴 `DATABASE_URL` 指向隔離 PostgreSQL；API smoke test 另需啟動 Worker。
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
- `mapping` / `expression_edge`：兩個 expression 的直接對照關係；兩端可以是詞、短語或句子，端點採排序後的整數 ID。例句原句與譯句各自是獨立 expression，只在兩者之間建立普通 mapping，不與主詞頭關聯。
- 來源標記（source marker）：詞典自己的 homograph 編號以 `(source_id, source_marker)` 保留在 `expression_sources`（expression 層）與 `expression_edge_sources`（edge 層）。同來源不同編號＝不同含義；跨來源編號不互宣稱相同，不建立 sense 實體。
- 詞典匯入、合併身份、來源標記的變更集中在 `scripts/dictionary/import_mapping_csv_pg.py` 與 dictionary repo；改動必須同步 `backend/postgres/schema.sql`、migration、pytest 與 mappingGraph 型別。
- 語言、locale、script 與 region 的名稱本身也是 expression；registry 列僅保留其 canonical English expression 的整數引用，譯名透過 direct edge 加完整 locale link 解析。
- `handbook`：學習手冊。
- `/mapping/:id` 以 expression ID 為中心展示關係，不要混淆詞句節點與映射邊。

## PostgreSQL 與 registry

- `backend/postgres/schema.sql` 是 PostgreSQL baseline；`scripts/postgres/manage.py` 執行 baseline、seed 與 checksum-locked migrations。
- `scripts/language-reference/generate.py` 產生 language registry、reference locale 與名稱 expression／edge seed。
- 本地服務從 `backend/.dev.vars` 或環境變數讀取 `DATABASE_URL`；`dev.sh` 不清除或重建資料庫。
- dictionary repo 產生 `csv/<source-key>/data.csv` + `manifest.json`；`scripts/dictionary/import_mapping_csv_pg.py` 先 `--check` 再 `--apply`，同一 transaction 依 source snapshot 同步 claims。
- Wikivoyage 來源在 dictionary repo 以每個英語→目標 locale 一份寬表 CSV 發布；`READING_<locale>_<scheme>` 是同表 metadata 欄位，不再產生 JSONL 或 SQLite/D1 staging。
- Wikivoyage handbook 只由 `scripts/postgres/build_wikivoyage_handbook.py` 以 PostgreSQL 重建，section catalog 從 dictionary adapter 取用。

### 詞典發布

- 每列 canonical CSV 的 `LOCALE_<locale-code>` 欄位建立或解析 language、script、region、language_locale。
- `(language, text)` 是 expression identity；`ENTRY_ID` 保留 source marker。每列所有不同詞面建立 pairwise mapping，同語言不同詞面也互連，不建立 self-edge。
- source snapshot 只刪除該 source 的 claims／annotations，保留其他 source 共用的 expressions、edges 與 markers。
- 發布前抽查 headword、direction、equivalents、readings 及例句 pairing；修正回 dictionary adapter 後重新產生 CSV 與 manifest。

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
