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
      :aria-pressed="modelValue === opt.value"
      @click="emit('update:modelValue', opt.value)"
    >
      {{ opt.label }}
    </button>
  </div>
</template>

<style scoped>
.seg {
  display: inline-flex;
  border: 1px solid var(--border);
  border-radius: var(--r);
  overflow: hidden;
}
.seg-btn {
  padding: 4px 12px;
  font-family: var(--mono);
  font-size: 12px;
  border: none;
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
}
.seg-btn:hover { color: var(--fg); }
.seg-btn.on {
  background: var(--fg);
  color: var(--surface);
}
@media (max-width: 768px) {
  .seg-btn { min-height: 44px; padding: 10px 14px; }
}
</style>
