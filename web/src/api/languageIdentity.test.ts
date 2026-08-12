import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from './client'
import { listLanguageLocales, listLanguages } from './languageIdentity'

vi.mock('./client', () => ({ default: { get: vi.fn(), post: vi.fn() } }))

describe('language identity API', () => {
  beforeEach(() => vi.mocked(api.get).mockResolvedValue({ data: { data: { items: [], total: 0, skip: 0, limit: 20, hasMore: false } } }))

  it('queries ISO registries and language locales through v2 contracts', async () => {
    await listLanguages('nan')
    expect(api.get).toHaveBeenCalledWith('/language-registry/languages', {
      params: { q: 'nan', limit: 20, offset: 0 }, signal: undefined,
    })

    await listLanguageLocales({ lang_code: 'nan', q: '', limit: 20, offset: 0 })
    expect(api.get).toHaveBeenLastCalledWith('/language-locales', {
      params: { lang_code: 'nan', q: '', limit: 20, offset: 0 }, signal: undefined,
    })
  })
})
