import { describe, expect, it } from 'vitest'
import { encodeExpressionTextWithHomograph, expressionPath, mapLensPath, parseExpressionTextSegment } from './expressionUrl'

describe('parseExpressionTextSegment', () => {
  it('defaults to homograph 1', () => {
    expect(parseExpressionTextSegment('hello')).toEqual({ text: 'hello', homograph_index: 1 })
  })
  it('takes the last suffix', () => {
    expect(parseExpressionTextSegment('hello~2')).toEqual({ text: 'hello', homograph_index: 2 })
    expect(parseExpressionTextSegment('hello~2~1')).toEqual({ text: 'hello~2', homograph_index: 1 })
  })
  it('keeps a trailing tilde without digits', () => {
    expect(parseExpressionTextSegment('hello~')).toEqual({ text: 'hello~', homograph_index: 1 })
  })
})

describe('encodeExpressionTextWithHomograph', () => {
  it('omits the suffix for homograph 1 plain text', () => {
    expect(encodeExpressionTextWithHomograph('hello')).toBe('hello')
  })
  it('appends the suffix for homographs above 1', () => {
    expect(encodeExpressionTextWithHomograph('hello', 2)).toBe('hello~2')
  })
  it('disambiguates texts that end in tilde digits', () => {
    expect(encodeExpressionTextWithHomograph('hello~2', 1)).toBe('hello~2~1')
    expect(encodeExpressionTextWithHomograph('hello~2', 3)).toBe('hello~2~3')
  })
  it('percent-encodes reserved characters', () => {
    expect(encodeExpressionTextWithHomograph('hello world')).toBe('hello%20world')
    expect(encodeExpressionTextWithHomograph('你/好')).toBe('%E4%BD%A0%2F%E5%A5%BD')
  })
})

describe('expressionPath', () => {
  it('builds the canonical mapping path', () => {
    expect(expressionPath('en', 'hello')).toBe('/mapping/en/hello')
    expect(expressionPath('en', 'hello', 2)).toBe('/mapping/en/hello~2')
    expect(expressionPath('nan', '食', 1)).toBe('/mapping/nan/%E9%A3%9F')
  })
  it('round-trips through parseExpressionTextSegment', () => {
    for (const [text, homo] of [['hello', 1], ['hello', 2], ['hello~2', 1], ['hello~2', 2], ['你 好', 3]] as const) {
      const segment = expressionPath('en', text, homo).split('/').pop()!
      const parsed = parseExpressionTextSegment(decodeURIComponent(segment))
      expect(parsed).toEqual({ text, homograph_index: homo })
    }
  })
})

describe('mapLensPath', () => {
  it('builds the map lens path', () => {
    expect(mapLensPath('en', 'hello', 2)).toBe('/map/en/hello~2')
  })
})
