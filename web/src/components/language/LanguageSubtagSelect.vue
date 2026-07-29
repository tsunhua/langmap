<script setup lang="ts">
import { ref, computed, watch, nextTick, onUnmounted } from 'vue'
import { listLanguageSubtags } from '@/api/languages'
import type { RegistrySubtag } from '@/api/languages'

const props = defineProps<{
  label: string
  modelValue: string
  type: 'language' | 'script' | 'region' | 'variant'
  prefix?: string
  placeholder?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: string]
  select: [subtag: RegistrySubtag]
}>()

const input = ref<HTMLInputElement>()
const open = ref(false)
const query = ref('')
const activeIndex = ref(-1)
const options = ref<RegistrySubtag[]>([])
const loading = ref(false)
const listId = `subtag-list-${Math.random().toString(36).slice(2, 8)}`

const filtered = computed(() => {
  const q = query.value.toLowerCase()
  if (!q) return options.value
  return options.value.filter(
    o =>
      o.subtag.toLowerCase().includes(q) ||
      o.descriptions.some(d => d.toLowerCase().includes(q)),
  )
})

const activeDescendant = computed(() => {
  if (activeIndex.value < 0 || activeIndex.value >= filtered.value.length) return undefined
  return `${listId}-opt-${activeIndex.value}`
})

watch(filtered, () => {
  activeIndex.value = filtered.value.length > 0 ? 0 : -1
})

let searchController: AbortController | null = null
let debounceTimer: ReturnType<typeof setTimeout> | null = null

async function runSearch() {
  searchController?.abort()
  const q = query.value.trim()
  if (!q) {
    options.value = []
    loading.value = false
    return
  }
  searchController = new AbortController()
  loading.value = true
  try {
    options.value = await listLanguageSubtags(props.type, q, props.prefix, searchController.signal)
  } catch (e: unknown) {
    if (!(e instanceof DOMException && e.name === 'AbortError')) {
      options.value = []
    }
  } finally {
    if (!searchController.signal.aborted) loading.value = false
  }
}

function onInput(e: Event) {
  const val = (e.target as HTMLInputElement).value
  query.value = val
  emit('update:modelValue', val)
  if (!open.value && val) open.value = true
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(runSearch, 200)
}

function openDropdown() {
  open.value = true
  activeIndex.value = filtered.value.length > 0 ? 0 : -1
}

function closeDropdown() {
  open.value = false
  activeIndex.value = -1
}

function selectOption(opt: RegistrySubtag) {
  emit('update:modelValue', opt.preferred_value ?? opt.subtag)
  emit('select', opt)
  query.value = ''
  options.value = []
  closeDropdown()
  nextTick(() => input.value?.focus())
}

function onKeydown(e: KeyboardEvent) {
  if (!open.value) {
    if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
      openDropdown()
      e.preventDefault()
    }
    return
  }
  switch (e.key) {
    case 'ArrowDown':
      e.preventDefault()
      activeIndex.value = Math.min(activeIndex.value + 1, filtered.value.length - 1)
      break
    case 'ArrowUp':
      e.preventDefault()
      activeIndex.value = Math.max(activeIndex.value - 1, 0)
      break
    case 'Enter':
      e.preventDefault()
      if (activeIndex.value >= 0 && activeIndex.value < filtered.value.length) {
        selectOption(filtered.value[activeIndex.value])
      }
      break
    case 'Escape':
      e.preventDefault()
      closeDropdown()
      break
  }
}

function onBlur(e: FocusEvent) {
  if (!(e.relatedTarget as HTMLElement)?.closest('.subtag-select')) {
    closeDropdown()
  }
}

onUnmounted(() => {
  searchController?.abort()
  if (debounceTimer) clearTimeout(debounceTimer)
})
</script>

<template>
  <div class="subtag-select">
    <label class="subtag-label">{{ label }}</label>
    <input
      ref="input"
      type="text"
      role="combobox"
      :value="query || modelValue"
      :aria-label="label"
      :aria-expanded="open"
      :aria-controls="listId"
      :aria-activedescendant="activeDescendant"
      :placeholder="placeholder"
      class="subtag-input"
      @input="onInput"
      @focus="openDropdown"
      @keydown="onKeydown"
      @blur="onBlur"
    />
    <ul
      v-if="open && (filtered.length > 0 || loading || query)"
      :id="listId"
      role="listbox"
      class="subtag-listbox"
    >
      <li v-if="loading" class="subtag-status">{{ $t('common.loading') }}</li>
      <li
        v-for="(opt, i) in filtered"
        :key="opt.subtag"
        :id="`${listId}-opt-${i}`"
        role="option"
        :aria-selected="i === activeIndex"
        class="subtag-option"
        @mousedown.prevent="selectOption(opt)"
        @mouseenter="activeIndex = i"
      >
        <span class="subtag-code">{{ opt.subtag }}</span>
        <span class="subtag-desc">{{ opt.descriptions[0] || '' }}</span>
      </li>
      <li v-if="!loading && filtered.length === 0 && query" class="subtag-status">
        {{ $t('languagePicker.noResults') }}
      </li>
    </ul>
  </div>
</template>

<style scoped>
.subtag-select {
  position: relative;
}
.subtag-label {
  display: block;
  font-size: 12px;
  font-weight: 500;
  color: var(--muted);
  margin-bottom: 4px;
}
.subtag-input {
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
.subtag-input:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent);
}
.subtag-listbox {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  margin: 2px 0 0;
  padding: 0;
  list-style: none;
  max-height: 200px;
  overflow-y: auto;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  box-shadow: 0 4px 12px oklch(0 0 0 / 0.1);
  z-index: 50;
}
.subtag-option {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  min-height: 44px;
  cursor: pointer;
  font-size: 13px;
}
.subtag-option:hover,
.subtag-option[aria-selected="true"] {
  background: var(--accent-soft);
}
.subtag-status {
  padding: 10px 12px;
  font-size: 13px;
  color: var(--muted);
  text-align: center;
}
.subtag-code {
  font-family: var(--mono);
  font-size: 12px;
  font-weight: 500;
  min-width: 32px;
}
.subtag-desc {
  color: var(--muted);
  font-size: 12px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
