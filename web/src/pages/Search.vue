<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSearch } from '@/composables/useSearch'
import ExpressionRow from '@/components/expression/ExpressionRow.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import LanguageSelect from '@/components/language/LanguageSelect.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import Pagination from '@/components/ui/Pagination.vue'
import { useI18n } from 'vue-i18n'

const route = useRoute()
const { search } = useSearch()
const { t } = useI18n()

const PAGE = 20
const query = ref((route.query.q as string) || '')
const langs = ref<string[]>([])
const sortBy = ref('hot')
const results = ref<any[]>([])
const total = ref(0)
const loading = ref(false)
const loadingMore = ref(false)
const searched = ref(false)
const loadError = ref('')

let debounceTimer: ReturnType<typeof setTimeout> | null = null

async function doSearch() {
  if (debounceTimer) { clearTimeout(debounceTimer); debounceTimer = null }
  if (!query.value.trim()) {
    results.value = []
    total.value = 0
    searched.value = false
    return
  }
  loading.value = true
  loadError.value = ''
  try {
    const data = await search(query.value, {
      lang: langs.value[0],
      limit: PAGE,
      offset: 0,
    })
    results.value = data.items
    total.value = data.total
    searched.value = true
  } catch (e: any) {
    loadError.value = e.response?.data?.error || t('search.loadFailed')
  } finally {
    loading.value = false
  }
}

async function loadMore() {
  if (loadingMore.value || results.value.length >= total.value) return
  loadingMore.value = true
  try {
    const data = await search(query.value, {
      lang: langs.value[0],
      limit: PAGE,
      offset: results.value.length,
    })
    results.value = results.value.concat(data.items)
  } catch {
    // keep existing results on load-more failure
  } finally {
    loadingMore.value = false
  }
}

// Debounced search on query input.
watch(query, () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(doSearch, 300)
})

// Re-search immediately when sort or language filter changes (only after a search has started).
watch([sortBy, langs], () => { if (searched.value) doSearch() })

onMounted(() => {
  if (query.value) doSearch()
})
</script>

<template>
  <div class="se-page">
    <div class="se-hero">
      <h1>{{ t('search.title') }}</h1>
      <div class="se-qrow">
        <SearchBar v-model="query" :placeholder="t('search.placeholder')" :large="true" @search="doSearch" />
        <LanguageSelect v-model="langs" />
      </div>
    </div>

    <div v-if="searched || loading" class="se-meta">
      <span class="se-count">{{ t('search.results', { count: total }) }}</span>
      <div class="se-sort" role="group" :aria-label="t('search.sort')">
        <button :class="{ on: sortBy === 'hot' }" @click="sortBy = 'hot'">{{ t('search.popular') }}</button>
        <button :class="{ on: sortBy === 'new' }" @click="sortBy = 'new'">{{ t('search.newest') }}</button>
        <button :class="{ on: sortBy === 'alpha' }" @click="sortBy = 'alpha'">{{ t('search.alphabetical') }}</button>
      </div>
    </div>

    <LoadingSpinner v-if="loading" />

    <EmptyState v-else-if="loadError" :message="loadError" />

    <EmptyState v-else-if="searched && results.length === 0" :message="t('search.noResults')" />

    <template v-else-if="results.length">
      <div class="se-list">
        <ExpressionRow
          v-for="r in results"
          :key="r.id"
          v-bind="r"
        />
      </div>
      <Pagination :has-more="results.length < total" @load-more="loadMore" />
      <p v-if="loadingMore" class="se-more" role="status">{{ t('common.loading') }}</p>
    </template>

    <p v-else class="se-hint">{{ t('search.hint') }}</p>
  </div>
</template>

<style scoped>
.se-page { max-width: 900px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.se-hero { margin-bottom: var(--space-md); }
.se-hero h1 { font-size: 22px; font-weight: 600; letter-spacing: -0.02em; margin-bottom: var(--space-base); }
.se-qrow { display: flex; gap: 12px; flex-wrap: wrap; align-items: center; }
.se-qrow > :first-child { flex: 1; min-width: 0; }
.se-meta { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px; margin-bottom: 14px; }
.se-count { font-family: var(--mono); font-size: 11px; color: var(--muted); }
.se-count b { color: var(--fg); font-weight: 500; }
.se-sort { display: inline-flex; border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; }
.se-sort button { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; border: none; background: var(--surface); color: var(--muted); cursor: pointer; height: 30px; padding: 0 16px; transition: background 0.15s, color 0.15s; }
.se-sort button:hover { color: var(--fg); }
.se-sort button.on { background: var(--fg); color: var(--surface); }
.se-list { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
.se-more { text-align: center; padding: 8px; font-size: 13px; color: var(--muted); }
.se-hint { font-family: var(--mono); font-size: 10px; text-align: center; padding: var(--space-xl); color: var(--faint); }
</style>
