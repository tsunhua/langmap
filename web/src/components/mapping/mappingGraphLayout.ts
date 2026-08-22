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

interface TreeNode {
  id: string
  depth: number
  parentId: string | null
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
  const { rootId, tree, nodeSizes, nodeMeta, gap = 12 } = input

  if (tree.nodes.length === 0) {
    return {
      nodes: [],
      treeEdges: [],
      crossEdges: tree.crossEdges,
      bounds: { x: 0, y: 0, width: 0, height: 0 },
    }
  }

  const sizeOf = (id: string): NodeSize => nodeSizes.get(id) ?? { width: 90, height: 36 }
  const diagOf = (id: string): number => {
    const s = sizeOf(id)
    return Math.hypot(s.width, s.height)
  }

  // 1. Build parent->children map and a TreeNode skeleton.
  const nodeById = new Map<string, TreeNode>()
  const childrenOf = new Map<string, string[]>()
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
  // buildDisplayTree already provides the stable language/text order. Keep it
  // here so the angular sectors reflect the user's grouping preference.
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

  // 2. Weight assignment: uniform for first ring, immediate children for deeper.
  //    Keeping depth-1 uniform ensures the first ring stays evenly spaced
  //    when deeper hops are expanded (subtree weight would otherwise
  //    squeeze nodes with few descendants into tiny sectors).
  for (const n of nodeById.values()) {
    n.weight = n.depth <= 1 ? 1 : Math.max(1, n.children.length)
  }

  // 3. Assign angular sectors top-down: root gets full circle.
  // Start at 12 o'clock; with screen coordinates (positive y downward),
  // increasing angles then place siblings clockwise.
  root.sector = { start: -Math.PI / 2, end: (Math.PI * 3) / 2 }
  const assignSectors = (node: TreeNode) => {
    if (node.children.length === 0) return
    const span = node.sector.end - node.sector.start
    const groups: TreeNode[][] = [node.children]
    const totalWeight = node.children.length
    let cursor = node.sector.start
    for (const group of groups) {
      const groupSpan = span * (group.length / totalWeight)
      const childSpan = groupSpan / group.length
      group.forEach((child, index) => {
        child.sector = { start: cursor + childSpan * index, end: cursor + childSpan * (index + 1) }
        assignSectors(child)
      })
      cursor += groupSpan
    }
  }
  assignSectors(root)
  for (const n of nodeById.values()) {
    n.angle = (n.sector.start + n.sector.end) / 2
  }

  // 4. Compute ring radius per depth.
  //    For each depth, size the ring so children fit side-by-side without
  //    excessive overlap. A soft bound caps sector-driven radius growth;
  //    remaining overlap is resolved by collision relaxation + relaxed clamping.
  const maxDepth = Math.max(...tree.nodes.map((n) => n.depth))
  const radii: number[] = new Array(maxDepth + 1).fill(0)
  radii[0] = 0
  const nodesAtDepth: TreeNode[][] = Array.from({ length: maxDepth + 1 }, () => [])
  for (const n of nodeById.values()) nodesAtDepth[n.depth].push(n)

