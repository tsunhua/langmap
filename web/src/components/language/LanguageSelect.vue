<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from 'vue'
import type { LanguageFilterOption } from './languageFilterOptions'
import { X } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
const { t } = useI18n()

const props = defineProps<{
  modelValue: string[]
  options: LanguageFilterOption[]
}>()
const emit = defineEmits<{ 'update:modelValue': [value: string[]] }>()

const open = ref(false)
const query = ref('')
const inputRef = ref<HTMLInputElement>()
const activeIndex = ref(-1)
const listId = `lang-select-list-${Math.random().toString(36).slice(2, 8)}`

const selected = computed(() => props.modelValue)

function selectedName(code: string): string {
  return props.options.find(option => option.code === code)?.name || code
}

const filtered = computed(() => {
  const normalized = query.value.trim().toLocaleLowerCase()
  return props.options
    .filter(option => !selected.value.includes(option.code))
    .filter(option => !normalized || `${option.name} ${option.code}`.toLocaleLowerCase().includes(normalized))
    .slice(0, 20)
})

watch(filtered, () => {
  activeIndex.value = filtered.value.length > 0 ? 0 : -1
})

function add(code: string) {
  emit('update:modelValue', [...selected.value, code])
  query.value = ''
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
})
onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

<template>
  <div class="lang-select">
    <div class="lang-select-tagwrap" @click="inputRef?.focus()">
      <span v-for="code in selected" :key="code" class="lang-tag">
        {{ selectedName(code) }}
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
        @keydown="onKeydown"
        @blur="onBlur"
      />
    </div>
    <div
      v-if="open && (filtered.length > 0 || query)"
      :id="listId"
      role="listbox"
      class="lang-select-dropdown"
    >
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
        <span class="lang-opt-name">{{ l.name }}</span>
        <span class="lang-opt-meta"><span class="lang-opt-code">{{ l.code }}</span><span class="lang-opt-count">{{ l.count }}</span></span>
      </button>
      <div v-if="filtered.length === 0 && query" class="lang-loading">
        {{ t('languagePicker.noResults') }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.lang-select { position: relative; }
.lang-select-tagwrap {
  display: flex; flex-wrap: wrap; gap: 4px;
  padding: 4px 8px; border: 1px solid var(--border);
  border-radius: var(--r); background: var(--surface); min-height: 36px; cursor: text;
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
  border: none; outline: none; font-size: 13px; flex: 1; min-width: 80px;
  background: transparent; min-height: 28px;
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
.lang-opt-meta { display: inline-flex; align-items: center; gap: 8px; flex: 0 0 auto; }
.lang-opt-code { font-family: var(--mono); font-size: 12px; color: var(--muted); }
.lang-opt-count { min-width: 1.5em; text-align: right; color: var(--fg); font-variant-numeric: tabular-nums; }
.lang-loading { padding: 10px 12px; font-size: 13px; color: var(--muted); text-align: center; }
</style>
