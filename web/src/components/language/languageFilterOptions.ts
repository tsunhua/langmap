import type { MappingGraphResponse } from '@/components/mapping/mappingGraphTypes'

export interface LanguageFilterOption {
  code: string
  name: string
  count: number
}

export function buildLanguageFilterOptions(
  graph: MappingGraphResponse | null,
  getName: (code: string) => string,
  maxDepth: number,
): LanguageFilterOption[] {
  if (!graph) return []

  const counts = new Map<string, number>()
  const graphNames = new Map<string, string>()
  const seen = new Set<string>()
  for (const node of graph.nodes) {
    if (node.depth < 1 || node.depth > maxDepth || seen.has(node.expression_id)) continue
    seen.add(node.expression_id)
    counts.set(node.lang_code, (counts.get(node.lang_code) ?? 0) + 1)
    if (node.language_name && node.language_name !== node.lang_code) {
      graphNames.set(node.lang_code, node.language_name)
    }
  }

  return [...counts.entries()]
    .map(([code, count]) => {
      const storeName = getName(code)
      return { code, name: storeName !== code ? storeName : graphNames.get(code) || code, count }
    })
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name) || a.code.localeCompare(b.code))
}
