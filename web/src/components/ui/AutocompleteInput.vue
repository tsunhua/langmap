<script setup lang="ts">
import { nextTick, onBeforeUnmount, ref } from 'vue'
import { useI18n } from 'vue-i18n'

export interface AutocompleteOption { code: string; label: string }

const props = defineProps<{
  modelValue: string
  label: string
  name?: string
  placeholder?: string
  required?: boolean
  pattern?: string
  search: (query: string) => Promise<AutocompleteOption[]>
}>()

const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
const { t } = useI18n()

const open = ref(false)
const options = ref<AutocompleteOption[]>([])
const activeIndex = ref(-1)
const input = ref<HTMLInputElement>()
let request = 0
let searchTimer: ReturnType<typeof setTimeout> | undefined

const listId = `autocomplete-${Math.random().toString(36).slice(2, 8)}`

async function load(value: string) {
  const id = ++request
  try {
    const items = await props.search(value)
    if (id !== request) return
    options.value = items
    activeIndex.value = items.length ? 0 : -1
  } catch {
    if (id !== request) return
    options.value = []
    activeIndex.value = -1
  }
}

function onInput(value: string) {
  emit('update:modelValue', value)
  open.value = true
  if (searchTimer) clearTimeout(searchTimer)
  searchTimer = setTimeout(() => void load(value), 150)
}

function select(option: AutocompleteOption) {
  emit('update:modelValue', option.code)
  options.value = []
  activeIndex.value = -1
  open.value = false
  nextTick(() => input.value?.focus())
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') { open.value = false; return }
  if (event.key === 'ArrowDown') { event.preventDefault(); open.value = true; activeIndex.value = Math.min(activeIndex.value + 1, options.value.length - 1) }
  if (event.key === 'ArrowUp') { event.preventDefault(); activeIndex.value = Math.max(activeIndex.value - 1, -1) }
  if (event.key === 'Enter' && open.value && activeIndex.value >= 0) { event.preventDefault(); select(options.value[activeIndex.value]) }
}

// Delay closing so a mousedown on a dropdown option lands before blur hides it.
function onBlur() {
  setTimeout(() => { open.value = false }, 120)
}

onBeforeUnmount(() => { if (searchTimer) clearTimeout(searchTimer) })
</script>

<template>
  <label class="ac-label">
    {{ label }}
    <div class="ac-wrap">
      <input
        ref="input"
        :name="name"
        :value="modelValue"
        :required="required"
        :pattern="pattern"
        :placeholder="placeholder"
        role="combobox"
        :aria-label="label"
        :aria-expanded="open"
        :aria-controls="listId"
        :aria-activedescendant="activeIndex >= 0 ? `${listId}-${activeIndex}` : undefined"
        autocomplete="off"
        @input="onInput(($event.target as HTMLInputElement).value)"
        @focus="open = true"
        @keydown="onKeydown"
        @blur="onBlur"
      >
      <div v-if="open && options.length" :id="listId" role="listbox" class="ac-dropdown">
        <button
          v-for="(option, index) in options"
          :id="`${listId}-${index}`"
          :key="option.code"
          type="button"
          role="option"
          :aria-selected="index === activeIndex"
          @mousedown.prevent="select(option)"
        >
          <span class="ac-option-label">{{ option.label }}</span>
          <code class="ac-option-code">{{ option.code }}</code>
        </button>
      </div>
      <p v-if="open && modelValue && !options.length" class="ac-empty">{{ t('autocomplete.noMatch') }}</p>
    </div>
  </label>
</template>

<style scoped>
.ac-label { display: grid; gap: 5px; font-size: 13px; color: var(--muted); }
.ac-wrap { position: relative; min-width: 0; }
.ac-wrap input { box-sizing: border-box; width: 100%; min-height: 44px; padding: 8px 10px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); color: var(--fg); font-family: var(--font); font-size: var(--text-ui); }
.ac-wrap input:focus { outline: none; border-color: var(--accent); box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent); }
.ac-dropdown { position: absolute; z-index: 20; top: calc(100% + 4px); left: 0; overflow-y: auto; width: 100%; max-height: 220px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); box-shadow: 0 4px 12px oklch(0 0 0 / .12); }
.ac-dropdown button { display: grid; grid-template-columns: minmax(0, 1fr) auto; align-items: center; gap: 4px 12px; width: 100%; min-height: 44px; padding: 6px 10px; box-sizing: border-box; border: 0; border-bottom: 1px solid var(--border); background: transparent; color: var(--fg); text-align: left; cursor: pointer; }
.ac-dropdown button:last-of-type { border-bottom: 0; }
.ac-dropdown button:hover, .ac-dropdown button[aria-selected="true"] { background: var(--accent-soft); }
.ac-option-label { min-width: 0; overflow-wrap: anywhere; line-height: 1.35; }
.ac-option-code { color: var(--muted); font-family: var(--mono); font-size: 11px; white-space: nowrap; }
.ac-empty { margin: 0; padding: 10px; color: var(--muted); font-size: 13px; }
</style>
