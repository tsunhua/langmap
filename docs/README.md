# LangMap 文檔中心

歡迎來到 LangMap 項目的文檔中心。本文檔提供所有項目文檔的導航和索引。

## 關於項目

**LangMap** 是一個開源、社區驅動的在線語言地圖項目，致力於收集世界各地的語言短語和表達方式，展示不同語言之間的差異，並爲語言愛好者提供有價值的資源。

## 文檔結構

```
docs/
├── policies/              # 政策與合規文檔
├── design/                # 系統設計與架構文檔
│   ├── system/            # 總體系統架構
│   └── features/          # 功能模塊設計（使用 feat- 前綴）
├── api/                   # API 接口文檔
├── guides/                # 實施與操作指南
├── plans/                 # 計劃與路線圖
├── specs/                 # 需求與規範文檔
└── README.md            # 文檔導航索引（本文件）
```

## 文檔目錄

### 📋 政策與合規 (policies/)
法律政策文檔，定義平臺的使用規則和數據處理規範。

- **[terms-privacy-content.md](policies/terms-privacy-content.md)** - 服務條款、隱私政策與內容政策（英文版）
- **[terms-privacy-content-zh.md](policies/terms-privacy-content-zh.md)** - 服務條款、隱私政策與內容政策（中文版）

### 🏗️ 系統設計 (design/)
系統架構、數據模型和功能設計的詳細技術文檔。

**總體架構 (system/)**
- **[architecture.md](design/system/architecture.md)** - 系統總體架構設計（技術棧、數據模型、API 設計、已實現和未實現狀態）

**功能模塊設計 (features/)**
各功能模塊的詳細設計文檔（統一使用 `feat-` 前綴），已標註實際實現狀態。

- **[feat-user-system.md](design/features/feat-user-system.md)** - 用戶與權限系統（角色定義、數據庫設計、API 接口、安全考慮、實現狀態標註）
- **[feat-collection.md](design/features/feat-collection.md)** - 集合（收藏夾）功能（數據模型、API 設計、前端交互、實現狀態標註）
- **[feat-handbook.md](design/features/feat-handbook.md)** - 學習手冊功能（Markdown編輯、動態語言詞句拉取、數據庫與API設計、實現狀態標註）
- **[feat-export.md](design/features/feat-export.md)** - 異步導出系統（架構設計、數據模型、API 規範、實現狀態標註）
- **[feat-ui-translation.md](design/features/feat-ui-translation.md)** - UI 翻譯系統（用戶翻譯界面、同步方案、審核工作流、實現狀態標註）
- **[feat-i18n.md](design/features/feat-i18n.md)** - 國際化動態語言支持（數據庫模型、API 設計、前端實現方案、實現狀態標註）
- **[feat-dynamic-languages.md](design/features/feat-dynamic-languages.md)** - 前端動態語言支持（動態加載機制、語言切換流程、實現狀態標註）
- **[feat-search.md](design/features/feat-search.md)** - 搜索功能設計（API 設計、前端實現、搜索策略、實現狀態標註）
- **[feat-heatmap.md](design/features/feat-heatmap.md)** - 語言地圖/熱力圖功能設計（數據模型、API 設計、可視化方案、實現狀態標註）
- **[feat-user-profile.md](design/features/feat-user-profile.md)** - 用戶資料/個人中心設計（數據模型、API 設計、前端實現、實現狀態標註）
- **[feat-database.md](design/features/feat-database.md)** - 數據庫設計（表結構、索引、遷移策略、性能優化、備份策略、實現狀態標註）
- **[feat-audio-upload.md](design/features/feat-audio-upload.md)** - 詞條錄音與上傳功能（前端直傳 R2、預籤名設計、低成本架構、實現狀態標註）
- **[feat-image-expression.md](design/features/feat-image-expression.md)** - 圖片詞句功能（圖片上傳與壓縮、R2 直傳架構、language_code='image' 標識、前端動態輸入方式切換、實現狀態標註）

### 🔌 API 文檔 (api/)
後端 API 的技術文檔、端點說明和部署指南。

- **[backend-guide.md](api/backend-guide.md)** - 後端部署與配置指南（數據庫架構、API 端點、國際化實現）
- **[statistics-api.md](api/statistics-api.md)** - 統計 API 設計（優化查詢邏輯、緩存機制）
- **[heatmap-api.md](api/heatmap-api.md)** - 熱力圖 API 設計（數據聚合、緩存策略）

