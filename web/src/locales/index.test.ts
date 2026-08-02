import { describe, expect, it } from 'vitest'
import { DEFAULT_LOCALE, localeFallbackChain, resolveLocale } from './index'

describe('localization locale helpers', () => {
  it('uses en as the built-in source locale', () => {
    expect(DEFAULT_LOCALE).toBe('en')
  })

  it('canonicalizes tags and prefers an available exact casing', () => {
    expect(resolveLocale('zh-hant-tw', ['en-US', 'zh-Hant'])).toBe('zh-Hant')
    expect(resolveLocale('not a locale', ['en'])).toBe('en')
  })

  it('builds a bounded parent fallback chain ending in en', () => {
    expect(localeFallbackChain('nan-Hant-x-chao1238')).toEqual([
      'nan-Hant-x-chao1238', 'nan-Hant-x', 'nan-Hant', 'nan', 'en',
    ])
    expect(localeFallbackChain('en-US')).toEqual(['en-US', 'en'])
  })
})
