# 語言頁面功能設計

## System Reminder

**實現狀態**：
- ✅ 後端 API 已存在 - `GET /api/v1/expressions` 支持 `language` 參數
- ✅ 數據庫查詢支持 - `getExpressions()` 方法支持按語言過濾
- ⏳ 前端語言頁面 - 未實現
- ⏳ 語言詳情路由 - 需要添加

**已實現的 API 端點**：
- `GET /api/v1/expressions?lang=...&skip=...&limit=...` - 獲取表達列表（支持按語言過濾）
- `GET /api/v1/languages` - 獲取語言列表

---

## 概述

語言頁面允許用戶查看特定語言的所有詞條，提供語言級別的瀏覽和導航功能。用戶可以通過 `/languages/:code` 路徑訪問（如 `/languages/zh-CN`），查看該語言的所有表達式，並支持分頁和搜索過濾。

## 數據模型

### Language（語言）

```typescript
interface Language {
  id: number
  code: string              // 語言代碼，如 'zh-CN', 'en-US'
  name: string              // 語言名稱，如 '簡體中文', 'English'
  is_active: boolean        // 是否激活
  created_by: string
  created_at: string
}
```

### Expression（詞條）

現有字段，按 `language_code` 過濾：

```typescript
interface Expression {
  id: number
  text: string
  meaning_id?: number
  audio_url?: string
  language_code: string      // 按此字段過濾
  region_code?: string
  region_name?: string
  tags?: string
  source_type?: string
  review_status?: string
  created_by?: string
  created_at?: string
}
```



## API 設計

### GET /api/v1/expressions?lang=:code&skip=:skip&limit=:limit

獲取指定語言的詞條列表（現有接口）。

**查詢參數**：
- `language` (string) - 語言代碼（必需，如 'zh-CN'）
- `skip` (number) - 跳過數量（默認 0）
- `limit` (number) - 返回數量限制（默認 20）

**響應**：
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



## 前端實現

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

### LanguageDetail.vue 頁面

**頁面結構**：

```
┌──────────────────────────────────────────────────┐
│  Language Header                                 │
│  [Back]  中文 (zh-CN)                            │
│  統計信息：1,250 詞條 · 85.5% 覆蓋率             │
└──────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────┐
│  Search & Filter                                 │
│  [Search] [Sort: 最新]  [Filter]                │
└──────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────┐
│  Expressions List                                │
│  ┌────────────────────────────────────────────┐ │
│  │ 你好                                      │ │
│  │ [zh-CN] [地域] [音頻] [標籤]             │ │
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

1. **頭部信息**
   - 語言名稱和代碼
   - 返回首頁按鈕
   - 分享按鈕

2. **搜索和過濾**
   - 搜索框：在當前語言內搜索詞條
   - 排序選項：最新、最早、按拼音/字母
   - 過濾選項：帶音頻、帶地域、按地域過濾

3. **詞條列表**
   - 顯示詞條文本
   - 顯示語言標籤
   - 顯示地域信息（如果有）
   - 音頻播放按鈕（如果有）
   - 標籤顯示
   - 點擊跳轉到詳情頁

4. **分頁**
   - 上一頁/下一頁
   - 頁碼導航
   - 跳轉到指定頁

**實現示例**：

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
        // 獲取語言信息
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
        let url = `/api/v1/expressions?lang=${languageCode.value}&skip=${skip}&limit=${itemsPerPage}`

        // 搜索過濾
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

    // 防抖函數
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

## 用戶界面設計

### 頁面布局

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

1. **進入頁面**
   - 用戶點擊語言鏈接或輸入 URL `/languages/zh-CN`
   - 頁面加載語言信息
   - 加載第一頁詞條列表

2. **搜索詞條**
   - 用戶在搜索框輸入關鍵詞
   - 實時過濾當前語言的詞條
   - 顯示匹配結果

3. **排序和過濾**
   - 用戶選擇排序方式（最新/最早/按文本）
   - 頁面重新排序顯示

4. **瀏覽詞條**
   - 用戶點擊詞條卡片
   - 跳轉到詞條詳情頁 `/detail/:id`

5. **分頁瀏覽**
   - 用戶點擊分頁按鈕
   - 加載對應頁的詞條

## 性能優化

### 後端優化

- **邊緣緩存**：對語言統計和熱門語言詞條列表使用 L2 緩存
- **數據庫索引**：確保 `language_code` 字段有索引
- **分頁查詢**：使用 LIMIT 和 OFFSET 避免一次性返回過多數據

### 前端優化

- **虛擬滾動**：如果詞條數量很大，考慮使用虛擬滾動
- **防抖搜索**：搜索輸入防抖，減少 API 調用
- **緩存策略**：緩存已加載的頁碼數據

## 國際化

需要添加的翻譯鍵：

```json
{
  "language_detail": "語言詳情",
  "search_in_language": "在 {lang} 中搜索",
  "sort_newest": "最新",
  "sort_oldest": "最早",
  "sort_text": "按文本排序",
  "no_expressions_found": "未找到詞條",
  "previous": "上一頁",
  "next": "下一頁"
}
```

## 相關文檔

- [搜索功能設計](./feat-search.md)
- [後端 API 指南](../../api/backend-guide.md)
- [系統架構設計](../system/architecture.md)