### 📖 實施指南 (guides/)
開發和部署的操作指南和最佳實踐。

- **[corpus-acquisition.md](guides/corpus-acquisition.md)** - 語料獲取指南（開源數據源、預處理、地域標註）
- **[email-verification.md](guides/email-verification.md)** - 郵箱驗證實施指南（Resend 集成、前後端實現）

### 📋 計劃與路線圖 (plans/)
項目開發計劃、路線圖和版本歷史。

- **[2026-01-27-ios-app-design.md](plans/2026-01-27-ios-app-design.md)** - iOS 應用設計文檔（SwiftUI、MVVM 架構、核心屏幕）

### 📄 需求與規範 (specs/)
項目需求規範、業務分析與技術規格。

- **[BRD.md](specs/BRD.md)** - 業務需求文檔（願景、目標、市場分析）
- **[PRD.md](specs/PRD.md)** - 產品需求文檔（功能描述、用戶流程）
- **[SRS.md](specs/SRS.md)** - 系統需求規格說明（技術棧、系統架構、接口規範）

## 快速導航

### 按主題查找

- **項目願景與背景** → [specs/BRD.md](specs/BRD.md)
- **產品核心功能** → [specs/PRD.md](specs/PRD.md)
- **系統架構與技術棧** → [specs/SRS.md](specs/SRS.md), [design/system/architecture.md](design/system/architecture.md)
- **用戶系統** → [design/features/feat-user-system.md](design/features/feat-user-system.md)
- **認證與安全** → [design/features/feat-user-system.md](design/features/feat-user-system.md), [guides/email-verification.md](guides/email-verification.md)
- **國際化** → [design/features/feat-i18n.md](design/features/feat-i18n.md), [design/features/feat-ui-translation.md](design/features/feat-ui-translation.md)
- **數據管理** → [design/system/architecture.md](design/system/architecture.md), [design/features/feat-collection.md](design/features/feat-collection.md)
- **數據庫設計** → [design/features/feat-database.md](design/features/feat-database.md)
- **搜索功能** → [design/features/feat-search.md](design/features/feat-search.md)
- **語言地圖** → [design/features/feat-heatmap.md](design/features/feat-heatmap.md)
- **用戶資料** → [design/features/feat-user-profile.md](design/features/feat-user-profile.md)
- **API 參考** → [api/README.md](api/README.md)
- **部署指南** → [api/backend-guide.md](api/backend-guide.md), [guides/corpus-acquisition.md](guides/corpus-acquisition.md)
- **開發計劃** → [plans/2026-01-27-ios-app-design.md](plans/2026-01-27-ios-app-design.md)

### 按角色查找

**開發者**
- [系統需求規格 (SRS)](specs/SRS.md)
- [總體架構設計](design/system/architecture.md)
- [功能模塊設計](design/features/)
- [API 文檔](api/)

**產品經理**
- [業務需求 (BRD)](specs/BRD.md)
- [產品需求 (PRD)](specs/PRD.md)
- [計劃與路線圖](plans/)

**運維人員**
- [後端部署指南](api/backend-guide.md)
- [系統架構設計](design/system/architecture.md)

**用戶**
- [關於項目](specs/ABOUT_US.md)
- [服務條款](policies/terms-privacy-content.md)
- [隱私政策](policies/terms-privacy-content-zh.md)

## 文檔規範

### 命名規範

- **總體架構文檔**：使用簡潔的名稱（如 `architecture.md`）
- **功能模塊文檔**：使用 `feat-` 前綴（如 `feat-user-system.md`）
- 標註要求：所有功能模塊文檔必須包含 system-reminder 章節

### 更新文檔

1. 在對應的目錄下創建或更新文檔
2. 更新 README.md 以反映變更
3. 提交代碼時在 commit message 中說明文檔更新

### 新增功能文檔

對於新增的功能，應創建對應的設計文檔：

1. 在 `design/features/` 目錄創建 `feat-{feature-name}.md`
2. 參考現有功能文檔的結構和格式
3. 必須包含 system-reminder 章節，標註實現狀態
4. 更新 `design/features/README.md` 添加新文檔鏈接
5. 如有 API 變更，更新 `api/` 目錄相關文檔

---

*本文檔最後更新：2026年2月11日*
