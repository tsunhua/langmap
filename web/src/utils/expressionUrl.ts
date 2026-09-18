const TRAILING_HOMOGRAPH = /~\d+$/

export function parseExpressionTextSegment(text: string): { text: string; homograph_index: number } {
  const match = /^(.*)~(\d+)$/s.exec(text)
  if (!match) return { text, homograph_index: 1 }
  return { text: match[1], homograph_index: Number(match[2]) }
}

export function encodeExpressionTextWithHomograph(text: string, homographIndex = 1): string {
  const needsSuffix = homographIndex > 1 || TRAILING_HOMOGRAPH.test(text)
  return needsSuffix ? `${encodeURIComponent(text)}~${homographIndex}` : encodeURIComponent(text)
}

export function expressionPath(langCode: string, text: string, homographIndex = 1): string {
  return `/mapping/${encodeURIComponent(langCode)}/${encodeExpressionTextWithHomograph(text, homographIndex)}`
}

export function mapLensPath(langCode: string, text: string, homographIndex = 1): string {
  return `/map/${encodeURIComponent(langCode)}/${encodeExpressionTextWithHomograph(text, homographIndex)}`
}
