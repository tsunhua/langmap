<script setup lang="ts">
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useLanguageCreation } from '@/composables/useLanguageCreation'
import { useLanguagesStore } from '@/stores/languages'
import LanguageTagBuilder from './LanguageTagBuilder.vue'
import GlottologMatchList from './GlottologMatchList.vue'
import LanguageMetadataForm from './LanguageMetadataForm.vue'
import { X, ArrowLeft, ArrowRight, Loader2 } from 'lucide-vue-next'

const { t } = useI18n()

const props = defineProps<{
  open: boolean
  returnFocus?: HTMLElement | null
}>()

const emit = defineEmits<{
  created: [language: { code: string; name: string }]
  close: []
}>()

const creation = useLanguageCreation()
const store = useLanguagesStore()

const dialogRef = ref<HTMLDivElement>()
const tagValid = ref(false)
const glottocodeSelected = ref(false)
const metadataErrors = ref<Record<string, string>>({})

const stepTitles = computed(() => [
  t('languageCreate.stepTag'),
  t('languageCreate.stepGlottolog'),
  t('languageCreate.stepMetadata'),
  t('languageCreate.stepPreview'),
])

const currentStepTitle = computed(() => stepTitles.value[creation.step.value - 1])

const canAdvance = computed(() => {
  switch (creation.step.value) {
    case 1:
      return tagValid.value
    case 2:
      return glottocodeSelected.value
    case 3:
      return Object.keys(metadataErrors.value).length === 0
    case 4:
      return true
    default:
      return false
  }
})

const isLastStep = computed(() => creation.step.value === 4)
const isFirstStep = computed(() => creation.step.value === 1)

function validateMetadata(): boolean {
  const errors: Record<string, string> = {}
  if (!creation.metadata.name.trim()) errors.name = t('languageCreate.errorName')
  if (!creation.metadata.description.trim()) errors.description = t('languageCreate.errorDescription')
  if (creation.glottocode.value === null && !creation.metadata.reason) {
    errors.reason = t('languageCreate.errorReason')
  }
  metadataErrors.value = errors
  return Object.keys(errors).length === 0
}

watch(
  () => creation.step.value,
  (step) => {
    if (step === 3) validateMetadata()
    else metadataErrors.value = {}
  },
)

function nextStep() {
  if (creation.step.value === 3 && !validateMetadata()) return
  if (!canAdvance.value) return
  if (creation.step.value < 4) {
    creation.goToStep((creation.step.value + 1) as 1 | 2 | 3 | 4)
  }
}

function prevStep() {
  if (creation.step.value > 1) {
    creation.goToStep((creation.step.value - 1) as 1 | 2 | 3 | 4)
  }
}

async function handleSubmit() {
  if (!validateMetadata()) return
  const result = await creation.submit()
  if (result) {
    store.upsertLanguage(result.variety)
    emit('created', { code: result.variety.code, name: result.variety.name })
    emit('close')
    creation.reset()
  }
}

function handleClose() {
  emit('close')
  creation.reset()
}

function onKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') {
    e.preventDefault()
    handleClose()
  }
}

function trapFocus(e: KeyboardEvent) {
  if (e.key !== 'Tab' || !dialogRef.value) return
  const focusable = dialogRef.value.querySelectorAll<HTMLElement>(
    'input:not([disabled]), select:not([disabled]), textarea:not([disabled]), button:not([disabled]), [tabindex]:not([tabindex="-1"])',
  )
  if (focusable.length === 0) return
  const first = focusable[0]
  const last = focusable[focusable.length - 1]
  if (e.shiftKey) {
    if (document.activeElement === first) {
      e.preventDefault()
      last.focus()
    }
  } else {
    if (document.activeElement === last) {
      e.preventDefault()
      first.focus()
    }
  }
}

watch(
  () => props.open,
  async (isOpen) => {
    if (isOpen) {
      await nextTick()
      const firstInput = dialogRef.value?.querySelector<HTMLElement>(
        'input:not([disabled]), select:not([disabled])',
      )
      firstInput?.focus()
    }
  },
)

onMounted(() => {
  document.addEventListener('keydown', onKeydown)
})
onUnmounted(() => {
  document.removeEventListener('keydown', onKeydown)
})
</script>

