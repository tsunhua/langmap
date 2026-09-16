<script setup lang="ts">
import { computed, nextTick, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useAuthStore } from '@/stores/auth'
import { useContributePrefillStore } from '@/stores/contributePrefill'
import { useTranslationStream } from '@/composables/useTranslationStream'
import { getLanguageLocale } from '@/api/languageIdentity'
import type { TranslationRequestInput } from '@/api/translation'
import TranslationForm, { type TranslationFormValue } from '@/components/translation/TranslationForm.vue'
import TranslationProgress from '@/components/translation/TranslationProgress.vue'
import TranslationResult from '@/components/translation/TranslationResult.vue'
import EvidenceList from '@/components/translation/EvidenceList.vue'
import LanguagePicker from '@/components/language/LanguagePicker.vue'

const router = useRouter()
const { t } = useI18n()
const auth = useAuthStore()
const prefillStore = useContributePrefillStore()
const stream = useTranslationStream()

const {
  stage,
  mode,
  sourceLanguage,
  confirmation,
  evidence,
  translation,
  alternatives,
  result,
  error,
  isStreaming,
} = stream

const authorized = computed(() => auth.isLoggedIn)
const form = ref<TranslationFormValue>({ sourceLangCode: null, targetLocaleCode: '', text: '' })
const lastInput = ref<TranslationRequestInput | null>(null)
const confirmationSource = ref('')
const confirmationHeading = ref<HTMLElement | null>(null)
const formHost = ref<HTMLElement | null>(null)
const contributeError = ref('')

// Auth-gated route: the query only carries where to come back to, never text.
if (!auth.isLoggedIn) {
  void router.replace({ path: '/auth', query: { return: '/translate' } })
}

// Candidates may be empty (planner sends none today), so fall back to whatever
// the user already picked in the form.
watch(confirmation, (value) => {
  if (!value) return
  confirmationSource.value = value.candidates[0]?.code ?? form.value.sourceLangCode ?? ''
  // The block appears asynchronously; announce it and move focus for keyboard
  // and screen-reader users.
  void nextTick(() => confirmationHeading.value?.focus())
})

const hasActivity = computed(() =>
  Boolean(stage.value || isStreaming.value || error.value || result.value || translation.value),
)

function buildInput(sourceLangCode: string | null): TranslationRequestInput {
  return {
    text: form.value.text,
    source_lang_code: sourceLangCode,
    source_locale_code: null,
    target_locale_code: form.value.targetLocaleCode,
  }
}

function onFormUpdate(value: TranslationFormValue) {
  form.value = value
}

function submit() {
  contributeError.value = ''
  const input = buildInput(form.value.sourceLangCode)
  lastInput.value = input
  void stream.submit(input)
}

function confirmSource() {
  if (!confirmationSource.value) return
  contributeError.value = ''
  form.value = { ...form.value, sourceLangCode: confirmationSource.value }
  const input = buildInput(confirmationSource.value)
  lastInput.value = input
  void stream.submit(input)
}

function retry() {
  if (!lastInput.value) return
  contributeError.value = ''
  void stream.submit(lastInput.value)
}

// Editing keeps the user's text; it only moves focus back to the textarea.
function edit() {
  void nextTick(() => {
    formHost.value?.querySelector<HTMLTextAreaElement>('#translation-text')?.focus()
  })
}

async function sendToContribute() {
  const input = lastInput.value
  const completed = result.value
  if (!input || !completed) return
  contributeError.value = ''
  let targetLangCode: string
  try {
    targetLangCode = (await getLanguageLocale(input.target_locale_code)).lang_code
  } catch {
    // Without a resolved target language code the prefill would be unusable.
    contributeError.value = t('phraseTranslate.sendToContributeFailed')
    return
  }
  prefillStore.set({
    // The exact fast path sends no source_language event, so the result is the
    // authoritative source when detection never streamed one.
    sourceLangCode:
      sourceLanguage.value?.code ?? completed.source_lang_code ?? input.source_lang_code ?? '',
    sourceLocaleCode: '',
    sourceText: input.text,
    targetLangCode,
    targetLocaleCode: input.target_locale_code,
    targetText: completed.translation,
    aiAssisted: completed.resolution === 'assisted',
  })
  await router.push('/contribute')
}
</script>

