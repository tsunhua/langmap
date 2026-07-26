<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useExpressions } from '@/composables/useExpressions'
import MappingGraph from '@/components/mapping/MappingGraph.vue'
import GraphInspector from '@/components/mapping/GraphInspector.vue'
import MappingHierarchyList from '@/components/mapping/MappingHierarchyList.vue'
import { buildDisplayTree } from '@/components/mapping/mappingGraphModel'
import type { MappingGraphResponse, DisplayTree } from '@/components/mapping/mappingGraphTypes'
import LangBadge from '@/components/expression/LangBadge.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { ArrowUpRight, Plus, ChevronRight } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const id = computed(() => parseInt(route.params.id as string))

const { detail, mappingGraph } = useExpressions()

const expr = ref<any>(null)
const graph = ref<MappingGraphResponse | null>(null)
const hops = ref<1 | 2 | 3>(1)
const loading = ref(true)
const loadError = ref('')
const selectedNodeId = ref<number | null>(null)
const collapsedIds = ref<Set<number>>(new Set())
const graphRef = ref<{ centerOnNodeById: (id: number) => void } | null>(null)

const MAX_HOPS = 3

async function load() {
  expr.value = null
  graph.value = null
  loading.value = true
  loadError.value = ''
  try {
    expr.value = await detail(id.value)
    graph.value = await mappingGraph(id.value, hops.value)
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  } finally {
    loading.value = false
  }
}

onMounted(load)
watch(id, load)

async function changeHops(h: 1 | 2 | 3) {
  hops.value = h
  try {
    graph.value = await mappingGraph(id.value, h)
  } catch (e: any) {
    loadError.value = e.response?.data?.error || '載入失敗'
  }
}

function selectNode(nodeId: number) {
  selectedNodeId.value = nodeId
}

function clearSelection() {
  selectedNodeId.value = null
}

function toggleCollapse(nodeId: number) {
  const next = new Set(collapsedIds.value)
  if (next.has(nodeId)) {
    next.delete(nodeId)
  } else {
    next.add(nodeId)
  }
  collapsedIds.value = next
}

function navigateToNode(nodeId: number) {
  if (nodeId === id.value) return
  router.push(`/mapping/${nodeId}`)
}

const directCount = computed(() => graph.value?.layer_counts[1] ?? 0)
const indirectCount = computed(() => (graph.value?.layer_counts[2] ?? 0) + (graph.value?.layer_counts[3] ?? 0))

const hasMappings = computed(() => (graph.value?.nodes.length ?? 0) > 1)

const displayTree = computed<DisplayTree>(() => {
  if (!graph.value) return { nodes: [], treeEdges: [], crossEdges: [] }
  return buildDisplayTree(graph.value)
})

function selectNodeFromList(nodeId: number) {
  selectedNodeId.value = nodeId
  graphRef.value?.centerOnNodeById(nodeId)
}

const coords = computed(() => {
  const lat = expr.value?.region_latitude
  const lng = expr.value?.region_longitude
  if (lat == null || lng == null) return null
  return `${lat}°N · ${lng}°E`
})

const sourceLabel = computed(() => {
  const t = expr.value?.source_type
  if (t === 'auth') return '權威'
  if (t === 'ai') return 'AI'
  if (t === 'user') return '用戶'
  return t || ''
})
</script>

<template>
  <LoadingSpinner v-if="loading" />

  <EmptyState v-else-if="loadError" :message="loadError" />

  <div v-else-if="expr" class="anchor">
    <nav class="crumbs" aria-label="麵包屑">
      <router-link to="/">首頁</router-link>
      <span class="sep">/</span>
      <span>{{ expr.text }}</span>
    </nav>

    <div class="anchor-title">
      <h1>{{ expr.text }}</h1>
      <LangBadge :code="expr.language_code" />
    </div>

    <div class="anchor-meta">
      <span>{{ expr.language_name }}</span>
      <span v-if="expr.region_name">· {{ expr.region_name }}</span>
      <span v-if="sourceLabel" :class="['src-tag', expr.source_type]">{{ sourceLabel }}</span>
      <span v-if="coords" class="mono coords">{{ coords }}</span>
    </div>

    <div class="anchor-acts">
      <router-link :to="`/contribute`" class="btn btn-primary btn-sm">
        <Plus :size="14" aria-hidden="true" /> 添加映射
      </router-link>
      <router-link :to="`/map/${expr.id}`" class="btn btn-sm">
        <ArrowUpRight :size="14" aria-hidden="true" /> 在地圖看此概念
      </router-link>
    </div>

    <div class="nb-head">
      <h2>對照集</h2>
      <span class="nb-meta">
        <b>{{ directCount }}</b> 直接映射<template v-if="indirectCount"> · <b>{{ indirectCount }}</b> 間接</template>
        · <b>{{ hops }}</b> 跳
      </span>
    </div>

    <template v-if="hasMappings">
      <div class="md-graph-area">
        <MappingGraph ref="graphRef"
          :graph="graph!"
          :selected-node-id="selectedNodeId"
          :collapsed-ids="collapsedIds"
          :current-hops="hops"
          :max-hops="MAX_HOPS"
          @select="selectNode"
          @navigate="navigateToNode"
          @clear-selection="clearSelection"
          @toggle-collapse="toggleCollapse"
          @change-hops="(h: number) => changeHops(h as 1 | 2 | 3)"
        />
        <GraphInspector
          :selected-node-id="selectedNodeId"
          :graph="graph!"
          :display-tree="displayTree"
          :anchor-text="expr.text"
          @close="clearSelection"
          @navigate="navigateToNode"
          @toggle-collapse="toggleCollapse"
        />
      </div>

      <MappingHierarchyList
        :tree="displayTree"
        :graph="graph!"
        :selected-node-id="selectedNodeId"
        :collapsed-ids="collapsedIds"
        @select="selectNodeFromList"
        @toggle-collapse="toggleCollapse"
      />
    </template>

    <div v-else class="md-empty">
      <EmptyState message="尚無對照映射" />
      <router-link to="/contribute" class="btn btn-primary btn-sm">
        <ChevronRight :size="14" aria-hidden="true" /> 貢獻映射
      </router-link>
    </div>
  </div>
</template>

<style scoped>
.anchor { max-width: 1280px; margin: 0 auto; padding: var(--page-pad-top) 28px var(--page-pad-bottom); }
.md-graph-area {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 280px;
  gap: 16px;
  align-items: start;
}
@media (max-width: 900px) {
  .md-graph-area {
    grid-template-columns: 1fr;
  }
}
.crumbs {
  font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase;
  color: var(--muted); display: flex; gap: 6px; align-items: center; margin-bottom: 16px;
}
.crumbs a:hover { color: var(--fg); }
.crumbs .sep { opacity: 0.5; }
.anchor-title { display: flex; align-items: baseline; gap: 12px; flex-wrap: wrap; margin-bottom: 8px; }
.anchor-title h1 { font-size: 30px; font-weight: 600; letter-spacing: -0.02em; }
.anchor-meta { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; color: var(--muted); font-size: 13px; }
.anchor-meta .coords { font-size: 11px; }
.anchor-acts { display: flex; gap: 8px; margin-top: var(--space-base); flex-wrap: wrap; }

.md-empty { display: flex; flex-direction: column; align-items: center; gap: var(--space-sm); margin: var(--space-lg) 0; }
</style>
