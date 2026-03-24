# 詞句組合併功能實施計劃

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在詳情頁實現詞句組合併功能，允許用戶將一個詞句組合併到另一個詞句組

**Architecture:** 前端在詞句組內部添加合併按鈕，打開模態框選擇目標詞句組；後端使用批量操作將源詞句組的所有詞句關聯到目標詞句組，然後刪除源詞句組

**Tech Stack:** Vue 3 (Composition API), TypeScript, Cloudflare D1, Hono API

---

### Task 1: 添加國際化字符串

**Files:**
- Modify: `web/src/locales/en-US.json`
- Modify: `web/src/locales/zh-CN.json`
- Modify: `web/src/locales/zh-TW.json`

**Step 1: 添加英文國際化字符串**

打開 `web/src/locales/en-US.json`，添加以下鍵值：

```json
{
  "merge_groups": "Merge Groups",
  "merge_groups_description": "Select a target meaning group to merge the current group into. This action cannot be undone.",
  "cannot_merge_to_same_group": "Cannot merge to the same group",
  "merge_success": "Successfully merged {count} expressions",
  "no_other_groups_to_merge": "No other groups available to merge"
}
```

**Step 2: 添加簡體中文國際化字符串**

打開 `web/src/locales/zh-CN.json`，添加以下鍵值：

```json
{
  "merge_groups": "合併詞句組",
  "merge_groups_description": "選擇要將當前詞句組合併到的目標詞句組。此操作無法撤銷。",
  "cannot_merge_to_same_group": "不能合併到同一個詞句組",
  "merge_success": "成功合併 {count} 個詞句",
  "no_other_groups_to_merge": "沒有其他可合併的詞句組"
}
```

**Step 3: 添加繁體中文國際化字符串**

打開 `web/src/locales/zh-TW.json`，添加以下鍵值：

```json
{
  "merge_groups": "合併詞句組",
  "merge_groups_description": "選擇要將當前詞句組合併到的目標詞句組。此操作無法撤銷。",
  "cannot_merge_to_same_group": "不能合併到同一個詞句組",
  "merge_success": "成功合併 {count} 個詞句",
  "no_other_groups_to_merge": "沒有其他可合併的詞句組"
}
```

**Step 4: 驗證字符串格式**

確保所有 JSON 文件格式正確，沒有語法錯誤。

**Step 5: Commit**

```bash
git add web/src/locales/en-US.json web/src/locales/zh-CN.json web/src/locales/zh-TW.json
git commit -m "feat: add i18n strings for meaning group merge feature"
```

---

### Task 2: 在詞句組內部添加合併按鈕

**Files:**
- Modify: `web/src/pages/Detail.vue:57-60`

**Step 1: 在詞句組頭部添加合併按鈕**

找到 Detail.vue 第 57-60 行的詞句組頭部代碼，在成員數量顯示後添加合併按鈕：

```vue
<div
  class="border-b border-slate-200 px-3 sm:px-6 py-3 sm:py-4 flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-3">
  <div class="flex items-center">
    <span class="text-slate-600 text-sm sm:text-base">{{ currentMembers.length }} {{ $t('expressions') }}</span>

    <!-- 新增：合併按鈕 -->
    <button @click="openMergeGroupsModal()"
      class="ml-2 text-slate-400 hover:text-blue-600 transition-colors"
      :title="$t('merge_groups')">
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24"
        stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
          d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
      </svg>
    </button>
  </div>

  <button v-if="!groupSearchModes.has(currentMeaning.id)" @click="toggleGroupSearch(currentMeaning.id)"
    class="inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 py-2 text-sm">
    ...
  </button>
  ...
</div>
```

**Step 2: 在 script 部分添加狀態變量**

在 Detail.vue 的 setup 函數中，找到 `const groupSearchModes = ref(new Set())` 後添加：

```typescript
// 詞句組合併模態框
const showMergeGroupsModal = ref(false)
const sourceMeaningId = ref<number | null>(null)
const targetMeaningId = ref<number | null>(null)
const mergeLoading = ref(false)
const mergeMessage = ref('')
```

**Step 3: 在 return 語句中導出新狀態**

在 Detail.vue 的 return 語句中（第 1040 行附近），添加：

```typescript
return {
  // ... 現有導出
  // 詞句組合併
  showMergeGroupsModal,
  sourceMeaningId,
  targetMeaningId,
  mergeLoading,
  mergeMessage,
  // ... 其餘導出
}
```

**Step 4: Commit**

```bash
git add web/src/pages/Detail.vue
git commit -m "feat: add merge button to meaning group header"
```

---

### Task 3: 實現詞句組合併模態框模板

