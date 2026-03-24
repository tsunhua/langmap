# 設計文檔

本目錄包含 LangMap 系統的總體架構設計和功能模塊設計文檔。

## 目錄結構

```
design/
├── system/                    # 總體系統架構設計
│   ├── architecture.md         # 系統總體架構設計
│   └── README.md             # 系統設計導航
├── features/                   # 功能模塊設計（所有使用 feat- 前綴）
│   ├── feat-user-system.md       # 用戶與權限系統
│   ├── feat-collection.md        # 集合功能
│   ├── feat-export.md           # 導出系統
│   ├── feat-ui-translation.md    # UI 翻譯
│   ├── feat-i18n.md            # 國際化
│   ├── feat-dynamic-languages.md # 動態語言
│   └── README.md              # 功能模塊導航
└── README.md                  # 本文檔
```

## 文檔分類

### 📗 總體系統設計 (system/)
系統整體架構設計文檔。

- **[architecture.md](system/architecture.md)** - 系統總體架構設計
  - 技術棧建議
  - 數據模型草案
  - API 設計示例
  - 前端頁面與交互流程
  - 審核與信任機制
  - 版本歷史實現狀態
  - MVP 路線圖

### ⚙️ 功能模塊設計 (features/)
各功能模塊的詳細設計文檔（統一使用 `feat-` 前綴）。

- **[feat-user-system.md](features/feat-user-system.md)** - 用戶與權限系統
  - 用戶角色定義
  - 數據庫表結構
  - API 接口設計
  - 權限控制邏輯
  - 郵箱驗證機制

- **[feat-collection.md](features/feat-collection.md)** - 集合（收藏夾）功能
  - 數據庫設計
  - 後端 API 設計
  - 前端交互設計
  - 集合管理頁面

- **[feat-export.md](features/feat-export.md)** - 異步導出系統
  - Cloudflare Workers 架構
  - Durable Object 實現
  - R2 存儲集成
  - 流式處理策略

- **[feat-ui-translation.md](features/feat-ui-translation.md)** - UI 翻譯系統
  - 用戶翻譯界面設計
  - 本地化翻譯同步方案
  - 完成度計算與激活邏輯
  - 審核工作流

- **[feat-i18n.md](features/feat-i18n.md)** - 國際化動態語言支持
  - 數據模型設計
  - 後端 API 設計
  - 前端實現方案
  - 用戶貢獻流程
  - 性能優化策略

 - **[feat-dynamic-languages.md](features/feat-dynamic-languages.md)** - 前端動態語言支持
    - 動態加載機制
    - 語言切換流程
    - 緩存策略
- **[feat-meaning-mapping.md](features/feat-meaning-mapping.md)** - 詞句與語義多對多關係
    - 數據模型設計（meanings、expression_meaning 表）
    - 數據遷移方案
    - API 接口設計
    - 前端交互實現
 - **[feat-expression-group-modal.md](features/feat-expression-group-modal.md)** - Handbook 詞句組快捷彈窗
     - 詞句組詳情彈窗設計
     - 表格展示所有翻譯
     - 快捷添加新翻譯功能
     - 組件與 API 集成
- **[feat-expression-group-abstraction.md](features/feat-expression-group-abstraction.md)** - Expression Group 抽象層設計
     - ExpressionGroup 概念定義
     - 隱藏 meanings 和 expression_meaning 表
     - ExpressionGroup 查詢接口實現
     - API 參數從 meaning_id 改爲 group_id

## 實施狀態

### 總體架構 (system/)
- [x] 基礎架構設計
- [x] 核心數據模型
- [x] 基礎 API 設計
- [ ] 版本回滾功能
- [ ] 版本比較功能
- [ ] 變更摘要功能

### 功能模塊 (features/)
- [x] feat-user-system - 基礎實現
- [x] feat-collection - 已實現
- [ ] feat-export - 待實現
- [x] feat-ui-translation - 基礎實現
- [ ] feat-i18n - 部分實現
- [ ] feat-dynamic-languages - 待實施
- [ ] feat-meaning-mapping - 設計完成，待實現

## 文檔規範

### 命名規範

- **總體設計文檔**：使用簡潔的名稱（如 `architecture.md`）
- **功能模塊文檔**：使用 `feat-` 前綴（如 `feat-user-system.md`）
- **README 文檔**：用於各子目錄的導航和說明

### 新增功能文檔

當需要新增功能模塊時：

1. 在 `design/features/` 目錄創建 `feat-{feature-name}.md`
2. 參考現有功能文檔的結構和格式
3. 更新 `design/features/README.md` 添加新文檔鏈接
4. 更新 `design/README.md` 添加簡要說明

### 文檔結構建議

功能模塊文檔應包含以下章節：

```markdown
# 功能名稱設計

## 概述
簡述功能的用途和目標

## 數據模型
相關數據庫表結構

## API 設計
涉及的 API 端點

## 前端實現
Vue 組件和交互邏輯

## 實施狀態
當前的完成度

## 相關文檔
其他相關的設計文檔鏈接
```

## 相關文檔

- [API 文檔](../api/)
- [實施指南](../guides/)
- [需求規範](../specs/)
- [計劃路線圖](../plans/)
