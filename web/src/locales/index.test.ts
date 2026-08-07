import { describe, expect, it } from 'vitest'
import { DEFAULT_LOCALE, localeFallbackChain, resolveLocale } from './index'

describe('localization locale helpers', () => {
  it('uses en-Latn as the built-in source locale', () => {
    expect(DEFAULT_LOCALE).toBe('en-Latn')
  })

  it('canonicalizes tags and prefers an available exact casing', () => {
    expect(resolveLocale('cmn-hant', ['en-US', 'cmn-Hant'])).toBe('cmn-Hant')
    expect(resolveLocale('not a locale', ['en'])).toBe('en-Latn')
  })

  it('maps legacy zh macrolanguage tags onto the precise cmn locales', () => {
    const available = ['en', 'cmn-Hans', 'cmn-Hant']
    expect(resolveLocale('zh-Hant', available)).toBe('cmn-Hant')
    expect(resolveLocale('zh-hant-tw', available)).toBe('cmn-Hant')
    expect(resolveLocale('zh-TW', available)).toBe('cmn-Hant')
    expect(resolveLocale('zh-HK', available)).toBe('cmn-Hant')
    expect(resolveLocale('zh-MO', available)).toBe('cmn-Hant')
    expect(resolveLocale('zh-Hans', available)).toBe('cmn-Hans')
    expect(resolveLocale('zh-CN', available)).toBe('cmn-Hans')
    expect(resolveLocale('zh-SG', available)).toBe('cmn-Hans')
    expect(resolveLocale('zh', available)).toBe('cmn-Hans')
  })

  it('leaves the zh alias inert when no cmn locale is available', () => {
    expect(resolveLocale('zh-Hant', ['en-Latn'])).toBe('en-Latn')
  })

  it('builds a bounded parent fallback chain ending in the source locale', () => {
    expect(localeFallbackChain('nan-Hant-x-chao1238')).toEqual([
      'nan-Hant-x-chao1238', 'nan-Hant-x', 'nan-Hant', 'nan', 'en-Latn',
    ])
    expect(localeFallbackChain('en-US')).toEqual(['en-US', 'en', 'en-Latn'])
  })
})
