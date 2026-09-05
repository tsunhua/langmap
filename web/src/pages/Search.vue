<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSearch } from '@/composables/useSearch'
import { apiErrorMessage } from '@/utils/apiError'
import ExpressionRow from '@/components/expression/ExpressionRow.vue'
import ExpressionSearchControls from '@/components/search/ExpressionSearchControls.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import Pagination from '@/components/ui/Pagination.vue'
import { useI18n } from 'vue-i18n'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { useLocalizationStore } from '@/stores/localization'
import { useSearchLanguages } from '@/composables/useSearchLanguages'
import type { SearchFormOf } from '@/api/expressions'

const route = useRoute()
const router = useRouter()
const { search } = useSearch()
const { t } = useI18n()
const localeParams = useLocaleParams()
const localization = useLocalizationStore()
const searchLanguages = useSearchLanguages()

const PAGE = 20
interface SearchResult {
  id: string
  text: string
  lang_code: string
  language_name?: string
  mapping_count?: number
  source_type?: string
  region_name?: string
  form_of?: SearchFormOf[]
}
const routeQueryValue = (value: unknown): string => typeof value === 'string' ? value : ''
const query = ref(routeQueryValue(route.query.q))
const language = ref(routeQueryValue(route.query.lang))
const results = ref<SearchResult[]>([])
const total = ref(0)
const loading = ref(false)
const loadingMore = ref(false)
const searched = ref(false)
const loadError = ref('')
const loadMoreError = ref('')
const languageMissing = ref(false)

let debounceTimer: ReturnType<typeof setTimeout> | null = null
let searchRequest = 0
let initialized = false
let skipNextQueryWatch = false
let skipNextLanguageWatch = false
let expectedRoute: { q: string; lang: string } | null = null

function syncUrl() {
  const params: Record<string, string> = {}
  const q = query.value.trim()
  if (q) params.q = q
  if (language.value) params.lang = language.value
  expectedRoute = { q, lang: language.value }
  void router.replace({ query: params })
}

async function doSearch(options: { syncUrl?: boolean } = {}) {
  const shouldSyncUrl = options.syncUrl ?? true
  if (debounceTimer) { clearTimeout(debounceTimer); debounceTimer = null }
  if (!query.value.trim()) {
    searchRequest += 1
    results.value = []
    total.value = 0
    searched.value = false
    loadError.value = ''
    loadMoreError.value = ''
    languageMissing.value = false
    if (shouldSyncUrl) syncUrl()
    return
  }
  if (!language.value) {
    searchRequest += 1
    loading.value = false
    searched.value = false
    languageMissing.value = Boolean(query.value.trim())
    loadError.value = ''
    loadMoreError.value = ''
    results.value = []
    total.value = 0
    if (shouldSyncUrl) syncUrl()
    return
  }
  languageMissing.value = false
  const request = ++searchRequest
  const requestedQuery = query.value.trim()
  loading.value = true
  loadError.value = ''
  loadMoreError.value = ''
  const requestedLanguage = language.value
  try {
    const data = await search(requestedQuery, {
      lang: requestedLanguage,
      limit: PAGE,
      offset: 0,
      ...localeParams.value,
    })
    if (request !== searchRequest) return
    results.value = data.items
    total.value = data.total
    searched.value = true
    if (shouldSyncUrl) syncUrl()
  } catch (e: unknown) {
    if (request !== searchRequest) return
    loadError.value = apiErrorMessage(e, t('search.loadFailed'))
  } finally {
    if (request === searchRequest) loading.value = false
  }
}

function onFormSubmit() {
  void doSearch()
}

async function loadMore() {
  if (loadingMore.value || results.value.length >= total.value || !language.value) return
  const request = searchRequest
  const requestedQuery = query.value.trim()
  const requestedLanguage = language.value
  const offset = results.value.length
  loadingMore.value = true
  loadMoreError.value = ''
  try {
    const data = await search(requestedQuery, {
      lang: requestedLanguage,
      limit: PAGE,
      offset,
      ...localeParams.value,
    })
    if (request !== searchRequest) return
    results.value = results.value.concat(data.items)
    total.value = data.total
  } catch (e: unknown) {
    if (request !== searchRequest) return
    loadMoreError.value = apiErrorMessage(e, t('search.loadMoreFailed'))
  } finally {
    if (request === searchRequest) loadingMore.value = false
  }
}

// Debounced search on query input.
watch(query, () => {
  if (skipNextQueryWatch) {
    skipNextQueryWatch = false
    return
  }
  if (!initialized) return
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => { void doSearch() }, 300)
})

