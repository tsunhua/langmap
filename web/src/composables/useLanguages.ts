import { ref } from 'vue'
import {
  getLanguageDetail,
  listContentLanguages,
  listLanguageExpressions,
  type ContentLanguagePageQuery,
  type LanguageExpressionPageQuery,
  type LocaleHints,
} from '@/api/languageIdentity'
import { apiErrorMessage } from '@/utils/apiError'

export function useLanguages() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function list(params: ContentLanguagePageQuery = {}, signal?: AbortSignal) {
    loading.value = true
    error.value = null
    try {
      return await listContentLanguages(params, signal)
    } catch (cause: unknown) {
      error.value = apiErrorMessage(cause, 'Request failed')
      throw cause
    } finally {
      loading.value = false
    }
  }

  async function detail(code: string, hints: LocaleHints = {}, signal?: AbortSignal) {
    loading.value = true
    error.value = null
    try {
      return await getLanguageDetail(code, hints, signal)
    } catch (cause: unknown) {
      error.value = apiErrorMessage(cause, 'Request failed')
      throw cause
    } finally {
      loading.value = false
    }
  }

  async function expressions(code: string, params: LanguageExpressionPageQuery = {}, signal?: AbortSignal) {
    loading.value = true
    error.value = null
    try {
      return await listLanguageExpressions(code, params, signal)
    } catch (cause: unknown) {
      error.value = apiErrorMessage(cause, 'Request failed')
      throw cause
    } finally {
      loading.value = false
    }
  }

  return { loading, error, list, detail, expressions }
}
