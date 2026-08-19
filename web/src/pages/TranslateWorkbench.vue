<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Search, Send, Check } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
import {
  addUiLocale,
  getTranslationWorkbench,
  listUiLocales,
  submitTranslationMapping,
  type TranslationWorkbench,
  type WorkbenchMessage,
  type UiLocale,
} from '@/api/localization'
import { createExpression } from '@/api/expressions'
import { getLanguageLocale } from '@/api/languageIdentity'
import LanguageLocalePicker from '@/components/language/LanguageLocalePicker.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const { t } = useI18n()

const locales = ref<UiLocale[]>([])
const workbench = ref<TranslationWorkbench | null>(null)
const draft = ref<Record<string, string>>({})
const initial = ref<Record<string, string>>({})
const query = ref('')
const loadError = ref('')
const actionError = ref('')
const loading = ref(true)
const busy = ref(false)
let loadRequest = 0

const code = computed(() => String(route.params.code || ''))
const messages = computed(() => (workbench.value?.messages ?? []).filter((item) => {
  const needle = query.value.trim().toLowerCase()
  return !needle || `${item.key} ${item.source_text}`.toLowerCase().includes(needle)
}))
const percent = computed(() => Math.round((workbench.value?.coverage.coverage ?? 0) * 100))
const dirty = computed(() => Object.entries(draft.value).filter(
  ([key, text]) => text.trim() && text.trim() !== (initial.value[key] ?? '').trim(),
))
const dirtyKeys = computed(() => new Set(dirty.value.map(([key]) => key)))
const statusChip = computed(() => {
  const status = workbench.value?.locale.status ?? 'draft'
  const labels: Record<string, string> = {
    draft: t('translate.statusDraft'),
    active: t('translate.statusActive'),
    archived: t('translate.statusArchived'),
  }
  return { key: status, label: labels[status] ?? status }
})
// 啟用來源只對已啟用的 locale 有意義；草稿階段的 null 就不顯示。
const sourceChip = computed(() => {
  const source = workbench.value?.locale.activation_source
  if (!source) return null
  const labels: Record<string, string> = {
    system: t('translate.sourceSystem'),
    auto: t('translate.sourceAuto'),
    manual: t('translate.sourceManual'),
  }
  return { key: source, label: labels[source] ?? source }
})

function errorMessage(cause: unknown, fallback: string) {
  if (cause instanceof Error && cause.message) return cause.message
  const responseError = (cause as { response?: { data?: { error?: string; message?: string } } })
    ?.response?.data
  return responseError?.message || responseError?.error || fallback
}

async function refresh() {
  locales.value = await listUiLocales()
}

async function load(next: string) {
  const request = ++loadRequest
  if (!next) {
    workbench.value = null
    loading.value = false
    return
  }

  loading.value = true
  loadError.value = ''
  actionError.value = ''
  try {
    const value = await getTranslationWorkbench(next)
    if (request !== loadRequest) return
    workbench.value = value
    initial.value = Object.fromEntries(value.messages.map((item) => [item.key, item.candidates[0]?.text ?? '']))
    draft.value = { ...initial.value }
  } catch (cause) {
    if (request !== loadRequest) return
    workbench.value = null
    loadError.value = errorMessage(cause, t('translate.loadFailed'))
  } finally {
    if (request === loadRequest) loading.value = false
  }
}

async function choose(next: string) {
  if (!next || next === code.value || busy.value) return
  busy.value = true
  actionError.value = ''
  try {
    if (!locales.value.some((item) => item.language_locale_code === next)) {
      await addUiLocale(next)
      await refresh()
    }
    await router.push(`/translate/${encodeURIComponent(next)}`)
  } catch (cause) {
    actionError.value = errorMessage(cause, t('translate.localesFailed'))
  } finally {
    busy.value = false
  }
}

async function submit() {
  if (!auth.isLoggedIn || !dirty.value.length || busy.value) return
  busy.value = true
  actionError.value = ''
  try {
    const locale = await getLanguageLocale(code.value)
    for (const [key, text] of dirty.value) {
      const result = await createExpression({
        lang_code: locale.lang_code,
        language_locale_code: locale.code,
        text: text.trim(),
      }) as { expression: { id: string } }
      await submitTranslationMapping({ message_key: key, target_expression_id: result.expression.id })
    }
    await load(code.value)
  } catch (cause) {
    actionError.value = errorMessage(cause, t('translate.submitFailed'))
  } finally {
    busy.value = false
  }
}

onMounted(async () => {
  try {
    await refresh()
  } catch (cause) {
    loadError.value = errorMessage(cause, t('translate.localesFailed'))
    loading.value = false
    return
  }

  if (!code.value) {
    loading.value = false
    const first = locales.value.find((item) => item.status !== 'archived')
    if (first) await router.replace(`/translate/${encodeURIComponent(first.language_locale_code)}`)
    return
  }
  if (auth.isLoggedIn) {
    await load(code.value)
  } else {
    loading.value = false
  }
})