**Files:**
- Modify: `web/src/pages/Detail.vue:319` (在 Meaning Selection Modal 之前添加）

**Step 1: 添加詞句組合併模態框模板**

在 Meaning Selection Modal 之前（第 319 行）添加新的模態框：

```vue
<!-- 詞句組合併模態框 -->
<div v-if="showMergeGroupsModal"
  class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
  <div class="bg-white rounded-xl shadow-lg max-w-2xl w-full max-h-[80vh] flex flex-col">
    <div
      class="border-b border-slate-200 px-4 sm:px-6 py-4 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
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
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-slate-400 sm:flex-shrink-0"
              fill="none" viewBox="0 0 24 24" stroke="currentColor">
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

**Step 2: Commit**

```bash
git add web/src/pages/Detail.vue
git commit -m "feat: add meaning group merge modal template"
```

---

### Task 4: 實現詞句組合併相關函數

**Files:**
- Modify: `web/src/pages/Detail.vue:336` (在 script 部分）

**Step 1: 添加計算屬性 otherMeanings**

在 Detail.vue 的 script 部分，找到 `const currentMembers = computed(...)` 後添加：

```typescript
// 獲取其他詞句組（排除當前詞句組）
const otherMeanings = computed(() => {
  if (!sourceMeaningId.value) return []
  return meanings.value.filter(m => m.id !== sourceMeaningId.value)
})
```

**Step 2: 添加輔助函數 getMeaningIndex**

在 Detail.vue 的 script 部分，找到 `function getMeaningDisplayText(...)` 後添加：

```typescript
// 獲取詞句組在列表中的索引
function getMeaningIndex(meaningId: number) {
  return meanings.value.findIndex(m => m.id === meaningId) + 1
}
```

**Step 3: 實現打開模態框函數**

在 Detail.vue 的 script 部分，添加：

```typescript
// 打開詞句組合併模態框
function openMergeGroupsModal() {
  sourceMeaningId.value = currentMeaning.value.id
  targetMeaningId.value = null
  mergeMessage.value = ''
  showMergeGroupsModal.value = true
}
```

**Step 4: 實現關閉模態框函數**

在 Detail.vue 的 script 部分，添加：

```typescript
// 關閉詞句組合併模態框
function closeMergeGroupsModal() {
  showMergeGroupsModal.value = false
  sourceMeaningId.value = null
  targetMeaningId.value = null
  mergeMessage.value = ''
}
```

**Step 5: 實現執行合併函數**

在 Detail.vue 的 script 部分，添加：

```typescript
// 執行詞句組合併
async function mergeMeaningGroups(targetMeaningIdParam: number) {
  if (!sourceMeaningId.value) return

  // 前端驗證
  if (sourceMeaningId.value === targetMeaningIdParam) {
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
        target_meaning_id: targetMeaningIdParam
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
    setActiveTab(targetMeaningIdParam.toString())
  } catch (e) {
    console.error('Merge error:', e)
    mergeMessage.value = String(e)
  } finally {
    mergeLoading.value = false
  }
}
```

**Step 6: 在 return 語句中導出新函數和計算屬性**

在 Detail.vue 的 return 語句中，添加：

```typescript
return {
  // ... 現有導出
  // 詞句組合併
  showMergeGroupsModal,
  sourceMeaningId,
  targetMeaningId,
  mergeLoading,
  mergeMessage,
  otherMeanings,
  openMergeGroupsModal,
  closeMergeGroupsModal,
  mergeMeaningGroups,
  getMeaningIndex,
  // ... 其餘導出
}
```

**Step 7: Commit**

```bash
git add web/src/pages/Detail.vue
git commit -m "feat: implement meaning group merge functions"
```

---

### Task 5: 在後端實現合併 API

**Files:**
- Modify: `backend/src/server/db/d1.ts`
- Modify: `backend/src/server/api/v1.ts`

**Step 1: 在 D1DatabaseService 中添加 mergeMeaningGroups 方法**

打開 `backend/src/server/db/d1.ts`，在文件末尾添加方法：

```typescript
// 合併詞句組
async mergeMeaningGroups(sourceMeaningId: number, targetMeaningId: number): Promise<{
  success: boolean
  merged_count: number
  target_meaning_id: number
}> {
  const db = this.db;

  // 1. 驗證詞句組存在
  const sourceMeaning = await db.prepare('SELECT * FROM meanings WHERE id = ?').bind(sourceMeaningId).first();
  const targetMeaning = await db.prepare('SELECT * FROM meanings WHERE id = ?').bind(targetMeaningId).first();

  if (!sourceMeaning) {
    throw new Error('Source meaning group not found');
  }

  if (!targetMeaning) {
    throw new Error('Target meaning group not found');
  }

  // 2. 獲取源詞句組的所有詞句
  const expressions = await db.prepare(
    'SELECT expression_id FROM expression_meaning WHERE meaning_id = ?'
  ).bind(sourceMeaningId).all<{ expression_id: number }>();

  if (expressions.length === 0) {
    return {
      success: true,
      merged_count: 0,
      target_meaning_id: targetMeaningId
    };
  }

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
  try {
    await db.batch([...insertStatements, deleteExpressionMeaningStmt, deleteMeaningStmt]);

    return {
      success: true,
      merged_count: expressions.length,
      target_meaning_id: targetMeaningId
    };
  } catch (error) {
    console.error('Failed to merge meaning groups:', error);
    throw new Error('Failed to merge meaning groups');
  }
}
```

**Step 2: 在 API v1 中添加合併端點**

打開 `backend/src/server/api/v1.ts`，在文件中找到合適的位置（在 DELETE /api/v1/expressions/:expr_id/meanings/:meaning_id 之後）添加：

```typescript
// POST /api/v1/meanings/merge
api.post('/meanings/merge', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const body = await c.req.json()
    const { source_meaning_id, target_meaning_id } = body

    // 驗證參數
    if (!source_meaning_id || !target_meaning_id) {
      return c.json({ error: 'source_meaning_id and target_meaning_id are required' }, 400)
    }

    // 驗證是數字
    const sourceId = parseInt(source_meaning_id, 10)
    const targetId = parseInt(target_meaning_id, 10)

    if (isNaN(sourceId) || isNaN(targetId)) {
      return c.json({ error: 'Invalid meaning IDs' }, 400)
    }

    // 執行合併
    const result = await db.mergeMeaningGroups(sourceId, targetId)

    // 清除緩存
    db.clearStatisticsCache();

    return c.json({
      success: true,
      message: '詞句組合併成功',
      ...result
    })
  } catch (error: any) {
    console.error('Error in POST /meanings/merge:', error);
    return c.json({ error: error.message || 'Failed to merge meaning groups' }, 500)
  }
})
```

**Step 3: Commit**

```bash
git add backend/src/server/db/d1.ts backend/src/server/api/v1.ts
git commit -m "feat: implement meaning group merge API"
```

---

### Task 6: 驗證構建

**Files:**
- Test: `web/` (前端構建）
- Test: `backend/` (後端構建）

**Step 1: 構建前端**

```bash
cd web
npm run build
```

預期：構建成功，沒有錯誤

**Step 2: 構建後端**

```bash
cd backend
npm run build
```

預期：構建成功，沒有錯誤

**Step 3: Commit**

```bash
git add web/ backend/
git commit -m "chore: verify build passes after merge feature implementation"
```

---

### Task 7: 功能測試

**Files:**
- Test: 手動測試

**Step 1: 測試合併按鈕顯示**

1. 啓動應用：`npm run dev`
2. 導航到詳情頁
3. 查看詞句組頭部是否顯示合併按鈕

預期：在成員數量旁邊顯示合併圖標按鈕

**Step 2: 測試打開合併模態框**

1. 點擊合併按鈕
2. 驗證模態框打開
3. 驗證顯示其他詞句組列表

預期：模態框打開，顯示所有其他詞句組

**Step 3: 測試合併功能**

1. 選擇一個目標詞句組
2. 點擊詞句組卡片
3. 驗證合併執行
4. 驗證頁面刷新並切換到目標詞句組

預期：合併成功，源詞句組被刪除，詞句移動到目標詞句組

**Step 4: 測試錯誤處理**

1. 嘗試在沒有登錄時合併
2. 驗證顯示權限錯誤

預期：顯示權限錯誤提示

**Step 5: 測試前端驗證**

1. 打開合併模態框
2. 檢查當前詞句組是否不在列表中

預期：當前詞句組不在可選擇的列表中

**Step 6: Commit**

如果有任何修復：

```bash
git add .
git commit -m "fix: address issues found during testing"
```

---

## 實施檢查清單

- [ ] Task 1: 添加國際化字符串
- [ ] Task 2: 在詞句組內部添加合併按鈕
- [ ] Task 3: 實現詞句組合併模態框模板
- [ ] Task 4: 實現詞句組合併相關函數
- [ ] Task 5: 在後端實現合併 API
- [ ] Task 6: 驗證構建
- [ ] Task 7: 功能測試

## 注意事項

1. 確保所有數據庫操作使用批量操作以提高性能
2. 所有 SQL 操作在一個 batch 中執行，確保原子性
3. 前端驗證源詞句組和目標詞句組不相同
4. 後端驗證詞句組存在性
5. 合併後清理相關緩存
6. 測試時檢查控制臺是否有錯誤

## 測試場景

1. **正常合併流程**
   - 點擊合併按鈕
   - 選擇目標詞句組
   - 驗證合併成功

2. **權限測試**
   - 未登錄用戶嘗試合併
   - 驗證顯示權限錯誤

3. **邊界情況**
   - 只有一個詞句組（不應顯示合併功能或顯示無其他組提示）
   - 源詞句組爲空（應成功合併）

4. **網絡錯誤**
   - 模擬網絡錯誤
   - 驗證錯誤提示正確顯示
