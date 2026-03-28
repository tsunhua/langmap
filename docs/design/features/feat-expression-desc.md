# Expression 描述字段功能設計

## System Reminder

**設計來源**：根據用戶需求（爲 expression 增加描述/例句字段，支持 Markdown 渲染）設計。

**實現狀態**：⏳ 待實現

---

## 1. 背景與目標

在 LangMap 中，每條 expression（詞句）目前僅有 `text` 字段存儲詞句文本。用戶希望爲 expression 增加一個 `desc`（description）字段，用於：

- 添加對該詞句的描述、解釋或補充說明
- 提供例句或用法示范
- 記錄語境信息（如口語/書面語、正式/非正式等）
- 其他用戶認爲有助於理解的備註

**核心原則**：
- **簡潔實現**：在 `expressions` 表新增 `desc` TEXT 字段即可，無需新建表
- **Markdown 支持**：`desc` 內容以 Markdown 格式存儲，在詞句詳情頁（Detail.vue）中渲染
- **可選字段**：`desc` 爲可選字段，不影響現有功能

## 2. 數據模型設計

### 2.1 expressions 表新增字段

```sql
-- Migration: 040_add_expression_desc.sql
ALTER TABLE expressions ADD COLUMN desc TEXT DEFAULT NULL;
```

新增字段：
| 字段 | 類型 | 約束 | 說明 |
|------|------|------|------|
| `desc` | TEXT | 可爲 NULL | Markdown 格式的描述/例句內容，最大 1000 字符 |

### 2.2 ExpressionVersion 表同步

版本歷史表也需新增 `desc` 字段以支持版本追蹤：

```sql
ALTER TABLE expression_versions ADD COLUMN desc TEXT DEFAULT NULL;
```

### 2.3 TypeScript 類型更新

```typescript
// backend/src/server/db/protocol.ts
export interface Expression {
  id: number
  text: string
  desc?: string | null           // 新增：Markdown 描述/例句
  audio_url?: string | null
  language_code: string
  region_code?: string
  region_name?: string
  region_latitude?: string
  region_longitude?: string
  tags?: string
  source_type?: string
  source_ref?: string
  review_status?: string
  created_by?: string
  created_at?: string
  updated_by?: string
  updated_at?: string
}
```

## 3. 後端 API 設計

### 3.1 Schema 驗證更新

```typescript
// backend/src/server/schemas/expression.ts
// createExpressionSchema 新增：
desc: z.string().max(1000).optional().nullable(),

// updateExpressionSchema 新增：
desc: z.string().max(1000).optional().nullable(),
```

### 3.2 查詢返回

所有返回 expression 數據的 API 均自動包含 `desc` 字段（D1 查詢已返回所有列，無需額外修改查詢語句）：

- `GET /api/v1/expressions/:id` — 包含 `desc`
- `GET /api/v1/expressions` — 列表接口包含 `desc`（用於搜索結果卡片預覽）
- `GET /api/v1/groups/:id` — group 中的 expressions 包含 `desc`
- `GET /api/v1/expressions/:id/versions` — 版本歷史包含 `desc`

### 3.3 版本追蹤

更新 expression 的 `desc` 時，同步在 `expression_versions` 中記錄版本快照（現有版本記錄邏輯已涵蓋，只需確保 `desc` 字段包含在版本快照中）。

## 4. 前端設計

### 4.1 詞句詳情頁（Detail.vue）

在 Detail.vue 的左側主內容區，`ExpressionCard` 下方新增描述展示區域：

```
┌─────────────────────────────────┐
│  ExpressionCard                  │  ← 現有：詞句文本、標籤、操作按鈕
├─────────────────────────────────┤
│  描述 / 例句                     │  ← 新增
│  ┌─────────────────────────────┐│
│  │ (Markdown 渲染結果)          ││
│  │                             ││
│  │ 例句：                      ││
│  │ - 這是一句常用口語。        ││
│  │ - 在正式場合中較少使用。    ││
│  │                             ││
│  │ **注意**：用於非正式場合。   ││
│  └─────────────────────────────┘│
│                    [編輯描述]    │
├─────────────────────────────────┤
│  關聯詞句組                      │  ← 現有
│  ...                            │
└─────────────────────────────────┘
```

**顯示規則**：
- 如果 `desc` 爲空或 null，不顯示描述區域
- Markdown 渲染使用 `marked` 或項目已有的 Markdown 渲染庫（Handbook 已使用 Markdown 渲染，可復用）
- 渲染風格與 Handbook 筆記本保持一致

### 4.2 描述編輯功能

提供「編輯描述」按鈕，點擊後展開編輯器：

- 使用 `<textarea>` 輸入，支持 Markdown 語法
- 提供簡單的工具欄（可選）：粗體、斜體、列表、代碼
- 即時預覽（可選）：在 textarea 旁邊或下方顯示 Markdown 預覽
- 保存/取消按鈕
- 調用 `PATCH /api/v1/expressions/:id` 更新 `desc` 字段

