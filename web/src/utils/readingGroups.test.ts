import { describe, expect, it } from 'vitest'
import { readingLocaleLabel } from './readingGroups'

describe('readingLocaleLabel', () => {
  it('omits a trailing 話 from locale display names', () => {
    expect(readingLocaleLabel({
      language_locale_code: 'wuu-Hant-CN_Shanghai',
      locale_display_name: '上海話',
      scheme: 'shanghai-church-romanization',
      value: 'Na°',
    })).toBe('上海')
  })

  it('keeps the existing 腔 suffix behavior for parenthesized labels', () => {
    expect(readingLocaleLabel({
      language_locale_code: 'hak-Hant-TW_Dapu',
      locale_display_name: '客語（大埔腔）',
      scheme: 'hakka-pinyin',
      value: 'ta11 pu24',
    })).toBe('大埔')
  })
})
