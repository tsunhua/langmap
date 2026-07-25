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
  padding: 12px 16px;
  background: #fff;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  text-align: center;
}
.stat-val {
  font-family: "IBM Plex Mono", monospace;
  font-size: 20px;
  font-weight: 600;
  color: #8B4513;
}
.stat-lbl {
  font-size: 12px;
  color: #4A6FA5;
  margin-top: 2px;
}
</style>
