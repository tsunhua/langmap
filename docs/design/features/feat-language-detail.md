# 语言页面功能设计

## System Reminder

**实现状态**：
- ✅ 后端 API 已存在 - `GET /api/v1/expressions` 支持 `language` 参数
- ✅ 数据库查询支持 - `getExpressions()` 方法支持按语言过滤
- ⏳ 前端语言页面 - 未实现
- ⏳ 语言详情路由 - 需要添加

**已实现的 API 端点**：
- `GET /api/v1/expressions?language=...&skip=...&limit=...` - 获取表达列表（支持按语言过滤）
- `GET /api/v1/languages` - 获取语言列表

---

## 概述

语言页面允许用户查看特定语言的所有词条，提供语言级别的浏览和导航功能。用户可以通过 `/languages/:code` 路径访问（如 `/languages/zh-CN`），查看该语言的所有表达式，并支持分页和搜索过滤。

## 数据模型

### Language（语言）

```typescript
interface Language {
  id: number
  code: string              // 语言代码，如 'zh-CN', 'en-US'
  name: string              // 语言名称，如 '简体中文', 'English'
  is_active: boolean        // 是否激活
  created_by: string
  created_at: string
}
```

### Expression（词条）

现有字段，按 `language_code` 过滤：

```typescript
interface Expression {
  id: number
  text: string
  meaning_id?: number
  audio_url?: string
  language_code: string      // 按此字段过滤
  region_code?: string
  region_name?: string
  tags?: string
  source_type?: string
  review_status?: string
  created_by?: string
  created_at?: string
}
```



## API 设计

### GET /api/v1/expressions?language=:code&skip=:skip&limit=:limit

获取指定语言的词条列表（现有接口）。

**查询参数**：
- `language` (string) - 语言代码（必需，如 'zh-CN'）
- `skip` (number) - 跳过数量（默认 0）
- `limit` (number) - 返回数量限制（默认 20）

**响应**：
```json
{
  "results": [
    {
      "id": 1,
      "text": "你好",
      "language_code": "zh-CN",
      "meaning_id": 123,
      "region_code": null,
      "region_name": null,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 125,
  "skip": 0,
  "limit": 20
}
```



## 前端实现

### 路由配置

在 `web/src/router/index.js` 中添加：

```javascript
{
  path: '/languages/:code',
  name: 'LanguageDetail',
  component: () => import('../pages/LanguageDetail.vue'),
  props: true
}
```

### LanguageDetail.vue 页面

**页面结构**：

```
┌──────────────────────────────────────────────────┐
│  Language Header                                 │
│  [Back]  中文 (zh-CN)                            │
│  统计信息：1,250 词条 · 85.5% 覆盖率             │
└──────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────┐
│  Search & Filter                                 │
│  [Search] [Sort: 最新]  [Filter]                │
└──────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────┐
│  Expressions List                                │
│  ┌────────────────────────────────────────────┐ │
│  │ 你好                                      │ │
│  │ [zh-CN] [地域] [音频] [标签]             │ │
│  └────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────┐ │
│  │ 世界                                      │ │
│  └────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────┐
│  Pagination                                      │
│  [Previous] 1 2 3 ... 10 [Next]                 │
└──────────────────────────────────────────────────┘
```

**主要功能**：

1. **头部信息**
   - 语言名称和代码
   - 返回首页按钮
   - 分享按钮

2. **搜索和过滤**
   - 搜索框：在当前语言内搜索词条
   - 排序选项：最新、最早、按拼音/字母
   - 过滤选项：带音频、带地域、按地域过滤

3. **词条列表**
   - 显示词条文本
   - 显示语言标签
   - 显示地域信息（如果有）
   - 音频播放按钮（如果有）
   - 标签显示
   - 点击跳转到详情页

4. **分页**
   - 上一页/下一页
   - 页码导航
   - 跳转到指定页

**实现示例**：

