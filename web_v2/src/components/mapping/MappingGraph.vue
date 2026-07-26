<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import GraphNode from './GraphNode.vue'
import GraphEdges from './GraphEdges.vue'
import GraphToolbar from './GraphToolbar.vue'
import { buildDisplayTree } from './mappingGraphModel'
import { layoutMappingGraph } from './mappingGraphLayout'
import { useGraphViewport } from '@/composables/useGraphViewport'
import type { LayoutNode } from './mappingGraphLayout'
import type { MappingGraphResponse, NodeSize, GraphBounds } from './mappingGraphTypes'

type SemanticLevel = 'compact' | 'medium' | 'full'

const props = defineProps<{
  graph: MappingGraphResponse
  selectedNodeId?: number | null
  semanticLevel?: SemanticLevel
}>()

const emit = defineEmits<{
  select: [id: number]
  navigate: [id: number]
}>()

const containerRef = ref<HTMLElement>()
const worldRef = ref<HTMLElement>()
const DEFAULT_NODE_SIZE: NodeSize = { width: 110, height: 40 }

const collapsedIds = ref<Set<number>>(new Set())
const nodeSizes = ref<Map<number, NodeSize>>(new Map())

const displayTree = computed(() =>
  buildDisplayTree(props.graph, collapsedIds.value),
)

const layoutBounds = computed<GraphBounds>(() => {
  if (!displayTree.value.nodes.length) {
    return { x: 0, y: 0, width: 0, height: 0 }
  }
  return layoutMappingGraph({
    rootId: props.graph.root_id,
    tree: displayTree.value,
    nodeSizes: nodeSizes.value.size > 0 ? nodeSizes.value : defaultSizes(),
  }).bounds
})

const layout = computed(() => {
  if (!displayTree.value.nodes.length) {
    return { nodes: [] as LayoutNode[], treeEdges: [], crossEdges: [], bounds: { x: 0, y: 0, width: 0, height: 0 } }
  }
  return layoutMappingGraph({
    rootId: props.graph.root_id,
    tree: displayTree.value,
    nodeSizes: nodeSizes.value.size > 0 ? nodeSizes.value : defaultSizes(),
  })
})

function defaultSizes(): Map<number, NodeSize> {
  const m = new Map<number, NodeSize>()
  for (const n of props.graph.nodes) {
    m.set(n.expression_id, { ...DEFAULT_NODE_SIZE })
  }
  return m
}

const layoutNodeById = computed(() => {
  const m = new Map<number, LayoutNode>()
  for (const n of layout.value.nodes) m.set(n.id, n)
  return m
})

const childCountByParent = computed(() => {
  const m = new Map<number, number>()
  for (const n of displayTree.value.nodes) {
    if (n.displayParentId !== null) {
      m.set(n.displayParentId, (m.get(n.displayParentId) ?? 0) + 1)
    }
  }
  return m
})

const scoreByNode = computed(() => {
  const m = new Map<number, number>()
  for (const n of props.graph.nodes) {
    if (n.depth === 0) continue
    const edge = props.graph.edges.find(
      (e) => e.source_id === n.expression_id || e.target_id === n.expression_id,
    )
    if (edge) m.set(n.expression_id, edge.score)
  }
  return m
})

const selectedSet = computed(() => {
  const s = new Set<number>()
  if (props.selectedNodeId) s.add(props.selectedNodeId)
  return s
})

const pathNodeIds = computed(() => {
  if (!props.selectedNodeId) return new Set<number>()
  const ids = new Set<number>()
  let current = props.selectedNodeId
  let guard = 0
  while (current && guard < 100) {
    ids.add(current)
    const node = layoutNodeById.value.get(current)
    if (!node || node.displayParentId === null) break
    current = node.displayParentId
    guard++
  }
  return ids
})

const currentSemanticLevel = computed<SemanticLevel>(() => props.semanticLevel ?? 'full')

const viewport = useGraphViewport({
  containerRef: containerRef as any,
  worldRef: worldRef as any,
  bounds: layoutBounds,
})

