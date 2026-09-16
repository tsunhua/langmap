// Mirrors backend/src/utils/limits.ts so the client can block over-limit input
// before the server rejects it. Keep these values in sync.
export const MAX_TRANSLATION_GRAPHEMES = 500
export const MAX_TRANSLATION_TEXT_BYTES = 8192

interface GraphemeSegmenter {
  segment(input: string): Iterable<unknown>
}

type SegmenterConstructor = new (
  locales?: string | string[],
  options?: { granularity?: 'grapheme' | 'word' | 'sentence' },
) => GraphemeSegmenter

// Intl.Segmenter is ES2022 and not in the project's ES2020 lib, and not every
// runtime implements it, so feature-detect through an untyped lookup.
function createGraphemeSegmenter(): GraphemeSegmenter | null {
  const segmenterConstructor = (Intl as unknown as { Segmenter?: SegmenterConstructor }).Segmenter
  if (!segmenterConstructor) return null
  try {
    return new segmenterConstructor('en', { granularity: 'grapheme' })
  } catch {
    return null
  }
}

const graphemeSegmenter = createGraphemeSegmenter()
const textEncoder = typeof TextEncoder !== 'undefined' ? new TextEncoder() : null

export function countGraphemes(text: string): number {
  if (!text) return 0
  if (graphemeSegmenter) {
    let count = 0
    for (const _ of graphemeSegmenter.segment(text)) count += 1
    return count
  }
  return Array.from(text).length
}

export function utf8ByteLength(text: string): number {
  if (textEncoder) return textEncoder.encode(text).length
  return fallbackUtf8ByteLength(text)
}

function fallbackUtf8ByteLength(text: string): number {
  let bytes = 0
  for (const character of text) {
    const codePoint = character.codePointAt(0) ?? 0
    if (codePoint <= 0x7f) bytes += 1
    else if (codePoint <= 0x7ff) bytes += 2
    else if (codePoint <= 0xffff) bytes += 3
    else bytes += 4
  }
  return bytes
}
