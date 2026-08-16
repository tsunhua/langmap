<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useHandbooks } from '@/composables/useHandbooks'
import { useExpressions } from '@/composables/useExpressions'
import VotePill from '@/components/mapping/VotePill.vue'
import { PanelRightOpen } from 'lucide-vue-next'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { useI18n } from 'vue-i18n'
import { useLocaleParams } from '@/composables/useLocaleParams'

const { t } = useI18n()
import HandbookExpressionInspector, {
  type HandbookExpressionDetail,
} from '@/components/handbook/HandbookExpressionInspector.vue'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'

interface HandbookItem {
  id: string
  text: string
  lang_code: string
  language_name?: string | null
}

interface HandbookSection {
  id: string
  title?: string | null
  items?: HandbookItem[]
}

interface HandbookDetail {
  id: string
  title: string
  author_username?: string | null
  visibility?: string | null
  score: number
  sections: HandbookSection[]
}

const route = useRoute()
const id = computed(() => route.params.id as string)

const { detail } = useHandbooks()
const { detail: expressionDetail, mappingGraph } = useExpressions()
const localeParams = useLocaleParams()

const hb = ref<HandbookDetail | null>(null)
const loading = ref(true)
const loadError = ref('')
const selectedExpression = ref<HandbookExpressionDetail | null>(null)
const inspectorLoading = ref(false)
const inspectorError = ref('')
const relationGraph = ref<MappingGraphResponse | null>(null)
const relationLoading = ref(false)
const relationError = ref('')
let selectionRequest = 0
let loadRequest = 0

async function load() {
  const request = ++loadRequest
  const requestedId = id.value
  hb.value = null
  loading.value = true
  loadError.value = ''
  try {
    const value = await detail(requestedId, localeParams.value)
    if (request !== loadRequest) return
    hb.value = value
  } catch (e: any) {
    if (request !== loadRequest) return
    loadError.value = e.response?.data?.error || t('handbook.loadFailed')
  } finally {
    if (request === loadRequest) loading.value = false
  }
}

async function selectExpression(item: HandbookItem) {
  await selectExpressionById(item.id, {
    id: item.id,
    text: item.text,
    lang_code: item.lang_code,
    language_name: item.language_name,
  })
}

async function selectExpressionById(
  expressionId: string,
  optimisticExpression?: HandbookExpressionDetail,
) {
  const request = ++selectionRequest
  selectedExpression.value = optimisticExpression ?? selectedExpression.value
  inspectorLoading.value = true
  inspectorError.value = ''
  relationGraph.value = null
  relationLoading.value = true
  relationError.value = ''

  const [detailResult, graphResult] = await Promise.allSettled([
    expressionDetail(expressionId, localeParams.value),
    mappingGraph(expressionId, 1, localeParams.value),
  ])
  if (request !== selectionRequest) return

  if (detailResult.status === 'fulfilled') {
    selectedExpression.value = {
      id: detailResult.value.expression.id,
      text: detailResult.value.expression.text,
      lang_code: detailResult.value.expression.lang_code,
      source_type: detailResult.value.expression.source_type,
    }
  } else {
    inspectorError.value = t('handbook.inspectorFailed')
  }
  if (graphResult.status === 'fulfilled') {
    relationGraph.value = graphResult.value
  } else {
    relationError.value = t('handbook.relationsFailed')
  }
  inspectorLoading.value = false
  relationLoading.value = false
}

function selectRelatedExpression(expressionId: string) {
  const node = relationGraph.value?.nodes.find(candidate => candidate.expression_id === expressionId)
  return selectExpressionById(expressionId, node ? {
    id: node.expression_id,
    text: node.text,
    lang_code: node.lang_code,
    language_name: node.language_name,
  } : undefined)
}

function closeInspector() {
  selectionRequest++
  selectedExpression.value = null
  inspectorLoading.value = false
  inspectorError.value = ''
  relationGraph.value = null
  relationLoading.value = false
  relationError.value = ''
}

function onKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape' && selectedExpression.value) closeInspector()
}

onMounted(() => {
  load()
  window.addEventListener('keydown', onKeydown)
})
onUnmounted(() => {
  loadRequest++
  selectionRequest++
  window.removeEventListener('keydown', onKeydown)
})
watch(id, () => {
  closeInspector()
  load()
})
</script>

<template>
  <LoadingSpinner v-if="loading" />

  <EmptyState v-else-if="loadError" :message="loadError" />

  <div v-else-if="hb" class="hv-layout">
    <aside class="hv-toc">
      <div class="hv-toc-label">{{ t('handbook.toc') }}</div>
      <ol>
        <li v-for="(sec, i) in hb.sections" :key="sec.id">
          <a :href="`#sec-${i}`">
            {{ i + 1 }} · {{ sec.title }}
          </a>
        </li>
      </ol>
    </aside>

    <main class="hv-content">
      <router-link to="/handbooks" class="hv-back">← {{ t('handbook.back') }}</router-link>
      <h1>{{ hb.title }}</h1>
      <div class="hv-meta">
        <span v-if="hb.author_username">{{ hb.author_username }}</span>
        <span v-if="hb.visibility">{{ hb.visibility }}</span>
      </div>

      <div class="hv-vote-row">
        <span>{{ t('handbook.helpful') }}</span>
        <VotePill :target-id="String(hb.id)" target-type="handbook" :score="hb.score" />
      </div>

      <section v-for="(sec, i) in hb.sections" :key="sec.id" :id="`sec-${i}`" class="hv-section">
        <div class="hv-sec-head">
          <span class="hv-sec-num">§{{ i + 1 }}</span>
          <h2>{{ sec.title || t('handbook.chapter', { number: i + 1 }) }}</h2>
        </div>
        <ol v-if="sec.items?.length" class="hb-expr-list">
          <li v-for="(expr, j) in sec.items" :key="expr.id">
            <button
              type="button"
              class="hb-expr"
              :class="{ selected: String(selectedExpression?.id) === expr.id }"
              :aria-expanded="String(selectedExpression?.id) === expr.id"
              aria-controls="handbook-expression-inspector"
              @click="selectExpression(expr)"
            >
              <span class="hb-num">{{ String(j + 1).padStart(2, '0') }}</span>
              <span class="hb-tx">{{ expr.text }}</span>
              <span class="lang-badge" :title="expr.lang_code">{{ expr.language_name || expr.lang_code }}</span>
              <span class="hb-go"><PanelRightOpen :size="15" aria-hidden="true" /></span>
            </button>
          </li>
        </ol>
      </section>

      <router-link :to="`/handbook/${id}/edit`" class="btn btn-ghost hb-edit-btn">
        {{ t('handbook.edit') }}
      </router-link>
    </main>

    <HandbookExpressionInspector
      id="handbook-expression-inspector"
      :expression="selectedExpression"
      :loading="inspectorLoading"
      :error="inspectorError"
      :graph="relationGraph"
      :graph-loading="relationLoading"
      :graph-error="relationError"
      @close="closeInspector"
      @select-expression="(id) => selectRelatedExpression(String(id))"
    />
  </div>
</template>

