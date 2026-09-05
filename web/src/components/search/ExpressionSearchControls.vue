<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { ChevronDown, Search } from 'lucide-vue-next'
import type { ContentLanguage } from '@/api/languageIdentity'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { rememberSearchLanguage, useSearchLanguages } from '@/composables/useSearchLanguages'

const props = withDefaults(defineProps<{
  query: string
  language: string
  variant?: 'compact' | 'page'
  languageRequired?: boolean
}>(), {
  variant: 'compact',
  languageRequired: false,
})

const emit = defineEmits<{
  'update:query': [value: string]
  'update:language': [value: string]
  submit: []
}>()

const { t } = useI18n()
const localeParams = useLocaleParams()
const {
  groups,
  loading,
  loadError,
  loadSearchLanguages,
} = useSearchLanguages()

const root = ref<HTMLElement | null>(null)
const languageButton = ref<HTMLButtonElement | null>(null)
const searchInput = ref<HTMLInputElement | null>(null)
const menuOpen = ref(false)
const activeIndex = ref(-1)
const skipOptionClick = ref(false)

const listId = `expression-search-list-${Math.random().toString(36).slice(2, 8)}`
const recentHeadingId = `${listId}-recent-heading`
const allHeadingId = `${listId}-all-heading`
const languageRequiredId = `${listId}-required`

const groupedOptions = computed<{ recent: ContentLanguage[]; alphabetical: ContentLanguage[] }>(() => {
  const seen = new Set<string>()
  const recent: ContentLanguage[] = []
  const alphabetical: ContentLanguage[] = []

  for (const item of groups.value.recent) {
    if (item.expression_count > 0 && !seen.has(item.code)) {
      seen.add(item.code)
      recent.push(item)
    }
  }
  for (const item of groups.value.alphabetical) {
    if (item.expression_count > 0 && !seen.has(item.code)) {
      seen.add(item.code)
      alphabetical.push(item)
    }
  }

  return { recent, alphabetical }
})

const options = computed(() => [
  ...groupedOptions.value.recent,
  ...groupedOptions.value.alphabetical,
])

const selectedLanguage = computed(() => options.value.find(item => item.code === props.language))
const selectedName = computed(() => {
  if (!props.language) return t('search.chooseLanguage')
  return selectedLanguage.value?.name || selectedLanguage.value?.name_en || props.language
})
const hasLanguageLoadError = computed(() => Boolean(loadError.value))
const hasOptions = computed(() => options.value.length > 0)

const activeDescendant = computed(() => {
  if (!menuOpen.value || activeIndex.value < 0 || activeIndex.value >= options.value.length) return undefined
  return optionId(activeIndex.value)
})

function optionId(index: number): string {
  return `${listId}-option-${index}`
}

function optionName(item: ContentLanguage): string {
  return item.name || item.name_en || item.code
}

function formatCount(count: number): string {
  return count.toLocaleString()
}

function countLabel(item: ContentLanguage): string {
  return t('search.expressionsAvailable', { count: formatCount(item.expression_count) })
}

function optionLabel(item: ContentLanguage): string {
  return `${optionName(item)}, ${item.code}, ${countLabel(item)}`
}

function activeIndexForSelection(): number {
  const selectedIndex = options.value.findIndex(item => item.code === props.language)
  return selectedIndex >= 0 ? selectedIndex : (options.value.length > 0 ? 0 : -1)
}

function openMenu() {
  menuOpen.value = true
  activeIndex.value = activeIndexForSelection()
}

function toggleMenu() {
  if (menuOpen.value) {
    closeMenu()
  } else {
    openMenu()
  }
}

function closeMenu() {
  menuOpen.value = false
  activeIndex.value = -1
}

function selectLanguage(code: string) {
  if (!options.value.some(item => item.code === code)) return
  emit('update:language', code)
  rememberSearchLanguage(code)
  closeMenu()
  nextTick(() => languageButton.value?.focus())
}

function onOptionMouseDown(event: MouseEvent, code: string) {
  event.preventDefault()
  skipOptionClick.value = true
  selectLanguage(code)
}

