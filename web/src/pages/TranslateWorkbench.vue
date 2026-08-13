<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Search, Send } from 'lucide-vue-next'
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
  await load(code.value)
})

watch(code, (next) => { void load(next) })

function best(item: WorkbenchMessage) {
  return item.candidates[0]
}
</script>

<template>
  <main class="translate-page">
    <header>
      <h1>{{ t('translate.title') }}</h1>
      <LanguageLocalePicker
        :model-value="code"
        :label="t('translate.locale')"
        @update:model-value="choose"
      />
    </header>

    <LoadingSpinner v-if="loading" />
    <div v-else-if="loadError" role="alert">
      <EmptyState :message="loadError" />
    </div>

    <template v-else-if="workbench">
      <section class="coverage-card" :aria-label="t('translate.coverage')">
        <strong>{{ percent }}%</strong>
        <span>{{ workbench.coverage.translated }} / {{ workbench.coverage.total }}</span>
        <small>{{ workbench.locale.status }} · {{ workbench.locale.activation_source || 'draft' }}</small>
      </section>
      <div class="toolbar">
        <label>
          <Search :size="16" aria-hidden="true" />
          <input v-model="query" type="search" :placeholder="t('translate.searchPlaceholder')">
        </label>
        <button class="btn btn-primary" :disabled="!auth.isLoggedIn || !dirty.length || busy" @click="submit">
          <Send :size="16" aria-hidden="true" />{{ t('translate.batchSubmit', { count: dirty.length }) }}
        </button>
      </div>
      <p v-if="!auth.isLoggedIn" class="login-note">{{ t('translate.loginNote') }}</p>
      <p v-if="actionError" role="alert">{{ actionError }}</p>
      <EmptyState v-if="messages.length === 0" :message="t('translate.noResults')" />
      <table v-else>
        <thead>
          <tr>
            <th>{{ t('translate.reference') }}</th>
            <th>{{ t('translate.source') }}</th>
            <th>{{ t('translate.translation') }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in messages" :key="item.key">
            <th>{{ item.key }}</th>
            <td>{{ item.source_text }}</td>
            <td>
              <textarea
                v-model="draft[item.key]"
                :aria-label="t('translate.translateKey', { key: item.key })"
                :placeholder="t('translate.inputPlaceholder')"
              />
              <small v-if="best(item)">score {{ best(item)?.score }}</small>
            </td>
          </tr>
        </tbody>
      </table>
    </template>
  </main>
</template>

<style scoped>
.translate-page { max-width: 1100px; margin: auto; padding: 24px; }
.translate-page header, .toolbar { display: flex; gap: 16px; align-items: end; justify-content: space-between; }
.coverage-card { display: flex; gap: 16px; margin: 20px 0; padding: 16px; border: 1px solid var(--border); background: var(--surface); }
.coverage-card strong { font: 24px var(--mono); }
.toolbar label { display: flex; min-height: 44px; align-items: center; border: 1px solid var(--border); padding: 0 8px; }
.toolbar input { border: 0; background: transparent; }
.login-note { color: var(--muted); font-size: 13px; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 10px; border-bottom: 1px solid var(--border); text-align: left; vertical-align: top; }
textarea { width: 100%; min-height: 68px; }
@media (max-width: 680px) {
  .translate-page header, .toolbar { align-items: stretch; flex-direction: column; }
  .coverage-card { flex-wrap: wrap; }
}
</style>
