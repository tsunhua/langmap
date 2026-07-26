<script setup lang="ts">
import { computed } from 'vue'
import type { LayoutNode } from './mappingGraphLayout'
import type { MappingGraphEdge } from './mappingGraphTypes'

const props = defineProps<{
  layoutNodes: LayoutNode[]
  treeEdges: MappingGraphEdge[]
  crossEdges: MappingGraphEdge[]
  selectedNodeIds: Set<number>
  pathNodeIds: Set<number>
  showCrossEdges: boolean
  bounds: { x: number; y: number; width: number; height: number }
}>()

const nodeById = computed(() => {
  const m = new Map<number, LayoutNode>()
  for (const n of props.layoutNodes) m.set(n.id, n)
  return m
})

function edgeWidth(score: number): number {
  return Math.max(1.2, Math.min(5, Math.max(0, score) / 4))
}

interface RenderedEdge {
  key: string
  x1: number
  y1: number
  x2: number
  y2: number
  width: number
  depth: number
  kind: 'tree' | 'cross'
  dimmed: boolean
  highlighted: boolean
}

const renderedEdges = computed<RenderedEdge[]>(() => {
  const out: RenderedEdge[] = []
  const pos = (id: number) => nodeById.value.get(id)
  for (const e of props.treeEdges) {
    const a = pos(e.source_id)
    const b = pos(e.target_id)
    if (!a || !b) continue
    const highlighted =
      props.selectedNodeIds.has(e.source_id) || props.selectedNodeIds.has(e.target_id) ||
      props.pathNodeIds.has(e.source_id) || props.pathNodeIds.has(e.target_id)
    out.push({
      key: `t-${e.edge_id}`,
      x1: a.x,
      y1: a.y,
      x2: b.x,
      y2: b.y,
      width: edgeWidth(e.score),
      depth: e.depth,
      kind: 'tree',
      dimmed: props.pathNodeIds.size > 0 && !highlighted,
      highlighted,
    })
  }
  if (props.showCrossEdges) {
    for (const e of props.crossEdges) {
      const a = pos(e.source_id)
      const b = pos(e.target_id)
      if (!a || !b) continue
      const highlighted =
        props.selectedNodeIds.has(e.source_id) || props.selectedNodeIds.has(e.target_id)
      out.push({
        key: `c-${e.edge_id}`,
        x1: a.x,
        y1: a.y,
        x2: b.x,
        y2: b.y,
        width: 1,
        depth: e.depth,
        kind: 'cross',
        dimmed: !highlighted,
        highlighted,
      })
    }
  }
  return out
})
</script>

<template>
  <svg class="graph-edges" aria-hidden="true" width="10000" height="10000">
    <line
      v-for="e in renderedEdges"
      :key="e.key"
      :data-tree-edge="e.kind === 'tree' ? '' : undefined"
      :data-cross-edge="e.kind === 'cross' ? '' : undefined"
      :x1="e.x1"
      :y1="e.y1"
      :x2="e.x2"
      :y2="e.y2"
      :stroke-width="e.width"
      :class="['edge', e.kind, `depth-${e.depth}`, { dimmed: e.dimmed, highlighted: e.highlighted }]"
    />
  </svg>
</template>

<style scoped>
.graph-edges {
  position: absolute;
  top: 0;
  left: 0;
  overflow: visible;
  pointer-events: none;
}
.edge {
  stroke: var(--edge);
  fill: none;
  transition: opacity 0.15s;
}
.edge.cross {
  stroke: var(--muted);
  stroke-dasharray: 4 3;
  opacity: 0.4;
}
.edge.depth-2 { opacity: 0.75; }
.edge.depth-3 { opacity: 0.55; }
.edge.dimmed { opacity: 0.15; }
.edge.highlighted {
  stroke: var(--accent);
  opacity: 1;
}
.edge.cross.highlighted {
  opacity: 0.8;
}
@media (prefers-reduced-motion: reduce) {
  .edge { transition: none; }
}
</style>
