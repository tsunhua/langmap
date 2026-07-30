<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n()

const props = defineProps<{
  name: string
  nameEn: string | null
  description: string
  reason: 'missing_from_glottolog' | 'community_specific' | 'emerging_variety' | 'other' | null
  glottocode: string | null
  errors: Record<string, string>
}>()

const emit = defineEmits<{
  'update:name': [value: string]
  'update:nameEn': [value: string | null]
  'update:description': [value: string]
  'update:reason': [value: 'missing_from_glottolog' | 'community_specific' | 'emerging_variety' | 'other' | null]
}>()

const reasons = [
  { value: 'missing_from_glottolog', labelKey: 'languageCreate.metadataReasonMissing' },
  { value: 'community_specific', labelKey: 'languageCreate.metadataReasonCommunity' },
  { value: 'emerging_variety', labelKey: 'languageCreate.metadataReasonEmerging' },
  { value: 'other', labelKey: 'languageCreate.metadataReasonOther' },
] as const
</script>

<template>
  <form class="metadata-form" @submit.prevent>
    <p class="required-hint">{{ t('languageCreate.requiredHint') }}</p>

    <div class="form-field">
      <label for="meta-name" class="field-label">{{ t('languageCreate.metadataName') }} *</label>
      <input
        id="meta-name"
        type="text"
        :value="name"
        class="field-input"
        required
        :aria-invalid="!!errors.name"
        :aria-describedby="errors.name ? 'meta-name-error' : undefined"
        @input="emit('update:name', ($event.target as HTMLInputElement).value)"
      />
      <p v-if="errors.name" id="meta-name-error" class="field-error" role="alert">
        {{ errors.name }}
      </p>
    </div>

    <div class="form-field">
      <label for="meta-name-en" class="field-label">
        {{ t('languageCreate.metadataNameEn') }}
        <span class="field-optional">({{ t('languageCreate.optional') }})</span>
      </label>
      <input
        id="meta-name-en"
        type="text"
        :value="nameEn || ''"
        class="field-input"
        @input="emit('update:nameEn', ($event.target as HTMLInputElement).value || null)"
      />
    </div>

    <div class="form-field">
      <label for="meta-desc" class="field-label">{{ t('languageCreate.metadataDescription') }} *</label>
      <textarea
        id="meta-desc"
        :value="description"
        rows="3"
        class="field-input field-textarea"
        required
        :aria-invalid="!!errors.description"
        :aria-describedby="errors.description ? 'meta-desc-error' : undefined"
        @input="emit('update:description', ($event.target as HTMLTextAreaElement).value)"
      />
      <p v-if="errors.description" id="meta-desc-error" class="field-error" role="alert">
        {{ errors.description }}
      </p>
    </div>

    <div v-if="glottocode === null" class="form-field">
      <label for="meta-reason" class="field-label">{{ t('languageCreate.metadataReason') }} *</label>
      <select
        id="meta-reason"
        :value="reason || ''"
        class="field-input"
        required
        :aria-invalid="!!errors.reason"
        :aria-describedby="errors.reason ? 'meta-reason-error' : undefined"
        @change="emit('update:reason', ($event.target as HTMLSelectElement).value as typeof reason || null)"
      >
        <option value="" disabled>{{ t('languageCreate.metadataReasonPlaceholder') }}</option>
        <option v-for="r in reasons" :key="r.value" :value="r.value">
          {{ t(r.labelKey) }}
        </option>
      </select>
      <p v-if="errors.reason" id="meta-reason-error" class="field-error" role="alert">
        {{ errors.reason }}
      </p>
    </div>
  </form>
</template>

<style scoped>
.metadata-form {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.required-hint {
  margin: 0;
  color: var(--muted);
  font-size: 11px;
  text-align: right;
}
.form-field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.field-label {
  font-size: 12px;
  font-weight: 500;
  color: var(--muted);
}
.field-optional {
  color: var(--faint);
  font-weight: 400;
}
.field-input {
  width: 100%;
  min-height: 44px;
  padding: 8px 10px;
  border: 1px solid var(--border);
  border-radius: var(--r);
  font-size: 14px;
  background: var(--surface);
  color: var(--fg);
  box-sizing: border-box;
}
.field-input:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 2px color-mix(in oklch, var(--accent) 22%, transparent);
}
.field-input[aria-invalid="true"] {
  border-color: var(--down);
}
.field-textarea {
  min-height: 80px;
  resize: vertical;
  font-family: var(--font);
}
.field-error {
  font-size: 11px;
  color: var(--down);
}
</style>
