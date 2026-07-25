<script setup lang="ts">
defineProps<{
  id: string
  a_text: string
  a_lang: string
  b_text: string
  b_lang: string
  score: number
  source?: string
}>()

function scoreClass(score: number) {
  if (score >= 10) return 's4'
  if (score >= 5) return 's3'
  if (score >= 2) return 's2'
  return 's1'
}
</script>

<template>
  <router-link :to="`/mapping/${id}`" class="map-card">
    <div class="mc-node">
      <div class="mc-tx">{{ a_text }}</div>
      <span class="lang-badge">{{ a_lang }}</span>
    </div>
    <div class="mc-edge">
      <div :class="['mc-line', scoreClass(score)]"></div>
      <span class="mc-score">{{ score }}</span>
      <div :class="['mc-line', scoreClass(score)]"></div>
    </div>
    <div class="mc-node r">
      <div class="mc-tx">{{ b_text }}</div>
      <span class="lang-badge">{{ b_lang }}</span>
    </div>
  </router-link>
</template>

<style scoped>
.map-card {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: 12px;
  align-items: center;
  padding: 14px 16px;
  background: #fff;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  text-decoration: none;
  color: inherit;
  transition: box-shadow 0.15s;
}
.map-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
.mc-node { min-width: 0; }
.mc-node.r { text-align: right; }
.mc-tx {
  font-size: 15px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.mc-edge {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}
.mc-line {
  width: 24px;
  height: 2px;
  background: #4A6FA5;
  border-radius: 1px;
}
.mc-line.s3, .mc-line.s4 { height: 3px; width: 32px; }
.mc-line.s4 { width: 40px; }
.mc-score {
  font-family: "IBM Plex Mono", monospace;
  font-size: 12px;
  color: #4A6FA5;
}
</style>
