<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { useI18n } from 'vue-i18n'
import GraphNode from './GraphNode.vue'
import GraphEdges from './GraphEdges.vue'
import GraphToolbar from './GraphToolbar.vue'
import { buildDisplayTree } from './mappingGraphModel'
import { layoutMappingGraph } from './mappingGraphLayout'
import { useGraphViewport } from '@/composables/useGraphViewport'
import { useGraphDrag } from '@/composables/useGraphDrag'
import type { LayoutNode } from './mappingGraphLayout'
import type { MappingGraphResponse, NodeSize } from './mappingGraphTypes'

type SemanticLevel = 'compact' | 'medium' | 'full'

const props = defineProps<{
  graph: MappingGraphResponse
  selectedNodeId?: string | null
  semanticLevel?: SemanticLevel
  collapsedIds?: Set<string>
  currentHops?: number
  maxHops?: number
  isFullscreen?: boolean
}>()
const { t } = useI18n()

const emit = defineEmits<{
  select: [id: string]
  navigate: [id: string]
  clearSelection: []
  toggleCollapse: [id: string]
  changeHops: [hops: number]
  toggleFullscreen: []
}>()

const graphRef = ref<HTMLElement>()
const containerRef = ref<HTMLElement>()
const worldRef = ref<HTMLElement>()
const DEFAULT_NODE_SIZE: NodeSize = { width: 110, height: 40 }

const collapsedIds = computed<Set<string>>(() => props.collapsedIds ?? new Set())
const nodeSizes = ref<Map<string, NodeSize>>(new Map())

const displayTree = computed(() =>
  buildDisplayTree(props.graph, collapsedIds.value),
)

const layout = computed(() => {
  if (!displayTree.value.nodes.length) {
    return { nodes: [] as LayoutNode[], treeEdges: [], crossEdges: [], bounds: { x: 0, y: 0, width: 0, height: 0 } }
  }
  return layoutMappingGraph({
    rootId: props.graph.root_id,
    tree: displayTree.value,
    nodeSizes: nodeSizes.value.size > 0 ? nodeSizes.value : defaultSizes(),
    nodeMeta: graphNodeMeta.value,
  })
})

const layoutBounds = computed(() => layout.value.bounds)

function defaultSizes(): Map<string, NodeSize> {
  const m = new Map<string, NodeSize>()
  for (const n of props.graph.nodes) {
    m.set(n.expression_id, { ...DEFAULT_NODE_SIZE })
  }
  return m
}

const layoutNodeById = computed(() => {
  const m = new Map<string, LayoutNode>()
  for (const n of layout.value.nodes) m.set(n.id, n)
  return m
})

const graphNodeById = computed(() => {
  const m = new Map<string, MappingGraphResponse['nodes'][number]>()
  for (const node of props.graph.nodes) m.set(String(node.expression_id), node)
  return m
})

const graphNodeMeta = computed(() => {
  const m = new Map<string, { language: string; text: string }>()
  for (const node of props.graph.nodes) {
    m.set(String(node.expression_id), {
      language: node.language_name || node.lang_code,
      text: node.text,
    })
  }
  return m
})

const childCountByParent = computed(() => {
  const m = new Map<string, number>()
  for (const n of displayTree.value.nodes) {
    if (n.displayParentId !== null) {
      m.set(n.displayParentId, (m.get(n.displayParentId) ?? 0) + 1)
    }
  }
  return m
})

const scoreByNode = computed(() => {
  const m = new Map<string, number>()
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
  const s = new Set<string>()
  if (props.selectedNodeId) s.add(props.selectedNodeId)
  return s
})

