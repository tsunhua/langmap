import api from './client'

export interface RegistryLanguage { code: string; name?: string; name_en?: string; direction?: 'ltr' | 'rtl'; }
export async function listRegistryLanguages(search = ''): Promise<RegistryLanguage[]> {
  const { data } = await api.get('/languages', { params: { q: search, sort: 'alpha', limit: 100 } })
  return data.data?.items ?? []
}
