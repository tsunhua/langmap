<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { useLocalizationStore } from '@/stores/localization'
import { useExpressions } from '@/composables/useExpressions'
import { getMappingGraph } from '@/api/expressions'
import {
  createFormEdge,
  getExpressionFormEdges,
  listMorphologicalFeatures,
  type ExpressionFormEdges,
  type FormEdgeAsForm,
  type FormEdgeAsLemma,
  type FormEdgeFeature,
  type MorphologicalDimension,
} from '@/api/morphology'
import type { MappingGraphNode } from '@/components/mapping/mappingGraphTypes'
import { apiErrorMessage } from '@/utils/apiError'
import {
  WORD_CLASSES,
  featureCodesForSelection,
  type MorphologyWordClass,
} from '@/utils/morphologyFeatures'

const props = defineProps<{
  expressionId: string
  langCode: string
}>()

const { t } = useI18n()
const auth = useAuthStore()
const localeParams = useLocaleParams()
const localization = useLocalizationStore()
const { search } = useExpressions()

const loading = ref(false)
const loadError = ref('')
const edges = ref<ExpressionFormEdges | null>(null)
const dimensions = ref<MorphologicalDimension[]>([])

const lemmaMappings = ref<Array<{
  lemma: FormEdgeAsForm['lemma']
  neighbors: MappingGraphNode[]
}>>([])
const extraLemmas = ref<FormEdgeAsForm[]>([])
const mappingError = ref('')

const lemmaQuery = ref('')
const lemmaResults = ref<Array<{ id: string; text: string; lang_code: string }>>([])
const lemmaSearchLoading = ref(false)
const lemmaSearchError = ref('')
const selectedLemma = ref<{ id: string; text: string; lang_code: string } | null>(null)
const selectedFeatures = ref<string[]>([])
const submitting = ref(false)
const submitError = ref('')
const formOpen = ref(false)
const saveNotice = ref('')
const showAllFeatures = ref(false)
const wordClass = ref<MorphologyWordClass | null>(null)

let edgesRequest = 0
let mappingsRequest = 0
let lemmaSearchRequest = 0
let edgesAbort: AbortController | null = null
let mappingsAbort: AbortController | null = null

function featureLabel(features: FormEdgeFeature[]) {
  return features.map((feature) => feature.name).filter(Boolean).join(' ')
}

const dimensionOrder = computed(() => {
  const order = new Map<string, number>()
  for (const dimension of dimensions.value) order.set(dimension.code, dimension.sort_order)
  return order
})

const dimensionNames = computed(() => {
  const names = new Map<string, string>()
  for (const dimension of dimensions.value) names.set(dimension.code, dimension.name)
  return names
})

const inflectionGroups = computed(() => {
  const groups = new Map<string, FormEdgeAsLemma[]>()
  const ungrouped: FormEdgeAsLemma[] = []
  for (const item of edges.value?.as_lemma ?? []) {
    const code = item.features[0]?.dimension_code
    if (!code) {
      ungrouped.push(item)
      continue
    }
    const list = groups.get(code) ?? []
    list.push(item)
    groups.set(code, list)
  }
  const ordered = [...groups.entries()].sort((a, b) => {
    const left = dimensionOrder.value.get(a[0]) ?? Number.MAX_SAFE_INTEGER
    const right = dimensionOrder.value.get(b[0]) ?? Number.MAX_SAFE_INTEGER
    if (left !== right) return left - right
    return a[0].localeCompare(b[0])
  })
  return { ordered, ungrouped }
})

const hasEdges = computed(() =>
  (edges.value?.as_form.length ?? 0) > 0 || (edges.value?.as_lemma.length ?? 0) > 0,
)

const visibleDimensions = computed(() => {
  const allowed = featureCodesForSelection(props.langCode, wordClass.value, showAllFeatures.value)
  if (!allowed) return dimensions.value
  return dimensions.value
    .map((dimension) => ({
      ...dimension,
      features: dimension.features.filter((feature) => allowed.has(feature.code)),
    }))
    .filter((dimension) => dimension.features.length > 0)
})

const canExpandFeatures = computed(() => Boolean(wordClass.value) && !showAllFeatures.value)

function setWordClass(next: MorphologyWordClass) {
  wordClass.value = next
  showAllFeatures.value = false
  const allowed = featureCodesForSelection(props.langCode, next, false)
  if (!allowed) return
  selectedFeatures.value = selectedFeatures.value.filter((code) => allowed.has(code))
}

