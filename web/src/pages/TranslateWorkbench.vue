<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Search, Send } from 'lucide-vue-next'
import { addUiLocale, getTranslationWorkbench, listUiLocales, submitTranslationMapping, type TranslationWorkbench, type WorkbenchMessage, type UiLocale } from '@/api/localization'
import { createExpression } from '@/api/expressions'
import { getLanguageLocale } from '@/api/languageIdentity'
import LanguageLocalePicker from '@/components/language/LanguageLocalePicker.vue'
import { useAuthStore } from '@/stores/auth'

const route = useRoute(); const router = useRouter(); const auth = useAuthStore()
const locales = ref<UiLocale[]>([]); const workbench = ref<TranslationWorkbench | null>(null); const draft = ref<Record<string, string>>({}); const initial = ref<Record<string, string>>({}); const query = ref(''); const error = ref(''); const busy = ref(false)
const code = computed(() => String(route.params.code || ''))
const messages = computed(() => (workbench.value?.messages ?? []).filter((item) => !query.value || `${item.key} ${item.source_text}`.toLowerCase().includes(query.value.toLowerCase())))
const percent = computed(() => Math.round((workbench.value?.coverage.coverage ?? 0) * 100))
const dirty = computed(() => Object.entries(draft.value).filter(([key, text]) => text.trim() && text.trim() !== (initial.value[key] ?? '').trim()))
async function refresh() { locales.value = await listUiLocales() }
async function load(next: string) { if (!next) return; const value = await getTranslationWorkbench(next); workbench.value = value; initial.value = Object.fromEntries(value.messages.map((item) => [item.key, item.candidates[0]?.text ?? ''])); draft.value = { ...initial.value } }
async function choose(next: string) { if (!next || next === code.value) return; if (!locales.value.some((item) => item.language_locale_code === next)) { await addUiLocale(next); await refresh() }; await router.push(`/translate/${encodeURIComponent(next)}`) }
async function submit() { if (!auth.isLoggedIn || !dirty.value.length) return; busy.value = true; try { const locale = await getLanguageLocale(code.value); for (const [key, text] of dirty.value) { const result = await createExpression({ lang_code: locale.lang_code, language_locale_code: locale.code, text: text.trim() }) as { expression: { id: string } }; await submitTranslationMapping({ message_key: key, target_expression_id: result.expression.id }) }; await load(code.value) } catch (cause) { error.value = cause instanceof Error ? cause.message : 'Submit failed' } finally { busy.value = false } }
onMounted(async () => { await refresh(); if (!code.value) { const first = locales.value.find((item) => item.status !== 'archived'); if (first) return router.replace(`/translate/${encodeURIComponent(first.language_locale_code)}`) }; await load(code.value) })
watch(code, load)
function best(item: WorkbenchMessage) { return item.candidates[0] }
</script>
<template><main class="translate-page"><header><h1>Translation workbench</h1><LanguageLocalePicker :model-value="code" label="Language Locale" @update:model-value="choose" /></header><section v-if="workbench" class="coverage-card"><strong>{{ percent }}%</strong><span>{{ workbench.coverage.translated }} / {{ workbench.coverage.total }}</span><small>{{ workbench.locale.status }} · {{ workbench.locale.activation_source || 'draft' }}</small></section><div class="toolbar"><label><Search :size="16" /><input v-model="query" type="search" placeholder="Search messages"></label><button class="btn btn-primary" :disabled="!dirty.length || busy" @click="submit"><Send :size="16" />Submit {{ dirty.length }}</button></div><p v-if="error" role="alert">{{ error }}</p><table v-if="workbench"><tbody><tr v-for="item in messages" :key="item.key"><th>{{ item.key }}</th><td>{{ item.source_text }}</td><td><textarea v-model="draft[item.key]" /><small v-if="best(item)">score {{ best(item)?.score }}</small></td></tr></tbody></table></main></template>
<style scoped>.translate-page{max-width:1100px;margin:auto;padding:24px}.translate-page header,.toolbar{display:flex;gap:16px;align-items:end;justify-content:space-between}.coverage-card{display:flex;gap:16px;margin:20px 0;padding:16px;border:1px solid var(--border);background:var(--surface)}.coverage-card strong{font:24px var(--mono)}.toolbar label{display:flex;min-height:44px;align-items:center;border:1px solid var(--border);padding:0 8px}.toolbar input{border:0;background:transparent}table{width:100%;border-collapse:collapse}th,td{padding:10px;border-bottom:1px solid var(--border);text-align:left;vertical-align:top}textarea{width:100%;min-height:68px}@media(max-width:680px){.translate-page header,.toolbar{align-items:stretch;flex-direction:column}}</style>
