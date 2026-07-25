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
    <span class="mc-node">
      <span class="mc-tx">{{ a_text }}</span>
      <span class="mc-lc">{{ a_lang }}</span>
    </span>
    <span :class="['mc-edge', scoreClass(score)]">
      <span class="mc-line"></span>
      <span class="mc-score">+{{ score }}</span>
      <span class="mc-line"></span>
    </span>
    <span class="mc-node r">
      <span class="mc-tx">{{ b_text }}</span>
      <span class="mc-lc">{{ b_lang }}</span>
    </span>
  </router-link>
</template>

<style scoped>
.map-card {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  align-items: center;
  gap: 12px;
  background: #fff;
  border: 1px solid #EDE5D8;
  border-radius: 6px;
  padding: 10px 14px;
  cursor: pointer;
  transition: border-color 0.12s;
  color: inherit;
  text-decoration: none;
}
.map-card:hover { border-color: #D4A574; }
.mc-node { display: flex; flex-direction: column; gap: 1px; min-width: 0; }
.mc-node.r { align-items: flex-end; text-align: right; }
.mc-tx {
  font-size: 14px;
  font-weight: 500;
  letter-spacing: -0.01em;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.mc-lc {
  font-family: "IBM Plex Mono", monospace;
  font-size: 10px;
  color: #6B7280;
}
.mc-edge { display: flex; align-items: center; gap: 5px; padding: 0; }
.mc-line { height: 3px; width: 20px; background: #4A6FA5; border-radius: 2px; opacity: 0.7; }
.mc-score {
  font-family: "IBM Plex Mono", monospace;
  font-variant-numeric: tabular-nums;
  font-size: 12px;
  font-weight: 500;
  color: #8B4513;
  white-space: nowrap;
}
.mc-edge.s4 .mc-line { width: 24px; height: 4px; }
.mc-edge.s3 .mc-line { width: 20px; height: 3px; }
.mc-edge.s2 .mc-line { width: 16px; height: 2px; opacity: 0.5; }
.mc-edge.s1 .mc-line { width: 13px; height: 2px; opacity: 0.35; }
</style>
