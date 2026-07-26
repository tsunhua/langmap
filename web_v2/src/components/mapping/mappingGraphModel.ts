import type {
  DisplayTree,
  MappingGraphEdge,
  MappingGraphResponse,
} from './mappingGraphTypes'

const NODE_DEPTH_KEY = (id: number) => `d:${id}`

export function getPrimaryIncomingEdge(
  nodeId: number,
  graph: MappingGraphResponse,
): MappingGraphEdge | null {
  if (nodeId === graph.root_id) return null

  const incoming = graph.edges.filter(
    (e) => e.source_id === nodeId || e.target_id === nodeId,
  )
  if (incoming.length === 0) return null

  const depthOf = (id: number): number => {
    const n = graph.nodes.find((x) => x.expression_id === id)
    return n ? n.depth : Number.POSITIVE_INFINITY
  }

  incoming.sort((a, b) => {
    const aOther = a.source_id === nodeId ? a.target_id : a.source_id
    const bOther = b.source_id === nodeId ? b.target_id : b.source_id
    const aDepth = depthOf(aOther)
    const bDepth = depthOf(bOther)
    if (aDepth !== bDepth) return aDepth - bDepth
    if (b.score !== a.score) return b.score - a.score
    return a.edge_id.localeCompare(b.edge_id)
  })

  return incoming[0]
}

export function getDepthOf(nodeId: number, graph: MappingGraphResponse): number {
  return graph.nodes.find((n) => n.expression_id === nodeId)?.depth ?? -1
}

export function getNeighborsOf(
  nodeId: number,
  graph: MappingGraphResponse,
): number[] {
  const out: number[] = []
  for (const e of graph.edges) {
    if (e.source_id === nodeId) out.push(e.target_id)
    else if (e.target_id === nodeId) out.push(e.source_id)
  }
  return out
}

export function buildDisplayTree(
  graph: MappingGraphResponse,
  collapsedIds: ReadonlySet<number> = new Set(),
): DisplayTree {
  const depthOf = new Map<number, number>()
  for (const n of graph.nodes) depthOf.set(n.expression_id, n.depth)

  const adj = new Map<number, number[]>()
  for (const n of graph.nodes) adj.set(n.expression_id, [])
  for (const e of graph.edges) {
    adj.get(e.source_id)?.push(e.target_id)
    adj.get(e.target_id)?.push(e.source_id)
  }

  for (const list of adj.values()) {
    list.sort((a, b) => {
      const da = depthOf.get(a) ?? Number.POSITIVE_INFINITY
      const db = depthOf.get(b) ?? Number.POSITIVE_INFINITY
      if (da !== db) return da - db
      return a - b
    })
  }

  const nodes: DisplayTree['nodes'] = []
  const treeEdgesMap = new Map<string, MappingGraphEdge>()
  const crossEdges: MappingGraphEdge[] = []

  const displayParent = new Map<number, number | null>()
  const visited = new Set<number>()
  const queue: number[] = []

  if (!adj.has(graph.root_id)) {
    return { nodes: [], treeEdges: [], crossEdges: [] }
  }

  displayParent.set(graph.root_id, null)
  visited.add(graph.root_id)
  queue.push(graph.root_id)

  const edgeById = new Map(graph.edges.map((e) => [e.edge_id, e]))

  while (queue.length > 0) {
    const current = queue.shift()!
    const isCollapsed = collapsedIds.has(current)

    nodes.push({
      id: current,
      depth: depthOf.get(current) ?? 0,
      displayParentId: displayParent.get(current) ?? null,
    })

    if (isCollapsed) continue

    const neighbors = adj.get(current) ?? []
    for (const nb of neighbors) {
      if (nb === graph.root_id) continue
      if (visited.has(nb)) continue

      visited.add(nb)
      displayParent.set(nb, current)
      queue.push(nb)

      const e = findEdgeBetween(edgeById, current, nb)
      if (e) treeEdgesMap.set(e.edge_id, e)
    }
  }

  const inTreeOrDescendant = (id: number): boolean => {
    if (!visited.has(id)) return false
    return true
  }

  for (const e of graph.edges) {
    if (treeEdgesMap.has(e.edge_id)) continue
    if (!inTreeOrDescendant(e.source_id)) continue
    if (!inTreeOrDescendant(e.target_id)) continue
    crossEdges.push(e)
  }

  crossEdges.sort((a, b) => {
    if (a.depth !== b.depth) return a.depth - b.depth
    if (a.source_id !== b.source_id) return a.source_id - b.source_id
    if (a.target_id !== b.target_id) return a.target_id - b.target_id
    return a.edge_id.localeCompare(b.edge_id)
  })

  const treeEdges = [...treeEdgesMap.values()].sort((a, b) => {
    if (a.depth !== b.depth) return a.depth - b.depth
    if (a.source_id !== b.source_id) return a.source_id - b.source_id
    if (a.target_id !== b.target_id) return a.target_id - b.target_id
    return a.edge_id.localeCompare(b.edge_id)
  })

  void NODE_DEPTH_KEY
  return { nodes, treeEdges, crossEdges }
}

function findEdgeBetween(
  edgeById: Map<string, MappingGraphEdge>,
  a: number,
  b: number,
): MappingGraphEdge | undefined {
  for (const e of edgeById.values()) {
    if (
      (e.source_id === a && e.target_id === b) ||
      (e.source_id === b && e.target_id === a)
    ) {
      return e
    }
  }
  return undefined
}
