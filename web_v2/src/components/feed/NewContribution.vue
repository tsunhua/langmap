<script setup lang="ts">
defineProps<{
  left_text: string
  left_lang: string
  right_text: string
  right_lang: string
  author?: string
}>()
</script>

<template>
  <div class="new-row">
    <span class="new-kind">映射</span>
    <div class="new-body">
      <span class="tx">{{ left_text }}</span>
      <span class="lang-badge">{{ left_lang }}</span>
      <span class="arrow">↔</span>
      <span class="tx">{{ right_text }}</span>
      <span class="lang-badge">{{ right_lang }}</span>
    </div>
    <div class="new-meta">
      <span v-if="author">{{ author }}</span>
    </div>
  </div>
</template>

<style scoped>
.new-row {
  display: grid;
  grid-template-columns: 60px 1fr auto;
  gap: 10px;
  align-items: center;
  padding: 8px 12px;
  border-bottom: 1px solid #EDE5D8;
}
.new-kind {
  font-family: "IBM Plex Mono", monospace;
  font-size: 11px;
  color: #4A6FA5;
}
.new-body { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.tx { font-size: 14px; }
.arrow { color: #4A6FA5; font-size: 13px; }
.new-meta { font-size: 12px; color: #4A6FA5; }
</style>