function abortIfStale(error: unknown) {
  return error instanceof DOMException && error.name === 'AbortError'
    || (typeof error === 'object' && error !== null && 'code' in error && (error as { code?: string }).code === 'ERR_CANCELED')
}

async function loadEdges() {
  const request = ++edgesRequest
  edgesAbort?.abort()
  mappingsAbort?.abort()
  const controller = new AbortController()
  edgesAbort = controller
  loading.value = true
  loadError.value = ''
  mappingError.value = ''
  lemmaMappings.value = []
  extraLemmas.value = []
  try {
    const hints = localeParams.value
    const [nextEdges, nextFeatures] = await Promise.all([
      getExpressionFormEdges(props.expressionId, { limit: 50, ...hints }, controller.signal),
      listMorphologicalFeatures(hints, controller.signal).catch(() => ({ dimensions: [] as MorphologicalDimension[] })),
    ])
    if (request !== edgesRequest) return
    const asForm = nextEdges.as_form ?? []
    const asLemma = nextEdges.as_lemma ?? []
    edges.value = { ...nextEdges, as_form: asForm, as_lemma: asLemma }
    dimensions.value = nextFeatures.dimensions ?? []
    await loadLemmaMappings(asForm, hints)
  } catch (error: unknown) {
    if (request !== edgesRequest || abortIfStale(error)) return
    loadError.value = apiErrorMessage(error, t('morphology.loadFailed'))
    edges.value = null
  } finally {
    if (request === edgesRequest) loading.value = false
  }
}

async function loadLemmaMappings(asForm: FormEdgeAsForm[], hints: { ui_locale?: string; secondary_ui_locale?: string }) {
  const request = ++mappingsRequest
  mappingsAbort?.abort()
  const controller = new AbortController()
  mappingsAbort = controller
  extraLemmas.value = asForm.slice(3)
  const first = asForm.slice(0, 3)
  if (first.length === 0) {
    lemmaMappings.value = []
    return
  }
  mappingError.value = ''
  try {
    let failed = false
    const results = await Promise.all(
      first.map(async (item) => {
        try {
          const graph = await getMappingGraph(item.lemma.id, 1, hints, controller.signal)
          return {
            lemma: item.lemma,
            neighbors: graph.nodes
              .filter((node) => node.depth >= 1)
              .slice()
              .sort((a, b) => a.expression_id.localeCompare(b.expression_id)),
          }
        } catch (error: unknown) {
          if (abortIfStale(error)) throw error
          failed = true
          return { lemma: item.lemma, neighbors: [] }
        }
      }),
    )
    if (request !== mappingsRequest) return
    lemmaMappings.value = results
    if (failed) mappingError.value = t('morphology.mappingLoadFailed')
  } catch (error: unknown) {
    if (request !== mappingsRequest || abortIfStale(error)) return
    mappingError.value = apiErrorMessage(error, t('morphology.mappingLoadFailed'))
    lemmaMappings.value = first.map((item) => ({ lemma: item.lemma, neighbors: [] }))
  }
}

async function searchLemma() {
  const query = lemmaQuery.value.trim()
  if (!query) {
    lemmaSearchRequest += 1
    lemmaResults.value = []
    lemmaSearchError.value = ''
    return
  }
  const request = ++lemmaSearchRequest
  lemmaSearchLoading.value = true
  lemmaSearchError.value = ''
  try {
    const data = await search(query, props.langCode, 8, localeParams.value)
    if (request !== lemmaSearchRequest) return
    const items = (data.items ?? []) as Array<{ id: string; text: string; lang_code: string }>
    lemmaResults.value = items.filter((item) => item.id !== props.expressionId)
  } catch (error: unknown) {
    if (request !== lemmaSearchRequest) return
    lemmaSearchError.value = apiErrorMessage(error, t('search.loadFailed'))
    lemmaResults.value = []
  } finally {
    if (request === lemmaSearchRequest) lemmaSearchLoading.value = false
  }
}

function selectLemma(item: { id: string; text: string; lang_code: string }) {
  selectedLemma.value = item
  lemmaQuery.value = item.text
  lemmaResults.value = []
  submitError.value = ''
  saveNotice.value = ''
}

function toggleForm() {
  formOpen.value = !formOpen.value
  submitError.value = ''
  saveNotice.value = ''
  if (!formOpen.value) {
    showAllFeatures.value = false
    wordClass.value = null
  }
}

