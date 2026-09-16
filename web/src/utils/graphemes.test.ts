import { describe, expect, it } from 'vitest'
import {
  MAX_TRANSLATION_GRAPHEMES,
  MAX_TRANSLATION_TEXT_BYTES,
  countGraphemes,
  utf8ByteLength,
} from './graphemes'

describe('graphemes', () => {
  it('counts base letters and precomposed accents as single graphemes', () => {
    expect(countGraphemes('a')).toBe(1)
    expect(countGraphemes('é')).toBe(1)
  })

  it('merges combining marks into the preceding base character', () => {
    expect(countGraphemes('e\u0301')).toBe(1)
    expect(countGraphemes('a\u0300\u0301')).toBe(1)
  })

  it('counts emoji ZWJ sequences, modifiers and flags as single graphemes', () => {
    expect(countGraphemes('👨‍👩‍👧')).toBe(1)
    expect(countGraphemes('👍🏽')).toBe(1)
    expect(countGraphemes('🇯🇵')).toBe(1)
  })

  it('handles empty and mixed text', () => {
    expect(countGraphemes('')).toBe(0)
    expect(countGraphemes('héllo')).toBe(5)
  })

  it('measures UTF-8 bytes, not code units', () => {
    expect(utf8ByteLength('a')).toBe(1)
    expect(utf8ByteLength('中')).toBe(3)
    expect(utf8ByteLength('👍')).toBe(4)
  })

  it('marks 500 graphemes and 8192 bytes as the limits', () => {
    expect(MAX_TRANSLATION_GRAPHEMES).toBe(countGraphemes('a'.repeat(500)))
    expect(countGraphemes('a'.repeat(501))).toBe(501)
    expect(MAX_TRANSLATION_TEXT_BYTES).toBe(utf8ByteLength('a'.repeat(8192)))
    expect(utf8ByteLength('a'.repeat(8193))).toBe(8193)
  })
})
