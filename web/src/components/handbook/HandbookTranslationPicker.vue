<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import LanguageLocalePicker from '@/components/language/LanguageLocalePicker.vue'

defineProps<{ modelValue: string }>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
const { t } = useI18n()
</script>

<template>
  <div class="handbook-translation-picker">
    <LanguageLocalePicker
      :model-value="modelValue"
      :label="t('handbook.translationLanguage')"
      :placeholder="t('handbook.translationLocalePlaceholder')"
      :allow-create="false"
      @update:model-value="emit('update:modelValue', $event)"
    />
  </div>
</template>

<style scoped>
.handbook-translation-picker {
  max-width: 260px;
  min-width: 0;
}
.handbook-translation-picker :deep(.locale-picker) {
  flex-direction: row;
  align-items: center;
  gap: 10px;
}
.handbook-translation-picker :deep(.locale-picker > label) {
  flex: none;
  color: var(--muted);
  font-size: 12px;
  font-weight: 400;
  letter-spacing: normal;
  text-transform: none;
}
.handbook-translation-picker :deep(.input-wrap) { flex: 1; }
.handbook-translation-picker :deep(.input-wrap input) { min-height: 40px; }

@media (max-width: 480px) {
  .handbook-translation-picker {
    max-width: none;
  }
}
</style>
