<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { ChevronDown, X } from 'lucide-vue-next'
import { listLanguages, type Language } from '@/api/languageIdentity'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { loadSearchLanguage, useSearchLanguages } from '@/composables/useSearchLanguages'

const props = withDefaults(defineProps<{
  modelValue: string
  label: string
  placeholder?: string
  variant?: 'default' | 'search'
  invalid?: boolean
  describedBy?: string
}>(), { variant: 'default' })
const { t } = useI18n()
const localeParams = useLocaleParams()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
const searchLanguages = useSearchLanguages()
const root = ref<HTMLElement>()
const input = ref<HTMLInputElement>()
const trigger = ref<HTMLButtonElement>()
const query = ref('')
const open = ref(false)
const registryLoading = ref(false)
const registryOptions = ref<Language[]>([])
const selectedLanguage = ref<Language | null>(null)
const activeIndex = ref(-1)
const listId = `language-picker-${Math.random().toString(36).slice(2, 8)}`
const inputId = `${listId}-input`
const localizedOptions = computed<Language[]>(() => [
  ...searchLanguages.groups.value.recent,
  ...searchLanguages.groups.value.alphabetical,
].map(({ code, name, name_en }) => ({ code, name, name_en })))
const options = computed(() => props.variant === 'search' ? localizedOptions.value : registryOptions.value)
const loading = computed(() => props.variant === 'search' ? searchLanguages.loading.value : registryLoading.value)
const selected = computed(() => {
  const option = options.value.find((item) => item.code === props.modelValue)
  if (option) return option
  return selectedLanguage.value?.code === props.modelValue ? selectedLanguage.value : undefined
})
const selectedLabel = computed(() => selected.value?.name || selected.value?.name_en || props.modelValue)

let selectionRequest = 0
let optionsRequest = 0
watch(() => props.modelValue, async (code) => {
  const request = ++selectionRequest
  if (!code) {
    selectedLanguage.value = null
    return
  }
  if (selectedLanguage.value?.code === code) return
  const option = options.value.find((item) => item.code === code)
  if (option) {
    selectedLanguage.value = option
    return
  }
  try {
    if (props.variant === 'search') {
      const language = await loadSearchLanguage(code, localeParams.value)
      if (request === selectionRequest && props.modelValue === code) selectedLanguage.value = language
      return
    }
    const page = await listLanguages(code, 50, 0, localeParams.value)
    if (request === selectionRequest && props.modelValue === code) {
      selectedLanguage.value = page.items.find((item) => item.code === code) ?? null
    }
  } catch {
    if (request === selectionRequest && props.modelValue === code) selectedLanguage.value = null
  }
}, { immediate: true })

async function loadOptions(value: string) {
  const request = ++optionsRequest
  if (!value.trim() && props.variant !== 'search') {
    registryOptions.value = []
    activeIndex.value = -1
    registryLoading.value = false
    return
  }
  activeIndex.value = -1
  if (props.variant === 'search') {
    try {
      await searchLanguages.loadSearchLanguages(localeParams.value, { query: value.trim() })
      if (request === optionsRequest) activeIndex.value = options.value.length ? 0 : -1
    } catch {
      if (request === optionsRequest) activeIndex.value = -1
    }
    return
  }
  registryOptions.value = []
  registryLoading.value = true
  try {
    const page = await listLanguages(value.trim(), 20, 0, localeParams.value)
    if (request !== optionsRequest) return
    registryOptions.value = page.items
    activeIndex.value = page.items.length ? 0 : -1
  } catch {
    if (request === optionsRequest) { registryOptions.value = []; activeIndex.value = -1 }
  } finally {
    if (request === optionsRequest) registryLoading.value = false
  }
}
watch(query, (value) => {
  if (open.value) void loadOptions(value)
})