watch(code, (next) => { if (auth.isLoggedIn) void load(next) })

function best(item: WorkbenchMessage) {
  return item.candidates[0]
}
</script>

<template>
  <main class="translate-page">
    <header class="page-head">
      <div class="head-text">
        <p class="eyebrow">{{ t('translate.eyebrow') }}</p>
        <h1>{{ t('translate.title') }}</h1>
        <p class="subtitle">{{ t('translate.subtitle') }}</p>
      </div>
      <LanguageLocalePicker
        class="locale-picker"
        :model-value="code"
        :label="t('translate.locale')"
        @update:model-value="choose"
      />
    </header>

    <LoadingSpinner v-if="loading" />
    <div v-else-if="loadError" role="alert">
      <EmptyState :message="loadError" />
    </div>

    <p v-else-if="!auth.isLoggedIn" class="login-note">{{ t('translate.loginNote') }}</p>

    <template v-else-if="workbench">
      <section class="card coverage-card" :aria-label="t('translate.coverage')">
        <div class="coverage-main">
          <span class="coverage-label">{{ t('translate.coverage') }}</span>
          <strong class="coverage-pct">{{ percent }}%</strong>
          <span class="coverage-count">{{ workbench.coverage.translated }} / {{ workbench.coverage.total }}</span>
        </div>
        <div
          class="coverage-bar"
          role="progressbar"
          aria-valuemin="0"
          aria-valuemax="100"
          :aria-valuenow="percent"
          :aria-label="t('translate.coverage')"
        >
          <span :style="{ width: `${percent}%` }" />
        </div>
        <div class="coverage-meta">
          <span class="chip" :class="`chip-${statusChip.key}`">{{ statusChip.label }}</span>
          <span v-if="sourceChip" class="chip">{{ sourceChip.label }}</span>
        </div>
      </section>

      <div class="toolbar">
        <label class="search-box">
          <Search :size="16" aria-hidden="true" />
          <input v-model="query" type="search" :placeholder="t('translate.searchPlaceholder')">
        </label>
        <span class="shown-count">{{ t('translate.displayed', { count: messages.length }) }}</span>
        <button class="btn btn-primary" :disabled="!auth.isLoggedIn || !dirty.length || busy" @click="submit">
          <span v-if="busy" class="btn-spinner" aria-hidden="true" />
          <Send v-else :size="16" aria-hidden="true" />
          <span v-if="busy">{{ t('translate.loading') }}</span>
          <span v-else>{{ t('translate.batchSubmit', { count: dirty.length }) }}</span>
        </button>
      </div>
      <p v-if="actionError" class="error-note" role="alert">{{ actionError }}</p>

      <EmptyState v-if="messages.length === 0" :message="t('translate.noResults')" />
      <div v-else class="table-wrap">
        <table>
          <thead>
            <tr>
              <th scope="col">{{ t('translate.key') }}</th>
              <th scope="col">{{ t('translate.source') }}</th>
              <th scope="col">{{ t('translate.translation') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in messages" :key="item.key" :class="{ 'row-dirty': dirtyKeys.has(item.key) }">
              <th scope="row" class="key">{{ item.key }}</th>
              <td class="source">{{ item.source_text }}</td>
              <td class="translation">
                <textarea
                  v-model="draft[item.key]"
                  :aria-label="t('translate.translateKey', { key: item.key })"
                  :placeholder="t('translate.inputPlaceholder')"
                />
                <div class="meta-row">
                  <span v-if="dirtyKeys.has(item.key)" class="chip chip-pending">{{ t('translate.pendingSubmit') }}</span>
                  <span v-else-if="item.candidates.length" class="meta-submitted"><Check :size="12" aria-hidden="true" />{{ t('translate.submitted') }}</span>
                  <p v-if="best(item)" class="score">{{ t('translate.candidateScore', { score: best(item)?.score }) }}</p>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </main>
</template>

<style scoped>
.translate-page { max-width: 1100px; margin: auto; padding: var(--page-pad-top) 24px var(--page-pad-bottom); }

/* Page header: eyebrow + title + subtitle establish hierarchy; picker sits opposite. */
.page-head { display: flex; align-items: flex-end; justify-content: space-between; gap: var(--space-md); flex-wrap: wrap; }
.head-text { min-width: 0; }
.eyebrow { margin: 0 0 4px; font-family: var(--mono); font-size: 11px; letter-spacing: 0.08em; text-transform: uppercase; color: var(--accent); }
.page-head h1 { margin: 0; font-size: 28px; font-weight: 700; letter-spacing: -0.02em; }
.subtitle { margin: 6px 0 0; max-width: 46ch; color: var(--muted); font-size: var(--text-ui); }
.page-head .locale-picker { min-width: min(320px, 100%); }

/* Coverage: label + mono percent + progress bar read as one unit. */
.coverage-card { display: grid; gap: 10px; margin: var(--space-md) 0 var(--space-base); }
.coverage-main { display: flex; align-items: baseline; gap: 12px; }
.coverage-label { font-size: 12px; font-weight: 600; color: var(--muted); }
.coverage-pct { font-family: var(--mono); font-size: 24px; font-variant-numeric: tabular-nums; line-height: 1; }
.coverage-count { font-family: var(--mono); font-size: var(--text-meta); color: var(--muted); }
.coverage-bar { height: 6px; border-radius: 999px; background: var(--surface-2); overflow: hidden; }
.coverage-bar > span { display: block; height: 100%; border-radius: 999px; background: var(--accent); transition: width 0.3s ease; }
.coverage-meta { display: flex; gap: 6px; }

.chip { display: inline-flex; align-items: center; gap: 4px; flex: none; padding: 1px 6px; border: 1px solid var(--border); border-radius: 2px; background: var(--surface); font-family: var(--mono); font-size: 11px; color: var(--muted); }
.chip-done { color: var(--up); border-color: color-mix(in oklch, var(--up) 45%, var(--border)); }
.chip-pending { color: var(--accent); border-color: color-mix(in oklch, var(--accent) 45%, var(--border)); }
.chip-active { color: var(--up); border-color: color-mix(in oklch, var(--up) 45%, var(--border)); }
.chip-archived { color: var(--faint); border-color: var(--border); }

/* Toolbar: search grows, count + submit stay fixed. */
.toolbar { display: flex; align-items: center; gap: 10px; margin: 0 0 var(--space-sm); }
.search-box { display: flex; align-items: center; gap: 8px; flex: 1 1 auto; min-width: 0; min-height: 44px; padding: 0 10px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); color: var(--muted); transition: border-color 0.15s, box-shadow 0.15s; }
.search-box:focus-within { border-color: var(--accent); box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent); }
.search-box input { flex: 1; min-width: 0; border: 0; outline: none; background: transparent; min-height: 40px; }
.shown-count { flex: none; font-family: var(--mono); font-size: var(--text-meta); color: var(--faint); }
.toolbar .btn { flex: none; }

