import { defineStore } from 'pinia'
import { ref } from 'vue'
import { listLanguages, type Language } from '@/api/languageIdentity'

export const useLanguagesStore = defineStore('languages', () => {
  const languages = ref<Language[]>([])
  const loaded = ref(false)

  async function fetchLanguages() {
    if (loaded.value) return
    languages.value = (await listLanguages('', 50)).items
    loaded.value = true
  }

  function upsertLanguage(language: Language) {
    const index = languages.value.findIndex(item => item.code === language.code)
    if (index >= 0) languages.value[index] = language
    else languages.value.push(language)
    languages.value.sort((a, b) => a.name_en.localeCompare(b.name_en) || a.code.localeCompare(b.code))
  }

  function getName(code: string): string {
    return languages.value.find(l => l.code === code)?.name_en || code
  }

  return { languages, loaded, fetchLanguages, upsertLanguage, getName }
})
