<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { X } from 'lucide-vue-next'
import { useI18n } from 'vue-i18n'
import { createLanguageLocale, listRegions, listScripts, type LanguageLocale } from '@/api/languageIdentity'
import AutocompleteInput from '@/components/ui/AutocompleteInput.vue'
import { useLocaleParams } from '@/composables/useLocaleParams'
import LanguageLocaleCodePreview from './LanguageLocaleCodePreview.vue'

const props = defineProps<{ open: boolean; langCode?: string | undefined }>()
const emit = defineEmits<{ close: []; created: [locale: LanguageLocale] }>()
const { t } = useI18n()
const localeParams = useLocaleParams()
const form = reactive({ lang_code: props.langCode ?? '', script_code: '', region_code: '', place: '', name: '', name_en: '', latitude: '', longitude: '' })
const error = reactive({ message: '' })
const places = computed(() => form.place.split('_').map((value) => value.trim()).filter(Boolean))
watch(() => props.langCode, (value) => { if (value) form.lang_code = value })
watch(() => props.open, (isOpen) => { if (isOpen) error.message = '' })

async function searchScripts(query: string) {
  const items = await listScripts(query, 20, 0, localeParams.value)
  return items.items.map((item) => ({ code: item.code, label: item.name ?? item.name_en }))
}

async function searchRegions(query: string) {
  const items = await listRegions(query, 20, 0, localeParams.value)
  return items.items.map((item) => ({ code: item.code, label: item.name ?? item.name_en }))
}

async function submit() {
  error.message = ''
  try {
    const input = {
      lang_code: form.lang_code, script_code: form.script_code, region_code: form.region_code,
      place_segments: places.value, name: form.name, name_en: form.name_en,
      ...(form.latitude && form.longitude ? { latitude: Number(form.latitude), longitude: Number(form.longitude) } : {}),
    }
    const locale = await createLanguageLocale(input)
    emit('created', locale)
    emit('close')
  } catch (cause) { error.message = cause instanceof Error ? cause.message : t('localeCreate.createFailed') }
}
</script>

<template>
  <Teleport to="body"><div v-if="open" class="dialog-backdrop" @mousedown.self="emit('close')"><section role="dialog" aria-modal="true" :aria-label="t('localeCreate.heading')" class="locale-dialog"><header><h2>{{ t('localeCreate.heading') }}</h2><button type="button" :aria-label="t('common.close')" @click="emit('close')"><X :size="18" /></button></header><form @submit.prevent="submit"><label>{{ t('common.language') }} <input v-model="form.lang_code" name="lang_code" required pattern="[a-z]{3}" placeholder="ISO 639-3 code"></label><AutocompleteInput v-model="form.script_code" name="script_code" :label="t('localeCreate.script')" required pattern="[A-Z][a-z]{3}" :placeholder="t('localeCreate.scriptPlaceholder')" :search="searchScripts" /><AutocompleteInput v-model="form.region_code" name="region_code" :label="t('localeCreate.region')" required pattern="[A-Z]{2}" :placeholder="t('localeCreate.regionPlaceholder')" :search="searchRegions" /><label>{{ t('localeCreate.place') }} <input v-model="form.place" name="place_segments" :placeholder="t('localeCreate.placePlaceholder')"></label><LanguageLocaleCodePreview :input="{ lang_code: form.lang_code, script_code: form.script_code, region_code: form.region_code, place_segments: places }" /><label>{{ t('localeCreate.localName') }} <input v-model="form.name" name="name" required></label><label>{{ t('localeCreate.englishName') }} <input v-model="form.name_en" name="name_en" required></label><div class="coordinates"><label>{{ t('localeCreate.latitude') }} <input v-model="form.latitude" name="latitude" inputmode="decimal"></label><label>{{ t('localeCreate.longitude') }} <input v-model="form.longitude" name="longitude" inputmode="decimal"></label></div><p v-if="error.message" role="alert">{{ error.message }}</p><button type="submit" class="btn btn-primary">{{ t('localeCreate.create') }}</button></form></section></div></Teleport>
</template>

<style scoped>
.dialog-backdrop { position: fixed; inset: 0; z-index: 100; display: grid; place-items: center; padding: 16px; background: oklch(0 0 0 / .35); }.locale-dialog { width: min(100%, 560px); max-height: calc(100vh - 32px); overflow: auto; padding: 18px; border-radius: var(--r); background: var(--surface); }.locale-dialog header { display: flex; align-items: center; justify-content: space-between; gap: 12px; }.locale-dialog header button { min-width: 44px; min-height: 44px; border: 0; background: transparent; }.locale-dialog form { display: grid; gap: 12px; }.locale-dialog label { display: grid; gap: 5px; font-size: 13px; color: var(--muted); }.locale-dialog input { min-height: 44px; box-sizing: border-box; padding: 8px 10px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); color: var(--fg); }.coordinates { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
</style>
