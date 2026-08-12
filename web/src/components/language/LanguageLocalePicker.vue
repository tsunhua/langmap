<script setup lang="ts">
import { nextTick, ref, watch } from 'vue'
import { Plus, X } from 'lucide-vue-next'
import { listLanguageLocales, type LanguageLocale } from '@/api/languageIdentity'
import LanguageLocaleCreateDialog from './LanguageLocaleCreateDialog.vue'

const props = withDefaults(defineProps<{ modelValue: string; label: string; langCode?: string | undefined; allowCreate?: boolean }>(), { allowCreate: true })
const emit = defineEmits<{ 'update:modelValue': [value: string]; created: [locale: LanguageLocale] }>()
const input = ref<HTMLInputElement>()
const query = ref('')
const options = ref<LanguageLocale[]>([])
const open = ref(false)
const dialogOpen = ref(false)
const activeIndex = ref(-1)
const listId = `locale-picker-${Math.random().toString(36).slice(2, 8)}`
watch(query, async (value) => {
  if (!value.trim()) { options.value = []; return }
  try { options.value = (await listLanguageLocales({ lang_code: props.langCode, q: value.trim(), limit: 20, offset: 0 })).items; activeIndex.value = options.value.length ? 0 : -1 } catch { options.value = []; activeIndex.value = -1 }
})
function select(locale: LanguageLocale) { emit('update:modelValue', locale.code); query.value = ''; open.value = false; nextTick(() => input.value?.focus()) }
function created(locale: LanguageLocale) { select(locale); emit('created', locale); dialogOpen.value = false }
function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') { open.value = false; return }
  if (event.key === 'ArrowDown') { open.value = true; activeIndex.value = Math.min(activeIndex.value + 1, options.value.length - 1); event.preventDefault() }
  if (event.key === 'ArrowUp') { activeIndex.value = Math.max(activeIndex.value - 1, 0); event.preventDefault() }
  if (event.key === 'Enter' && activeIndex.value >= 0) { select(options.value[activeIndex.value]); event.preventDefault() }
}
</script>

<template><div class="locale-picker"><label>{{ label }}</label><div v-if="modelValue && !open" class="selected"><span>{{ modelValue }}</span><button type="button" aria-label="Clear locale" @click="emit('update:modelValue', '')"><X :size="16" /></button></div><div v-else class="input-wrap"><input ref="input" v-model="query" role="combobox" :aria-label="label" :aria-expanded="open" :aria-controls="listId" :aria-activedescendant="activeIndex >= 0 ? `${listId}-${activeIndex}` : undefined" placeholder="Search language locales" @focus="open = true" @keydown="onKeydown"><div v-if="open && (query || options.length)" :id="listId" role="listbox" class="dropdown"><button v-for="(locale, index) in options" :id="`${listId}-${index}`" :key="locale.code" type="button" role="option" :aria-selected="index === activeIndex" @mousedown.prevent="select(locale)">{{ locale.name }} <code>{{ locale.code }}</code></button><span v-if="query && !options.length">No locale found</span></div></div><button v-if="allowCreate" type="button" class="btn btn-ghost create" data-action="create-locale" @click="dialogOpen = true"><Plus :size="16" /> Create locale</button><LanguageLocaleCreateDialog :open="dialogOpen" :lang-code="langCode" @close="dialogOpen = false" @created="created" /></div></template>

<style scoped>
.locale-picker { display: flex; flex-direction: column; gap: 6px; min-width: 0; }.locale-picker > label { font-size: 12px; font-weight: 600; color: var(--muted); }.input-wrap { position: relative; }.input-wrap input, .selected { width: 100%; min-height: 44px; box-sizing: border-box; padding: 8px 12px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); color: var(--fg); }.selected { display: flex; align-items: center; justify-content: space-between; font-family: var(--mono); }.selected button { min-width: 44px; min-height: 44px; margin: -8px -12px -8px 0; border: 0; background: transparent; }.dropdown { position: absolute; z-index: 20; inset: calc(100% + 2px) 0 auto; overflow: auto; max-height: 240px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); }.dropdown button, .dropdown span { display: flex; justify-content: space-between; width: 100%; min-height: 44px; padding: 8px 12px; box-sizing: border-box; border: 0; background: transparent; color: var(--fg); text-align: left; }.dropdown button:hover { background: var(--accent-soft); }.create { align-self: flex-start; min-height: 44px; }
</style>