function onOptionClick(code: string) {
  if (skipOptionClick.value) {
    skipOptionClick.value = false
    return
  }
  selectLanguage(code)
}

function onLanguageKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') {
    if (menuOpen.value) {
      closeMenu()
      event.preventDefault()
    }
    return
  }

  if (event.key === 'ArrowDown') {
    if (!menuOpen.value) {
      openMenu()
    } else if (options.value.length > 0) {
      activeIndex.value = (activeIndex.value + 1) % options.value.length
    }
    event.preventDefault()
    return
  }

  if (event.key === 'ArrowUp') {
    if (!menuOpen.value) {
      openMenu()
      if (options.value.length > 0) activeIndex.value = options.value.length - 1
    } else if (options.value.length > 0) {
      activeIndex.value = activeIndex.value <= 0 ? options.value.length - 1 : activeIndex.value - 1
    }
    event.preventDefault()
    return
  }

  if (event.key === 'Enter' && menuOpen.value && activeIndex.value >= 0) {
    const item = options.value[activeIndex.value]
    if (item) selectLanguage(item.code)
    event.preventDefault()
    return
  }

  if (event.key === 'Tab') closeMenu()
}

function onOptionKeydown(event: KeyboardEvent, code: string) {
  if (event.key === 'Enter' || event.key === ' ') {
    event.preventDefault()
    selectLanguage(code)
  }
}

function onFocusOut(event: FocusEvent) {
  const nextTarget = event.relatedTarget as Node | null
  if (!nextTarget || !root.value?.contains(nextTarget)) closeMenu()
}

function onDocumentPointerDown(event: MouseEvent) {
  const target = event.target as Node | null
  if (target && root.value?.contains(target)) return
  closeMenu()
}

function onSubmit() {
  if (loading.value) return
  emit('submit')
}

function onQueryKeydown(event: KeyboardEvent) {
  if (event.key !== 'Enter') return
  event.preventDefault()
  onSubmit()
}

function requestLanguageLoad() {
  loadSearchLanguages(localeParams.value).catch(() => {
    // The composable exposes the reactive error state for the inline message.
  })
}

function focusSearch() {
  closeMenu()
  searchInput.value?.focus()
}

function focusLanguage() {
  languageButton.value?.focus()
}

defineExpose({ focusSearch, focusLanguage })

watch(
  () => [localeParams.value.ui_locale, localeParams.value.secondary_ui_locale],
  requestLanguageLoad,
)

watch(options, (next) => {
  if (!menuOpen.value) return
  if (activeIndex.value >= next.length) activeIndex.value = activeIndexForSelection()
  if (activeIndex.value < 0 && next.length > 0) activeIndex.value = activeIndexForSelection()
})

onMounted(() => {
  document.addEventListener('mousedown', onDocumentPointerDown)
  document.addEventListener('click', onDocumentPointerDown)
  requestLanguageLoad()
})

onUnmounted(() => {
  document.removeEventListener('mousedown', onDocumentPointerDown)
  document.removeEventListener('click', onDocumentPointerDown)
})
</script>