```vue
<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <!-- Header -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
      <div class="flex items-center gap-3 mb-4">
        <router-link to="/" class="text-gray-500 hover:text-gray-700">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
        </router-link>
        <div>
          <h1 class="text-3xl font-bold text-gray-900">
            {{ languageName }} ({{ languageCode }})
          </h1>
        </div>
      </div>

    </div>

    <!-- Search & Filter -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
      <div class="flex flex-col sm:flex-row gap-4">
        <div class="flex-grow">
          <input
            v-model="searchQuery"
            type="text"
            :placeholder="$t('search_in_language', { lang: languageName })"
            class="w-full border border-gray-300 rounded-lg px-4 py-2"
            @input="handleSearch"
          />
        </div>
        <div class="flex gap-2">
          <select v-model="sortBy" @change="fetchExpressions" class="border border-gray-300 rounded-lg px-3 py-2">
            <option value="newest">{{ $t('sort_newest') }}</option>
            <option value="oldest">{{ $t('sort_oldest') }}</option>
            <option value="text">{{ $t('sort_text') }}</option>
          </select>
        </div>
      </div>
    </div>

    <!-- Expressions List -->
    <div v-if="loading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
    </div>

    <div v-else-if="expressions.length === 0" class="text-center py-12 bg-gray-50 rounded-lg border border-gray-200">
      <p class="text-gray-500">{{ $t('no_expressions_found') }}</p>
    </div>

    <div v-else class="space-y-4">
      <ExpressionCard
        v-for="expr in expressions"
        :key="expr.id"
        :expression="expr"
      />
    </div>

    <!-- Pagination -->
    <div v-if="totalPages > 1" class="mt-6 flex justify-center items-center gap-2">
      <button
        @click="prevPage"
        :disabled="currentPage === 1"
        class="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50"
      >
        {{ $t('previous') }}
      </button>

      <div class="flex gap-1">
        <button
          v-for="page in displayedPages"
          :key="page"
          @click="goToPage(page)"
          :class="[
            'px-3 py-1 rounded',
            page === currentPage ? 'bg-blue-600 text-white' : 'hover:bg-gray-100'
          ]"
        >
          {{ page }}
        </button>
      </div>

      <button
        @click="nextPage"
        :disabled="currentPage === totalPages"
        class="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50"
      >
        {{ $t('next') }}
      </button>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import ExpressionCard from '../components/ExpressionCard.vue'

export default {
  name: 'LanguageDetail',
  components: { ExpressionCard },
  props: {
    code: {
      type: String,
      required: true
    }
  },
  setup(props) {
    const route = useRoute()
    const router = useRouter()
    const { t } = useI18n()

    const languageCode = computed(() => props.code || route.params.code)
    const languageName = ref('')
    const expressions = ref([])
    const loading = ref(true)
    const currentPage = ref(1)
    const totalPages = ref(1)
    const searchQuery = ref('')
    const sortBy = ref('newest')
    const itemsPerPage = 20

    const fetchLanguageInfo = async () => {
      try {
        // 获取语言信息
        const response = await fetch('/api/v1/languages')
        const languages = await response.json()
        const language = languages.find(l => l.code === languageCode.value)
        if (language) {
          languageName.value = language.name
        }
      } catch (error) {
        console.error('Failed to fetch language info:', error)
      }
    }

    const fetchExpressions = async () => {
      loading.value = true
      try {
        const skip = (currentPage.value - 1) * itemsPerPage
        let url = `/api/v1/expressions?language=${languageCode.value}&skip=${skip}&limit=${itemsPerPage}`

        // 搜索过滤
        if (searchQuery.value) {
          url += `&q=${encodeURIComponent(searchQuery.value)}`
        }

        // 排序
        const response = await fetch(url)
        const data = await response.json()
        expressions.value = data.results || data
        totalPages.value = Math.ceil((data.total || data.length) / itemsPerPage)
      } catch (error) {
        console.error('Failed to fetch expressions:', error)
      } finally {
        loading.value = false
      }
    }

    const handleSearch = debounce(() => {
      currentPage.value = 1
      fetchExpressions()
    }, 300)

    const nextPage = () => {
      if (currentPage.value < totalPages.value) {
        currentPage.value++
        fetchExpressions()
      }
    }

    const prevPage = () => {
      if (currentPage.value > 1) {
        currentPage.value--
        fetchExpressions()
      }
    }

    const goToPage = (page) => {
      currentPage.value = page
      fetchExpressions()
    }

    const displayedPages = computed(() => {
      const pages = []
      const maxDisplayed = 7

      if (totalPages.value <= maxDisplayed) {
        for (let i = 1; i <= totalPages.value; i++) {
          pages.push(i)
        }
      } else {
        if (currentPage.value <= 4) {
          for (let i = 1; i <= 5; i++) pages.push(i)
          pages.push('...')
          pages.push(totalPages.value)
        } else if (currentPage.value >= totalPages.value - 3) {
          pages.push(1)
          pages.push('...')
          for (let i = totalPages.value - 4; i <= totalPages.value; i++) pages.push(i)
        } else {
          pages.push(1)
          pages.push('...')
          for (let i = currentPage.value - 1; i <= currentPage.value + 1; i++) pages.push(i)
          pages.push('...')
          pages.push(totalPages.value)
        }
      }

      return pages
    })

    // 防抖函数
    function debounce(func, wait) {
      let timeout
      return function executedFunction(...args) {
        const later = () => {
          clearTimeout(timeout)
          func(...args)
        }
        clearTimeout(timeout)
        timeout = setTimeout(later, wait)
      }
    }

    onMounted(() => {
      fetchLanguageInfo()
      fetchExpressions()
    })

    return {
      languageCode,
      languageName,
      expressions,
      loading,
      currentPage,
      totalPages,
      searchQuery,
      sortBy,
      displayedPages,
      fetchExpressions,
      handleSearch,
      nextPage,
      prevPage,
      goToPage,
      t
    }
  }
}
</script>
```

