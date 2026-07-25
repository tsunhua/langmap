<script setup lang="ts">
import { computed } from 'vue'

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

const nodes = computed(() => {
  const cx = 400, cy = 230, r = 180
  const items = props.mappings
  return items.map((m, i) => {
    const angle = (2 * Math.PI * i) / items.length - Math.PI / 2
    return {
      ...m,
      x: cx + r * Math.cos(angle),
      y: cy + r * Math.sin(angle),
      angle,
    }
  })
})

const anchorPos = { x: 400, y: 230 }
</script>

<template>
  <div class="vb-stage">
    <svg viewBox="0 0 800 460" class="vb-svg">
      <line
        v-for="n in nodes.filter(n => n.hops === 1)"
        :key="'line-' + n.expression_id"
        :x1="anchorPos.x"
        :y1="anchorPos.y"
        :x2="n.x"
        :y2="n.y"
        stroke="#4A6FA5"
        :stroke-width="Math.max(1, n.score / 3)"
        class="vb-edge"
      />
      <line
        v-for="n in nodes.filter(n => n.hops === 2)"
        :key="'line2-' + n.expression_id"
        :x1="anchorPos.x"
        :y1="anchorPos.y"
        :x2="n.x"
        :y2="n.y"
        stroke="#4A6FA5"
        stroke-width="1"
        stroke-dasharray="4,4"
        opacity="0.5"
        class="vb-edge-indirect"
      />
    </svg>

    <div class="vb-node anchor" :style="{ left: anchorPos.x + 'px', top: anchorPos.y + 'px' }">
      <div class="vb-lc">{{ anchorLang }}</div>
      <div class="vb-tx">{{ anchorText }}</div>
    </div>

    <div
      v-for="n in nodes"
      :key="n.expression_id"
      :class="['vb-node', { indirect: n.hops === 2 }]"
      :style="{ left: n.x + 'px', top: n.y + 'px' }"
      @click.stop="emit('select', n.expression_id)"
    >
      <div class="vb-lc">{{ n.language_code }}</div>
      <div class="vb-tx">{{ n.text }}</div>
      <div class="vb-score">{{ n.score }}</div>
    </div>
  </div>
</template>

<style scoped>
.vb-stage {
  position: relative;
  height: 460px;
  background: #fff;
  border-radius: 4px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
  overflow: hidden;
}
.vb-svg {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}
.vb-node {
  position: absolute;
  transform: translate(-50%, -50%);
  background: #fff;
  border: 1px solid #EDE5D8;
  border-radius: 4px;
  padding: 4px 8px;
  font-size: 12px;
  cursor: pointer;
  transition: box-shadow 0.15s;
  white-space: nowrap;
  z-index: 1;
}
.vb-node:hover {
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}
.vb-node.anchor {
  background: #8B4513;
  color: #fff;
  border-color: #8B4513;
  box-shadow: 0 0 12px rgba(139,69,19,0.3);
  font-weight: 600;
  z-index: 2;
}
.vb-node.indirect {
  opacity: 0.6;
}
.vb-lc {
  font-family: "IBM Plex Mono", monospace;
  font-size: 10px;
  opacity: 0.7;
}
.vb-tx { font-size: 13px; }
.vb-score {
  font-family: "IBM Plex Mono", monospace;
  font-size: 10px;
  color: #8B4513;
}
.vb-node.anchor .vb-score { color: #fff; opacity: 0.8; }
</style>
