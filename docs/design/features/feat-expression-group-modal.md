# Handbook 詞句組快捷彈窗功能設計

## System Reminder

**設計來源**：用戶需求 - 在 HandbookView 頁面點擊詞句時，彈出一個簡略的詞句詳情框，顯示當前詞句組（meaning group）的所有詞句，並支持快捷添加新詞句到該組，使用表格形式展示（表頭：語言、詞句）。

**實現狀態**：設計階段，待實現

---

## 概述

在閱讀 Handbook（學習手冊）時，用戶經常需要快速查看某個詞句在不同語言下的翻譯版本，或添加新的翻譯版本。當前系統點擊詞句會跳轉到完整的 Detail 頁面，這在快速瀏覽時不夠高效。

本功能設計一個快捷彈窗，提供：
1. **詞句組概覽**：展示該詞句組（meaning group）中所有詞句的翻譯
2. **表格編輯**：以"語言 - 詞句"表格形式展示，支持直接在表格中添加新行
3. **語言範圍限定**：語言選擇器的選項與 Handbook 的學習語言（target_lang）範圍保持一致
4. **無縫交互**：支持關閉彈窗或跳轉到完整詳情頁

## 交互流程

### 1. 點擊詞句觸發彈窗

在 `HandbookView.vue` 中，渲染的詞句元素（`<span class="expression-term">`）點擊時不再直接跳轉，而是：
- 調用新的全局函數 `window.showExpressionGroupModal(expressionId, meaningId)`
- 彈出詞句組詳情彈窗

### 2. 彈窗內容結構

彈窗採用表格編輯形式，每行顯示一個語言的詞句：

```
┌─────────────────────────────────────────────────────────┐
│  [×]  詞句組詳情                            [查看詳情] │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┤
│  │ [+ 添加一行]                                         │
│  ├─────────────┬────────────────────────────────────────┤
│  │ 語言        │ 詞句                    │ 操作        │
│  ├─────────────┼────────────────────────────────────────┤
│  │ English    │ Hello                      │ [×]       │
│  │ 中文（簡體）│ 你好                        │ [×]       │
│  │ 中文（繁體）│ 你好                        │ [×]       │
│  │ 日本語      │ こんにちは                   │ [×]       │
│  │ [+ 新行]   │ [輸入框]        │ [✓] [×]  │            │
│  └─────────────┴────────────────────────────────────────┤
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3. 表格操作

- **關閉彈窗**：點擊右上角 × 或背景區域
- **跳轉詳情**：點擊"查看詳情"按鈕，跳轉到 `/detail/:id` 完整頁面
- **添加新行**：
  - 點擊"+ 添加一行"按鈕，在表格末尾添加一個新的空行
  - 新行包含：語言下拉選擇器、詞句輸入框、確認✓和取消×按鈕
  - 語言選擇器選項限定爲 handbook 的學習語言範圍（與頁面頂部語言選擇器一致）
  - 點擊✓保存，調用後端 API 添加新詞句
  - 點擊×取消，移除新行

### 4. 添加邏輯

當用戶點擊✓保存新行時：
1. 前端驗證：
   - 語言不能爲空
   - 詞句文本不能爲空
   - 該語言在當前詞句組中尚未存在
2. 調用後端 API：
   - 創建新的 expression 記錄
   - 關聯到現有的 meaning_id
3. 成功後刷新表格內容
4. 可選：同時刷新 Handbook 頁面的渲染內容

### 5. 語言範圍限定

**關鍵設計**：語言選擇器的選項必須與當前 Handbook 的學習語言範圍保持一致。

從 `HandbookView.vue` 的 `instructionLanguages` 狀態獲取當前選定的學習語言列表，僅顯示這些語言作爲添加選項。

如果用戶還未選擇任何學習語言，則顯示 Handbook 默認的 `target_lang` 對應的語言。

## 組件設計

### ExpressionGroupModal.vue（新組件）

位於 `web/src/components/ExpressionGroupModal.vue`

#### Props
- `visible`: Boolean - 控制彈窗顯示/隱藏
- `expressionId`: Number - 當前詞句 ID（可選，用於獲取完整詞句信息）
- `meaningId`: Number - 詞句組 ID（核心標識）
- `availableLanguages`: Array - 可用語言列表（從父組件傳入，與 handbook 學習語言一致）
- `instructionLanguages`: Array - 當前選定的學習語言代碼數組

#### Data
- `loading`: Boolean - 加載狀態
- `expressions`: Array - 詞句組中的所有詞句
- `showNewRow`: Boolean - 是否顯示新行
- `newRowLanguage`: String - 新行選擇的語言
- `newRowText`: String - 新行詞句文本
- `adding`: Boolean - 添加操作進行中
- `message`: String - 操作消息（成功/錯誤）

#### Computed
- `displayLanguages` - 計算屬性：從 `availableLanguages` 中過濾，僅返回 `instructionLanguages` 中存在的語言

#### Methods
- `fetchGroupMembers()` - 獲取詞句組所有成員
- `addNewRow()` - 顯示新行（編輯模式）
- `cancelNewRow()` - 取消添加，隱藏新行
- `confirmNewRow()` - 確認添加新詞句
- `close()` - 關閉彈窗
- `goToDetail()` - 跳轉到詳情頁

#### Events
- `close` - 關閉彈窗時觸發
- `updated` - 成功添加翻譯後觸發（可觸發父組件刷新渲染）

### HandbookView.vue 修改

#### Template
添加組件引用：

```vue
<ExpressionGroupModal
  :visible="showExpressionGroupModal"
  :expression-id="selectedExpressionId"
  :meaning-id="selectedMeaningId"
  :available-languages="languages"
  :instruction-languages="instructionLanguages"
  @close="showExpressionGroupModal = false"
  @updated="handleExpressionGroupUpdated"
