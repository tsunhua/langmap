<script setup lang="ts">
import { nextTick, ref, watch } from 'vue'
import { Plus, X } from 'lucide-vue-next'
import { listLanguageLocales, type LanguageLocale } from '@/api/languageIdentity'
import { useLocaleParams } from '@/composables/useLocaleParams'
import LanguageLocaleCreateDialog from './LanguageLocaleCreateDialog.vue'

const props = withDefaults(defineProps<{ modelValue: string; label: string; langCode?: string | undefined; allowCreate?: boolean }>(), { allowCreate: true })
const localeParams = useLocaleParams()
const emit = defineEmits<{
  'update:modelValue': [value: string]
  selected: [locale: LanguageLocale | null]
  created: [locale: LanguageLocale]
}>()
const input = ref<HTMLInputElement>()
const query = ref('')
const options = ref<LanguageLocale[]>([])
const open = ref(false)
const dialogOpen = ref(false)
const activeIndex = ref(-1)
const listId = `locale-picker-${Math.random().toString(36).slice(2, 8)}`
watch(query, async (value) => {
  if (!value.trim()) { options.value = []; return }
  try { options.value = (await listLanguageLocales({ lang_code: props.langCode, q: value.trim(), limit: 20, offset: 0, ...localeParams.value })).items; activeIndex.value = options.value.length ? 0 : -1 } catch { options.value = []; activeIndex.value = -1 }
})
function select(locale: LanguageLocale) {
  emit('update:modelValue', locale.code)
  emit('selected', locale)
  query.value = ''
  open.value = false
  nextTick(() => input.value?.focus())
}
function clear() {
  emit('update:modelValue', '')
  emit('selected', null)
}
function created(locale: LanguageLocale) { select(locale); emit('created', locale); dialogOpen.value = false }
function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') { open.value = false; return }
  if (event.key === 'ArrowDown') { open.value = true; activeIndex.value = Math.min(activeIndex.value + 1, options.value.length - 1); event.preventDefault() }
  if (event.key === 'ArrowUp') { activeIndex.value = Math.max(activeIndex.value - 1, 0); event.preventDefault() }
  if (event.key === 'Enter' && activeIndex.value >= 0) { select(options.value[activeIndex.value]); event.preventDefault() }
}
</script>

<template><div class="locale-picker"><label>{{ label }}</label><div v-if="modelValue && !open" class="selected"><code :title="modelValue">{{ modelValue }}</code><button type="button" aria-label="Clear locale" @click="clear"><X :size="16" /></button></div><div v-else class="input-wrap"><input ref="input" v-model="query" role="combobox" :aria-label="label" :aria-expanded="open" :aria-controls="listId" :aria-activedescendant="activeIndex >= 0 ? `${listId}-${activeIndex}` : undefined" placeholder="Search language locales" @focus="open = true" @keydown="onKeydown"><div v-if="open && (query || options.length)" :id="listId" role="listbox" class="dropdown"><button v-for="(locale, index) in options" :id="`${listId}-${index}`" :key="locale.code" type="button" role="option" :aria-selected="index === activeIndex" @mousedown.prevent="select(locale)"><span class="option-name">{{ locale.display_name ?? locale.name }}</span><span class="option-meta"><span v-if="locale.name && locale.name_en && locale.name !== locale.name_en">{{ locale.name_en }}</span><code>{{ locale.code }}</code></span></button><span v-if="query && !options.length" class="empty">No locale found</span></div></div><button v-if="allowCreate" type="button" class="btn btn-ghost create" data-action="create-locale" @click="dialogOpen = true"><Plus :size="16" /> Create locale</button><LanguageLocaleCreateDialog :open="dialogOpen" :lang-code="langCode" @close="dialogOpen = false" @created="created" /></div></template>

<style scoped>
.locale-picker { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.locale-picker > label { font-size: 12px; font-weight: 600; color: var(--muted); }
.input-wrap { position: relative; min-width: 0; }
.input-wrap input, .selected { width: 100%; min-height: 44px; box-sizing: border-box; padding: 8px 12px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); color: var(--fg); }
.selected { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.selected code { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.selected button { flex: none; min-width: 44px; min-height: 44px; margin: -8px -12px -8px 0; border: 0; background: transparent; color: var(--muted); cursor: pointer; }
.dropdown { position: absolute; z-index: 20; top: calc(100% + 4px); left: 0; overflow-y: auto; width: min(360px, calc(100vw - 32px)); max-height: 220px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); box-shadow: 0 4px 12px oklch(0 0 0 / .12); }
.dropdown button { display: grid; grid-template-columns: minmax(0, 1fr) auto; align-items: center; gap: 4px 12px; width: 100%; min-height: 44px; padding: 6px 10px; box-sizing: border-box; border: 0; border-bottom: 1px solid var(--border); background: transparent; color: var(--fg); text-align: left; cursor: pointer; }
.dropdown button:last-of-type { border-bottom: 0; }
.dropdown button:hover, .dropdown button[aria-selected="true"] { background: var(--accent-soft); }
.option-name { min-width: 0; overflow-wrap: anywhere; line-height: 1.35; }
.option-meta { display: flex; align-items: flex-end; flex-direction: column; gap: 1px; max-width: 150px; color: var(--muted); font-size: 11px; line-height: 1.3; text-align: right; overflow-wrap: anywhere; }
.option-meta code { color: inherit; white-space: normal; overflow-wrap: anywhere; }
.dropdown .empty { display: block; padding: 10px; color: var(--muted); font-size: 13px; }
.create { align-self: flex-start; min-height: 44px; }
</style>
