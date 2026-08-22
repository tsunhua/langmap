import type {
  DisplayTree,
  GraphBounds,
  MappingGraphEdge,
  NodeSize,
} from './mappingGraphTypes'

export interface LayoutNode {
  id: string
  x: number
  y: number
  depth: number
  displayParentId: string | null
}

export interface LayoutOutput {
  nodes: LayoutNode[]
  treeEdges: MappingGraphEdge[]
  crossEdges: MappingGraphEdge[]
  bounds: GraphBounds
}

export interface LayoutInput {
  rootId: string
  tree: DisplayTree
  nodeSizes: ReadonlyMap<string, NodeSize>
  nodeMeta?: ReadonlyMap<string, { language: string; text: string }>
  gap?: number
}

const TWO_PI = Math.PI * 2
const DEFAULT_NODE_SIZE: NodeSize = { width: 90, height: 36 }

interface TreeNode {
  id: string
  depth: number
  parentId: string | null
}

interface PositionedNode {
  id: string
  x: number
  y: number
}

/**
 * Lay the display tree out on one continuous, compact spiral.
 *
 * The old layout calculated one complete ring for every depth. That made a
 * large second hop jump straight to the circumference required by all of its
 * siblings. A single spiral lets the first nodes occupy the small inner turn,
 * then adds subsequent hops to the next available point as the radius grows.
 * The graph edges still preserve the tree relationship; only the placement
 * path is shared by all hops.
 */
