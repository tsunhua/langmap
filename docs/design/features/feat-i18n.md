# 國際化動態語言支持

## System Reminder

**設計來源**：本設計基於原始 `i18n.md`

**實現狀態**：
- ✅ 基礎架構設計 - 已完成
- ✅ 數據模型擴展 - 已完成（languages 表、tags 字段）
- ✅ 後端 API 基礎實現 - 已實現（語言列表、UI 翻譯端點）
- ⏳ 前端動態語言加載 - 部分實現（後端端點可用，前端集成需確認）
- ⏳ 用戶自定義語言創建 - 部分實現（API 已實現，前端集成需確認）
- ❌ 語言切換流程 - 未實現完整（緩存策略、用戶偏好保存）
- ❌ 用戶貢獻流程 - 未實現完整（翻譯貢獻、質量控制、審核）
- ❌ 性能優化 - 未實現（按需加載、多級緩存）
- ❌ 混合模式實現 - 未實現（核心語言靜態配置 + 動態語言）

**未實現的 API 端點**：
- `POST /api/v1/languages` - 提交新語言（API 已定義，實現需確認）
- 完成度計算 API（`calculateUITranslationCompletion` 在抽象層定義，具體實現需確認）

**未實現的功能**：
- 用戶語言貢獻界面
- 翻譯質量控制機制
- 機器翻譯建議集成
- 翻譯記憶功能
- 術語表集成

---

## 概述

國際化動態語言支持擴展方案，支持通過數據庫動態添加新語言，允許用戶自由貢獻界面翻譯。

## 目標

1. 支持通過數據庫動態添加新語言
2. 允許用戶自由貢獻界面翻譯
3. 實現界面文本的動態加載
4. 保持現有i18n框架的兼容性
5. 確保系統性能不受影響
6. 支持沒有標準BCP-47代碼的小衆語言

## 設計方案

### 1. 數據模型設計