<template>
  <div class="expression-search-field">
    <div
      ref="root"
      class="expression-search"
      :class="`variant-${variant}`"
      @focusout="onFocusOut"
    >
      <div class="expression-search-language-wrap">
        <button
          ref="languageButton"
          type="button"
          role="combobox"
          class="expression-search-language"
          :aria-label="props.language ? `${t('search.chooseLanguage')}: ${selectedName}` : t('search.chooseLanguage')"
          :aria-expanded="menuOpen"
          :aria-controls="listId"
          aria-haspopup="listbox"
          :aria-activedescendant="activeDescendant"
          :aria-invalid="props.languageRequired || undefined"
          :aria-describedby="props.languageRequired ? languageRequiredId : undefined"
          :title="selectedName"
          @click="toggleMenu"
          @keydown="onLanguageKeydown"
          @blur="closeMenu"
        >
          <span v-if="props.language && selectedLanguage" class="expression-search-language-name">
            {{ selectedName }}
          </span>
          <span v-else-if="props.language" class="expression-search-language-name">
            {{ props.language }}
          </span>
          <span v-else class="expression-search-language-name expression-search-language-placeholder">
            {{ t('search.chooseLanguage') }}
          </span>
          <code v-if="props.language" class="expression-search-language-code">{{ props.language }}</code>
          <ChevronDown :size="16" aria-hidden="true" class="expression-search-chevron" />
        </button>

        <div
          v-if="menuOpen"
          :id="listId"
          role="listbox"
          class="expression-search-dropdown"
          :aria-label="t('search.chooseLanguage')"
          :aria-busy="loading"
        >
          <div v-if="loading" class="expression-search-state" role="status">
            {{ t('common.loading') }}
          </div>

          <div
            v-if="groupedOptions.recent.length"
            role="group"
            class="expression-search-group"
            :aria-labelledby="recentHeadingId"
          >
            <div :id="recentHeadingId" class="expression-search-group-heading">
              {{ t('search.recentLanguages') }}
            </div>
            <button
              v-for="(item, index) in groupedOptions.recent"
              :id="optionId(index)"
              :key="item.code"
              type="button"
              role="option"
              tabindex="-1"
              class="expression-search-option"
              :class="{ active: activeIndex === index }"
              :aria-selected="props.language === item.code"
              :aria-label="optionLabel(item)"
              @mousedown="onOptionMouseDown($event, item.code)"
              @click="onOptionClick(item.code)"
              @keydown="onOptionKeydown($event, item.code)"
              @mouseenter="activeIndex = index"
            >
              <span class="expression-search-option-name">{{ optionName(item) }}</span>
              <code class="expression-search-option-code">{{ item.code }}</code>
              <span class="expression-search-option-count">{{ countLabel(item) }}</span>
            </button>
          </div>

          <div
            v-if="groupedOptions.alphabetical.length"
            role="group"
            class="expression-search-group"
            :aria-labelledby="allHeadingId"
          >
            <div :id="allHeadingId" class="expression-search-group-heading">
              {{ t('search.allLanguages') }}
            </div>
            <button
              v-for="(item, offset) in groupedOptions.alphabetical"
              :id="optionId(groupedOptions.recent.length + offset)"
              :key="item.code"
              type="button"
              role="option"
              tabindex="-1"
              class="expression-search-option"
              :class="{ active: activeIndex === groupedOptions.recent.length + offset }"
              :aria-selected="props.language === item.code"
              :aria-label="optionLabel(item)"
              @mousedown="onOptionMouseDown($event, item.code)"
              @click="onOptionClick(item.code)"
              @keydown="onOptionKeydown($event, item.code)"
              @mouseenter="activeIndex = groupedOptions.recent.length + offset"
            >
              <span class="expression-search-option-name">{{ optionName(item) }}</span>
              <code class="expression-search-option-code">{{ item.code }}</code>
              <span class="expression-search-option-count">{{ countLabel(item) }}</span>
            </button>
          </div>

          <div v-if="!loading && !hasOptions" class="expression-search-state" role="status">
            {{ t('search.allLanguages') }}
          </div>
        </div>
      </div>

      <label class="expression-search-query">
        <Search :size="16" aria-hidden="true" class="expression-search-icon" />
        <input
          ref="searchInput"
          type="search"
          class="expression-search-input"
          :value="props.query"
          :placeholder="t('search.placeholder')"
          :aria-label="t('search.title')"
          @input="emit('update:query', ($event.target as HTMLInputElement).value)"
          @keydown="onQueryKeydown"
        />
      </label>
    </div>

    <p v-if="props.languageRequired" :id="languageRequiredId" class="expression-search-required" role="status">
      {{ t('search.languageRequired') }}
    </p>
    <p v-if="hasLanguageLoadError" class="expression-search-error" role="alert">
      {{ t('search.languagesLoadFailed') }}
    </p>
  </div>
</template>

<style scoped>
.expression-search-field {
  width: 100%;
  min-width: 0;
  position: relative;
}

.expression-search {
  display: grid;
  grid-template-columns: minmax(138px, 0.42fr) minmax(180px, 1fr);
  width: 100%;
  min-width: 0;
  height: 40px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}