function closeMenu() {
  open.value = false
  query.value = ''
  activeIndex.value = -1
}
function onFocusOut(event: FocusEvent) {
  if (props.variant !== 'search') return
  const nextTarget = event.relatedTarget as Node | null
  if (!nextTarget || !root.value?.contains(nextTarget)) closeMenu()
}
function onDocumentPointerDown(event: MouseEvent) {
  const target = event.target as Node | null
  if (props.variant === 'search' && target && !root.value?.contains(target)) closeMenu()
}
function toggleSearchMenu() {
  if (open.value) {
    closeMenu()
    return
  }
  open.value = true
  void loadOptions('')
  void nextTick(() => input.value?.focus())
}

function select(language: Language) {
  selectedLanguage.value = language
  emit('update:modelValue', language.code)
  closeMenu()
  void nextTick(() => (props.variant === 'search' ? trigger.value : input.value)?.focus())
}
function clear() { selectedLanguage.value = null; emit('update:modelValue', '') }
function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') {
    closeMenu()
    if (props.variant === 'search') void nextTick(() => trigger.value?.focus())
    return
  }
  if (event.key === 'ArrowDown') {
    if (!open.value && props.variant === 'search') toggleSearchMenu()
    else open.value = true
    if (options.value.length) activeIndex.value = (activeIndex.value + 1) % options.value.length
    event.preventDefault()
    return
  }
  if (event.key === 'ArrowUp') {
    if (!open.value && props.variant === 'search') toggleSearchMenu()
    if (options.value.length) activeIndex.value = activeIndex.value <= 0 ? options.value.length - 1 : activeIndex.value - 1
    event.preventDefault()
    return
  }
  if (event.key === 'Enter' && open.value && activeIndex.value >= 0) {
    const language = options.value[activeIndex.value]
    if (language) select(language)
    event.preventDefault()
    return
  }
  if (event.key === 'Tab') closeMenu()
}
onMounted(() => document.addEventListener('mousedown', onDocumentPointerDown))
onUnmounted(() => document.removeEventListener('mousedown', onDocumentPointerDown))
</script>

