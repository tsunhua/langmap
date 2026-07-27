import { ref, reactive } from 'vue'
import {
  listLanguageSubtags,
  searchLanguoids as apiSearchLanguoids,
  previewLanguage as apiPreviewLanguage,
  createLanguage as apiCreateLanguage,
} from '@/api/languages'
import type {
  LanguageSubtags,
  RegistrySubtag,
  LanguoidCandidate,
  LanguagePreview,
  CreateLanguagePayload,
  CreatedLanguage,
} from '@/api/languages'

export function useLanguageCreation() {
  const step = ref<1 | 2 | 3 | 4>(1)

  const subtags = ref<LanguageSubtags>({
    language: '',
    script: null,
    region: null,
    variants: [],
    private_use: [],
  })

  const glottocode = ref<string | null>(null)

  const metadata = reactive({
    name: '',
    name_en: null as string | null,
    description: '',
    reason: null as CreateLanguagePayload['language']['reason'],
    alternate_names: [] as string[],
    references: [] as string[],
    parent_languoid_id: null as string | null,
    latitude: null as number | null,
    longitude: null as number | null,
  })

  const subtagOptions = ref<RegistrySubtag[]>([])
  const languoidOptions = ref<LanguoidCandidate[]>([])

  const loadingSubtags = ref(false)
  const loadingLanguoids = ref(false)
  const loadingPreview = ref(false)
  const loadingSubmit = ref(false)

  const errorSubtags = ref<string | null>(null)
  const errorLanguoids = ref<string | null>(null)
  const errorPreview = ref<string | null>(null)
  const errorSubmit = ref<string | null>(null)

  const preview = ref<LanguagePreview | null>(null)

  let subtagRequestId = 0
  let subtagController: AbortController | null = null

  let languoidRequestId = 0
  let languoidController: AbortController | null = null

  async function searchSubtags(type: string, query: string, prefix?: string): Promise<void> {
    subtagController?.abort()
    const requestId = ++subtagRequestId
    subtagController = new AbortController()

    loadingSubtags.value = true
    errorSubtags.value = null
    try {
      const items = await listLanguageSubtags(type, query, prefix, subtagController.signal)
      if (requestId === subtagRequestId) {
        subtagOptions.value = items
      }
    } catch (e: unknown) {
      if (requestId === subtagRequestId && !isAbortError(e)) {
        errorSubtags.value = (e as Error).message || 'Subtag search failed'
      }
    } finally {
      if (requestId === subtagRequestId) {
        loadingSubtags.value = false
      }
    }
  }

  async function searchLanguoids(query: string): Promise<void> {
    languoidController?.abort()
    const requestId = ++languoidRequestId
    languoidController = new AbortController()

    loadingLanguoids.value = true
    errorLanguoids.value = null
    try {
      const items = await apiSearchLanguoids(query, languoidController.signal)
      if (requestId === languoidRequestId) {
        languoidOptions.value = items
      }
    } catch (e: unknown) {
      if (requestId === languoidRequestId && !isAbortError(e)) {
        errorLanguoids.value = (e as Error).message || 'Languoid search failed'
      }
    } finally {
      if (requestId === languoidRequestId) {
        loadingLanguoids.value = false
      }
    }
  }

  function setSubtag(subtag: RegistrySubtag) {
    if (subtag.type === 'language') {
      subtags.value.language = subtag.subtag
    } else if (subtag.type === 'script') {
      subtags.value.script = subtag.subtag
    } else if (subtag.type === 'region') {
      subtags.value.region = subtag.subtag
    } else if (subtag.type === 'variant') {
      if (!subtags.value.variants.includes(subtag.subtag)) {
        subtags.value.variants.push(subtag.subtag)
      }
    }
    if (subtag.preferred_value) {
      if (subtag.type === 'language') subtags.value.language = subtag.preferred_value
      else if (subtag.type === 'script') subtags.value.script = subtag.preferred_value
      else if (subtag.type === 'region') subtags.value.region = subtag.preferred_value
    }
  }

  function removeVariant(variant: string) {
    subtags.value.variants = subtags.value.variants.filter(v => v !== variant)
  }

  function goToStep(s: 1 | 2 | 3 | 4) {
    step.value = s
  }

  async function runPreview(): Promise<void> {
    loadingPreview.value = true
    errorPreview.value = null
    preview.value = null
    try {
      const payload = buildPayload()
      preview.value = await apiPreviewLanguage(payload)
    } catch (e: unknown) {
      errorPreview.value = (e as Error).message || 'Preview failed'
    } finally {
      loadingPreview.value = false
    }
  }

  async function submit(): Promise<CreatedLanguage | null> {
    loadingSubmit.value = true
    errorSubmit.value = null
    try {
      const payload = buildPayload()
      const result = await apiCreateLanguage(payload)
      return result
    } catch (e: unknown) {
      errorSubmit.value = (e as Error).message || 'Submit failed'
      return null
    } finally {
      loadingSubmit.value = false
    }
  }

  function buildPayload(): CreateLanguagePayload {
    return {
      subtags: { ...subtags.value },
      glottocode: glottocode.value,
      language: {
        name: metadata.name,
        name_en: metadata.name_en,
        description: metadata.description,
        reason: metadata.reason,
        alternate_names: [...metadata.alternate_names],
        references: [...metadata.references],
        parent_languoid_id: metadata.parent_languoid_id,
        latitude: metadata.latitude,
        longitude: metadata.longitude,
      },
    }
  }

  function reset() {
    subtagController?.abort()
    languoidController?.abort()
    subtagRequestId = 0
    languoidRequestId = 0
    step.value = 1
    subtags.value = {
      language: '',
      script: null,
      region: null,
      variants: [],
      private_use: [],
    }
    glottocode.value = null
    metadata.name = ''
    metadata.name_en = null
    metadata.description = ''
    metadata.reason = null
    metadata.alternate_names = []
    metadata.references = []
    metadata.parent_languoid_id = null
    metadata.latitude = null
    metadata.longitude = null
    subtagOptions.value = []
    languoidOptions.value = []
    preview.value = null
    loadingSubtags.value = false
    loadingLanguoids.value = false
    loadingPreview.value = false
    loadingSubmit.value = false
    errorSubtags.value = null
    errorLanguoids.value = null
    errorPreview.value = null
    errorSubmit.value = null
  }

  return {
    step,
    subtags,
    glottocode,
    metadata,
    subtagOptions,
    languoidOptions,
    loadingSubtags,
    loadingLanguoids,
    loadingPreview,
    loadingSubmit,
    errorSubtags,
    errorLanguoids,
    errorPreview,
    errorSubmit,
    preview,
    searchSubtags,
    searchLanguoids,
    setSubtag,
    removeVariant,
    goToStep,
    runPreview,
    submit,
    reset,
  }
}

function isAbortError(e: unknown): boolean {
  return e instanceof DOMException && e.name === 'AbortError'
}
