# 詞句組合併功能設計文檔

## 1. 概述與用戶流程

### 功能目標
允許用戶在詳情頁將一個詞句組合併到另一個詞句組，簡化詞句組管理，避免重複或相似的含義組。

### 用戶場景
- 用戶發現兩個詞句組表達的含義相似，想要合併它們
- 用戶希望減少詞句組數量，使管理更加簡潔
- 用戶誤創建了多個詞句組，需要合併修正

### 操作流程
1. 用戶在詳情頁看到當前詞句所屬的多個詞句組標籤
2. 在詞句組標籤頁的成員數量顯示區域旁邊點擊「合併」按鈕
3. 彈出模態框，顯示該詞句所屬的其他詞句組列表
4. 用戶選擇要合併到的目標詞句組
5. 系統執行合併，將源詞句組中的所有詞句添加到目標詞句組，然後刪除源詞句組
6. 頁面自動刷新，顯示合併後的詞句組列表

## 2. 界面設計

### 2.1 詞句組內部布局

在詞句組內部的成員數量顯示區域旁邊添加合併按鈕（Detail.vue 第 57-60 行）：

```vue
<div class="border-b border-slate-200 px-3 sm:px-6 py-3 sm:py-4 flex ...">
  <span class="text-slate-600 text-sm sm:text-base">{{ currentMembers.length }} {{ $t('expressions') }}</span>

  <!-- 新增：合併按鈕 -->
  <button @click="openMergeGroupsModal()" class="ml-2 text-slate-400 hover:text-blue-600 transition-colors" :title="$t('merge_groups')">
    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
    </svg>
  </button>

  <button @click="toggleGroupSearch(...)">...</button>
</div>
```

合併按鈕使用淺色圖標，hover 時變爲藍色，保持低調但可見。

### 2.2 詞句組合併模態框

模態框布局：
- **標題**：「合併詞句組」
- **描述**：「選擇要將當前詞句組合併到的目標詞句組。此操作無法撤銷。」
- **詞句組列表**：顯示當前詞句所屬的所有其他詞句組（排除當前標籤頁的詞句組）
  - 每個詞句組卡片顯示：
    - 詞句組標籤號（如 #1）
    - 詞句數量（如「5 個詞句」）
    - 前 3 個詞句的文本（用 " / " 分隔）
    - 創建者信息
  - 點擊卡片直接執行合併操作
- **底部操作欄**：
  - 「取消」按鈕

## 3. 數據流程

### 3.1 合併操作流程

1. **用戶點擊合併按鈕**（在詞句組內部）
   - 調用 `openMergeGroupsModal()` 函數
   - 設置 `showMergeGroupsModal = true`
   - 設置 `sourceMeaningId = currentMeaning.id`
   - 加載其他詞句組列表（通過 `meanings.value` 過濾，排除當前詞句組）

2. **用戶選擇目標詞句組**
   - 調用 `mergeMeaningGroups(targetMeaningId)` 函數
   - 傳遞源詞句組 ID 和目標詞句組 ID

3. **執行合併操作**（前端）
   - 發送 POST 請求到 `/api/v1/meanings/merge`
   - 請求體：
     ```json
     {
       "source_meaning_id": "源詞句組ID",
       "target_meaning_id": "目標詞句組ID"
     }
     ```

4. **後端處理合併邏輯**（使用批量操作）
   - 驗證用戶權限
   - 使用事務或批量操作：
     1. **批量插入**新的 expression_meaning 關聯：
        ```sql
        INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at)
        VALUES (?, ?, ?, ?)
        ```
        對源詞句組的每個詞句執行
     2. **批量刪除**源詞句組的 expression_meaning 記錄：
        ```sql
        DELETE FROM expression_meaning WHERE meaning_id = ?
        ```
     3. **刪除**源詞句組記錄：
        ```sql
        DELETE FROM meanings WHERE id = ?
        ```
   - 所有操作在一個事務中執行，確保原子性
   - 返回合併結果

5. **前端刷新顯示**
   - 重新加載詞句組列表
   - 自動切換到目標詞句組標籤頁

**性能優化點**：
- 使用 D1 的 `batch()` 方法一次性執行所有 SQL 語句
- 使用 `INSERT OR IGNORE` 避免重複插入
- 單次數據庫往返完成所有操作

## 4. 錯誤處理

### 4.1 前端錯誤處理

