<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { previewLanguageLocaleCode, type LanguageLocalePreviewInput } from '@/utils/languageLocale'

const props = defineProps<{ input: LanguageLocalePreviewInput }>()
const { t } = useI18n()
const code = computed(() => {
  try { return previewLanguageLocaleCode(props.input) } catch { return '' }
})
</script>

<template><output class="locale-preview" aria-live="polite">{{ code || t('localeCreate.codePreviewEmpty') }}</output></template>
<style scoped>.locale-preview { display: block; min-height: 44px; padding: 12px; box-sizing: border-box; border: 1px dashed var(--border); border-radius: var(--r); font-family: var(--mono); font-size: 13px; color: var(--muted); }</style>
