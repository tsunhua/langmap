# LangMap

> 開源、社區驅動的多語詞句地圖。

- AI 回覆使用中文。
- 新增中文文件與介面文案使用繁體中文；編輯既有內容時沿用原語體。
- 遵循 Simplicity First、Surgical Changes、Goal-Driven Execution：先確認需求，只改必要範圍，完成後驗證。

## 當前主線

- 前端：`web_v2/`，Vue 3 + TypeScript + Vite + Pinia + Tailwind CSS。
- 後端：`backend_v2/`，Hono + TypeScript + Cloudflare Workers + D1。
- API prefix：`/api/v2`，一般回應格式為 `{ success, data?, error?, message? }`。
- `web/`、`backend/` 是舊版；除非需求明確指向，否則不要同步修改。
- `apple/` 是獨立 SwiftUI 客戶端，不要在 Web/API 任務中順手修改。

## 目錄

```text
web_v2/src/          pages / components / composables / stores / api / assets
backend_v2/src/      index.tsx / routes / utils / types.ts
backend_v2/tests/    Vitest 整合測試
backend_v2/migrations/ D1 增量 migration
backend_v2/schema.sql  新資料庫完整 schema
docs/superpowers/    specs / plans
scripts/             資料匯入與維護
```

## 指令

```bash
./dev.sh                 # Web :5173 + API :8788
./build.sh               # build web_v2 → backend_v2/public
cd web_v2 && npm run build
cd backend_v2 && npm test
```

- 後端整合測試依賴 `127.0.0.1:8788` 與本地 D1，執行前先啟動 Worker。
- `web_v2/dist/`、`backend_v2/public/`、`.wrangler/` 是生成或本地狀態，不要手動修改。

## 程式規範

- Vue 使用 `<script setup lang="ts">`；避免新增 `any`。
- 頁面負責組合，重用視圖放 component，重用邏輯放 composable。
- 前端 API 統一經 `web_v2/src/api/client.ts`，不要寫死 base URL。
- 後端新路由放 `backend_v2/src/routes/`，使用 `utils/response.ts` 的回應 helper。
- API 契約變更時同步更新型別、composable、測試及相關規格。
- schema 變更同時新增 migration 並更新 `schema.sql`。
- 資料問題回到來源、匯入腳本或 migration 修正，不在前端寫死例外。
- 查詢、圖遍歷與佈局必須有穩定排序，並處理循環、重複與數量上限。
- 註釋只解釋 WHY，不重述程式碼。

## 前端設計

- 沿用 `web_v2/src/assets/atlas.css` 的 tokens、暖紙張背景、陶土色主色、藍色關係線與低圓角。
- 不另起顏色、陰影或圓角系統；不因 Tailwind 已安裝而機械式重寫 scoped CSS。
- 圖示沿用 `lucide-vue-next`，不要手寫 SVG path。
- 行動版不是桌面版的等比例縮小；觸控目標至少 44px。
- Grid/Flex 子元素注意 `min-width: 0`，避免長詞句撐破容器。
- 互動元件需支援鍵盤、可見 focus 與 accessible name。
- 地圖、圖譜等複雜視覺需提供列表或文字替代。
- 動效只用於狀態與操作回饋，並尊重 `prefers-reduced-motion`。

## Domain

- `expression`：單一語言中的詞或句。
- `mapping` / `expression_edge`：兩個 expression 的語義關係。
- `language`：語言或地區化語言代碼。
- `contribution`：一批新增或關聯提交。
- `handbook`：學習手冊。
- `/mapping/:id` 以 expression ID 為中心展示關係，不要混淆詞句節點與映射邊。

## 文檔與安全

- 大型改造先更新 `docs/superpowers/specs/`；施工拆解放 `docs/superpowers/plans/`。
- 文件名使用 `YYYY-MM-DD-topic.md`，明確區分已實作、計畫與非目標。
- 跨模組架構決策放 `docs/adr/`；API 變更同步相關文件。
- 詞句詳情圖譜規格：`docs/superpowers/specs/2026-07-26-mapping-detail-graph-optimization.md`。
- 不提交 `.dev.vars`、token、真實 secret、credentials、`node_modules/` 或 `.wrangler/`。

## 驗證與 Git

- 前端變更至少執行 `cd web_v2 && npm run build`，並檢查相關桌面與行動 viewport。
- 後端變更執行相關測試；跨前後端變更再執行 `./build.sh` 與完整流程驗證。
- 文件變更執行 `git diff --check` 並檢查連結。
- 保留使用者既有未提交變更，不修改無關檔案。
- Commit 使用簡潔 Conventional Commit，例如 `feat:`、`fix:`、`docs:`。
