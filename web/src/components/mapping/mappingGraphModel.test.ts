import { describe, expect, it } from 'vitest'
import { buildDisplayTree, getPrimaryIncomingEdge, getPathToRoot, getRelatedCrossEdges } from './mappingGraphModel'
import type { MappingGraphResponse } from './mappingGraphTypes'

function graphFrom(
  nodes: Array<[number, number, string?]>,
  edges: Array<[string, number, number, number]>,
): MappingGraphResponse {
  return {
    root_id: 1,
    requested_hops: 3,
    resolved_hops: 3,
    nodes: nodes.map(([id, depth, text = `t${id}`]) => ({
      expression_id: id,
      text,
      language_profile_code: 'en',
      language_name: 'English',
      depth,
    })),
    edges: edges.map(([edge_id, a, b, score]) => ({
      edge_id,
      source_id: a,
      target_id: b,
      score,
      depth: Math.max(
        nodes.find((n) => n[0] === a)![1],
        nodes.find((n) => n[0] === b)![1],
      ),
    })),
    layer_counts: nodes.reduce<Record<number, number>>((acc, [, d]) => {
      acc[d] = (acc[d] ?? 0) + 1
      return acc
    }, {}),
    truncated: false,
    omitted_count: 0,
  }
}

describe('buildDisplayTree', () => {
  it('root has no parent', () => {
    const g = graphFrom([[1, 0]], [])
    const tree = buildDisplayTree(g)
    const root = tree.nodes.find((n) => n.id === 1)
    expect(root?.displayParentId).toBeNull()
  })

  it('every non-root visible node has exactly one displayParentId', () => {
    const g = graphFrom(
      [
        [1, 0], [2, 1], [3, 1], [4, 2], [5, 2],
      ],
      [
        ['e1-2', 1, 2, 5],
        ['e1-3', 1, 3, 4],
        ['e2-4', 2, 4, 3],
        ['e3-5', 3, 5, 2],
      ],
    )
    const tree = buildDisplayTree(g)
    const nonRoot = tree.nodes.filter((n) => n.id !== 1)
    for (const n of nonRoot) {
      expect(n.displayParentId).not.toBeNull()
    }
    expect(nonRoot.length).toBe(4)
  })

  it('first BFS parent wins, others become cross edges', () => {
    // Node 4 connected from both node 2 (depth 1) and node 3 (depth 1).
    // BFS visits node 2 before node 3 (lower id), so displayParent(4) = 2.
    const g = graphFrom(
      [[1, 0], [2, 1], [3, 1], [4, 2]],
      [
        ['e1-2', 1, 2, 10],
        ['e1-3', 1, 3, 8],
        ['e2-4', 2, 4, 4],
        ['e3-4', 3, 4, 6],
      ],
    )
    const tree = buildDisplayTree(g)
    const n4 = tree.nodes.find((n) => n.id === 4)
    expect(n4?.displayParentId).toBe(2)
    expect(tree.treeEdges.map((e) => e.edge_id).sort()).toEqual(['e1-2', 'e1-3', 'e2-4'])
    expect(tree.crossEdges.map((e) => e.edge_id)).toEqual(['e3-4'])
  })

  it('collapsed node hides its descendants from visible nodes', () => {
    const g = graphFrom(
      [[1, 0], [2, 1], [3, 2], [4, 3]],
      [
        ['e1-2', 1, 2, 1],
        ['e2-3', 2, 3, 1],
        ['e3-4', 3, 4, 1],
      ],
    )
    const tree = buildDisplayTree(g, new Set([2]))
    const ids = tree.nodes.map((n) => n.id)
    expect(ids).toContain(1)
    expect(ids).toContain(2)
    expect(ids).not.toContain(3)
    expect(ids).not.toContain(4)
  })

  it('produces identical parent results for reshuffled edge input', () => {
    const baseEdges: Array<[string, number, number, number]> = [
      ['e1-2', 1, 2, 9],
      ['e1-3', 1, 3, 7],
      ['e1-4', 1, 4, 5],
      ['e3-5', 3, 5, 3],
      ['e2-5', 2, 5, 1],
    ]
    const baseNodes: Array<[number, number, string?]> = [
      [1, 0], [2, 1], [3, 1], [4, 1], [5, 2],
    ]
    const a = buildDisplayTree(graphFrom(baseNodes, baseEdges))
    const b = buildDisplayTree(graphFrom(baseNodes, [...baseEdges].reverse()))
    expect(a.nodes.map((n) => [n.id, n.displayParentId])).toEqual(
      b.nodes.map((n) => [n.id, n.displayParentId]),
    )
    expect(a.treeEdges).toEqual(b.treeEdges)
    expect(a.crossEdges).toEqual(b.crossEdges)
  })

  it('handles cycle without duplicating nodes', () => {
    const g = graphFrom(
      [[1, 0], [2, 1], [3, 1]],
      [
        ['e1-2', 1, 2, 1],
        ['e2-3', 2, 3, 1],
        ['e3-1', 3, 1, 1],
      ],
    )
    const tree = buildDisplayTree(g)
    expect(tree.nodes.map((n) => n.id).sort((x, y) => x - y)).toEqual([1, 2, 3])
  })
})

