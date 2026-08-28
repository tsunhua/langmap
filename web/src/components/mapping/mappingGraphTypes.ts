export interface MappingGraphNode {
  expression_id: string
  text: string
  lang_code: string
  language_profile_code?: string | null
  language_name: string | null
  depth: number
}

export interface MappingGraphEdge {
  edge_id: string
  source_id: string
  target_id: string
  score: number
  depth: number
  sources: EdgeSourceMarker[]
}

export interface EdgeSourceMarker {
  source_id: string
  marker: string | null
}

export interface MappingGraphResponse {
  root_id: string
  requested_hops: 1 | 2 | 3
  resolved_hops: 0 | 1 | 2 | 3
  nodes: MappingGraphNode[]
  edges: MappingGraphEdge[]
  layer_counts: Record<number, number>
  truncated: boolean
  omitted_count: number
}

export interface NodeSize {
  width: number
  height: number
}

export interface GraphBounds {
  x: number
  y: number
  width: number
  height: number
}

export interface DisplayGraphNode {
  id: string
  depth: number
  displayParentId: string | null
}

export interface DisplayGraphEdge extends MappingGraphEdge {
  kind: 'tree' | 'cross'
}

export interface DisplayTree {
  nodes: DisplayGraphNode[]
  treeEdges: MappingGraphEdge[]
  crossEdges: MappingGraphEdge[]
}
