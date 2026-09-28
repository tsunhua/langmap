export interface TranslationTerm {
  text: string
  start: number
  end: number
  interactive: boolean
}
interface WordSegment { segment: string; index: number; isWordLike?: boolean }
type WordSegmenterConstructor = new (locales?: string[], options?: { granularity: 'word' }) => {
  segment(text: string): Iterable<WordSegment>
}

const wordCharacter = /[\p{L}\p{N}\p{M}_]/u
const unspacedCharacter = /[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}]/u
function requiresBoundary(character: string | undefined) {
  return Boolean(character && wordCharacter.test(character) && !unspacedCharacter.test(character))
}

export function translationTerms(text: string, references: string[] = []): TranslationTerm[] {
  const characters = Array.from(text)
  const phrases = [...new Set(references.filter(value => value.trim()))]
    .map(value => Array.from(value))
    .sort((a, b) => b.length - a.length || a.join('').localeCompare(b.join('')))
  const output: TranslationTerm[] = []
  const Constructor = (Intl as unknown as { Segmenter?: WordSegmenterConstructor }).Segmenter
  const segmenter = Constructor ? new Constructor(undefined, { granularity: 'word' }) : null
  function segment(value: string): WordSegment[] {
    if (segmenter) return [...segmenter.segment(value)]
    return [...value.matchAll(/[\p{L}\p{N}\p{M}_]+(?:['’][\p{L}\p{N}\p{M}_]+)*|[^\p{L}\p{N}\p{M}_]+/gu)]
      .map(match => ({ segment: match[0], index: match.index ?? 0, isWordLike: wordCharacter.test(match[0]) }))
  }
  const wordStarts = new Set<number>()
  const wordEnds = new Set<number>()
  let wordOffset = 0
  for (const part of segment(text)) {
    const end = wordOffset + Array.from(part.segment).length
    if (part.isWordLike) { wordStarts.add(wordOffset); wordEnds.add(end) }
    wordOffset = end
  }
  function appendPlain(start: number, end: number) {
    const value = characters.slice(start, end).join('')
    const parts = segment(value)
    let offset = start
    for (const part of parts) {
      const length = Array.from(part.segment).length
      output.push({ text: part.segment, start: offset, end: offset + length, interactive: Boolean(part.isWordLike) })
      offset += length
    }
  }
  let plainStart = 0
  for (let index = 0; index < characters.length;) {
    const phrase = phrases.find(candidate => {
      const end = index + candidate.length
      if (end > characters.length || !candidate.every((character, offset) => character === characters[index + offset])) return false
      if (requiresBoundary(candidate[0]) && !wordStarts.has(index)) return false
      if (requiresBoundary(candidate[candidate.length - 1]) && !wordEnds.has(end)) return false
      return true
    })
    if (!phrase) { index += 1; continue }
    appendPlain(plainStart, index)
    output.push({ text: phrase.join(''), start: index, end: index + phrase.length, interactive: true })
    index += phrase.length
    plainStart = index
  }
  appendPlain(plainStart, characters.length)
  return output
}
