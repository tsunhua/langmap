<script setup lang="ts">
import { ref, computed, onMounted, watch, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useExpressions } from '@/composables/useExpressions'
import { createExpression, getExpressionEdges, splitExpression } from '@/api/expressions'
import MappingGraph from '@/components/mapping/MappingGraph.vue'
import MappingGraphSkeleton from '@/components/mapping/MappingGraphSkeleton.vue'
import MappingHierarchyList from '@/components/mapping/MappingHierarchyList.vue'
import GraphInspector from '@/components/mapping/GraphInspector.vue'
import ExpressionSplitDialog from '@/components/mapping/ExpressionSplitDialog.vue'
import MorphologyPanel from '@/components/mapping/MorphologyPanel.vue'
import { buildDisplayTree, filterMappingGraphByTargetLanguages, getPathToRoot } from '@/components/mapping/mappingGraphModel'
import type { MappingGraphResponse, DisplayTree } from '@/components/mapping/mappingGraphTypes'
import { buildLanguageFilterOptions } from '@/components/language/languageFilterOptions'
import LangBadge from '@/components/expression/LangBadge.vue'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { ArrowUpRight, Plus, ChevronRight, Share2, List, X, Split, Filter, MoreHorizontal } from 'lucide-vue-next'
import LanguagePicker from '@/components/language/LanguagePicker.vue'
import LanguageSelect from '@/components/language/LanguageSelect.vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { useLocalizationStore } from '@/stores/localization'
import { useLanguagesStore } from '@/stores/languages'
import { readingSchemeLabel } from '@/utils/readingLabel'
import { expressionPath, mapLensPath, parseExpressionTextSegment } from '@/utils/expressionUrl'
import { groupReadings, hasMultipleReadingSchemes, uniqueReadingLocaleLabels, uniqueReadingLocaleCodes } from '@/utils/readingGroups'
import type { ReadingGroup } from '@/utils/readingGroups'

const { t } = useI18n()

const route = useRoute()
const router = useRouter()

// Stable text key from the route; null on legacy numeric urls whose id could
// not be canonicalized (the page then shows its link-expired state).
const key = computed(() => {
  const lang = route.params.lang
  const text = route.params.text
  if (typeof lang !== 'string' || typeof text !== 'string') return null
  const parsed = parseExpressionTextSegment(text)
  return { lang_code: lang, text: parsed.text, homograph_index: parsed.homograph_index }
})
const anchorId = computed(() => expr.value?.expression.id ?? null)

const { detail, mappingGraph } = useExpressions()
const localeParams = useLocaleParams()
const localization = useLocalizationStore()
const languageStore = useLanguagesStore()

const expr = ref<Awaited<ReturnType<typeof detail>> | null>(null)
const graph = ref<MappingGraphResponse | null>(null)
const optionGraph = ref<MappingGraphResponse | null>(null)
const hops = ref<1 | 2 | 3>(2)
const targetLanguageCodes = ref<string[]>([])
const loading = ref(true)
const updatingHops = ref(false)
const loadError = ref('')
const selectedNodeId = ref<string | null>(null)
const selectedExpr = ref<Awaited<ReturnType<typeof detail>> | null>(null)
const collapsedIds = ref<Set<string>>(new Set())
const graphRef = ref<{ centerOnNodeById: (id: string) => void } | null>(null)
const viewMode = ref<'graph' | 'list'>('graph')
const isMobile = ref(false)
const shareStatus = ref('')

const isFullscreen = ref(false)
const MAX_HOPS = 3
const ANONYMOUS_MAX_HOPS = 2
const showQuickAdd = ref(false)
const quickAddText = ref('')
const quickAddLang = ref('')
const quickAddRegion = ref('')
const quickAddSubmitting = ref(false)
const quickAddError = ref('')
const showSplitDialog = ref(false)
const splitEdges = ref<Awaited<ReturnType<typeof getExpressionEdges>>['items']>([])
const splitSubmitting = ref(false)
const splitError = ref('')
const auth = useAuthStore()
const isAdmin = computed(() => auth.user?.role === 'admin')
const maxHops = computed<2 | 3>(() => auth.isLoggedIn ? MAX_HOPS : ANONYMOUS_MAX_HOPS)
const morphFormOpen = ref(false)
const languageFilterOptions = computed(() =>
  buildLanguageFilterOptions(optionGraph.value, languageStore.getName, hops.value),
)

