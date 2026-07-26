import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '@/api/client'

interface Language {
  code: string
  name: string
  expression_count: number
}

export const useLanguagesStore = defineStore('languages', () => {
  const languages = ref<Language[]>([])
  const loaded = ref(false)

  async function fetchLanguages() {
    if (loaded.value) return
    const { data } = await api.get('/languages')
    languages.value = data.data
    loaded.value = true
  }

  function getName(code: string): string {
    return languages.value.find(l => l.code === code)?.name || code
  }

  return { languages, loaded, fetchLanguages, getName }
})
