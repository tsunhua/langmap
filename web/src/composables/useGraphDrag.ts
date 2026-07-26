import { ref, readonly } from 'vue'

export interface DragState {
  nodeId: number
  worldX: number
  worldY: number
}

export function useGraphDrag() {
  const positionOverrides = ref<Map<number, { x: number; y: number }>>(new Map())
  const activeDrag = ref<DragState | null>(null)

  function applyOverride(nodeId: number, worldX: number, worldY: number) {
    const next = new Map(positionOverrides.value)
    next.set(nodeId, { x: worldX, y: worldY })
    positionOverrides.value = next
  }

  function removeOverride(nodeId: number) {
    const next = new Map(positionOverrides.value)
    next.delete(nodeId)
    positionOverrides.value = next
  }

  function resetPositions() {
    positionOverrides.value = new Map()
    activeDrag.value = null
  }

  function getEffectiveX(nodeId: number, layoutX: number): number {
    const o = positionOverrides.value.get(nodeId)
    return o ? o.x : layoutX
  }

  function getEffectiveY(nodeId: number, layoutY: number): number {
    const o = positionOverrides.value.get(nodeId)
    return o ? o.y : layoutY
  }

  return {
    positionOverrides: readonly(positionOverrides),
    activeDrag: readonly(activeDrag),
    applyOverride,
    removeOverride,
    resetPositions,
    getEffectiveX,
    getEffectiveY,
    setActiveDrag: (s: DragState | null) => { activeDrag.value = s },
  }
}
