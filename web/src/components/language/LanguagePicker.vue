<script setup lang="ts">
import { ref, computed, watch, onMounted, nextTick } from 'vue'
import { useI18n } from 'vue-i18n'
import { useLanguagesStore } from '@/stores/languages'
import { listRegistryLanguages } from '@/api/languages'
import type { Variety } from '@/api/languages'
import LanguageCreateDialog from './LanguageCreateDialog.vue'
import { Plus, X } from 'lucide-vue-next'

const { t } = useI18n()

const props = withDefaults(
  defineProps<{
    modelValue: string
    label: string
    allowCreate?: boolean
  }>(),
  { allowCreate: true },
)

const emit = defineEmits<{
  'update:modelValue': [value: string]
  created: [language: { code: string; name: string }]
}>()

const store = useLanguagesStore()
const input = ref<HTMLInputElement>()
const triggerRef = ref<HTMLDivElement>()
const open = ref(false)
const query = ref('')
const searchResults = ref<Variety[]>([])
const loading = ref(false)
const dialogOpen = ref(false)
const activeIndex = ref(-1)
const listId = `picker-list-${Math.random().toString(36).slice(2, 8)}`

const selectedLanguage = computed(() =>
  store.languages.find(l => l.code === props.modelValue),
)

const displayOptions = computed(() => {
  const q = query.value.toLowerCase()
  if (q.length < 2) return []
  return searchResults.value.filter(
    l => l.name.toLowerCase().includes(q) || l.code.toLowerCase().includes(q),
  ).slice(0, 20)
})

watch(displayOptions, () => {
  activeIndex.value = displayOptions.value.length > 0 ? 0 : -1
})

let searchController: AbortController | null = null

async function search() {
  searchController?.abort()
  if (query.value.length < 2) {
    searchResults.value = []
    return
  }
  searchController = new AbortController()
  loading.value = true
  try {
    searchResults.value = await listRegistryLanguages(query.value, searchController.signal)
  } catch {
    searchResults.value = []
  } finally {
    loading.value = false
  }
}

let debounceTimer: ReturnType<typeof setTimeout> | null = null
watch(query, () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(search, 200)
})

function selectLanguage(code: string) {
  const found = searchResults.value.find(l => l.code === code)
  if (found) store.upsertLanguage(found)
  emit('update:modelValue', code)
  query.value = ''
  open.value = false
  nextTick(() => input.value?.focus())
}

function clearSelection() {
  emit('update:modelValue', '')
}

function openCreateDialog() {
  dialogOpen.value = true
}

function handleDialogClose() {
  dialogOpen.value = false
  nextTick(() => input.value?.focus())
}

function handleCreated(lang: { code: string; name: string }) {
  emit('update:modelValue', lang.code)
  emit('created', lang)
}