const isMorphWord = computed(() => {
  const text = expr.value?.expression.text ?? ''
  const langCode = expr.value?.expression.lang_code ?? ''
  return !/\s/.test(text.trim()) && langCode !== 'x-image' && langCode !== 'x-emoji'
})

function toggleMorphForm() {
  if (!auth.isLoggedIn) {
    router.push('/auth')
    return
  }
  morphFormOpen.value = !morphFormOpen.value
}
let loadRequest = 0
let graphRequest = 0

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

function parseHops(value: unknown, maximum: 2 | 3 = MAX_HOPS): 1 | 2 | 3 {
  if (value === '1') return 1
  if (value === '2') return 2
  if (value === '3') return maximum === 3 ? 3 : 2
  return 2
}

function initFromUrl() {
  hops.value = 2
  const h = route.query.hops
  if (h) hops.value = parseHops(h, maxHops.value)
  const nodeId = typeof route.query.node === 'string' ? route.query.node : null
  if (nodeId) selectedNodeId.value = nodeId
  const rawTargetLanguages = typeof route.query.target_language === 'string' ? route.query.target_language : ''
  targetLanguageCodes.value = rawTargetLanguages
    ? rawTargetLanguages.split(',').map((code) => code.trim().toLowerCase()).filter(Boolean)
    : []
}

async function loadGraphPair(requestedKey: { lang_code: string; text: string; homograph_index: number }, requestedHops: 1 | 2 | 3) {
  const source = await mappingGraph(requestedKey, requestedHops, localeParams.value)
  return {
    display: filterMappingGraphByTargetLanguages(source, targetLanguageCodes.value),
    options: source,
  }
}

function syncUrl() {
  const query: Record<string, string> = {}
  if (hops.value !== 2) query.hops = String(hops.value)
  if (selectedNodeId.value) query.node = selectedNodeId.value
  if (targetLanguageCodes.value.length) query.target_language = targetLanguageCodes.value.join(',')
  router.replace({ query })
}

async function load() {
  if (!key.value) {
    expr.value = null
    graph.value = null
    loadError.value = t('errors.expressionLinkExpired')
    return
  }
  const request = ++loadRequest
  const requestedKey = key.value
  const requestedHops = hops.value
  ++graphRequest
  expr.value = null
  graph.value = null
  optionGraph.value = null
  loading.value = true
  updatingHops.value = false
  loadError.value = ''
  try {
    const [nextExpression, nextGraph] = await Promise.all([
      detail(requestedKey, localeParams.value),
      loadGraphPair(requestedKey, requestedHops),
    ])
    if (request !== loadRequest) return
    expr.value = nextExpression
    graph.value = nextGraph.display
    optionGraph.value = nextGraph.options
    trySelectNodeFromUrl()
  } catch (e: any) {
    if (request !== loadRequest) return
    loadError.value = e.response?.data?.error || t('mappingDetail.loadFailed')
  } finally {
    if (request === loadRequest) loading.value = false
  }
}

function trySelectNodeFromUrl() {
  const n = route.query.node
  if (!graph.value) return
  if (!n) {
    // Opening a mapping should inspect the expression represented by the URL.
    selectedNodeId.value = anchorId.value
    return
  }
  const nodeId = typeof n === 'string' ? n : null
  if (!nodeId) return
  const exists = graph.value.nodes.some((node) => node.expression_id === nodeId)
  if (exists) {
    selectedNodeId.value = nodeId
  } else {
    selectedNodeId.value = null
    syncUrl()
  }
}

onMounted(() => {
  initFromUrl()
  void languageStore.fetchLanguages(localeParams.value).catch(() => {})
  load()
  mql = window.matchMedia('(max-width: 767px)')
  isMobile.value = mql.matches
  mqlListener = (e: MediaQueryListEvent) => {
    isMobile.value = e.matches
  }
  mql.addEventListener('change', mqlListener)
})

