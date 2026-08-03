<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Search, Send, Languages } from 'lucide-vue-next'
import { listUiLocales, getUiMessages, getTranslationWorkbench, submitTranslationMappings, addUiLocale, type TranslationWorkbench, type WorkbenchMessage, type UiLocale, LOCALIZATION_PROJECT_ID } from '@/api/localization'
import { listRegistryLanguages, type Variety } from '@/api/languages'
import LanguagePicker from '@/components/language/LanguagePicker.vue'
import { useAuthStore } from '@/stores/auth'
import { useI18n } from 'vue-i18n'
import { en } from '@/locales/en'

const { t } = useI18n()

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const locales = ref<UiLocale[]>([])
const workbench = ref<TranslationWorkbench | null>(null)
const loading = ref(false)
const error = ref('')
const query = ref('')
const draft = ref<Record<string, string>>({})
const initialTranslation = ref<Record<string, string>>({})
const draftLocale = ref('')
const registryLanguages = ref<Variety[]>([])
const referenceLocale = ref('')
const referenceMessages = ref<Record<string, string>>({})
const loaded = ref(false)
const batchSubmitting = ref(false)

const code = computed(() => String(route.params.code || ''))
const targetLanguages = computed(() => {
  const byCode = new Map<string, Variety | UiLocale>()
  for (const item of registryLanguages.value) byCode.set(item.code, item)
  for (const item of locales.value) byCode.set(item.code, { ...byCode.get(item.code), ...item })
  return [...byCode.values()].sort((a, b) =>
    String(a.name || ('name_en' in a ? a.name_en : '') || a.code).localeCompare(String(b.name || ('name_en' in b ? b.name_en : '') || b.code)) || a.code.localeCompare(b.code))
})
const filteredMessages = computed(() => {
  const q = query.value.trim().toLowerCase()
  return (workbench.value?.messages ?? []).filter((item) => !q || item.key.toLowerCase().includes(q) || item.source_text.toLowerCase().includes(q))
})
const percent = computed(() => Math.round((workbench.value?.coverage ?? 0) * 100))
const draftCount = computed(() => Object.entries(draft.value).filter(([key, value]) => value?.trim() && value.trim() !== (initialTranslation.value[key] || '').trim()).length)

function flattenMessages(value: Record<string, unknown>, prefix = '', output: Record<string, string> = {}) {
  for (const [key, item] of Object.entries(value)) {
    const path = prefix ? `${prefix}.${key}` : key
    if (typeof item === 'string') output[path] = item
    else if (item && typeof item === 'object') flattenMessages(item as Record<string, unknown>, path, output)
  }
  return output
}
const sourceCatalog = flattenMessages(en as unknown as Record<string, unknown>)

function bestCandidate(item: WorkbenchMessage) {
  return item.candidates[0]
}
async function loadWorkbench(codeToLoad: string) {
  if (!codeToLoad) return
  loading.value = true
  error.value = ''
  try {
    const remote = await getTranslationWorkbench(codeToLoad)
    const remoteByKey = new Map(remote.messages.map(item => [item.key, item]))
    const messages = Object.entries(sourceCatalog).map(([key, sourceText]) => remoteByKey.get(key) || {
      key, source_expression_id: 0, source_text: sourceText, candidates: [],
    })
    const translatedKeys = messages.filter(item => item.candidates[0]?.score >= 0).length
    workbench.value = { ...remote, messages, total_keys: messages.length, translated_keys: translatedKeys, coverage: messages.length ? translatedKeys / messages.length : 1 }
    if (draftLocale.value !== codeToLoad) {
      initialTranslation.value = Object.fromEntries(messages.map(item => [item.key, item.candidates[0]?.text || '']))
      draft.value = { ...initialTranslation.value }
      draftLocale.value = codeToLoad
    }
    if (referenceLocale.value && referenceLocale.value !== 'en') {
      const remoteReference = (await getUiMessages(referenceLocale.value)).messages as Record<string, string>
      referenceMessages.value = remoteReference
    } else {
      referenceMessages.value = {}
    }
  }
  catch (e: any) { error.value = e.response?.data?.message || t('translate.loadFailed') }
  finally { loading.value = false }
}
async function chooseLocale(next: string) {
  if (!next || next === code.value) return
  try {
    if (!locales.value.some(item => item.code === next)) {
      await addUiLocale(next)
      await refreshLocales()
    }
    router.push(`/translate/${encodeURIComponent(next)}`)
  } catch (e: any) { error.value = e.response?.data?.message || t('translate.loadFailed') }
}

