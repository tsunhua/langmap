# LangMap 前後端代碼重構計劃

**制定日期**: 2026年3月18日  
**優先級**: 分三階段執行

---

## 📊 現狀分析

### 後端 (Backend)
- **框架**: Hono.js + Cloudflare Workers
- **數據庫**: Cloudflare D1 (SQLite)
- **存儲**: R2 Bucket (音頻/導出)
- **認證**: JWT + bcryptjs
- **當前問題**:
  - API v1.ts 文件過大，需要模塊化拆分
  - 缺少統一的錯誤處理層
  - 數據庫查詢邏輯未充分抽象
  - 缺少API文檔和OpenAPI規範
  - 環境變量管理不規範
  - 缺少測試框架和單元測試

### 前端 (Frontend)
- **框架**: Vue 3 + Composition API
- **路由**: Vue Router 4
- **國際化**: Vue i18n
- **樣式**: Tailwind CSS
- **HTTP客戶端**: Axios
- **當前問題**:
  - 組件劃分不夠清晰
  - 狀態管理缺失（無Pinia/Vuex）
  - 重複的API調用邏輯
  - 缺少錯誤處理標準化
  - 缺少TypeScript類型定義
  - 頁面組件和業務邏輯混雜

---

## 🎯 重構目標

1. **提高代碼可維護性** - 模塊化、單一職責
2. **增強類型安全** - 完整的TypeScript類型定義
3. **規範化錯誤處理** - 統一的異常管理
4. **提升開發效率** - 自動化測試、文檔生成
5. **性能優化** - 代碼分割、緩存策略
6. **團隊協作** - API文檔、代碼規範

---

## 📋 第一階段：架構和基礎設施 (2-3周)

### 後端重構

#### 1.1 API路由模塊化
**目標**: 將單一的 `v1.ts` 拆分爲功能模塊

```
backend/src/server/
├── routes/
│   ├── auth.ts          # 認證相關
│   ├── expressions.ts   # 表達式管理
│   ├── languages.ts     # 語言管理
│   ├── collections.ts   # 收藏集合
│   ├── users.ts         # 用戶管理
│   ├── export.ts        # 導出功能
│   └── index.ts         # 路由匯總
├── middleware/
│   ├── auth.ts          # 認證中間件
│   ├── error.ts         # 錯誤處理
│   ├── validation.ts    # 數據驗證
│   └── logging.ts       # 日誌記錄
├── schemas/             # Zod驗證模式
│   ├── auth.ts
│   ├── expression.ts
│   ├── user.ts
│   └── collection.ts
├── services/            # 業務邏輯
│   ├── auth.ts
│   ├── expression.ts
│   ├── user.ts
│   └── collection.ts
├── db/
│   ├── queries/         # 數據庫查詢
│   │   ├── auth.ts
│   │   ├── expression.ts
│   │   └── ...
│   └── migrations/      # 遷移文件
├── types/               # 類型定義
│   ├── api.ts           # API響應類型
│   ├── entity.ts        # 數據實體
│   └── error.ts         # 錯誤類型
└── utils/
    ├── jwt.ts           # JWT工具
    ├── password.ts
    └── response.ts      # 標準響應格式
```

**關鍵任務**:
- [x] 創建文件夾結構
- [x] 提取認證邏輯到 `services/auth.ts`
- [x] 提取表達式邏輯到 `services/expression.ts`
- [x] 使用Zod定義所有驗證schema
- [x] 統一使用 `utils/response.ts` 返迴響應 (所有路由已更新使用統一響應格式)


#### 1.2 錯誤處理層
**創建**: `backend/src/server/error/handler.ts`

```typescript
// 錯誤類型和處理
export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
    public details?: any
  ) {
    super(message)
  }
}

export const errorHandler = (error: unknown) => {
  // 統一處理所有錯誤
}
```

**關鍵任務**:
- [ ] 定義標準錯誤響應格式
- [ ] 創建自定義錯誤類
- [ ] 添加全局錯誤處理中間件
- [ ] 完善調試日誌

#### 1.3 環境配置規範化
**創建**：`backend/src/config.ts`

```typescript
export const config = {
  api: {
    baseUrl: process.env.API_BASE_URL,
    version: 'v1'
  },
  db: {
    // D1配置
  },
  auth: {
    jwtSecret: process.env.SECRET_KEY,
    tokenExpiry: '24h'
  },
  storage: {
    // R2配置
  }
}
```

**關鍵任務**:
- [x] 整合所有環境變量
- [x] 創建 `.env.example`
- [ ] 添加配置驗證

#### 1.4 數據庫查詢層抽象
**創建**: `backend/src/server/db/queries/`

```typescript
// 每個功能模塊一個查詢文件
// 示例: queries/expression.ts
export class ExpressionQueries {
  async findById(db: D1Database, id: number) { }
  async findAll(db: D1Database, filters: object) { }
  async create(db: D1Database, data: object) { }
  async update(db: D1Database, id: number, data: object) { }
  async delete(db: D1Database, id: number) { }
}
```

