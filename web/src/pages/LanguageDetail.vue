<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useLanguages } from '@/composables/useLanguages'
import { useLatestRequest } from '@/composables/useLatestRequest'
import { apiErrorMessage } from '@/utils/apiError'
import type { LanguageDetail as LanguageDetailData, LanguageExpressionSummary, LanguageLocale } from '@/api/languageIdentity'
import ExpressionRow from '@/components/expression/ExpressionRow.vue'
import SearchBar from '@/components/ui/SearchBar.vue'
import StatBox from '@/components/ui/StatBox.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { useI18n } from 'vue-i18n'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { useLocalizationStore } from '@/stores/localization'
import { contentRevision } from '@/utils/contentRevision'

const PAGE = 20
const { t } = useI18n()
const route = useRoute()
const router = useRouter()
const { detail, expressions } = useLanguages()
const localization = useLocalizationStore()
const code = computed(() => String(route.params.code ?? ''))
const localeParams = useLocaleParams()

const lang = ref<LanguageDetailData | null>(null)
const exprs = ref<LanguageExpressionSummary[]>([])
const searchQuery = ref('')
const selectedLocaleCode = ref('')
const detailLoading = ref(false)
const expressionsLoading = ref(false)
const loadError = ref('')
const detailRequest = useLatestRequest()
const expressionsRequest = useLatestRequest()
let debounceTimer: ReturnType<typeof setTimeout> | undefined

const selectedLocale = computed(() => lang.value?.locales.find((locale) => locale.code === selectedLocaleCode.value) ?? null)
const title = computed(() => selectedLocale.value?.display_name ?? lang.value?.name ?? lang.value?.name_en ?? '')
const subtitle = computed(() => {
  const sub = selectedLocale.value?.name ?? lang.value?.name_en ?? ''
  return sub && sub !== title.value ? sub : ''
})

// —— 變體選擇：連動雙下拉（變體 × 其他），選項由 locales 動態切分 ——
const variantSelect = ref('')
const otherSelect = ref('')

const variants = computed(() => [...new Set((lang.value?.locales ?? []).map((locale) => locale.script_code).filter(Boolean))])
const hasVariants = computed(() => variants.value.length > 1)
const showOtherSelect = computed(() => otherOptions.value.length > 1)
const showLocaleSelects = computed(() => hasVariants.value || showOtherSelect.value)

function otherOf(locale: LanguageLocale) {
  return locale.place_path ? `${locale.region_code}/${locale.place_path}` : locale.region_code
}

const otherOptions = computed(() => {
  const pool = variantSelect.value
    ? (lang.value?.locales ?? []).filter((locale) => locale.script_code === variantSelect.value)
    : (lang.value?.locales ?? [])
  const seen = new Set<string>()
  return pool.flatMap((locale) => {
    const other = otherOf(locale)
    if (seen.has(other)) return []
    seen.add(other)
    return [{ value: other, label: `${locale.name} (${other})` }]
  })
})

const derivedLocale = computed(() => {
  if (!lang.value) return ''
  return lang.value.locales.find((locale) =>
    (variantSelect.value === '' || locale.script_code === variantSelect.value) &&
    otherSelect.value !== '' &&
    otherOf(locale) === otherSelect.value)?.code ?? ''
})

function scriptLabel(code: string) {
  const label = t(`languageDetail.scripts.${code}`)
  return label.includes('languageDetail.scripts.') ? code : label
}

function syncSelects(code: string) {
  const locale = lang.value?.locales.find((item) => item.code === code)
  if (locale) {
    variantSelect.value = locale.script_code
    otherSelect.value = otherOf(locale)
  } else {
    variantSelect.value = ''
    otherSelect.value = ''
  }
}

function changeLocaleQuery(code: string) {
  if (code === routeLocale()) return
  const query = { ...route.query }
  if (code) query.locale = code
  else delete query.locale
  delete query.script
  void router.replace({ query })
}

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

async function loadExpressions() {
  if (!code.value) return
  const request = expressionsRequest.begin()
  expressionsLoading.value = true
  loadError.value = ''
  try {
    const page = await expressions(code.value, {
      q: searchQuery.value.trim(),
      locale: selectedLocaleCode.value,
      sort: 'new',
      limit: PAGE,
      offset: 0,
      ...localeParams.value,
    })
    if (!expressionsRequest.isCurrent(request)) return
    exprs.value = page.items
  } catch (cause: unknown) {
    if (!expressionsRequest.isCurrent(request)) return
    loadError.value = apiErrorMessage(cause, t('languageDetail.loadFailed'))
  } finally {
    if (expressionsRequest.isCurrent(request)) {
      expressionsLoading.value = false
    }
  }
}

