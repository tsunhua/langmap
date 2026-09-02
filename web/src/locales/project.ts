import cmnHans from '../../../scripts/i18n/cmn-Hans-CN.json'
import cmnHant from '../../../scripts/i18n/cmn-Hant-TW.json'
import jpn from '../../../scripts/i18n/jpn-Jpan-JP.json'
import spa from '../../../scripts/i18n/spa-Latn-ES.json'

export type ProjectTranslationCatalog = Readonly<Record<string, string>>

const catalogs: Readonly<Record<string, ProjectTranslationCatalog>> = {
  'cmn-Hans-CN': cmnHans,
  'cmn-Hant-TW': cmnHant,
  'jpn-Jpan-JP': jpn,
  'spa-Latn-ES': spa,
}

export function projectTranslations(locale: string | undefined): ProjectTranslationCatalog {
  if (!locale) return {}
  const exact = catalogs[locale]
  if (exact) return exact
  const code = Object.keys(catalogs).find((candidate) => candidate.toLowerCase() === locale.toLowerCase())
  return code ? catalogs[code] : {}
}