.error-note { margin: 0 0 var(--space-sm); padding: 10px 12px; border: 1px solid color-mix(in oklch, var(--down) 40%, var(--border)); border-radius: var(--r); background: color-mix(in oklch, var(--down) 6%, var(--surface)); color: var(--down); font-size: 13px; }

/* Table: card container scrolls horizontally instead of breaking the page. */
.table-wrap { overflow-x: auto; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); }
table { width: 100%; min-width: 640px; border-collapse: collapse; table-layout: fixed; }
thead th { padding: 10px 12px; border-bottom: 1px solid var(--border); background: var(--surface-2); font-size: 12px; font-weight: 600; color: var(--muted); text-align: left; white-space: nowrap; }
thead th:nth-child(1) { width: 22%; }
thead th:nth-child(2) { width: 28%; }
thead th:nth-child(3) { width: 50%; }
tbody th, tbody td { padding: 12px; border-bottom: 1px solid var(--border); text-align: left; vertical-align: top; }
tbody tr:last-child th, tbody tr:last-child td { border-bottom: 0; }
.key { font-family: var(--mono); font-size: 12px; color: var(--muted); overflow-wrap: anywhere; }
.source { overflow-wrap: anywhere; font-size: var(--text-ui); }
.row-dirty td { background: color-mix(in oklch, var(--accent-soft) 55%, var(--surface)); }
.translation textarea { width: 100%; min-height: 68px; resize: vertical; padding: 8px 10px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); font-family: var(--font); font-size: var(--text-ui); color: var(--fg); }
.translation textarea:focus { outline: none; border-color: var(--accent); box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent); }
.meta-row { display: flex; align-items: center; flex-wrap: wrap; gap: 4px 10px; margin-top: 4px; }
.meta-row .score { margin: 0 0 0 auto; }
.meta-submitted { display: inline-flex; align-items: center; gap: 3px; font-family: var(--mono); font-size: 11px; color: var(--up); }

.btn-spinner { width: 14px; height: 14px; border-radius: 50%; border: 2px solid color-mix(in oklch, #fff 45%, transparent); border-top-color: #fff; animation: btn-spin 0.7s linear infinite; }
@keyframes btn-spin { to { transform: rotate(360deg); } }

@media (max-width: 680px) {
  .page-head { align-items: stretch; flex-direction: column; }
  .page-head .locale-picker { min-width: 0; }
  .toolbar { flex-wrap: wrap; }
  .search-box { flex: 1 1 100%; }
  .shown-count { order: 3; margin-left: auto; }
  .toolbar .btn { flex: 1 1 auto; }
  .translation textarea { font-size: 16px; }
}
</style>
