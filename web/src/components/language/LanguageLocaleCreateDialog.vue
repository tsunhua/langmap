<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { X } from 'lucide-vue-next'
import { createLanguageLocale, listRegions, listScripts, type Region, type LanguageLocale, type Script } from '@/api/languageIdentity'
import LanguageLocaleCodePreview from './LanguageLocaleCodePreview.vue'

const props = defineProps<{ open: boolean; langCode?: string | undefined }>()
const emit = defineEmits<{ close: []; created: [locale: LanguageLocale] }>()
const form = reactive({ lang_code: props.langCode ?? '', script_code: '', region_code: '', place: '', name: '', name_en: '', latitude: '', longitude: '' })
const error = reactive({ message: '' })
const scripts = ref<Script[]>([])
const regions = ref<Region[]>([])
const places = computed(() => form.place.split('_').map((value) => value.trim()).filter(Boolean))
watch(() => props.langCode, (value) => { if (value) form.lang_code = value })
watch(() => props.open, (isOpen) => { if (isOpen) error.message = '' })
watch(() => form.script_code, async (value) => {
  try { scripts.value = value ? (await listScripts(value)).items : [] } catch { scripts.value = [] }
})
watch(() => form.region_code, async (value) => {
  try { regions.value = value ? (await listRegions(value)).items : [] } catch { regions.value = [] }
})

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
  } catch (cause) { error.message = cause instanceof Error ? cause.message : 'Unable to create language locale' }
}
</script>

<template>
  <Teleport to="body"><div v-if="open" class="dialog-backdrop" @mousedown.self="emit('close')"><section role="dialog" aria-modal="true" aria-label="Create language locale" class="locale-dialog"><header><h2>Create Language Locale</h2><button type="button" aria-label="Close" @click="emit('close')"><X :size="18" /></button></header><form @submit.prevent="submit"><label>Language <input v-model="form.lang_code" name="lang_code" required pattern="[a-z]{3}" placeholder="ISO 639-3 code"></label><label>Script <input v-model="form.script_code" name="script_code" required pattern="[A-Z][a-z]{3}" list="locale-scripts" placeholder="ISO 15924 code"><datalist id="locale-scripts"><option v-for="script in scripts" :key="script.code" :value="script.code">{{ script.name_en }}</option></datalist></label><label>Region <input v-model="form.region_code" name="region_code" required pattern="[A-Z]{2}" list="locale-regions" placeholder="ISO 3166-1 code"><datalist id="locale-regions"><option v-for="region in regions" :key="region.code" :value="region.code">{{ region.name_en }}</option></datalist></label><label>Place segments <input v-model="form.place" name="place_segments" placeholder="Quanzhou_Nanan"></label><LanguageLocaleCodePreview :input="{ lang_code: form.lang_code, script_code: form.script_code, region_code: form.region_code, place_segments: places }" /><label>Local name <input v-model="form.name" name="name" required></label><label>English name <input v-model="form.name_en" name="name_en" required></label><div class="coordinates"><label>Latitude <input v-model="form.latitude" name="latitude" inputmode="decimal"></label><label>Longitude <input v-model="form.longitude" name="longitude" inputmode="decimal"></label></div><p v-if="error.message" role="alert">{{ error.message }}</p><button type="submit" class="btn btn-primary">Create locale</button></form></section></div></Teleport>
</template>

<style scoped>
.dialog-backdrop { position: fixed; inset: 0; z-index: 100; display: grid; place-items: center; padding: 16px; background: oklch(0 0 0 / .35); }.locale-dialog { width: min(100%, 560px); max-height: calc(100vh - 32px); overflow: auto; padding: 18px; border-radius: var(--r); background: var(--surface); }.locale-dialog header { display: flex; align-items: center; justify-content: space-between; gap: 12px; }.locale-dialog header button { min-width: 44px; min-height: 44px; border: 0; background: transparent; }.locale-dialog form { display: grid; gap: 12px; }.locale-dialog label { display: grid; gap: 5px; font-size: 13px; color: var(--muted); }.locale-dialog input { min-height: 44px; box-sizing: border-box; padding: 8px 10px; border: 1px solid var(--border); border-radius: var(--r); background: var(--surface); color: var(--fg); }.coordinates { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
</style>