// --- node measurement (post-mount) ---
let measured = false
async function measureNodes() {
  if (!containerRef.value) return
  await nextTick()
  const els = containerRef.value.querySelectorAll<HTMLElement>('[data-node-id]')
  if (!els.length) return
  const sizes = new Map<number, NodeSize>()
  let changed = false
  for (const el of els) {
    const id = Number(el.getAttribute('data-node-id'))
    const rect = el.getBoundingClientRect()
    const w = Math.ceil(rect.width) || DEFAULT_NODE_SIZE.width
    const h = Math.ceil(rect.height) || DEFAULT_NODE_SIZE.height
    const prev = nodeSizes.value.get(id)
    if (!prev || prev.width !== w || prev.height !== h) changed = true
    sizes.set(id, { width: w, height: h })
  }
  if (changed || !measured) {
    nodeSizes.value = sizes
    measured = true
  }
}

onMounted(() => {
  measureNodes()
})
onUnmounted(() => {})

watch(
  () => [props.graph.nodes.length, collapsedIds.value.size],
  () => {
    measured = false
    nextTick(() => measureNodes())
  },
)

function onSelectNode(id: number) {
  emit('select', id)
}
function onNavigateNode(id: number) {
  emit('navigate', id)
}

const layerStats = computed(() => {
  const parts: string[] = []
  for (const [depth, count] of Object.entries(props.graph.layer_counts)) {
    parts.push(`${depth}跳 ${count}`)
  }
  return parts.join(' · ')
})
</script>

<template>
  <div class="mapping-graph" role="region" aria-label="詞句對照圖譜">
    <div ref="containerRef" class="graph-viewport">
      <div ref="worldRef" class="graph-world">
        <GraphEdges
          :layout-nodes="layout.nodes"
          :tree-edges="layout.treeEdges"
          :cross-edges="layout.crossEdges"
          :selected-node-ids="selectedSet"
          :path-node-ids="pathNodeIds"
          :show-cross-edges="false"
        />
        <GraphNode
          v-for="n in layout.nodes"
          :key="n.id"
          :node-id="n.id"
          :text="graph.nodes.find(gn => gn.expression_id === n.id)?.text ?? ''"
          :language-code="graph.nodes.find(gn => gn.expression_id === n.id)?.language_code ?? ''"
          :language-name="graph.nodes.find(gn => gn.expression_id === n.id)?.language_name ?? null"
          :depth="n.depth"
          :x="n.x"
          :y="n.y"
          :display-parent-id="n.displayParentId"
          :child-count="childCountByParent.get(n.id) ?? 0"
          :score="scoreByNode.get(n.id) ?? null"
          :is-root="n.id === graph.root_id"
          :is-selected="selectedNodeId === n.id"
          :semantic-level="currentSemanticLevel"
          @select="onSelectNode"
          @navigate="onNavigateNode"
        />
      </div>
    </div>
    <GraphToolbar
      :zoom-percent="viewport.zoomPercent.value"
      @zoom-in="viewport.zoomIn"
      @zoom-out="viewport.zoomOut"
      @fit="viewport.fit"
      @actual-size="viewport.actualSize"
      @reset="viewport.reset"
    />
    <div class="graph-legend">
      <span class="lr">● 根節點</span>
      <span class="lr">○ 一跳</span>
      <span class="lr lr-d2">○ 二跳</span>
      <span v-if="graph.layer_counts[3]" class="lr lr-d3">○ 三跳</span>
      <span v-if="graph.truncated" class="lr lr-warn">另有 {{ graph.omitted_count }} 個未載入</span>
    </div>
  </div>
</template>

<style scoped>
.mapping-graph {
  position: relative;
  width: 100%;
  height: clamp(520px, 68dvh, 820px);
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  background-image: radial-gradient(circle, oklch(0.90 0.010 88) 1px, transparent 1px);
  background-size: 18px 18px;
  overflow: hidden;
}
.graph-viewport {
  position: absolute;
  inset: 0;
  overflow: hidden;
}
.graph-world {
  position: absolute;
  top: 0;
  left: 0;
  transform-origin: 0 0;
}
.graph-legend {
  position: absolute;
  left: 12px;
  bottom: 12px;
  display: flex;
  flex-wrap: wrap;
  gap: 4px 10px;
  font-family: var(--mono);
  font-size: 10px;
  color: var(--muted);
  background: color-mix(in oklch, var(--surface) 90%, transparent);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 6px 10px;
  max-width: calc(100% - 24px);
}
.graph-legend .lr { display: flex; align-items: center; gap: 4px; }
.graph-legend .lr-d2 { opacity: 0.75; }
.graph-legend .lr-d3 { opacity: 0.55; }
.graph-legend .lr-warn { color: var(--accent); }
</style>
