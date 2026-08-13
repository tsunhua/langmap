<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useLanguages } from '@/composables/useLanguages'
import { useLatestRequest } from '@/composables/useLatestRequest'
import { apiErrorMessage } from '@/utils/apiError'
import type { LanguageDetail as LanguageDetailData, LanguageExpressionSummary } from '@/api/languageIdentity'
import ExpressionRow from '@/components/expression/ExpressionRow.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import StatBox from '@/components/ui/StatBox.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import Pagination from '@/components/ui/Pagination.vue'
import { useI18n } from 'vue-i18n'

const PAGE = 20
const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const { detail, expressions } = useLanguages()
const code = computed(() => String(route.params.code ?? ''))

const lang = ref<LanguageDetailData | null>(null)
const exprs = ref<LanguageExpressionSummary[]>([])
const searchQuery = ref('')
const sortBy = ref<'hot' | 'new' | 'alpha'>('hot')
const selectedLocaleCode = ref('')
const detailLoading = ref(false)
const expressionsLoading = ref(false)
const loadingMore = ref(false)
const total = ref(0)
const loadError = ref('')
const loadMoreError = ref('')
const detailRequest = useLatestRequest()
const expressionsRequest = useLatestRequest()
let debounceTimer: ReturnType<typeof setTimeout> | undefined

const selectedLocale = computed(() => lang.value?.locales.find((locale) => locale.code === selectedLocaleCode.value) ?? null)
const title = computed(() => selectedLocale.value?.name ?? lang.value?.name_en ?? '')
const subtitle = computed(() => selectedLocale.value
  ? `${selectedLocale.value.code} · ${selectedLocale.value.name_en}`
  : lang.value?.code ?? '')

function routeLocale() {
  return typeof route.query.locale === 'string' ? route.query.locale : ''
}

function normalizeLocale(locale: string) {
  return lang.value?.locales.some((item) => item.code === locale) ? locale : ''
}

function clearUnknownLocale(locale: string) {
  if (!locale || normalizeLocale(locale)) return
  const query = { ...route.query }
  delete query.locale
  void router.replace({ query })
}

async function loadExpressions(append = false) {
  if (!code.value || (append && (loadingMore.value || exprs.value.length >= total.value))) return
  const request = append ? expressionsRequest.current() : expressionsRequest.begin()
  if (append) {
    loadingMore.value = true
    loadMoreError.value = ''
  } else {
    expressionsLoading.value = true
    loadError.value = ''
    loadMoreError.value = ''
  }
  try {
    const page = await expressions(code.value, {
      q: searchQuery.value.trim(),
      locale: selectedLocaleCode.value,
      sort: sortBy.value,
      limit: PAGE,
      offset: append ? exprs.value.length : 0,
    })
    if (!expressionsRequest.isCurrent(request)) return
    exprs.value = append ? [...exprs.value, ...page.items] : page.items
    total.value = page.total
  } catch (cause: unknown) {
    if (!expressionsRequest.isCurrent(request)) return
    if (append) loadMoreError.value = apiErrorMessage(cause, t('search.loadMoreFailed'))
    else loadError.value = apiErrorMessage(cause, t('languageDetail.loadFailed'))
  } finally {
    if (expressionsRequest.isCurrent(request)) {
      if (append) loadingMore.value = false
      else expressionsLoading.value = false
    }
  }
}

async function loadDetail() {
  const request = detailRequest.begin()
  expressionsRequest.begin()
  lang.value = null
  exprs.value = []
  total.value = 0
  detailLoading.value = true
  loadError.value = ''
  try {
    const value = await detail(code.value)
    if (!detailRequest.isCurrent(request)) return
    lang.value = value
    const requestedLocale = routeLocale()
    selectedLocaleCode.value = normalizeLocale(requestedLocale)
    clearUnknownLocale(requestedLocale)
    await loadExpressions()
  } catch (cause: unknown) {
    if (!detailRequest.isCurrent(request)) return
    loadError.value = apiErrorMessage(cause, t('languageDetail.loadFailed'))
  } finally {
    if (detailRequest.isCurrent(request)) detailLoading.value = false
  }
}

function changeSort(sort: 'hot' | 'new' | 'alpha') {
  if (sort === sortBy.value) return
  sortBy.value = sort
  void loadExpressions()
}

function changeLocale(locale: string) {
  if (locale === selectedLocaleCode.value) return
  const query = { ...route.query }
  if (locale) query.locale = locale
  else delete query.locale
  delete query.script
  void router.replace({ query })
}

watch(code, () => { void loadDetail() }, { immediate: true })
watch(() => route.query.locale, () => {
  if (!lang.value) return
  const requestedLocale = routeLocale()
  const next = normalizeLocale(requestedLocale)
  clearUnknownLocale(requestedLocale)
  if (next === selectedLocaleCode.value) return
  selectedLocaleCode.value = next
  void loadExpressions()
})
watch(searchQuery, () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => { void loadExpressions() }, 300)
})
onUnmounted(() => {
  if (debounceTimer) clearTimeout(debounceTimer)
})
</script>