## 用户界面设计

### 页面布局

```
┌─────────────────────────────────────────────────────┐
│  [←] 中文 (zh-CN)                    [📤 Share]     │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│  [🔍 Search in 中文...]  [Sort: ▼ Newest]          │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│  Expressions (1,250)                                │
│  ┌───────────────────────────────────────────────┐ │
│  │ 你好                                          │ │
│  │ [zh-CN] [🔊] [📍 北京] [langmap.intro]       │ │
│  │ Added by user123 · 2024-02-15                 │ │
│  └───────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────┐ │
│  │ 世界                                          │ │
│  │ [zh-CN] [🔊]                                  │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│  [◀ Previous] 1 2 3 ... 63 [Next ▶]               │
└─────────────────────────────────────────────────────┘
```

### 交互流程

1. **进入页面**
   - 用户点击语言链接或输入 URL `/languages/zh-CN`
   - 页面加载语言信息
   - 加载第一页词条列表

2. **搜索词条**
   - 用户在搜索框输入关键词
   - 实时过滤当前语言的词条
   - 显示匹配结果

3. **排序和过滤**
   - 用户选择排序方式（最新/最早/按文本）
   - 页面重新排序显示

4. **浏览词条**
   - 用户点击词条卡片
   - 跳转到词条详情页 `/detail/:id`

5. **分页浏览**
   - 用户点击分页按钮
   - 加载对应页的词条

## 性能优化

### 后端优化

- **边缘缓存**：对语言统计和热门语言词条列表使用 L2 缓存
- **数据库索引**：确保 `language_code` 字段有索引
- **分页查询**：使用 LIMIT 和 OFFSET 避免一次性返回过多数据

### 前端优化

- **虚拟滚动**：如果词条数量很大，考虑使用虚拟滚动
- **防抖搜索**：搜索输入防抖，减少 API 调用
- **缓存策略**：缓存已加载的页码数据

## 国际化

需要添加的翻译键：

```json
{
  "language_detail": "语言详情",
  "search_in_language": "在 {lang} 中搜索",
  "sort_newest": "最新",
  "sort_oldest": "最早",
  "sort_text": "按文本排序",
  "no_expressions_found": "未找到词条",
  "previous": "上一页",
  "next": "下一页"
}
```

## 相关文档

- [搜索功能设计](./feat-search.md)
- [后端 API 指南](../../api/backend-guide.md)
- [系统架构设计](../system/architecture.md)
