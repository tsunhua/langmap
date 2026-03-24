# Handbook (學習手冊) 功能設計

## System Reminder

**設計來源**：根據用戶需求（基於 Markdown 編輯並支持動態切換語言渲染相關詞句的手冊）設計。

**實現狀態**：
- ✅ 數據庫模型（handbooks 表，含 `source_lang`、`target_lang`） - 已實現
- ✅ 後端 API 基礎實現（CRUD，含語言字段透傳） - 已實現
- ✅ 前端 Markdown 編輯器（工具欄、格式化控件、Undo/Redo） - 已實現
- ✅ 編輯器語言設置（編寫語言 / 學習語言 選擇器） - 已實現
- ✅ 詞條搜索按 source_lang 過濾 - 已實現
- ✅ 編輯器預覽：按 target_lang 拉取翻譯，括號備註顯示 - 已實現
- ✅ Markdown 閱讀頁動態渲染詞句，默認使用 handbook.target_lang - 已實現

---

## 概述

Handbook（學習手冊）功能允許用戶使用 LangMap 中的詞句構建結構化的學習內容或筆記。
用戶可以通過基於 Markdown 的編輯器編寫手冊，並在其中嵌入 LangMap 的詞句（使用特定語法關聯其 `meaning_id` 或 `expression_id`）。

編輯手冊時，需要指定：
- **編寫語言 (`source_lang`)**：手冊內容所用的語言，用於過濾詞條搜索結果。
- **學習語言 (`target_lang`)**：預覽和閱讀時的默認目標語言。

在閱讀手冊時，系統會自動使用手冊的 `target_lang` 作爲初始語言，用戶也可以手動切換，系統會即時重新拉取對應語言的詞彙並更新渲染。

## 數據庫設計 (Database Schema)

### 1. handbooks 表

存儲學習手冊的基本信息和 Markdown 格式的正文內容。

```sql
CREATE TABLE IF NOT EXISTS handbooks (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER NOT NULL,          -- 創建者ID，關聯 users.id
    title TEXT NOT NULL,               -- 手冊標題
    description TEXT,                  -- 手冊簡介/描述
    content TEXT NOT NULL,             -- Markdown 格式的正文內容
    source_lang TEXT,                   -- 手冊編寫語言 (e.g., 'en', 'zh-CN')
    target_lang TEXT,                   -- 目標學習語言 (e.g., 'zh-TW', 'nan-TW')
    is_public INTEGER DEFAULT 0,       -- 是否公開 (0: 私有, 1: 公開)
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

### 2. 索引設計

- `CREATE INDEX idx_handbooks_user_id ON handbooks(user_id);`
- `CREATE INDEX idx_handbooks_is_public_created ON handbooks(is_public, created_at DESC);`
- `CREATE INDEX idx_handbooks_user_created ON handbooks(user_id, created_at DESC);`

## 後端接口設計 (API Design)

### 1. 詞句表達式查詢 API 增強

- **GET `/api/v1/expressions`**：`meaning_id` 支持逗號分隔的多值查詢（`?meaning_id=123,456`），用於批量獲取手冊中引用的所有詞句。

### 2. 手冊管理 API (Handbooks CRUD)

所有寫請求及查看私人手冊均需通過 `requireAuth` 中間件驗證用戶身份。

| Method | Path | 說明 |
|--------|------|------|
| GET | `/api/v1/handbooks` | 獲取列表（支持 `user_id`, `is_public`, `skip`, `limit` 篩選） |
| POST | `/api/v1/handbooks` | 創建手冊（Body: `title`, `content`, `description`, `source_lang`, `target_lang`, `is_public`）|
| GET | `/api/v1/handbooks/:id` | 獲取詳情（非公開則校驗用戶） |
| PUT | `/api/v1/handbooks/:id` | 更新手冊 |
| DELETE | `/api/v1/handbooks/:id` | 刪除手冊 |

## 前端交互與渲染設計 (Frontend Design)

### 1. Markdown 詞句嵌入語法

```markdown
點擊以下詞彙可試聽錄音：{{exp:123|mid:456|text:測試文本|audio:https://...}}
```

字段含義：
- **`exp`**: 原始詞句 ID（用於溯源）
- **`mid`**: 語義 ID（動態切換語言的核心 Key）
- **`text`**: 原始文本（即使離線也能保持內容可讀）
- **`audio`**: 原始錄音 URL（降級時可用）

### 2. 編輯器交互 (`HandbookEdit.vue`)

- **語言設置面板**：編輯器頂部提供兩個下拉選擇器：
  - **編寫語言 (`source_lang`)**：選擇後，工具欄內的詞條搜索框將自動過濾，僅返回對應語言的結果。
  - **學習語言 (`target_lang`)**：選擇後，預覽模式下的詞條將以目標語言進行渲染。

- **格式工具欄**：包含加粗、斜體、下劃線、刪除線、H1-H3、列表、引用、代碼等按鈕，以及 Undo / Redo。

- **詞條搜索插入**：工具欄內集成搜索框，按 `source_lang` 過濾詞條，選中後自動插入完整的 `{{exp:...}}` 語法。

- **預覽模式（含翻譯）**：
  - 點擊 "Preview" 時自動掃描內容中所有 `mid`
  - 按 `target_lang` 調用 `/api/v1/expressions` 批量獲取翻譯
  - 詞條以 **`原文 [譯文]`** 格式展示，支持點擊播放音頻
  - 翻譯結果按 `mid` 緩存，避免重複請求
  - 若無對應翻譯，降級顯示原始 `text` 和 `audio`

### 3. 閱讀器與動態渲染 (`HandbookView.vue`)

- **初始語言**：默認使用手冊本身的 `target_lang`，若未設置則回退至 localStorage 中的用戶偏好。
- **語言切換器**：頁面頂部提供語言下拉框，切換後立即重新請求翻譯並重新生成。
- **渲染邏輯**：
  - 掃描 Markdown 內所有 `mid`，批量請求對應語言的詞句
  - 已翻譯詞條高亮顯示、支持點擊播放錄音
  - 無翻譯的詞條以灰色降級展示，標註 "fallback"

### 4. 路由與頁面入口

- **`/handbooks`**：公開手冊大廳 + "我的手冊"選項卡
- **`/handbooks/edit/:id?`**：新建 / 編輯手冊界面
- **`/handbooks/:id`**：手冊閱讀頁面

## 開發計劃 (Implementation Steps)

1. **Database**:
   - `024_handbook_table.sql` 建表，含 `source_lang`、`target_lang` 字段。✅
   - `protocol.ts` 添加 `Handbook` 接口（含語言字段）。✅
   - `d1.ts` 實現 CRUD，透傳語言字段。✅
2. **Backend API**:
   - `/api/v1/handbooks` CRUD 路由。✅
   - `GET /expressions` 支持 `meaning_id` 逗號數組查詢。✅
3. **Frontend Markdown 解析**:
   - `handbookService.js` 封裝接口，含 `getHandbookExpressions`。✅
   - 實現 `mid` 正則提取與翻譯批量請求。✅
4. **Frontend UI**:
   - `HandbookEdit.vue`：語言選擇器、格式工具欄、Undo/Redo、語言過濾搜索、帶翻譯的預覽。✅
   - `HandbookView.vue`：默認 `target_lang`、動態切換渲染、降級處理。✅
   - `en-US.json` 和 `zh-CN.json` 國際化。✅