<template>
  <Teleport to="body">
    <div
      v-if="open"
      ref="dialogRef"
      role="dialog"
      aria-modal="true"
      :aria-label="t('languageCreate.dialogLabel')"
      class="dialog-overlay"
      @keydown="trapFocus"
    >
      <div class="dialog-panel">
        <header class="dialog-header">
          <h2 class="dialog-title">{{ currentStepTitle }}</h2>
          <button
            class="dialog-close btn-icon"
            :aria-label="t('languageCreate.close')"
            data-action="cancel"
            @click="handleClose"
          >
            <X :size="18" />
          </button>
        </header>

        <div class="dialog-steps">
          <span
            v-for="(title, i) in stepTitles"
            :key="i"
            class="step-indicator"
            :class="{ active: i + 1 === creation.step.value, done: i + 1 < creation.step.value }"
          >
            {{ i + 1 }}
          </span>
        </div>

        <div class="dialog-body">
          <div v-if="creation.step.value === 1">
            <LanguageTagBuilder
              :model-value="creation.subtags.value"
              @update:model-value="creation.subtags.value = $event"
              @validity-change="tagValid = $event"
            />
          </div>

          <div v-else-if="creation.step.value === 2">
            <GlottologMatchList
              :candidates="creation.languoidOptions.value"
              :selected-glottocode="creation.glottocode.value"
              :has-selection="glottocodeSelected"
              :loading="creation.loadingLanguoids.value"
              :initial-query="creation.subtags.value.language"
              @select="creation.glottocode.value = $event; glottocodeSelected = true"
              @search="creation.searchLanguoids($event)"
            />
          </div>

          <div v-else-if="creation.step.value === 3">
            <LanguageMetadataForm
              :name="creation.metadata.name"
              :name-en="creation.metadata.name_en"
              :description="creation.metadata.description"
              :reason="creation.metadata.reason"
              :glottocode="creation.glottocode.value"
              :errors="metadataErrors"
              @update:name="creation.metadata.name = $event"
              @update:name-en="creation.metadata.name_en = $event"
              @update:description="creation.metadata.description = $event"
              @update:reason="creation.metadata.reason = $event"
            />
          </div>

          <div v-else-if="creation.step.value === 4" class="preview-step">
            <div v-if="creation.preview.value?.existing_variety" class="preview-existing">
              <p>{{ t('languageCreate.previewExisting') }}</p>
              <button
                class="btn"
                @click="emit('created', { code: creation.preview.value!.existing_variety!.code, name: creation.preview.value!.existing_variety!.name }); handleClose()"
              >
                {{ t('languageCreate.previewExistingAction') }}
              </button>
            </div>
            <div v-else class="preview-details">
              <div class="preview-row">
                <span class="preview-label">{{ t('languageCreate.previewCanonicalCode') }}</span>
                <code>{{ creation.preview.value?.canonical_profile_code || '—' }}</code>
              </div>
              <div v-if="creation.preview.value?.warnings?.length" class="preview-warnings">
                <p class="preview-label">{{ t('languageCreate.previewWarnings') }}</p>
                <ul>
                  <li v-for="(w, i) in creation.preview.value.warnings" :key="i">{{ w }}</li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <footer class="dialog-footer">
          <button
            v-if="!isFirstStep"
            class="btn"
            data-action="back"
            @click="prevStep"
          >
            <ArrowLeft :size="14" />
            {{ t('languageCreate.back') }}
          </button>
          <div class="footer-spacer" />
          <button
            class="btn"
            data-action="cancel"
            @click="handleClose"
          >
            {{ t('languageCreate.cancel') }}
          </button>
          <button
            v-if="!isLastStep"
            class="btn btn-primary"
            data-action="next"
            :disabled="!canAdvance"
            @click="nextStep"
          >
            {{ t('languageCreate.next') }}
            <ArrowRight :size="14" />
          </button>
          <button
            v-else
            class="btn btn-primary"
            data-action="create"
            :disabled="creation.loadingSubmit.value"
            @click="handleSubmit"
          >
            <Loader2 v-if="creation.loadingSubmit.value" :size="14" class="spin" />
            {{ creation.loadingSubmit.value ? t('languageCreate.creating') : t('languageCreate.create') }}
          </button>
        </footer>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.dialog-overlay {
  position: fixed;
  inset: 0;
  z-index: 200;
  display: flex;
  align-items: center;
  justify-content: center;
  background: oklch(0 0 0 / 0.4);
  padding: 16px;
}
.dialog-panel {
  background: var(--surface);
  border-radius: var(--r);
  box-shadow: 0 8px 32px oklch(0 0 0 / 0.15);
  width: 100%;
  max-width: 520px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.dialog-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid var(--border);
}
.dialog-title {
  font-size: 15px;
  font-weight: 600;
}
.dialog-close {
  width: 36px;
  height: 36px;
}
.dialog-steps {
  display: flex;
  gap: 8px;
  padding: 12px 20px;
  border-bottom: 1px solid var(--border);
}
.step-indicator {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: grid;
  place-items: center;
  font-size: 12px;
  font-weight: 600;
  border: 1px solid var(--border);
  color: var(--muted);
  background: var(--surface);
}
.step-indicator.active {
  border-color: var(--accent);
  background: var(--accent);
  color: #fff;
}
.step-indicator.done {
  border-color: var(--up);
  background: var(--up);
  color: #fff;
}
.dialog-body {
  padding: 20px;
  overflow-y: auto;
  flex: 1;
}
.preview-step {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.preview-existing {
  padding: 16px;
  background: var(--accent-soft);
  border-radius: var(--r);
}
.preview-details {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.preview-row {
  display: flex;
  align-items: center;
  gap: 8px;
}
.preview-label {
  font-size: 12px;
  color: var(--muted);
  font-weight: 500;
}
.preview-warnings ul {
  padding-left: 16px;
  margin: 4px 0 0;
  font-size: 13px;
  color: var(--down);
}
.step-divider {
  margin: 16px 0;
  border-top: 1px solid var(--border);
}
.dialog-footer {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-top: 1px solid var(--border);
}
.footer-spacer {
  flex: 1;
}
.spin {
  animation: spin 1s linear infinite;
}
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
</style>
