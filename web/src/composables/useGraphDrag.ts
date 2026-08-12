import { ref, readonly } from 'vue'

export interface DragState {
  nodeId: string
  worldX: number
  worldY: number
}

export function useGraphDrag() {
  const positionOverrides = ref<Map<string, { x: number; y: number }>>(new Map())
  const activeDrag = ref<DragState | null>(null)

  function applyOverride(nodeId: string, worldX: number, worldY: number) {
    const next = new Map(positionOverrides.value)
    next.set(nodeId, { x: worldX, y: worldY })
    positionOverrides.value = next
  }

  function removeOverride(nodeId: string) {
    const next = new Map(positionOverrides.value)
    next.delete(nodeId)
    positionOverrides.value = next
  }

  function resetPositions() {
    positionOverrides.value = new Map()
    activeDrag.value = null
  }

  function getEffectiveX(nodeId: string, layoutX: number): number {
    const o = positionOverrides.value.get(nodeId)
    return o ? o.x : layoutX
  }

  function getEffectiveY(nodeId: string, layoutY: number): number {
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
