<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <!-- Header -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6">
      <div v-if="loadingInfo" class="animate-pulse space-y-4">
        <div class="h-8 bg-gray-200 rounded w-1/3"></div>
        <div class="h-4 bg-gray-200 rounded w-2/3"></div>
      </div>
      <div v-else>
        <div class="flex items-center gap-3">
          <h1 class="text-3xl font-bold text-gray-900">{{ languageName }}</h1>
          <span class="bg-blue-100 text-blue-800 text-sm px-3 py-1 rounded-full font-medium">
            {{ languageCode }}
          </span>
        </div>
      </div>
    </div>

    <!-- Search -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="`Search in ${languageName || languageCode}`"
        class="w-full border border-gray-300 rounded-lg px-4 py-2"
        @input="handleSearch"
      />
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
        :item="expr"
      />
    </div>

    <!-- Pagination -->
    <div v-if="currentPage > 0 && (currentPage > 1 || canGoNext)" class="mt-6 flex justify-center items-center gap-2">
      <button
        @click="prevPage"
        :disabled="currentPage === 1"
        class="px-3 py-2 border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
      >
        {{ $t('prev') }}
      </button>

      <div class="flex gap-1">
        <button
          v-for="page in displayedPages"
          :key="page"
          @click="goToPage(page)"
          :class="[
            'min-w-[2.5rem] px-3 py-2 rounded text-sm',
            typeof page === 'number'
              ? page === currentPage
                ? 'bg-blue-600 text-white hover:bg-blue-700'
                : 'hover:bg-gray-100 text-gray-700'
              : 'bg-transparent text-gray-400 cursor-default'
          ]"
        >
          {{ page }}
        </button>
      </div>

      <button
        @click="nextPage"
        :disabled="!canGoNext"
        class="px-3 py-2 border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed text-sm"
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
    const loadingInfo = ref(true)
    const expressions = ref([])
    const loading = ref(true)
    const total = ref(0)
    const currentPage = ref(1)
    const totalPages = ref(1)
    const searchQuery = ref('')
    const itemsPerPage = 20
    const hasMore = ref(false) // Track if there might be more items

    const fetchLanguageInfo = async () => {
      loadingInfo.value = true
      try {
        const response = await fetch('/api/v1/languages')
        const languages = await response.json()
        const language = languages.find(l => l.code === languageCode.value)
        if (language) {
          languageName.value = language.name
        }
      } catch (error) {
        console.error('Failed to fetch language info:', error)
      } finally {
        loadingInfo.value = false
      }
    }

    const fetchExpressions = async () => {
      loading.value = true
      try {
        const skip = (currentPage.value - 1) * itemsPerPage

        let url
        let useSearchAPI = false

        if (searchQuery.value && searchQuery.value.trim()) {
          // Use search API when there's a search query
          useSearchAPI = true
          url = `/api/v1/search?q=${encodeURIComponent(searchQuery.value.trim())}&from_lang=${languageCode.value}&skip=${skip}&limit=${itemsPerPage}`
        } else {
          // Use expressions API for browsing all expressions
          useSearchAPI = false
          url = `/api/v1/expressions?language=${languageCode.value}&skip=${skip}&limit=${itemsPerPage}`
        }

        console.log('Fetching expressions:', { url, currentPage: currentPage.value, skip, limit: itemsPerPage, searchQuery: searchQuery.value, useSearchAPI })

        const response = await fetch(url)
        const data = await response.json()

        console.log('API Response:', data)

        // Handle different response formats
        if (Array.isArray(data)) {
          expressions.value = data
          const itemCount = data.length

          if (itemCount === 0) {
            // Empty result
            total.value = skip
            hasMore.value = false
          } else if (itemCount < itemsPerPage) {
            // Got less than a full page, this is last page
            total.value = skip + itemCount
            hasMore.value = false
          } else {
            // Got exactly a full page, there might be more
            hasMore.value = true
            // Update total to at least what we've seen
            total.value = Math.max(total.value || 0, skip + itemCount)
          }
        } else if (data.results && Array.isArray(data.results)) {
          expressions.value = data.results
          total.value = data.total || data.results.length || 0
          hasMore.value = (data.results.length === itemsPerPage && (!data.total || data.total > skip + itemsPerPage))
        } else {
          expressions.value = []
          total.value = 0
          hasMore.value = false
        }

        // Calculate totalPages based on what we know
        if (hasMore.value) {
          // There might be more pages, show at least current + 1
          totalPages.value = currentPage.value + 1
        } else {
          // No more pages
          totalPages.value = currentPage.value
        }

        console.log('After fetch:', {
          expressionsCount: expressions.value.length,
          total: total.value,
          totalPages: totalPages.value,
          currentPage: currentPage.value,
          hasMore: hasMore.value
        })
      } catch (error) {
        console.error('Failed to fetch expressions:', error)
        expressions.value = []
        total.value = 0
        totalPages.value = 0
        hasMore.value = false
      } finally {
        loading.value = false
      }
    }

    const goToPage = (page) => {
      if (typeof page === 'number') {
        currentPage.value = page
        fetchExpressions()
      }
    }

    const handleSearch = debounce(() => {
      currentPage.value = 1
      fetchExpressions()
    }, 300)

    const nextPage = () => {
      if (canGoNext.value) {
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

    const canGoNext = computed(() => {
      return hasMore.value || currentPage.value < totalPages.value
    })

    const displayedPages = computed(() => {
      const pages = []
      const maxDisplayed = 7

      // If there might be more pages, treat it as if totalPages is at least current + 1
      const effectiveTotalPages = hasMore.value ? Math.max(totalPages.value, currentPage.value + 1) : totalPages.value

      if (effectiveTotalPages <= maxDisplayed) {
        for (let i = 1; i <= effectiveTotalPages; i++) {
          pages.push(i)
        }
      } else {
        if (currentPage.value <= 4) {
          for (let i = 1; i <= 5; i++) pages.push(i)
          if (hasMore.value || effectiveTotalPages > 5) {
            pages.push('...')
            pages.push(effectiveTotalPages)
          }
        } else if (currentPage.value >= effectiveTotalPages - 3) {
          pages.push(1)
          pages.push('...')
          for (let i = effectiveTotalPages - 4; i <= effectiveTotalPages; i++) pages.push(i)
        } else {
          pages.push(1)
          pages.push('...')
          for (let i = currentPage.value - 1; i <= currentPage.value + 1; i++) pages.push(i)
          if (hasMore.value || effectiveTotalPages > currentPage.value + 2) {
            pages.push('...')
            pages.push(effectiveTotalPages)
          }
        }
      }

      return pages
    })

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
      loadingInfo,
      expressions,
      loading,
      total,
      currentPage,
      totalPages,
      searchQuery,
      displayedPages,
      canGoNext,
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
