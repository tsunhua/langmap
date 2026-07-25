<script setup lang="ts">
import { computed } from 'vue'
import VotePill from './VotePill.vue'

const props = defineProps<{
  anchorId: number
  anchorText: string
  anchorLang: string
  mappings: Array<{
    expression_id: number
    text: string
    language_code: string
    score: number
    hops: number
    edge_id: string | null
  }>
}>()

const emit = defineEmits<{ select: [id: number] }>()

const VB_W = 800
const VB_H = 460

const nodes = computed(() => {
  const cx = VB_W / 2, cy = VB_H / 2, r = 175
  const items = props.mappings
  return items.map((m, i) => {
    const angle = (2 * Math.PI * i) / items.length - Math.PI / 2
    return {
      ...m,
      x: cx + r * Math.cos(angle),
      y: cy + r * Math.sin(angle),
      folded: m.score < 0,
    }
  })
})

const anchorPos = { x: VB_W / 2, y: VB_H / 2 }

function edgeWidth(score: number) {
  // 邊粗細 = 評分 — clamp to a 1.2–5px band
  return Math.max(1.2, Math.min(5, score / 4))
}

function pct(x: number, w: number) {
  return (x / w * 100) + '%'
}
</script>

<template>
  <div class="vb-stage">
    <svg :viewBox="`0 0 ${VB_W} ${VB_H}`" class="vb-svg" role="img"
         aria-label="對照集徑向圖譜:以錨點詞句為中心,連接各對應語言的映射節點">
      <line
        v-for="n in nodes.filter(n => n.hops === 1)"
        :key="'line-' + n.expression_id"
        :x1="anchorPos.x" :y1="anchorPos.y"
        :x2="n.x" :y2="n.y"
        stroke="var(--edge)"
        :stroke-width="edgeWidth(n.score)"
        class="vb-edge"
      />
      <line
        v-for="n in nodes.filter(n => n.hops === 2)"
        :key="'line2-' + n.expression_id"
        :x1="anchorPos.x" :y1="anchorPos.y"
        :x2="n.x" :y2="n.y"
        stroke="var(--edge)"
        stroke-width="1"
        stroke-dasharray="4 4"
        opacity="0.5"
        class="vb-edge vb-indirect"
      />
    </svg>

    <div
      class="vb-node anchor"
      :style="{ left: pct(anchorPos.x, VB_W), top: pct(anchorPos.y, VB_H) }"
    >
      <span class="vb-tx">{{ anchorText }}</span>
      <span class="vb-lc">{{ anchorLang }} · 錨點</span>
    </div>

    <div
      v-for="n in nodes"
      :key="n.expression_id"
      :class="['vb-node', { indirect: n.hops === 2, folded: n.folded }]"
      :style="{ left: pct(n.x, VB_W), top: pct(n.y, VB_H) }"
      tabindex="0"
      role="button"
      :aria-label="`${n.text} · ${n.language_code} · ${n.score} 評分`"
      @click.stop="emit('select', n.expression_id)"
      @keydown.enter="emit('select', n.expression_id)"
      @keydown.space.prevent="emit('select', n.expression_id)"
    >
      <span class="vb-tx">{{ n.text }}</span>
      <span class="vb-lc">{{ n.language_code }} · {{ n.score >= 0 ? '+' : '' }}{{ n.score }}</span>
      <span v-if="n.edge_id" class="vb-vote">
        <VotePill :target-id="n.edge_id" target-type="mapping" :score="n.score" />
      </span>
    </div>

    <div class="vb-legend">
      <div class="lr"><span class="ln"></span> 邊粗細 = 評分</div>
      <div class="lr"><span class="ln thin"></span> 間接 / 2 跳</div>
      <div class="lr hint">滑過節點 → 讚踩</div>
    </div>
  </div>
</template>

<style scoped>
.vb-stage {
  position: relative;
  width: 100%;
  aspect-ratio: 800 / 460;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  background-image: radial-gradient(circle, oklch(0.90 0.010 88) 1px, transparent 1px);
  background-size: 18px 18px;
  overflow: hidden;
}
.vb-svg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}
.vb-edge { transition: opacity 0.15s; }

.vb-node {
  position: absolute;
  transform: translate(-50%, -50%);
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 8px 12px;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  text-align: center;
  min-width: 90px;
  box-shadow: 0 1px 2px oklch(0 0 0 / 0.04);
  transition: transform 0.12s, box-shadow 0.12s, border-color 0.12s;
  z-index: 1;
}
.vb-node:hover {
  transform: translate(-50%, -50%) translateY(-2px);
  box-shadow: 0 4px 10px oklch(0 0 0 / 0.08);
  z-index: 4;
}
.vb-node:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
.vb-node .vb-tx { display: block; font-size: 13px; }
.vb-node .vb-lc {
  display: block;
  font-family: var(--mono);
  font-size: 10px;
  color: var(--muted);
  margin-top: 3px;
  font-weight: 400;
}

.vb-node.anchor {
  background: var(--accent);
  color: #fff;
  border-color: var(--accent);
  font-size: 16px;
  font-weight: 600;
  min-width: 110px;
  padding: 10px 16px;
  box-shadow: 0 0 0 6px color-mix(in oklch, var(--accent) 15%, transparent);
  cursor: default;
  z-index: 2;
}
.vb-node.anchor .vb-lc { color: oklch(0.92 0.04 35); }

.vb-node.indirect { opacity: 0.7; }

.vb-node.folded { opacity: 0.45; }
.vb-node.folded .vb-tx {
  text-decoration: line-through;
  text-decoration-color: var(--fold);
}

.vb-vote {
  position: absolute;
  bottom: -16px;
  left: 50%;
  transform: translateX(-50%);
  display: none;
  z-index: 5;
}
.vb-node:hover .vb-vote,
.vb-node:focus-within .vb-vote { display: inline-flex; }

.vb-legend {
  position: absolute;
  left: 12px;
  bottom: 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  font-family: var(--mono);
  font-size: 10px;
  color: var(--muted);
  background: color-mix(in oklch, var(--surface) 90%, transparent);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 8px 10px;
}
.vb-legend .lr { display: flex; align-items: center; gap: 6px; }
.vb-legend .lr.hint { color: var(--faint); margin-top: 2px; }
.vb-legend .ln { width: 22px; height: 2px; background: var(--edge); }
.vb-legend .ln.thin {
  height: 1px; opacity: 0.5;
  border-top: 1px dashed var(--edge);
  background: transparent;
}

@media (max-width: 640px) {
  .vb-node { padding: 4px 8px; min-width: 70px; }
  .vb-node .vb-tx { font-size: 12px; }
  .vb-node.anchor { font-size: 14px; min-width: 90px; }
  .vb-legend { font-size: 9px; padding: 6px 8px; }
  /* Vote pill shrinks in sync with the dense nodes (override the global 44px touch-target). */
  .vb-vote :deep(.vote button) { width: 22px; height: 22px; }
  .vb-vote :deep(.vote .score) { min-width: 24px; height: 22px; font-size: 11px; padding: 0 4px; }
}
</style>
