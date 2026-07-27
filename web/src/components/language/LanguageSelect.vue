<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useLanguagesStore } from '@/stores/languages'
import { listRegistryLanguages } from '@/api/languages'
import type { RegistryLanguage } from '@/api/languages'
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
const searchResults = ref<RegistryLanguage[]>([])
const loading = ref(false)

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
    searchResults.value = await listRegistryLanguages(q, searchController.signal)
  } catch {
    searchResults.value = []
  } finally {
    loading.value = false
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

function add(code: string) {
  emit('update:modelValue', [...selected.value, code])
  query.value = ''
  searchResults.value = []
}

function remove(code: string) {
  emit('update:modelValue', selected.value.filter(c => c !== code))
}

function handleClickOutside(e: MouseEvent) {
  if (!(e.target as HTMLElement).closest('.lang-select')) {
    open.value = false
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
        <button :aria-label="t('components.removeLanguage', { code })" @click.stop="remove(code)"><X :size="10" aria-hidden="true" /></button>
      </span>
      <input
        ref="inputRef"
        v-model="query"
        class="lang-select-input"
        :placeholder="t('components.filterLanguages')"
        :aria-label="t('components.filterLanguages')"
        @focus="open = true"
        @input="onQueryChange"
      />
    </div>
    <div v-if="open && (filtered.length > 0 || loading)" class="lang-select-dropdown">
      <div v-if="loading" class="lang-loading">{{ t('common.loading') }}</div>
      <button
        v-for="l in filtered"
        :key="l.code"
        class="lang-opt"
        @click="add(l.code)"
      >
        {{ l.name }} ({{ l.code }})
      </button>
    </div>
    <div v-if="loadError" class="lang-err" role="alert">{{ loadError }}</div>
  </div>
</template>

<style scoped>
.lang-select { position: relative; }
.lang-select-tagwrap {
  display: flex; flex-wrap: wrap; gap: 4px;
  padding: 4px 8px; border: 1px solid var(--border);
  border-radius: var(--r); background: var(--surface); min-height: 32px; cursor: text;
}
.lang-select-tagwrap:focus-within { border-color: var(--accent); }
.lang-tag {
  display: inline-flex; align-items: center; gap: 4px;
  padding: 1px 6px; border-radius: 999px;
  background: var(--accent-soft); color: var(--accent);
  font-family: var(--mono); font-size: 10px;
}
.lang-tag button { border: none; background: none; cursor: pointer; font-size: 10px; color: var(--accent); display: grid; place-items: center; }
.lang-select-input { border: none; outline: none; font-size: 13px; flex: 1; min-width: 80px; background: transparent; }
.lang-select-dropdown {
  position: absolute; top: 100%; left: 0; right: 0;
  max-height: 200px; overflow-y: auto;
  background: var(--surface); border: 1px solid var(--border);
  border-radius: var(--r); box-shadow: 0 4px 12px oklch(0 0 0 / 0.1);
  z-index: 50;
}
.lang-opt {
  display: block; width: 100%; text-align: left;
  padding: 6px 10px; border: none; background: none;
  font-size: 13px; cursor: pointer; color: var(--fg);
}
.lang-opt:hover { background: var(--accent-soft); }
.lang-loading { padding: 6px 10px; font-size: 12px; color: var(--muted); text-align: center; }
.lang-err { font-size: 11px; color: var(--down); margin-top: 4px; }
</style>