export function layoutMappingGraph(input: LayoutInput): LayoutOutput {
  const { rootId, tree, nodeSizes, nodeMeta, gap = 12 } = input

  if (tree.nodes.length === 0) {
    return {
      nodes: [],
      treeEdges: [],
      crossEdges: tree.crossEdges,
      bounds: { x: 0, y: 0, width: 0, height: 0 },
    }
  }

  const sizeOf = (id: string): NodeSize => nodeSizes.get(id) ?? DEFAULT_NODE_SIZE
  const nodeById = new Map<string, TreeNode>()
  const inputOrder = new Map<string, number>()

  for (const [index, node] of tree.nodes.entries()) {
    nodeById.set(node.id, {
      id: node.id,
      depth: node.depth,
      parentId: node.displayParentId,
    })
    inputOrder.set(node.id, index)
  }

  const root = nodeById.get(rootId)
  if (!root) {
    return {
      nodes: [],
      treeEdges: tree.treeEdges,
      crossEdges: tree.crossEdges,
      bounds: { x: 0, y: 0, width: 0, height: 0 },
    }
  }

  const stableOrder = (node: TreeNode): number => inputOrder.get(node.id) ?? Number.MAX_SAFE_INTEGER
  const compareSpiralOrder = (a: TreeNode, b: TreeNode): number => {
    if (a.depth !== b.depth) return a.depth - b.depth

    // buildDisplayTree already supplies a stable BFS order. The metadata and
    // id tie-breakers also keep direct callers deterministic.
    const inputDelta = stableOrder(a) - stableOrder(b)
    if (inputDelta !== 0) return inputDelta
    const aText = nodeMeta?.get(a.id)?.text ?? ''
    const bText = nodeMeta?.get(b.id)?.text ?? ''
    return String(aText).localeCompare(String(bText)) || String(a.id).localeCompare(String(b.id))
  }

  const spiralNodes = [...nodeById.values()]
    .filter((node) => node.id !== rootId)
    .sort(compareSpiralOrder)

  const allSizes = [...nodeById.values()].map((node) => sizeOf(node.id))
  const maxWidth = Math.max(...allSizes.map((size) => size.width), DEFAULT_NODE_SIZE.width)
  const maxHeight = Math.max(...allSizes.map((size) => size.height), DEFAULT_NODE_SIZE.height)
  const rootSize = sizeOf(root.id)
  const firstNodeSize = sizeOf(spiralNodes[0]?.id ?? root.id)

  // Start outside the root's rectangular clearance. The radial pitch only
  // needs to clear a card's height between neighbouring turns; collision
  // checks below handle different card widths and diagonal approaches.
  const innerRadius = Math.hypot(
    (rootSize.width + firstNodeSize.width) / 2 + gap,
    (rootSize.height + firstNodeSize.height) / 2 + gap,
  )
  // A small extra pitch keeps the rectangular cards clear near a turn's
  // diagonal approach, so the spiral does not need to make a large local
  // jump when it encounters the previous turn.
  const turnPitch = Math.max(maxHeight + gap + 4, (maxWidth + gap) * 0.7)
  const radialPerRadian = turnPitch / TWO_PI
  const pathSpacing = Math.max(maxWidth + gap, maxHeight + gap)

  const positions = new Map<string, PositionedNode>()
  const occupied: PositionedNode[] = [{ id: root.id, x: 0, y: 0 }]
  positions.set(root.id, occupied[0])

  const positionAt = (theta: number): PositionedNode => {
    const radius = innerRadius + radialPerRadian * theta
    // Start at twelve o'clock and travel clockwise in screen coordinates.
    const angle = -Math.PI / 2 + theta
    return {
      id: '',
      x: Math.cos(angle) * radius,
      y: Math.sin(angle) * radius,
    }
  }

  const overlaps = (candidate: PositionedNode, size: NodeSize, other: PositionedNode): boolean => {
    const otherSize = sizeOf(other.id)
    return Math.abs(candidate.x - other.x) < (size.width + otherSize.width) / 2 + gap
      && Math.abs(candidate.y - other.y) < (size.height + otherSize.height) / 2 + gap
  }

  const angularStepAt = (theta: number): number => {
    const radius = innerRadius + radialPerRadian * theta
    return Math.max(0.1, pathSpacing / Math.max(Math.hypot(radius, radialPerRadian), 1))
  }

  let theta = 0
  for (const node of spiralNodes) {
    const size = sizeOf(node.id)
    let candidateTheta = theta
    let candidate: PositionedNode
    let attempts = 0

    // A candidate moves forward along the same curve until its complete card
    // rectangle clears every earlier card. This is bounded in normal graphs,
    // but the fallback also guarantees progress for unusually large cards.
    while (true) {
      candidate = { ...positionAt(candidateTheta), id: node.id }
      if (!occupied.some((other) => overlaps(candidate, size, other))) break

      candidateTheta += angularStepAt(candidateTheta) * 0.5
      attempts++
      if (attempts >= 4000) {
        // A pathological card can force many small skips. Move one complete
        // turn outward and keep checking rather than accepting a collision.
        candidateTheta += TWO_PI
        attempts = 0
      }
    }

    positions.set(node.id, candidate)
    occupied.push(candidate)
    // Advance by a full local path step after placing a card. Keeping theta
    // monotonic makes every later hop farther from the root without creating
    // another large per-depth ring.
    theta = candidateTheta + angularStepAt(candidateTheta)
  }

  const outNodes: LayoutNode[] = []
  let minX = Infinity
  let minY = Infinity
  let maxX = -Infinity
  let maxY = -Infinity

  for (const node of nodeById.values()) {
    const position = positions.get(node.id)
    if (!position) continue
    const size = sizeOf(node.id)
    minX = Math.min(minX, position.x - size.width / 2)
    minY = Math.min(minY, position.y - size.height / 2)
    maxX = Math.max(maxX, position.x + size.width / 2)
    maxY = Math.max(maxY, position.y + size.height / 2)
    outNodes.push({
      id: node.id,
      x: position.x,
      y: position.y,
      depth: node.depth,
      displayParentId: node.parentId,
    })
  }

  outNodes.sort((a, b) => a.depth - b.depth || String(a.id).localeCompare(String(b.id)))

  return {
    nodes: outNodes,
    treeEdges: tree.treeEdges,
    crossEdges: tree.crossEdges,
    bounds: {
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY,
    },
  }
}
