import { describe, expect, it } from 'vitest'
import { translationTerms } from './translationTerms'

describe('translationTerms', () => {
  it('preserves whitespace, emoji, RTL and occurrence codepoint offsets', () => {
    const text = '😀 station\nstation  مرحبا';
    const parts = translationTerms(text, ['station'])
    expect(parts.map(part => part.text).join('')).toBe(text)
    expect(parts.filter(part => part.text === 'station').map(part => part.start)).toEqual([2, 10])
    expect(parts.find(part => part.text === 'مرحبا')?.interactive).toBe(true)
  })
  it('prefers the longest matching phrase and does not match inside Latin words', () => {
    const parts = translationTerms('new railway station concatenated cat', ['station', 'railway station', 'cat'])
    expect(parts.filter(part => part.interactive).map(part => part.text)).toEqual(['new', 'railway station', 'concatenated', 'cat'])
  })
  it('does not treat an apostrophe inside a complete word as a boundary', () => {
    const parts = translationTerms("can't can café cafétéria", ['can', 'café'])
    expect(parts.filter(part => part.interactive).map(part => part.text)).toEqual(["can't", 'can', 'café', 'cafétéria'])
  })
  it('keeps Chinese phrases and surrounding text intact', () => {
    const text = '最近的車站在哪裡？'
    const parts = translationTerms(text, ['車站', '最近的車站'])
    expect(parts[0]?.text).toBe('最近的車站')
    expect(parts.map(part => part.text).join('')).toBe(text)
  })
})
