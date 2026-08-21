<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useHandbooks } from '@/composables/useHandbooks'
import { useExpressions } from '@/composables/useExpressions'
import VotePill from '@/components/mapping/VotePill.vue'
import { PanelRightOpen, Pencil } from 'lucide-vue-next'
import LoadingSpinner from '@/components/ui/LoadingSpinner.vue'
import EmptyState from '@/components/ui/EmptyState.vue'
import { useI18n } from 'vue-i18n'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { useLocalizationStore } from '@/stores/localization'

const { t } = useI18n()
import HandbookExpressionInspector, {
  type HandbookExpressionDetail,
} from '@/components/handbook/HandbookExpressionInspector.vue'
import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'

interface HandbookItem {
  id: string
  text: string
  lang_code: string
  language_profile_code?: string | null
  language_name?: string | null
}

interface HandbookSection {
  id: string
  title?: string | null
  position?: number
  parent_section_id?: string | null
  items?: HandbookItem[]
}

interface HandbookDetail {
  id: string
  title: string
  language_profile_code?: string | null
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
const localization = useLocalizationStore()

function sectionDepth(section: { parent_section_id?: string | null }, sections: Array<{ id: string; parent_section_id?: string | null }>): number {
  let depth = 0
  let parentId = section.parent_section_id ?? null
  const seen = new Set<string>()
  while (parentId && !seen.has(parentId)) {
    seen.add(parentId)
    depth += 1
    parentId = sections.find((candidate) => candidate.id === parentId)?.parent_section_id ?? null
  }
  return depth
}

function sectionNumber(section: HandbookSection, sections: HandbookSection[]): string {
  const numberParts: number[] = []
  let current: HandbookSection | undefined = section
  const seen = new Set<string>()
  while (current && !seen.has(current.id)) {
    seen.add(current.id)
    const siblings = sections
      .filter((candidate) => (candidate.parent_section_id ?? null) === (current?.parent_section_id ?? null))
      .sort((a, b) => (a.position ?? 0) - (b.position ?? 0) || a.id.localeCompare(b.id))
    numberParts.unshift(siblings.findIndex((candidate) => candidate.id === current?.id) + 1)
    current = current.parent_section_id ? sections.find((candidate) => candidate.id === current?.parent_section_id) : undefined
  }
  return numberParts.join('.')
}

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
    language_profile_code: item.language_profile_code,
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
    const selectedProfile = selectedExpression.value?.language_profile_code
      ?? detailResult.value.attestations.find(attestation => attestation.language_locale_code === 'cmn-Hant-TW')?.language_locale_code
      ?? detailResult.value.attestations[0]?.language_locale_code
      ?? null
    const selectedAttestation = detailResult.value.attestations.find(attestation => attestation.language_locale_code === selectedProfile)
    selectedExpression.value = {
      id: detailResult.value.expression.id,
      text: detailResult.value.expression.text,
      lang_code: detailResult.value.expression.lang_code,
      language_profile_code: selectedProfile,
      language_name: selectedAttestation?.locale_display_name
        ?? selectedExpression.value?.language_name
        ?? detailResult.value.expression.language_name
        ?? null,
      source_type: detailResult.value.expression.source_type,
      attestations: detailResult.value.attestations,
      readings: detailResult.value.readings,
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
    language_profile_code: node.language_profile_code,
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

watch([() => localization.locale, () => localization.secondary], () => {
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
          <a :href="`#sec-${i}`" :style="{ paddingLeft: `${9 + sectionDepth(sec, hb.sections) * 14}px` }">
            {{ sectionNumber(sec, hb.sections) }} · {{ sec.title }}
          </a>
        </li>
      </ol>
    </aside>

    <main class="hv-content">
      <router-link to="/handbooks" class="hv-back">← {{ t('handbook.back') }}</router-link>
      <div class="hv-title-row">
        <h1>{{ hb.title }}</h1>
        <router-link :to="`/handbooks/${id}/edit`" class="btn btn-ghost hb-edit-btn">
          <Pencil :size="15" aria-hidden="true" />
          <span>{{ t('handbook.edit') }}</span>
        </router-link>
      </div>
      <div class="hv-meta">
        <span v-if="hb.author_username" class="hv-author">@{{ hb.author_username.toLowerCase() }}</span>
        <span v-if="hb.visibility" class="hv-visibility">{{ hb.visibility }}</span>
      </div>

      <div class="hv-vote-row">
        <span>{{ t('handbook.helpful') }}</span>
        <VotePill :target-id="String(hb.id)" target-type="handbook" :score="hb.score" />
      </div>

      <section v-for="(sec, i) in hb.sections" :key="sec.id" :id="`sec-${i}`" class="hv-section" :class="{ 'hv-subsection': sectionDepth(sec, hb.sections) > 0 }">
        <div class="hv-sec-head">
          <span class="hv-sec-num">§{{ sectionNumber(sec, hb.sections) }}</span>
          <component :is="sectionDepth(sec, hb.sections) > 0 ? 'h3' : 'h2'">{{ sec.title || t('handbook.chapter', { number: sectionNumber(sec, hb.sections) }) }}</component>
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
              <span class="lang-badge" :title="expr.language_profile_code || expr.lang_code">{{ expr.language_name || expr.language_profile_code || expr.lang_code }}</span>
              <span class="hb-go"><PanelRightOpen :size="15" aria-hidden="true" /></span>
            </button>
          </li>
        </ol>
      </section>

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
.hv-title-row { display: flex; align-items: flex-start; justify-content: space-between; gap: 20px; }
.hv-title-row h1 { min-width: 0; }
.hb-edit-btn { flex: 0 0 auto; min-height: 38px; margin-top: 1px; gap: 7px; white-space: nowrap; }
.hv-content h1 { font-size: clamp(26px, 3vw, 34px); line-height: 1.2; font-weight: 600; letter-spacing: -0.03em; }
.hv-meta { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--muted); margin: 8px 0 16px; padding-bottom: 14px; border-bottom: 1px solid var(--border); }
.hv-author { color: var(--fg); font-family: var(--mono); }
.hv-visibility { display: inline-flex; align-items: center; min-height: 22px; padding: 0 8px; border: 1px solid var(--border); border-radius: var(--r); color: var(--muted); font-family: var(--mono); font-size: 11px; text-transform: lowercase; }
.hv-toc ol { list-style: none; padding: 0; margin: 0; }
.hv-vote-row { display: flex; align-items: center; gap: 10px; margin-bottom: var(--space-md); font-size: 13px; }
.hv-section { scroll-margin-top: calc(var(--bar-h) + 20px); margin-bottom: 20px; padding-top: 14px; border-top: 1px solid var(--border); }
.hv-section:first-of-type { border-top: none; padding-top: 0; }
.hv-sec-head { display: flex; align-items: baseline; gap: 8px; margin-bottom: 6px; }
.hv-sec-head h2 { font-size: 17px; font-weight: 600; letter-spacing: -0.01em; }
.hv-sec-head h3 { font-size: 15px; font-weight: 600; letter-spacing: -0.01em; color: var(--muted); }
.hv-sec-num { font-family: var(--mono); font-size: 12px; color: var(--accent); }
.hv-subsection { margin-left: 18px; padding-top: 10px; margin-bottom: 14px; }
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
  .hv-title-row { flex-direction: column; gap: 12px; }
  .hb-edit-btn { min-height: 44px; align-self: flex-start; }
  .hb-expr { gap: 8px; }
  .hv-vote-row { align-items: flex-start; flex-direction: column; }
}
</style>