**場景 1：權限不足**
- 後端返回 401 或 403 狀態碼
- 前端顯示提示：「您沒有權限執行此操作」
- 不關閉模態框，允許用戶重新登錄後重試

**場景 2：詞句組不存在**
- 後端返回 404 狀態碼
- 前端顯示提示：「詞句組不存在，請重新整理頁面」
- 關閉模態框，刷新數據

**場景 3：合併到同一個詞句組**
- 前端驗證：源詞句組 ID 不等於目標詞句組 ID
- 如果相等，不發送請求，顯示提示：「不能合併到同一個詞句組」

**場景 4：網絡錯誤**
- 捕獲 fetch 錯誤
- 顯示提示：「網絡錯誤，請稍後再試」
- 不關閉模態框，允許用戶重試

### 4.2 後端錯誤處理

**驗證失敗**：
- 源詞句組 ID 或目標詞句組 ID 不存在：返回 404
- 用戶無權限修改詞句組：返回 403

**數據庫錯誤**：
- 事務執行失敗：返回 500，包含錯誤詳情
- 記錄錯誤日誌便於排查

**並發衝突**：
- 使用數據庫鎖或事務隔離級別處理並發合併請求
- 如果檢測到衝突，返回 409 Conflict

## 5. 後端 API 設計

### 5.1 API 端點

```
POST /api/v1/meanings/merge
```

### 5.2 請求格式

```json
{
  "source_meaning_id": 123,
  "target_meaning_id": 456
}
```

### 5.3 響應格式

**成功響應（200）**：
```json
{
  "success": true,
  "message": "詞句組合併成功",
  "merged_count": 5,
  "target_meaning_id": 456
}
```

**錯誤響應**：

```json
// 403 Forbidden
{
  "error": "您沒有權限執行此操作"
}

// 404 Not Found
{
  "error": "詞句組不存在"
}

// 500 Internal Server Error
{
  "error": "合併失敗",
  "details": "具體錯誤信息"
}
```

### 5.4 數據庫操作（僞代碼）

```typescript
async mergeMeaningGroups(sourceMeaningId: number, targetMeaningId: number, username: string) {
  const db = this.db;

  // 1. 驗證詞句組存在
  const sourceMeaning = await db.prepare('SELECT * FROM meanings WHERE id = ?').bind(sourceMeaningId).first();
  const targetMeaning = await db.prepare('SELECT * FROM meanings WHERE id = ?').bind(targetMeaningId).first();

  if (!sourceMeaning || !targetMeaning) {
    throw new Error('詞句組不存在');
  }

  // 2. 獲取源詞句組的所有詞句
  const expressions = await db.prepare(
    'SELECT expression_id FROM expression_meaning WHERE meaning_id = ?'
  ).bind(sourceMeaningId).all();

  // 3. 批量插入新的 expression_meaning 關聯
  const now = new Date().toISOString();
  const insertStatements = expressions.map(e =>
    db.prepare(
      'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
    ).bind(`${e.expression_id}-${targetMeaningId}`, e.expression_id, targetMeaningId, now)
  );

  // 4. 批量刪除源詞句組的關聯
  const deleteExpressionMeaningStmt = db.prepare(
    'DELETE FROM expression_meaning WHERE meaning_id = ?'
  ).bind(sourceMeaningId);

  // 5. 刪除源詞句組
  const deleteMeaningStmt = db.prepare(
    'DELETE FROM meanings WHERE id = ?'
  ).bind(sourceMeaningId);

  // 6. 使用 batch 執行所有操作
  await db.batch([...insertStatements, deleteExpressionMeaningStmt, deleteMeaningStmt]);

  return {
    success: true,
    merged_count: expressions.length,
    target_meaning_id: targetMeaningId
  };
}
```

## 6. 前端組件設計

### 6.1 新增狀態變量（Detail.vue）

```typescript
// 詞句組合併模態框
const showMergeGroupsModal = ref(false)
const sourceMeaningId = ref<number | null>(null)
const targetMeaningId = ref<number | null>(null)
const mergeLoading = ref(false)
const mergeMessage = ref('')
```

### 6.2 新增函數（Detail.vue）

