# 词句组合并功能设计文档

## 1. 概述与用户流程

### 功能目标
允许用户在详情页将一个词句组合并到另一个词句组，简化词句组管理，避免重复或相似的含义组。

### 用户场景
- 用户发现两个词句组表达的含义相似，想要合并它们
- 用户希望减少词句组数量，使管理更加简洁
- 用户误创建了多个词句组，需要合并修正

### 操作流程
1. 用户在详情页看到当前词句所属的多个词句组标签
2. 在词句组标签页的成员数量显示区域旁边点击「合并」按钮
3. 弹出模态框，显示该词句所属的其他词句组列表
4. 用户选择要合并到的目标词句组
5. 系统执行合并，将源词句组中的所有词句添加到目标词句组，然后删除源词句组
6. 页面自动刷新，显示合并后的词句组列表

## 2. 界面设计

### 2.1 词句组内部布局

在词句组内部的成员数量显示区域旁边添加合并按钮（Detail.vue 第 57-60 行）：

```vue
<div class="border-b border-slate-200 px-3 sm:px-6 py-3 sm:py-4 flex ...">
  <span class="text-slate-600 text-sm sm:text-base">{{ currentMembers.length }} {{ $t('expressions') }}</span>

  <!-- 新增：合并按钮 -->
  <button @click="openMergeGroupsModal()" class="ml-2 text-slate-400 hover:text-blue-600 transition-colors" :title="$t('merge_groups')">
    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
    </svg>
  </button>

  <button @click="toggleGroupSearch(...)">...</button>
</div>
```

合并按钮使用浅色图标，hover 时变为蓝色，保持低调但可见。

### 2.2 词句组合并模态框

模态框布局：
- **标题**：「合併詞句組」
- **描述**：「選擇要將當前詞句組合併到的目標詞句組。此操作無法撤銷。」
- **词句组列表**：显示当前词句所属的所有其他词句组（排除当前标签页的词句组）
  - 每个词句组卡片显示：
    - 词句组标签号（如 #1）
    - 词句数量（如「5 個詞句」）
    - 前 3 个词句的文本（用 " / " 分隔）
    - 创建者信息
  - 点击卡片直接执行合并操作
- **底部操作栏**：
  - 「取消」按钮

## 3. 数据流程

### 3.1 合并操作流程

1. **用户点击合并按钮**（在词句组内部）
   - 调用 `openMergeGroupsModal()` 函数
   - 设置 `showMergeGroupsModal = true`
   - 设置 `sourceMeaningId = currentMeaning.id`
   - 加载其他词句组列表（通过 `meanings.value` 过滤，排除当前词句组）

2. **用户选择目标词句组**
   - 调用 `mergeMeaningGroups(targetMeaningId)` 函数
   - 传递源词句组 ID 和目标词句组 ID

3. **执行合并操作**（前端）
   - 发送 POST 请求到 `/api/v1/meanings/merge`
   - 请求体：
     ```json
     {
       "source_meaning_id": "源词句组ID",
       "target_meaning_id": "目标词句组ID"
     }
     ```

4. **后端处理合并逻辑**（使用批量操作）
   - 验证用户权限
   - 使用事务或批量操作：
     1. **批量插入**新的 expression_meaning 关联：
        ```sql
        INSERT OR IGNORE INTO expression_meaning (id, expression_id, meaning_id, created_at)
        VALUES (?, ?, ?, ?)
        ```
        对源词句组的每个词句执行
     2. **批量删除**源词句组的 expression_meaning 记录：
        ```sql
        DELETE FROM expression_meaning WHERE meaning_id = ?
        ```
     3. **删除**源词句组记录：
        ```sql
        DELETE FROM meanings WHERE id = ?
        ```
   - 所有操作在一个事务中执行，确保原子性
   - 返回合并结果

5. **前端刷新显示**
   - 重新加载词句组列表
   - 自动切换到目标词句组标签页

**性能优化点**：
- 使用 D1 的 `batch()` 方法一次性执行所有 SQL 语句
- 使用 `INSERT OR IGNORE` 避免重复插入
- 单次数据库往返完成所有操作

