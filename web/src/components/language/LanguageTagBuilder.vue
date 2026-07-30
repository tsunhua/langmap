<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import LanguageSubtagSelect from './LanguageSubtagSelect.vue'
import type { LanguageSubtags, RegistrySubtag } from '@/api/languages'

const { t } = useI18n()

const props = defineProps<{
  modelValue: LanguageSubtags
}>()

const emit = defineEmits<{
  'update:modelValue': [value: LanguageSubtags]
  validityChange: [valid: boolean]
}>()

const statusMessage = ref('')

function emitUpdate(subtags: LanguageSubtags) {
  emit('update:modelValue', subtags)
  emit('validityChange', subtags.language.length > 0)
}

function updateLanguage(value: string) {
  const prev = props.modelValue.language
  const next = value || ''
  if (prev && next !== prev && props.modelValue.variants.length > 0) {
    const count = props.modelValue.variants.length
    emitUpdate({
      ...props.modelValue,
      language: next,
      variants: [],
    })
    statusMessage.value =
      count === 1
        ? t('languageCreate.variantRemoved')
        : t('languageCreate.variantsRemoved', { count })
  } else {
    emitUpdate({ ...props.modelValue, language: next })
  }
}

function updateScript(value: string) {
  emitUpdate({ ...props.modelValue, script: value || null })
}

function updateRegion(value: string) {
  emitUpdate({ ...props.modelValue, region: value || null })
}

function removeVariant(variant: string) {
  emitUpdate({
    ...props.modelValue,
    variants: props.modelValue.variants.filter(v => v !== variant),
  })
}

function handleVariantSelect(subtag: RegistrySubtag) {
  if (subtag.type === 'variant' && !props.modelValue.variants.includes(subtag.subtag)) {
    emitUpdate({
      ...props.modelValue,
      variants: [...props.modelValue.variants, subtag.subtag],
    })
  }
}

const previewCode = ref('')
watch(
  () => props.modelValue,
  (val) => {
    const parts: string[] = []
    if (val.language) parts.push(val.language)
    if (val.script) parts.push(val.script)
    if (val.region) parts.push(val.region)
    if (val.variants.length) parts.push(val.variants.join('-'))
    previewCode.value = parts.join('-')
  },
  { immediate: true, deep: true },
)
</script>

<template>
  <div class="tag-builder">
    <p class="required-hint">{{ t('languageCreate.requiredHint') }}</p>

    <div data-field="language">
      <LanguageSubtagSelect
        :label="t('languageCreate.subtagLanguage')"
        :model-value="modelValue.language"
        type="language"
        :placeholder="t('languageCreate.subtagSearch')"
        required
        @update:model-value="updateLanguage"
      />
    </div>

    <div data-field="script">
      <LanguageSubtagSelect
        :label="t('languageCreate.subtagScript')"
        :model-value="modelValue.script || ''"
        type="script"
        :placeholder="t('languageCreate.subtagSearch')"
        optional
        @update:model-value="updateScript"
      />
    </div>

    <div data-field="region">
      <LanguageSubtagSelect
        :label="t('languageCreate.subtagRegion')"
        :model-value="modelValue.region || ''"
        type="region"
        :placeholder="t('languageCreate.subtagSearch')"
        optional
        @update:model-value="updateRegion"
      />
    </div>

    <div data-field="variants">
      <label class="subtag-label">
        {{ t('languageCreate.subtagVariant') }}
        <span class="field-optional">({{ t('languageCreate.optional') }})</span>
      </label>
      <div class="variant-tags" v-if="modelValue.variants.length">
        <span v-for="v in modelValue.variants" :key="v" class="variant-tag">
          {{ v }}
          <button
            type="button"
            :aria-label="`Remove ${v}`"
            class="variant-remove"
            @click="removeVariant(v)"
          >&times;</button>
        </span>
      </div>
      <LanguageSubtagSelect
        :label="t('languageCreate.subtagVariant')"
        model-value=""
        type="variant"
        :prefix="modelValue.language || undefined"
        :placeholder="t('languageCreate.subtagSearch')"
        hide-label
        @select="handleVariantSelect"
      />
    </div>

    <div class="preview">
      <span class="preview-label">{{ t('languageCreate.provisionalTag') }}:</span>
      <code class="preview-code">{{ previewCode || '—' }}</code>
    </div>

    <div role="status" class="sr-only" aria-live="polite">
      {{ statusMessage }}
    </div>
  </div>
</template>

<style scoped>
.tag-builder {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.required-hint {
  margin: 0;
  color: var(--muted);
  font-size: 11px;
  text-align: right;
}
.subtag-label {
  display: block;
  font-size: 12px;
  font-weight: 500;
  color: var(--muted);
  margin-bottom: 4px;
}
.field-optional {
  color: var(--faint);
  font-weight: 400;
}
.variant-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-bottom: 8px;
}
.variant-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius: 999px;
  background: var(--accent-soft);
  color: var(--accent);
  font-family: var(--mono);
  font-size: 11px;
}
.variant-remove {
  border: none;
  background: none;
  cursor: pointer;
  font-size: 14px;
  color: var(--accent);
  padding: 0;
  line-height: 1;
}
.preview {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  background: var(--surface-2);
  border-radius: var(--r);
  font-size: 13px;
}
.preview-label {
  color: var(--muted);
  font-size: 11px;
}
.preview-code {
  font-family: var(--mono);
  font-size: 13px;
  color: var(--fg);
}
.sr-only {
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
</style>
