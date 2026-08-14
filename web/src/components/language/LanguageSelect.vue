<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from 'vue'
import { useLanguagesStore } from '@/stores/languages'
import { listLanguages, type Language } from '@/api/languageIdentity'
import { X } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
const { t } = useI18n()

const props = defineProps<{
  modelValue: string[]
}>()
const emit = defineEmits<{ 'update:modelValue': [value: string[]] }>()

const store = useLanguagesStore()
const open = ref(false)
const query = ref('')
const inputRef = ref<HTMLInputElement>()
const loadError = ref('')
const searchResults = ref<Language[]>([])
const loading = ref(false)
const activeIndex = ref(-1)
const listId = `lang-select-list-${Math.random().toString(36).slice(2, 8)}`

const selected = computed(() => props.modelValue)

let searchController: AbortController | null = null
let debounceTimer: ReturnType<typeof setTimeout> | null = null

async function search(q: string) {
  searchController?.abort()
  if (!q.trim()) {
    searchResults.value = []
    return
  }
  searchController = new AbortController()
  loading.value = true
  try {
    searchResults.value = (await listLanguages(q, 20, 0, searchController.signal)).items
  } catch (e: unknown) {
    if (!(e instanceof DOMException && e.name === 'AbortError')) {
      searchResults.value = []
    }
  } finally {
    if (!searchController?.signal.aborted) loading.value = false
  }
}

function onQueryChange() {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => search(query.value), 200)
}

const filtered = computed(() => {
  return searchResults.value
    .filter(l => !selected.value.includes(l.code))
    .slice(0, 20)
})

watch(filtered, () => {
  activeIndex.value = filtered.value.length > 0 ? 0 : -1
})

function add(code: string) {
  const found = searchResults.value.find(l => l.code === code)
  if (found) store.upsertLanguage(found)
  emit('update:modelValue', [...selected.value, code])
  query.value = ''
  searchResults.value = []
  nextTick(() => inputRef.value?.focus())
}

function remove(code: string) {
  emit('update:modelValue', selected.value.filter(c => c !== code))
  nextTick(() => inputRef.value?.focus())
}

function handleClickOutside(e: MouseEvent) {
  if (!(e.target as HTMLElement).closest('.lang-select')) {
    open.value = false
  }
}

function onBlur(e: FocusEvent) {
  if (!(e.relatedTarget as HTMLElement)?.closest('.lang-select')) {
    open.value = false
  }
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape' && open.value) {
    open.value = false
    e.preventDefault()
    return
  }
  if (!open.value) {
    if (e.key === 'ArrowDown') {
      open.value = true
      e.preventDefault()
    }
    return
  }
  const opts = filtered.value
  if (opts.length === 0) return
  if (e.key === 'ArrowDown') {
    activeIndex.value = (activeIndex.value + 1) % opts.length
    e.preventDefault()
  } else if (e.key === 'ArrowUp') {
    activeIndex.value = activeIndex.value <= 0 ? opts.length - 1 : activeIndex.value - 1
    e.preventDefault()
  } else if (e.key === 'Enter' && activeIndex.value >= 0) {
    add(opts[activeIndex.value].code)
    e.preventDefault()
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
  store.fetchLanguages().catch(() => { loadError.value = t('components.languageLoadFailed') })
})
onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
  searchController?.abort()
  if (debounceTimer) clearTimeout(debounceTimer)
})
</script>

<template>
  <div class="lang-select">
    <div class="lang-select-tagwrap" @click="inputRef?.focus()">
      <span v-for="code in selected" :key="code" class="lang-tag">
        {{ store.getName(code) || code }}
        <button
          :aria-label="t('components.removeLanguage', { code })"
          class="lang-tag-remove"
          @click.stop="remove(code)"
        ><X :size="12" aria-hidden="true" /></button>
      </span>
      <input
        ref="inputRef"
        v-model="query"
        type="text"
        role="combobox"
        :aria-label="t('components.filterLanguages')"
        :aria-expanded="open"
        :aria-controls="listId"
        :aria-activedescendant="activeIndex >= 0 ? `${listId}-opt-${activeIndex}` : undefined"
        class="lang-select-input"
        :placeholder="t('components.filterLanguages')"
        @focus="open = true"
        @input="onQueryChange"
        @keydown="onKeydown"
        @blur="onBlur"
      />
    </div>
    <div
      v-if="open && (filtered.length > 0 || loading || query)"
      :id="listId"
      role="listbox"
      class="lang-select-dropdown"
    >
      <div v-if="loading" class="lang-loading">{{ t('common.loading') }}</div>
      <button
        v-for="(l, i) in filtered"
        :key="l.code"
        :id="`${listId}-opt-${i}`"
        role="option"
        :aria-selected="i === activeIndex"
        class="lang-opt"
        :class="{ 'lang-opt-active': i === activeIndex }"
        @mousedown.prevent="add(l.code)"
      >
        <span class="lang-opt-name">{{ l.name_en }}</span>
        <span class="lang-opt-code">{{ l.code }}</span>
      </button>
      <div v-if="!loading && filtered.length === 0 && query" class="lang-loading">
        {{ t('languagePicker.noResults') }}
      </div>
    </div>
    <div v-if="loadError" class="lang-err" role="alert">{{ loadError }}</div>
  </div>
</template>

<style scoped>
.lang-select { position: relative; }
.lang-select-tagwrap {
  display: flex; flex-wrap: wrap; gap: 4px;
  padding: 6px 10px; border: 1px solid var(--border);
  border-radius: var(--r); background: var(--surface); min-height: 48px; cursor: text;
  align-items: center;
}
.lang-select-tagwrap:focus-within {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent);
}
.lang-tag {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 4px 10px; border-radius: 999px;
  background: var(--accent-soft); color: var(--accent);
  font-family: var(--mono); font-size: 12px;
  min-height: 32px;
}
.lang-tag-remove {
  border: none; background: none; cursor: pointer;
  color: var(--accent); display: grid; place-items: center;
  width: 28px; height: 28px; border-radius: 999px;
}
.lang-tag-remove:hover { background: color-mix(in oklch, var(--accent) 15%, transparent); }
.lang-select-input {
  border: none; outline: none; font-size: 14px; flex: 1; min-width: 80px;
  background: transparent; min-height: 36px;
}
.lang-select-dropdown {
  position: absolute; top: 100%; left: 0; right: 0;
  max-height: 240px; overflow-y: auto;
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--r); box-shadow: 0 4px 12px oklch(0 0 0 / 0.1);
  z-index: 50;
}
.lang-opt {
  display: flex; align-items: center; gap: 8px;
  width: 100%; text-align: left;
  padding: 8px 12px; min-height: 44px; border: none; background: none;
  font-size: 14px; cursor: pointer; color: var(--fg);
}
.lang-opt:hover { background: var(--accent-soft); }
.lang-opt-active { background: var(--accent-soft); }
.lang-opt-name { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.lang-opt-code { font-family: var(--mono); font-size: 12px; color: var(--muted); }
.lang-loading { padding: 10px 12px; font-size: 13px; color: var(--muted); text-align: center; }
.lang-err { font-size: 13px; color: var(--down); margin-top: 4px; }
</style>
