import api from './client'

export const LOCALIZATION_PROJECT_ID = 'langmap-web'
export interface UiLocale { language_locale_code: string; name: string; name_en: string; direction: 'ltr' | 'rtl'; status: 'draft' | 'active' | 'archived'; mapping_revision: number; activation_source: 'system' | 'auto' | 'manual' | null }
export interface ResolvedMessage { key: string; text: string; resolved_from: 'primary' | 'secondary' | 'source' }
export interface TranslationCandidate { edge_id: string | null; expression_id: string; text: string; score: number }
export interface WorkbenchMessage { key: string; source_text: string; candidates: TranslationCandidate[] }
export interface TranslationWorkbench { locale: UiLocale; coverage: { coverage: number; translated: number; total: number }; messages: WorkbenchMessage[]; total: number; skip: number; limit: number }
const path = (suffix: string) => `/localization/projects/${LOCALIZATION_PROJECT_ID}${suffix}`
export async function listUiLocales(): Promise<UiLocale[]> { const { data } = await api.get(path('/locales')); return data.data ?? [] }
export async function getUiMessages(preferences: { primary?: string; secondary?: string } = {}): Promise<ResolvedMessage[]> { const params = Object.fromEntries(Object.entries(preferences).filter(([, value]) => value)); const { data } = await api.get(path('/messages'), { params }); return data.data?.messages ?? [] }
export async function getTranslationWorkbench(code: string): Promise<TranslationWorkbench> { const { data } = await api.get(path(`/workbench/${encodeURIComponent(code)}`)); return data.data }
export async function addUiLocale(language_locale_code: string): Promise<UiLocale> { const { data } = await api.post(path('/locales'), { language_locale_code }); return data.data }
export async function submitTranslationMapping(input: { message_key: string; target_expression_id: string }) { const { data } = await api.post(path('/mappings'), input); return data.data }
export async function activateUiLocale(code: string) { const { data } = await api.post(path(`/locales/${encodeURIComponent(code)}/activate`)); return data.data }
export async function archiveUiLocale(code: string) { const { data } = await api.post(path(`/locales/${encodeURIComponent(code)}/archive`)); return data.data }
