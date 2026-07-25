<script setup lang="ts">
defineProps<{
  options: Array<{ value: string; label: string }>
  modelValue: string
}>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
</script>

<template>
  <div class="seg">
    <button
      v-for="opt in options"
      :key="opt.value"
      :class="['seg-btn', { on: modelValue === opt.value }]"
      @click="emit('update:modelValue', opt.value)"
    >
      {{ opt.label }}
    </button>
  </div>
</template>

<style scoped>
.seg {
  display: inline-flex;
  border: 1px solid #EDE5D8;
  border-radius: 4px;
  overflow: hidden;
}
.seg-btn {
  padding: 4px 12px;
  font-family: "IBM Plex Mono", monospace;
  font-size: 12px;
  border: none;
  background: transparent;
  cursor: pointer;
  transition: all 0.15s;
}
.seg-btn.on {
  background: #1A1A1A;
  color: #fff;
}
</style>
