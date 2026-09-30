import type { UiLocale } from '@/api/localization'

interface LocaleParts {
  language: string
  script?: string
  region?: string
}

// Browser language tags commonly use ISO 639-1 codes, while LangMap locale
// codes use ISO 639-3 codes.
const BROWSER_LANGUAGE_ALIASES: Record<string, string> = {
  en: 'eng',
  es: 'spa',
  ja: 'jpn',
  zh: 'cmn',
}

const TRADITIONAL_CHINESE_REGIONS = new Set(['HK', 'MO', 'TW'])
const SIMPLIFIED_CHINESE_REGIONS = new Set(['CN', 'SG'])

function parseLocaleParts(code: string): LocaleParts | null {
  const [rawLanguage, ...subtags] = code.replace(/_/g, '-').split('-')
  const language = rawLanguage?.toLowerCase()
  if (!language) return null

  const canonicalLanguage = BROWSER_LANGUAGE_ALIASES[language] ?? language
  const script = subtags.find((part) => /^[A-Za-z]{4}$/.test(part))?.toLowerCase()
  const region = subtags.find((part) => /^[A-Za-z]{2}$/.test(part) || /^\d{3}$/.test(part))?.toUpperCase()
  const inferredChineseScript = canonicalLanguage === 'cmn' && !script
    ? TRADITIONAL_CHINESE_REGIONS.has(region ?? '')
      ? 'hant'
      : SIMPLIFIED_CHINESE_REGIONS.has(region ?? '')
        ? 'hans'
        : undefined
    : undefined

  return { language: canonicalLanguage, script: script ?? inferredChineseScript, region }
}

function matchScore(preferred: LocaleParts, candidate: LocaleParts): number {
  const scriptMatch = preferred.script && candidate.script === preferred.script ? 2 : 0
  const regionMatch = preferred.region && candidate.region === preferred.region ? 1 : 0
  return scriptMatch + regionMatch
}

function compareCodes(left: string, right: string): number {
  return left < right ? -1 : left > right ? 1 : 0
}

export function resolveBrowserUiLocale(
  browserLanguages: readonly string[],
  locales: readonly UiLocale[],
): string | undefined {
  const activeLocales = locales
    .filter((locale) => locale.status === 'active')
    .flatMap((locale) => {
      const parts = parseLocaleParts(locale.language_locale_code)
      return parts ? [{ code: locale.language_locale_code, parts }] : []
    })
    .sort((left, right) => compareCodes(left.code, right.code))

  for (const browserLanguage of browserLanguages) {
    const preferred = parseLocaleParts(browserLanguage)
    if (!preferred) continue

    const candidates = activeLocales
      .filter((locale) => locale.parts.language === preferred.language)
      .sort((left, right) =>
        matchScore(preferred, right.parts) - matchScore(preferred, left.parts)
        || compareCodes(left.code, right.code),
      )

    if (candidates[0]) return candidates[0].code
  }

  return undefined
}