const pathNodeIds = computed(() => {
  if (!props.selectedNodeId) return new Set<string>()
  const ids = new Set<string>()
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

const showCrossEdges = true

const viewport = useGraphViewport({
  containerRef: containerRef as any,
  worldRef: worldRef as any,
  bounds: layoutBounds,
})

const graphFullscreen = computed(() => props.isFullscreen ?? false)

watch(() => props.isFullscreen, (fs) => {
  if (fs === false) {
    nextTick(() => viewport.fit())
  }
})

const {
  positionOverrides,
  activeDrag,
  applyOverride,
  resetPositions,
  setActiveDrag,
} = useGraphDrag()

const zoomBasedLevel = ref<SemanticLevel>('full')
const currentSemanticLevel = computed<SemanticLevel>(() => props.semanticLevel ?? zoomBasedLevel.value)

watch(() => viewport.zoomPercent.value, (pct) => {
  const next: SemanticLevel = pct < 45 ? 'compact' : pct < 80 ? 'medium' : 'full'
  if (next !== zoomBasedLevel.value) {
    zoomBasedLevel.value = next
  }
})

const worldScale = computed(() => Math.max(0.25, viewport.zoomPercent.value / 100))

const effectiveLayoutNodes = computed<LayoutNode[]>(() => {
  return layout.value.nodes.map(n => {
    const o = positionOverrides.value.get(n.id)
    const d = activeDrag.value?.nodeId === n.id
      ? { x: activeDrag.value.worldX, y: activeDrag.value.worldY }
      : null
    const override = o ?? d
    if (!override) return n
    return { ...n, x: override.x, y: override.y }
  })
})

function onDragMove(nodeId: string, worldX: number, worldY: number) {
  setActiveDrag({ nodeId, worldX, worldY })
}

function onDragEnd(nodeId: string, worldX: number, worldY: number) {
  setActiveDrag(null)
  applyOverride(nodeId, worldX, worldY)
}

function handleReset() {
  viewport.reset()
  resetPositions()
}

function handleReflow() {
  resetPositions()
  nextTick(() => viewport.fit())
}

function onToggleCollapse(nodeId: string) {
  emit('toggleCollapse', nodeId)
}

// --- node measurement (post-mount) ---
let measured = false
let measureQueued = false
async function measureNodes() {
  if (!containerRef.value) return
  await nextTick()
  const els = containerRef.value.querySelectorAll<HTMLElement>('[data-node-id]')
  if (!els.length) return
  const sizes = new Map<string, NodeSize>()
  let changed = false
  for (const el of els) {
    const id = el.getAttribute('data-node-id')
    if (!id) continue
    // getBoundingClientRect() includes the graph zoom transform. Layout needs
    // the card's dimensions in world coordinates, otherwise a 25% zoom makes
    // a 56px card look like a 14px card and breaks collision spacing.
    const rect = el.getBoundingClientRect()
    const w = el.offsetWidth || Math.ceil(rect.width / worldScale.value) || DEFAULT_NODE_SIZE.width
    const h = el.offsetHeight || Math.ceil(rect.height / worldScale.value) || DEFAULT_NODE_SIZE.height
    const prev = nodeSizes.value.get(id)
    if (!prev || prev.width !== w || prev.height !== h) changed = true
    sizes.set(id, { width: w, height: h })
  }
  if (changed || !measured) {
    nodeSizes.value = sizes
    measured = true
  }
}

function scheduleMeasure() {
  if (measureQueued) return
  measureQueued = true
  nextTick(async () => {
    measureQueued = false
    await measureNodes()
  })
}

onMounted(() => {
  scheduleMeasure()
})
onUnmounted(() => {})

watch(
  () => [props.graph.nodes.length, collapsedIds.value.size],
  () => {
    measured = false
    scheduleMeasure()
  },
)

watch(currentSemanticLevel, () => {
  scheduleMeasure()
})

function onSelectNode(id: string) {
  emit('select', id)
}
function onEscape() {
  emit('clearSelection')
}
function onNavigateNode(id: string) {
  emit('navigate', id)
}

function onToggleFullscreen() {
  emit('toggleFullscreen')
}

function centerOnNodeById(nodeId: string) {
  const node = layoutNodeById.value.get(nodeId)
  if (node) viewport.centerOnNode(node.x, node.y)
}

defineExpose({ centerOnNodeById })

const layerStats = computed(() => {
  const parts: string[] = []
  for (const [depth, count] of Object.entries(props.graph.layer_counts)) {
    parts.push(`${t('components.depth', { depth })}: ${count}`)
  }
  return parts.join(' · ')
})
</script>

<template>
  <div ref="graphRef" class="mapping-graph" :class="{ 'is-fullscreen': graphFullscreen }" role="region" :aria-label="t('components.graphLabel')">
    <div ref="containerRef" class="graph-viewport" tabindex="-1" @keydown.escape="onEscape">
      <div ref="worldRef" class="graph-world">
        <GraphEdges
          :layout-nodes="effectiveLayoutNodes"
          :tree-edges="layout.treeEdges"
          :cross-edges="layout.crossEdges"
          :selected-node-ids="selectedSet"
          :path-node-ids="pathNodeIds"
          :show-cross-edges="showCrossEdges"
          :bounds="layout.bounds"
        />
        <GraphNode
          v-for="n in effectiveLayoutNodes"
          :key="n.id"
          :node-id="n.id"
          :text="graphNodeById.get(String(n.id))?.text ?? ''"
          :language-code="graphNodeById.get(String(n.id))?.lang_code ?? ''"
          :language-name="graphNodeById.get(String(n.id))?.language_name ?? null"
          :depth="n.depth"
          :x="n.x"
          :y="n.y"
          :display-parent-id="n.displayParentId"
          :child-count="childCountByParent.get(n.id) ?? 0"
          :score="scoreByNode.get(n.id) ?? null"
          :is-root="n.id === graph.root_id"
          :is-selected="selectedNodeId === n.id"
          :semantic-level="currentSemanticLevel"
          :world-scale="worldScale"
          @select="onSelectNode"
          @navigate="onNavigateNode"
          @drag-move="onDragMove"
          @drag-end="onDragEnd"
          @toggle-collapse="onToggleCollapse"
        />
      </div>
    </div>
    <GraphToolbar
      :zoom-percent="viewport.zoomPercent.value"
      :current-hops="props.currentHops ?? 1"
      :max-hops="props.maxHops ?? 1"
      :is-fullscreen="graphFullscreen"
      @zoom-in="viewport.zoomIn"
      @zoom-out="viewport.zoomOut"
      @fit="viewport.fit"
      @actual-size="viewport.actualSize"
      @reset="handleReset"
      @reflow="handleReflow"
      @change-hops="(h: number) => emit('changeHops', h as 1 | 2 | 3)"
      @toggle-fullscreen="onToggleFullscreen"
    />
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
</style>