async function handleTargetCreated(lang: { code: string; name: string }) {
  await chooseLocale(lang.code)
}
async function refreshLocales() { locales.value = await listUiLocales(LOCALIZATION_PROJECT_ID) }
async function submitBatch() {
  if (!auth.isLoggedIn || !workbench.value || !draftCount.value) return
  batchSubmitting.value = true
  error.value = ''
  try {
    const byKey = new Map(workbench.value.messages.map(item => [item.key, item]))
    const mappings = Object.entries(draft.value).filter(([key, text]) => text?.trim() && text.trim() !== (initialTranslation.value[key] || '').trim()).map(([key, text]) => ({ key, locale_code: code.value, text: text.trim(), source_text: byKey.get(key)?.source_text }))
    for (let index = 0; index < mappings.length; index += 100) {
      await submitTranslationMappings(mappings.slice(index, index + 100))
    }
    draftLocale.value = ''
    await loadWorkbench(code.value)
  } catch (e: any) { error.value = e.response?.data?.message || t('translate.submitFailed') }
  finally { batchSubmitting.value = false }
}

onMounted(async () => {
  try {
    await refreshLocales()
    registryLanguages.value = await listRegistryLanguages()
    if (!code.value) {
      const target = locales.value.find((item) => item.code !== 'en' && item.status !== 'archived') || locales.value[0]
      if (target) return router.replace(`/translate/${encodeURIComponent(target.code)}`)
    }
    if (!referenceLocale.value) {
      const ref = locales.value.find((item) => item.code !== code.value && item.code !== 'en' && item.status !== 'archived')
      if (ref) referenceLocale.value = ref.code
    }
    loaded.value = true
    await loadWorkbench(code.value)
  } catch (e: any) { error.value = e.response?.data?.message || t('translate.localesFailed') }
})
watch(code, (val) => { if (val && loaded.value) loadWorkbench(val) })
watch(referenceLocale, (val) => { if (val && loaded.value && code.value) loadWorkbench(code.value) })
</script>

<template>
  <div class="translate-page">
    <header class="translate-head">
      <div>
        <p class="eyebrow"><Languages :size="13" aria-hidden="true" /> {{ t('translate.eyebrow') }}</p>
        <h1>{{ t('translate.title') }}</h1>
        <p class="translate-sub">{{ t('translate.subtitle') }}</p>
      </div>
      <LanguagePicker
        :model-value="code"
        :label="t('translate.locale')"
        :allow-create="true"
        @update:model-value="chooseLocale"
        @created="handleTargetCreated"
      />
      <label class="locale-select">{{ t('translate.reference') }}
        <select v-model="referenceLocale"><option v-for="item in locales.filter(item => item.code !== code)" :key="item.code" :value="item.code">{{ item.native_name || item.name }} · {{ item.code }}</option></select>
      </label>
    </header>

    <section v-if="workbench" class="coverage-card" :aria-label="t('translate.coverage')">
      <div><strong>{{ percent }}%</strong><span>{{ t('translate.translated') }}</span></div>
      <div class="coverage-track"><span :style="{ width: `${percent}%` }" /></div>
      <span class="coverage-count">{{ workbench.translated_keys }} / {{ workbench.total_keys }} keys</span>
    </section>
    <div class="translate-toolbar"><label class="search-box"><Search :size="15" aria-hidden="true" /><input v-model="query" type="search" :placeholder="t('translate.searchPlaceholder')" /></label><span class="mono">{{ t('translate.displayed', { count: filteredMessages.length }) }}</span><button class="btn btn-primary" :disabled="!auth.isLoggedIn || !draftCount || batchSubmitting" @click="submitBatch"><Send :size="15" />{{ t('translate.batchSubmit', { count: draftCount }) }}</button></div>

    <p v-if="loading" class="state">{{ t('translate.loading') }}</p>
    <p v-else-if="error" class="state error">{{ error }}</p>
    <div v-else class="translation-table-wrap">
      <table class="translation-table"><thead><tr><th>Key</th><th>{{ t('translate.source') }}</th><th>{{ t('translate.reference') }}</th><th>{{ t('translate.translation') }}</th></tr></thead><tbody>
        <tr v-for="item in filteredMessages" :key="item.key"><td><code>{{ item.key }}</code><small v-if="item.description">{{ item.description }}</small></td><td>{{ item.source_text }}</td><td>{{ referenceLocale === 'en' ? item.source_text : (referenceMessages[item.key] || '—') }}</td><td><textarea v-model="draft[item.key]" :placeholder="t('translate.inputPlaceholder')" :aria-label="t('translate.translateKey', { key: item.key })" rows="2" /><small v-if="bestCandidate(item)">score {{ bestCandidate(item)?.score }}</small></td></tr>
      </tbody></table><p v-if="!filteredMessages.length" class="state">{{ t('translate.noResults') }}</p>
    </div>
    <p v-if="!auth.isLoggedIn" class="login-note">{{ t('translate.loginNote') }}</p>
  </div>