<template>
  <div ref="root" class="identity-picker" :class="{ 'identity-picker-search': variant === 'search' }" @focusout="onFocusOut">
    <label :for="variant === 'search' ? undefined : inputId" class="picker-label">{{ label }}</label>
    <template v-if="variant === 'search'">
      <button
        ref="trigger"
        type="button"
        role="combobox"
        class="search-trigger"
        :aria-label="modelValue ? `${label}: ${selectedLabel}, ${modelValue}` : label"
        :aria-expanded="open"
        :aria-controls="listId"
        aria-haspopup="listbox"
        :aria-activedescendant="open && activeIndex >= 0 ? `${listId}-${activeIndex}` : undefined"
        :aria-invalid="props.invalid || undefined"
        :aria-describedby="props.describedBy"
        :title="modelValue ? `${selectedLabel} (${modelValue})` : undefined"
        @click="toggleSearchMenu"
        @keydown="onKeydown"
      >
        <span class="search-trigger-name" :class="{ placeholder: !modelValue }">
          {{ modelValue ? selectedLabel : (placeholder ?? t('languagePicker.placeholder')) }}
        </span>
        <code v-if="modelValue" class="search-trigger-code">{{ modelValue }}</code>
        <ChevronDown :size="16" aria-hidden="true" class="search-chevron" />
      </button>
      <div v-if="open" :id="listId" role="listbox" class="search-dropdown" :aria-label="label" :aria-busy="loading">
        <label class="search-filter">
          <span class="sr-only">{{ placeholder ?? t('languagePicker.placeholder') }}</span>
          <input
            :id="inputId"
            ref="input"
            v-model="query"
            type="search"
            :aria-label="placeholder ?? t('languagePicker.placeholder')"
            :aria-activedescendant="activeIndex >= 0 ? `${listId}-${activeIndex}` : undefined"
            autocomplete="off"
            @keydown="onKeydown"
          >
        </label>
        <div v-if="loading" class="search-state" role="status">{{ t('common.loading') }}</div>
        <button
          v-for="(item, index) in options"
          :id="`${listId}-${index}`"
          :key="item.code"
          type="button"
          role="option"
          tabindex="-1"
          class="search-option"
          :class="{ active: activeIndex === index }"
          :aria-selected="modelValue === item.code"
          @mousedown.prevent="select(item)"
          @mouseenter="activeIndex = index"
        >
          <span class="search-option-name">{{ item.name ?? item.name_en }}</span>
          <code class="search-option-code">{{ item.code }}</code>
        </button>
        <div v-if="!loading && query && !options.length" class="search-state" role="status">
          {{ t('languagePicker.noResults') }}
        </div>
      </div>
    </template>
    <template v-else>
      <div v-if="modelValue && !open" class="picker-selected">
        <span>{{ selected?.name ?? selected?.name_en ?? modelValue }}</span><code>{{ modelValue }}</code>
        <button type="button" class="picker-clear" :aria-label="t('languagePicker.clear')" data-action="clear" @click="clear"><X :size="16" /></button>
      </div>
      <div v-else class="picker-input-wrap">
        <input :id="inputId" ref="input" v-model="query" role="combobox" :aria-label="label" :aria-invalid="props.invalid || undefined" :aria-describedby="props.describedBy" :aria-expanded="open" :aria-controls="listId" :aria-activedescendant="activeIndex >= 0 ? `${listId}-${activeIndex}` : undefined" :placeholder="props.placeholder ?? t('languagePicker.placeholder')" autocomplete="off" @focus="open = true" @keydown="onKeydown">
        <div v-if="open && (loading || options.length || query)" :id="listId" role="listbox" class="picker-dropdown">
          <span v-if="loading" class="picker-state">{{ t('common.loading') }}</span>
          <button v-for="(item, index) in options" :id="`${listId}-${index}`" :key="item.code" type="button" role="option" :aria-selected="index === activeIndex" class="picker-option" @mousedown.prevent="select(item)">{{ item.name ?? item.name_en }} <code>{{ item.code }}</code></button>
          <span v-if="!loading && query && !options.length" class="picker-state">{{ t('languagePicker.noResults') }}</span>
        </div>
      </div>
    </template>
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
.identity-picker-search { position: relative; }
.search-trigger {
  display: flex; align-items: center; gap: 6px; width: 100%; min-width: 0; min-height: 48px;
  padding: 0 12px; border: 1px solid var(--border); border-radius: var(--r);
  background: var(--surface); color: var(--fg); cursor: pointer; text-align: left; font: inherit;
}
.search-trigger:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.search-trigger-name {
  min-width: 0; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
  font-size: 14px;
}
.search-trigger-name.placeholder, .search-trigger-code, .search-chevron { color: var(--muted); }
.search-trigger-code, .search-option-code { flex: 0 0 auto; font-family: var(--mono); font-size: 11px; font-weight: 400; }
.search-chevron { flex: 0 0 auto; }
.search-dropdown {
  position: absolute; z-index: 40; top: calc(100% + 4px); left: 0; width: 100%;
  max-height: min(360px, calc(100vh - 120px)); overflow-y: auto;
  border: 1px solid var(--border); border-radius: var(--r); background: var(--surface);
  box-shadow: 0 6px 18px oklch(0 0 0 / .12);
}
.search-filter { display: block; padding: 8px 10px; border-bottom: 1px solid var(--border); }
.search-filter input {
  box-sizing: border-box; width: 100%; min-height: 40px; padding: 0 8px;
  border: 1px solid var(--border); border-radius: var(--r); background: var(--surface);
  color: var(--fg); font: inherit; font-size: 13px;
}
.search-filter input:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.search-option {
  display: flex; align-items: center; gap: 8px; width: 100%; min-height: 44px; padding: 8px 12px;
  border: 0; background: transparent; color: var(--fg); cursor: pointer; text-align: left;
}
.search-option:hover, .search-option.active, .search-option[aria-selected="true"] { background: var(--accent-soft); }
.search-option-name { min-width: 0; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 14px; }
.search-state { padding: 12px; color: var(--muted); font-size: 13px; text-align: center; }
.sr-only {
  position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden;
  clip: rect(0, 0, 0, 0); white-space: nowrap; border: 0;
}
</style>
