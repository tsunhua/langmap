# 词句组合并功能实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在详情页实现词句组合并功能，允许用户将一个词句组合并到另一个词句组

**Architecture:** 前端在词句组内部添加合并按钮，打开模态框选择目标词句组；后端使用批量操作将源词句组的所有词句关联到目标词句组，然后删除源词句组

**Tech Stack:** Vue 3 (Composition API), TypeScript, Cloudflare D1, Hono API

---

### Task 1: 添加国际化字符串

**Files:**
- Modify: `web/src/locales/en-US.json`
- Modify: `web/src/locales/zh-CN.json`
- Modify: `web/src/locales/zh-TW.json`

**Step 1: 添加英文国际化字符串**

打开 `web/src/locales/en-US.json`，添加以下键值：

```json
{
  "merge_groups": "Merge Groups",
  "merge_groups_description": "Select a target meaning group to merge the current group into. This action cannot be undone.",
  "cannot_merge_to_same_group": "Cannot merge to the same group",
  "merge_success": "Successfully merged {count} expressions",
  "no_other_groups_to_merge": "No other groups available to merge"
}
```

**Step 2: 添加简体中文国际化字符串**

打开 `web/src/locales/zh-CN.json`，添加以下键值：

```json
{
  "merge_groups": "合并词句组",
  "merge_groups_description": "选择要将当前词句组合并到的目标词句组。此操作无法撤销。",
  "cannot_merge_to_same_group": "不能合并到同一个词句组",
  "merge_success": "成功合并 {count} 个词句",
  "no_other_groups_to_merge": "没有其他可合并的词句组"
}
```

**Step 3: 添加繁体中文国际化字符串**

打开 `web/src/locales/zh-TW.json`，添加以下键值：

```json
{
  "merge_groups": "合併詞句組",
  "merge_groups_description": "選擇要將當前詞句組合併到的目標詞句組。此操作無法撤銷。",
  "cannot_merge_to_same_group": "不能合併到同一個詞句組",
  "merge_success": "成功合併 {count} 個詞句",
  "no_other_groups_to_merge": "沒有其他可合併的詞句組"
}
```

**Step 4: 验证字符串格式**

确保所有 JSON 文件格式正确，没有语法错误。

**Step 5: Commit**

```bash
git add web/src/locales/en-US.json web/src/locales/zh-CN.json web/src/locales/zh-TW.json
git commit -m "feat: add i18n strings for meaning group merge feature"
```

---

### Task 2: 在词句组内部添加合并按钮

**Files:**
- Modify: `web/src/pages/Detail.vue:57-60`

**Step 1: 在词句组头部添加合并按钮**

找到 Detail.vue 第 57-60 行的词句组头部代码，在成员数量显示后添加合并按钮：

```vue
<div
  class="border-b border-slate-200 px-3 sm:px-6 py-3 sm:py-4 flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-3">
  <div class="flex items-center">
    <span class="text-slate-600 text-sm sm:text-base">{{ currentMembers.length }} {{ $t('expressions') }}</span>

    <!-- 新增：合并按钮 -->
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

**Step 2: 在 script 部分添加状态变量**

在 Detail.vue 的 setup 函数中，找到 `const groupSearchModes = ref(new Set())` 后添加：

```typescript
// 词句组合并模态框
const showMergeGroupsModal = ref(false)
const sourceMeaningId = ref<number | null>(null)
const targetMeaningId = ref<number | null>(null)
const mergeLoading = ref(false)
const mergeMessage = ref('')
```

**Step 3: 在 return 语句中导出新状态**

在 Detail.vue 的 return 语句中（第 1040 行附近），添加：

```typescript
return {
  // ... 现有导出
  // 词句组合并
  showMergeGroupsModal,
  sourceMeaningId,
  targetMeaningId,
  mergeLoading,
  mergeMessage,
  // ... 其余导出
}
```

**Step 4: Commit**

```bash
git add web/src/pages/Detail.vue
git commit -m "feat: add merge button to meaning group header"
```

---

### Task 3: 实现词句组合并模态框模板

**Files:**
- Modify: `web/src/pages/Detail.vue:319` (在 Meaning Selection Modal 之前添加）

**Step 1: 添加词句组合并模态框模板**

在 Meaning Selection Modal 之前（第 319 行）添加新的模态框：

```vue
<!-- 词句组合并模态框 -->
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

