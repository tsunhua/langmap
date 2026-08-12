import { describe, expect, it } from 'vitest'
import { previewLanguageLocaleCode } from './languageLocale'

describe('previewLanguageLocaleCode', () => {
  it('renders the structured locale code without becoming the server authority', () => {
    expect(previewLanguageLocaleCode({
      lang_code: 'nan', script_code: 'Hant', region_code: 'CN',
      place_segments: ['Quanzhou', 'Nanan'],
    })).toBe('nan-Hant-CN_Quanzhou_Nanan')
  })

  it('rejects a place segment outside the locale grammar', () => {
    expect(() => previewLanguageLocaleCode({
      lang_code: 'nan', script_code: 'Hant', region_code: 'CN', place_segments: ['New York'],
    })).toThrow('INVALID_PLACE_SEGMENT')
  })
})
