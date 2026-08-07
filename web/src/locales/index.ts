import { createI18n } from 'vue-i18n'
import { en, type MessageSchema } from './en'

export const SOURCE_LOCALE = 'en-Latn'
export const DEFAULT_LOCALE = SOURCE_LOCALE
export const i18n = createI18n<[MessageSchema], typeof SOURCE_LOCALE>({
  legacy: false,
  locale: DEFAULT_LOCALE,
  fallbackLocale: SOURCE_LOCALE,
  messages: { [SOURCE_LOCALE]: en },
  missingWarn: false,
  fallbackWarn: false,
})

export type LocaleCode = string

/** Keep the user-facing locale tag in canonical BCP 47 casing. */
export function resolveLocale(input: string | null | undefined, available: readonly string[] = []): string {
  const value = input?.trim()
  if (!value) return DEFAULT_LOCALE
  const exact = available.find(code => code.toLowerCase() === value.toLowerCase())
  if (exact) return exact
  try {
    const canonical = Intl.getCanonicalLocales(value)[0]
    const alias = mandarinAlias(canonical)
    if (alias) {
      const aliased = available.find(code => code.toLowerCase() === alias.toLowerCase())
      if (aliased) return aliased
    }
    for (const candidate of localeFallbackChain(canonical)) {
      const availableCode = available.find(code => code.toLowerCase() === candidate.toLowerCase())
      if (availableCode) return availableCode
    }
    return canonical
  } catch {
    return DEFAULT_LOCALE
  }
}

/**
 * Browsers only ever send the zh macrolanguage, never cmn, so inbound tags need
 * mapping onto the precise Mandarin locales or Chinese users fall back to English.
 */
const LEGACY_MANDARIN_ALIASES: Record<string, string> = {
  'zh': 'cmn-Hans',
  'zh-hans': 'cmn-Hans',
  'zh-cn': 'cmn-Hans',
  'zh-sg': 'cmn-Hans',
  'zh-my': 'cmn-Hans',
  'zh-hant': 'cmn-Hant',
  'zh-tw': 'cmn-Hant',
  'zh-hk': 'cmn-Hant',
  'zh-mo': 'cmn-Hant',
}

function mandarinAlias(locale: string): string | null {
  const lower = locale.toLowerCase()
  if (!lower.startsWith('zh')) return null
  for (const candidate of localeFallbackChain(lower)) {
    const alias = LEGACY_MANDARIN_ALIASES[candidate]
    if (alias) return alias
  }
  return null
}

export function localeFallbackChain(locale: string): string[] {
  const parts = locale.split('-')
  const chain: string[] = []
  while (parts.length > 1) {
    chain.push(parts.join('-'))
    parts.pop()
  }
  chain.push(parts[0] || DEFAULT_LOCALE)
  if (!chain.includes(DEFAULT_LOCALE)) chain.push(DEFAULT_LOCALE)
  return chain
}
