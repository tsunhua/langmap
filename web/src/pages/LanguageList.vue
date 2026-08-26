<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useLanguages } from '@/composables/useLanguages'
import { useLatestRequest } from '@/composables/useLatestRequest'
import { apiErrorMessage } from '@/utils/apiError'
import type { ContentLanguage } from '@/api/languageIdentity'
import LanguageCard from '@/components/language/LanguageCard.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import StatBox from '@/components/ui/StatBox.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import Pagination from '@/components/ui/Pagination.vue'
import { useI18n } from 'vue-i18n'
import { useLocalizationStore } from '@/stores/localization'
import { useLocaleParams } from '@/composables/useLocaleParams'

const PAGE = 20
const { list } = useLanguages()
const { t } = useI18n()
const localization = useLocalizationStore()
const localeParams = useLocaleParams()

const languages = ref<ContentLanguage[]>([])
const searchQuery = ref('')
const sortBy = ref<'new' | 'alpha'>('alpha')
const nextCursor = ref<string | null>(null)
const loading = ref(false)
const loadingMore = ref(false)
const loadError = ref('')
const loadMoreError = ref('')
const languagesRequest = useLatestRequest()
let debounceTimer: ReturnType<typeof setTimeout> | undefined

const totalExpressions = computed(() => languages.value.reduce((sum, language) => sum + language.expression_count, 0))

async function loadLanguages(append = false) {
  if (append && (loadingMore.value || !nextCursor.value)) return
  const request = append ? languagesRequest.current() : languagesRequest.begin()
  if (append) {
    loadingMore.value = true
    loadMoreError.value = ''
  } else {
    loading.value = true
    loadError.value = ''
    loadMoreError.value = ''
  }

  try {
    const page = await list({
      q: searchQuery.value.trim(),
      sort: sortBy.value,
      limit: PAGE,
      cursor: append ? nextCursor.value ?? undefined : undefined,
      ...localeParams.value,
    })
    if (!languagesRequest.isCurrent(request)) return
    languages.value = append ? [...languages.value, ...page.items] : page.items
    nextCursor.value = page.next_cursor ?? null
  } catch (cause: unknown) {
    if (!languagesRequest.isCurrent(request)) return
    if (append) loadMoreError.value = apiErrorMessage(cause, t('search.loadMoreFailed'))
    else loadError.value = apiErrorMessage(cause, t('languagesPage.loadFailed'))
  } finally {
    if (languagesRequest.isCurrent(request)) {
      if (append) loadingMore.value = false
      else loading.value = false
    }
  }
}

watch(searchQuery, () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => { void loadLanguages() }, 300)
})

watch(sortBy, () => { void loadLanguages() })

watch([() => localization.locale, () => localization.secondary], () => { void loadLanguages() })

onMounted(() => { void loadLanguages() })
onUnmounted(() => {
  if (debounceTimer) clearTimeout(debounceTimer)
})
</script>

<template>
  <div class="lg-page">
    <div class="lg-head">
      <div class="lg-heading">
        <h1>{{ t('languagesPage.title') }}</h1>
        <p class="lg-sub">{{ t('languagesPage.subtitle') }}</p>
      </div>
    </div>

    <div class="lg-stats">
      <StatBox :label="t('languagesPage.languageCount')" :value="languages.length" />
      <StatBox :label="t('languagesPage.expressionCount')" :value="totalExpressions.toLocaleString()" />
    </div>

    <div class="lg-toolbar">
      <SearchBar v-model="searchQuery" :placeholder="t('languagesPage.searchPlaceholder')" style="flex: 1;" />
      <div class="lg-sort" role="group" :aria-label="t('languagesPage.title')">
        <button :class="{ on: sortBy === 'new' }" @click="sortBy = 'new'">{{ t('languagesPage.sortNewest') }}</button>
        <button :class="{ on: sortBy === 'alpha' }" @click="sortBy = 'alpha'">{{ t('languagesPage.sortAlphabetical') }}</button>
      </div>
    </div>

    <LoadingSpinner v-if="loading" />
    <EmptyState v-else-if="loadError" :message="loadError" />
    <EmptyState v-else-if="languages.length === 0" :message="t('languagesPage.noResults')" />
    <template v-else>
      <div class="lg-list">
        <LanguageCard v-for="lang in languages" :key="lang.code" v-bind="lang" />
      </div>
      <Pagination :has-more="Boolean(nextCursor)" @load-more="loadLanguages(true)" />
      <p v-if="loadingMore" class="lg-more" role="status">{{ t('common.loading') }}</p>
      <p v-else-if="loadMoreError" class="lg-more lg-more-error" role="alert">{{ loadMoreError }}</p>
    </template>
  </div>
</template>

<style scoped>
.lg-page { max-width: 900px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.lg-head { display: flex; align-items: flex-start; justify-content: space-between; gap: 24px; }
.lg-heading { min-width: 0; }
.lg-head h1 { font-size: 28px; font-weight: 600; letter-spacing: -0.02em; }
.lg-sub { font-size: 16px; color: var(--muted); margin: 6px 0 0; }
.lg-stats { display: flex; gap: 28px; flex-wrap: wrap; padding: 14px 0 18px; border-bottom: 1px solid var(--border); margin-bottom: 18px; }
.lg-toolbar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: 16px; }
.lg-sort { display: inline-flex; border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; }
.lg-sort button { font-family: var(--mono); font-size: 13px; letter-spacing: 0.04em; text-transform: uppercase; border: none; background: var(--surface); color: var(--muted); cursor: pointer; min-height: 44px; padding: 0 18px; transition: background 0.15s, color 0.15s; }
.lg-sort button:hover { color: var(--fg); }
.lg-sort button.on { background: var(--fg); color: var(--surface); }
.lg-list { display: grid; grid-template-columns: minmax(0, 1fr) auto auto; column-gap: 16px; background: var(--surface); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
.lg-more { text-align: center; padding: 10px; font-size: 14px; color: var(--muted); }
.lg-more-error { color: var(--down); }
@media (max-width: 640px) {
  .lg-page { padding-right: 16px; padding-left: 16px; }
  .lg-head { align-items: stretch; flex-direction: column; gap: 16px; }
  .lg-list { grid-template-columns: minmax(0, 1fr) auto; }
}
</style>
