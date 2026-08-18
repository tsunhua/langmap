<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { useLocaleParams } from '@/composables/useLocaleParams'
import { useLocalizationStore } from '@/stores/localization'
import { useExpressions } from '@/composables/useExpressions'
import {
  createFormEdge,
  getExpressionFormEdges,
  listMorphologicalFeatures,
  type ExpressionFormEdges,
  type FormEdgeFeature,
  type MorphologicalDimension,
} from '@/api/morphology'
import { apiErrorMessage } from '@/utils/apiError'
import {
  WORD_CLASSES,
  featureCodesForSelection,
  type MorphologyWordClass,
} from '@/utils/morphologyFeatures'

const props = defineProps<{
  expressionId: string
  langCode: string
  text: string
}>()

const { t } = useI18n()
const router = useRouter()
const auth = useAuthStore()
const localeParams = useLocaleParams()
const localization = useLocalizationStore()
const { search } = useExpressions()

const isSingleWord = computed(() => !/\s/.test(props.text.trim()))

const loading = ref(false)
const loadError = ref('')
const edges = ref<ExpressionFormEdges | null>(null)
const dimensions = ref<MorphologicalDimension[]>([])

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
let lemmaSearchRequest = 0
let edgesAbort: AbortController | null = null

function featureLabel(features: FormEdgeFeature[]) {
  return features.map((feature) => feature.name).filter(Boolean).join(' ')
}

const dimensionOrder = computed(() => {
  const order = new Map<string, number>()
  for (const dimension of dimensions.value) order.set(dimension.code, dimension.sort_order)
  return order
})

const orderedInflections = computed(() => {
  const items = edges.value?.as_lemma ?? []
  return [...items].sort((a, b) => {
    const aDim = a.features[0]?.dimension_code
    const bDim = b.features[0]?.dimension_code
    const aOrder = aDim ? (dimensionOrder.value.get(aDim) ?? Number.MAX_SAFE_INTEGER) : Number.MAX_SAFE_INTEGER
    const bOrder = bDim ? (dimensionOrder.value.get(bDim) ?? Number.MAX_SAFE_INTEGER) : Number.MAX_SAFE_INTEGER
    if (aOrder !== bOrder) return aOrder - bOrder
    const aLabel = featureLabel(a.features)
    const bLabel = featureLabel(b.features)
    if (aLabel !== bLabel) return aLabel.localeCompare(bLabel)
    return a.form.text.localeCompare(b.form.text)
  })
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
  const controller = new AbortController()
  edgesAbort = controller
  loading.value = true
  loadError.value = ''
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
  } catch (error: unknown) {
    if (request !== edgesRequest || abortIfStale(error)) return
    loadError.value = apiErrorMessage(error, t('morphology.loadFailed'))
    edges.value = null
  } finally {
    if (request === edgesRequest) loading.value = false
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
  if (!auth.isLoggedIn) {
    router.push('/auth')
    return
  }
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
  () => { if (isSingleWord.value) void loadEdges() },
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
  <section v-if="isSingleWord" class="morph" :aria-label="t('morphology.title')">
    <div class="nb-head">
      <h2>{{ t('morphology.title') }}</h2>
      <button
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

    <p v-if="loading && !edges" class="morph-note">{{ t('common.loading') }}</p>
    <p v-else-if="loadError" class="morph-error" role="alert">{{ loadError }}</p>
    <p v-else-if="!hasEdges && !formOpen" class="morph-note">{{ t('morphology.empty') }}</p>

    <template v-else>
      <ul v-if="edges && edges.as_form.length" class="morph-chips">
        <li v-for="item in edges.as_form" :key="item.edge_id">
          <router-link :to="`/mapping/${item.lemma.id}`" class="morph-form-chip">
            <span class="morph-role">{{ t('morphology.dictionaryForm') }}：</span>
            <span>{{ item.lemma.text }}</span>
            <span v-if="featureLabel(item.features)" class="morph-feats">{{ featureLabel(item.features) }}</span>
          </router-link>
        </li>
      </ul>

      <ul v-if="edges && orderedInflections.length" class="morph-chips">
        <li v-for="item in orderedInflections" :key="item.edge_id">
          <router-link :to="`/mapping/${item.form.id}`" class="morph-form-chip">
            <span v-if="featureLabel(item.features)" class="morph-feats">{{ featureLabel(item.features) }}：</span>
            <span>{{ item.form.text }}</span>
          </router-link>
        </li>
      </ul>
    </template>

    <section
      v-if="formOpen"
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
.morph-chips {
  list-style: none;
  margin: var(--space-sm) 0 0;
  padding: 0;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  min-width: 0;
}
.morph-chips + .morph-chips { margin-top: 8px; }
.morph-role { color: var(--muted); font-size: 12px; }
.morph-form-chip {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  min-height: 44px;
  padding: 0 12px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface-2);
  color: var(--fg);
  transition: border-color 0.15s, color 0.15s;
}
.morph-form-chip:hover { border-color: var(--accent); color: var(--accent); }
.morph-form-chip:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
.morph-form-chip .morph-feats { font-size: 12px; }
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
  .morph-pick-btn, .morph-form-chip { transition: none; }
}
</style>