<template>
  <LoadingSpinner v-if="detailLoading && !lang" />
  <EmptyState v-else-if="loadError && !lang" :message="loadError" />
  <div v-else-if="lang" class="ld-page">
    <router-link to="/languages" class="ld-back">← {{ t('languageDetail.back') }}</router-link>
    <div class="ld-title">
      <h1>{{ title }}</h1>
      <span class="lang-badge">{{ lang.code }}</span>
    </div>
    <div v-if="lang.locales.length" class="ld-locales" role="group" :aria-label="t('languageDetail.regionalForms')">
      <button :class="{ on: selectedLocaleCode === '' }" @click="changeLocale('')">
        <span>{{ t('languageDetail.allScripts') }}</span><small>{{ lang.code }}</small>
      </button>
      <button v-for="locale in lang.locales" :key="locale.code" :class="{ on: selectedLocaleCode === locale.code }" @click="changeLocale(locale.code)">
        <span>{{ locale.name }}</span><small>{{ locale.code }}</small>
      </button>
    </div>
    <p v-if="subtitle" class="ld-sub">{{ subtitle }}</p>
    <div class="ld-stats">
      <StatBox :label="t('languageDetail.expressions')" :value="lang.expression_count" />
      <StatBox :label="t('languageDetail.mapped')" :value="lang.mapped_expression_count" />
    </div>
    <div class="ld-toolbar">
      <SearchBar v-model="searchQuery" :placeholder="t('languageDetail.searchPlaceholder')" style="flex: 1;" />
      <div class="ld-sort" role="group" :aria-label="t('languageDetail.expressions')">
        <button :class="{ on: sortBy === 'hot' }" @click="changeSort('hot')">{{ t('languageDetail.popular') }}</button>
        <button :class="{ on: sortBy === 'new' }" @click="changeSort('new')">{{ t('languageDetail.latest') }}</button>
        <button :class="{ on: sortBy === 'alpha' }" @click="changeSort('alpha')">{{ t('languageDetail.alphabetical') }}</button>
      </div>
    </div>
    <LoadingSpinner v-if="expressionsLoading" />
    <p v-else-if="loadError" class="ld-error" role="alert">{{ loadError }}</p>
    <EmptyState v-else-if="exprs.length === 0" :message="t('languageDetail.noResults')" />
    <template v-else>
      <div class="ld-list">
        <ExpressionRow v-for="expr in exprs" :key="expr.id" v-bind="expr" :show-language="false" />
      </div>
      <Pagination :has-more="exprs.length < total" @load-more="loadExpressions(true)" />
      <p v-if="loadingMore" class="ld-more" role="status">{{ t('common.loading') }}</p>
      <p v-else-if="loadMoreError" class="ld-more ld-error" role="alert">{{ loadMoreError }}</p>
    </template>
  </div>
</template>

<style scoped>
.ld-page { max-width: 900px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.ld-back { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); display: inline-block; margin-bottom: 12px; }
.ld-back:hover { color: var(--fg); }
.ld-title { display: flex; align-items: baseline; gap: 12px; flex-wrap: wrap; margin-bottom: 6px; }
.ld-title h1 { font-size: 28px; font-weight: 600; letter-spacing: -0.02em; }
.ld-sub { font-size: 13px; color: var(--muted); margin: 6px 0; }
.ld-stats { display: flex; gap: 28px; flex-wrap: wrap; padding: 14px 0 18px; border-bottom: 1px solid var(--border); margin-bottom: 18px; }
.ld-toolbar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: var(--space-base); }
.ld-sort { display: inline-flex; border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; }
.ld-locales { display: flex; flex-wrap: wrap; gap: 8px; margin: 8px 0; }
.ld-sort button, .ld-locales button { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); color: var(--muted); cursor: pointer; min-height: 44px; padding: 0 16px; }
.ld-locales button { display: flex; flex-direction: column; align-items: flex-start; justify-content: center; gap: 2px; min-width: 0; text-align: left; }
.ld-locales button small { max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 9px; opacity: .7; }
.ld-sort button { border: none; border-radius: 0; }
.ld-sort button:hover, .ld-locales button:hover { color: var(--fg); }
.ld-sort button.on, .ld-locales button.on { background: var(--fg); color: var(--surface); }
.ld-sort button:focus-visible, .ld-locales button:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.ld-list { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
.ld-more, .ld-error { text-align: center; padding: 8px; font-size: 13px; color: var(--muted); }
.ld-error { color: var(--down); }
@media (max-width: 640px) { .ld-page { padding-right: 16px; padding-left: 16px; } }
</style>