// Re-search immediately when language filter changes (only after a search has started).
watch(language, () => {
  if (skipNextLanguageWatch) {
    skipNextLanguageWatch = false
    return
  }
  if (!initialized) return
  languageMissing.value = false
  syncUrl()
  if (searched.value || query.value.trim()) void doSearch()
})

// Sync state back when the URL changes externally (back/forward, typed URL).
watch(() => route.query, (next) => {
  if (!initialized) return
  const urlQ = typeof next.q === 'string' ? next.q : ''
  const urlLang = typeof next.lang === 'string' ? next.lang : ''
  if (expectedRoute && expectedRoute.q === urlQ && expectedRoute.lang === urlLang) {
    expectedRoute = null
    return
  }
  expectedRoute = null
  const resolvedLanguage = urlLang
    ? (searchLanguages.isSearchLanguageAvailable(urlLang) ? urlLang : '')
    : searchLanguages.resolveSearchLanguage()
  const queryChanged = urlQ !== query.value
  const languageChanged = resolvedLanguage !== language.value
  if (!queryChanged && !languageChanged) return

  if (queryChanged) {
    skipNextQueryWatch = true
    query.value = urlQ
  }
  if (languageChanged) {
    skipNextLanguageWatch = true
    language.value = resolvedLanguage
  }
  if (debounceTimer) { clearTimeout(debounceTimer); debounceTimer = null }
  void doSearch()
})

// Re-search when UI locale changes.
watch([() => localization.locale, () => localization.secondary], () => { if (initialized && searched.value) void doSearch() })

onMounted(async () => {
  try {
    await searchLanguages.loadSearchLanguages(localeParams.value)
  } catch {
    // The shared control renders the localized loading error; without a validated
    // language the page must not send an expression search request.
    language.value = ''
    languageMissing.value = Boolean(query.value.trim())
    initialized = true
    return
  }

  const requested = routeQueryValue(route.query.lang)
  language.value = requested
    ? (searchLanguages.isSearchLanguageAvailable(requested) ? requested : '')
    : searchLanguages.resolveSearchLanguage()

  // Keep all watchers quiet while the URL state is normalized and the initial
  // request is made. This prevents the language and query watchers from issuing
  // a second request for the same route.
  if (query.value.trim()) await doSearch({ syncUrl: !requested || Boolean(language.value) })
  initialized = true
})
onUnmounted(() => {
  searchRequest += 1
  if (debounceTimer) clearTimeout(debounceTimer)
})
</script>

<template>
  <div class="se-page">
    <div class="se-hero">
      <h1>{{ t('search.title') }}</h1>
      <form class="se-search-form" role="search" @submit.prevent="onFormSubmit">
        <ExpressionSearchControls
          v-model:query="query"
          v-model:language="language"
          variant="page"
          :language-required="languageMissing"
          @submit="doSearch"
        />
      </form>
    </div>

    <div v-if="searched || loading" class="se-meta">
      <span class="se-count">{{ t('search.results', { count: total }) }}</span>
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
          :show-language="true"
        />
      </div>
      <Pagination :has-more="results.length < total" @load-more="loadMore" />
      <p v-if="loadingMore" class="se-more" role="status">{{ t('common.loading') }}</p>
      <p v-else-if="loadMoreError" class="se-more se-more-error" role="alert">{{ loadMoreError }}</p>
    </template>

    <p v-else class="se-hint">{{ t('search.hint') }}</p>
  </div>
</template>

<style scoped>
.se-page { max-width: 900px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.se-hero { margin-bottom: var(--space-md); }
.se-hero h1 { font-size: 28px; font-weight: 600; letter-spacing: -0.02em; margin-bottom: var(--space-base); }
.se-search-form { min-width: 0; }
.se-meta { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px; margin-bottom: 14px; }
.se-count { font-family: var(--mono); font-size: 13px; color: var(--muted); }
.se-count b { color: var(--fg); font-weight: 500; }
.se-sort { display: inline-flex; border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; }
.se-sort button { font-family: var(--mono); font-size: 13px; letter-spacing: 0.04em; text-transform: uppercase; border: none; background: var(--surface); color: var(--muted); cursor: pointer; min-height: 40px; padding: 0 18px; transition: background 0.15s, color 0.15s; }
.se-sort button:hover { color: var(--fg); }
.se-sort button.on { background: var(--fg); color: var(--surface); }
.se-list { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
.se-more { text-align: center; padding: 10px; font-size: 14px; color: var(--muted); }
.se-more-error { color: var(--down); }
.se-hint { font-family: var(--mono); font-size: 13px; text-align: center; padding: var(--space-xl); color: var(--faint); }
@media (max-width: 768px) {
  .se-page { padding-left: 20px; padding-right: 20px; }
}
@media (max-width: 640px) {
  .se-page { padding-left: 16px; padding-right: 16px; }
}
</style>