## 4. 错误处理

### 4.1 前端错误处理

**场景 1：权限不足**
- 后端返回 401 或 403 状态码
- 前端显示提示：「您沒有權限執行此操作」
- 不关闭模态框，允许用户重新登录后重试

**场景 2：词句组不存在**
- 后端返回 404 状态码
- 前端显示提示：「詞句組不存在，請重新整理頁面」
- 关闭模态框，刷新数据

**场景 3：合并到同一个词句组**
- 前端验证：源词句组 ID 不等于目标词句组 ID
- 如果相等，不发送请求，显示提示：「不能合併到同一個詞句組」

**场景 4：网络错误**
- 捕获 fetch 错误
- 显示提示：「網絡錯誤，請稍後再試」
- 不关闭模态框，允许用户重试

### 4.2 后端错误处理

**验证失败**：
- 源词句组 ID 或目标词句组 ID 不存在：返回 404
- 用户无权限修改词句组：返回 403

**数据库错误**：
- 事务执行失败：返回 500，包含错误详情
- 记录错误日志便于排查

**并发冲突**：
- 使用数据库锁或事务隔离级别处理并发合并请求
- 如果检测到冲突，返回 409 Conflict

## 5. 后端 API 设计

### 5.1 API 端点

```
POST /api/v1/meanings/merge
```

### 5.2 请求格式

```json
{
  "source_meaning_id": 123,
  "target_meaning_id": 456
}
```

### 5.3 响应格式

**成功响应（200）**：
```json
{
  "success": true,
  "message": "詞句組合併成功",
  "merged_count": 5,
  "target_meaning_id": 456
}
```

**错误响应**：

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
  "details": "具体错误信息"
}
```

### 5.4 数据库操作（伪代码）

```typescript
async mergeMeaningGroups(sourceMeaningId: number, targetMeaningId: number, username: string) {
  const db = this.db;

  // 1. 验证词句组存在
  const sourceMeaning = await db.prepare('SELECT * FROM meanings WHERE id = ?').bind(sourceMeaningId).first();
  const targetMeaning = await db.prepare('SELECT * FROM meanings WHERE id = ?').bind(targetMeaningId).first();

  if (!sourceMeaning || !targetMeaning) {
    throw new Error('詞句組不存在');
  }

  // 2. 获取源词句组的所有词句
  const expressions = await db.prepare(
    'SELECT expression_id FROM expression_meaning WHERE meaning_id = ?'
  ).bind(sourceMeaningId).all();

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
  await db.batch([...insertStatements, deleteExpressionMeaningStmt, deleteMeaningStmt]);

  return {
    success: true,
    merged_count: expressions.length,
    target_meaning_id: targetMeaningId
  };
}
```

## 6. 前端组件设计

### 6.1 新增状态变量（Detail.vue）

```typescript
// 词句组合并模态框
const showMergeGroupsModal = ref(false)
const sourceMeaningId = ref<number | null>(null)
const targetMeaningId = ref<number | null>(null)
const mergeLoading = ref(false)
const mergeMessage = ref('')
```

### 6.2 新增函数（Detail.vue）

```typescript
// 打开词句组合并模态框
function openMergeGroupsModal() {
  sourceMeaningId.value = currentMeaning.value.id
  targetMeaningId.value = null
  mergeMessage.value = ''
  showMergeGroupsModal.value = true
}

// 关闭词句组合并模态框
function closeMergeGroupsModal() {
  showMergeGroupsModal.value = false
  sourceMeaningId.value = null
  targetMeaningId.value = null
  mergeMessage.value = ''
}

// 执行词句组合并
async function mergeMeaningGroups(targetMeaningId: number) {
  if (!sourceMeaningId.value) return

  // 前端验证
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

    // 关闭模态框
    closeMergeGroupsModal()

    // 刷新数据
    await load()

    // 切换到目标词句组
    setActiveTab(targetMeaningId.toString())

    // 显示成功提示（可选）
    mergeMessage.value = t('merge_success', { count: result.merged_count })
  } catch (e) {
    console.error('Merge error:', e)
    mergeMessage.value = String(e)
  } finally {
    mergeLoading.value = false
  }
}
```

### 6.3 模态框模板（Detail.vue）

```vue
<!-- 词句组合并模态框 -->
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

