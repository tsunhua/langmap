<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useSearch } from '@/composables/useSearch'
import { apiErrorMessage } from '@/utils/apiError'
import ExpressionRow from '@/components/expression/ExpressionRow.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import LanguageSelect from '@/components/language/LanguageSelect.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import Pagination from '@/components/ui/Pagination.vue'
import { useI18n } from 'vue-i18n'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { useLocalizationStore } from '@/stores/localization'
import { useLanguagesStore } from '@/stores/languages'
import { useSearchLanguages, rememberSearchLanguage } from '@/composables/useSearchLanguages'
import type { SearchFormOf } from '@/api/expressions'

const route = useRoute()
const router = useRouter()
const { search } = useSearch()
const { t } = useI18n()
const localeParams = useLocaleParams()
const localization = useLocalizationStore()
const languagesStore = useLanguagesStore()
const { recent } = useSearchLanguages()

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
const query = ref((route.query.q as string) || '')
const initialLang = (() => {
  const urlLang = typeof route.query.lang === 'string' && route.query.lang
  if (urlLang) return [urlLang]
  const first = recent.value[0]
  return first ? [first] : []
})()
const langs = ref<string[]>(initialLang)
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

function syncUrl() {
  const params: Record<string, string> = {}
  const q = query.value.trim()
  if (q) params.q = q
  if (langs.value[0]) params.lang = langs.value[0]
  router.replace({ query: params })
}

async function doSearch() {
  if (debounceTimer) { clearTimeout(debounceTimer); debounceTimer = null }
  if (!query.value.trim()) {
    searchRequest += 1
    results.value = []
    total.value = 0
    searched.value = false
    loadError.value = ''
    loadMoreError.value = ''
    syncUrl()
    return
  }
  if (!langs.value[0]) {
    searched.value = false
    languageMissing.value = Boolean(query.value.trim())
    loadError.value = ''
    results.value = []
    total.value = 0
    syncUrl()
    return
  }
  languageMissing.value = false
  const request = ++searchRequest
  const requestedQuery = query.value.trim()
  loading.value = true
  loadError.value = ''
  loadMoreError.value = ''
  try {
    const data = await search(requestedQuery, {
      lang: langs.value[0],
      limit: PAGE,
      offset: 0,
      ...localeParams.value,
    })
    if (request !== searchRequest) return
    results.value = data.items
    total.value = data.total
    searched.value = true
    rememberSearchLanguage(langs.value[0])
    syncUrl()
  } catch (e: unknown) {
    if (request !== searchRequest) return
    loadError.value = apiErrorMessage(e, t('search.loadFailed'))
  } finally {
    if (request === searchRequest) loading.value = false
  }
}

async function loadMore() {
  if (loadingMore.value || results.value.length >= total.value) return
  const request = searchRequest
  const requestedQuery = query.value.trim()
  const offset = results.value.length
  loadingMore.value = true
  loadMoreError.value = ''
  try {
    const data = await search(requestedQuery, {
      lang: langs.value[0],
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

function recentLabel(code: string) {
  return languagesStore.getName(code)
}

function selectRecentLanguage(code: string) {
  if (langs.value[0] === code) return
  langs.value = [code]
}

function isRecentActive(code: string) {
  return langs.value.includes(code)
}

// Debounced search on query input.
watch(query, () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(doSearch, 300)
})

// Re-search immediately when language filter changes (only after a search has started).
watch(langs, () => {
  syncUrl()
  if (searched.value || query.value) doSearch()
})

// Sync state back when the URL changes externally (back/forward, typed URL).
watch(() => route.query, (next) => {
  const urlQ = typeof next.q === 'string' ? next.q : ''
  const urlLang = typeof next.lang === 'string' ? next.lang : ''
  if (urlQ !== query.value) query.value = urlQ
  if (urlLang !== langs.value[0]) {
    langs.value = urlLang ? [urlLang] : []
    doSearch()
  }
})

// Re-search when UI locale changes.
watch([() => localization.locale, () => localization.secondary], () => { if (searched.value) doSearch() })

onMounted(() => {
  if (query.value) doSearch()
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
      <div class="se-qrow">
        <SearchBar v-model="query" :placeholder="t('search.placeholder')" :large="true" @search="doSearch" />
        <LanguageSelect v-model="langs" :class="{ 'se-lang-required': languageMissing }" />
      </div>
      <div v-if="languageMissing" class="se-lang-warn" role="status">
        {{ t('search.languageRequired') }}
      </div>
      <div v-if="recent.length" class="se-recents" :aria-label="t('components.filterLanguages')">
        <button
          v-for="code in recent"
          :key="code"
          type="button"
          class="se-recent"
          :class="{ on: isRecentActive(code) }"
          :aria-pressed="isRecentActive(code)"
          @click="selectRecentLanguage(code)"
        >
          {{ recentLabel(code) }}
        </button>
      </div>
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
.se-qrow { display: flex; gap: 12px; flex-wrap: wrap; align-items: center; }
.se-qrow > :first-child { flex: 1; min-width: 0; }
.se-lang-required :deep(.lang-select-tagwrap) {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent);
}
.se-lang-warn {
  margin-top: 10px;
  padding: 10px 12px;
  font-size: 13px;
  color: var(--accent);
  border: 1px solid color-mix(in oklch, var(--accent) 30%, var(--border));
  border-radius: var(--r);
  background: color-mix(in oklch, var(--accent) 7%, var(--surface));
}
.se-recents {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin: 14px 0 var(--space-base);
}
.se-recent {
  display: inline-flex;
  align-items: center;
  min-height: 40px;
  padding: 0 14px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--surface);
  color: var(--fg);
  font-family: var(--mono);
  font-size: 13px;
  cursor: pointer;
  transition: border-color 0.12s, color 0.12s, background 0.12s;
}
.se-recent:hover { border-color: var(--accent); color: var(--accent); }
.se-recent.on { background: var(--accent); border-color: var(--accent); color: #fff; }
.se-recent:focus-visible { outline: 2px solid var(--accent); outline-offset: 1px; }
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
  .se-recent { min-height: 44px; }
}
</style>
