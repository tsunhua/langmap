<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  expressions: Array<{ id: number; text: string; language_code: string }>
}>()

const edgeCount = computed(() => {
  const n = props.expressions.length
  return n * (n - 1) / 2
})

const nodes = computed(() => {
  const n = props.expressions.length
  const cx = 110, cy = 110, r = 80
  return props.expressions.map((e, i) => ({
    ...e,
    x: cx + r * Math.cos((2 * Math.PI * i) / Math.max(n, 1) - Math.PI / 2),
    y: cy + r * Math.sin((2 * Math.PI * i) / Math.max(n, 1) - Math.PI / 2),
  }))
})

const allEdges = computed(() => {
  const result: Array<{ x1: number; y1: number; x2: number; y2: number }> = []
  for (let i = 0; i < nodes.value.length; i++) {
    for (let j = i + 1; j < nodes.value.length; j++) {
      result.push({
        x1: nodes.value[i].x, y1: nodes.value[i].y,
        x2: nodes.value[j].x, y2: nodes.value[j].y,
      })
    }
  }
  return result
})
</script>

<template>
  <div class="clique-card">
    <h3>完全圖預覽</h3>
    <svg viewBox="0 0 220 220" class="clique-svg">
      <line v-for="(e, i) in allEdges" :key="'e'+i"
        :x1="e.x1" :y1="e.y1" :x2="e.x2" :y2="e.y2"
        stroke="#4A6FA5" stroke-width="1" opacity="0.4" />
      <circle v-for="(n, i) in nodes" :key="'n'+i"
        :cx="n.x" :cy="n.y" r="5"
        fill="#8B4513" />
    </svg>
    <div class="clique-meta">
      {{ expressions.length }} 個詞句 → {{ edgeCount }} 條映射
    </div>
  </div>
</template>

<style scoped>
.clique-card {
  padding: 16px;
  background: #F5F0E8;
  border-radius: 4px;
}
.clique-card h3 { font-size: 14px; margin-bottom: 8px; }
.clique-svg { width: 100%; max-width: 220px; display: block; margin: 0 auto; }
.clique-meta { text-align: center; font-family: "IBM Plex Mono", monospace; font-size: 13px; margin-top: 8px; }
</style>
