# Handbook 多頁手冊功能設計

## System Reminder

**設計來源**：用戶希望在現有單頁 Handbook 基礎上，支持多頁手冊功能。用戶可手動創建和管理 Page，每個 Page 有獨立標題和 Markdown 內容，類似 Notion 子頁面。頁面間通過側邊欄 TOC 導航。

**實現狀態**：⏸️ 待實現

**兼容策略**：新老數據並存。現有單頁 handbook 保持不變（使用 `handbooks.content`），新創建的多頁 handbook 僅使用 `handbook_pages` 表存儲內容。

---

## 概述

現有 handbook 是單一 Markdown 內容，所有正文存在 `handbooks.content` 字段中。多頁功能引入 `handbook_pages` 表，允許一個 handbook 包含多個獨立的 page。

**核心原則**：
- 每個 page 是獨立的可編輯單元，擁有自己的標題、內容
- page 的排序由用戶通過拖拽決定，通過 `sort_order` 字段持久化
- 閱讀頁側邊欄 TOC 顯示所有 page 標題，點擊切換
- 現有單頁 handbook 完全不受影響，無需數據遷移

---

## 數據庫設計

### 1. handbook_pages 表（新增）

```sql
CREATE TABLE IF NOT EXISTS handbook_pages (
    id INTEGER PRIMARY KEY NOT NULL,
    handbook_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL DEFAULT '',
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (handbook_id) REFERENCES handbooks(id) ON DELETE CASCADE
);
```

| Column | Type | Description |
|---|---|---|
| `id` | INTEGER | FNV-1a hash（`handbook_id\|title\|timestamp`），與 handbook ID 生成規則一致 |
| `handbook_id` | INTEGER | 所屬 handbook，FK → handbooks(id)，級聯刪除 |
| `title` | TEXT | 頁面標題（用於 TOC 顯示） |
| `content` | TEXT | 頁面 Markdown 內容，支持 `{{...}}` 表達式語法 |
| `sort_order` | INTEGER | 排序序號，越小越靠前，支持拖拽重排序 |
| `created_at` | TEXT | 創建時間 |
| `updated_at` | TEXT | 更新時間 |

### 2. 索引

```sql
CREATE INDEX idx_handbook_pages_handbook_id ON handbook_pages(handbook_id);
CREATE INDEX idx_handbook_pages_handbook_sort ON handbook_pages(handbook_id, sort_order);
```

### 3. handbook_pages_renders 列（新增）

在 `handbook_pages` 表上增加渲染緩存列，與 `handbooks` 表的 `renders` 列設計保持一致：

```sql
ALTER TABLE handbook_pages ADD COLUMN renders TEXT DEFAULT NULL;
```

`renders` 的 JSON 結構與 handbooks 一致：

```json
{
  "zh-TW|nan-TW": {
    "rendered_title": "...",
    "rendered_content": "...",
    "at": "2026-04-09T12:00:00Z"
  }
}
```

### 4. handbooks 表新增字段

```sql
ALTER TABLE handbooks ADD COLUMN author TEXT DEFAULT NULL;
ALTER TABLE handbooks ADD COLUMN published_at TEXT DEFAULT NULL;
ALTER TABLE handbooks ADD COLUMN has_pages INTEGER NOT NULL DEFAULT 0;
```

| Column | Type | Description |
|---|---|---|
| `author` | TEXT | 原書作者。用於舊書電子化場景（如「林連祥」），區別於 `user_id`（上傳/創建者） |
| `published_at` | TEXT | 原書出版時間，格式為 ISO 8601 日期（如 `1992-06-01`，不帶時區）。區別於 `created_at`（系統記錄創建時間） |
| `has_pages` | INTEGER | `0` = 單頁 handbook（使用 `handbooks.content`），`1` = 多頁 handbook（使用 `handbook_pages` 表）。性能優化字段，也可通過查詢 `handbook_pages` 表是否存在記錄來判斷 |

**`author` vs `user_id` 區別**：
- `user_id`：在 LangMap 系統中創建/上傳該 handbook 的**用戶**，用於權限控制
- `author`：原始內容的**作者/著作權人**，用於展示和歸屬標注
- 兩者可能不同（例如用戶 A 電子化並上傳了作者 B 的著作）

**`published_at` vs `created_at` 區別**：
- `created_at`：該 handbook 在 LangMap 系統中創建的時間
- `published_at`：原始書籍的出版年份/日期，用於展示和排序

---

