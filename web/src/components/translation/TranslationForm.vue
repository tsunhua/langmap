<script setup lang="ts">
import { computed, nextTick, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { Wand2 } from 'lucide-vue-next'
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
  error?: string
}>(), { disabled: false, error: '' })

const emit = defineEmits<{
  'update:modelValue': [value: TranslationFormValue]
  submit: []
  cancel: []
}>()

const { t } = useI18n()

const summary = ref<HTMLElement>()
// Dirtiness gates the error summary so an untouched empty form stays quiet.
const dirty = ref(false)

function update(patch: Partial<TranslationFormValue>) {
  dirty.value = true
  emit('update:modelValue', { ...props.modelValue, ...patch })
}

const sourceLang = computed(() => props.modelValue.sourceLangCode ?? '')
const targetLocale = computed(() => props.modelValue.targetLocaleCode)
const graphemeCount = computed(() => countGraphemes(props.modelValue.text))
const byteLength = computed(() => utf8ByteLength(props.modelValue.text))

const textEmpty = computed(() => props.modelValue.text.trim().length === 0)
const textTooLong = computed(() =>
  graphemeCount.value > MAX_TRANSLATION_GRAPHEMES || byteLength.value > MAX_TRANSLATION_TEXT_BYTES,
)
const targetEmpty = computed(() => targetLocale.value.trim().length === 0)
const isAutoDetect = computed(() => sourceLang.value === '')

const textInvalid = computed(() => textEmpty.value || textTooLong.value)
const canSubmit = computed(() => !props.disabled && !textInvalid.value && !targetEmpty.value)

const showSummary = computed(() =>
  Boolean(props.error) || (dirty.value && (textInvalid.value || targetEmpty.value)),
)

function onText(value: string) {
  update({ text: value })
}

function onSourceLang(value: string) {
  update({ sourceLangCode: value === '' ? null : value })
}

function onTargetLocale(value: string) {
  update({ targetLocaleCode: value })
}

function focusSummary() {
  void nextTick(() => summary.value?.focus())
}

function onSubmit() {
  if (!canSubmit.value) {
    dirty.value = true
    focusSummary()
    return
  }
  emit('submit')
}
</script>

<template>
  <form class="translation-form" novalidate @submit.prevent="onSubmit">
    <p v-if="showSummary" ref="summary" class="form-summary" role="alert" tabindex="-1">
      {{ props.error || t('phraseTranslate.validationSummary') }}
    </p>

    <div class="language-controls">
      <div class="field source-field">
        <LanguagePicker
          :model-value="sourceLang"
          :label="t('phraseTranslate.sourceLanguage')"
          @update:model-value="onSourceLang"
        />
        <button
          type="button"
          class="btn btn-ghost auto-detect"
          :aria-pressed="isAutoDetect"
          data-action="source-auto"
          @click="onSourceLang('')"
        >
          <Wand2 :size="16" aria-hidden="true" />
          {{ t('phraseTranslate.sourceAuto') }}
        </button>
      </div>

      <div class="field target-field">
        <LanguageLocalePicker
          :model-value="targetLocale"
          :label="t('phraseTranslate.targetLocale')"
          :placeholder="t('phraseTranslate.targetLocalePlaceholder')"
          :allow-create="false"
          @update:model-value="onTargetLocale"
        />
        <p v-if="dirty && targetEmpty" class="field-error" role="alert">
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
        :aria-invalid="textInvalid"
        aria-describedby="translation-text-count"
        @input="onText(($event.target as HTMLTextAreaElement).value)"
      />
      <div class="text-meta">
        <p
          id="translation-text-count"
          class="grapheme-count"
          :class="{ over: textTooLong }"
          aria-live="polite"
        >
          {{ t('phraseTranslate.graphemeCount', { count: graphemeCount, max: MAX_TRANSLATION_GRAPHEMES }) }}
        </p>
        <p v-if="dirty && textInvalid" class="field-error" role="alert">
          {{ t('phraseTranslate.errorValidation') }}
        </p>
      </div>
    </div>

    <div class="actions">
      <button
        v-if="!disabled"
        type="submit"
        class="btn btn-primary"
        :disabled="!canSubmit"
        data-action="submit"
      >
        {{ t('phraseTranslate.submit') }}
      </button>
      <button v-else type="button" class="btn" data-action="cancel" @click="emit('cancel')">
        {{ t('phraseTranslate.cancel') }}
      </button>
    </div>
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
.language-controls {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
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
.auto-detect {
  align-self: flex-start;
  min-height: 44px;
}
.auto-detect[aria-pressed="true"] {
  border-color: var(--accent);
  color: var(--accent);
}
.text-input {
  box-sizing: border-box;
  width: 100%;
  min-height: 96px;
  padding: 10px 12px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  background: var(--surface);
  color: var(--fg);
  font-family: var(--font);
  font-size: var(--text-body);
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
.actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}
.actions .btn {
  min-height: 44px;
  padding: 0 18px;
}
@media (min-width: 720px) {
  .language-controls {
    grid-template-columns: minmax(0, 1fr) minmax(0, 1fr);
  }
}
</style>
