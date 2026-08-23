<script setup lang="ts">
defineProps<{
  id: string
  a_id: string
  a_text: string
  a_lang: string
  a_language_name?: string
  b_id: string
  b_text: string
  b_lang: string
  b_language_name?: string
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
  <!-- /mapping/:id takes an expression id, not an edge id; anchor on one endpoint. -->
  <router-link :to="`/mapping/${a_id}`" class="map-card">
    <span class="mc-node">
      <span class="mc-tx">{{ a_text }}</span>
      <span class="mc-lc" :title="a_lang">{{ a_language_name || a_lang }}</span>
    </span>
    <span :class="['mc-edge', scoreClass(score)]">
      <span class="mc-line"></span>
      <span class="mc-score">+{{ score }}</span>
      <span class="mc-line"></span>
    </span>
    <span class="mc-node r">
      <span class="mc-tx">{{ b_text }}</span>
      <span class="mc-lc" :title="b_lang">{{ b_language_name || b_lang }}</span>
    </span>
  </router-link>
</template>

<style scoped>
.map-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto minmax(0, 1fr);
  align-items: center;
  gap: 12px;
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 10px 14px;
  cursor: pointer;
  transition: border-color 0.12s, box-shadow 0.12s;
  color: inherit;
  text-decoration: none;
}
.map-card:hover { border-color: color-mix(in oklch, var(--accent) 45%, var(--border)); box-shadow: 0 2px 6px oklch(0 0 0 / 0.05); }
.mc-node { display: flex; flex-direction: column; gap: 1px; min-width: 0; }
.mc-node.r { align-items: flex-end; text-align: right; }
.mc-tx {
  width: 100%;
  min-width: 0;
  font-size: 18px;
  font-weight: 500;
  letter-spacing: -0.01em;
  overflow-wrap: anywhere;
}
.mc-lc {
  font-family: var(--mono);
  font-size: 13px;
  color: var(--muted);
}
.mc-edge { display: flex; align-items: center; gap: 5px; padding: 0; }
.mc-line { height: 3px; width: 20px; background: var(--edge); border-radius: 2px; opacity: 0.75; }
.mc-score {
  font-family: var(--mono);
  font-variant-numeric: tabular-nums;
  font-size: 14px;
  font-weight: 500;
  color: var(--accent);
  white-space: nowrap;
}
.mc-edge.s4 .mc-line { width: 24px; height: 4px; }
.mc-edge.s3 .mc-line { width: 20px; height: 3px; }
.mc-edge.s2 .mc-line { width: 16px; height: 2px; opacity: 0.5; }
.mc-edge.s1 .mc-line { width: 13px; height: 2px; opacity: 0.35; }

@media (max-width: 640px) {
  .map-card {
    grid-template-columns: minmax(0, 1fr);
    gap: 8px;
  }
  .mc-node.r {
    align-items: flex-start;
    text-align: left;
  }
  .mc-edge {
    grid-row: 2;
    justify-content: center;
  }
}
</style>