onUnmounted(() => {
  if (mql && mqlListener) {
    mql.removeEventListener('change', mqlListener)
  }
})

watch(key, () => {
  collapsedIds.value = new Set()
  selectedNodeId.value = null
  morphFormOpen.value = false
  initFromUrl()
  load()
})

watch([() => localization.locale, () => localization.secondary], () => { load() })

async function changeHops(h: number) {
  if (!key.value) return
  const nextHops = Math.min(Math.max(Math.trunc(h), 1), maxHops.value) as 1 | 2 | 3
  const request = ++graphRequest
  const requestedKey = key.value
  hops.value = nextHops
  loadError.value = ''
  updatingHops.value = true
  try {
    const nextGraph = await loadGraphPair(requestedKey, nextHops)
    if (request !== graphRequest || requestedKey !== key.value) return
    graph.value = nextGraph.display
    optionGraph.value = nextGraph.options
    trySelectNodeFromUrl()
  } catch (e: any) {
    if (request !== graphRequest || requestedKey !== key.value) return
    loadError.value = e.response?.data?.error || t('mappingDetail.loadFailed')
    // Keep the selector and URL aligned with the graph still displayed.
    hops.value = graph.value?.requested_hops ?? 2
  } finally {
    if (request === graphRequest) updatingHops.value = false
  }
}

watch(hops, () => syncUrl())
watch(maxHops, (maximum) => {
  if (hops.value > maximum) void changeHops(maximum)
})
watch(targetLanguageCodes, () => { syncUrl(); if (graph.value) void changeHops(hops.value) })
watch(selectedNodeId, () => syncUrl())

watch(selectedNodeId, async (nodeId) => {
  if (!nodeId || nodeId === anchorId.value) {
    selectedExpr.value = null
    return
  }
  const request = nodeId
  try {
    const next = await detail(nodeId, localeParams.value)
    if (selectedNodeId.value === request) selectedExpr.value = next
  } catch {
    if (selectedNodeId.value === request) selectedExpr.value = null
  }
})

const inspectorLocales = computed(() => selectedExpr.value?.locales ?? expr.value?.locales ?? [])
const inspectorReadings = computed(() => selectedExpr.value?.readings ?? expr.value?.readings ?? [])

function selectNode(nodeId: string) {
  selectedNodeId.value = nodeId
}

function clearSelection() {
  selectedNodeId.value = null
}

function toggleCollapse(nodeId: string) {
  const next = new Set(collapsedIds.value)
  if (next.has(nodeId)) {
    next.delete(nodeId)
  } else {
    next.add(nodeId)
  }
  collapsedIds.value = next
}

function navigateToNode(nodeId: string) {
  if (nodeId === anchorId.value) return
  const node = graph.value?.nodes.find((candidate) => candidate.expression_id === nodeId)
  if (node) router.push(expressionPath(node.lang_code, node.text, node.homograph_index))
}

function selectNodeFromList(nodeId: string) {
  selectedNodeId.value = nodeId
  graphRef.value?.centerOnNodeById(nodeId)
  if (isMobile.value) setViewMode('graph')
}

function setViewMode(next: 'graph' | 'list') {
  if (viewMode.value === next) return
  if (next === 'list' && isFullscreen.value) toggleFullscreen()
  viewMode.value = next
}

function openQuickAdd() {
  showQuickAdd.value = true
  quickAddError.value = ''
}

function handleLangCreated(lang: { code: string; name: string }) {
  quickAddLang.value = lang.code
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
    const result = await createExpression({
      text,
      lang_code: languageCode,
    })
    const newExpression = result.expression
    closeQuickAdd()
    quickAddText.value = ''
    quickAddLang.value = ''
    quickAddRegion.value = ''
    if (newExpression && !(newExpression.lang_code === key.value?.lang_code && newExpression.text === key.value?.text && newExpression.homograph_index === key.value?.homograph_index)) {
      router.push(expressionPath(newExpression.lang_code, newExpression.text, newExpression.homograph_index))
    }
  } catch (e: any) {
    quickAddError.value = e.response?.data?.message || e.response?.data?.error || t('mappingDetail.addFailed')
  } finally {
    quickAddSubmitting.value = false
  }
}