```typescript
// 打開詞句組合併模態框
function openMergeGroupsModal() {
  sourceMeaningId.value = currentMeaning.value.id
  targetMeaningId.value = null
  mergeMessage.value = ''
  showMergeGroupsModal.value = true
}

// 關閉詞句組合併模態框
function closeMergeGroupsModal() {
  showMergeGroupsModal.value = false
  sourceMeaningId.value = null
  targetMeaningId.value = null
  mergeMessage.value = ''
}

// 執行詞句組合併
async function mergeMeaningGroups(targetMeaningId: number) {
  if (!sourceMeaningId.value) return

  // 前端驗證
  if (sourceMeaningId.value === targetMeaningId) {
    mergeMessage.value = t('cannot_merge_to_same_group')
    return
  }

  const token = localStorage.getItem('authToken')
  if (!token) {
    alert(t('login_required'))
    return
  }

  mergeLoading.value = true
  mergeMessage.value = ''

  try {
    const res = await fetch('/api/v1/meanings/merge', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        source_meaning_id: sourceMeaningId.value,
        target_meaning_id: targetMeaningId
      })
    })

    if (!res.ok) {
      const errorData = await res.json()
      throw new Error(errorData.error || 'Failed to merge meaning groups')
    }

    const result = await res.json()

    // 關閉模態框
    closeMergeGroupsModal()

    // 刷新數據
    await load()

    // 切換到目標詞句組
    setActiveTab(targetMeaningId.toString())

    // 顯示成功提示（可選）
    mergeMessage.value = t('merge_success', { count: result.merged_count })
  } catch (e) {
    console.error('Merge error:', e)
    mergeMessage.value = String(e)
  } finally {
    mergeLoading.value = false
  }
}
```

### 6.3 模態框模板（Detail.vue）

```vue
<!-- 詞句組合併模態框 -->
<div v-if="showMergeGroupsModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
  <div class="bg-white rounded-xl shadow-lg max-w-2xl w-full max-h-[80vh] flex flex-col">
    <div class="border-b border-slate-200 px-4 sm:px-6 py-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
      <div>
        <h3 class="text-lg font-bold text-slate-800">{{ $t('merge_groups') }}</h3>
        <p class="text-slate-500 text-sm mt-1">
          {{ $t('merge_groups_description') }}
        </p>
      </div>
      <button @click="closeMergeGroupsModal"
        class="text-slate-400 hover:text-slate-600 transition-colors self-start">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24"
          stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <div class="flex-1 overflow-y-auto px-4 sm:px-6 py-4">
      <div v-if="mergeLoading" class="flex items-center justify-center py-8">
        <svg class="animate-spin h-6 w-6 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
          viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
          </path>
        </svg>
        <span class="ml-2 text-slate-600">{{ $t('loading') }}</span>
      </div>

      <div v-else-if="mergeMessage" class="text-center py-8">
        <p class="text-slate-600">{{ mergeMessage }}</p>
      </div>

      <div v-else class="space-y-3">
        <div v-for="meaning in otherMeanings" :key="meaning.id"
          @click="mergeMeaningGroups(meaning.id)"
          class="border border-slate-200 rounded-lg p-4 hover:border-blue-300 hover:bg-blue-50 transition-colors cursor-pointer">
          <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
            <div class="flex-1 min-w-0">
              <h4 class="font-semibold text-slate-800">#{{ getMeaningIndex(meaning.id) }}</h4>
              <p class="text-sm text-slate-500 mt-1">
                {{ meaning.members.length }} {{ $t('expressions') }}
              </p>
              <p class="text-sm text-slate-600 mt-1 truncate">
                {{ getMeaningDisplayText(meaning) }}
              </p>
              <p class="text-xs text-slate-400 mt-1">
                {{ $t('created_by') }}: {{ meaning.created_by || $t('anonymous') }}
              </p>
            </div>
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-400 sm:flex-shrink-0" fill="none"
              viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </div>
        </div>

        <div v-if="otherMeanings.length === 0" class="text-center py-8">
          <p class="text-slate-500">{{ $t('no_other_groups_to_merge') }}</p>
        </div>
      </div>
    </div>

    <div class="border-t border-slate-200 px-4 sm:px-6 py-4">
      <button @click="closeMergeGroupsModal"
        class="w-full inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-slate-100 text-slate-700 hover:bg-slate-200 focus:ring-slate-500 px-4 py-2">
        {{ $t('cancel') }}
      </button>
    </div>
  </div>
</div>
```

### 6.4 計算屬性（Detail.vue）