<style scoped>
.hv-layout {
  display: grid;
  grid-template-columns: 176px minmax(540px, 760px) minmax(240px, 292px);
  align-items: start;
  gap: 36px;
  width: min(calc(100vw - 56px), 1380px);
  margin-left: 50%;
  transform: translateX(-50%);
  padding: var(--page-pad-top) 28px var(--page-pad-bottom);
}
.hv-toc { position: sticky; top: calc(var(--bar-h) + 24px); align-self: start; min-width: 0; }
.hv-toc-label { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); margin-bottom: var(--space-xs); }
.hv-toc a { display: block; padding: 6px 9px; font-size: 13px; color: var(--muted); text-decoration: none; border-left: 2px solid transparent; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.hv-toc a:hover { color: var(--fg); background: var(--accent-soft); border-left-color: var(--accent); }
.hv-content { min-width: 0; }
.hv-back { font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--muted); display: inline-block; margin-bottom: 12px; }
.hv-back:hover { color: var(--fg); }
.hb-edit-btn { margin-top: var(--space-md); }
.hv-content h1 { font-size: clamp(26px, 3vw, 34px); line-height: 1.2; font-weight: 600; letter-spacing: -0.03em; }
.hv-meta { display: flex; gap: 10px; font-size: 13px; color: var(--muted); margin: 8px 0 16px; padding-bottom: 14px; border-bottom: 1px solid var(--border); }
.hv-toc ol { list-style: none; padding: 0; margin: 0; }
.hv-vote-row { display: flex; align-items: center; gap: 10px; margin-bottom: var(--space-md); font-size: 13px; }
.hv-section { scroll-margin-top: calc(var(--bar-h) + 20px); margin-bottom: 20px; padding-top: 14px; border-top: 1px solid var(--border); }
.hv-section:first-of-type { border-top: none; padding-top: 0; }
.hv-sec-head { display: flex; align-items: baseline; gap: 8px; margin-bottom: 6px; }
.hv-sec-head h2 { font-size: 17px; font-weight: 600; letter-spacing: -0.01em; }
.hv-sec-num { font-family: var(--mono); font-size: 12px; color: var(--accent); }
.hb-expr-list { list-style: none; padding: 0; }
.hb-expr {
  display: grid;
  grid-template-columns: 24px minmax(0, 1fr) auto 18px;
  width: 100%;
  min-width: 0;
  align-items: center;
  gap: 8px;
  min-height: 36px;
  padding: 5px 8px;
  border: 0;
  border-radius: var(--r);
  background: transparent;
  color: inherit;
  text-align: left;
  cursor: pointer;
  transition: background 0.12s, box-shadow 0.12s;
}
.hb-expr:hover { background: var(--surface); }
.hb-expr:hover .hb-tx { color: var(--accent); }
.hb-expr.selected { background: var(--accent-soft); box-shadow: inset 2px 0 var(--accent); }
.hb-expr:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.hb-num { font-family: var(--mono); font-size: 10px; color: var(--faint); }
.hb-tx { min-width: 0; font-size: 14px; font-weight: 500; letter-spacing: -0.01em; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.hb-go { display: grid; place-items: center; color: var(--faint); }
.hb-expr:hover .hb-go, .hb-expr.selected .hb-go { color: var(--accent); }

@media (max-width: 1200px) {
  .hv-layout {
    grid-template-columns: 160px minmax(0, 760px) 0;
    width: min(calc(100vw - 48px), 1020px);
    gap: 28px;
  }
}
@media (max-width: 768px) {
  .hv-layout {
    grid-template-columns: minmax(0, 1fr) 0;
    width: 100vw;
    gap: 0;
    padding: 22px 20px 72px;
  }
  .hv-toc {
    grid-column: 1;
    position: static;
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
    margin-bottom: 24px;
  }
  .hv-toc-label { width: 100%; }
  .hv-toc ol { display: flex; gap: 4px; max-width: 100%; overflow-x: auto; padding-bottom: 4px; }
  .hv-toc li { flex: 0 0 auto; }
  .hv-toc a { min-height: 44px; display: flex; align-items: center; border-left: 0; border-bottom: 2px solid transparent; }
  .hv-content { grid-column: 1; }
  .hb-expr { grid-template-columns: 24px minmax(0, 1fr) auto 20px; min-height: 44px; padding: 7px 6px; }
}
@media (max-width: 480px) {
  .hv-layout { padding-inline: 16px; }
  .hb-expr { gap: 8px; }
  .hv-vote-row { align-items: flex-start; flex-direction: column; }
}
</style>
