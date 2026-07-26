<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()

const props = defineProps<{
  expressions: Array<{ text: string }>
}>()

const edgeCount = computed(() => {
  const n = props.expressions.length
  return n * (n - 1) / 2
})

const nodes = computed(() => {
  const n = props.expressions.length
  const cx = 110, cy = 110, r = n <= 1 ? 0 : 78
  return props.expressions.map((_, i) => {
    const a = -Math.PI / 2 + i * 2 * Math.PI / n
    return { x: cx + r * Math.cos(a), y: cy + r * Math.sin(a) }
  })
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
    <h3>{{ t('components.cliqueTitle') }}</h3>
    <svg viewBox="0 0 220 220" class="clique-svg">
      <line v-for="(e, i) in allEdges" :key="'e' + i"
        :x1="e.x1.toFixed(1)" :y1="e.y1.toFixed(1)" :x2="e.x2.toFixed(1)" :y2="e.y2.toFixed(1)"
        stroke="var(--edge)" stroke-width="1" opacity="0.4" />
      <circle v-for="(n, i) in nodes" :key="'n' + i"
        :cx="n.x.toFixed(1)" :cy="n.y.toFixed(1)" r="7"
        fill="var(--accent)" stroke="var(--surface)" stroke-width="2" />
    </svg>
    <div class="clique-meta">
      <span>{{ t('components.nodeCount', { count: expressions.length }) }}</span>
      <span>{{ t('components.edgeCount', { count: edgeCount }) }}</span>
    </div>
    <p class="clique-note">{{ t('components.cliqueNote') }}</p>
  </div>
</template>

<style scoped>
.clique-card {
  border: 1px solid var(--border); border-radius: var(--r);
  background: var(--surface); padding: 14px;
}
.clique-card h3 {
  font-size: 10px; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase;
  color: var(--muted); margin-bottom: 8px;
}
.clique-svg { width: 100%; height: auto; display: block; }
.clique-meta {
  display: flex; gap: 14px; justify-content: center; margin-top: 6px;
  font-family: var(--mono); font-size: 11px; color: var(--muted);
}
.clique-meta b { color: var(--fg); font-weight: 500; font-variant-numeric: tabular-nums; }
.clique-note {
  font-size: 11px; color: var(--faint); line-height: 1.5; margin-top: 10px;
  padding-top: 10px; border-top: 1px solid var(--border);
}
</style>
