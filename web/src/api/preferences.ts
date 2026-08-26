import api from './client'
export interface LanguageLocalePreference { primary: string; secondary?: string }
export async function getPreferences(): Promise<Record<string, unknown>> { const { data } = await api.get('/preferences'); return data.data ?? {} }
export async function putLanguageLocalePreference(value: LanguageLocalePreference): Promise<LanguageLocalePreference> { const { data } = await api.put('/preferences/language.locales', value); return data.data?.value ?? value }
