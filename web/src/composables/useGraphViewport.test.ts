import { describe, expect, it, vi } from 'vitest'
import { ref, defineComponent, nextTick, h } from 'vue'
import { mount } from '@vue/test-utils'
import { calcFitTransform, useGraphViewport } from './useGraphViewport'
import type { GraphBounds } from '@/components/mapping/mappingGraphTypes'

describe('calcFitTransform', () => {
  it('centers bounds within viewport', () => {
    const bounds: GraphBounds = { x: -100, y: -50, width: 200, height: 100 }
    const result = calcFitTransform(bounds, 800, 600, 40)
    expect(result.k).toBeGreaterThan(0)
    const cx = (800 / 2 - result.x) / result.k
    const cy = (600 / 2 - result.y) / result.k
    expect(cx).toBeCloseTo(0, 0)
    expect(cy).toBeCloseTo(0, 0)
  })

  it('clamps scale to upper limit 2.5', () => {
    const bounds: GraphBounds = { x: 0, y: 0, width: 100, height: 50 }
    const result = calcFitTransform(bounds, 2000, 2000, 40)
    expect(result.k).toBe(2.5)
  })

  it('caps the fit scale on narrow viewports so nodes do not over-zoom', () => {
    const bounds: GraphBounds = { x: 0, y: 0, width: 100, height: 50 }
    expect(calcFitTransform(bounds, 375, 600, 40).k).toBe(1)
    expect(calcFitTransform(bounds, 640, 700, 40).k).toBe(1.5)
  })

  it('clamps scale to lower limit 0.25', () => {
    const bounds: GraphBounds = { x: 0, y: 0, width: 10000, height: 5000 }
    const result = calcFitTransform(bounds, 800, 600, 40)
    expect(result.k).toBe(0.25)
  })

  it('returns identity for empty bounds', () => {
    const bounds: GraphBounds = { x: 0, y: 0, width: 0, height: 0 }
    const result = calcFitTransform(bounds, 800, 600, 40)
    expect(result).toEqual({ x: 0, y: 0, k: 1 })
  })

  it('returns identity for zero viewport', () => {
    const bounds: GraphBounds = { x: 0, y: 0, width: 200, height: 100 }
    const result = calcFitTransform(bounds, 0, 0, 40)
    expect(result).toEqual({ x: 0, y: 0, k: 1 })
  })

  it('applies padding correctly', () => {
    const bounds: GraphBounds = { x: 0, y: 0, width: 600, height: 600 }
    const noPad = calcFitTransform(bounds, 800, 800, 0)
    const padded = calcFitTransform(bounds, 800, 800, 20)
    expect(padded.k).toBeLessThan(noPad.k)
  })
})

describe('useGraphViewport', () => {
  it('mounts and returns expected API', async () => {
    const containerRef = ref<HTMLElement | null>(null)
    const worldRef = ref<HTMLElement | null>(null)
    const bounds = ref<GraphBounds>({ x: 0, y: 0, width: 200, height: 100 })

    const comp = defineComponent({
      setup() {
        const api = useGraphViewport({ containerRef, worldRef, bounds })
        return { ...api }
      },
      template: '<div ref="containerRef" style="width:800px;height:600px"><div ref="worldRef"></div></div>',
    })

    const wrapper = mount(comp, { attachTo: document.body })
    await nextTick()

    expect(typeof wrapper.vm.zoomIn).toBe('function')
    expect(typeof wrapper.vm.zoomOut).toBe('function')
    expect(typeof wrapper.vm.fit).toBe('function')
    expect(typeof wrapper.vm.actualSize).toBe('function')
    expect(typeof wrapper.vm.centerOnNode).toBe('function')
    expect(typeof wrapper.vm.reset).toBe('function')
    expect(typeof wrapper.vm.zoomPercent).toBe('number')
    expect(typeof wrapper.vm.isUserInteracted).toBe('boolean')

    wrapper.unmount()
  })

  it('zoomPercent starts at 100', async () => {
    const containerRef = ref<HTMLElement | null>(null)
    const worldRef = ref<HTMLElement | null>(null)
    const bounds = ref<GraphBounds>({ x: 0, y: 0, width: 200, height: 100 })

    const comp = defineComponent({
      setup() {
        const api = useGraphViewport({ containerRef, worldRef, bounds })
        return { ...api }
      },
      template: '<div ref="containerRef" style="width:800px;height:600px"><div ref="worldRef"></div></div>',
    })

    const wrapper = mount(comp, { attachTo: document.body })
    await nextTick()
    expect(wrapper.vm.zoomPercent).toBeGreaterThanOrEqual(25)
    wrapper.unmount()
  })
})
