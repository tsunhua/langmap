# LangMap

LangMap is an open-source, community-driven language map platform that collects phrases and expressions from languages around the world, showcases differences between languages, and provides a valuable resource for language enthusiasts.

LangMap 是一個開源、社區驅動的語言地圖平臺，致力於收集世界各地的語言短語和表達方式，展示不同語言之間的差異，爲語言愛好者提供有價值的學習資源。


## 主要功能

- **語言地圖** — 首頁熱力圖可視化展示各語言在全球的分布與語料豐富度（Leaflet + OpenStreetMap）
- **詞條搜索** — 支持按關鍵詞、語言、地域等多維度搜索和篩選詞句，查看詞句組內不同語言的翻譯對比
- **貢獻詞句** — 用戶可提交新詞句或批量跨語言提交同一語義的多語表達，系統自動歸入詞句組（Expression Group）
- **學習手冊（Handbook）** — 基於 Markdown 的結構化學習筆記，嵌入詞句組後可動態切換目標語言，即時渲染翻譯
- **收藏集合** — 創建公開或私有的詞句收藏集，方便整理和分享
- **語言列表** — 按語言瀏覽所有詞條，查看各語言的語料統計
- **多語言界面** — 支持動態切換 UI 語言，社區可在線貢獻翻譯

> 詳細功能規劃請參見 [PRD](./docs/specs/PRD.md)，技術架構請參見 [系統架構設計](./docs/design/system/architecture.md)。

## 技術棧

| 層級 | 技術 |
|------|------|
| 前端 | Vue 3 + Vite + Tailwind CSS + vue-i18n + Leaflet |
| 後端 | Hono + TypeScript + Cloudflare Workers |
| 數據庫 | Cloudflare D1（SQLite）+ R2（對象存儲） |
| 部署 | Cloudflare Workers + Assets |

## 參與開發

### 環境準備

- Node.js >= 18
- npm

### 前端開發

```bash
cd web
npm install
npm run dev
```

### 後端開發

```bash
cd backend
npm install
npm run dev
```

後端使用 `wrangler dev --remote` 連接遠程 D1 數據庫進行開發。

### 完整構建

```bash
./build.sh
```

該腳本會安裝前端依賴、構建前端應用，並將產物複製到 `backend/public` 目錄。

### 數據庫配置

在 `backend/wrangler.jsonc` 中配置 Cloudflare D1 綁定：

```jsonc
{
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "your-database-name",
      "database_id": "your-database-id"
    }
  ]
}
```

### 貢獻指南

1. Fork 本倉庫
2. 創建功能分支（`git checkout -b feat/your-feature`）
3. 提交更改（`git commit -m 'feat: add your feature'`）
4. 推送分支（`git push origin feat/your-feature`）
5. 發起 Pull Request

## 部署

代碼推送到 `main` 分支後，Cloudflare 會自動構建並部署，無需手動操作。

如需手動部署：

```bash
cd backend
npm run deploy
```

此命令使用 Wrangler 將前端靜態資源（通過 Cloudflare Assets）和後端 API（通過 Cloudflare Workers）一併部署到 Cloudflare 邊緣網絡。

預覽部署（不實際上線）：

```bash
npx wrangler deploy --dry-run
```

## 文檔

- [業務需求文檔 (BRD)](./docs/specs/BRD.md)
- [產品需求文檔 (PRD)](./docs/specs/PRD.md)
- [系統架構設計](./docs/design/system/architecture.md)
- [API 文檔](./docs/api/)
- [功能模塊設計](./docs/design/features/)

## License

[Apache-2.0](./LICENSE)
