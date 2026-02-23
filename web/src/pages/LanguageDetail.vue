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
           <div class="relative" ref="languageDropdownContainer">
             <button
               @click.stop="toggleLanguageDropdown"
               class="flex items-center gap-2 group"
             >
               <h1 class="text-3xl font-bold text-gray-900 group-hover:text-blue-600 transition-colors">{{ languageName }}</h1>
               <span class="bg-blue-100 text-blue-800 text-sm px-3 py-1 rounded-full font-medium">
                 {{ languageCode }}
               </span>
               <svg
                 :class="['w-5 h-5 text-gray-500 transition-transform duration-200', showLanguageDropdown ? 'rotate-180' : '']"
                 xmlns="http://www.w3.org/2000/svg"
                 fill="none"
                 viewBox="0 0 24 24"
                 stroke="currentColor"
               >
                 <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
               </svg>
             </button>

             <!-- Language Dropdown -->
             <div v-if="showLanguageDropdown" class="absolute top-full left-0 mt-2 w-64 bg-white rounded-lg shadow-lg border border-gray-200 z-50 max-h-96 overflow-y-auto">
               <div v-if="loadingLanguages" class="flex justify-center items-center py-4">
                 <div class="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
               </div>
               <div v-else class="py-2">
                 <button
                   v-for="lang in allLanguages"
                   :key="lang.code"
                   @click.stop="selectLanguage(lang.code)"
                   :class="[
                     'w-full text-left px-4 py-2 hover:bg-gray-100 transition-colors flex items-center justify-between',
                     lang.code === languageCode ? 'bg-blue-50 text-blue-700' : 'text-gray-700'
                   ]"
                 >
                   <span>{{ lang.name }}</span>
                   <span class="text-sm text-gray-500">{{ lang.code }}</span>
                 </button>
               </div>
             </div>
           </div>
         </div>
      </div>
    </div>

    <!-- Search -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 mb-6">
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="`Search in ${languageName || languageCode}`"
        class="w-full border border-gray-300 rounded-lg px-4 py-2 mb-3"
        @input="handleSearch"
      />

      <!-- Tag Filters -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">包含标签</label>
          <input
            v-model="tagPrefix"
            type="text"
            placeholder="eg: langmap"
            class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
            @input="handleFilterChange"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">排除标签</label>
          <input
            v-model="excludeTagPrefix"
            type="text"
            placeholder="eg: langmap"
            class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
            @input="handleFilterChange"
          />
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

    const languageCode = computed(() => route.params.code)
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
    const tagPrefix = ref('')
    const excludeTagPrefix = ref('')

    // Language dropdown state
    const showLanguageDropdown = ref(false)
    const allLanguages = ref([])
    const loadingLanguages = ref(false)
    const languageDropdownContainer = ref(null)

    const fetchLanguageInfo = async () => {
      loadingInfo.value = true
      try {
        const response = await fetch('/api/v1/languages')
        const languages = await response.json()
        const language = languages.find(l => l.code === languageCode.value)
        if (language) {
          languageName.value = language.name
        }
        // Store all languages for dropdown
        allLanguages.value = languages
      } catch (error) {
        console.error('Failed to fetch language info:', error)
      } finally {
        loadingInfo.value = false
      }
    }

    const toggleLanguageDropdown = () => {
      showLanguageDropdown.value = !showLanguageDropdown.value
    }

    const selectLanguage = (langCode) => {
      if (langCode !== languageCode.value) {
        router.push(`/languages/${langCode}`)
      }
      showLanguageDropdown.value = false
    }

    // Close dropdown when clicking outside
    onMounted(() => {
      const handleClickOutside = (event) => {
        if (showLanguageDropdown.value && languageDropdownContainer.value) {
          if (!languageDropdownContainer.value.contains(event.target)) {
            showLanguageDropdown.value = false
          }
        }
      }
      document.addEventListener('click', handleClickOutside)
      return () => {
        document.removeEventListener('click', handleClickOutside)
      }
    })

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
          if (tagPrefix.value) {
            url += `&tag=${encodeURIComponent(tagPrefix.value)}`
          }
          if (excludeTagPrefix.value) {
            url += `&exclude_tag=${encodeURIComponent(excludeTagPrefix.value)}`
          }
        }

        console.log('Fetching expressions:', { url, currentPage: currentPage.value, skip, limit: itemsPerPage, searchQuery: searchQuery.value, tagPrefix: tagPrefix.value, excludeTagPrefix: excludeTagPrefix.value, useSearchAPI })

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
    }, 600)

    const handleFilterChange = debounce(() => {
      currentPage.value = 1
      fetchExpressions()
    }, 400)

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

    // Watch for language code changes to fetch new language data
    watch(languageCode, (newCode, oldCode) => {
      console.log('Language code changed:', { oldCode, newCode })
      if (newCode && newCode !== oldCode) {
        // Reset search, filters, pagination and expressions
        searchQuery.value = ''
        tagPrefix.value = ''
        excludeTagPrefix.value = ''
        currentPage.value = 1
        expressions.value = []
        // Fetch new language info and expressions
        fetchLanguageInfo()
        fetchExpressions()
      }
    })

    // Watch for language name changes to update document title
    watch(languageName, (newName) => {
      if (newName) {
        document.title = `${newName} (${languageCode.value}) - LangMap`
      }
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
      tagPrefix,
      excludeTagPrefix,
      displayedPages,
      canGoNext,
      fetchExpressions,
      handleSearch,
      handleFilterChange,
      nextPage,
      prevPage,
      goToPage,
      showLanguageDropdown,
      allLanguages,
      loadingLanguages,
      languageDropdownContainer,
      toggleLanguageDropdown,
      selectLanguage,
      t
    }
  }
}
</script>