  // A large first ring is better represented by a compact snail spiral than
  // by a huge circle. Grow the radius according to the current circumference
  // so the inner turns have enough room and the outer turns use the canvas.
  const spiralRootPositions = new Map<string, { x: number; y: number }>()
  const spiralRootOrder = new Map<string, number>()
  let spiralRootRadius = 0
  if (root.children.length >= 8) {
    const maxChildDiag = Math.max(...root.children.map((n) => diagOf(n.id)))
    const rootSize = sizeOf(root.id)
    const maxChildSize = root.children.reduce(
      (max, child) => {
        const size = sizeOf(child.id)
        return {
          width: Math.max(max.width, size.width),
          height: Math.max(max.height, size.height),
        }
      },
      { width: 0, height: 0 },
    )
    const rootClearance = Math.hypot(
      (rootSize.width + maxChildSize.width) / 2 + gap,
      (rootSize.height + maxChildSize.height) / 2 + gap,
    )
    // This minimum center distance keeps neighbouring axis-aligned cards
    // apart regardless of the local tangent direction of the spiral.
    const pathSpacing = Math.max(
      rootClearance,
      Math.hypot(maxChildSize.width + gap, maxChildSize.height + gap),
    )
    // Keep consecutive centers at a constant path distance, while leaving a
    // visibly wider radial pitch between neighbouring turns.
    const turnSpacing = maxChildDiag * 1.6 + gap * 2
    const radialPerRadian = turnSpacing / TWO_PI
    let radius = rootClearance
    let angle = -Math.PI / 2
    const maxChildRadius = Math.max(...root.children.map((child, index) => {
      const x = Math.cos(angle) * radius
      const y = Math.sin(angle) * radius
      spiralRootPositions.set(child.id, { x, y })
      spiralRootOrder.set(child.id, index)

      // For an Archimedean spiral r = a + bθ, decreasing Δθ as r grows keeps
      // the actual center-to-center distance stable instead of making outer
      // cards sparse.
      const angleStep = pathSpacing / Math.max(Math.hypot(radius, radialPerRadian), 1)
      radius += radialPerRadian * angleStep
      angle += angleStep
      return Math.hypot(x, y)
    }))
    spiralRootRadius = maxChildRadius + maxChildDiag / 2 + gap
  }

  // Once a graph has more than one hop, the parent sector is useful for
  // ordering but should not limit the child's visual position. Otherwise a
  // large subtree inherits a narrow wedge from its first-hop parent. Put each
  // deeper ring on the full circumference; edges still show the parent-child
  // relationship independently of this display ordering.
  const fullRingNodes = new Set<TreeNode>()
  for (let d = 2; d <= maxDepth; d++) {
    const ringNodes = nodesAtDepth[d]
    if (ringNodes.length === 0) continue
    ringNodes.sort((a, b) => {
      const sectorDelta = a.sector.start - b.sector.start
      if (sectorDelta !== 0) return sectorDelta
      const aText = nodeMeta?.get(a.id)?.text ?? a.id
      const bText = nodeMeta?.get(b.id)?.text ?? b.id
      return String(aText).localeCompare(String(bText)) || String(a.id).localeCompare(String(b.id))
    })
    const angleStep = TWO_PI / ringNodes.length
    ringNodes.forEach((node, index) => {
      node.angle = -Math.PI / 2 + angleStep * index
      fullRingNodes.add(node)
    })
  }

  for (let d = 1; d <= maxDepth; d++) {
    const ringNodes = nodesAtDepth[d]
    if (ringNodes.length === 0) {
      radii[d] = radii[d - 1]
      continue
    }
    ringNodes.sort((a, b) => a.sector.start - b.sector.start)
    const maxDiag = Math.max(...ringNodes.map((n) => diagOf(n.id)))

    // Full-circumference radius: reserve the complete collision gap between
    // neighbouring cards. This is especially important when the final pass
    // is restricted to angular movement on the ring.
    const circumferenceNeeded = ringNodes.reduce((s, n) => {
      const sz = sizeOf(n.id)
      return s + Math.max(sz.width, sz.height) + gap
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
        return s + Math.max(sz.width, sz.height) + gap
      }, 0)
      const r = arcNeeded / span
      if (r > radiusBySector) radiusBySector = r
    }

