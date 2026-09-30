<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { ChevronDown, Plus, X } from 'lucide-vue-next'
import { getLanguageLocale, listLanguageLocales, type LanguageLocale } from '@/api/languageIdentity'
import { useLocaleParams } from '@/composables/useLocaleParams'
import LanguageLocaleCreateDialog from './LanguageLocaleCreateDialog.vue'

const props = withDefaults(defineProps<{
  modelValue: string
  label: string
  placeholder?: string
  langCode?: string | undefined
  variant?: 'default' | 'search'
  allowCreate?: boolean
  invalid?: boolean
  describedBy?: string
}>(), { allowCreate: true, variant: 'default' })
const { t } = useI18n()
const localeParams = useLocaleParams()
const emit = defineEmits<{
  'update:modelValue': [value: string]
  selected: [locale: LanguageLocale | null]
  created: [locale: LanguageLocale]
}>()
const root = ref<HTMLElement>()
const input = ref<HTMLInputElement>()
const trigger = ref<HTMLButtonElement>()
const query = ref('')
const options = ref<LanguageLocale[]>([])
const selectedLocale = ref<LanguageLocale | null>(null)
const open = ref(false)
const loading = ref(false)
const dialogOpen = ref(false)
const activeIndex = ref(-1)
const listId = `locale-picker-${Math.random().toString(36).slice(2, 8)}`
const inputId = `${listId}-input`
const englishUi = computed(() => localeParams.value.ui_locale?.startsWith('eng'))
function localeName(locale: LanguageLocale): string {
  const names = englishUi.value
    ? [locale.name_en, locale.display_name, locale.name]
    : [locale.display_name, locale.name, locale.name_en]
  return names.find(name => name?.trim() && name !== locale.code && name !== locale.lang_code) ?? locale.code
}
const selectedLabel = computed(() => selectedLocale.value ? localeName(selectedLocale.value) : props.modelValue)
const selectedCode = computed(() => selectedLocale.value?.code ?? props.modelValue)
watch(() => props.modelValue, (value) => {
  if (!value || selectedLocale.value?.code === value) {
    if (!value) selectedLocale.value = null
    return
  }
  void Promise.resolve()
    .then(() => getLanguageLocale(value, undefined, localeParams.value))
    .then((locale) => {
      if (props.modelValue === value) selectedLocale.value = locale
    })
    .catch(() => {
      if (props.modelValue === value) selectedLocale.value = null
    })
}, { immediate: true })
let optionsRequest = 0
async function loadOptions(value: string) {
  const request = ++optionsRequest
  if (!value.trim() && props.variant !== 'search') {
    options.value = []
    activeIndex.value = -1
    return
  }
  loading.value = true
  try {
    const page = await listLanguageLocales({ lang_code: props.langCode, q: value.trim(), limit: 20, offset: 0, ...localeParams.value })
    if (request !== optionsRequest) return
    options.value = page.items
    activeIndex.value = page.items.length ? 0 : -1
  } catch {
    if (request === optionsRequest) {
      options.value = []
      activeIndex.value = -1
    }
  } finally {
    if (request === optionsRequest) loading.value = false
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
  const nextTarget = event.relatedTarget as Node | null
  if (!nextTarget || !root.value?.contains(nextTarget)) closeMenu()
}
function onDocumentPointerDown(event: MouseEvent) {
  const target = event.target as Node | null
  if (target && !root.value?.contains(target)) closeMenu()
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
function select(locale: LanguageLocale) {
  selectedLocale.value = locale
  emit('update:modelValue', locale.code)
  emit('selected', locale)
  closeMenu()
  nextTick(() => (props.variant === 'search' ? trigger.value : input.value)?.focus())
}
function clear() {
  selectedLocale.value = null
  emit('update:modelValue', '')
  emit('selected', null)
  closeMenu()
}
function created(locale: LanguageLocale) { select(locale); emit('created', locale); dialogOpen.value = false }
function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') {
    closeMenu()
    if (props.variant === 'search') void nextTick(() => trigger.value?.focus())
    return
  }
  if (event.key === 'ArrowDown') {
    if (!open.value && props.variant === 'search') toggleSearchMenu()
    else open.value = true
    activeIndex.value = Math.min(activeIndex.value + 1, options.value.length - 1)
    event.preventDefault()
  }
  if (event.key === 'ArrowUp') { activeIndex.value = Math.max(activeIndex.value - 1, 0); event.preventDefault() }
  if (event.key === 'Enter' && activeIndex.value >= 0) { select(options.value[activeIndex.value]); event.preventDefault() }
}
onMounted(() => {
  document.addEventListener('mousedown', onDocumentPointerDown)
})
onUnmounted(() => {
  document.removeEventListener('mousedown', onDocumentPointerDown)
})
</script>

