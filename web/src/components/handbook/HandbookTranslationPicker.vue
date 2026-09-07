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
      :allow-create="false"
      @update:model-value="emit('update:modelValue', $event)"
    />
  </div>
</template>

<style scoped>
.handbook-translation-picker { min-width: min(300px, 100%); }
.handbook-translation-picker :deep(.locale-picker > label) { font-size: 10px; letter-spacing: 0.04em; text-transform: uppercase; }
</style>
