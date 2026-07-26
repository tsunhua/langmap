<script setup lang="ts">
defineProps<{
  label: string
  value: string | number
}>()
</script>

<template>
  <div class="stat-box">
    <div class="stat-val">{{ value }}</div>
    <div class="stat-lbl">{{ label }}</div>
  </div>
</template>

<style scoped>
.stat-box {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.stat-val {
  font-family: var(--mono);
  font-variant-numeric: tabular-nums;
  font-size: 19px;
  font-weight: 500;
  color: var(--fg);
}
.stat-lbl {
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--muted);
}
</style>