## TypeScript 接口設計

### Backend (`protocol.ts`)

```typescript
export interface HandbookPage {
  id: number
  handbook_id: number
  title: string
  content: string
  sort_order: number
  created_at: string
  updated_at: string
  renders?: string // JSON string for cached renders
}
```

### Frontend (`web/src/api/handbooks.ts`)

```typescript
export interface HandbookPage {
  id: number
  handbook_id: number
  title: string
  content: string
  sort_order: number
  created_at: string
  updated_at?: string
  rendered_content?: string
}

export interface CreateHandbookPageData {
  title: string
  content?: string
  sort_order?: number
}

export interface UpdateHandbookPageData {
  title?: string
  content?: string
  sort_order?: number
}
```

### Handbook 接口擴展

```typescript
export interface Handbook {
  // ... 現有字段不變
  author?: string          // 原書作者
  published_at?: string    // 原書出版時間 (ISO date, e.g. '1992-06-01')
  has_pages?: number       // 0 或 1，是否為多頁手冊
  pages?: HandbookPage[]   // 多頁模式下列出所有 page
  page_count?: number      // 頁面總數（列表展示用）
}
```

#### Frontend Handbook 接口擴展

```typescript
export interface Handbook {
  // ... 現有字段不變
  author?: string
  published_at?: string
  has_pages?: number
  page_count?: number
}

export interface CreateHandbookData {
  // ... 現有字段不變
  author?: string
  published_at?: string
}

export interface UpdateHandbookData {
  // ... 現有字段不變
  author?: string
  published_at?: string
}
```

---

## 後端 API 設計

### 新增 Page 管理端點

基礎路徑：`/api/v1/handbooks/:handbookId/pages`

所有寫操作需 `requireAuth`，且驗證當前用戶為 handbook 的 owner。

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/v1/handbooks/:handbookId/pages` | Optional | 獲取手冊的所有 page，按 `sort_order` 排序。公開手冊允許未登錄訪問。 |
| GET | `/api/v1/handbooks/:handbookId/pages/:pageId/:target_lang?` | Optional | 獲取單個 page 詳情。若提供 `target_lang`，觸發渲染管道。 |
| POST | `/api/v1/handbooks/:handbookId/pages` | Required | 創建 page。Body: `title`, `content`, `sort_order`。同時將 handbook 的 `has_pages` 設為 1。 |
| PUT | `/api/v1/handbooks/:handbookId/pages/:pageId` | Required | 更新 page（標題、內容、排序）。清除該 page 的 render 緩存。 |
| PUT | `/api/v1/handbooks/:handbookId/pages/reorder` | Required | 批量重排序。Body: `{ pages: [{ id, sort_order }] }`。 |
| DELETE | `/api/v1/handbooks/:handbookId/pages/:pageId` | Required | 刪除 page。若刪除後無 page 殘留，將 handbook 的 `has_pages` 設回 0。 |
| POST | `/api/v1/handbooks/:handbookId/pages/:pageId/rerender` | Required | 清除 page 的 render 緩存。 |
| POST | `/api/v1/handbooks/:handbookId/pages/preview` | Required | 預覽 page 渲染（不保存）。Body: `content`, `title`, `source_lang`, `target_lang`。 |

### 現有 API 調整

| 端點 | 調整 |
|---|---|
| `GET /api/v1/handbooks` | 返回結果增加 `has_pages` 和 `page_count` 字段 |
| `GET /api/v1/handbooks/:id` | 返回結果增加 `has_pages`，若為多頁則同時返回 `pages` 列表（不含 content，僅 `id`, `title`, `sort_order`） |
| `DELETE /api/v1/handbooks/:id` | 級聯刪除所有關聯 page（由 FK ON DELETE CASCADE 保證） |

---

## Database Service 方法 (`protocol.ts`)

```typescript
// Handbook Pages
abstract getHandbookPages(handbookId: number): Promise<HandbookPage[]>
abstract getHandbookPageById(id: number): Promise<HandbookPage | null>
abstract getHandbookPageSummaries(handbookId: number): Promise<Pick<HandbookPage, 'id' | 'title' | 'sort_order'>[]>
abstract createHandbookPage(page: Partial<HandbookPage>): Promise<HandbookPage>
abstract updateHandbookPage(id: number, page: Partial<HandbookPage>): Promise<HandbookPage>
abstract deleteHandbookPage(id: number): Promise<boolean>
abstract reorderHandbookPages(pages: Array<{ id: number; sort_order: number }>): Promise<void>