### Task 4: 实现词句组合并相关函数

**Files:**
- Modify: `web/src/pages/Detail.vue:336` (在 script 部分）

**Step 1: 添加计算属性 otherMeanings**

在 Detail.vue 的 script 部分，找到 `const currentMembers = computed(...)` 后添加：

```typescript
// 获取其他词句组（排除当前词句组）
const otherMeanings = computed(() => {
  if (!sourceMeaningId.value) return []
  return meanings.value.filter(m => m.id !== sourceMeaningId.value)
})
```

**Step 2: 添加辅助函数 getMeaningIndex**

在 Detail.vue 的 script 部分，找到 `function getMeaningDisplayText(...)` 后添加：

```typescript
// 获取词句组在列表中的索引
function getMeaningIndex(meaningId: number) {
  return meanings.value.findIndex(m => m.id === meaningId) + 1
}
```

**Step 3: 实现打开模态框函数**

在 Detail.vue 的 script 部分，添加：

```typescript
// 打开词句组合并模态框
function openMergeGroupsModal() {
  sourceMeaningId.value = currentMeaning.value.id
  targetMeaningId.value = null
  mergeMessage.value = ''
  showMergeGroupsModal.value = true
}
```

**Step 4: 实现关闭模态框函数**

在 Detail.vue 的 script 部分，添加：

```typescript
// 关闭词句组合并模态框
function closeMergeGroupsModal() {
  showMergeGroupsModal.value = false
  sourceMeaningId.value = null
  targetMeaningId.value = null
  mergeMessage.value = ''
}
```

**Step 5: 实现执行合并函数**

在 Detail.vue 的 script 部分，添加：

```typescript
// 执行词句组合并
async function mergeMeaningGroups(targetMeaningIdParam: number) {
  if (!sourceMeaningId.value) return

  // 前端验证
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

    // 关闭模态框
    closeMergeGroupsModal()

    // 刷新数据
    await load()

    // 切换到目标词句组
    setActiveTab(targetMeaningIdParam.toString())
  } catch (e) {
    console.error('Merge error:', e)
    mergeMessage.value = String(e)
  } finally {
    mergeLoading.value = false
  }
}
```

**Step 6: 在 return 语句中导出新函数和计算属性**

在 Detail.vue 的 return 语句中，添加：

```typescript
return {
  // ... 现有导出
  // 词句组合并
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
  // ... 其余导出
}
```

**Step 7: Commit**

```bash
git add web/src/pages/Detail.vue
git commit -m "feat: implement meaning group merge functions"
```

---

### Task 5: 在后端实现合并 API

**Files:**
- Modify: `backend/src/server/db/d1.ts`
- Modify: `backend/src/server/api/v1.ts`

**Step 1: 在 D1DatabaseService 中添加 mergeMeaningGroups 方法**

打开 `backend/src/server/db/d1.ts`，在文件末尾添加方法：

```typescript
// 合并词句组
async mergeMeaningGroups(sourceMeaningId: number, targetMeaningId: number): Promise<{
  success: boolean
  merged_count: number
  target_meaning_id: number
}> {
  const db = this.db;

  // 1. 验证词句组存在
  const sourceMeaning = await db.prepare('SELECT * FROM meanings WHERE id = ?').bind(sourceMeaningId).first();
  const targetMeaning = await db.prepare('SELECT * FROM meanings WHERE id = ?').bind(targetMeaningId).first();

  if (!sourceMeaning) {
    throw new Error('Source meaning group not found');
  }

  if (!targetMeaning) {
    throw new Error('Target meaning group not found');
  }

  // 2. 获取源词句组的所有词句
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

  // 3. 批量插入新的 expression_meaning 关联
  const now = new Date().toISOString();
  const insertStatements = expressions.map(e =>
    db.prepare(
      'INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at) VALUES (?, ?, ?, ?)'
    ).bind(`${e.expression_id}-${targetMeaningId}`, e.expression_id, targetMeaningId, now)
  );

  // 4. 批量删除源词句组的关联
  const deleteExpressionMeaningStmt = db.prepare(
    'DELETE FROM expression_meaning WHERE meaning_id = ?'
  ).bind(sourceMeaningId);

  // 5. 删除源词句组
  const deleteMeaningStmt = db.prepare(
    'DELETE FROM meanings WHERE id = ?'
  ).bind(sourceMeaningId);

  // 6. 使用 batch 执行所有操作
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

**Step 2: 在 API v1 中添加合并端点**

打开 `backend/src/server/api/v1.ts`，在文件中找到合适的位置（在 DELETE /api/v1/expressions/:expr_id/meanings/:meaning_id 之后）添加：

```typescript
// POST /api/v1/meanings/merge
api.post('/meanings/merge', requireAuth, async (c) => {
  try {
    const db = getDB(c)
    const body = await c.req.json()
    const { source_meaning_id, target_meaning_id } = body

    // 验证参数
    if (!source_meaning_id || !target_meaning_id) {
      return c.json({ error: 'source_meaning_id and target_meaning_id are required' }, 400)
    }

    // 验证是数字
    const sourceId = parseInt(source_meaning_id, 10)
    const targetId = parseInt(target_meaning_id, 10)

    if (isNaN(sourceId) || isNaN(targetId)) {
      return c.json({ error: 'Invalid meaning IDs' }, 400)
    }

    // 执行合并
    const result = await db.mergeMeaningGroups(sourceId, targetId)

    // 清除缓存
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

### Task 6: 验证构建

**Files:**
- Test: `web/` (前端构建）
- Test: `backend/` (后端构建）

**Step 1: 构建前端**

```bash
cd web
npm run build
```

预期：构建成功，没有错误

**Step 2: 构建后端**

```bash
cd backend
npm run build
```

预期：构建成功，没有错误

**Step 3: Commit**

```bash
git add web/ backend/
git commit -m "chore: verify build passes after merge feature implementation"
```

---

### Task 7: 功能测试

**Files:**
- Test: 手动测试

**Step 1: 测试合并按钮显示**

1. 启动应用：`npm run dev`
2. 导航到详情页
3. 查看词句组头部是否显示合并按钮

预期：在成员数量旁边显示合并图标按钮

**Step 2: 测试打开合并模态框**

1. 点击合并按钮
2. 验证模态框打开
3. 验证显示其他词句组列表

预期：模态框打开，显示所有其他词句组

**Step 3: 测试合并功能**

1. 选择一个目标词句组
2. 点击词句组卡片
3. 验证合并执行
4. 验证页面刷新并切换到目标词句组

预期：合并成功，源词句组被删除，词句移动到目标词句组

**Step 4: 测试错误处理**

1. 尝试在没有登录时合并
2. 验证显示权限错误

预期：显示权限错误提示

**Step 5: 测试前端验证**

1. 打开合并模态框
2. 检查当前词句组是否不在列表中

预期：当前词句组不在可选择的列表中

**Step 6: Commit**

如果有任何修复：

```bash
git add .
git commit -m "fix: address issues found during testing"
```

---

## 实施检查清单

- [ ] Task 1: 添加国际化字符串
- [ ] Task 2: 在词句组内部添加合并按钮
- [ ] Task 3: 实现词句组合并模态框模板
- [ ] Task 4: 实现词句组合并相关函数
- [ ] Task 5: 在后端实现合并 API
- [ ] Task 6: 验证构建
- [ ] Task 7: 功能测试

## 注意事项

1. 确保所有数据库操作使用批量操作以提高性能
2. 所有 SQL 操作在一个 batch 中执行，确保原子性
3. 前端验证源词句组和目标词句组不相同
4. 后端验证词句组存在性
5. 合并后清理相关缓存
6. 测试时检查控制台是否有错误

## 测试场景

1. **正常合并流程**
   - 点击合并按钮
   - 选择目标词句组
   - 验证合并成功

2. **权限测试**
   - 未登录用户尝试合并
   - 验证显示权限错误

3. **边界情况**
   - 只有一个词句组（不应显示合并功能或显示无其他组提示）
   - 源词句组为空（应成功合并）

4. **网络错误**
   - 模拟网络错误
   - 验证错误提示正确显示