function selectFeature(dimensionCode: string, featureCode: string) {
  const dimensionCodes = new Set(
    dimensions.value
      .find((dimension) => dimension.code === dimensionCode)
      ?.features.map((feature) => feature.code) ?? [],
  )
  const withoutDimension = selectedFeatures.value.filter((code) => !dimensionCodes.has(code))
  if (selectedFeatures.value.includes(featureCode)) {
    selectedFeatures.value = withoutDimension
  } else {
    selectedFeatures.value = [...withoutDimension, featureCode]
  }
}

async function submitFormEdge() {
  if (!selectedLemma.value) return
  submitting.value = true
  submitError.value = ''
  try {
    await createFormEdge(
      props.expressionId,
      {
        lemma_expression_id: selectedLemma.value.id,
        features: selectedFeatures.value,
      },
      localeParams.value,
    )
    selectedLemma.value = null
    selectedFeatures.value = []
    lemmaQuery.value = ''
    lemmaResults.value = []
    saveNotice.value = t('morphology.saved')
    formOpen.value = false
    await loadEdges()
  } catch (error: unknown) {
    submitError.value = apiErrorMessage(error, t('morphology.submitFailed'))
  } finally {
    submitting.value = false
  }
}

watch(
  () => [props.expressionId, localization.locale, localization.secondary] as const,
  () => { void loadEdges() },
  { immediate: true },
)

watch(
  () => props.langCode,
  () => {
    showAllFeatures.value = false
    const allowed = featureCodesForSelection(props.langCode, wordClass.value, false)
    if (!allowed) {
      selectedFeatures.value = []
      return
    }
    selectedFeatures.value = selectedFeatures.value.filter((code) => allowed.has(code))
  },
)
</script>

