import api from './client'
import type { LocaleHints } from './languageIdentity'
import { contentRevision } from '@/utils/contentRevision'

export interface HandbookTranslationReading { scheme: string; value: string }
export interface HandbookTranslation {
  id: string
  text: string
  lang_code: string
  language_locale_code: string
  language_name: string
  readings: HandbookTranslationReading[]
}
export interface HandbookTranslationItem {
  source_expression_id: string
  translations: HandbookTranslation[]
}
export interface HandbookTranslations {
  target_locale: string
  items: HandbookTranslationItem[]
}
export async function getHandbookTranslations(
  id: string,
  targetLocale: string,
  hints: LocaleHints = {},
  signal?: AbortSignal,
): Promise<HandbookTranslations> {
  const params: Record<string, string | number> = {
    target_locale: targetLocale,
    _content_revision: contentRevision.value,
  }
  if (hints.ui_locale) params.ui_locale = hints.ui_locale
  if (hints.secondary_ui_locale) params.secondary_ui_locale = hints.secondary_ui_locale
  const { data } = await api.get(`/handbooks/${encodeURIComponent(id)}/translations`, { params, signal })
  return (data as { data: HandbookTranslations }).data
}
