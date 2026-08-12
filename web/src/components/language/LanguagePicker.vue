<script setup lang="ts">
import { computed, nextTick, ref, watch } from 'vue'
import { X } from 'lucide-vue-next'
import { listLanguages, type Language } from '@/api/languageIdentity'

const props = defineProps<{ modelValue: string; label: string }>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
const input = ref<HTMLInputElement>()
const query = ref('')
const open = ref(false)
const loading = ref(false)
const options = ref<Language[]>([])
const activeIndex = ref(-1)
const listId = `language-picker-${Math.random().toString(36).slice(2, 8)}`
const selected = computed(() => options.value.find((item) => item.code === props.modelValue))

watch(query, async (value) => {
  if (!value.trim()) { options.value = []; activeIndex.value = -1; return }
  loading.value = true
  try {
    const page = await listLanguages(value.trim())
    options.value = page.items
    activeIndex.value = page.items.length ? 0 : -1
  } catch { options.value = []; activeIndex.value = -1 } finally { loading.value = false }
})

function select(code: string) { emit('update:modelValue', code); query.value = ''; open.value = false; nextTick(() => input.value?.focus()) }
function clear() { emit('update:modelValue', '') }
function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') { open.value = false; return }
  if (event.key === 'ArrowDown') { open.value = true; activeIndex.value = Math.min(activeIndex.value + 1, options.value.length - 1); event.preventDefault() }
  if (event.key === 'ArrowUp') { activeIndex.value = Math.max(activeIndex.value - 1, 0); event.preventDefault() }
  if (event.key === 'Enter' && activeIndex.value >= 0) { select(options.value[activeIndex.value].code); event.preventDefault() }
}
</script>

<template>
  <div class="identity-picker">
    <label class="picker-label">{{ label }}</label>
    <div v-if="modelValue && !open" class="picker-selected">
      <span>{{ selected?.name_en ?? modelValue }}</span><code>{{ modelValue }}</code>
      <button type="button" class="picker-clear" aria-label="Clear language" data-action="clear" @click="clear"><X :size="16" /></button>
    </div>
    <div v-else class="picker-input-wrap">
      <input ref="input" v-model="query" role="combobox" :aria-label="label" :aria-expanded="open" :aria-controls="listId" :aria-activedescendant="activeIndex >= 0 ? `${listId}-${activeIndex}` : undefined" placeholder="Search ISO 639-3 languages" @focus="open = true" @keydown="onKeydown">
      <div v-if="open && (loading || options.length || query)" :id="listId" role="listbox" class="picker-dropdown">
        <span v-if="loading" class="picker-state">Loading…</span>
        <button v-for="(item, index) in options" :id="`${listId}-${index}`" :key="item.code" type="button" role="option" :aria-selected="index === activeIndex" class="picker-option" @mousedown.prevent="select(item.code)">{{ item.name_en }} <code>{{ item.code }}</code></button>
        <span v-if="!loading && query && !options.length" class="picker-state">No ISO language found</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.identity-picker { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.picker-label { font-size: 12px; font-weight: 600; color: var(--muted); }
.picker-input-wrap { position: relative; }
input, .picker-selected { box-sizing: border-box; width: 100%; min-height: 44px; padding: 8px 12px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); color: var(--fg); }
.picker-selected { display: flex; align-items: center; gap: 8px; } .picker-selected span { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
code { font-family: var(--mono); color: var(--muted); font-size: 12px; } .picker-clear { min-width: 44px; min-height: 44px; margin: -8px -12px -8px 0; border: 0; background: transparent; color: var(--muted); }
.picker-dropdown { position: absolute; z-index: 20; inset: calc(100% + 2px) 0 auto; max-height: 240px; overflow: auto; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); box-shadow: 0 4px 12px oklch(0 0 0 / .12); }
.picker-option { display: flex; justify-content: space-between; width: 100%; min-height: 44px; padding: 8px 12px; border: 0; background: transparent; text-align: left; color: var(--fg); } .picker-option:hover, .picker-option[aria-selected="true"] { background: var(--accent-soft); }
.picker-state { display: block; padding: 10px 12px; color: var(--muted); font-size: 13px; }
</style>
