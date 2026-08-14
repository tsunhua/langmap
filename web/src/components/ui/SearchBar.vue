<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
const props = defineProps<{
  modelValue: string
  placeholder?: string
  large?: boolean
}>()
const emit = defineEmits<{
  'update:modelValue': [value: string]
  search: []
}>()
</script>

<template>
  <input
    type="search"
    :value="modelValue"
    :placeholder="placeholder || t('components.search') + '…'"
    :aria-label="placeholder || t('components.search')"
    :class="['search-input', { large }]"
    @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    @keydown.enter="emit('search')"
  />
</template>

<style scoped>
.search-input {
  width: 100%;
  min-height: 40px;
  padding: 6px 12px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  font-family: var(--font);
  font-size: 16px;
  background: var(--surface);
  color: var(--fg);
}
.search-input:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent);
}
.search-input.large {
  height: 48px;
  font-size: 16px;
}
</style>
