import { describe, expect, it } from 'vitest'
import { DEFAULT_LOCALE, resolveLocale } from './index'

describe('localization locale helpers', () => {
  it('uses the ISO language-locale source locale', () => {
    expect(DEFAULT_LOCALE).toBe('eng-Latn-US')
  })

  it('canonicalizes tags and prefers an available exact casing', () => {
    expect(resolveLocale('cmn-hant', ['en-US', 'cmn-Hant'])).toBe('cmn-Hant')
    expect(resolveLocale('not a locale', ['en'])).toBe('not a locale')
  })

})
