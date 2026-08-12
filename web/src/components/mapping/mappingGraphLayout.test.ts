// @ts-nocheck
import { describe, expect, it } from 'vitest'
import { layoutMappingGraph } from './mappingGraphLayout'
import { buildDisplayTree } from './mappingGraphModel'
import type {
  MappingGraphEdge,
  MappingGraphNode,
  MappingGraphResponse,
} from './mappingGraphTypes'

function makeGraph(
  nodes: MappingGraphNode[],
  edges: MappingGraphEdge[],
): MappingGraphResponse {
  const layer_counts: Record<number, number> = {}
  for (const n of nodes) layer_counts[n.depth] = (layer_counts[n.depth] ?? 0) + 1
  return {
    root_id: 1,
    requested_hops: 3,
    resolved_hops: 3,
    nodes,
    edges,
    layer_counts,
    truncated: false,
    omitted_count: 0,
  }
}

function defaultNodeSize() {
  return { width: 90, height: 36 }
}

function countCollisions(
  layoutNodes: Array<{ x: number; y: number }>,
  sizes: Map<number, { width: number; height: number }>,
  gap: number,
): number {
  let collisions = 0
  for (let i = 0; i < layoutNodes.length; i++) {
    for (let j = i + 1; j < layoutNodes.length; j++) {
      const a = layoutNodes[i]
      const b = layoutNodes[j]
      const sa = sizes.get((a as any).id) ?? defaultNodeSize()
      const sb = sizes.get((b as any).id) ?? defaultNodeSize()
      const dx = Math.abs(a.x - b.x) - (sa.width + sb.width) / 2 - gap
      const dy = Math.abs(a.y - b.y) - (sa.height + sb.height) / 2 - gap
      if (dx < 0 && dy < 0) collisions++
    }
  }
  return collisions
}

