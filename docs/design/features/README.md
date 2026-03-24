# 功能模塊設計導航

本目錄包含 LangMap 系統各功能模塊的詳細設計文檔。

## 文檔列表

### 核心功能模塊

- **[feat-meaning-mapping.md](./feat-meaning-mapping.md)** - 詞句與語義多對多關係
  - meanings 和 expression_meaning 表設計
  - 數據遷移方案
  - API 接口設計
  - 前端實現方案
  - 實施狀態：設計完成，待實現

- **[feat-expression-group-abstraction.md](./feat-expression-group-abstraction.md)** - Expression Group 抽象層設計
  - ExpressionGroup 概念定義
  - 隱藏 meanings 和 expression_meaning 表實現細節
  - ExpressionGroup 查詢接口（expression_group.ts）
  - API 參數從 meaning_id 改爲 group_id
  - 實施狀態：設計完成，待實現

- **[feat-expression-group-modal.md](./feat-expression-group-modal.md)** - Handbook 詞句組快捷彈窗
  - 詞句組詳情彈窗設計
  - 表格展示所有翻譯
  - 快捷添加新翻譯功能
  - 組件與 API 集成

### 用戶與權限

- **[feat-user-system.md](./feat-user-system.md)** - 用戶與權限系統
  - 用戶角色定義
  - 數據庫表結構
  - API 接口設計
  - 權限控制邏輯
  - 郵箱驗證機制

- **[feat-user-profile.md](./feat-user-profile.md)** - 用戶資料功能

### 詞句與翻譯

- **[feat-database.md](./feat-database.md)** - 數據庫設計
  - 核心數據表結構
  - 表關係設計
  - 索引設計

- **[feat-batch-meaning-submission.md](./feat-batch-meaning-submission.md)** - 批量語義提交
- **[feat-merge-meaning-groups.md](./feat-merge-meaning-groups.md)** - 合併詞句組
- **[feat-search.md](./feat-search.md)** - 搜索功能
- **[feat-smart-search-associate.md](./feat-smart-search-associate.md)** - 智能搜索關聯

### 語言與國際化

- **[feat-language-detail.md](./feat-language-detail.md)** - 語言詳情頁面
  - 語言展示卡片
  - 區域數據可視化
  - 熱力圖展示

- **[feat-dynamic-languages.md](./feat-dynamic-languages.md)** - 動態語言支持
  - 動態加載機制
  - 語言切換流程
  - 緩存策略

- **[feat-i18n.md](./feat-i18n.md)** - 國際化系統
  - 數據模型設計
  - 後端 API 設計
  - 前端實現方案
  - 用戶貢獻流程

- **[feat-ui-translation.md](./feat-ui-translation.md)** - UI 翻譯系統
  - 用戶翻譯界面設計
  - 本地化翻譯同步方案
  - 完成度計算與激活邏輯
  - 審核工作流

### 內容管理

- **[feat-handbook.md](./feat-handbook.md)** - Handbook 筆記本功能
  - 數據庫設計
  - 筆記本管理
  - 筆記內容編輯

- **[feat-handbook-toc.md](./feat-handbook-toc.md)** - Handbook 目錄功能
  - 目錄結構設計
  - 目錄生成邏輯

### 收藏與導出

- **[feat-collection.md](./feat-collection.md)** - 集合（收藏夾）功能
  - 數據庫設計
  - 後端 API 設計
  - 前端交互設計
  - 集合管理頁面

- **[feat-export.md](./feat-export.md)** - 異步導出系統
  - Cloudflare Workers 架構
  - Durable Object 實現
  - R2 存儲集成
  - 流式處理策略

### 數據可視化

- **[feat-heatmap.md](./feat-heatmap.md)** - 熱力圖功能
  - 數據聚合
  - 地圖可視化

### 媒體處理

- **[feat-audio-upload.md](./feat-audio-upload.md)** - 音頻上傳功能
- **[feat-image-expression.md](./feat-image-expression.md)** - 圖片詞句功能
  - 圖片上傳與壓縮
  - R2 直傳架構
  - language_code='image' 標識
  - 前端動態輸入方式切換

## 命名規範

- **功能模塊文檔**：使用 `feat-` 前綴（如 `feat-user-system.md`）
- **文檔組織**：按功能類別分組
- **更新日期**：每次更新文檔時在頂部標記實現狀態

## 新增功能文檔流程

1. 在 `design/features/` 目錄創建 `feat-{feature-name}.md`
2. 參考現有功能文檔的結構和格式
3. 更新本 `README.md` 添加新文檔鏈接
4. 更新 `../README.md` 添加簡要說明

## 實施狀態說明

- ✅ 設計文檔已完成
- ⏳ 等待實現
- 🔄 實現中
- ✅ 已實現

## 相關文檔

- [總體系統設計](../system/)
- [API 文檔](../../api/)
- [實施指南](../../guides/)
- [需求規範](../../specs/)
- [計劃路線圖](../../plans/)