async function loadDetail(keepContent = false) {
  const request = detailRequest.begin()
  expressionsRequest.begin()
  if (!keepContent) {
    lang.value = null
    exprs.value = []
  }
  detailLoading.value = true
  loadError.value = ''
  try {
    const value = await detail(code.value, localeParams.value, routeLocale())
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

watch(variantSelect, () => {
  if (!lang.value) return
  if (otherSelect.value && !otherOptions.value.some((option) => option.value === otherSelect.value)) otherSelect.value = ''
  if (!otherSelect.value && otherOptions.value.length === 1) otherSelect.value = otherOptions.value[0].value
})
watch([variantSelect, otherSelect], () => {
  if (!lang.value) return
  changeLocaleQuery(derivedLocale.value)
})
watch(selectedLocaleCode, (code) => { syncSelects(code) })

watch(code, () => { void loadDetail() }, { immediate: true })
watch([() => localization.locale, () => localization.secondary], () => { void loadDetail() })
watch(contentRevision, () => { void loadDetail(true) })
watch(() => route.query.locale, () => {
  if (!lang.value) return
  const requestedLocale = routeLocale()
  const next = normalizeLocale(requestedLocale)
  clearUnknownLocale(requestedLocale)
  if (next === selectedLocaleCode.value) return
  selectedLocaleCode.value = next
  void loadDetail(true)
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
      <span class="lang-badge">{{ selectedLocale?.code ?? lang.code }}</span>
    </div>
    <div v-if="showLocaleSelects" class="ld-locales" role="group" :aria-label="t('languageDetail.regionalForms')">
      <div v-if="hasVariants" class="ld-sel">
        <label class="visually-hidden" for="locale-variant">{{ t('languageDetail.variantLabel') }}</label>
        <select id="locale-variant" v-model="variantSelect" class="ld-select">
          <option value="">{{ t('languageDetail.allVariants') }}</option>
          <option v-for="variant in variants" :key="variant" :value="variant">{{ scriptLabel(variant) }} ({{ variant }})</option>
        </select>
      </div>
      <div v-if="showOtherSelect" class="ld-sel">
        <label class="visually-hidden" for="locale-other">{{ t('languageDetail.otherLabel') }}</label>
        <select id="locale-other" v-model="otherSelect" class="ld-select">
          <option value="">{{ t('languageDetail.allOthers') }}</option>
          <option v-for="other in otherOptions" :key="other.value" :value="other.value">{{ other.label }}</option>
        </select>
      </div>
    </div>
    <p v-if="subtitle" class="ld-sub">{{ subtitle }}</p>
    <div class="ld-stats">
      <StatBox :label="t('languageDetail.expressions')" :value="lang.expression_count" />
      <StatBox :label="t('languageDetail.mapped')" :value="lang.mapped_expression_count" />
    </div>
    <div class="ld-toolbar">
      <SearchBar v-model="searchQuery" :placeholder="t('languageDetail.searchPlaceholder')" style="flex: 1;" />
    </div>
    <LoadingSpinner v-if="expressionsLoading" />
    <p v-else-if="loadError" class="ld-error" role="alert">{{ loadError }}</p>
    <EmptyState v-else-if="exprs.length === 0" :message="t('languageDetail.noResults')" />
    <template v-else>
      <div class="ld-list">
        <ExpressionRow v-for="expr in exprs" :key="expr.id" v-bind="expr" :show-language="false" />
      </div>
    </template>
  </div>
</template>

<style scoped>
.ld-page { max-width: 900px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.ld-back { font-family: var(--mono); font-size: 13px; letter-spacing: 0.04em; text-transform: uppercase; color: var(--muted); display: inline-block; margin-bottom: 12px; }
.ld-back:hover { color: var(--fg); }
.ld-title { display: flex; align-items: baseline; gap: 12px; flex-wrap: wrap; margin-bottom: 6px; }
.ld-title h1 { font-size: 28px; font-weight: 600; letter-spacing: -0.02em; }
.ld-sub { font-size: 16px; color: var(--muted); margin: 6px 0; }
.ld-stats { display: flex; gap: 28px; flex-wrap: wrap; padding: 14px 0 18px; border-bottom: 1px solid var(--border); margin-bottom: 18px; }
.ld-toolbar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: var(--space-base); }
.ld-locales { display: flex; gap: 8px; margin: 8px 0; }
.ld-sel { position: relative; flex: 0 0 auto; max-width: 320px; }
.ld-select {
  appearance: none; -webkit-appearance: none;
  width: 100%; min-height: 36px; padding: 0 36px 0 14px;
  border: 1px solid var(--border); border-radius: var(--r);
  background: var(--surface); color: var(--fg);
  font-family: var(--font); font-size: 14px; cursor: pointer;
}
.ld-select:hover { border-color: color-mix(in oklch, var(--muted) 40%, var(--border)); }
.ld-select:focus-visible { outline: 2px solid var(--accent); outline-offset: 1px; }
.ld-sel::after {
  content: ""; position: absolute; right: 14px; top: 50%; width: 7px; height: 7px;
  border-right: 1.5px solid var(--muted); border-bottom: 1.5px solid var(--muted);
  transform: translateY(-70%) rotate(45deg); pointer-events: none;
}
.visually-hidden { position: absolute; width: 1px; height: 1px; margin: -1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
.ld-list { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
.ld-error { text-align: center; padding: 10px; font-size: 14px; color: var(--muted); }
.ld-error { color: var(--down); }
@media (max-width: 640px) {
  .ld-page { padding-right: 16px; padding-left: 16px; }
  .ld-locales { flex-direction: column; }
  .ld-sel { flex: 1 1 0; min-width: 0; max-width: none; }
  .ld-select { min-height: 44px; font-size: 16px; }
}
</style>
