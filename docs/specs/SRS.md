# LangMap 系統需求規格說明 (SRS)

## 1. 系統架構
LangMap 採用現代的前後端分離架構，全面適配 Cloudflare 平臺。

- **前端 (Web)**: 基於 Vue 3 構建，使用 Vite 作爲構建工具，Vercel/Pages 部署。
- **後端 (Backend)**: 基於 Hono (TypeScript) 構建，部署在 Cloudflare Workers。
- **數據庫 (Database)**: 採用 Cloudflare D1 (SQLite)，由 Hono 邏輯層進行訪問控制。
- **移動端 (iOS)**: 基於 SwiftUI 構建的原生應用。
- **存儲 (Storage)**: 採用 Cloudflare R2 用於異步導出文件的存儲。

## 2. 技術棧
### 2.1 後端 (Backend)
- **框架**: Hono (v4.10.7+)
- **語言**: TypeScript (v5.9.3+)
- **運行時**: Cloudflare Workers
- **庫**: Zod (驗證), Jose (JWT), Bcryptjs (加密), Resend (郵件)
- **數據庫驅動**: Cloudflare D1 Native API

### 2.2 前端 (Web)
- **框架**: Vue 3
- **樣式**: Tailwind CSS
- **構建**: Vite
- **地圖**: Leaflet / OpenStreetMap

### 2.3 移動端 (Apple)
- **框架**: SwiftUI
- **語言**: Swift

## 3. 關鍵組件與設計
詳細設計請參閱 `docs/design/features/` 目錄：
- **用戶與權限**: [feat-user-system.md](../design/features/feat-user-system.md)
- **數據庫架構**: [feat-database.md](../design/features/feat-database.md)
- **地圖可視化**: [feat-heatmap.md](../design/features/feat-heatmap.md)
- **搜索系統**: [feat-search.md](../design/features/feat-search.md)
- **異步導出**: [feat-export.md](../design/features/feat-export.md)
- **國際化 (i18n)**: [feat-i18n.md](../design/features/feat-i18n.md)

## 4. 接口協議
- 遵循 RESTful API 規範。
- 詳情請參閱 `docs/api/`（如果存在）。

## 5. 性能與安全
- **緩存策略**: 在後端和前端均實施多級緩存。
- **權限校驗**: 嚴格的 JWT 認證與 RBAC（基於角色的訪問控制）。