describe('layoutMappingGraph', () => {
  it('places the root at (0, 0)', () => {
    const g = makeGraph(
      [
        { expression_id: 1, text: 'root', language_profile_code: 'en', language_name: 'English', depth: 0 },
        { expression_id: 2, text: 'a', language_profile_code: 'en', language_name: 'English', depth: 1 },
      ],
      [{ edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 }],
    )
    const tree = buildDisplayTree(g)
    const sizes = new Map([
      [1, defaultNodeSize()],
      [2, defaultNodeSize()],
    ])
    const out = layoutMappingGraph({ rootId: 1, tree, nodeSizes: sizes })
    const root = out.nodes.find((n) => n.id === 1)
    expect(root?.x).toBeCloseTo(0, 5)
    expect(root?.y).toBeCloseTo(0, 5)
  })

  it('depth-2 radius is larger than depth-1 radius', () => {
    const g = makeGraph(
      [
        { expression_id: 1, text: 'root', language_profile_code: 'en', language_name: 'English', depth: 0 },
        { expression_id: 2, text: 'a', language_profile_code: 'en', language_name: 'English', depth: 1 },
        { expression_id: 3, text: 'b', language_profile_code: 'en', language_name: 'English', depth: 2 },
      ],
      [
        { edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 },
        { edge_id: 'e2-3', source_id: 2, target_id: 3, score: 3, depth: 2 },
      ],
    )
    const tree = buildDisplayTree(g)
    const sizes = new Map([
      [1, defaultNodeSize()],
      [2, defaultNodeSize()],
      [3, defaultNodeSize()],
    ])
    const out = layoutMappingGraph({ rootId: 1, tree, nodeSizes: sizes })
    const d1 = out.nodes.find((n) => n.id === 2)
    const d2 = out.nodes.find((n) => n.id === 3)
    const r1 = Math.hypot(d1!.x, d1!.y)
    const r2 = Math.hypot(d2!.x, d2!.y)
    expect(r2).toBeGreaterThan(r1)
  })

  it('depth-3 radius is larger than depth-2', () => {
    const g = makeGraph(
      [
        { expression_id: 1, text: 'root', language_profile_code: 'en', language_name: 'English', depth: 0 },
        { expression_id: 2, text: 'a', language_profile_code: 'en', language_name: 'English', depth: 1 },
        { expression_id: 3, text: 'b', language_profile_code: 'en', language_name: 'English', depth: 2 },
        { expression_id: 4, text: 'c', language_profile_code: 'en', language_name: 'English', depth: 3 },
      ],
      [
        { edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 },
        { edge_id: 'e2-3', source_id: 2, target_id: 3, score: 3, depth: 2 },
        { edge_id: 'e3-4', source_id: 3, target_id: 4, score: 1, depth: 3 },
      ],
    )
    const tree = buildDisplayTree(g)
    const sizes = new Map([
      [1, defaultNodeSize()],
      [2, defaultNodeSize()],
      [3, defaultNodeSize()],
      [4, defaultNodeSize()],
    ])
    const out = layoutMappingGraph({ rootId: 1, tree, nodeSizes: sizes })
    const r2 = Math.hypot(out.nodes.find((n) => n.id === 2)!.x, out.nodes.find((n) => n.id === 2)!.y)
    const r3 = Math.hypot(out.nodes.find((n) => n.id === 3)!.x, out.nodes.find((n) => n.id === 3)!.y)
    const r4 = Math.hypot(out.nodes.find((n) => n.id === 4)!.x, out.nodes.find((n) => n.id === 4)!.y)
    expect(r3).toBeGreaterThan(r2)
    expect(r4).toBeGreaterThan(r3)
  })

  it('child angle lies within parent sector', () => {
    const g = makeGraph(
      [
        { expression_id: 1, text: 'root', language_profile_code: 'en', language_name: 'English', depth: 0 },
        { expression_id: 2, text: 'a', language_profile_code: 'en', language_name: 'English', depth: 1 },
        { expression_id: 3, text: 'b', language_profile_code: 'en', language_name: 'English', depth: 1 },
        { expression_id: 4, text: 'c', language_profile_code: 'en', language_name: 'English', depth: 2 },
      ],
      [
        { edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 },
        { edge_id: 'e1-3', source_id: 1, target_id: 3, score: 3, depth: 1 },
        { edge_id: 'e2-4', source_id: 2, target_id: 4, score: 1, depth: 2 },
      ],
    )
    const tree = buildDisplayTree(g)
    const sizes = new Map([
      [1, defaultNodeSize()],
      [2, defaultNodeSize()],
      [3, defaultNodeSize()],
      [4, defaultNodeSize()],
    ])
    const out = layoutMappingGraph({ rootId: 1, tree, nodeSizes: sizes })
    const parent = out.nodes.find((n) => n.id === 2)!
    const child = out.nodes.find((n) => n.id === 4)!
    const pAngle = Math.atan2(parent.y, parent.x)
    const cAngle = Math.atan2(child.y, child.x)
    // child should be within +/- pi/2 (90 degrees) of parent angle
    const diff = Math.abs(angleDelta(pAngle, cAngle))
    expect(diff).toBeLessThan(Math.PI / 2 + 0.001)
  })

  it('bounds contain all nodes', () => {
    const g = makeGraph(
      [
        { expression_id: 1, text: 'root', language_profile_code: 'en', language_name: 'English', depth: 0 },
        { expression_id: 2, text: 'a', language_profile_code: 'en', language_name: 'English', depth: 1 },
        { expression_id: 3, text: 'b', language_profile_code: 'en', language_name: 'English', depth: 2 },
      ],
      [
        { edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 },
        { edge_id: 'e2-3', source_id: 2, target_id: 3, score: 3, depth: 2 },
      ],
    )
    const tree = buildDisplayTree(g)
    const sizes = new Map([
      [1, defaultNodeSize()],
      [2, defaultNodeSize()],
      [3, defaultNodeSize()],
    ])
    const out = layoutMappingGraph({ rootId: 1, tree, nodeSizes: sizes })
    for (const n of out.nodes) {
      expect(n.x).toBeGreaterThanOrEqual(out.bounds.x)
      expect(n.x).toBeLessThanOrEqual(out.bounds.x + out.bounds.width)
      expect(n.y).toBeGreaterThanOrEqual(out.bounds.y)
      expect(n.y).toBeLessThanOrEqual(out.bounds.y + out.bounds.height)
    }
  })

  it('produces identical coordinates for identical input', () => {
    const g = makeGraph(
      [
        { expression_id: 1, text: 'root', language_profile_code: 'en', language_name: 'English', depth: 0 },
        { expression_id: 2, text: 'a', language_profile_code: 'en', language_name: 'English', depth: 1 },
        { expression_id: 3, text: 'b', language_profile_code: 'en', language_name: 'English', depth: 1 },
      ],
      [
        { edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 },
        { edge_id: 'e1-3', source_id: 1, target_id: 3, score: 3, depth: 1 },
      ],
    )
    const tree = buildDisplayTree(g)
    const sizes = new Map([
      [1, defaultNodeSize()],
      [2, defaultNodeSize()],
      [3, defaultNodeSize()],
    ])
    const a = layoutMappingGraph({ rootId: 1, tree, nodeSizes: sizes })
    const b = layoutMappingGraph({ rootId: 1, tree, nodeSizes: sizes })
    expect(a.nodes).toEqual(b.nodes)
  })

  it('40 one-hop nodes have zero collisions', () => {
    const nodes: MappingGraphNode[] = [
      { expression_id: 1, text: 'root', language_profile_code: 'en', language_name: 'English', depth: 0 },
    ]
    const edges: MappingGraphEdge[] = []
    for (let i = 2; i <= 41; i++) {
      nodes.push({
        expression_id: i,
        text: `n${i}`,
        language_profile_code: 'en',
        language_name: 'English',
        depth: 1,
      })
      edges.push({
        edge_id: `e1-${i}`,
        source_id: 1,
        target_id: i,
        score: 10 - (i % 5),
        depth: 1,
      })
    }
    const g = makeGraph(nodes, edges)
    const tree = buildDisplayTree(g)
    const sizes = new Map(nodes.map((n) => [n.expression_id, defaultNodeSize()]))
    const out = layoutMappingGraph({ rootId: 1, tree, nodeSizes: sizes })
    const collisions = countCollisions(
      out.nodes.map((n) => ({ x: n.x, y: n.y, id: n.id })),
      sizes,
      12,
    )
    expect(collisions).toBe(0)
  })

  it('uneven 2-hop subtree has zero collisions', () => {
    const nodes: MappingGraphNode[] = [
      { expression_id: 1, text: 'root', language_profile_code: 'en', language_name: 'English', depth: 0 },
    ]
    const edges: MappingGraphEdge[] = []
    let nextId = 2
    // 3 one-hop nodes
    const oneHopIds = []
    for (let i = 0; i < 3; i++) {
      const id = nextId++
      oneHopIds.push(id)
      nodes.push({
        expression_id: id,
        text: `h1-${id}`,
        language_profile_code: 'en',
        language_name: 'English',
        depth: 1,
      })
      edges.push({
        edge_id: `e1-${id}`,
        source_id: 1,
        target_id: id,
        score: 5,
        depth: 1,
      })
    }
    // First one-hop has 15 children, second has 4, third has 8 -> very uneven
    const counts = [15, 4, 8]
    for (let i = 0; i < oneHopIds.length; i++) {
      const parent = oneHopIds[i]
      for (let j = 0; j < counts[i]; j++) {
        const id = nextId++
        nodes.push({
          expression_id: id,
          text: `h2-${id}`,
          language_profile_code: 'en',
          language_name: 'English',
          depth: 2,
        })
        edges.push({
          edge_id: `e${parent}-${id}`,
          source_id: parent,
          target_id: id,
          score: 1,
          depth: 2,
        })
      }
    }
    const g = makeGraph(nodes, edges)
    const tree = buildDisplayTree(g)
    const sizes = new Map(nodes.map((n) => [n.expression_id, defaultNodeSize()]))
    const out = layoutMappingGraph({ rootId: 1, tree, nodeSizes: sizes })
    const collisions = countCollisions(
      out.nodes.map((n) => ({ x: n.x, y: n.y, id: n.id })),
      sizes,
      12,
    )
    expect(collisions).toBe(0)
  })

  it('handles long-text nodes without shrinking bounds', () => {
    const g = makeGraph(
      [
        { expression_id: 1, text: 'root', language_profile_code: 'en', language_name: 'English', depth: 0 },
        { expression_id: 2, text: 'a-very-long-text-node-content-here', language_profile_code: 'en', language_name: 'English', depth: 1 },
        { expression_id: 3, text: 'b', language_profile_code: 'en', language_name: 'English', depth: 1 },
      ],
      [
        { edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 },
        { edge_id: 'e1-3', source_id: 1, target_id: 3, score: 3, depth: 1 },
      ],
    )
    const tree = buildDisplayTree(g)
    const sizes = new Map([
      [1, defaultNodeSize()],
      [2, { width: 240, height: 36 }],
      [3, defaultNodeSize()],
    ])
    const out = layoutMappingGraph({ rootId: 1, tree, nodeSizes: sizes })
    const collisions = countCollisions(
      out.nodes.map((n) => ({ x: n.x, y: n.y, id: n.id })),
      sizes,
      12,
    )
    expect(collisions).toBe(0)
  })
})

function angleDelta(a: number, b: number): number {
  let d = a - b
  while (d > Math.PI) d -= 2 * Math.PI
  while (d < -Math.PI) d += 2 * Math.PI
  return d
}