describe('getPathToRoot', () => {
  it('returns [rootId] for root node', () => {
    const tree = buildDisplayTree(graphFrom([[1, 0]], []))
    expect(getPathToRoot(1, tree)).toEqual([1])
  })

  it('returns path from node up to root', () => {
    const g = graphFrom(
      [[1, 0], [2, 1], [3, 2]],
      [['e1-2', 1, 2, 5], ['e2-3', 2, 3, 4]],
    )
    const tree = buildDisplayTree(g)
    expect(getPathToRoot(3, tree)).toEqual([3, 2, 1])
  })

  it('returns correct path for depth-1 node', () => {
    const g = graphFrom(
      [[1, 0], [2, 1]],
      [['e1-2', 1, 2, 5]],
    )
    const tree = buildDisplayTree(g)
    expect(getPathToRoot(2, tree)).toEqual([2, 1])
  })

  it('returns [nodeId] when node not in tree', () => {
    const tree = buildDisplayTree(graphFrom([[1, 0]], []))
    expect(getPathToRoot(999, tree)).toEqual([999])
  })
})

describe('getRelatedCrossEdges', () => {
  it('returns empty array when no cross edges', () => {
    const g = graphFrom(
      [[1, 0], [2, 1]],
      [['e1-2', 1, 2, 5]],
    )
    const tree = buildDisplayTree(g)
    expect(getRelatedCrossEdges(2, tree)).toEqual([])
  })

  it('finds cross edges connected to the node', () => {
    const g = graphFrom(
      [[1, 0], [2, 1], [3, 1], [4, 2]],
      [
        ['e1-2', 1, 2, 10],
        ['e1-3', 1, 3, 8],
        ['e2-4', 2, 4, 4],
        ['e3-4', 3, 4, 6],
      ],
    )
    const tree = buildDisplayTree(g)
    const edges = getRelatedCrossEdges(4, tree)
    expect(edges.map((e) => e.edge_id)).toEqual(['e3-4'])
  })
})

describe('getPrimaryIncomingEdge', () => {
  it('returns null for root node', () => {
    const g = graphFrom(
      [[1, 0], [2, 1]],
      [['e1-2', 1, 2, 5]],
    )
    expect(getPrimaryIncomingEdge(1, g)).toBeNull()
  })

  it('picks the higher-score edge for a node with two same-depth parents', () => {
    const g = graphFrom(
      [[1, 0], [2, 1], [3, 1], [4, 2]],
      [
        ['e1-2', 1, 2, 10],
        ['e1-3', 1, 3, 8],
        ['e2-4', 2, 4, 4],
        ['e3-4', 3, 4, 6],
      ],
    )
    const primary = getPrimaryIncomingEdge(4, g)
    // Both parents at depth 1; higher score wins -> e3-4 (score 6 > 4).
    expect(primary!.edge_id).toBe('e3-4')
  })

  it('returns null when the node has no edges', () => {
    const g = graphFrom([[1, 0]], [])
    expect(getPrimaryIncomingEdge(999, g)).toBeNull()
  })
})