**關鍵任務**:
- [ ] 提取所有SQL查詢到專用模塊
- [ ] 創建參數化查詢以防SQL注入
- [ ] 添加查詢日誌

---

### 前端重構

#### 2.1 狀態管理 (Pinia)
**創建**: `web/src/stores/`

```
web/src/stores/
├── auth.ts          # 認證狀態
├── expressions.ts   # 表達式列表
├── user.ts         # 用戶信息
├── ui.ts           # UI狀態
└── index.ts        # 導出
```

**關鍵任務**:
- [x] 安裝Pinia: `npm install pinia`
- [x] 創建認證store
- [x] 創建用戶store
- [ ] 遷移Axios調用到actions

#### 2.2 API客戶端層
**創建**: `web/src/api/`

```
web/src/api/
├── client.ts           # Axios配置和攔截器
├── auth.ts            # 認證API
├── expressions.ts     # 表達式API
├── languages.ts       # 語言API
├── collections.ts     # 收藏集合API
└── index.ts           # API導出
```

**關鍵任務**:
- [x] 集中Axios配置
- [x] 添加請求/響應攔截器 (已更新以處理統一響應格式)
- [x] 錯誤處理標準化 (統一錯誤處理)
- [x] 添加請求loading狀態

#### 2.3 類型定義完善
**創建**: `web/src/types/`

```typescript
// types/api.ts - API響應類型
export interface ApiResponse<T> {
  code: number
  message: string
  data?: T
}

// types/models.ts - 數據模型
export interface Expression {
  id: number
  language: string
  phrase: string
  // ...
}

// types/components.ts - 組件props類型
```

**關鍵任務**:
- [x] 統一API響應類型
- [x] 定義所有數據模型
- [x] 定義組件props類型

#### 2.4 組件結構優化
**重新組織**: `web/src/components/`

```
web/src/components/
├── common/            # 可復用組件
│   ├── Button.vue
│   ├── Modal.vue
│   ├── Form.vue
│   └── ...
├── layout/            # 布局組件
│   ├── Header.vue
│   ├── Sidebar.vue
│   └── Footer.vue
├── features/          # 功能組件
│   ├── ExpressionCard.vue
│   ├── LanguageSelector.vue
│   └── ...
└── README.md          # 組件文檔
```

**關鍵任務**:
- [x] 分類組件
- [x] 提取公共邏輯到composables (useAuth.ts, useForm.ts, useExpressions.ts 已存在)
- [x] 編寫組件文檔 (web/src/components/README.md 已創建)

#### 2.5 Composables提取
**創建**: `web/src/composables/`

```
web/src/composables/
├── useAuth.ts           # 認證邏輯
├── useExpressions.ts    # 表達式獲取
├── useForm.ts          # 表單處理
├── useNotification.ts  # 通知
└── useAsyncData.ts     # 異步數據加載
```

**關鍵任務**:
- [x] 提取表達式獲取邏輯 (useExpressions.ts 已存在)
- [x] 提取表單驗證邏輯 (useForm.ts 已存在)
- [x] 提取認證邏輯 (useAuth.ts 已存在)

---

## 📋 第二階段：測試和文檔 (2-3周)

### 後端測試

#### 3.1 單元測試框架
- [ ] 安裝Vitest: `npm install vitest`
- [ ] 配置測試環境
- [ ] 爲services編寫單元測試
- [ ] 目標覆蓋率: 70%+

```
backend/src/__tests__/
├── unit/
│   ├── services/auth.test.ts
│   ├── services/expression.test.ts
│   └── utils/jwt.test.ts
└── integration/
    ├── api/auth.test.ts
    └── api/expressions.test.ts
```

#### 3.2 API文檔
- [ ] 安裝OpenAPI生成: `npm install -D @hono/typegen-hono-openapi`
- [ ] 爲所有API端點添加OpenAPI注釋
- [ ] 生成Swagger文檔
- [ ] 部署API文檔到 `/api/docs`

### 前端測試

#### 3.3 單元和集成測試
- [ ] 安裝Vitest + Vue Test Utils
- [ ] 爲組件編寫單元測試
- [ ] 爲store編寫測試
- [ ] 目標覆蓋率: 60%+

```
web/src/__tests__/
├── unit/
│   ├── components/ExpressionCard.test.ts
│   ├── stores/auth.test.ts
│   └── composables/useAuth.test.ts
└── integration/
    ├── pages/CreateExpression.test.ts
    └── api/expressions.test.ts
```

#### 3.4 E2E測試
- [ ] 安裝Cypress或Playwright
- [ ] 編寫關鍵用戶流程測試
- [ ] 配置CI/CD測試自動化

### 代碼文檔

#### 3.5 API文檔 (後端)
- [ ] README.md - 項目概覽
- [ ] ARCHITECTURE.md - 架構說明
- [ ] API_DOCS.md - API文檔
- [ ] DATABASE.md - 數據庫架構

