import { describe, expect, it } from 'vitest'
import { buildLanguageFilterOptions } from './languageFilterOptions'

const graph = (nodes: Array<{ expression_id: string; lang_code: string; depth: number }>) => ({
  root_id: 'root', requested_hops: 3 as const, resolved_hops: 3 as const,
  nodes: nodes.map((node) => ({ ...node, text: node.expression_id, language_name: node.lang_code })),
  edges: [], layer_counts: { 0: 1, 1: 0, 2: 0, 3: 0 }, truncated: false, omitted_count: 0,
})

describe('buildLanguageFilterOptions', () => {
  it('counts only unique non-root nodes through the current hop and sorts deterministically', () => {
    const result = buildLanguageFilterOptions(graph([
      { expression_id: 'root', lang_code: 'eng', depth: 0 },
      { expression_id: 'a', lang_code: 'jpn', depth: 1 },
      { expression_id: 'b', lang_code: 'eng', depth: 1 },
      { expression_id: 'c', lang_code: 'jpn', depth: 2 },
      { expression_id: 'd', lang_code: 'cmn', depth: 3 },
      { expression_id: 'e', lang_code: 'nan', depth: 4 },
    ]), (code) => ({ eng: 'English', cmn: 'Mandarin', jpn: 'Japanese', nan: 'Taiwanese' }[code] ?? code), 3)

    expect(result).toEqual([
      { code: 'jpn', name: 'Japanese', count: 2 },
      { code: 'eng', name: 'English', count: 1 },
      { code: 'cmn', name: 'Mandarin', count: 1 },
    ])
  })

  it('uses code as the final stable tie breaker', () => {
    const result = buildLanguageFilterOptions(graph([
      { expression_id: 'root', lang_code: 'eng', depth: 0 },
      { expression_id: 'a', lang_code: 'zxx', depth: 1 },
      { expression_id: 'b', lang_code: 'abc', depth: 1 },
    ]), () => 'Same', 1)

    expect(result.map((option) => option.code)).toEqual(['abc', 'zxx'])
  })

  it('does not count duplicate expression nodes', () => {
    const result = buildLanguageFilterOptions(graph([
      { expression_id: 'root', lang_code: 'eng', depth: 0 },
      { expression_id: 'a', lang_code: 'jpn', depth: 1 },
      { expression_id: 'a', lang_code: 'jpn', depth: 2 },
    ]), (code) => code, 2)

    expect(result).toEqual([{ code: 'jpn', name: 'jpn', count: 1 }])
  })

  it('falls back to names carried by the graph when the language store has no name', () => {
    const value = graph([
      { expression_id: 'root', lang_code: 'eng', depth: 0 },
      { expression_id: 'a', lang_code: 'hak', depth: 1 },
    ])
    value.nodes[1].language_name = 'Hakka Chinese'

    expect(buildLanguageFilterOptions(value, (code) => code, 1)).toEqual([
      { code: 'hak', name: 'Hakka Chinese', count: 1 },
    ])
  })
})
