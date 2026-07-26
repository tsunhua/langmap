import type {
  DisplayTree,
  GraphBounds,
  MappingGraphEdge,
  NodeSize,
} from './mappingGraphTypes'

export interface LayoutNode {
  id: number
  x: number
  y: number
  depth: number
  displayParentId: number | null
}

export interface LayoutOutput {
  nodes: LayoutNode[]
  treeEdges: MappingGraphEdge[]
  crossEdges: MappingGraphEdge[]
  bounds: GraphBounds
}

export interface LayoutInput {
  rootId: number
  tree: DisplayTree
  nodeSizes: ReadonlyMap<number, NodeSize>
  gap?: number
}

const TWO_PI = Math.PI * 2

interface TreeNode {
  id: number
  depth: number
  parentId: number | null
  children: TreeNode[]
  // assigned sector [angleStart, angleEnd] (radians, [-pi, pi))
  sector: { start: number; end: number }
  // computed angle (centre of sector, may shift during collision fix)
  angle: number
  // computed radius
  radius: number
  // visible leaf count of subtree
  weight: number
}

export function layoutMappingGraph(input: LayoutInput): LayoutOutput {
  const { rootId, tree, nodeSizes, gap = 12 } = input

  if (tree.nodes.length === 0) {
    return {
      nodes: [],
      treeEdges: [],
      crossEdges: tree.crossEdges,
      bounds: { x: 0, y: 0, width: 0, height: 0 },
    }
  }

  const sizeOf = (id: number): NodeSize => nodeSizes.get(id) ?? { width: 90, height: 36 }
  const diagOf = (id: number): number => {
    const s = sizeOf(id)
    return Math.hypot(s.width, s.height)
  }

  // 1. Build parent->children map and a TreeNode skeleton.
  const nodeById = new Map<number, TreeNode>()
  const childrenOf = new Map<number, number[]>()
  for (const n of tree.nodes) {
    nodeById.set(n.id, {
      id: n.id,
      depth: n.depth,
      parentId: n.displayParentId,
      children: [],
      sector: { start: -Math.PI, end: Math.PI },
      angle: 0,
      radius: 0,
      weight: 0,
    })
    childrenOf.set(n.id, [])
  }
  for (const n of tree.nodes) {
    if (n.displayParentId !== null) {
      childrenOf.get(n.displayParentId)?.push(n.id)
    }
  }
  // Sort children stably by id for deterministic sector allocation.
  for (const list of childrenOf.values()) list.sort((a, b) => a - b)
  for (const n of nodeById.values()) {
    const cs = childrenOf.get(n.id) ?? []
    n.children = cs.map((id) => nodeById.get(id)!).filter(Boolean)
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

  // 2. Compute subtree weight (visible leaf count, minimum 1 per node).
  const computeWeight = (node: TreeNode): number => {
    if (node.children.length === 0) {
      node.weight = 1
      return 1
    }
    let sum = 0
    for (const c of node.children) sum += computeWeight(c)
    node.weight = Math.max(1, sum)
    return node.weight
  }
  computeWeight(root)

  // 3. Assign angular sectors top-down: root gets full circle.
  root.sector = { start: -Math.PI, end: Math.PI }
  const assignSectors = (node: TreeNode) => {
    if (node.children.length === 0) return
    const span = node.sector.end - node.sector.start
    const totalWeight = node.children.reduce((s, c) => s + c.weight, 0)
    let cursor = node.sector.start
    for (const c of node.children) {
      const w = c.weight / totalWeight
      c.sector = { start: cursor, end: cursor + span * w }
      cursor = c.sector.end
      assignSectors(c)
    }
  }
  assignSectors(root)
  for (const n of nodeById.values()) {
    n.angle = (n.sector.start + n.sector.end) / 2
  }

  // 4. Compute ring radius per depth.
  //    For each depth, find the parent whose children occupy the tightest
  //    angular sector (children-per-radian) and size the ring so those
  //    children fit side-by-side without overlap. Falls back to the
  //    full-circumference formula when sectors are uniform.
  const maxDepth = Math.max(...tree.nodes.map((n) => n.depth))
  const radii: number[] = new Array(maxDepth + 1).fill(0)
  radii[0] = 0
  const nodesAtDepth: TreeNode[][] = Array.from({ length: maxDepth + 1 }, () => [])
  for (const n of nodeById.values()) nodesAtDepth[n.depth].push(n)
  for (let d = 1; d <= maxDepth; d++) {
    const ringNodes = nodesAtDepth[d]
    if (ringNodes.length === 0) {
      radii[d] = radii[d - 1]
      continue
    }
    ringNodes.sort((a, b) => a.sector.start - b.sector.start)
    const maxDiag = Math.max(...ringNodes.map((n) => diagOf(n.id)))

    // Full-circumference radius: assumes uniform spread around 2π.
    const circumferenceNeeded = ringNodes.reduce((s, n) => {
      const sz = sizeOf(n.id)
      return s + Math.hypot(sz.width, sz.height) + gap
    }, 0)
    const radiusByCount = circumferenceNeeded / TWO_PI

    // Tightest-sector radius: for each parent, sum child widths+gap and divide
    // by that parent's sector span. Take the max across all parents at this depth.
    let radiusBySector = 0
    const parentsAtPrevDepth = nodesAtDepth[d - 1].filter((p) => p.children.length > 0)
    for (const parent of parentsAtPrevDepth) {
      const span = parent.sector.end - parent.sector.start
      if (span <= 0) continue
      const arcNeeded = parent.children.reduce((s, c) => {
        const sz = sizeOf(c.id)
        // Use the larger of width (tangential) and a min spacing.
        return s + Math.max(sz.width, sz.height) + gap
      }, 0)
      const r = arcNeeded / span
      if (r > radiusBySector) radiusBySector = r
    }

    const radiusByStep = radii[d - 1] + maxDiag + gap * 2
    radii[d] = Math.max(radiusByCount, radiusBySector, radiusByStep)
  }
  for (const n of nodeById.values()) n.radius = radii[n.depth]

  // 5. Convert angle+radius to x,y for collision relaxation.
  const toXY = (n: TreeNode) => ({
    x: Math.cos(n.angle) * n.radius,
    y: Math.sin(n.angle) * n.radius,
  })

  // Helper used both inside the relaxation loop and at the end.
  const clampToParentRaw = (node: TreeNode) => {
    for (const c of node.children) {
      if (c.angle < node.sector.start) c.angle = node.sector.start
      if (c.angle > node.sector.end) c.angle = node.sector.end
      clampToParentRaw(c)
    }
  }

  // 6. Collision relaxation: two passes per iteration.
  // Pass A: within each parent's sector, sort children by angle and push apart
  //         any adjacent siblings whose bounding boxes overlap.
  // Pass B: across the full ring, push overlapping pairs apart along the
  //         angular axis, then re-clamp to parent sector.
  const overlapAmount = (a: TreeNode, b: TreeNode): { x: number; y: number } => {
    const aPos = toXY(a)
    const bPos = toXY(b)
    const sa = sizeOf(a.id)
    const sb = sizeOf(b.id)
    const dx = (sa.width + sb.width) / 2 + gap - Math.abs(aPos.x - bPos.x)
    const dy = (sa.height + sb.height) / 2 + gap - Math.abs(aPos.y - bPos.y)
    return { x: dx, y: dy }
  }
  const ITERATIONS = 60
  for (let iter = 0; iter < ITERATIONS; iter++) {
    let moved = 0
    // Pass A: within-sector sibling spacing based on real bbox overlap.
    const walk = (node: TreeNode) => {
      if (node.children.length >= 2) {
        const cs = node.children.slice().sort((a, b) => a.angle - b.angle)
        for (let i = 0; i < cs.length - 1; i++) {
          const a = cs[i]
          const b = cs[i + 1]
          const ov = overlapAmount(a, b)
          if (ov.x > 0 && ov.y > 0) {
            const r = Math.max(a.radius, b.radius, 1)
            // Push apart by the amount needed to clear the larger overlap dimension,
            // converted to angular displacement at this ring radius.
            const pushPx = Math.max(ov.x, ov.y)
            const da = (pushPx / r) * 0.6
            a.angle -= da
            b.angle += da
            moved++
          }
        }
      }
      for (const c of node.children) walk(c)
    }
    walk(root)
    // Pass B: ring-wise pairwise push (handles cross-parent neighbours on the same ring).
    for (let d = 1; d <= maxDepth; d++) {
      const ring = nodesAtDepth[d].slice().sort((a, b) => a.angle - b.angle)
      if (ring.length < 2) continue
      for (let i = 0; i < ring.length; i++) {
        const a = ring[i]
        const b = ring[(i + 1) % ring.length]
        const ov = overlapAmount(a, b)
        if (ov.x > 0 && ov.y > 0) {
          const dirSign = angularDeltaSigned(a.angle, b.angle) || 1
          const r = Math.max(a.radius, b.radius, 1)
          const push = Math.min(ov.x, ov.y) * 0.4
          const da = push / r
          if (dirSign >= 0) {
            a.angle -= da
            b.angle += da
          } else {
            a.angle += da
            b.angle -= da
          }
          moved++
        }
      }
    }
    // Re-clamp to parent sector each iteration so cross-ring pushes don't drift.
    clampToParentRaw(root)
    if (moved === 0) break
  }

  // 7. Final tolerance-clamped clamp to parent sector.
  const TOLERANCE = 0.02
  const clampToParent = (node: TreeNode) => {
    for (const c of node.children) {
      const lo = node.sector.start - TOLERANCE
      const hi = node.sector.end + TOLERANCE
      if (c.angle < lo) c.angle = lo
      if (c.angle > hi) c.angle = hi
      clampToParent(c)
    }
  }
  clampToParent(root)

  // 8. Final x,y + bounds.
  const outNodes: LayoutNode[] = []
  let minX = Infinity
  let minY = Infinity
  let maxX = -Infinity
  let maxY = -Infinity
  for (const n of nodeById.values()) {
    const p = toXY(n)
    const s = sizeOf(n.id)
    minX = Math.min(minX, p.x - s.width / 2)
    minY = Math.min(minY, p.y - s.height / 2)
    maxX = Math.max(maxX, p.x + s.width / 2)
    maxY = Math.max(maxY, p.y + s.height / 2)
    outNodes.push({
      id: n.id,
      x: p.x,
      y: p.y,
      depth: n.depth,
      displayParentId: n.parentId,
    })
  }
  const bounds: GraphBounds = {
    x: minX,
    y: minY,
    width: maxX - minX,
    height: maxY - minY,
  }
  outNodes.sort((a, b) => {
    if (a.depth !== b.depth) return a.depth - b.depth
    return a.id - b.id
  })

  return {
    nodes: outNodes,
    treeEdges: tree.treeEdges,
    crossEdges: tree.crossEdges,
    bounds,
  }
}

function angularDeltaSigned(a: number, b: number): number {
  let d = b - a
  while (d > Math.PI) d -= TWO_PI
  while (d < -Math.PI) d += TWO_PI
  return d
}