#### languages表
```sql
CREATE TABLE languages (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,  -- 自定義語言代碼 (如: en, zh-CN, toki-pona, x-dialect)
    name VARCHAR(100) NOT NULL,        -- 語言顯示名稱
    native_name VARCHAR(100),          -- 本地語言名稱
    direction VARCHAR(3) DEFAULT 'ltr', -- 文字方向 (ltr/rtl)
    is_active BOOLEAN DEFAULT true,    -- 是否啓用
    created_by INTEGER,                -- 創建者用戶ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### expressions表擴展
在現有expressions表基礎上添加tags字段：
```sql
ALTER TABLE expressions ADD COLUMN tags TEXT[]; -- 標籤數組字段
```

### 2. 後端API設計

#### 獲取支持的語言列表
```
GET /api/v1/languages
響應:
[
  {
    "code": "en",
    "name": "English",
    "native_name": "English",
    "direction": "ltr"
  },
  {
    "code": "zh-CN",
    "name": "Simplified Chinese",
    "native_name": "簡體中文",
    "direction": "ltr"
  },
  {
    "code": "toki-pona",
    "name": "Toki Pona",
    "native_name": "toki pona",
    "direction": "ltr"
  }
]
```

#### 獲取指定語言的UI翻譯
```
GET /api/v1/expressions?lang={language_code}&tags=langmap
響應:
[
  {
    "id": 1,
    "text": "Explore the World of Languages",
    "language": "en",
    "region": "global",
    "tags": ["langmap", "home.title"]
  },
  {
    "id": 2,
    "text": "Home",
    "language": "en",
    "region": "global",
    "tags": ["langmap", "nav.home"]
  }
]
```

#### 提交新的語言
```
POST /api/v1/languages
請求體:
{
  "code": "custom-lang",        // 用戶自定義代碼
  "name": "Custom Language",    // 語言名稱
  "native_name": "Native Name", // 本地名稱
  "direction": "ltr"            // 文字方向
}
```

#### 提交新的翻譯（UI文本作爲特殊的表達式）
```
POST /api/v1/expressions
請求體:
{
  "text": "Home",
  "language": "custom-lang",
  "region": "global",
  "source_type": "ui",
  "tags": ["langmap", "nav.home"]
}
```

### 3. 前端實現方案

#### 動態加載翻譯
1. 應用啓動時從後端獲取當前用戶選擇的語言翻譯（帶langmap標籤的表達式）
2. 將獲取的翻譯轉換爲i18n所需的格式
3. 實現緩存機制避免重複請求

#### 語言切換流程
1. 用戶選擇新語言
2. 檢查本地是否有緩存翻譯
3. 如果沒有緩存，則從後端獲取帶langmap標籤的表達式
4. 轉換爲i18n消息格式並更新i18n實例
5. 保存到本地緩存

#### 用戶自定義語言創建流程
1. 提供"添加新語言"按鈕
2. 用戶填寫語言信息表單（代碼、名稱、本地名稱、文字方向）
3. 提交到後端創建新語言
4. 自動切換到新創建的語言

#### 緩存策略
1. 使用localStorage或IndexedDB緩存翻譯
2. 實現緩存過期機制（如24小時）
3. 提供強制刷新緩存的機制

### 4. 混合模式實現

爲了保持性能和兼容性，採用混合模式：

1. 保留核心語言（en, zh-CN, zh-TW, es, fr, ja）在靜態配置中
2. 動態語言通過數據庫加載
3. 當用戶選擇動態語言時，從後端獲取帶langmap標籤的表達式並動態註冊到i18n實例

### 5. 用戶貢獻流程

#### 語言貢獻
1. 用戶可以添加新語言，包括沒有標準代碼的小衆語言
2. 提供簡單的表單收集必要信息
3. 新語言創建後立即可用

#### 翻譯貢獻
1. 用戶可以在界面中提交缺失的翻譯
2. UI翻譯作爲帶langmap標籤的表達式存儲在expressions表中
3. 提交的翻譯進入待審核狀態
4. 管理員審核通過後生效

#### 質量控制
1. 實現投票機制，用戶可以對翻譯進行投票
2. 基於用戶信譽度加權投票結果
3. 實現舉報機制處理不當翻譯

### 6. 性能優化

#### 數據加載優化
1. 按需加載：只加載當前頁面需要的翻譯
2. 分批加載：將翻譯按功能模塊分組
3. 預加載：預測用戶可能訪問的頁面並預加載翻譯

#### 緩存策略
1. 實現多級緩存（內存緩存 + 本地存儲）
2. 使用HTTP緩存頭優化API響應
3. 實現緩存版本控制

## 實施步驟

### 第一階段：基礎架構
1. 修改expressions表，添加tags字段
2. 修改後端API接口以支持標籤查詢
3. 實現後端語言管理接口
4. 修改前端i18n初始化邏輯以支持動態加載

### 第二階段：核心功能
1. 實現語言切換功能
2. 實現翻譯緩存機制
3. 實現混合模式（靜態+動態語言）
4. 實現用戶自定義語言創建功能

### 第三階段：用戶功能
1. 實現翻譯貢獻界面
2. 實現審核流程
3. 實現質量控制機制

### 第四階段：優化完善
1. 實施性能優化
2. 添加錯誤處理和降級機制
3. 完善測試用例

## 風險與應對

### 性能風險
**風險**：動態加載可能影響頁面加載速度
**應對**：
- 實施緩存機制
- 使用懶加載策略
- 提供加載狀態提示

### 數據一致性風險
**風險**：數據庫中的翻譯與靜態配置可能不一致
**應對**：
- 建立同步機制
- 實施數據驗證
- 提供版本控制

### 用戶貢獻質量風險
**風險**：用戶貢獻的翻譯質量參差不齊
**應對**：
- 實施審核機制
- 建立信譽系統
- 提供舉報功能

## 總結

通過實現基於數據庫的動態語言支持系統，Langmap可以支持更多的語言，並允許社區貢獻翻譯。該方案在保持現有功能的基礎上，擴展了系統的語言支持能力，爲項目的國際化發展提供了可持續的解決方案。用戶可以自由添加任何語言，包括那些沒有標準BCP-47代碼的小衆語言，真正實現了語言的自由擴展。

通過在expressions表中添加tags字段，我們可以有效地區分UI翻譯和普通表達式，同時保持數據模型的統一性。這種方法充分利用了現有的表達式管理系統功能，如版本控制、審核機制等，避免了數據冗餘和維護複雜性。使用"langmap"作爲專有標籤能夠更好地標識這些UI翻譯屬於Langmap項目。