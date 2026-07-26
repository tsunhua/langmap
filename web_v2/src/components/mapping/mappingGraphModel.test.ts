import { describe, expect, it } from 'vitest'
import { getPrimaryIncomingEdge } from './mappingGraphModel'
import type { MappingGraphResponse } from './mappingGraphTypes'

function makeGraph(): MappingGraphResponse {
  return {
    root_id: 1,
    requested_hops: 2,
    resolved_hops: 2,
    nodes: [
      { expression_id: 1, text: 'root', language_code: 'en', language_name: 'English', depth: 0 },
      { expression_id: 2, text: 'a', language_code: 'en', language_name: 'English', depth: 1 },
      { expression_id: 3, text: 'b', language_code: 'en', language_name: 'English', depth: 1 },
      { expression_id: 4, text: 'c', language_code: 'en', language_name: 'English', depth: 2 },
    ],
    edges: [
      { edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 },
      { edge_id: 'e1-3', source_id: 1, target_id: 3, score: 3, depth: 1 },
      { edge_id: 'e2-4', source_id: 2, target_id: 4, score: 4, depth: 2 },
      { edge_id: 'e3-4', source_id: 3, target_id: 4, score: 1, depth: 2 },
    ],
    layer_counts: { 0: 1, 1: 2, 2: 1 },
    truncated: false,
    omitted_count: 0,
  }
}

describe('getPrimaryIncomingEdge', () => {
  it('returns null for root node', () => {
    expect(getPrimaryIncomingEdge(1, makeGraph())).toBeNull()
  })

  it('picks the shallower-source edge for a node with two parents', () => {
    const g = makeGraph()
    const primary = getPrimaryIncomingEdge(4, g)
    expect(primary).not.toBeNull()
    expect(primary!.edge_id).toBe('e2-4')
    expect(primary!.source_id).toBe(2)
    expect(primary!.score).toBe(4)
  })

  it('returns the sole edge for a 1-hop node', () => {
    const g = makeGraph()
    const primary = getPrimaryIncomingEdge(2, g)
    expect(primary!.edge_id).toBe('e1-2')
  })

  it('returns null when the node has no edges', () => {
    const g = makeGraph()
    expect(getPrimaryIncomingEdge(999, g)).toBeNull()
  })
})