// Handbook Page Renders
abstract getHandbookPageRender(id: number, targetLang: string): Promise<any | null>
abstract saveHandbookPageRender(renderData: {
  page_id: number;
  target_lang: string;
  rendered_title: string;
  rendered_content: string;
}): Promise<void>
abstract invalidateHandbookPageRenders(id: number): Promise<void>
```

---

## 前端設計

### 1. 路由變更

新增 page 級別路由：

| Route | Component | Auth | Description |
|---|---|---|---|
| `/handbooks/:id` | `HandbookView` | No | 單頁 handbook 閱讀（現有行為不變） |
| `/handbooks/:id/pages/:pageId` | `HandbookView` | No | 多頁 handbook 的 page 閱讀（復用 HandbookView，通過 `has_pages` 區分） |
| `/handbooks/:id/pages/:pageId/edit` | `HandbookPageEdit` | Yes | 編輯單個 page |
| `/handbooks/:id/pages/new` | `HandbookPageEdit` | Yes | 創建新 page |

### 2. HandbookList.vue 調整

- 列表項增加作者和出版時間展示（若存在）
- 列表項增加頁面數量徽章（如「3 pages」）
- 多頁 handbook 點擊後直接跳轉到第一個 page（`/handbooks/:id/pages/:firstPageId`）
- 單頁 handbook 保持現有行為（跳轉到 `/handbooks/:id`）

列表卡片展示示例：
```
┌──────────────────────────────┐
│  手冊標題                    │
│  作者：林連祥 · 1992 年出版   │
│  語言：台語 → 華語、客語      │
│  3 頁 · 公開                 │
└──────────────────────────────┘
```

### 3. HandbookView.vue 調整（多頁模式）

當 `handbook.has_pages === 1` 時進入多頁模式：

```
┌──────────────────────────────────────────────────┐
│  Header                                          │
│  ┌────────────────────────────────────────────┐  │
│  │  手冊標題                                   │  │
│  │  作者：林連祥 · 1992 年出版                  │  │
│  │  由 username 上傳 · 語言切換器              │  │
│  └────────────────────────────────────────────┘  │
├─────────────┬────────────────────────────────────┤
│   Sidebar   │  Content                           │
│   TOC       │                                    │
│             │  # Page Title                      │
│  + Add Page │                                    │
│  ─────────  │  Page content rendered here...     │
│  Page 1 ◄── │                                    │
│  Page 2     │                                    │
│  Page 3     │                                    │
│             │                                    │
│             │  ◀ Prev    Page 2/3    Next ▶      │
└─────────────┴────────────────────────────────────┘
```

**側邊欄 TOC 行為**：
- 顯示所有 page 標題，當前 page 高亮
- Owner 可見「+ 新增頁面」按鈕
- Owner 可拖拽重排序（或通過上下箭頭按鈕）
- Owner 可右鍵/點擊「...」菜單：重命名、刪除
- 現有的自動解析標題 TOC 功能保留為**頁內 TOC**（可摺疊顯示在頁面內容區頂部或側邊欄下方）

**Page 間導航**：
- 底部顯示「上一頁 / 下一頁」快速切換
- 側邊欄點擊直接跳轉
- URL 直接記錄當前 page（支持分享特定頁面鏈接）

**渲染邏輯**：
- 每個 page 獨立渲染，與現有 handbook 渲染管道一致
- page 的 `source_lang` 和 `target_lang` 繼承自所屬 handbook
- render 緩存獨立存儲在 `handbook_pages.renders` 列中

### 4. HandbookPageEdit.vue（新增）

編輯單個 page 的頁面，與現有 `HandbookEdit.vue` 共享大部分邏輯：

- 複用現有的 Markdown 編輯器（`md-editor-v3`）及工具欄
- 複用表達式搜索/插入功能
- 複用預覽功能
- 頁面頂部顯示所屬 handbook 標題 + 麵包屑導航
- 僅編輯 page 的 `title` 和 `content`，語言設置由 handbook 管理

### 5. HandbookEdit.vue 調整

編輯 handbook 元信息時，擴展表單字段：

- 現有標題和描述字段下方增加：
  - **作者**：文本輸入框（optional），用於填寫原書作者
  - **出版時間**：日期選擇器（optional），用於填寫原書出版日期
- 增加「頁面管理」標籤頁
- 顯示所有 page 列表，支持添加、刪除、重排序

---

## 單頁 vs 多頁的判斷邏輯

```typescript
// 前端判斷
const isMultiPage = computed(() => handbook.value?.has_pages === 1)

