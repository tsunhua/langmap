export interface LanguageLocalePreviewInput {
  lang_code: string
  script_code: string
  region_code: string
  place_segments: string[]
}

const PLACE_SEGMENT_RE = /^[A-Z][A-Za-z]*$/

/** A client-side preview only; the API builds the persisted locale code. */
export function previewLanguageLocaleCode(input: LanguageLocalePreviewInput): string {
  const lang = input.lang_code.toLowerCase()
  if (!/^[a-z]{3}$/.test(lang)) throw new Error('INVALID_LANG_CODE')
  if (!/^[A-Z][a-z]{3}$/.test(input.script_code)) throw new Error('INVALID_SCRIPT_CODE')
  if (!/^[A-Z]{2}$/.test(input.region_code)) throw new Error('INVALID_REGION_CODE')
  if (input.place_segments.some((segment) => !PLACE_SEGMENT_RE.test(segment))) {
    throw new Error('INVALID_PLACE_SEGMENT')
  }
  const path = input.place_segments.join('_')
  return `${lang}-${input.script_code}-${input.region_code}${path ? `_${path}` : ''}`
}
