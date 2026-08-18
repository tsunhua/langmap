import { describe, expect, it } from 'vitest'
import { parseLocaleCode, splitVarietyAndScript, groupLocalesByVariety } from './useLocaleVarieties'
import type { UiLocale } from '@/api/localization'

describe('parseLocaleCode', () => {
  it('parses a bare primary subtag', () => {
    expect(parseLocaleCode('en')).toEqual({ base: 'en' })
  })

  it('parses a primary subtag with script', () => {
    expect(parseLocaleCode('cmn-Hans')).toEqual({ base: 'cmn', script: 'Hans' })
    expect(parseLocaleCode('cmn-Hant')).toEqual({ base: 'cmn', script: 'Hant' })
  })

  it('parses a primary subtag with region', () => {
    expect(parseLocaleCode('en-GB')).toEqual({ base: 'en', region: 'GB' })
  })

  it('parses a primary subtag with script and region', () => {
    expect(parseLocaleCode('cmn-Hans-CN')).toEqual({ base: 'cmn', script: 'Hans', region: 'CN' })
  })

  it('ignores private-use and variant subtags for grouping', () => {
    expect(parseLocaleCode('nan-x-cha')).toEqual({ base: 'nan' })
  })
})

describe('splitVarietyAndScript', () => {
  it('returns the whole string as variety when no fullwidth parens', () => {
    expect(splitVarietyAndScript('English')).toEqual({ variety: 'English' })
    expect(splitVarietyAndScript('日本語')).toEqual({ variety: '日本語' })
  })

  it('splits trailing fullwidth parens into script label', () => {
    expect(splitVarietyAndScript('華語（簡體）')).toEqual({ variety: '華語', scriptLabel: '簡體' })
    expect(splitVarietyAndScript('華語（傳承體）')).toEqual({ variety: '華語', scriptLabel: '傳承體' })
  })

  it('does not split non-trailing parens', () => {
    expect(splitVarietyAndScript('English (United Kingdom)')).toEqual({ variety: 'English (United Kingdom)' })
  })

  it('splits the last fullwidth paren group when the variety name itself contains parens', () => {
    expect(splitVarietyAndScript('華語（普通話、國語）（傳承體）')).toEqual({
      variety: '華語（普通話、國語）',
      scriptLabel: '傳承體',
    })
  })
})

describe('groupLocalesByVariety', () => {
  const locales: UiLocale[] = [
    { language_locale_code: 'eng-Latn-US', name: 'English', name_en: 'English', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: 'system' },
    { language_locale_code: 'spa-Latn-ES', name: 'Español', name_en: 'Spanish', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: 'system' },
    { language_locale_code: 'jpn-Jpan-JP', name: '日本語', name_en: 'Japanese', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: 'system' },
    { language_locale_code: 'cmn-Hans-CN', name: '華語（普通話、國語）（簡體）', name_en: 'Simplified', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: 'system' },
    { language_locale_code: 'cmn-Hant-TW', name: '華語（普通話、國語）（傳承體）', name_en: 'Traditional', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: 'system' },
  ]

  it('groups the 5 first-party locales into 4 variety groups', () => {
    const groups = groupLocalesByVariety(locales)
    expect(groups.map(g => g.base)).toEqual(['eng', 'spa', 'jpn', 'cmn'])
  })

  it('places en first then sorts by variety label', () => {
    const groups = groupLocalesByVariety(locales)
    expect(groups[0].base).toBe('eng')
    expect(groups[0].varietyLabel).toBe('English')
  })

  it('keeps single-script varieties as one-item groups', () => {
    const groups = groupLocalesByVariety(locales)
    const ja = groups.find(g => g.base === 'jpn')!
    expect(ja.items).toHaveLength(1)
    expect(ja.items[0].code).toBe('jpn-Jpan-JP')
    expect(ja.items[0].scriptLabel).toBeUndefined()
  })

  it('merges cmn-Hans and cmn-Hant under one variety with script labels', () => {
    const groups = groupLocalesByVariety(locales)
    const cmn = groups.find(g => g.base === 'cmn')!
    expect(cmn.varietyLabel).toBe('華語（普通話、國語）')
    expect(cmn.items.map(i => i.code)).toEqual(['cmn-Hans-CN', 'cmn-Hant-TW'])
    expect(cmn.items.map(i => i.scriptLabel)).toEqual(['簡體', '傳承體'])
  })

  it('returns an empty array for no locales', () => {
    expect(groupLocalesByVariety([])).toEqual([])
  })

  it('prefers the active locale\'s self-name as the variety label', () => {
    const groups = groupLocalesByVariety([
      { language_locale_code: 'cmn-Hans-CN', name: '普通话', name_en: 'Simplified Chinese', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: 'system' },
      { language_locale_code: 'cmn-Hant-TW', name: '華語', name_en: 'Taiwan Mandarin', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: 'system' },
    ], 'cmn-Hant-TW')
    const cmn = groups.find(g => g.base === 'cmn')!
    expect(cmn.varietyLabel).toBe('華語')
  })

  it('falls back to the first locale\'s self-name without an active locale', () => {
    const groups = groupLocalesByVariety([
      { language_locale_code: 'cmn-Hans-CN', name: '普通话', name_en: 'Simplified Chinese', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: 'system' },
      { language_locale_code: 'cmn-Hant-TW', name: '華語', name_en: 'Taiwan Mandarin', direction: 'ltr', status: 'active', mapping_revision: 0, activation_source: 'system' },
    ])
    const cmn = groups.find(g => g.base === 'cmn')!
    expect(cmn.varietyLabel).toBe('普通话')
  })
})