function onBlur(e: FocusEvent) {
  if (!(e.relatedTarget as HTMLElement)?.closest('.lang-picker')) {
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
  const opts = displayOptions.value
  if (opts.length === 0) return
  if (e.key === 'ArrowDown') {
    activeIndex.value = (activeIndex.value + 1) % opts.length
    e.preventDefault()
  } else if (e.key === 'ArrowUp') {
    activeIndex.value = activeIndex.value <= 0 ? opts.length - 1 : activeIndex.value - 1
    e.preventDefault()
  } else if (e.key === 'Enter' && activeIndex.value >= 0) {
    selectLanguage(opts[activeIndex.value].code)
    e.preventDefault()
  }
}
</script>

<template>
  <div class="lang-picker">
    <label class="picker-label">{{ label }}</label>

    <div
      v-if="selectedLanguage && !open"
      class="picker-selected"
    >
      <span class="picker-selected-name">{{ selectedLanguage.name }}</span>
      <span class="picker-selected-code">{{ selectedLanguage.code }}</span>
      <button
        class="picker-clear"
        :aria-label="t('languagePicker.clear')"
        data-action="clear"
        @click="clearSelection"
      >
        <X :size="14" />
      </button>
    </div>

    <div v-else ref="triggerRef" class="picker-input-wrap">
      <input
        ref="input"
        v-model="query"
        type="text"
        role="combobox"
        :aria-label="label"
        :aria-expanded="open"
        :aria-controls="listId"
        :aria-activedescendant="activeIndex >= 0 ? `${listId}-opt-${activeIndex}` : undefined"
        :placeholder="t('languagePicker.placeholder')"
        class="picker-input"
        @focus="open = true"
        @blur="onBlur"
        @keydown="onKeydown"
      />
      <div
        v-if="open && (displayOptions.length > 0 || query.length >= 2)"
        :id="listId"
        role="listbox"
        class="picker-dropdown"
      >
        <div v-if="loading" class="picker-loading">{{ t('common.loading') }}</div>
        <button
          v-for="(l, i) in displayOptions"
          :key="l.code"
          :id="`${listId}-opt-${i}`"
          role="option"
          class="picker-option"
          :class="{ 'picker-option-active': i === activeIndex }"
          :aria-selected="i === activeIndex"
          @mousedown.prevent="selectLanguage(l.code)"
        >
          <span class="picker-option-name">{{ l.name }}</span>
          <span class="picker-option-code">{{ l.code }}</span>
        </button>
        <div v-if="!loading && displayOptions.length === 0 && query.length >= 2" class="picker-empty">
          <span>{{ t('languagePicker.noResults') }}</span>
          <button
            v-if="allowCreate"
            class="picker-empty-create"
            data-action="create-language"
            @mousedown.prevent="openCreateDialog"
          >
            <Plus :size="12" />
            {{ t('languagePicker.createLanguage') }}
          </button>
        </div>
      </div>
    </div>

    <button
      v-if="allowCreate && !selectedLanguage"
      class="picker-create btn btn-ghost"
      data-action="create-language"
      @click="openCreateDialog"
    >
      <Plus :size="14" />
      {{ t('languagePicker.createLanguage') }}
    </button>

    <LanguageCreateDialog
      :open="dialogOpen"
      @close="handleDialogClose"
      @created="handleCreated"
    />
  </div>
</template>

<style scoped>
.lang-picker {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.picker-label {
  font-size: 12px;
  font-weight: 500;
  color: var(--muted);
}
.picker-selected {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  min-height: 44px;
  background: var(--surface);
}
.picker-selected-name {
  font-size: 14px;
  font-weight: 500;
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.picker-selected-code {
  font-family: var(--mono);
  font-size: 12px;
  color: var(--muted);
}
.picker-clear {
  width: 44px;
  height: 44px;
  border: none;
  background: none;
  cursor: pointer;
  display: grid;
  place-items: center;
  color: var(--muted);
  border-radius: var(--r);
}
.picker-clear:hover {
  background: var(--bg);
  color: var(--fg);
}
.picker-input-wrap {
  position: relative;
}
.picker-input {
  width: 100%;
  min-height: 44px;
  padding: 8px 10px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  font-size: 14px;
  background: var(--surface);
  color: var(--fg);
  box-sizing: border-box;
}
.picker-input:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent);
}
.picker-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  margin: 2px 0 0;
  max-height: 240px;
  overflow-y: auto;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  box-shadow: 0 4px 12px oklch(0 0 0 / 0.1);
  z-index: 50;
}
.picker-loading,
.picker-empty {
  padding: 10px 12px;
  font-size: 13px;
  color: var(--muted);
  text-align: center;
}
.picker-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}
.picker-empty-create {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 6px 12px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  color: var(--accent);
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  min-height: 36px;
}
.picker-empty-create:hover {
  background: var(--accent-soft);
  border-color: var(--accent);
}
.picker-option {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  text-align: left;
  padding: 8px 12px;
  min-height: 44px;
  border: none;
  background: none;
  cursor: pointer;
  font-size: 13px;
  color: var(--fg);
}
.picker-option:hover {
  background: var(--accent-soft);
}
.picker-option-active {
  background: var(--accent-soft);
}
.picker-option-name {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.picker-option-code {
  font-family: var(--mono);
  font-size: 11px;
  color: var(--muted);
}
.picker-create {
  align-self: flex-start;
}
</style>
