import { createI18n } from 'vue-i18n'
import { en, type MessageSchema } from './en'

export const SOURCE_LOCALE = 'eng-Latn-US'
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

export function resolveLocale(input: string | null | undefined, available: readonly string[] = []): string {
  const value = input?.trim()
  if (!value) return DEFAULT_LOCALE
  const exact = available.find(code => code.toLowerCase() === value.toLowerCase())
  if (exact) return exact
  return available.find(code => code.toLowerCase() === value.toLowerCase()) ?? value
}