### 6.4 计算属性（Detail.vue）

```typescript
// 获取其他词句组（排除当前词句组）
const otherMeanings = computed(() => {
  if (!sourceMeaningId.value) return []
  return meanings.value.filter(m => m.id !== sourceMeaningId.value)
})

// 获取词句组在列表中的索引
function getMeaningIndex(meaningId: number) {
  return meanings.value.findIndex(m => m.id === meaningId) + 1
}
```

## 7. 国际化字符串

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

### 7.2 简体中文（zh-CN.json）

```json
{
  "merge_groups": "合併詞句組",
  "merge_groups_description": "選擇要將當前詞句組合併到的目標詞句組。此操作無法撤銷。",
  "cannot_merge_to_same_group": "不能合併到同一個詞句組",
  "merge_success": "成功合併 {count} 個詞句",
  "no_other_groups_to_merge": "沒有其他可合併的詞句組"
}
```

### 7.3 繁体中文（zh-TW.json）

```json
{
  "merge_groups": "合併詞句組",
  "merge_groups_description": "選擇要將當前詞句組合併到的目標詞句組。此操作無法撤銷。",
  "cannot_merge_to_same_group": "不能合併到同一個詞句組",
  "merge_success": "成功合併 {count} 個詞句",
  "no_other_groups_to_merge": "沒有其他可合併的詞句組"
}
```

## 8. 实现清单

### 8.1 前端实现

- [ ] 在 Detail.vue 中添加合并按钮（词句组内部）
- [ ] 添加词句组合并模态框模板
- [ ] 添加相关状态变量
- [ ] 实现打开/关闭模态框函数
- [ ] 实现执行合并函数
- [ ] 添加错误处理
- [ ] 添加国际化字符串
- [ ] 测试合并功能

### 8.2 后端实现

- [ ] 在 D1DatabaseService 中添加 `mergeMeaningGroups` 方法
- [ ] 在 API v1 中添加 POST /api/v1/meanings/merge 端点
- [ ] 实现批量插入、批量删除逻辑
- [ ] 添加权限验证
- [ ] 添加错误处理
- [ ] 测试合并 API

## 9. 测试用例

### 9.1 功能测试

1. **正常合并**
   - 在详情页点击合并按钮
   - 选择目标词句组
   - 验证源词句组的词句已添加到目标词句组
   - 验证源词句组已删除
   - 验证页面自动切换到目标词句组

2. **合并到同一词句组**
   - 尝试将词句组合并到自己
   - 验证显示错误提示
   - 验证不发送请求

3. **权限测试**
   - 未登录用户尝试合并
   - 验证显示权限错误
   - 普通用户尝试合并其他用户的词句组
   - 验证显示权限错误
   - 管理员用户可以合并任何词句组

4. **网络错误**
   - 模拟网络中断
   - 验证显示网络错误提示
   - 验证模态框不关闭

### 9.2 性能测试

1. **大量词句合并**
   - 创建包含 100 个词句的词句组
   - 执行合并操作
   - 验证响应时间 < 2 秒

2. **并发合并**
   - 同时对同一词句组发起多个合并请求
   - 验证只执行一次合并
   - 验证其他请求返回冲突错误

## 10. 注意事项

1. **数据一致性**：所有数据库操作必须在事务中执行，确保原子性
2. **权限控制**：只有词句组的创建者或管理员可以执行合并操作
3. **用户体验**：合并操作不可逆，必须在界面中明确提示
4. **性能优化**：使用批量操作减少数据库往返次数
5. **缓存清理**：合并后清理相关缓存（statistics cache, heatmap cache）

## 11. 后续优化

1. **批量选择**：支持同时选择多个词句组进行批量合并
2. **合并历史**：记录词句组合并历史，支持撤销操作
3. **智能推荐**：根据词句相似度推荐合并目标词句组
4. **合并预览**：在合并前显示预览，展示合并后的词句组内容