.expression-search.variant-page {
  height: 48px;
}

.expression-search-language-wrap {
  position: relative;
  min-width: 0;
  border-right: 1px solid var(--border);
}

.expression-search-language {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
  height: 100%;
  min-height: 40px;
  min-width: 0;
  padding: 0 10px;
  border: 0;
  border-radius: 0;
  background: transparent;
  color: var(--fg);
  cursor: pointer;
  text-align: left;
  font: inherit;
}

.expression-search.variant-page .expression-search-language {
  min-height: 48px;
}

.expression-search-language:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: -2px;
}

.expression-search-input:focus-visible {
  outline: none;
}

.expression-search-input:focus {
  border: 0;
  outline: none;
  box-shadow: none;
}

.expression-search-language-name {
  min-width: 0;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 14px;
}

.expression-search-language-placeholder {
  color: var(--muted);
}

.expression-search-language-code,
.expression-search-option-code {
  flex: 0 0 auto;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 11px;
  font-weight: 400;
}

.expression-search-chevron {
  flex: 0 0 auto;
  color: var(--muted);
}

.expression-search-query {
  display: flex;
  align-items: center;
  gap: 7px;
  min-width: 0;
  padding: 0 10px;
  color: var(--muted);
}

.expression-search-icon {
  flex: 0 0 auto;
}

.expression-search-input {
  width: 100%;
  min-width: 0;
  height: 100%;
  padding: 0;
  border: 0;
  outline: 0;
  background: transparent;
  color: var(--fg);
  font-family: var(--font);
  font-size: 14px;
}

.expression-search.variant-page .expression-search-input {
  font-size: 16px;
}

.expression-search-input:disabled {
  cursor: wait;
  opacity: 0.72;
}

.expression-search-dropdown {
  position: absolute;
  z-index: 40;
  top: calc(100% + 4px);
  left: 0;
  width: max(100%, 260px);
  max-width: min(340px, calc(100vw - 24px));
  max-height: min(360px, calc(100vh - 120px));
  overflow-y: auto;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  box-shadow: 0 6px 18px oklch(0 0 0 / 0.12);
}

.expression-search-group + .expression-search-group {
  border-top: 1px solid var(--border);
}

.expression-search-group-heading {
  padding: 8px 12px 5px;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.expression-search-option {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  min-height: 44px;
  padding: 8px 12px;
  border: 0;
  background: transparent;
  color: var(--fg);
  cursor: pointer;
  text-align: left;
}

.expression-search-option:hover,
.expression-search-option.active,
.expression-search-option[aria-selected='true'] {
  background: var(--accent-soft);
}

.expression-search-option-name {
  min-width: 0;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 14px;
}

.expression-search-option-count {
  flex: 0 0 auto;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 11px;
  white-space: nowrap;
}

.expression-search-state {
  padding: 12px;
  color: var(--muted);
  font-size: 13px;
  text-align: center;
}

.expression-search-required,
.expression-search-error {
  margin: 6px 0 0;
  font-size: 13px;
}

.expression-search-required {
  color: var(--accent);
}

.expression-search-error {
  color: var(--down);
}

@media (max-width: 768px) {
  .expression-search {
    grid-template-columns: 1fr;
    height: auto;
    gap: 8px;
    border: 0;
    background: transparent;
  }

  .expression-search-language-wrap {
    border: 0;
  }

  .expression-search-language,
  .expression-search-query {
    min-height: 44px;
    border: 1px solid var(--border);
    border-radius: var(--r);
    background: var(--surface);
  }

  .expression-search-language {
    height: 44px;
  }

  .expression-search.variant-page .expression-search-language {
    min-height: 48px;
    height: 48px;
  }

  .expression-search-query {
    padding: 0 12px;
  }

  .expression-search-input {
    min-height: 44px;
  }

  .expression-search-dropdown {
    width: 100%;
    max-width: none;
  }
}

@media (prefers-reduced-motion: reduce) {
  .expression-search-dropdown {
    scroll-behavior: auto;
  }
}
</style>