/>
```

#### Script
添加狀態和方法：

```javascript
// State
const showExpressionGroupModal = ref(false)
const selectedExpressionId = ref(null)
const selectedMeaningId = ref(null)

// 全局函數
window.showExpressionGroupModal = (expressionId, meaningId) => {
  selectedExpressionId.value = expressionId
  selectedMeaningId.value = meaningId
  showExpressionGroupModal.value = true
}

// 處理更新事件
const handleExpressionGroupUpdated = () => {
  // 刷新 handbook 內容以顯示新翻譯
  fetchInitialData()
}
```

#### 傳遞 languages 和 instructionLanguages

在 `return` 中暴露給組件：

```javascript
return {
  // ... other exports
  languages,
  instructionLanguages
}
```

## 後端 API 需求

現有 API 已經支持所需功能，無需修改：

1. **獲取詞句組成員**：
   - `GET /api/v1/expressions?meaning_id={meaningId}`
   - 返回詞句組中所有詞句

2. **添加新詞句**：
   - `POST /api/v1/expressions`
   - Body: `{ text, language_code, meaning_id }`

## 數據結構

### 詞句組響應示例

```json
[
  {
    "id": 123,
    "text": "Hello",
    "language_code": "en",
    "region_name": null,
    "audio_url": null,
    "meaning_id": 456
  },
  {
    "id": 124,
    "text": "你好",
    "language_code": "zh-CN",
    "region_name": null,
    "audio_url": null,
    "meaning_id": 456
  }
]
```

### 添加詞句請求示例

```json
{
  "text": "Bonjour",
  "language_code": "fr",
  "meaning_id": 456
}
```

## 國際化支持

需要添加以下翻譯鍵到所有 locale 文件：

| 鍵名 | 描述 | 示例（中文） |
|-----|------|------------|
| `expression_group_details` | 彈窗標題 | 詞句組詳情 |
| `more` | 更多按鈕 | 更多 |
| `add_row` | 添加一行按鈕 | 添加一行 |
| `cancel` | 取消按鈕 | 取消 |
| `confirm` | 確認按鈕 | 確認 |
| `language` | 表頭：語言 | 語言 |
| `expression` | 表頭：詞句 | 詞句 |
| `language_already_exists` | 語言已存在錯誤 | 該語言已存在 |
| `translation_added_successfully` | 添加成功消息 | 添加成功 |
| `please_select_language` | 選擇語言提示 | 請選擇語言 |
| `please_enter_expression` | 輸入詞句提示 | 請輸入詞句 |

## 樣式設計

### 彈窗容器
- 最大寬度：600px
- 最大高度：80vh
- 圓角：12px
- 陰影：中等
- 背景：白色

### 表格樣式
- 表頭：淺灰色背景，加粗文字
- 行：底部邊框分隔
- 操作列：固定寬度 80px
- 語言列：寬度 30%
- 詞句列：寬度 50%（剩餘空間）

### 新行樣式
- 背景：淺藍色高亮
- 語言選擇器：下拉框樣式
- 輸入框：邊框樣式
- 按鈕：✓ 綠色確認，× 灰色取消

### 按鈕樣式
- 添加一行：虛線邊框，+ 圖標，hover 時高亮
- 刪除：× 圖標，hover 時紅色
- 查看詳情：藍色按鈕

## 實施計劃

### Phase 1: 基礎彈窗
- [ ] 創建 `ExpressionGroupModal.vue` 組件
- [ ] 實現彈窗基礎樣式和布局
- [ ] 集成到 `HandbookView.vue`
- [ ] 修改 `window.navigateToExpression` 爲 `window.showExpressionGroupModal`
- [ ] 傳遞 `languages` 和 `instructionLanguages` 到組件

### Phase 2: 表格展示
- [ ] 實現 `fetchGroupMembers()` 方法
- [ ] 實現表格展示邏輯
- [ ] 添加加載狀態處理
- [ ] 實現關閉和跳轉詳情功能
- [ ] 實現刪除按鈕 UI（暫不實現功能）

### Phase 3: 表格編輯添加功能
- [ ] 實現"+ 添加一行"按鈕
- [ ] 實現新行 UI（語言選擇器 + 輸入框 + 確認/取消按鈕）
- [ ] 實現 `displayLanguages` 計算屬性（過濾到 instructionLanguages）
- [ ] 實現添加翻譯表單驗證
- [ ] 實現後端 API 調用
- [ ] 實現成功後刷新邏輯

### Phase 4: 國際化與優化
- [ ] 添加所有翻譯鍵到 10 個 locale 文件
- [ ] 優化響應式布局（移動端適配）
- [ ] 添加錯誤處理和用戶反饋
- [ ] 測試邊界情況

### Phase 5: 測試與文檔
- [ ] 單元測試
- [ ] 集成測試
- [ ] 用戶驗收測試

## 相關文檔

- [feat-handbook.md](feat-handbook.md) - Handbook 功能基礎設計
- [feat-meaning-mapping.md](feat-meaning-mapping.md) - 詞句與語義多對多關係
- [feat-ui-translation.md](feat-ui-translation.md) - UI 翻譯系統

## 實現檢查清單

- [ ] 組件 `ExpressionGroupModal.vue` 創建完成
- [ ] 彈窗樣式符合設計稿
- [ ] 表格展示詞句組所有成員
- [ ] "+ 添加一行"按鈕功能正常
- [ ] 新行語言選擇器選項正確限定（與 instructionLanguages 一致）
- [ ] 添加翻譯功能正常工作
- [ ] 國際化翻譯完整（所有 10 個語言）
- [ ] 移動端響應式正常
- [ ] 錯誤處理完善
- [ ] 後端 API 調用正確
- [ ] 成功後刷新邏輯正確

## 注意事項

1. **權限控制**：添加翻譯需要用戶登錄，未登錄用戶應提示登錄
2. **語言限定**：**關鍵** - 語言選擇器必須只能選擇 handbook 當前的學習語言範圍
3. **緩存處理**：Handbook 的渲染內容有 24 小時緩存，添加新翻譯後需要決定是否刷新緩存
4. **邊界情況**：
   - 學習語言列表爲空（應顯示默認語言或提示）
   - 所有學習語言都已有翻譯（應禁用添加按鈕或提示）
   - 網絡請求失敗
   - 後端驗證失敗
   - 用戶未登錄

5. **可訪問性**：
   - 彈窗支持 ESC 關閉
   - 支持焦點管理
   - 支持鍵盤導航

## 未來擴展

- 支持直接在表格中編輯現有翻譯
- 支持直接在表格中刪除翻譯（需要權限檢查）
- 支持播放錄音（如果有）
- 支持批量導入翻譯