<template>
  <main v-if="authorized" class="expression-translation">
    <header class="page-head">
      <p class="eyebrow">{{ t('phraseTranslate.eyebrow') }}</p>
      <h1>{{ t('phraseTranslate.title') }}</h1>
      <p class="subtitle">{{ t('phraseTranslate.subtitle') }}</p>
    </header>

    <div ref="formHost" class="form-host">
      <TranslationForm
        :model-value="form"
        :disabled="isStreaming"
        :error="error?.message ?? ''"
        @update:model-value="onFormUpdate"
        @submit="submit"
        @cancel="stream.cancel()"
      />
    </div>

    <section
      v-if="confirmation"
      class="source-confirmation"
      role="status"
      aria-live="polite"
      aria-labelledby="source-confirm-heading"
    >
      <h2
        id="source-confirm-heading"
        ref="confirmationHeading"
        tabindex="-1"
      >
        {{ t('phraseTranslate.sourceConfirmHeading') }}
      </h2>
      <p class="hint">{{ t('phraseTranslate.sourceConfirmHint') }}</p>
      <LanguagePicker
        :model-value="confirmationSource"
        :label="t('phraseTranslate.sourceLanguage')"
        @update:model-value="confirmationSource = $event"
      />
      <button
        type="button"
        class="btn btn-primary confirm-source"
        data-action="confirm-source"
        :disabled="!confirmationSource"
        @click="confirmSource"
      >
        {{ t('phraseTranslate.sourceConfirmSubmit') }}
      </button>
    </section>

    <!-- A stable block keeps streaming deltas from shifting the main layout. -->
    <div class="output-region" :class="{ 'has-activity': hasActivity }">
      <TranslationProgress
        v-if="hasActivity"
        :stage="stage"
        :mode="mode"
        :is-streaming="isStreaming"
        :error="error"
        :source-language="sourceLanguage"
        :evidence="evidence"
        :target-locale-code="form.targetLocaleCode"
        :translation="translation"
        :result="result"
      />

      <TranslationResult
        v-if="translation || result"
        :translation="translation"
        :result="result"
        :alternatives="alternatives"
        @retry="retry"
        @edit="edit"
        @send-to-contribute="sendToContribute"
      />

      <p v-if="contributeError" class="contribute-error" role="alert">{{ contributeError }}</p>

      <EvidenceList
        v-if="evidence"
        :items="evidence.items"
        :omitted-count="evidence.omittedCount"
        :degraded="evidence.degraded"
        :retrieval-status="evidence.retrievalStatus"
      />
    </div>
  </main>
</template>

<style scoped>
.expression-translation {
  display: grid;
  gap: var(--space-md);
  max-width: 920px;
  margin: auto;
  padding: var(--page-pad-top) 24px var(--page-pad-bottom);
  min-width: 0;
}
.page-head {
  min-width: 0;
}
.eyebrow {
  margin: 0 0 4px;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--accent);
}
.page-head h1 {
  margin: 0;
  font-size: 28px;
  font-weight: 700;
  letter-spacing: -0.02em;
}
.subtitle {
  margin: 6px 0 0;
  max-width: 46ch;
  color: var(--muted);
  font-size: var(--text-ui);
}
.form-host,
.output-region,
.source-confirmation {
  min-width: 0;
}
.output-region {
  display: grid;
  gap: 16px;
}
.output-region.has-activity {
  min-height: 240px;
}
.source-confirmation {
  display: grid;
  gap: 10px;
  padding: 14px 16px;
  border: 1px solid var(--border);
  border-left: 3px solid var(--accent);
  border-radius: var(--r);
  background: var(--surface-2);
}
.source-confirmation h2 {
  margin: 0;
  font-size: 16px;
}
.source-confirmation .hint {
  margin: 0;
  color: var(--muted);
  font-size: 13px;
}
.source-confirmation .confirm-source {
  justify-self: start;
  min-height: 44px;
  padding: 0 18px;
}
.source-confirmation h2:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
.contribute-error {
  margin: 0;
  padding: 10px 12px;
  border: 1px solid color-mix(in oklch, var(--down) 40%, var(--border));
  border-radius: var(--r);
  background: var(--surface-2);
  color: var(--down);
  font-size: 13px;
}
@media (max-width: 640px) {
  .expression-translation {
    padding: var(--space-md) 16px var(--page-pad-bottom);
  }
}
</style>
