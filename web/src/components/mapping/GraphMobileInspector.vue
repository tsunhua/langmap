<script setup lang="ts">
import { computed, ref, watch, nextTick } from 'vue'
import { useI18n } from 'vue-i18n'
import VotePill from './VotePill.vue'
import ExpressionEvidenceList from './ExpressionEvidenceList.vue'
import type { ExpressionReading, LocaleAttestation } from '@/api/expressions'
import { getPrimaryIncomingEdge, getPathToRoot, getRelatedCrossEdges } from './mappingGraphModel'
import type { MappingGraphResponse, DisplayTree } from './mappingGraphTypes'

const props = defineProps<{
  selectedNodeId: string | null
  graph: MappingGraphResponse
  displayTree: DisplayTree
  anchorText: string
  collapsedIds?: Set<string>
  attestations?: LocaleAttestation[]
  readings?: ExpressionReading[]
}>()
const { t } = useI18n()

const isCollapsed = computed(() => {
  if (!props.selectedNodeId) return false
  return props.collapsedIds?.has(props.selectedNodeId) ?? false
})

const emit = defineEmits<{
  close: []
  navigate: [id: string]
  toggleCollapse: [id: string]
}>()

const sheetRef = ref<HTMLElement>()

const node = computed(() => {
  if (!props.selectedNodeId) return null
  return props.graph.nodes.find((n) => n.expression_id === props.selectedNodeId) ?? null
})

const primaryEdge = computed(() => {
  if (!props.selectedNodeId) return null
  return getPrimaryIncomingEdge(props.selectedNodeId, props.graph)
})

const pathToRoot = computed(() => {
  if (!props.selectedNodeId) return [] as string[]
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

let previousFocus: HTMLElement | null = null

watch(() => props.selectedNodeId, (id) => {
  if (id) {
    previousFocus = document.activeElement as HTMLElement
    nextTick(() => {
      sheetRef.value?.focus()
    })
  }
})

watch(() => props.selectedNodeId, (id) => {
  if (!id && previousFocus) {
    previousFocus.focus()
    previousFocus = null
  }
})

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') emit('close')
}

</script>

<template>
  <div
    v-if="selectedNodeId && node"
    ref="sheetRef"
    class="gm-sheet"
    role="dialog"
    :aria-label="t('components.nodeInfo')"
    tabindex="-1"
    @keydown="onKeydown"
  >
    <div class="gm-handle" aria-hidden="true">
      <span class="gm-handle-bar" />
    </div>

    <div class="gm-head">
      <h3 class="gm-title">{{ node.text }}</h3>
      <button class="gm-close" :aria-label="t('common.close')" @click="emit('close')">&times;</button>
    </div>

    <div class="gm-meta">
      <span class="gm-lang">{{ node.lang_code }}</span>
      <span v-if="node.language_name" class="gm-lang-name">{{ node.language_name }}</span>
      <span class="gm-depth">{{ t('components.depth', { depth: node.depth }) }}</span>
    </div>

    <div class="gm-section">
      <span class="gm-label">{{ t('components.sourcePath') }}</span>
      <span class="gm-path">{{ pathText }}</span>
    </div>

    <div v-if="primaryEdge" class="gm-score">
      <span class="gm-label">{{ t('components.mappingScore') }}</span>
      <VotePill
        :target-id="primaryEdge.edge_id"
        target-type="mapping"
        :score="primaryEdge.score"
      />
    </div>

    <div v-if="crossEdgeCount > 0" class="gm-multipath">
      <span class="gm-label">{{ t('components.otherRelations') }}</span>
      <span class="gm-count">{{ t('components.relationCount', { count: crossEdgeCount }) }}</span>
    </div>

    <ExpressionEvidenceList :attestations="attestations ?? []" :readings="readings ?? []" />

    <div v-if="node.expression_id !== graph.root_id" class="gm-acts">
      <button
        class="btn btn-sm"
        @click="emit('toggleCollapse', node.expression_id)"
      >
        {{ isCollapsed ? t('components.expandBranch') : t('components.collapseBranch') }}
      </button>
      <button
        class="btn btn-sm btn-primary"
        @click="emit('navigate', node.expression_id)"
      >
        {{ t('components.viewExpression') }}
      </button>
    </div>
  </div>
  <div v-else-if="selectedNodeId === null" />
</template>

<style scoped>
.gm-sheet {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: var(--surface);
  border-top-left-radius: var(--r);
  border-top-right-radius: var(--r);
  padding: 8px 16px 24px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  z-index: 100;
  box-shadow: 0 -4px 20px rgba(0,0,0,0.1);
  max-height: 60dvh;
  overflow-y: auto;
}

.gm-handle {
  display: flex;
  justify-content: center;
  padding: 4px 0;
}
.gm-handle-bar {
  width: 36px;
  height: 4px;
  background: var(--border);
  border-radius: 2px;
}

.gm-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 8px;
}
.gm-title {
  font-size: 15px;
  font-weight: 600;
  margin: 0;
  line-height: 1.3;
  word-break: break-word;
}
.gm-close {
  background: none;
  border: none;
  font-size: 22px;
  color: var(--muted);
  cursor: pointer;
  padding: 4px;
  line-height: 1;
  min-width: 44px;
  min-height: 44px;
  display: flex;
  align-items: center;
  justify-content: center;
}
.gm-close:hover { color: var(--fg); }
.gm-close:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; border-radius: 2px; }

.gm-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  font-size: 12px;
  color: var(--muted);
}
.gm-section {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.gm-label {
  font-family: var(--mono);
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--faint);
}
.gm-path {
  font-size: 12px;
  color: var(--muted);
  line-height: 1.4;
  word-break: break-word;
}
.gm-score {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.gm-multipath {
  display: flex;
  align-items: center;
  gap: 6px;
}
.gm-count {
  font-size: 13px;
  color: var(--accent);
  font-weight: 500;
}
.gm-acts {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
</style>