    const previousDiag = Math.max(...nodesAtDepth[d - 1].map((n) => diagOf(n.id)), 0)
    // Compress adjacent hop rings. Collision resolution can add back only the
    // clearance needed by an actual card, instead of spacing every depth by a
    // full card diameter.
    const radiusByStep = radii[d - 1] + (maxDiag + previousDiag) * 0.25 + gap * 0.25
    const radiusByRootClearance = d === 1
      ? diagOf(root.id) / 2 + maxDiag / 2 + gap
      : 0
    // Soft bound: sector-driven radius cannot exceed a small expansion over
    // the compact ring requirement.
    // This prevents enormous rings when many children occupy a tight sector;
    // remaining overlap is resolved by collision relaxation below.
    const softBound = Math.max(radiusByStep, radiusByCount * 1.1)
    const firstRingNeedsSectorClearance = d === 1 && root.children.length < 8
    radii[d] = firstRingNeedsSectorClearance
      ? Math.max(radiusByCount, radiusBySector, radiusByStep, radiusByRootClearance)
      : Math.max(radiusByCount, Math.min(radiusBySector, softBound), radiusByStep, radiusByRootClearance)
    if (d === 1 && spiralRootRadius > 0) radii[d] = spiralRootRadius
  }
  for (const n of nodeById.values()) n.radius = radii[n.depth]

  // Keep the first hop on the compact root-centred spiral. Deeper hops use
  // their own fixed-radius rings so different depths never interleave.

  // 5. Convert angle+radius to x,y for collision relaxation.
  const toXY = (n: TreeNode) => spiralRootPositions.get(n.id) ?? {
    x: Math.cos(n.angle) * n.radius,
    y: Math.sin(n.angle) * n.radius,
  }

  // Relaxed clamp used inside the collision loop — allows children to drift
  // into neighbouring sectors so collision relaxation can converge without
  // requiring an enormous ring radius.
  const UP_TOLERANCE = 0.4 // radians ≈ 23°
  const clampRelaxed = (node: TreeNode) => {
    for (const c of node.children) {
      if (fullRingNodes.has(c)) {
        clampRelaxed(c)
        continue
      }
      const lo = node.sector.start - UP_TOLERANCE
      const hi = node.sector.end + UP_TOLERANCE
      if (c.angle < lo) c.angle = lo
      if (c.angle > hi) c.angle = hi
      clampRelaxed(c)
    }
  }

  // 6. Collision relaxation: two passes per iteration.
  // Pass A: within each parent's sector, sort children by angle and push apart
  //         any adjacent siblings whose bounding boxes overlap.
  // Pass B: for the small first ring, push overlapping pairs apart along the
  // angular axis, then re-clamp to the parent sector. Deeper rings already
  // use the full circumference and are left evenly distributed.
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
          if (fullRingNodes.has(a) || fullRingNodes.has(b)) continue
          const ov = overlapAmount(a, b)
          if (ov.x > 0 && ov.y > 0) {
            const r = Math.max(a.radius, b.radius, 1)
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
      if (d >= 2 || (d === 1 && root.children.length >= 8)) continue
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
    clampRelaxed(root)
    if (moved === 0) break
  }

  // 7. Final tight clamp to parent sector (minimal tolerance).
  const TOLERANCE = 0.4
  const clampToParent = (node: TreeNode) => {
    for (const c of node.children) {
      if (fullRingNodes.has(c)) {
        clampToParent(c)
        continue
      }
      const lo = node.sector.start - TOLERANCE
      const hi = node.sector.end + TOLERANCE
      if (c.angle < lo) c.angle = lo
      if (c.angle > hi) c.angle = hi
      clampToParent(c)
    }
  }
  clampToParent(root)

  // 8. Resolve actual card-rectangle collisions. Angular spacing is only an
  // initial estimate; long labels need exact width/height checks. Keep every
  // card on its assigned circle/thread while resolving those overlaps so the
  // rings cannot turn into interleaved elliptical clouds.
  const resolvedPositions = new Map<string, { x: number; y: number }>()
  const resolvedAngles = new Map<string, number>()
  const resolvedRadii = new Map<string, number>()
  for (const n of nodeById.values()) {
    const position = toXY(n)
    resolvedPositions.set(n.id, position)
    resolvedAngles.set(n.id, Math.atan2(position.y, position.x))
    resolvedRadii.set(n.id, Math.hypot(position.x, position.y))
  }

  const setResolvedAngle = (node: TreeNode, angle: number) => {
    const radius = resolvedRadii.get(node.id) ?? 0
    resolvedAngles.set(node.id, angle)
    const position = resolvedPositions.get(node.id)
    if (!position || radius === 0) return
    position.x = Math.cos(angle) * radius
    position.y = Math.sin(angle) * radius
  }

  // Keep layout responsive for the 200-node graph. The spiral already gives
  // a strong initial separation; collision relaxation only needs a short
  // bounded pass for long labels and nearby neighbours.
  const COLLISION_ITERATIONS = 80
  for (let iter = 0; iter < COLLISION_ITERATIONS; iter++) {
    let moved = false
    // Nodes are already ordered along the spiral. A card can only overlap
    // nearby spiral neighbours, so avoid the O(n²) all-pairs scan that blocks
    // the browser on a truncated 200-node graph.
    const positioned = [root, ...[...nodeById.values()].filter((node) => node.id !== rootId)]
    for (let i = 0; i < positioned.length; i++) {
      const lastNeighbour = Math.min(positioned.length, i + 4)
      for (let j = i + 1; j < lastNeighbour; j++) {
        const a = positioned[i]
        const b = positioned[j]
        const pa = resolvedPositions.get(a.id)!
        const pb = resolvedPositions.get(b.id)!
        const sa = sizeOf(a.id)
        const sb = sizeOf(b.id)
        const overlapX = (sa.width + sb.width) / 2 + gap - Math.abs(pa.x - pb.x)
        const overlapY = (sa.height + sb.height) / 2 + gap - Math.abs(pa.y - pb.y)
        if (overlapX <= 0 || overlapY <= 0) continue

        const aIsRoot = a.id === rootId
        const bIsRoot = b.id === rootId
        const amount = Math.max(overlapX, overlapY) + 1
        const aIsSpiral = spiralRootPositions.has(a.id)
        const bIsSpiral = spiralRootPositions.has(b.id)
        let moveA = false
        let splitMovement = false
        if (bIsRoot) {
          moveA = !aIsRoot
        } else if (!aIsRoot) {
          // Keep the spiral's earlier center stable when two spiral cards
          // collide. For mixed-depth pairs, preserve the spiral card and move
          // the deeper-ring card instead.
          moveA = aIsSpiral && !bIsSpiral
          if (aIsSpiral && bIsSpiral) {
            moveA = (spiralRootOrder.get(a.id) ?? 0) > (spiralRootOrder.get(b.id) ?? 0)
            splitMovement = true
          } else if (aIsSpiral === bIsSpiral) {
            splitMovement = true
          }
        }
        if (aIsRoot && bIsRoot) continue

        const aAngle = resolvedAngles.get(a.id) ?? Math.atan2(pa.y, pa.x)
        const bAngle = resolvedAngles.get(b.id) ?? Math.atan2(pb.y, pb.x)
        const direction = angularDeltaSigned(aAngle, bAngle) || 1
        const directionSign = Math.sign(direction)
        if (splitMovement) {
          const aRadius = Math.max(resolvedRadii.get(a.id) ?? 0, 1)
          const bRadius = Math.max(resolvedRadii.get(b.id) ?? 0, 1)
          setResolvedAngle(a, aAngle - directionSign * amount / (2 * aRadius))
          setResolvedAngle(b, bAngle + directionSign * amount / (2 * bRadius))
        } else {
          const mover = moveA ? a : b
          const moverAngle = moveA ? aAngle : bAngle
          const moverRadius = Math.max(resolvedRadii.get(mover.id) ?? 0, 1)
          const signedAngle = directionSign * amount / moverRadius * (moveA ? -1 : 1)
          setResolvedAngle(mover, moverAngle + signedAngle)
        }
        moved = true
      }
    }
    if (!moved) break
  }

  // 9. Final x,y + bounds.
  const outNodes: LayoutNode[] = []
  let minX = Infinity
  let minY = Infinity
  let maxX = -Infinity
  let maxY = -Infinity
  for (const n of nodeById.values()) {
    const p = resolvedPositions.get(n.id)!
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
    return String(a.id).localeCompare(String(b.id))
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
