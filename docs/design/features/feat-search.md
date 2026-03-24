# 搜索功能設計

## System Reminder

**實現狀態**：
- ✅ 後端搜索 API 已實現 - `GET /api/v1/search` + `searchExpressions()` 方法
- ✅ 前端搜索頁面已實現 - `Search.vue`
- ✅ 性能優化 - 已集成 L2 邊緣緩存 (TTL 1小時)
- ✅ 數據庫查詢支持 - LIKE 模糊匹配 + 複合索引優化
- ⏳ 高級搜索功能 - 未實現（全文檢索、拼寫糾正）
- ⏳ 搜索結果排序和過濾 - 部分實現

**已實現的 API 端點**：
- `GET /api/v1/search?q=...&from_lang=...&region=...&skip=...&limit=...` - 搜索表達式

**已實現的功能**：
- 基礎搜索（關鍵詞匹配）
- 按語言過濾
- 按地域過濾
- 分頁支持

**未實現的功能**：
- 全文檢索（Typesense/Elasticsearch）
- 拼寫糾正
- 高級過濾（按來源類型、審核狀態）
- 搜索歷史
- 搜索建議/自動完成

---

## 概述

搜索功能是 LangMap 項目的核心功能之一，允許用戶通過關鍵詞檢索表達式，並按語言和地域進行過濾。搜索功能支持模糊匹配，幫助用戶找到相關的語言表達。

## 數據模型

### 搜索相關字段

搜索主要使用 `Expression` 表的現有字段：

```typescript
interface Expression {
  id: number
  text: string              // 主要搜索字段
  meaning_id?: number
  audio_url?: string
  language_code: string      // 按語言過濾
  region_code?: string       // 按地域過濾
  region_name?: string
  tags?: string            // JSON 數組，用於高級搜索
  source_type?: string      // 按來源類型過濾
  review_status?: string    // 按審核狀態過濾
  created_by?: string
  created_at?: string
}
```

## API 設計

### GET /api/v1/search

搜索表達式，支持關鍵詞匹配和多維度過濾。

**查詢參數**：
- `q` (string) - 搜索關鍵詞（必需）
- `from_lang` (string) - 源語言代碼（可選）
- `region` (string) - 地域代碼（可選）
- `skip` (number) - 跳過數量（默認 0）
- `limit` (number) - 返回數量限制（默認 20）

**響應**：
```json
{
  "results": [
    {
      "id": 1,
      "text": "Hello",
      "language_code": "en",
      "region_code": "US",
      "source_type": "user",
      "review_status": "approved",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 125,
  "skip": 0,
  "limit": 20
}
```

### 實現詳情

後端使用簡單的 LIKE 模糊匹配：

```typescript
async searchExpressions(query: string, fromLang?: string, region?: string, skip: number = 0, limit: number = 20): Promise<Expression[]> {
  let sql = 'SELECT * FROM expressions WHERE text LIKE ?'
  const params = [`%${query}%`]

  if (fromLang) {
    sql += ' AND language_code = ?'
    params.push(fromLang)
  }

  if (region) {
    sql += ' AND region_code = ?'
    params.push(region)
  }

  sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?'
  params.push(limit, skip)

  const { results } = await this.db.prepare(sql).bind(...params).all<Expression>()
  return results
}
```

## 前端實現

### Search.vue 頁面

主要功能：
1. 搜索輸入框
2. 語言選擇器
3. 地域選擇器
4. 搜索結果列表
5. 分頁控件

**交互流程**：
1. 用戶輸入搜索關鍵詞
2. 選擇語言和地域（可選）
3. 點擊搜索或按回車
4. 調用搜索 API
5. 顯示搜索結果
6. 點擊結果跳轉到詳情頁

## 搜索策略

### 當前實現（簡單匹配）

- **LIKE 模糊匹配**：使用 SQL LIKE `%query%` 進行匹配
- **多維度過濾**：支持按語言、地域過濾
- **分頁支持**：使用 skip 和 limit 分頁

### 未來改進計劃

#### 1. 全文檢索

引入 Typesense 或 Elasticsearch：

**優點**：
- 更快的搜索性能
- 支持拼寫糾正
- 相關性排序
- 支持複雜查詢（AND、OR、NOT）

**實施**：
```typescript
// Typesense 客戶端示例
const searchResults = await client.collections('expressions').documents().search({
  q: query,
  query_by: 'text',
  filter_by: `language_code:${fromLang}, region_code:${region}`,
  page: 1,
  per_page: 20
})
```

#### 2. 拼寫糾正

使用搜索引擎的拼寫糾正功能，自動糾正用戶輸入的拼寫錯誤。

#### 3. 高級過濾

添加更多過濾選項：
- 按來源類型過濾（authoritative/ai/user）
- 按審核狀態過濾（approved/pending）
- 按時間範圍過濾
- 按熱度過濾（投票數）

#### 4. 搜索歷史

- 記錄用戶的搜索歷史
- 提供快速重新搜索
- 支持刪除搜索歷史

#### 5. 搜索建議/自動完成

- 根據用戶輸入提供實時搜索建議
- 使用前綴匹配
- 顯示匹配的文本和數量

## 性能優化

### 當前優化

- **分頁**：避免一次返回過多數據
- **邊緣緩存**：集成 L2 緩存，TTL 1小時，針對相同搜索詞實現秒開。
- **複合索引**：部署了 `idx_expressions_lang_text` 等索引，優化模糊查找後的排序開銷。

### 未來優化

- **緩存**：緩存熱門搜索詞的結果
- **搜索服務**：使用 Typesense/Elasticsearch 提升性能
- **防抖**：前端搜索輸入防抖，減少 API 調用

## 用戶界面設計

### 搜索頁面布局

```
┌─────────────────────────────────────────┐
│  Search Bar                           │
│  [Search Input]  [Lang]  [Region]    │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Search Results                       │
│  ┌──────────────────────────────────┐ │
│  │ Expression 1                   │ │
│  │ [Language] [Region] [Source]   │ │
│  └──────────────────────────────────┘ │
│  ┌──────────────────────────────────┐ │
│  │ Expression 2                   │ │
│  └──────────────────────────────────┘ │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Pagination                          │
│  [Previous] 1 2 3 ... 10 [Next]    │
└─────────────────────────────────────────┘
```

## 測試策略

### 單元測試
- 測試搜索表達式方法
- 測試過濾邏輯
- 測試分頁邏輯

### 集成測試
- 測試搜索 API 端點
- 測試搜索參數驗證
- 測試搜索結果格式

### 前端測試
- 測試搜索頁面組件
- 測試搜索輸入和過濾
- 測試分頁交互

## 相關文檔

- [系統架構設計](../system/architecture.md)
- [後端 API 指南](../../api/backend-guide.md)
