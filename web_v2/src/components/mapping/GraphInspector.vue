<script setup lang="ts">
import { computed } from 'vue'
import VotePill from './VotePill.vue'
import { getPrimaryIncomingEdge, getPathToRoot, getRelatedCrossEdges } from './mappingGraphModel'
import type { MappingGraphResponse, DisplayTree } from './mappingGraphTypes'

const props = defineProps<{
  selectedNodeId: number | null
  graph: MappingGraphResponse
  displayTree: DisplayTree
  anchorText: string
}>()

const emit = defineEmits<{
  close: []
  navigate: [id: number]
}>()

const node = computed(() => {
  if (!props.selectedNodeId) return null
  return props.graph.nodes.find((n) => n.expression_id === props.selectedNodeId) ?? null
})

const primaryEdge = computed(() => {
  if (!props.selectedNodeId) return null
  return getPrimaryIncomingEdge(props.selectedNodeId, props.graph)
})

const pathToRoot = computed(() => {
  if (!props.selectedNodeId) return [] as number[]
  return getPathToRoot(props.selectedNodeId, props.displayTree)
})

const pathText = computed(() => {
  const ids = pathToRoot.value
  if (ids.length === 0) return ''
  const texts = ids.map((id) => {
    if (id === props.graph.root_id) return props.anchorText
    const n = props.graph.nodes.find((x) => x.expression_id === id)
    return n?.text ?? `#${id}`
  })
  return texts.reverse().join(' → ')
})

const relatedCrossEdges = computed(() => {
  if (!props.selectedNodeId) return [] as string[]
  return getRelatedCrossEdges(props.selectedNodeId, props.displayTree)
})

const crossEdgeCount = computed(() => relatedCrossEdges.value.length)
</script>

<template>
  <div
    v-if="selectedNodeId && node"
    class="graph-inspector"
    role="region"
    aria-label="節點資訊"
  >
    <div class="gi-head">
      <h3 class="gi-title">{{ node.text }}</h3>
      <button class="gi-close" aria-label="關閉資訊面板" @click="emit('close')">&times;</button>
    </div>

    <div class="gi-meta">
      <span class="gi-lang">{{ node.language_code }}</span>
      <span v-if="node.language_name" class="gi-lang-name">{{ node.language_name }}</span>
      <span class="gi-depth">深度 {{ node.depth }}</span>
    </div>

    <div class="gi-section">
      <span class="gi-label">來源路徑</span>
      <span class="gi-path">{{ pathText }}</span>
    </div>

    <div v-if="primaryEdge" class="gi-score">
      <span class="gi-label">映射評分</span>
      <VotePill
        :target-id="primaryEdge.edge_id"
        target-type="mapping"
        :score="primaryEdge.score"
      />
    </div>

    <div v-if="crossEdgeCount > 0" class="gi-multipath">
      <span class="gi-label">其他關係</span>
      <span class="gi-count">{{ crossEdgeCount }} 條</span>
    </div>

    <div v-if="node.expression_id !== graph.root_id" class="gi-acts">
      <button
        class="btn btn-sm btn-primary"
        @click="emit('navigate', node.expression_id)"
      >
        查看詞句詳情
      </button>
    </div>
  </div>

  <div v-else class="graph-inspector gi-empty">
    <p class="gi-hint">選取圖譜中的節點以查看詳細資訊</p>
    <p class="gi-stats">{{ graph.nodes.length - 1 }} 個映射節點 · {{ graph.edges.length }} 條關係</p>
  </div>
</template>

<style scoped>
.graph-inspector {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--r);
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 200px;
}
.gi-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 8px;
}
.gi-title {
  font-size: 15px;
  font-weight: 600;
  margin: 0;
  line-height: 1.3;
  word-break: break-word;
}
.gi-close {
  background: none;
  border: none;
  font-size: 20px;
  color: var(--muted);
  cursor: pointer;
  padding: 0 2px;
  line-height: 1;
}
.gi-close:hover { color: var(--fg); }
.gi-close:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; border-radius: 2px; }
.gi-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  font-size: 12px;
  color: var(--muted);
}
.gi-section {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.gi-label {
  font-family: var(--mono);
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--faint);
}
.gi-path {
  font-size: 12px;
  color: var(--muted);
  line-height: 1.4;
  word-break: break-word;
}
.gi-score {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.gi-multipath {
  display: flex;
  align-items: center;
  gap: 6px;
}
.gi-count {
  font-size: 13px;
  color: var(--accent);
  font-weight: 500;
}
.gi-acts {
  margin-top: 4px;
}
.gi-empty {
  justify-content: center;
  align-items: center;
  text-align: center;
  color: var(--muted);
}
.gi-hint {
  font-size: 13px;
  margin: 0;
}
.gi-stats {
  font-family: var(--mono);
  font-size: 11px;
  margin: 4px 0 0;
  color: var(--faint);
}
</style>