<template>
  <div ref="root" class="locale-picker" :class="{ 'locale-picker-search': variant === 'search' }" @focusout="onFocusOut">
    <label :for="variant === 'search' ? undefined : inputId">{{ label }}</label>

    <template v-if="variant === 'search'">
      <button
        ref="trigger"
        type="button"
        role="combobox"
        class="search-trigger"
        :aria-label="modelValue ? `${label}: ${selectedLabel}, ${selectedCode}` : label"
        :aria-expanded="open"
        :aria-controls="listId"
        aria-haspopup="listbox"
        :aria-activedescendant="activeIndex >= 0 ? `${listId}-${activeIndex}` : undefined"
        :aria-invalid="props.invalid || undefined"
        :aria-describedby="props.describedBy"
        :title="modelValue ? `${selectedLabel} (${selectedCode})` : undefined"
        @click="toggleSearchMenu"
        @keydown="onKeydown"
      >
        <span class="search-trigger-name" :class="{ placeholder: !modelValue }">
          {{ modelValue ? selectedLabel : (placeholder ?? t('localeCreate.searchPlaceholder')) }}
        </span>
        <code v-if="modelValue" class="search-trigger-code">{{ selectedCode }}</code>
        <ChevronDown :size="16" aria-hidden="true" class="search-chevron" />
      </button>

      <div
        v-if="open"
        :id="listId"
        role="listbox"
        class="search-dropdown"
        :aria-label="label"
        :aria-busy="loading"
      >
        <label class="search-filter">
          <span class="sr-only">{{ placeholder ?? t('localeCreate.searchPlaceholder') }}</span>
          <input
            :id="inputId"
            ref="input"
            v-model="query"
            type="search"
            :aria-label="placeholder ?? t('localeCreate.searchPlaceholder')"
            :aria-activedescendant="activeIndex >= 0 ? `${listId}-${activeIndex}` : undefined"
            autocomplete="off"
            @keydown="onKeydown"
          >
        </label>
        <div v-if="loading" class="search-state" role="status">{{ t('common.loading') }}</div>
        <button
          v-for="(locale, index) in options"
          :id="`${listId}-${index}`"
          :key="locale.code"
          type="button"
          role="option"
          tabindex="-1"
          class="search-option"
          :class="{ active: activeIndex === index }"
          :aria-selected="modelValue === locale.code"
          @mousedown.prevent="select(locale)"
          @mouseenter="activeIndex = index"
        >
          <span class="search-option-name">{{ localeName(locale) }}</span>
          <code class="search-option-code">{{ locale.code }}</code>
        </button>
        <div v-if="!loading && query && !options.length" class="search-state" role="status">
          {{ t('localeCreate.noResults') }}
        </div>
      </div>
    </template>

    <template v-else>
      <div v-if="modelValue && !open" class="selected">
        <span class="selected-name" :title="modelValue">{{ selectedLabel }}</span>
        <button type="button" :aria-label="t('languagePicker.clear')" @click="clear"><X :size="16" /></button>
      </div>
      <div v-else class="input-wrap">
        <input
          :id="inputId"
          ref="input"
          v-model="query"
          role="combobox"
          :aria-label="label"
          :aria-invalid="props.invalid || undefined"
          :aria-describedby="props.describedBy"
          :aria-expanded="open"
          :aria-controls="listId"
          :aria-activedescendant="activeIndex >= 0 ? `${listId}-${activeIndex}` : undefined"
          :placeholder="props.placeholder ?? t('localeCreate.searchPlaceholder')"
          autocomplete="off"
          @focus="open = true"
          @keydown="onKeydown"
        >
        <div v-if="open && (query || options.length)" :id="listId" role="listbox" class="dropdown">
          <button
            v-for="(locale, index) in options"
            :id="`${listId}-${index}`"
            :key="locale.code"
            type="button"
            role="option"
            :aria-selected="index === activeIndex"
            @mousedown.prevent="select(locale)"
          >
            <span class="option-name">{{ locale.display_name ?? locale.name }}</span>
            <span class="option-meta">
              <span v-if="locale.name && locale.name_en && locale.name !== locale.name_en">{{ locale.name_en }}</span>
              <code>{{ locale.code }}</code>
            </span>
          </button>
          <span v-if="query && !options.length" class="empty">{{ t('localeCreate.noResults') }}</span>
        </div>
      </div>
    </template>

    <button v-if="allowCreate" type="button" class="btn btn-ghost create" data-action="create-locale" @click="dialogOpen = true">
      <Plus :size="16" aria-hidden="true" /> {{ t('localeCreate.create') }}
    </button>
    <LanguageLocaleCreateDialog :open="dialogOpen" :lang-code="langCode" @close="dialogOpen = false" @created="created" />
  </div>
</template>

<style scoped>
.locale-picker { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.locale-picker > label { font-size: 12px; font-weight: 600; color: var(--muted); }
.input-wrap { position: relative; min-width: 0; }
.input-wrap input, .selected { width: 100%; min-height: 44px; box-sizing: border-box; padding: 8px 12px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); color: var(--fg); }
.selected { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.selected-name { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
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
.locale-picker-search { position: relative; }
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
