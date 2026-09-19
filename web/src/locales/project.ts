import systemUiCsv from '../../../scripts/i18n/ui-locales.csv?raw'
import { parseTranslationWideCsv, type TranslationCatalog } from './csvCatalog'

export type ProjectTranslationCatalog = TranslationCatalog

const catalogs: Readonly<Record<string, ProjectTranslationCatalog>> = parseTranslationWideCsv(systemUiCsv)

export function projectTranslations(locale: string | undefined): ProjectTranslationCatalog {
  if (!locale) return {}
  const exact = catalogs[locale]
  if (exact) return exact
  const code = Object.keys(catalogs).find((candidate) => candidate.toLowerCase() === locale.toLowerCase())
  return code ? catalogs[code] : {}
}
