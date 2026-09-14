import { ref } from 'vue'
import { defineStore } from 'pinia'

// A mapping needs both endpoints, so the translate result carries the full pair
// rather than the plan's abbreviated single-row shape.
export interface ContributePrefill {
  sourceLangCode: string
  sourceLocaleCode: string
  sourceText: string
  targetLangCode: string
  targetLocaleCode: string
  targetText: string
  aiAssisted: boolean
}

export const useContributePrefillStore = defineStore('contributePrefill', () => {
  const prefill = ref<ContributePrefill | null>(null)

  function set(value: ContributePrefill) {
    prefill.value = value
  }

  function consume(): ContributePrefill | null {
    const value = prefill.value
    prefill.value = null
    return value
  }

  return { prefill, set, consume }
})