</template>

<style scoped>
.translate-page { width:100%; max-width:1100px; min-width:0; margin:0 auto; padding:var(--page-pad-top) 0 var(--page-pad-bottom); }
.translate-head { display:flex; justify-content:space-between; gap:24px; align-items:flex-end; border-bottom:1px solid var(--border); padding-bottom:20px; }
.eyebrow,.label { display:flex; align-items:center; gap:6px; color:var(--muted); font:10px var(--mono); letter-spacing:.06em; text-transform:uppercase; }
h1 { margin:7px 0 4px; font-size:26px; letter-spacing:-.03em; }
.translate-sub { margin:0; color:var(--muted); }
.locale-select { display:grid; gap:6px; color:var(--muted); font-size:12px; }
.locale-select select { min-width:220px; }
.coverage-card { display:flex; gap:18px; align-items:center; margin:22px 0 16px; padding:15px 18px; background:var(--surface); border:1px solid var(--border); border-radius:var(--r); }
.coverage-card strong { font:22px var(--mono); display:block; }.coverage-card span { color:var(--muted); font-size:12px; }.coverage-track { flex:1; height:7px; background:var(--surface-2); }.coverage-track span { display:block; height:100%; background:var(--accent); transition:width .2s; }.coverage-count { font-family:var(--mono); white-space:nowrap; }
.translate-toolbar { display:flex; justify-content:space-between; align-items:center; gap:12px; margin:14px 0; }.search-box { display:flex; align-items:center; gap:8px; width:min(440px,100%); min-width:0; padding:0 10px; background:var(--surface); border:1px solid var(--border); border-radius:var(--r); }.search-box input { flex:1; min-width:0; padding-left:0; border:0 !important; outline:0; box-shadow:none !important; background:transparent; }
.translation-table-wrap { width:100%; max-width:100%; min-width:0; overflow-x:auto; border:1px solid var(--border); background:var(--surface); }.translation-table { width:100%; border-collapse:collapse; table-layout:fixed; }.translation-table th { position:sticky; top:0; z-index:1; background:var(--surface-2); color:var(--muted); font:10px var(--mono); letter-spacing:.05em; text-align:left; text-transform:uppercase; }.translation-table th,.translation-table td { padding:10px; border-bottom:1px solid var(--border); vertical-align:top; overflow-wrap:anywhere; }.translation-table th:nth-child(1) { width:18%; }.translation-table th:nth-child(2),.translation-table th:nth-child(3) { width:24%; }.translation-table th:nth-child(4) { width:34%; }.translation-table code { display:block; color:var(--accent); font:11px var(--mono); overflow-wrap:anywhere; }.translation-table td small { display:block; margin-top:4px; color:var(--muted); }.translation-table textarea { display:block; width:100%; max-width:100%; min-height:68px; box-sizing:border-box; resize:vertical; }.state { text-align:center; padding:44px; color:var(--muted); }.error,.form-error { color:var(--down); }.login-note { margin-top:18px; color:var(--muted); font-size:12px; }
@media (max-width: 680px) { .translate-head,.translate-toolbar { align-items:stretch; flex-direction:column; }.locale-select select { width:100%; }.coverage-card { align-items:flex-start; flex-wrap:wrap; }.coverage-track { flex-basis:100%; order:3; }.translation-table { min-width:760px; } }
</style>