```typescript
// 獲取其他詞句組（排除當前詞句組）
const otherMeanings = computed(() => {
  if (!sourceMeaningId.value) return []
  return meanings.value.filter(m => m.id !== sourceMeaningId.value)
})

// 獲取詞句組在列表中的索引
function getMeaningIndex(meaningId: number) {
  return meanings.value.findIndex(m => m.id === meaningId) + 1
}
```

## 7. 國際化字符串

### 7.1 英文（en-US.json）

```json
{
  "merge_groups": "Merge Groups",
  "merge_groups_description": "Select the target meaning group to merge the current group into. This action cannot be undone.",
  "cannot_merge_to_same_group": "Cannot merge to the same group",
  "merge_success": "Successfully merged {count} expressions",
  "no_other_groups_to_merge": "No other groups available to merge"
}
```

### 7.2 簡體中文（zh-CN.json）

```json
{
  "merge_groups": "合併詞句組",
  "merge_groups_description": "選擇要將當前詞句組合併到的目標詞句組。此操作無法撤銷。",
  "cannot_merge_to_same_group": "不能合併到同一個詞句組",
  "merge_success": "成功合併 {count} 個詞句",
  "no_other_groups_to_merge": "沒有其他可合併的詞句組"
}
```

### 7.3 繁體中文（zh-TW.json）

```json
{
  "merge_groups": "合併詞句組",
  "merge_groups_description": "選擇要將當前詞句組合併到的目標詞句組。此操作無法撤銷。",
  "cannot_merge_to_same_group": "不能合併到同一個詞句組",
  "merge_success": "成功合併 {count} 個詞句",
  "no_other_groups_to_merge": "沒有其他可合併的詞句組"
}
```

## 8. 實現清單

### 8.1 前端實現

- [ ] 在 Detail.vue 中添加合併按鈕（詞句組內部）
- [ ] 添加詞句組合併模態框模板
- [ ] 添加相關狀態變量
- [ ] 實現打開/關閉模態框函數
- [ ] 實現執行合併函數
- [ ] 添加錯誤處理
- [ ] 添加國際化字符串
- [ ] 測試合併功能

### 8.2 後端實現

- [ ] 在 D1DatabaseService 中添加 `mergeMeaningGroups` 方法
- [ ] 在 API v1 中添加 POST /api/v1/meanings/merge 端點
- [ ] 實現批量插入、批量刪除邏輯
- [ ] 添加權限驗證
- [ ] 添加錯誤處理
- [ ] 測試合併 API

## 9. 測試用例

### 9.1 功能測試

1. **正常合併**
   - 在詳情頁點擊合併按鈕
   - 選擇目標詞句組
   - 驗證源詞句組的詞句已添加到目標詞句組
   - 驗證源詞句組已刪除
   - 驗證頁面自動切換到目標詞句組

2. **合併到同一詞句組**
   - 嘗試將詞句組合併到自己
   - 驗證顯示錯誤提示
   - 驗證不發送請求

3. **權限測試**
   - 未登錄用戶嘗試合併
   - 驗證顯示權限錯誤
   - 普通用戶嘗試合併其他用戶的詞句組
   - 驗證顯示權限錯誤
   - 管理員用戶可以合併任何詞句組

4. **網絡錯誤**
   - 模擬網絡中斷
   - 驗證顯示網絡錯誤提示
   - 驗證模態框不關閉

### 9.2 性能測試

1. **大量詞句合併**
   - 創建包含 100 個詞句的詞句組
   - 執行合併操作
   - 驗證響應時間 < 2 秒

2. **並發合併**
   - 同時對同一詞句組發起多個合併請求
   - 驗證只執行一次合併
   - 驗證其他請求返回衝突錯誤

## 10. 注意事項

1. **數據一致性**：所有數據庫操作必須在事務中執行，確保原子性
2. **權限控制**：只有詞句組的創建者或管理員可以執行合併操作
3. **用戶體驗**：合併操作不可逆，必須在界面中明確提示
4. **性能優化**：使用批量操作減少數據庫往返次數
5. **緩存清理**：合併後清理相關緩存（statistics cache, heatmap cache）

## 11. 後續優化

1. **批量選擇**：支持同時選擇多個詞句組進行批量合併
2. **合併歷史**：記錄詞句組合併歷史，支持撤銷操作
3. **智能推薦**：根據詞句相似度推薦合併目標詞句組
4. **合併預覽**：在合併前顯示預覽，展示合併後的詞句組內容