### 4.3 創建/編輯詞句流程

在現有的創建詞句（CreateExpression）彈窗中新增 `desc` 輸入區：

- 在 `text` 輸入框下方添加「描述（可選）」區域
- 使用 `<textarea>` 輸入 Markdown
- 佔位符提示：「添加描述、例句或用法說明（支持 Markdown）」
- 字數限制提示：最多 1000 字符

### 4.4 ExpressionCard 組件更新

在搜索結果列表和詞句詳情頁的 ExpressionCard 中：

- 如果 expression 有 `desc`，在卡片上顯示描述的摘要（純文本截取前 100 字符）
- 不在列表卡片中渲染 Markdown，僅顯示純文本預覽
- 點擊進入詳情頁查看完整 Markdown 渲染

### 4.5 SmartSearch 搜索結果

搜索結果中的 expression 條目可選顯示 `desc` 摘要，提供更多上下文幫助用戶判斷是否爲目標詞句。

## 5. Markdown 渲染方案

### 5.1 前端渲染方案

`desc` 採用**前端 Markdown 渲染**，原因：
- 內容較短（≤ 1000 字符），前端渲染性能無壓力
- 服務端無需額外處理，存儲原始 Markdown 文本即可
- 渲染靈活，可隨時調整樣式

- 使用 `marked` 庫（輕量，Handbook 前端可能已引入）
- 添加 XSS 防護：使用 `DOMPurify` 對渲染後的 HTML 進行消毒
- 樣式：使用 `prose` class（Tailwind Typography），與 Handbook 風格統一

```vue
<template>
  <div v-if="expression.desc" class="mt-4 p-4 bg-gray-50 rounded-lg">
    <h3 class="text-sm font-medium text-gray-500 mb-2">描述 / 例句</h3>
    <div class="prose prose-sm max-w-none" v-html="renderedDesc"></div>
  </div>
</template>

<script setup>
import { marked } from 'marked'
import DOMPurify from 'dompurify'

const renderedDesc = computed(() => {
  if (!props.expression.desc) return ''
  return DOMPurify.sanitize(marked.parse(props.expression.desc))
})
</script>
```

### 5.2 安全考量

- **XSS 防護**：必須使用 DOMPurify 對渲染後的 HTML 進行消毒
- **輸入限制**：最大 1000 字符，防止存儲過大內容
- **內容審核**：`desc` 服從現有的 `review_status` 審核流程

## 6. 數據庫遷移

### Migration 040: add_expression_desc.sql

```sql
-- Migration 040: 爲 expressions 表新增 desc 字段
-- 用於存儲 Markdown 格式的描述/例句

-- 1. 新增 desc 字段
ALTER TABLE expressions ADD COLUMN desc TEXT DEFAULT NULL;

-- 2. 新增 desc 字段到版本歷史表
ALTER TABLE expression_versions ADD COLUMN desc TEXT DEFAULT NULL;

-- 3. 更新 FTS 索引（可選，是否需要全文搜索 desc 內容）
-- 如果需要支持 desc 內容搜索，需重建 FTS 表
-- ALTER TABLE expressions_fts REBUILD;
```

### 回滾方案

```sql
-- Rollback: 移除 desc 字段
-- SQLite 不支持 DROP COLUMN（需 3.35.0+）
-- 使用重建表方式：
-- 1. 創建不含 desc 的新表
-- 2. 複製數據
-- 3. 刪除舊表
-- 4. 重命名新表
```

## 7. 實現步驟

1. **數據庫遷移**：創建 `scripts/040_add_expression_desc.sql`
2. **後端 Schema 更新**：更新 `protocol.ts`、`expression.ts` 驗證 schema
3. **後端查詢確認**：確保 `ExpressionQueries` 的版本快照包含 `desc` 字段
4. **前端類型更新**：更新 `web/src/types/` 中的 Expression 接口
5. **Detail.vue 描述展示**：在 ExpressionCard 下方新增 Markdown 渲染區域
6. **描述編輯功能**：實現 desc 編輯器（textarea + Markdown 預覽）
7. **創建詞句流程更新**：CreateExpression 彈窗新增 desc 輸入
8. **ExpressionCard 更新**：列表中顯示 desc 摘要
9. **樣式調整**：Markdown 渲染樣式與 Handbook 統一
10. **測試**：功能測試 + XSS 安全測試

## 8. 後續優化（可選）

- **Markdown 工具欄**：提供粗體、斜體、列表、代碼等快捷按鈕
- **即時預覽**：編輯 desc 時提供分屏預覽
- **desc 全文搜索**：將 desc 內容納入 FTS 搜索範圍
- **desc 歷史 diff**：在版本歷史中支持 desc 的差異比較
- **模板系統**：提供常用描述模板（如「例句」、「用法」、「語境」等結構化模板）
