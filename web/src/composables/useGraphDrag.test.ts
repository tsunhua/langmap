import { describe, expect, it } from 'vitest'
import { useGraphDrag } from './useGraphDrag'

describe('useGraphDrag', () => {
  it('positionOverrides starts empty', () => {
    const drag = useGraphDrag()
    expect(drag.positionOverrides.value.size).toBe(0)
  })

  it('applyOverride stores position', () => {
    const drag = useGraphDrag()
    drag.applyOverride('node:1', 100, 200)
    expect(drag.positionOverrides.value.get('node:1')).toEqual({ x: 100, y: 200 })
  })

  it('applyOverride replaces existing', () => {
    const drag = useGraphDrag()
    drag.applyOverride('node:1', 100, 200)
    drag.applyOverride('node:1', 300, 400)
    expect(drag.positionOverrides.value.get('node:1')).toEqual({ x: 300, y: 400 })
  })

  it('removeOverride removes position', () => {
    const drag = useGraphDrag()
    drag.applyOverride('node:1', 100, 200)
    drag.removeOverride('node:1')
    expect(drag.positionOverrides.value.has('node:1')).toBe(false)
  })

  it('resetPositions clears all', () => {
    const drag = useGraphDrag()
    drag.applyOverride('node:1', 100, 200)
    drag.applyOverride('node:2', 300, 400)
    drag.resetPositions()
    expect(drag.positionOverrides.value.size).toBe(0)
  })

  it('getEffectiveX returns override when present', () => {
    const drag = useGraphDrag()
    drag.applyOverride('node:1', 200, 300)
    expect(drag.getEffectiveX('node:1', 100)).toBe(200)
  })

  it('getEffectiveX returns layout when no override', () => {
    const drag = useGraphDrag()
    expect(drag.getEffectiveX('node:1', 100)).toBe(100)
  })

  it('getEffectiveY returns override when present', () => {
    const drag = useGraphDrag()
    drag.applyOverride('node:1', 200, 300)
    expect(drag.getEffectiveY('node:1', 100)).toBe(300)
  })

  it('activeDrag starts null', () => {
    const drag = useGraphDrag()
    expect(drag.activeDrag.value).toBeNull()
  })

  it('setActiveDrag updates drag state', () => {
    const drag = useGraphDrag()
    drag.setActiveDrag({ nodeId: 'node:1', worldX: 150, worldY: 250 })
    expect(drag.activeDrag.value).toEqual({ nodeId: 'node:1', worldX: 150, worldY: 250 })
  })

  it('resetPositions also clears activeDrag', () => {
    const drag = useGraphDrag()
    drag.setActiveDrag({ nodeId: 'node:1', worldX: 150, worldY: 250 })
    drag.resetPositions()
    expect(drag.activeDrag.value).toBeNull()
  })
})
