import { createI18n } from 'vue-i18n'
import { en, type MessageSchema } from './en'

export const SOURCE_LOCALE = 'en-US'
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
    return available.find(code => code.toLowerCase() === canonical.toLowerCase()) ?? canonical
  } catch {
    return DEFAULT_LOCALE
  }
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
