import { defineStore } from 'pinia'
import { ref } from 'vue'
import { listRegistryLanguages } from '@/api/languages'
import type { RegistryLanguage } from '@/api/languages'

export const useLanguagesStore = defineStore('languages', () => {
  const languages = ref<RegistryLanguage[]>([])
  const loaded = ref(false)

  async function fetchLanguages() {
    if (loaded.value) return
    languages.value = await listRegistryLanguages()
    loaded.value = true
  }

  function upsertLanguage(language: RegistryLanguage) {
    const index = languages.value.findIndex(item => item.code === language.code)
    if (index >= 0) languages.value[index] = language
    else languages.value.push(language)
    languages.value.sort((a, b) => a.name.localeCompare(b.name) || a.code.localeCompare(b.code))
  }

  function getName(code: string): string {
    return languages.value.find(l => l.code === code)?.name || code
  }

  return { languages, loaded, fetchLanguages, upsertLanguage, getName }
})
