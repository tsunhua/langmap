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
    type="text"
    :value="modelValue"
    :placeholder="placeholder || '搜尋…'"
    :class="['search-input', { large }]"
    @input="emit('update:modelValue', ($event.target as HTMLInputElement).value)"
    @keydown.enter="emit('search')"
  />
</template>

<style scoped>
.search-input {
  width: 100%;
  padding: 6px 10px;
  border: 1px solid #EDE5D8;
  border-radius: 4px;
  font-size: 14px;
  background: #fff;
}
.search-input.large {
  height: 44px;
  font-size: 16px;
}
</style>