<template>
  <section class="morph" :aria-label="t('morphology.title')">
    <div class="nb-head">
      <h2>{{ t('morphology.title') }}</h2>
      <button
        v-if="auth.isLoggedIn"
        class="btn btn-sm"
        type="button"
        :aria-expanded="formOpen"
        :aria-controls="'morph-form'"
        @click="toggleForm"
      >
        {{ formOpen ? t('morphology.hideForm') : t('morphology.addFormLink') }}
      </button>
    </div>
    <p v-if="saveNotice" class="morph-note" role="status">{{ saveNotice }}</p>
    <p v-else-if="!auth.isLoggedIn" class="morph-note">
      <router-link to="/auth" class="morph-signin">{{ t('morphology.signInToAdd') }}</router-link>
    </p>

    <p v-if="loading && !edges" class="morph-note">{{ t('common.loading') }}</p>
    <p v-else-if="loadError" class="morph-error" role="alert">{{ loadError }}</p>
    <p v-else-if="!hasEdges && !formOpen" class="morph-note">{{ t('morphology.empty') }}</p>

    <template v-else>
      <section v-if="edges && edges.as_form.length" class="morph-block">
        <h3>{{ t('morphology.lemmas') }}</h3>
        <ul class="morph-list">
          <li v-for="item in edges.as_form" :key="item.edge_id">
            <router-link :to="`/mapping/${item.lemma.id}`" class="morph-link">
              <span v-if="featureLabel(item.features)">{{ featureLabel(item.features) }} ← </span>
              <span>{{ item.lemma.text }}</span>
            </router-link>
          </li>
        </ul>
      </section>

      <section v-if="edges && edges.as_lemma.length" class="morph-block">
        <h3>{{ t('morphology.inflections') }}</h3>
        <div
          v-for="[code, forms] in inflectionGroups.ordered"
          :key="code"
          class="morph-group"
        >
          <h4>{{ dimensionNames.get(code) || code }}</h4>
          <ul class="morph-list">
            <li v-for="item in forms" :key="item.edge_id">
              <router-link :to="`/mapping/${item.form.id}`" class="morph-link">
                <span>{{ item.form.text }}</span>
                <span v-if="featureLabel(item.features)" class="morph-feats">{{ featureLabel(item.features) }}</span>
              </router-link>
            </li>
          </ul>
        </div>
        <ul v-if="inflectionGroups.ungrouped.length" class="morph-list">
          <li v-for="item in inflectionGroups.ungrouped" :key="item.edge_id">
            <router-link :to="`/mapping/${item.form.id}`" class="morph-link">
              {{ item.form.text }}
            </router-link>
          </li>
        </ul>
      </section>

      <section v-if="lemmaMappings.length || extraLemmas.length" class="morph-block">
        <h3>{{ t('morphology.lemmaMappings') }}</h3>
        <p v-if="mappingError" class="morph-error" role="alert">{{ mappingError }}</p>
        <div v-for="group in lemmaMappings" :key="group.lemma.id" class="morph-group">
          <h4>
            <router-link :to="`/mapping/${group.lemma.id}`" class="morph-link">
              {{ group.lemma.text }}
            </router-link>
          </h4>
          <ul v-if="group.neighbors.length" class="morph-list">
            <li v-for="node in group.neighbors" :key="node.expression_id">
              <router-link :to="`/mapping/${node.expression_id}`" class="morph-link">
                {{ node.text }}
                <span v-if="node.language_name || node.lang_code" class="morph-feats">{{ node.language_name || node.lang_code }}</span>
              </router-link>
            </li>
          </ul>
        </div>
        <div v-if="extraLemmas.length" class="morph-group">
          <h4>{{ t('morphology.moreLemmas') }}</h4>
          <ul class="morph-list">
            <li v-for="item in extraLemmas" :key="item.edge_id">
              <router-link :to="`/mapping/${item.lemma.id}`" class="morph-link">
                {{ item.lemma.text }}
                <span class="morph-feats">{{ t('morphology.viewMapping') }}</span>
              </router-link>
            </li>
          </ul>
        </div>
      </section>
    </template>

    <section
      v-if="auth.isLoggedIn && formOpen"
      id="morph-form"
      class="morph-block morph-form"
      :aria-label="t('morphology.markAsForm')"
    >
      <h3>{{ t('morphology.markAsForm') }}</h3>
      <label class="morph-field" for="morph-lemma-search">{{ t('morphology.searchLemmaLabel') }}</label>
      <div class="morph-search">
        <input
          id="morph-lemma-search"
          v-model="lemmaQuery"
          type="search"
          :placeholder="t('morphology.searchLemma')"
          autocomplete="off"
          @keydown.enter.prevent="searchLemma"
        />
        <button class="btn btn-sm" type="button" @click="searchLemma">{{ t('common.search') }}</button>
      </div>
      <p v-if="lemmaSearchLoading" class="morph-note">{{ t('common.loading') }}</p>
      <p v-else-if="lemmaSearchError" class="morph-error" role="alert">{{ lemmaSearchError }}</p>
      <ul v-else-if="lemmaResults.length" class="morph-pick" role="listbox" :aria-label="t('morphology.searchLemma')">
        <li v-for="item in lemmaResults" :key="item.id">
          <button
            type="button"
            class="morph-pick-btn"
            :aria-pressed="selectedLemma?.id === item.id"
            @click="selectLemma(item)"
          >
            {{ item.text }}
          </button>
        </li>
      </ul>
      <p v-if="selectedLemma" class="morph-selected">{{ selectedLemma.text }}</p>

      <fieldset class="morph-dim">
        <legend>{{ t('morphology.wordClass') }}</legend>
        <p class="morph-hint">{{ t('morphology.wordClassHint') }}</p>
        <div class="morph-chips" role="radiogroup" :aria-label="t('morphology.wordClass')">
          <label
            v-for="item in WORD_CLASSES"
            :key="item"
            class="morph-chip"
            :class="{ on: wordClass === item }"
          >
            <input
              type="radio"
              name="morph-word-class"
              :value="item"
              :checked="wordClass === item"
              @change="setWordClass(item)"
            />
            <span>{{ t(`morphology.class.${item}`) }}</span>
          </label>
        </div>
      </fieldset>

      <fieldset v-if="wordClass || showAllFeatures" class="morph-dim">
        <legend>{{ t('morphology.pickFeatures') }}</legend>
        <p class="morph-hint">{{ t('morphology.pickFeaturesHint') }}</p>
        <div class="morph-feature-grid">
          <div class="morph-chip-scroll">
            <div v-for="dimension in visibleDimensions" :key="dimension.code" class="morph-chip-group">
              <p class="morph-chip-label">{{ dimension.name }}</p>
              <div class="morph-chips">
                <label
                  v-for="feature in dimension.features"
                  :key="feature.code"
                  class="morph-chip"
                  :class="{ on: selectedFeatures.includes(feature.code) }"
                >
                  <input
                    type="radio"
                    :name="`morph-feature-${dimension.code}`"
                    :value="feature.code"
                    :checked="selectedFeatures.includes(feature.code)"
                    @change="selectFeature(dimension.code, feature.code)"
                  />
                  <span>{{ feature.name }}</span>
                </label>
              </div>
            </div>
            <p v-if="visibleDimensions.length === 0" class="morph-hint">{{ t('morphology.noLanguageFeatures') }}</p>
          </div>
        </div>
        <button
          v-if="canExpandFeatures && !showAllFeatures"
          class="btn btn-sm morph-more"
          type="button"
          @click="showAllFeatures = true"
        >
          {{ t('morphology.showAllFeatures') }}
        </button>
      </fieldset>

      <p v-if="submitError" class="morph-error" role="alert">{{ submitError }}</p>
      <button
        class="btn btn-primary btn-sm"
        type="button"
        :disabled="!selectedLemma || submitting"
        @click="submitFormEdge"
      >
        {{ submitting ? t('morphology.saving') : t('morphology.submit') }}
      </button>
    </section>
  </section>
