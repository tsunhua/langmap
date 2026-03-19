<template>
  <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 py-4 sm:py-8">
    <div class="bg-white rounded-xl shadow-sm border border-slate-200 p-6 mb-8">
      <h2 class="text-2xl font-bold text-slate-800 mb-2">{{ $t('search_expressions') }}</h2>
      <p class="text-slate-600 mb-6">{{ $t('search_expressions_desc') }}</p>

      <div class="flex gap-3">
        <div class="flex-1">
          <input v-model="q" :placeholder="$t('placeholder')"
            class="w-full rounded-lg border border-slate-400 shadow-sm focus:border-blue-500 focus:ring focus:ring-blue-200 focus:ring-opacity-50 py-3 px-4 text-lg"
            @keydown.enter="search" />
        </div>
        <button @click="search"
          class="inline-flex items-center justify-center rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-3 sm:px-6 py-3">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
              d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <span class="hidden sm:inline ml-2">{{ $t('search') }}</span>
        </button>
      </div>
    </div>

    <!-- Add Expression Modal -->
    <CreateExpression :visible="showCreateModal" :initial-text="q" @close="showCreateModal = false"
      @created="handleExpressionCreated" />

    <div v-if="loading" class="flex items-center justify-center py-12">
      <svg class="animate-spin h-6 w-6 text-blue-500" xmlns="http://www.w3.org/2000/svg" fill="none"
        viewBox="0 0 24 24">
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
        <path class="opacity-75" fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z">
        </path>
      </svg>
      <span class="ml-2 text-slate-600">{{ $t('searching') }}</span>
    </div>

    <div v-else-if="hasSearched" class="space-y-6">
      <div v-if="items.length === 0" class="bg-white rounded-xl shadow-sm border border-slate-200 p-8 text-center">
        <h3 class="text-xl font-semibold text-slate-800 mb-2">{{ $t('no_results') }}</h3>
        <p class="text-slate-600 mb-6">{{ $t('try_different') }}</p>
        <button @click="showCreateModal = true"
          class="inline-flex items-center justify-center rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 px-6 py-2">
          {{ $t('add_expression', { expression: q || $t('new_expression') }) }}
        </button>
      </div>

      <div v-else>
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-slate-800">
            {{ $t('found_expressions', { count: items_length, plural: items_length !== 1 ? $t('plural') : '' }) }}
          </h3>
        </div>

        <div class="space-y-4">
          <ExpressionCard v-for="item in items" :key="item.id" :item="item" />
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import { ref, watch, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import ExpressionCard from '../components/ExpressionCard.vue'
import CreateExpression from '../components/CreateExpression.vue'

export default {
  name: 'Search',
  components: { ExpressionCard, CreateExpression },
  setup() {
    const route = useRoute()
    const router = useRouter()
    const { t } = useI18n()
    const q = ref('')
    const items = ref([])
    const loading = ref(false)
    const hasSearched = ref(false)
    const showCreateModal = ref(false)
    const items_length = computed(() => items.value.length)

    async function search() {
      // Don't trigger search if query is empty
      if (!q.value || q.value.trim() === '') {
        return
      }

      // 更新URL查询参数
      router.replace({ name: 'Search', query: { q: q.value } })

      hasSearched.value = true
      loading.value = true
      try {
        const params = new URLSearchParams()
        if (q.value) params.set('q', q.value)
        // no language selector in MVP; server will return cross-language matches via meanings
        const res = await fetch(`/api/v1/search?${params.toString()}`)
        if (!res.ok) throw new Error('search failed')
        const response = await res.json()
        // 适配新的API响应格式 { success, data }
        items.value = response.data || response || []
      } catch (e) {
        console.error(e)
        items.value = []
      } finally {
        loading.value = false
      }
    }

    function handleExpressionCreated(expression) {
      showCreateModal.value = false
      // Optionally refresh the search or redirect
      search()
    }

    // Watch for route query changes
    watch(() => route.query, (newQuery) => {
      if (newQuery.q) {
        q.value = newQuery.q
        search()
      }
    }, { immediate: true })

    return { q, items, loading, hasSearched, search, t, showCreateModal, handleExpressionCreated, items_length }
  }
}
</script>