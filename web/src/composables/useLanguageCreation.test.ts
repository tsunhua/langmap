import { describe, expect, it, vi, beforeEach } from 'vitest'
import {
  listLanguageSubtags,
  searchLanguoids,
  previewVariety,
  createVariety,
} from '@/api/languages'
import type { RegistrySubtag, LanguoidCandidate, VarietyPreview, CreatedVarietyResult } from '@/api/languages'
import { useLanguageCreation } from './useLanguageCreation'

vi.mock('@/api/languages', () => ({
  listRegistryLanguages: vi.fn(),
  listLanguageSubtags: vi.fn(),
  searchLanguoids: vi.fn(),
  previewVariety: vi.fn(),
  createVariety: vi.fn(),
}))

function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason?: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}

beforeEach(() => {
  vi.restoreAllMocks()
})

describe('useLanguageCreation', () => {
  it('starts at step 1 with empty subtags', () => {
    const state = useLanguageCreation()
    expect(state.step.value).toBe(1)
    expect(state.subtags.value).toEqual({
      language: '',
      script: null,
      region: null,
      variants: [],
      private_use: [],
    })
  })

  it('ignores a stale subtag response', async () => {
    const first = deferred<RegistrySubtag[]>()
    const second = deferred<RegistrySubtag[]>()
    vi.mocked(listLanguageSubtags)
      .mockReturnValueOnce(first.promise)
      .mockReturnValueOnce(second.promise)

    const state = useLanguageCreation()
    const a = state.searchSubtags('language', 'z')
    const b = state.searchSubtags('language', 'zh')
    second.resolve([{ type: 'language', subtag: 'zh', descriptions: ['Chinese'], prefixes: [], preferred_value: null, suppress_script: null, deprecated_at: null }])
    first.resolve([{ type: 'language', subtag: 'za', descriptions: ['Zhuang'], prefixes: [], preferred_value: null, suppress_script: null, deprecated_at: null }])
    await Promise.all([a, b])
    expect(state.subtagOptions.value[0].subtag).toBe('zh')
  })

  it('cancels previous languoid search when a new one fires', async () => {
    const first = deferred<LanguoidCandidate[]>()
    const second = deferred<LanguoidCandidate[]>()
    vi.mocked(searchLanguoids)
      .mockReturnValueOnce(first.promise)
      .mockReturnValueOnce(second.promise)

    const state = useLanguageCreation()
    const a = state.searchLanguoids('abc')
    const b = state.searchLanguoids('abcd')
    second.resolve([])
    first.resolve([])
    await Promise.all([a, b])
    expect(searchLanguoids).toHaveBeenCalledTimes(2)
  })

  it('reset returns to step 1', async () => {
    vi.mocked(listLanguageSubtags).mockResolvedValue([])
    const state = useLanguageCreation()
    await state.searchSubtags('language', 'en')
    state.setSubtag({ type: 'language', subtag: 'en', descriptions: ['English'], prefixes: [], preferred_value: null, suppress_script: null, deprecated_at: null })
    expect(state.step.value).toBe(1)
    state.reset()
    expect(state.step.value).toBe(1)
    expect(state.subtags.value.language).toBe('')
  })

  it('runPreview calls previewVariety and stores result', async () => {
    const preview: VarietyPreview = {
      canonical_profile_code: 'en',
      direction: 'ltr',
      warnings: [],
      existing_variety: null,
      existing_profile: null,
      profiles_of_variety: [],
      similar_varieties: [],
      required_metadata: [],
    }
    vi.mocked(previewVariety).mockResolvedValue(preview)

    const state = useLanguageCreation()
    await state.runPreview()
    expect(state.preview.value).toEqual(preview)
  })

  it('submit calls createVariety and returns result', async () => {
    const created: CreatedVarietyResult = {
      variety: {
        id: '01K1GWHD00NMQC20PMZV031H78',
        code: 'test-lang',
        name: 'Test',
        name_en: null,
        description: '',
        glottocode: null,
        origin: 'community',
        community_reason: null,
        alternate_names: [],
        references: [],
        parent_languoid_id: null,
      },
      profile: {
        code: 'test-lang',
        language_variety_id: '01K1GWHD00NMQC20PMZV031H78',
        language_variety_code: 'test-lang',
        name: 'Test',
        name_en: null,
        direction: 'ltr',
        base_language: 'test',
        script_code: null,
        region_code: null,
        variants: [],
        private_use: [],
      },
    }
    vi.mocked(createVariety).mockResolvedValue(created)

    const state = useLanguageCreation()
    const result = await state.submit()
    expect(result).toEqual(created)
  })
})
