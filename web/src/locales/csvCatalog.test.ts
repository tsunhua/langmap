import { describe, expect, it } from 'vitest'
import { parseTranslationWideCsv } from './csvCatalog'

describe('parseTranslationWideCsv', () => {
  it('parses quoted commas, newlines, and escaped quotes', () => {
    expect(parseTranslationWideCsv('ENTRY_ID,NOTE,LOCALE_cmn-Hant-TW,LOCALE_eng-Latn-US\nhello,,"你好, 世界",Hello\nquote,,"他說 ""好""","He said ""yes"""\nline,,"第一行\n第二行",Line\n')).toEqual({
      'cmn-Hant-TW': { hello: '你好, 世界', quote: '他說 "好"', line: '第一行\n第二行' },
      'eng-Latn-US': { hello: 'Hello', quote: 'He said "yes"', line: 'Line' },
    })
  })

  it('rejects duplicate keys', () => {
    expect(() => parseTranslationWideCsv('ENTRY_ID,NOTE,LOCALE_cmn-Hant-TW,LOCALE_eng-Latn-US\na,,one,two\na,,three,four\n')).toThrow('row 3')
  })
})