// 後端 GET /api/v1/handbooks/:id 返回邏輯
// 若 has_pages === 1，content 字段返回 null 或空字符串
// 若 has_pages === 0，pages 字段返回空數組
```

**規則**：
- `has_pages = 0`：使用 `handbooks.content`，`handbook_pages` 中無記錄
- `has_pages = 1`：使用 `handbook_pages` 表，`handbooks.content` 不再使用（但不刪除歷史數據）
- 一旦切換為多頁模式，不可回退為單頁模式

---

## 渲染管道擴展

現有渲染管道用於 handbook 的 title/description/content，多頁模式下：

1. page 的 `source_lang` 和 `target_lang` 從所屬 handbook 繼承
2. page 的表達式提取和解析邏輯與 handbook 完全一致
3. page 的 render 緩存存儲在 `handbook_pages.renders` JSON 列中
4. page 的 `lang_colors` 也從 handbook 繼承（不需要在 page 上存儲）

```typescript
// 渲染 page 時的數據流
const handbook = await getHandbookById(handbookId)
const page = await getHandbookPageById(pageId)
const sourceLang = handbook.source_lang
const targetLang = targetLangParam || handbook.target_lang
const langColors = handbook.lang_colors

// 複用現有 renderHandbookContent() 函數
const rendered = await renderHandbookContent({
  title: page.title,
  content: page.content,
  source_lang: sourceLang,
  target_lang: targetLang,
  lang_colors: langColors
})
```

---

## 國際化

```json
{
  "pages": "頁面",
  "add_page": "新增頁面",
  "edit_page": "編輯頁面",
  "delete_page": "刪除頁面",
  "rename_page": "重命名頁面",
  "reorder_pages": "重新排序",
  "page_count": "{count} 頁",
  "prev_page": "上一頁",
  "next_page": "下一頁",
  "page_not_found": "頁面不存在",
  "confirm_delete_page": "確定要刪除此頁面嗎？",
  "enable_multipage": "啟用多頁模式",
  "page_of_total": "第 {current} 頁，共 {total} 頁",
  "author": "作者",
  "author_placeholder": "原作者姓名",
  "published_at": "出版時間",
  "published_at_placeholder": "原書出版日期",
  "uploaded_by": "由 {user} 上傳",
  "published_year": "{year} 年出版"
}
```

---

## 開發計劃

### Phase 1: Database & Backend

1. `043_handbook_pages.sql`：建表 + 索引 + `has_pages`、`author`、`published_at` 列
2. `protocol.ts`：新增 `HandbookPage` 接口及 abstract 方法，`Handbook` 接口增加 `author`、`published_at`
3. `d1.ts`：實現所有 handbook page CRUD 及 render 方法，handbook CRUD 透傳新字段
4. `handbooks.ts` 路由：新增 page 管理端點，調整現有端點返回值

### Phase 2: Frontend - View & Navigation

1. `HandbookView.vue`：Header 展示 author + published_at；多頁模式側邊欄 TOC + 頁面切換
2. 路由更新：新增 `/handbooks/:id/pages/:pageId` 路由
3. `HandbookList.vue`：增加 author、published_at、page 數量展示

### Phase 3: Frontend - Edit & Management

1. `HandbookPageEdit.vue`：新 page 編輯器
2. `HandbookEdit.vue`：增加 author / published_at 輸入字段 + 頁面管理面板
3. 拖拽排序、新增/刪除 page 交互

### Phase 4: Rendering & Polish

1. 後端 page 渲染管道
2. Render 緩存
3. 國際化
4. 測試與邊界情況處理

---

## 注意事項

1. **不遷移舊數據**：現有 handbook 的 `content` 始終保留，`has_pages` 默認為 0
2. **不可逆轉**：一旦 handbook 啟用多頁模式，不支持回退為單頁
3. **級聯刪除**：刪除 handbook 時，FK `ON DELETE CASCADE` 自動清理所有 page
4. **權限**：page 的 CRUD 權限繼承自 handbook 的 owner
5. **排序並發**：`reorder` 端點使用事務確保原子性
6. **表達式關聯**：page 的 expression 搜索仍使用 handbook 的 `source_lang`，與現有邏輯一致
7. **渲染性能**：每個 page 獨立緩存，切換 page 時不需要重新渲染所有頁面
