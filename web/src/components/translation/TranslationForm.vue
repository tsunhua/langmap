<script setup lang="ts">
import { computed, nextTick, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import LanguagePicker from '@/components/language/LanguagePicker.vue'
import LanguageLocalePicker from '@/components/language/LanguageLocalePicker.vue'
import {
  MAX_TRANSLATION_GRAPHEMES,
  MAX_TRANSLATION_TEXT_BYTES,
  countGraphemes,
  utf8ByteLength,
} from '@/utils/graphemes'

export interface TranslationFormValue {
  sourceLangCode: string | null
  targetLocaleCode: string
  text: string
}

const props = withDefaults(defineProps<{
  modelValue: TranslationFormValue
  disabled?: boolean
}>(), { disabled: false })

const emit = defineEmits<{
  'update:modelValue': [value: TranslationFormValue]
  submit: []
}>()

const { t } = useI18n()
const summary = ref<HTMLElement>()
const submitAttempted = ref(false)

const sourceErrorId = 'translation-source-error'
const targetErrorId = 'translation-target-error'
const textErrorId = 'translation-text-error'

function update(patch: Partial<TranslationFormValue>) {
  emit('update:modelValue', { ...props.modelValue, ...patch })
}

const sourceLang = computed(() => props.modelValue.sourceLangCode ?? '')
const targetLocale = computed(() => props.modelValue.targetLocaleCode)
const graphemeCount = computed(() => countGraphemes(props.modelValue.text))
const byteLength = computed(() => utf8ByteLength(props.modelValue.text))
const sourceEmpty = computed(() => !sourceLang.value.trim())
const targetEmpty = computed(() => !targetLocale.value.trim())
const textEmpty = computed(() => props.modelValue.text.trim().length === 0)
const textTooLong = computed(() =>
  graphemeCount.value > MAX_TRANSLATION_GRAPHEMES || byteLength.value > MAX_TRANSLATION_TEXT_BYTES,
)
const invalid = computed(() => sourceEmpty.value || targetEmpty.value || textEmpty.value || textTooLong.value)
const canSubmit = computed(() => !props.disabled)
const showSummary = computed(() => submitAttempted.value && invalid.value)
const showSourceError = computed(() => submitAttempted.value && sourceEmpty.value)
const showTargetError = computed(() => submitAttempted.value && targetEmpty.value)
const showTextError = computed(() =>
  textTooLong.value || (textEmpty.value && submitAttempted.value),
)
const textDescribedBy = computed(() =>
  showTextError.value ? `translation-text-count ${textErrorId}` : 'translation-text-count',
)

function onText(value: string) {
  update({ text: value })
}

function onSourceLang(value: string) {
  update({ sourceLangCode: value || null })
}

function onTargetLocale(value: string) {
  update({ targetLocaleCode: value })
}

function focusSummary() {
  void nextTick(() => summary.value?.focus())
}

function onSubmit() {
  if (invalid.value) {
    submitAttempted.value = true
    focusSummary()
    return
  }
  emit('submit')
}
</script>

<template>
  <form class="translation-form" novalidate @submit.prevent="onSubmit">
    <p v-if="showSummary" ref="summary" class="form-summary" role="alert" tabindex="-1">
      {{ t('phraseTranslate.validationSummary') }}
    </p>

    <div class="language-fields">
      <div class="field">
        <LanguagePicker
          :model-value="sourceLang"
          :label="t('phraseTranslate.sourceLanguage')"
          :placeholder="t('phraseTranslate.sourceLanguagePlaceholder')"
          variant="search"
          :invalid="showSourceError"
          :described-by="showSourceError ? sourceErrorId : undefined"
          @update:model-value="onSourceLang"
        />
        <p v-if="showSourceError" :id="sourceErrorId" class="field-error">
          {{ t('phraseTranslate.sourceRequired') }}
        </p>
      </div>

      <div class="field">
        <LanguageLocalePicker
          :model-value="targetLocale"
          :label="t('phraseTranslate.targetLocale')"
          :placeholder="t('phraseTranslate.targetLocalePlaceholder')"
          variant="search"
          :allow-create="false"
          :invalid="showTargetError"
          :described-by="showTargetError ? targetErrorId : undefined"
          @update:model-value="onTargetLocale"
        />
        <p v-if="showTargetError" :id="targetErrorId" class="field-error">
          {{ t('phraseTranslate.errorTargetLocale') }}
        </p>
      </div>
    </div>

    <div class="field text-field">
      <label for="translation-text" class="field-label">{{ t('phraseTranslate.text') }}</label>
      <textarea
        id="translation-text"
        class="text-input"
        :value="props.modelValue.text"
        :placeholder="t('phraseTranslate.textPlaceholder')"
        dir="auto"
        :aria-invalid="showTextError"
        :aria-describedby="textDescribedBy"
        @input="onText(($event.target as HTMLTextAreaElement).value)"
      />
      <div class="text-meta">
        <p id="translation-text-count" class="grapheme-count" :class="{ over: textTooLong }">
          {{ t('phraseTranslate.graphemeCount', { count: graphemeCount, max: MAX_TRANSLATION_GRAPHEMES }) }}
        </p>
        <p
          v-if="textTooLong"
          :id="textErrorId"
          class="field-error"
          role="status"
          aria-live="polite"
        >
          {{ t('phraseTranslate.errorValidation') }}
        </p>
        <p v-else-if="showTextError" :id="textErrorId" class="field-error">
          {{ t('phraseTranslate.errorValidation') }}
        </p>
      </div>
    </div>

    <button
      type="submit"
      class="btn btn-primary translate-submit"
      :disabled="!canSubmit"
      data-action="submit"
    >
      {{ t('phraseTranslate.submit') }}
    </button>
  </form>
</template>

<style scoped>
.translation-form {
  display: grid;
  gap: 16px;
  min-width: 0;
}
.form-summary {
  margin: 0;
  padding: 10px 12px;
  border: 1px solid color-mix(in oklch, var(--down) 40%, var(--border));
  border-radius: var(--r);
  background: var(--surface-2);
  color: var(--down);
  font-size: 13px;
}
.form-summary:focus {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
.language-fields {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
  min-width: 0;
}
.field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 0;
}
.field-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--muted);
}
.text-input {
  box-sizing: border-box;
  width: 100%;
  min-height: 152px;
  padding: 12px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  color: var(--fg);
  font-family: var(--font);
  font-size: var(--text-body);
  line-height: 1.5;
  resize: vertical;
}
.text-input:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent);
}
.text-input[aria-invalid="true"] {
  border-color: var(--down);
}
.translation-form :deep(.identity-picker input),
.translation-form :deep(.identity-picker .picker-selected),
.translation-form :deep(.locale-picker .input-wrap input),
.translation-form :deep(.locale-picker .selected) {
  background: var(--surface);
}
.text-meta {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
  min-width: 0;
}
.grapheme-count {
  margin: 0;
  font-family: var(--mono);
  font-size: var(--text-meta);
  color: var(--muted);
}
.grapheme-count.over {
  color: var(--down);
}
.field-error {
  margin: 0;
  color: var(--down);
  font-size: 12px;
}
.translate-submit {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  justify-self: end;
  min-width: 168px;
  min-height: 48px;
  padding: 0 18px;
}
@media (max-width: 640px) {
  .language-fields {
    grid-template-columns: minmax(0, 1fr);
  }
  .translate-submit {
    width: 100%;
  }
}
</style>