#### 3.6 代碼文檔 (前端)
- [ ] COMPONENTS.md - 組件指南
- [ ] STATE_MANAGEMENT.md - 狀態管理說明
- [ ] DEVELOPMENT.md - 開發指南

---

## 📋 第三階段：性能優化和部署 (1-2周)

### 後端優化

#### 4.1 緩存策略
- [ ] 實現HTTP緩存頭
- [ ] 添加Cloudflare緩存規則
- [ ] 爲熱門查詢添加緩存

#### 4.2 數據庫優化
- [ ] 添加適當的數據庫索引
- [ ] 優化N+1查詢問題
- [ ] 添加數據庫查詢日誌和監控

#### 4.3 API性能
- [ ] 添加請求速率限制
- [ ] 實現分頁
- [ ] 優化大數據響應

### 前端優化

#### 4.4 代碼分割
- [ ] 配置動態import實現路由代碼分割
- [ ] 預加載關鍵資源
- [ ] 優化bundle大小

#### 4.5 性能監控
- [ ] 集成Web Vitals監控
- [ ] 添加錯誤追蹤 (Sentry)
- [ ] 監控API響應時間

#### 4.6 構建優化
- [ ] 配置Vite預構建
- [ ] 優化CSS和JS壓縮
- [ ] 生成源地圖用於生產調試

### 部署和CI/CD

#### 4.7 自動化部署
- [ ] 配置GitHub Actions
- [ ] 自動運行測試
- [ ] 自動部署到預發布環境
- [ ] 手動批准生產部署

```yaml
# .github/workflows/deploy.yml
name: Deploy
on: [push, pull_request]
jobs:
  test:
    # 運行測試
  deploy-staging:
    # 部署到staging
  deploy-production:
    # 手動批准後部署
```

---

## 🔄 重構順序和優先級

### Week 1-2: 後端基礎架構
1. **高優先級** (必須):
    - [x] API路由模塊化
    - [ ] 錯誤處理層
    - [x] 環境配置規範化

2. **中優先級** (應該):
    - [ ] 數據庫查詢層抽象
    - [x] 使用Zod驗證

### Week 3: 前端基礎架構
1. **高優先級** (必須):
    - [x] 狀態管理 (Pinia)
    - [x] API客戶端層
    - [x] 類型定義完善

2. **中優先級** (應該):
    - [x] 組件結構優化
    - [x] Composables提取

### Week 4-5: 測試和文檔
1. **高優先級**:
   - [ ] 後端單元測試
   - [ ] 前端單元測試
   - [ ] API文檔

2. **中優先級**:
   - [ ] E2E測試
   - [ ] 代碼文檔

### Week 6-7: 性能優化
1. **中優先級**:
   - [ ] 緩存策略
   - [ ] 代碼分割
   - [ ] 構建優化

2. **低優先級**:
   - [ ] 性能監控
   - [ ] 細粒度優化

---

## 📦 依賴安裝清單

### 後端
```bash
# 數據驗證
npm install zod @hono/zod-validator

# 測試
npm install -D vitest @testing-library/node

# 日誌
npm install pino

# 監控/追蹤
npm install @opentelemetry/api @opentelemetry/sdk-node
```

### 前端
```bash
# 狀態管理
npm install pinia

# 表單/驗證
npm install vee-validate zod

# 測試
npm install -D vitest @testing-library/vue @vue/test-utils

# Linting和格式化
npm install -D eslint prettier eslint-plugin-vue

# 性能監控
npm install web-vitals
```

---

## 🎯 成功指標

### 代碼質量
- [ ] 類型覆蓋率: 85%+
- [ ] 測試覆蓋率: 65%+ (後端 70%, 前端 60%)
- [ ] ESLint通過率: 100%
- [ ] 沒有關鍵代碼味問題

### 性能
- [ ] Lighthouse評分: 85+
- [ ] First Contentful Paint (FCP): < 1.5s
- [ ] Time to Interactive (TTI): < 2.5s
- [ ] API響應時間: < 200ms (中位數)

### 維護性
- [ ] 所有公共API都有文檔
- [ ] 新文件都有類型定義
- [ ] 代碼審查時間降低30%
- [ ] Bug修復時間縮短25%

---

## 🚀 執行建議

### 團隊協作
- **後端小組**: 專注階段1的後端部分
- **前端小組**: 同時進行階段1的前端部分
- **QA**: 準備測試用例，爲階段2做準備

### 風險管理
- 每階段結束前進行代碼審查
- 保持舊代碼兼容，逐步遷移
- 使用Feature flags隱藏未完成的功能
- 頻繁merge到主分支 (日常)

### 溝通
- 每日站會 15分鐘
- 每周進度評審
- 文檔同步更新

---

## 📚 相關文件

- 現有項目: `/Users/share.lim/Documents/GitHub/langmap`
- 後端源碼: `backend/src`
- 前端源碼: `web/src`
- 腳本: `scripts/`

---

**下一步**: 選擇第一階段的任務開始執行，或需要我詳細解析某個模塊的重構方案。