async function openSplitDialog() {
  splitError.value = ''
  try {
    splitEdges.value = (await getExpressionEdges(key.value!)).items
    showSplitDialog.value = true
  } catch (error: any) {
    splitError.value = error.response?.data?.error || t('mappingDetail.splitLoadFailed')
    showSplitDialog.value = true
  }
}

async function confirmSplit(edgeIds: string[]) {
  splitSubmitting.value = true
  splitError.value = ''
  try {
    const result = await splitExpression(key.value!, edgeIds)
    showSplitDialog.value = false
    await router.push(expressionPath(result.target.lang_code, result.target.text, result.target.homograph_index))
  } catch (error: any) {
    splitError.value = error.response?.data?.error || t('mappingDetail.splitFailed')
  } finally {
    splitSubmitting.value = false
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

const anchorLangName = computed(() => graph.value?.nodes.find((node) => node.expression_id === anchorId.value)?.language_name ?? '')

const anchorImageUrl = computed(() => {
  if (expr.value?.expression.lang_code !== 'x-image') return null
  try {
    const url = new URL(expr.value.expression.text, window.location.origin)
    return url.protocol === 'http:' || url.protocol === 'https:' ? url.href : null
  } catch { return null }
})

const canViewMap = computed(() => !expr.value?.expression.lang_code.toLowerCase().startsWith('x-'))

const displayTree = computed<DisplayTree>(() => {
  if (!graph.value) return { nodes: [], treeEdges: [], crossEdges: [] }
  return buildDisplayTree(graph.value)
})

const mobilePreviewGraph = computed<MappingGraphResponse | null>(() => {
  const source = graph.value
  if (!source) return null
  const limit = 8
  if (!isMobile.value || source.nodes.length <= limit) return source

  const nodesById = new Map(source.nodes.map((node) => [node.expression_id, node]))
  const orderedNodes = [...source.nodes].sort((a, b) => {
    if (a.depth !== b.depth) return a.depth - b.depth
    const languageOrder = (a.language_name || a.lang_code).localeCompare(b.language_name || b.lang_code)
    if (languageOrder !== 0) return languageOrder
    const textOrder = a.text.localeCompare(b.text)
    return textOrder || a.expression_id.localeCompare(b.expression_id)
  })
  const selected = new Set<string>([source.root_id])
  const selectedPath = selectedNodeId.value
    ? getPathToRoot(selectedNodeId.value, displayTree.value).reverse()
    : []
  for (const id of selectedPath) {
    if (selected.size >= limit) break
    if (nodesById.has(id)) selected.add(id)
  }

  const languages = new Set<string>()
  for (const id of selectedPath) {
    const node = nodesById.get(id)
    if (node?.depth === 1) languages.add(node.lang_code)
  }
  for (const node of orderedNodes.filter((item) => item.depth === 1)) {
    if (selected.size >= limit) break
    if (languages.has(node.lang_code)) continue
    selected.add(node.expression_id)
    languages.add(node.lang_code)
  }
  for (const node of orderedNodes) {
    if (selected.size >= limit) break
    const path = getPathToRoot(node.expression_id, displayTree.value).reverse()
    const additions = path.filter((id) => !selected.has(id))
    if (selected.size + additions.length > limit) continue
    for (const id of additions) selected.add(id)
  }

  const nodes = source.nodes.filter((node) => selected.has(node.expression_id))
  const edges = source.edges.filter((edge) => selected.has(edge.source_id) && selected.has(edge.target_id))
  const layerCounts: Record<number, number> = {}
  for (const node of nodes) {
    if (node.depth > 0) layerCounts[node.depth] = (layerCounts[node.depth] ?? 0) + 1
  }
  return { ...source, nodes, edges, layer_counts: layerCounts }
})

async function shareExpression() {
  const expression = expr.value?.expression
  if (!expression) return
  const url = new URL(expressionPath(expression.lang_code, expression.text, expression.homograph_index), window.location.origin).href
  shareStatus.value = ''
  try {
    if (navigator.share) {
      await navigator.share({ title: expression.text, url })
      return
    }
    await navigator.clipboard.writeText(url)
    shareStatus.value = t('mappingDetail.linkCopied')
  } catch (error) {
    if (error instanceof DOMException && error.name === 'AbortError') return
    try {
      await navigator.clipboard.writeText(url)
      shareStatus.value = t('mappingDetail.linkCopied')
    } catch {
      shareStatus.value = t('mappingDetail.shareFailed')
    }
  }
}

const coords = computed(() => {
  return null
})

const anchorReadingGroups = computed(() => groupReadings(expr.value?.readings ?? []))
const showAnchorReadingScheme = computed(() => hasMultipleReadingSchemes(anchorReadingGroups.value))

function anchorReadingLocalesLabel(readings: ReadingGroup['readings']) {
  return uniqueReadingLocaleLabels(readings).join(', ')
}

function anchorReadingLocalesTitle(readings: ReadingGroup['readings']) {
  return uniqueReadingLocaleCodes(readings).join(', ')
}

</script>

<template>
  <LoadingSpinner v-if="loading && !graph" />

  <EmptyState v-else-if="loadError && !graph" :message="loadError" />

  <div v-else-if="expr" class="anchor">
    <nav class="crumbs" :aria-label="t('mappingDetail.breadcrumb')">
      <router-link to="/">{{ t('mappingDetail.home') }}</router-link>
      <span class="sep">/</span>
      <span v-if="anchorImageUrl" class="crumb-image-id">{{ expr.expression.text }}</span>
      <span v-else>{{ expr.expression.text }}</span>
    </nav>

    <div class="anchor-title">
      <h1 v-if="!anchorImageUrl">{{ expr.expression.text }}</h1>
      <a v-else :href="anchorImageUrl" target="_blank" rel="noopener noreferrer">
        <img class="anchor-image anchor-image--large" :src="anchorImageUrl" :alt="t('expression.imageAlt')" />
      </a>
      <LangBadge :code="expr.expression.lang_code" :name="anchorLangName" />
    </div>

    <div v-if="anchorReadingGroups.length" class="anchor-readings">
      <span class="anchor-readings-label">{{ t('mappingDetail.readingsByLocale') }}</span>
      <div class="anchor-reading-list">
        <span
          v-for="group in anchorReadingGroups"
          :key="`${group.scheme}:${group.value}`"
          class="anchor-reading"
          :title="anchorReadingLocalesTitle(group.readings)"
        >
          <span class="anchor-reading-locale">{{ anchorReadingLocalesLabel(group.readings) }}</span>
          <span class="anchor-reading-value">[{{ group.value }}]</span>
          <span v-if="showAnchorReadingScheme" class="anchor-reading-scheme">· {{ readingSchemeLabel(group.scheme) }}</span>
        </span>
      </div>
    </div>

    <div class="anchor-meta">
      <span v-if="coords" class="mono coords">{{ coords }}</span>
    </div>

    <div class="anchor-acts">
      <button class="btn btn-sm" type="button" @click="shareExpression">
        <Share2 :size="14" aria-hidden="true" /> {{ t('mappingDetail.share') }}
      </button>
      <router-link to="/contribute" class="btn btn-primary btn-sm">
        <Plus :size="14" aria-hidden="true" /> {{ t('nav.contribute') }}
      </router-link>
      <details class="anchor-more">
        <summary class="btn btn-sm"><MoreHorizontal :size="16" aria-hidden="true" /> {{ t('components.moreActions') }}</summary>
        <div class="anchor-more-menu">
          <button class="anchor-more-item" type="button" @click="openQuickAdd">
            <Plus :size="14" aria-hidden="true" /> {{ t('mappingDetail.addExpression') }}
          </button>
          <router-link v-if="canViewMap" :to="mapLensPath(expr.expression.lang_code, expr.expression.text, expr.expression.homograph_index)" class="anchor-more-item">
            <ArrowUpRight :size="14" aria-hidden="true" /> {{ t('mappingDetail.viewMap') }}
          </router-link>
          <button
            v-if="isMorphWord"
            class="anchor-more-item"
            type="button"
            :aria-expanded="morphFormOpen"
            aria-controls="morph-form"
            @click="toggleMorphForm"
          >
            <Plus :size="14" aria-hidden="true" /> {{ morphFormOpen ? t('morphology.hideForm') : t('morphology.addFormLink') }}
          </button>
          <button v-if="isAdmin" class="anchor-more-item" type="button" @click="openSplitDialog">
            <Split :size="14" aria-hidden="true" /> {{ t('mappingDetail.splitExpression') }}
          </button>
        </div>
      </details>
    </div>
    <p v-if="shareStatus" class="share-status" role="status">{{ shareStatus }}</p>

    <section v-if="showQuickAdd" class="quick-add" :aria-label="t('mappingDetail.quickAdd')">
      <div class="qa-head">
        <h2>{{ t('mappingDetail.quickAdd') }}</h2>
        <button class="qa-close" type="button" :aria-label="t('mappingDetail.closeQuickAdd')" @click="closeQuickAdd">
          <X :size="16" aria-hidden="true" />
        </button>
      </div>
      <p class="qa-lead">{{ t('mappingDetail.quickAddLead') }}</p>
      <div class="qa-grid">
        <LanguagePicker v-model="quickAddLang" :label="t('mappingDetail.languageCode')" @created="handleLangCreated" />
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

    <MorphologyPanel
      v-if="expr.expression.lang_code !== 'x-image' && expr.expression.lang_code !== 'x-emoji'"
      v-model:form-open="morphFormOpen"
      :lang-code="expr.expression.lang_code"
      :text="expr.expression.text"
      :homograph-index="expr.expression.homograph_index"
    />

    <div class="nb-heading">
      <h2>{{ t('mappingDetail.mappingSet') }}</h2>
      <p>{{ t('mappingDetail.subtitle') }}</p>
      <span class="nb-meta">
        <b>{{ directCount }}</b> {{ t('mappingDetail.direct') }}<template v-if="indirectCount"> · <b>{{ indirectCount }}</b> {{ t('mappingDetail.indirect') }}</template>
      </span>
    </div>
    <p v-if="loadError && graph" class="md-graph-error" role="alert">{{ loadError }}</p>

    <template v-if="hasMappings">
      <div class="md-view-controls">
        <div class="target-language-filter">
          <div class="target-language-filter__label"><Filter :size="14" aria-hidden="true" /><span class="sr-only">{{ t('mappingDetail.targetLanguage') }}</span></div>
          <LanguageSelect v-model="targetLanguageCodes" :options="languageFilterOptions" />
        </div>
        <div class="md-view-switch" role="group" :aria-label="t('mappingDetail.mappingSet')">
          <button
            class="md-mode-btn"
            :class="{ active: viewMode === 'graph' }"
            data-view="graph"
            type="button"
            :aria-pressed="viewMode === 'graph'"
            @click="setViewMode('graph')"
          >
            <Share2 :size="14" aria-hidden="true" /> {{ t('mappingDetail.graph') }}
          </button>
          <button
            class="md-mode-btn"
            :class="{ active: viewMode === 'list' }"
            data-view="list"
            type="button"
            :aria-pressed="viewMode === 'list'"
            @click="setViewMode('list')"
          >
            <List :size="14" aria-hidden="true" /> {{ t('mappingDetail.list') }}
          </button>
        </div>
      </div>
      <div v-if="maxHops > 1" class="md-hops-controls" role="group" :aria-label="t('components.hops')">
        <span class="md-hops-label">{{ t('components.hops') }}</span>
        <button
          v-for="hop in maxHops"
          :key="hop"
          type="button"
          class="md-hop-btn"
          :class="{ active: hops === hop }"
          :aria-label="`${hop} ${t('components.hops')}`"
          :aria-pressed="hops === hop"
          :disabled="loading || updatingHops"
          @click="changeHops(hop)"
        >{{ hop }}</button>
      </div>
      <p v-if="graph?.truncated" class="md-truncated" role="status">
        {{ targetLanguageCodes.length
          ? t('mappingDetail.filteredGraphTruncated')
          : t('mappingDetail.graphTruncated', { count: graph.omitted_count }) }}
      </p>

      <div v-if="viewMode === 'graph'" class="md-graph-area">
        <div class="md-graph-cell" :class="{ 'is-fullscreen': isFullscreen }">
          <template v-if="loading || updatingHops">
            <MappingGraphSkeleton />
          </template>
          <MappingGraph v-else ref="graphRef"
            :graph="mobilePreviewGraph!"
            :selected-node-id="selectedNodeId"
            :collapsed-ids="collapsedIds"
            :current-hops="hops"
            :max-hops="maxHops"
            :show-hops-control="false"
            :is-fullscreen="isFullscreen"
            @select="selectNode"
            @navigate="navigateToNode"
            @clear-selection="clearSelection"
            @toggle-collapse="toggleCollapse"
            @change-hops="changeHops"
            @toggle-fullscreen="toggleFullscreen"
          />
          <p v-if="isMobile && mobilePreviewGraph && graph && mobilePreviewGraph.nodes.length < graph.nodes.length" class="md-preview-note" role="status">
            {{ t('mappingDetail.mobileGraphPreview', { shown: mobilePreviewGraph.nodes.length, total: graph.nodes.length }) }}
            <button type="button" class="md-preview-link" @click="setViewMode('list')">{{ t('mappingDetail.viewFullList') }}</button>
          </p>
        </div>
        <GraphInspector
          :selected-node-id="selectedNodeId"
          :graph="graph!"
          :display-tree="displayTree"
          :anchor-text="expr.expression.text"
          :collapsed-ids="collapsedIds"
          :locales="inspectorLocales"
          :readings="inspectorReadings"
          @close="clearSelection"
          @navigate="navigateToNode"
          @toggle-collapse="toggleCollapse"
        />
      </div>

      <div v-else class="md-list-section">
        <MappingHierarchyList
          :tree="displayTree"
          :graph="graph!"
          :selected-node-id="selectedNodeId"
          :collapsed-ids="collapsedIds"
          @select="selectNodeFromList"
          @toggle-collapse="toggleCollapse"
        />
      </div>

    </template>

    <div v-else class="md-empty">
      <EmptyState :message="t('mappingDetail.noMappings')" />
      <router-link to="/contribute" class="btn btn-primary btn-sm">
        <ChevronRight :size="14" aria-hidden="true" /> {{ t('mappingDetail.contribute') }}
      </router-link>
    </div>

    <ExpressionSplitDialog
      v-if="showSplitDialog"
      :edges="splitEdges"
      :submitting="splitSubmitting"
      :error="splitError"
      @close="showSplitDialog = false"
      @confirm="confirmSplit"
    />
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
  .anchor {
    padding-left: 20px;
    padding-right: 20px;
  }
}
@media (max-width: 640px) {
  .anchor {
    padding-left: 16px;
    padding-right: 16px;
  }
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
.anchor-readings {
  display: grid;
  gap: 6px;
  margin: 10px 0 0;
}
.anchor-readings-label {
  color: var(--faint);
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}
.anchor-reading-list {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  min-width: 0;
}
.anchor-reading {
  display: inline-flex;
  align-items: baseline;
  flex-wrap: wrap;
  gap: 6px;
  min-width: 0;
  max-width: 100%;
  padding: 6px 9px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  overflow-wrap: anywhere;
}
.anchor-reading-list .anchor-reading {
  font-family: var(--mono);
  font-size: 12px;
  color: var(--fg);
}
.anchor-reading-value {
  color: var(--fg);
  font-weight: 600;
  overflow-wrap: anywhere;
}
.anchor-reading-scheme {
  font-size: 11px;
  color: var(--faint);
}
.anchor-reading-locale {
  color: var(--accent);
  font-size: 11px;
  font-weight: 600;
}
.anchor-acts { display: flex; gap: 8px; margin-top: var(--space-base); flex-wrap: wrap; }
.anchor-more { position: relative; }
.anchor-more > summary { list-style: none; cursor: pointer; }
.anchor-more > summary::-webkit-details-marker { display: none; }
.anchor-more-menu {
  position: absolute;
  z-index: 20;
  top: calc(100% + 4px);
  right: 0;
  display: grid;
  min-width: 200px;
  padding: 4px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
}
.anchor-more-item {
  display: flex;
  align-items: center;
  gap: 8px;
  min-height: 44px;
  padding: 0 10px;
  border: 0;
  border-radius: calc(var(--r) - 2px);
  background: transparent;
  color: var(--fg);
  font: inherit;
  font-size: 13px;
  text-align: left;
  text-decoration: none;
  cursor: pointer;
}
.anchor-more-item:hover { background: var(--surface-2); }
.anchor-more-item:focus-visible,
.anchor-more > summary:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.share-status { margin: 8px 0 0; color: var(--muted); font-size: 13px; }
.sr-only { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0); white-space: nowrap; border: 0; }
.target-language-filter {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}
.target-language-filter__label { display: inline-flex; color: var(--muted); }
.target-language-filter :deep(.lang-select) { flex: 1; min-width: 160px; }
.target-language-filter :deep(.lang-select-tagwrap) { min-height: 36px; }

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
  grid-template-columns: 1fr 160px 1fr;
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
.anchor-image { display: block; width: 96px; height: 64px; object-fit: cover; border: 1px solid var(--border); }
.anchor-image--large { width: min(480px, 100%); height: auto; max-height: 360px; }
.crumb-image-id { font-family: var(--mono); font-size: 12px; }
.qa-error { margin: 10px 0 0; color: var(--down); font-size: 13px; }
.qa-actions { display: flex; justify-content: flex-end; margin-top: 12px; }

.md-graph-error { margin: 8px 0 0; color: var(--down); font-size: 13px; }

.md-empty { display: flex; flex-direction: column; align-items: center; gap: var(--space-sm); margin: var(--space-lg) 0; }

.nb-heading { display: grid; gap: 5px; margin: 22px 0 16px; }
.nb-heading h2 { margin: 0; font-size: 20px; font-weight: 600; line-height: 1.25; }
.nb-heading p { margin: 0; color: var(--muted); font-size: 14px; line-height: 1.45; }
.nb-meta { color: var(--muted); font-size: 12px; }
.md-view-controls { display: flex; align-items: center; gap: 12px; margin-bottom: 10px; }
.md-view-controls .target-language-filter { flex: 1 1 220px; max-width: 420px; }
.md-view-controls .target-language-filter :deep(.lang-select) { min-width: 0; }
.md-view-switch {
  display: flex;
  flex: 0 0 auto;
  gap: 0;
  border: 1px solid var(--border);
  border-radius: var(--r);
  overflow: hidden;
}
.md-mode-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  min-height: 44px;
  padding: 0 12px;
  border: 0;
  background: transparent;
  color: var(--muted);
  font: inherit;
  font-size: 13px;
  cursor: pointer;
}
.md-mode-btn.active { background: var(--accent); color: #fff; }
.md-mode-btn:not(.active):hover { color: var(--accent); }
.md-mode-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.md-hops-controls { display: flex; align-items: center; gap: 6px; margin: 0 0 12px; }
.md-hops-label {
  margin-right: 4px;
  color: var(--faint);
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}
.md-hop-btn {
  min-width: 44px;
  min-height: 44px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  color: var(--muted);
  font: inherit;
  cursor: pointer;
}
.md-hop-btn.active { border-color: var(--accent); background: var(--accent); color: #fff; }
.md-hop-btn:disabled { opacity: 0.6; cursor: wait; }
.md-hop-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.md-preview-note { display: flex; flex-wrap: wrap; align-items: center; gap: 2px 8px; margin: 8px 0 0; color: var(--muted); font-size: 12px; line-height: 1.45; }
.md-preview-link { min-height: 44px; padding: 0 4px; border: 0; background: transparent; color: var(--accent); font: inherit; font-weight: 600; text-decoration: underline; text-underline-offset: 2px; cursor: pointer; }
.md-preview-link:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }

@media (max-width: 700px) {
  .qa-grid { grid-template-columns: 1fr; }
  .nb-heading { margin-top: 20px; }
  .md-view-controls { align-items: stretch; gap: 8px; }
  .md-view-controls .target-language-filter { flex-basis: 0; }
  .md-view-controls .target-language-filter__label { display: none; }
  .md-mode-btn { gap: 4px; padding: 0 9px; }
}
@media (prefers-reduced-motion: reduce) {
  .md-mode-btn { transition: none; }
}
</style>
