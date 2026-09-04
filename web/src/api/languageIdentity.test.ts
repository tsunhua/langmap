import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import api from './client'
import { listContentLanguages, listLanguageExpressions, listLanguageLocales, listLanguages } from './languageIdentity'

vi.mock('./client', () => ({ default: { get: vi.fn(), post: vi.fn() } }))

describe('language identity API', () => {
  beforeEach(() => {
    vi.stubEnv('DEV', false)
    vi.mocked(api.get).mockResolvedValue({ data: { data: { items: [], total: 0, skip: 0, limit: 20, hasMore: false } } })
  })

  afterEach(() => {
    vi.unstubAllEnvs()
  })

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

  it('forwards language content search, sort, paging and locale filters', async () => {
    const signal = new AbortController().signal

    await listContentLanguages({ q: 'min', sort: 'alpha', limit: 10, offset: 20, ui_locale: 'cmn-Hans-CN' }, signal)
    expect(api.get).toHaveBeenLastCalledWith('/languages', {
      params: { q: 'min', sort: 'alpha', limit: 10, offset: 20, ui_locale: 'cmn-Hans-CN', _content_revision: 0 }, signal,
    })

    await listLanguageExpressions('nan', { q: '食', sort: 'new', locale: 'nan-Hant-CN_Quanzhou_Nanan', limit: 10, offset: 20, ui_locale: 'cmn-Hans-CN' }, signal)
    expect(api.get).toHaveBeenLastCalledWith('/languages/nan/expressions', {
      params: { q: '食', sort: 'new', locale: 'nan-Hant-CN_Quanzhou_Nanan', limit: 10, offset: 20, ui_locale: 'cmn-Hans-CN', _content_revision: 0 }, signal,
    })
  })

  it('preserves pagination metadata from language content responses', async () => {
    vi.mocked(api.get).mockResolvedValueOnce({
      data: { data: { items: [], total: 101, skip: 20, limit: 20, hasMore: true } },
    })

    await expect(listLanguageExpressions('nan')).resolves.toMatchObject({
      items: [], total: 101, skip: 20, limit: 20, has_more: true, hasMore: true,
    })
  })
})
