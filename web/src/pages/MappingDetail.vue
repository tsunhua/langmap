<script setup lang="ts">
import { ref, computed, onMounted, watch, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import api from '@/api/client'
import { useExpressions } from '@/composables/useExpressions'
import MappingGraph from '@/components/mapping/MappingGraph.vue'
import MappingGraphSkeleton from '@/components/mapping/MappingGraphSkeleton.vue'
import MappingHierarchyList from '@/components/mapping/MappingHierarchyList.vue'
import GraphInspector from '@/components/mapping/GraphInspector.vue'
import GraphMobileInspector from '@/components/mapping/GraphMobileInspector.vue'
import { buildDisplayTree } from '@/components/mapping/mappingGraphModel'
import type { MappingGraphResponse, DisplayTree } from '@/components/mapping/mappingGraphTypes'
import LangBadge from '@/components/expression/LangBadge.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { ArrowUpRight, Plus, ChevronRight, Share2, List, X } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'

const { t } = useI18n()

const route = useRoute()
const router = useRouter()
const id = computed(() => parseInt(route.params.id as string))

const { detail, mappingGraph } = useExpressions()

const expr = ref<any>(null)
const graph = ref<MappingGraphResponse | null>(null)
const hops = ref<1 | 2 | 3>(1)
const loading = ref(true)
const updatingHops = ref(false)
const loadError = ref('')
const selectedNodeId = ref<number | null>(null)
const collapsedIds = ref<Set<number>>(new Set())
const graphRef = ref<{ centerOnNodeById: (id: number) => void } | null>(null)
const mobileMode = ref<'graph' | 'list'>('list')
const isMobile = ref(false)

const isFullscreen = ref(false)
const MAX_HOPS = 3
const showQuickAdd = ref(false)
const quickAddText = ref('')
const quickAddLang = ref('')
const quickAddRegion = ref('')
const quickAddSubmitting = ref(false)
const quickAddError = ref('')

function toggleFullscreen() {
  isFullscreen.value = !isFullscreen.value
  if (isFullscreen.value) {
    document.body.style.overflow = 'hidden'
  } else {
    document.body.style.overflow = ''
    nextTick(() => {
      document.querySelector('.md-graph-area')?.scrollIntoView({ block: 'start' })
    })
  }
}

let mql: MediaQueryList | null = null
let mqlListener: ((e: MediaQueryListEvent) => void) | null = null

function parseHops(value: unknown): 1 | 2 | 3 {
  const n = typeof value === 'string' ? parseInt(value) : NaN
  if (n === 2) return 2
  if (n === 3) return 3
  return 1
}

function initFromUrl() {
  const h = route.query.hops
  if (h) hops.value = parseHops(h)
  const n = route.query.node
  if (n) {
    const nodeId = parseInt(n as string)
    if (!isNaN(nodeId)) selectedNodeId.value = nodeId
  }
}

function syncUrl() {
  const query: Record<string, string> = {}
  if (hops.value > 1) query.hops = String(hops.value)
  if (selectedNodeId.value) query.node = String(selectedNodeId.value)
  router.replace({ query })
}

async function load() {
  expr.value = null
  graph.value = null
  loading.value = true
  updatingHops.value = false
  loadError.value = ''
  try {
    expr.value = await detail(id.value)
    graph.value = await mappingGraph(id.value, hops.value)
    trySelectNodeFromUrl()
  } catch (e: any) {
    loadError.value = e.response?.data?.error || t('mappingDetail.loadFailed')
  } finally {
    loading.value = false
  }
}

function trySelectNodeFromUrl() {
  const n = route.query.node
  if (!n || !graph.value) return
  const nodeId = parseInt(n as string)
  if (isNaN(nodeId)) return
  const exists = graph.value.nodes.some((node) => node.expression_id === nodeId)
  if (exists) {
    selectedNodeId.value = nodeId
  } else {
    selectedNodeId.value = null
    router.replace({ query: { hops: hops.value > 1 ? String(hops.value) : undefined } })
  }
}

onMounted(() => {
  initFromUrl()
  load()
  mql = window.matchMedia('(max-width: 767px)')
  isMobile.value = mql.matches
  mqlListener = (e: MediaQueryListEvent) => {
    isMobile.value = e.matches
    if (!e.matches) mobileMode.value = 'list'
  }
  mql.addEventListener('change', mqlListener)
})

onUnmounted(() => {
  if (mql && mqlListener) {
    mql.removeEventListener('change', mqlListener)
  }
})

watch(id, () => {
  collapsedIds.value = new Set()
  selectedNodeId.value = null
  initFromUrl()
  load()
})

async function changeHops(h: 1 | 2 | 3) {
  hops.value = h
  updatingHops.value = true
  try {
    graph.value = await mappingGraph(id.value, h)
    trySelectNodeFromUrl()
  } catch (e: any) {
    loadError.value = e.response?.data?.error || t('mappingDetail.loadFailed')
  } finally {
    updatingHops.value = false
  }
}

watch(hops, () => syncUrl())
watch(selectedNodeId, () => syncUrl())

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

function selectNodeFromList(nodeId: number) {
  selectedNodeId.value = nodeId
  graphRef.value?.centerOnNodeById(nodeId)
  if (isMobile.value) mobileMode.value = 'graph'
}

function toggleMobileMode() {
  mobileMode.value = mobileMode.value === 'graph' ? 'list' : 'graph'
}

function openQuickAdd() {
  showQuickAdd.value = true
  quickAddError.value = ''
}

function closeQuickAdd() {
  showQuickAdd.value = false
  quickAddError.value = ''
}

async function submitQuickAdd() {
  const text = quickAddText.value.trim()
  const languageCode = quickAddLang.value.trim()
  const regionName = quickAddRegion.value.trim()
  if (!text || !languageCode) {
    quickAddError.value = t('mappingDetail.enterRequired')
    return
  }
  quickAddSubmitting.value = true
  quickAddError.value = ''
  try {
    const { data } = await api.post('/expressions', {
      text,
      language_code: languageCode,
      region_name: regionName || undefined,
      related_to: id.value,
    })
    const newId = data.data?.expressionId
    closeQuickAdd()
    quickAddText.value = ''
    quickAddLang.value = ''
    quickAddRegion.value = ''
    if (newId && newId !== id.value) {
      router.push(`/mapping/${newId}`)
    }
  } catch (e: any) {
    quickAddError.value = e.response?.data?.message || e.response?.data?.error || t('mappingDetail.addFailed')
  } finally {
    quickAddSubmitting.value = false
  }
}

function expandAll() {
  collapsedIds.value = new Set()
}

function collapseToFirst() {
  if (!graph.value) return
  const firstHopIds = graph.value.nodes
    .filter((n) => n.depth === 1)
    .map((n) => n.expression_id)
  collapsedIds.value = new Set(firstHopIds)
}

const directCount = computed(() => graph.value?.layer_counts[1] ?? 0)
const indirectCount = computed(() => (graph.value?.layer_counts[2] ?? 0) + (graph.value?.layer_counts[3] ?? 0))

const hasMappings = computed(() => (graph.value?.nodes.length ?? 0) > 1)

const displayTree = computed<DisplayTree>(() => {
  if (!graph.value) return { nodes: [], treeEdges: [], crossEdges: [] }
  return buildDisplayTree(graph.value)
})

const coords = computed(() => {
  const lat = expr.value?.region_latitude
  const lng = expr.value?.region_longitude
  if (lat == null || lng == null) return null
  return `${lat}°N · ${lng}°E`
})

const sourceLabel = computed(() => {
  const sourceType = expr.value?.source_type
  if (sourceType === 'auth') return t('mappingDetail.authority')
  if (sourceType === 'ai') return 'AI'
  if (sourceType === 'user') return t('mappingDetail.user')
  return sourceType || ''
})
</script>

<template>
  <LoadingSpinner v-if="loading && !graph" />

  <EmptyState v-else-if="loadError && !graph" :message="loadError" />

  <div v-else-if="expr" class="anchor">
    <nav class="crumbs" :aria-label="t('mappingDetail.breadcrumb')">
      <router-link to="/">{{ t('mappingDetail.home') }}</router-link>
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
      <button class="btn btn-primary btn-sm" type="button" @click="openQuickAdd">
        <Plus :size="14" aria-hidden="true" /> {{ t('mappingDetail.addExpression') }}
      </button>
      <router-link :to="`/map/${expr.id}`" class="btn btn-sm">
        <ArrowUpRight :size="14" aria-hidden="true" /> {{ t('mappingDetail.viewMap') }}
      </router-link>
    </div>

    <section v-if="showQuickAdd" class="quick-add" :aria-label="t('mappingDetail.quickAdd')">
      <div class="qa-head">
        <h2>{{ t('mappingDetail.quickAdd') }}</h2>
        <button class="qa-close" type="button" :aria-label="t('mappingDetail.closeQuickAdd')" @click="closeQuickAdd">
          <X :size="16" aria-hidden="true" />
        </button>
      </div>
      <p class="qa-lead">{{ t('mappingDetail.quickAddLead') }}</p>
      <div class="qa-grid">
        <label>
          <span>{{ t('mappingDetail.languageCode') }}</span>
          <input v-model="quickAddLang" :placeholder="t('mappingDetail.languageCodePlaceholder')" :aria-label="t('mappingDetail.languageCode')" />
        </label>
        <label>
          <span>{{ t('mappingDetail.region') }}</span>
          <input v-model="quickAddRegion" :placeholder="t('mappingDetail.optional')" :aria-label="t('mappingDetail.region')" />
        </label>
        <label class="qa-text">
          <span>{{ t('mappingDetail.expression') }}</span>
          <input v-model="quickAddText" :placeholder="t('mappingDetail.expressionPlaceholder')" :aria-label="t('mappingDetail.expression')" />
        </label>
      </div>
      <p v-if="quickAddError" class="qa-error" role="alert">{{ quickAddError }}</p>
      <div class="qa-actions">
        <button class="btn btn-primary btn-sm" type="button" :disabled="quickAddSubmitting" @click="submitQuickAdd">
          {{ quickAddSubmitting ? t('mappingDetail.adding') : t('mappingDetail.addAndMap') }}
        </button>
      </div>
    </section>

    <div class="nb-head">
      <h2>{{ t('mappingDetail.mappingSet') }}</h2>
      <span class="nb-meta">
        <b>{{ directCount }}</b> {{ t('mappingDetail.direct') }}<template v-if="indirectCount"> · <b>{{ indirectCount }}</b> {{ t('mappingDetail.indirect') }}</template>
        · <b>{{ hops }}</b> {{ t('mappingDetail.hops') }}
      </span>
    </div>

    <template v-if="hasMappings">
      <div v-if="isMobile" class="md-mobile-bar">
        <button
          class="md-mode-btn"
          :class="{ active: mobileMode === 'graph' }"
          :aria-label="t('mappingDetail.graph')"
          @click="toggleMobileMode"
        >
          <Share2 :size="14" aria-hidden="true" /> {{ t('mappingDetail.graph') }}
        </button>
        <button
          class="md-mode-btn"
          :class="{ active: mobileMode === 'list' }"
          :aria-label="t('mappingDetail.list')"
          @click="toggleMobileMode"
        >
          <List :size="14" aria-hidden="true" /> {{ t('mappingDetail.list') }}
        </button>
      </div>

      <div class="md-graph-area">
        <div class="md-graph-cell" :class="{ 'is-fullscreen': isFullscreen }">
          <template v-if="loading || updatingHops">
            <MappingGraphSkeleton />
          </template>
          <template v-else-if="!isMobile || mobileMode === 'graph'">
            <MappingGraph ref="graphRef"
              :graph="graph!"
              :selected-node-id="selectedNodeId"
              :collapsed-ids="collapsedIds"
              :current-hops="hops"
              :max-hops="MAX_HOPS"
              :is-fullscreen="isFullscreen"
              @select="selectNode"
              @navigate="navigateToNode"
              @clear-selection="clearSelection"
              @toggle-collapse="toggleCollapse"
              @change-hops="(h: number) => changeHops(h as 1 | 2 | 3)"
              @toggle-fullscreen="toggleFullscreen"
            />
          </template>
        </div>
        <GraphInspector
          v-if="!isMobile"
          :selected-node-id="selectedNodeId"
          :graph="graph!"
          :display-tree="displayTree"
          :anchor-text="expr.text"
          :collapsed-ids="collapsedIds"
          @close="clearSelection"
          @navigate="navigateToNode"
          @toggle-collapse="toggleCollapse"
        />
      </div>

      <div v-if="!isMobile || mobileMode === 'list'" class="md-list-section">
        <MappingHierarchyList
          :tree="displayTree"
          :graph="graph!"
          :selected-node-id="selectedNodeId"
          :collapsed-ids="collapsedIds"
          @select="selectNodeFromList"
          @toggle-collapse="toggleCollapse"
        />
      </div>

      <GraphMobileInspector
        v-if="isMobile"
        :selected-node-id="selectedNodeId"
        :graph="graph!"
        :display-tree="displayTree"
        :anchor-text="expr.text"
        :collapsed-ids="collapsedIds"
        @close="clearSelection"
        @navigate="navigateToNode"
        @toggle-collapse="toggleCollapse"
      />
    </template>

    <div v-else class="md-empty">
      <EmptyState :message="t('mappingDetail.noMappings')" />
      <router-link to="/contribute" class="btn btn-primary btn-sm">
        <ChevronRight :size="14" aria-hidden="true" /> {{ t('mappingDetail.contribute') }}
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
.md-graph-cell {
  position: relative;
  min-width: 0;
}
@media (max-width: 900px) {
  .md-graph-area {
    grid-template-columns: 1fr;
  }
}
.md-mobile-bar {
  display: flex;
  gap: 0;
  margin-bottom: 12px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  overflow: hidden;
  width: fit-content;
}
.md-mode-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 16px;
  border: none;
  background: transparent;
  color: var(--muted);
  font-size: 13px;
  cursor: pointer;
  transition: background 0.1s, color 0.1s;
}
.md-mode-btn.active {
  background: var(--accent);
  color: #fff;
}
.md-mode-btn:not(.active):hover {
  color: var(--accent);
}
.md-mode-btn:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: -2px;
}
.md-list-section {
  margin-top: 16px;
}
.md-graph-cell.is-fullscreen {
  position: fixed;
  inset: 0;
  z-index: 9999;
  width: 100vw;
  height: 100dvh;
  background: var(--surface);
  background-image: radial-gradient(circle, oklch(0.90 0.010 88) 1px, transparent 1px);
  background-size: 18px 18px;
}
.md-graph-cell.is-fullscreen :deep(.mapping-graph),
.md-graph-cell.is-fullscreen :deep(.graph-skeleton) {
  height: 100dvh;
  border: none;
  border-radius: 0;
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

.quick-add {
  margin-top: 16px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  padding: 14px;
}
.qa-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}
.qa-head h2 {
  font-size: 15px;
  font-weight: 600;
  margin: 0;
}
.qa-close {
  border: none;
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  padding: 6px;
  min-width: 36px;
  min-height: 36px;
  border-radius: var(--r);
}
.qa-close:hover { color: var(--fg); background: var(--surface-2); }
.qa-lead { margin: 0 0 12px; color: var(--muted); font-size: 13px; line-height: 1.5; }
.qa-grid {
  display: grid;
  grid-template-columns: 160px 160px 1fr;
  gap: 10px;
}
.qa-grid label {
  display: flex;
  flex-direction: column;
  gap: 6px;
  font-size: 12px;
  color: var(--muted);
}
.qa-grid input {
  min-width: 0;
  height: 36px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--bg);
  padding: 0 10px;
  font-size: 13px;
}
.qa-grid input:focus {
  outline: none;
  border-color: var(--accent);
}
.qa-text { grid-column: 1 / -1; }
.qa-error { margin: 10px 0 0; color: var(--down); font-size: 13px; }
.qa-actions { display: flex; justify-content: flex-end; margin-top: 12px; }

.md-empty { display: flex; flex-direction: column; align-items: center; gap: var(--space-sm); margin: var(--space-lg) 0; }

@media (max-width: 700px) {
  .qa-grid { grid-template-columns: 1fr; }
}
</style>
