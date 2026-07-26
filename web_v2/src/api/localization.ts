import api from './client'

export const LOCALIZATION_PROJECT_ID = 'langmap-web'

export interface UiLocale { code: string; name: string; native_name?: string; direction?: 'ltr' | 'rtl'; status: string; }
export interface UiMessages { locale: string; messages: Record<string, unknown>; source_hash?: string; mapping_revision: number; }
export interface TranslationCandidate {
  edge_id: string | null
  expression_id: number
  text: string
  score: number
  created_at?: string
}
export interface WorkbenchMessage {
  key: string
  description?: string | null
  scope?: string | null
  message_format?: string | null
  source_expression_id: number
  source_text: string
  placeholders_json?: string | null
  candidates: TranslationCandidate[]
}
export interface TranslationWorkbench {
  project_id: string
  locale: string
  coverage: number
  total_keys: number
  translated_keys: number
  messages: WorkbenchMessage[]
}

export async function listUiLocales(projectId = LOCALIZATION_PROJECT_ID): Promise<UiLocale[]> {
  const { data } = await api.get(`/localization/projects/${encodeURIComponent(projectId)}/locales`)
  return data.data?.locales ?? data.data ?? []
}

export async function getUiMessages(code: string, projectId = LOCALIZATION_PROJECT_ID): Promise<UiMessages> {
  const { data } = await api.get(`/localization/projects/${encodeURIComponent(projectId)}/locales/${encodeURIComponent(code)}/messages`)
  return data.data
}

export async function getTranslationWorkbench(code: string, projectId = LOCALIZATION_PROJECT_ID): Promise<TranslationWorkbench> {
  const { data } = await api.get(`/localization/projects/${encodeURIComponent(projectId)}/workbench/${encodeURIComponent(code)}`)
  return data.data
}

export async function submitTranslationMapping(payload: { key: string; locale_code: string; text: string; source_text?: string }, projectId = LOCALIZATION_PROJECT_ID) {
  const { data } = await api.post(`/localization/projects/${encodeURIComponent(projectId)}/mappings`, payload)
  return data.data
}
export async function submitTranslationMappings(mappings: Array<{ key: string; locale_code: string; text: string; source_text?: string }>, projectId = LOCALIZATION_PROJECT_ID) {
  const { data } = await api.post(`/localization/projects/${encodeURIComponent(projectId)}/mappings/batch`, { mappings })
  return data.data
}
export async function addUiLocale(code: string, projectId = LOCALIZATION_PROJECT_ID) {
  const { data } = await api.post(`/localization/projects/${encodeURIComponent(projectId)}/locales`, { code })
  return data.data as UiLocale
}
