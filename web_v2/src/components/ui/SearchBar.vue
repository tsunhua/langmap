<script setup lang="ts">
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
    :placeholder="placeholder || '搜尋…'"
    :aria-label="placeholder || '搜尋'"
    :class="['search-input', { large }]"
    @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    @keydown.enter="emit('search')"
  />
</template>

<style scoped>
.search-input {
  width: 100%;
  padding: 6px 10px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  font-family: var(--font);
  font-size: 14px;
  background: var(--surface);
  color: var(--fg);
}
.search-input:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent);
}
.search-input.large {
  height: 44px;
  font-size: 16px;
}
</style>
