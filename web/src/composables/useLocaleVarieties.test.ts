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
    { code: 'en', name: 'English', native_name: 'English', status: 'active' },
    { code: 'es', name: 'Spanish', native_name: 'Español', status: 'active' },
    { code: 'ja', name: 'Japanese', native_name: '日本語', status: 'active' },
    { code: 'cmn-Hans', name: 'Simplified', native_name: '華語（普通話、國語）（簡體）', status: 'active' },
    { code: 'cmn-Hant', name: 'Traditional', native_name: '華語（普通話、國語）（傳承體）', status: 'active' },
  ]

  it('groups the 5 first-party locales into 4 variety groups', () => {
    const groups = groupLocalesByVariety(locales)
    expect(groups.map(g => g.base)).toEqual(['en', 'es', 'ja', 'cmn'])
  })

  it('places en first then sorts by variety label', () => {
    const groups = groupLocalesByVariety(locales)
    expect(groups[0].base).toBe('en')
    expect(groups[0].varietyLabel).toBe('English')
  })

  it('keeps single-script varieties as one-item groups', () => {
    const groups = groupLocalesByVariety(locales)
    const ja = groups.find(g => g.base === 'ja')!
    expect(ja.items).toHaveLength(1)
    expect(ja.items[0].code).toBe('ja')
    expect(ja.items[0].scriptLabel).toBeUndefined()
  })

  it('merges cmn-Hans and cmn-Hant under one variety with script labels', () => {
    const groups = groupLocalesByVariety(locales)
    const cmn = groups.find(g => g.base === 'cmn')!
    expect(cmn.varietyLabel).toBe('華語（普通話、國語）')
    expect(cmn.items.map(i => i.code)).toEqual(['cmn-Hans', 'cmn-Hant'])
    expect(cmn.items.map(i => i.scriptLabel)).toEqual(['簡體', '傳承體'])
  })

  it('returns an empty array for no locales', () => {
    expect(groupLocalesByVariety([])).toEqual([])
  })
})
