# UI 翻譯系統設計

## System Reminder

**設計來源**：本設計整合了原始 `design_ui_translation.md` 和 `user_translate_locales_design.md`

**實現狀態**：
- ✅ 翻譯界面基礎功能 - 已實現
- ✅ 後端 API 基礎實現 - 已實現
- ✅ 性能優化 (L2 Cache + 專用索引) - 已實現
- ✅ 完成度計算 - 已實現
- ⏳ 自動激活邏輯 - 部分實現（閾值檢測已完成，但自動激活機制需確認）
- ⏳ 管理員同步功能 - 部分實現（同步按鈕已設計，但未實現）
- ❌ 審核工作流完善 - 未實現（審核隊列、批准/拒絕功能）
- ❌ 高級工具 - 未實現（機器翻譯建議、翻譯記憶、術語表）
- ❌ 質量保證 - 未實現（翻譯完整性驗證、複數形式、上下文信息）

**未實現或需確認的 API 端點**：
- `POST /api/v1/ui-translations/:language` - 保存翻譯（部分實現，需確認批量保存功能）
- 完成度計算 API（前端已實現，後端可能需要對應端點）
- 語言自動激活 API（需要確認是否已實現）

**已實現的功能**：
- 翻譯界面語言選擇器
- 過濾控件（未翻譯/已翻譯/全部）
- 翻譯表格和分頁
- 進度可視化顯示
- 參考語言和目標語言匹配邏輯

---

## 概述

UI 翻譯系統設計，包括用戶翻譯界面、本地化翻譯同步方案和翻譯數據管理機制。

## 用戶翻譯功能

### 翻譯界面設計

翻譯界面採用基於表格的形式，包含以下列：
1. **本地化鍵** - 每個可翻譯字符串的鍵/標識符
2. **參考語言** - 用作參考的源語言（通常是英語）
3. **目標語言** - 用戶可以輸入翻譯的輸入字段

#### 關鍵組件

**語言選擇**
- 用戶可以選擇要翻譯的目標語言
- 用戶可以選擇用作參考的語言
- 參考語言和目標語言不能相同
- 顯示所選語言的當前進度百分比
- 顯示語言當前是否處於活動狀態（≥60%完成度）

**過濾控件**
- 過濾選項：未翻譯（默認）、已翻譯、全部
- 搜索框：支持模糊匹配，快速查找需要翻譯的條目

**翻譯表格**
- 每一行代表一個可翻譯的UI字符串
- 中間列顯示參考字符串以提供上下文
- 最右列包含用於翻譯的可編輯輸入字段
- 在參考語言列和目標語言列之間添加">>"按鈕，點擊後可將參考翻譯填充到待翻譯的輸入框中
- 進度指示器顯示已翻譯的字符串數量
- 表格支持分頁或虛擬滾動以處理大量數據

**提交控件**
- 保存按鈕用於提交翻譯
- 進度可視化顯示總體完成百分比
- 清晰指示語言何時變爲活動狀態（達到60%閾值時）

#### 頁面路徑

- 翻譯頁面路徑：`/translate`
- 頁面URL可包含查詢參數：`/translate?refLang=en-US&targetLang=fr`
- 如果沒有查詢參數，則默認參考語言爲`en-US`，目標語言需要用戶選擇

### 後端實現

#### 數據模型

系統使用現有的 `expressions` 表存儲用戶貢獻的翻譯：

```sql
CREATE TABLE IF NOT EXISTS expressions (
    id INTEGER PRIMARY KEY NOT NULL,
    text TEXT NOT NULL,
    meaning_id INTEGER, -- 關聯的 en-US 的 expression_id
    audio_url TEXT,
    language_code TEXT NOT NULL,
    region_code TEXT,
    region_name TEXT,
    region_latitude REAL,
    region_longitude REAL,
    tags TEXT,
    source_type TEXT DEFAULT 'user',
    source_ref TEXT,
    review_status TEXT DEFAULT 'pending',
    created_by TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_by TEXT,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);
```

對於用戶貢獻的翻譯：
- `text` - 存儲翻譯後的文本
- `meaning_id` - 指向英文原文的ID，用於關聯同一含義的不同語言翻譯
- `language_code` - 目標語言代碼
- `tags` - 存儲本地化鍵路徑，如 `["home.title"]`
- `source_type` - 設置爲 `"user"` 表示用戶貢獻的翻譯
- `review_status` - 初始設置爲 `"pending"`，待審核

#### API 端點

**GET /api/v1/ui-translations/:language**
- 獲取指定語言的UI翻譯
- **性能優化**：已集成 L2 邊緣緩存 (TTL 1小時) 並利用 `idx_collections_name` 索引加速收藏集查找。
- 支持過濾參數：`filter` (untranslated/translated/all)
- 支持搜索參數：`search`
- 支持分頁參數：`skip` 和 `limit`

**POST /api/v1/ui-translations/:language**
- 批量提交用戶翻譯
- 請求體示例：
```json
{
  "translations": [
    {
      "key": "home.title",
      "text": "首頁標題"
    }
  ]
}
```

#### 完成度計算

```javascript
完成度 % = (已翻譯鍵數 / 總鍵數) * 100
```

- 已翻譯鍵數：目標語言中非空翻譯的鍵的數量
- 總鍵數：應用程序中可翻譯鍵的總數

#### 激活邏輯

當語言完成度達到60%時將自動激活：
- 完成度低於60%的語言被視爲"進行中"
- 完成度達到或超過60%的語言被視爲"活動"狀態
- 在 `languages` 表中將 `is_active` 字段設置爲 1
- 每次提交翻譯時都會檢查激活狀態

