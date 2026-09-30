<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useTranslationStream } from '@/composables/useTranslationStream'
import type { TranslationRequestInput } from '@/api/translation'
import TranslationForm, { type TranslationFormValue } from './TranslationForm.vue'
import TranslationResult from './TranslationResult.vue'

const { t } = useI18n()
const stream = useTranslationStream()

const {
  stage,
  evidence,
  translation,
  result,
  error,
  isStreaming,
} = stream

const form = ref<TranslationFormValue>({ sourceLangCode: null, targetLocaleCode: '', text: '' })
const lastInput = ref<TranslationRequestInput | null>(null)

const translationErrorMessages: Record<string, string> = {
  VALIDATION_FAILED: 'phraseTranslate.errorValidation',
  PLAIN_TEXT_ONLY: 'phraseTranslate.errorPlainText',
  INVALID_LANG_CODE: 'phraseTranslate.errorSourceLanguage',
  INVALID_LANGUAGE_LOCALE_CODE: 'phraseTranslate.errorSourceLanguage',
  TARGET_LOCALE_NOT_FOUND: 'phraseTranslate.errorTargetLocale',
  PAYLOAD_TOO_LARGE: 'phraseTranslate.errorValidation',
  RATE_LIMITED: 'phraseTranslate.errorRateLimited',
  TRANSLATION_UNAVAILABLE: 'phraseTranslate.unavailable',
  AI_DAILY_QUOTA_EXHAUSTED: 'phraseTranslate.errorQuota',
  AI_PROVIDER_FAILED: 'phraseTranslate.errorProvider',
  TRANSLATION_FAILED: 'phraseTranslate.errorGeneric',
  TRANSLATION_OUTPUT_TOO_LARGE: 'phraseTranslate.errorOutputTooLarge',
  TRANSLATION_TIMEOUT: 'phraseTranslate.errorTimeout',
  NETWORK_ERROR: 'phraseTranslate.errorNetwork',
  STREAM_FAILED: 'phraseTranslate.errorNetwork',
  HTTP_429: 'phraseTranslate.errorRateLimited',
  HTTP_503: 'phraseTranslate.unavailable',
}

const progressError = computed(() => {
  if (!error.value) return null
  if (error.value.code === 'RATE_LIMITED' || error.value.code === 'HTTP_429') {
    return {
      ...error.value,
      message: error.value.retryAfterSeconds !== undefined
        ? t('phraseTranslate.rateLimited', { seconds: error.value.retryAfterSeconds })
        : t('phraseTranslate.errorRateLimited'),
    }
  }
  const key = translationErrorMessages[error.value.code]
    ?? (error.value.code.startsWith('HTTP_5') ? 'phraseTranslate.errorProvider' : 'phraseTranslate.errorGeneric')
  return { ...error.value, message: t(key) }
})

const progressMessage = computed(() => {
  switch (stage.value) {
    case 'analyzing': return t('phraseTranslate.stageAnalyzing')
    case 'retrieving': return t('phraseTranslate.stageRetrieving')
    case 'generating': return t('phraseTranslate.stageGenerating')
    default: return t('phraseTranslate.processStarting')
  }
})

function buildInput(): TranslationRequestInput | null {
  const sourceLangCode = form.value.sourceLangCode
  if (!sourceLangCode) return null
  return {
    text: form.value.text,
    source_lang_code: sourceLangCode,
    source_locale_code: null,
    target_locale_code: form.value.targetLocaleCode,
  }
}

function onFormUpdate(value: TranslationFormValue) {
  if (value.text !== form.value.text || value.sourceLangCode !== form.value.sourceLangCode || value.targetLocaleCode !== form.value.targetLocaleCode) {
    stream.reset()
    lastInput.value = null
  }
  form.value = value
}

function submit() {
  const input = buildInput()
  if (!input) return
  lastInput.value = input
  void stream.submit(input)
}

function retry() {
  if (!lastInput.value) return
  void stream.submit(lastInput.value)
}
</script>

<template>
  <section class="translation-workbench" aria-labelledby="translation-workbench-title">
    <header class="workbench-intro">
      <h2 id="translation-workbench-title">{{ t('phraseTranslate.title') }}</h2>
      <p class="translation-instruction">{{ t('phraseTranslate.subtitle') }}</p>
    </header>
    <div class="form-host">
      <TranslationForm
        :model-value="form"
        :disabled="isStreaming"
        @update:model-value="onFormUpdate"
        @submit="submit"
      />
    </div>

    <div v-if="isStreaming || progressError || translation || result" class="output-region">
      <p v-if="isStreaming" class="translation-status" role="status" aria-live="polite">
        {{ progressMessage }}
      </p>
      <div v-if="progressError" class="translation-error" role="alert">
        <p>{{ progressError.message }}</p>
        <button
          v-if="progressError.retryable && !translation && !result"
          type="button"
          class="btn retry-error"
          data-action="retry-error"
          @click="retry"
        >
          {{ t('phraseTranslate.retry') }}
        </button>
      </div>
      <TranslationResult
        v-if="translation || result"
        :translation="translation"
        :result="result"
        :evidence="evidence?.items ?? []"
        :source-lang-code="form.sourceLangCode"
      />
    </div>
  </section>
</template>

<style scoped>
.translation-workbench {
  display: grid;
  gap: 18px;
  width: 100%;
  max-width: 880px;
  margin: 0 auto;
  min-width: 0;
}
.workbench-intro { display: grid; gap: 4px; }
.workbench-intro h2 { margin: 0; font-size: clamp(22px, 3vw, 26px); line-height: 1.25; }
.form-host, .output-region { min-width: 0; }
.output-region { display: grid; gap: 12px; }
.translation-instruction { margin: 0; color: var(--muted); font-size: var(--text-ui); }
.translation-status {
  margin: 0;
  color: var(--muted);
  font-size: var(--text-meta);
}
.translation-error {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-width: 0;
  padding: 10px 12px;
  border: 1px solid color-mix(in oklch, var(--down) 40%, var(--border));
  border-radius: var(--r);
  background: var(--surface-2);
  color: var(--down);
  font-size: 13px;
}
.translation-error p { margin: 0; }
.retry-error { flex: none; min-height: 44px; }
@media (max-width: 480px) {
  .translation-error { align-items: stretch; flex-direction: column; }
  .retry-error { align-self: flex-start; }
}
</style>
