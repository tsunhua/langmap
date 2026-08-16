import { defineStore } from 'pinia'
import { ref } from 'vue'
import { listLanguages, type Language, type LocaleHints } from '@/api/languageIdentity'

export const useLanguagesStore = defineStore('languages', () => {
  const languages = ref<Language[]>([])
  const loaded = ref(false)
  const loadedFor = ref<string>()

  async function fetchLanguages(hints: LocaleHints = {}) {
    const key = hints.ui_locale ?? ''
    if (loaded.value && loadedFor.value === key) return
    languages.value = (await listLanguages('', 50, 0, hints)).items
    loaded.value = true
    loadedFor.value = key
  }

  function upsertLanguage(language: Language) {
    const index = languages.value.findIndex(item => item.code === language.code)
    if (index >= 0) languages.value[index] = language
    else languages.value.push(language)
    languages.value.sort((a, b) => a.name_en.localeCompare(b.name_en) || a.code.localeCompare(b.code))
  }

  function getName(code: string): string {
    const language = languages.value.find(l => l.code === code)
    return language?.name || language?.name_en || code
  }

  return { languages, loaded, fetchLanguages, upsertLanguage, getName }
})