</template>

<style scoped>
.morph { min-width: 0; }
.morph :deep(.nb-head) { align-items: center; }
.morph :deep(.nb-head .btn) { flex-shrink: 0; }
.morph-signin { color: var(--accent); text-underline-offset: 2px; }
.morph-signin:hover { text-decoration: underline; }
.morph-block {
  display: grid;
  gap: var(--space-sm);
  margin-top: var(--space-sm);
  padding: var(--space-sm) var(--space-base);
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  min-width: 0;
}
.morph-block h3 {
  margin: 0;
  font-size: var(--text-ui);
  font-weight: 600;
}
.morph-group { display: grid; gap: var(--space-xs); min-width: 0; }
.morph-group + .morph-group { margin-top: var(--space-sm); }
.morph-group h4 {
  margin: 0;
  font-size: 13px;
  font-weight: 600;
  color: var(--muted);
}
.morph-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: 0;
}
.morph-link {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 6px 10px;
  min-height: 40px;
  min-width: 0;
  padding: 8px 0;
  color: var(--fg);
}
.morph-link:hover { color: var(--accent); }
.morph-link:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
.morph-feats { color: var(--muted); font-size: 13px; }
.morph-note, .morph-error { margin: 0; font-size: 13px; line-height: 1.5; }
.morph > .morph-note,
.morph > .morph-error { margin-bottom: var(--space-sm); }
.morph-note { color: var(--muted); }
.morph-error { color: var(--down); }
.morph-form { gap: var(--space-base); }
.morph-field { display: block; margin: 0 0 var(--space-xs); font-size: 13px; color: var(--muted); }
.morph-search { display: flex; gap: var(--space-xs); align-items: center; }
.morph-search input { flex: 1; min-width: 0; }
.morph-pick { list-style: none; margin: 0; padding: 0; border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; }
.morph-pick-btn {
  display: flex;
  align-items: center;
  width: 100%;
  min-height: 40px;
  padding: 8px 12px;
  border: none;
  background: var(--surface);
  color: var(--fg);
  text-align: left;
  cursor: pointer;
}
.morph-pick-btn:hover { background: var(--bg); }
.morph-pick-btn:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
.morph-selected { margin: 0; font-size: 13px; color: var(--fg); }
.morph-dim {
  display: grid;
  gap: var(--space-xs);
  margin: 0;
  padding: 0;
  border: none;
  min-width: 0;
}
.morph-dim legend { font-size: 13px; color: var(--muted); padding: 0; }
.morph-hint { margin: 0; font-size: 13px; line-height: 1.5; color: var(--muted); }
.morph-feature-grid { min-width: 0; }
.morph-chip-scroll {
  min-width: 0;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--space-sm);
}
.morph-more { justify-self: start; }
.morph-chip-group {
  display: grid;
  align-content: start;
  gap: var(--space-xs);
  min-width: 0;
  padding: var(--space-sm);
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface-2);
}
.morph-chip-label { margin: 0; font-size: 12px; color: var(--muted); }
.morph-chips { display: flex; flex-wrap: wrap; gap: var(--space-xs); }
.morph-chip {
  display: inline-flex;
  align-items: center;
  min-height: 40px;
  padding: 0 12px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  cursor: pointer;
}
.morph-chip.on {
  border-color: var(--accent);
  background: var(--accent-soft);
}
.morph-chip:focus-within { outline: 2px solid var(--accent); outline-offset: 2px; }
.morph-chip input[type='checkbox'],
.morph-chip input[type='radio'] {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
.visually-hidden {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
@media (prefers-reduced-motion: reduce) {
  .morph-link, .morph-pick-btn { transition: none; }
}
</style>