### 前端實現

#### Vue 組件結構

1. **TranslateInterface.vue** - 翻譯頁面的主容器組件
2. **LanguageSelector.vue** - 語言選擇下拉菜單
3. **FilterControls.vue** - 過濾控件
4. **TranslationProgress.vue** - 完成百分比的可視化指示器
5. **TranslationTable.vue** - 主表格界面

#### 狀態管理

關鍵響應式數據：
- `referenceLanguage` - 參考語言
- `selectedLanguage` - 目標語言
- `languages` - 所有可用語言列表
- `referenceTranslations` - 參考語言翻譯數據
- `targetTranslations` - 目標語言翻譯數據
- `mergedTranslations` - 合併後的雙語對照數據
- `completionPercentage` - 當前完成百分比
- `isActive` - 語言是否處於活動狀態
- `filterOptions` - 過濾選項
- `searchQuery` - 搜索關鍵詞

#### 表單驗證

- 驗證參考語言和目標語言不能相同
- 提交翻譯前驗證所有必填字段

#### 數據處理邏輯

1. 並行調用兩次 `/api/v1/ui-translations/:language` 接口獲取數據
2. 根據 `tags` 字段將兩種語言的數據進行匹配合併
3. 生成三列數據：本地化鍵、參考語言文本、目標語言文本
4. 根據過濾條件和搜索關鍵詞篩選數據

---

## 翻譯同步系統

### 問題背景

當前系統中，翻譯 key 的管理存在數據流斷裂問題：

1. **靜態 locales 文件**（`web/src/locales/en-US.json` 等）是前端 UI 翻譯的權威來源
2. **數據庫 expressions 表**通過 `langmap` 收藏集存儲翻譯
3. **缺失環節**：從 locales 文件到數據庫沒有自動同步機制
4. **結果**：開發者新增的翻譯 key 在前端可見，但在翻譯界面不可見

### 系統架構

```
┌─────────────────────────────────────────┐
│     前端 (Vue + Vue I18n)            │
└─────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  1. 靜態文件加載                 │
│     8種核心語言: en-US, zh-CN...  │
│     直接從 locales/*.json 導入        │
│  2. 動態加載 (其他語言)            │
│     i18n.js: loadLanguage(langCode)   │
└─────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│         後端 API (Hono)             │
└─────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│       Cloudflare D1 數據庫            │
│  expressions 表 + collections 表       │
└─────────────────────────────────────────┘
```

### 數據關聯機制

- **meaning_id**：不同語言的翻譯通過 meaning_id 關聯到同一含義
- **對於 en-US**：meaning_id 就是其自身的 id
- **對於其他語言**：meaning_id 指向 en-US 的對應翻譯 id
- **tags 字段**：存儲本地化鍵（如 `["home.title"]`）

---

## 推薦同步方案

### 方案零：前端直接顯示本地 JSON（推薦）

**核心思路**：翻譯界面直接讀取本地 `locales/en-US.json` 文件作爲參考語言，合併數據庫中的目標語言翻譯。

**優點**：
- 最簡單：無需後端同步，無需數據庫操作
- 最快速：立即可用，新增 key 自動顯示
- 無風險：不修改數據庫，不影響現有數據
- 易維護：純前端改動，邏輯清晰

**實現方式**：

修改 `web/src/pages/TranslateInterface.vue`：

```javascript
import enMessages from '../locales/en-US.json'

// 扁平化 en-US.json
const flattenObject = (obj, prefix = '') => {
  const flattened = {}
  for (const key in obj) {
    const newKey = prefix ? `${prefix}.${key}` : key
    if (typeof obj[key] === 'object' && obj[key] !== null) {
      Object.assign(flattened, flattenObject(obj[key], newKey))
    } else {
      flattened[newKey] = obj[key]
    }
  }
  return flattened
}

// 在組件加載時使用本地 en-US
const loadReferenceTranslations = () => {
  const flattened = flattenObject(enMessages)
  referenceTranslations.value = Object.entries(flattened).map(([key, text]) => ({
    key,
    text,
    meaning_id: key,
    fromLocal: true
  }))
}
```

### 管理員同步功能（可選）

在翻譯界面添加一個**同步按鈕**，僅管理員可見：

**功能描述**：
- 新增：數據庫中不存在的 key 會被創建
- 忽略：數據庫中已存在的 key 不會被覆蓋（保持數據安全）

**設計考慮**：
1. 權限控制：僅管理員可見同步按鈕
2. 冪等性：多次同步不會產生重複數據
3. 安全性：不覆蓋已有翻譯，避免誤操作
4. 反饋：顯示同步進度和結果統計

---

## 審核工作流

爲了確保翻譯質量，系統將實施審核工作流：

- 用戶提交的翻譯初始狀態爲 `"pending"`
- 管理員可以審核並批准翻譯，將其狀態更改爲 `"approved"`
- 只有已批准的翻譯才會計算在完成度內
- 被拒絕的翻譯可以被重新編輯和提交

---

## 未來增強功能

1. **協作功能**
   - 多個用戶爲同一語言做貢獻
   - 翻譯的討論功能
   - 翻譯排行榜

2. **高級工具**
   - 機器翻譯建議作爲起點
   - 翻譯記憶以重用先前批准的翻譯
   - 術語表集成以確保術語的一致性

3. **質量保證**
   - 翻譯完整性的自動化驗證
   - 複數形式處理
   - 上下文信息用於消除歧義的字符串

---

## 相關文檔

- [國際化設計方案](./i18n-architecture.md)
- [導出系統設計](./export-system.md)
- [用戶系統設計](./user-system.md)
