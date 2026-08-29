import { ref, onMounted, onUnmounted, watch, type Ref } from 'vue'
import { zoom, zoomIdentity, type ZoomBehavior } from 'd3-zoom'
import { select } from 'd3-selection'
import type { GraphBounds } from '@/components/mapping/mappingGraphTypes'

export interface ZoomState {
  x: number
  y: number
  k: number
}

export function calcFitTransform(
  bounds: GraphBounds,
  viewportWidth: number,
  viewportHeight: number,
  padding = 40,
): ZoomState {
  if (bounds.width <= 0 || bounds.height <= 0 || viewportWidth <= 0 || viewportHeight <= 0) {
    return { x: 0, y: 0, k: 1 }
  }
  const scaleX = (viewportWidth - padding * 2) / bounds.width
  const scaleY = (viewportHeight - padding * 2) / bounds.height
  // On narrow screens a graph with few nodes must not auto-zoom cards to
  // screen-filling size; keep the initial fit at or below natural scale.
  const maxK = viewportWidth < 480 ? 1 : viewportWidth < 768 ? 1.5 : 2.5
  const k = Math.max(0.25, Math.min(scaleX, scaleY, maxK))
  const x = (viewportWidth - bounds.width * k) / 2 - bounds.x * k
  const y = (viewportHeight - bounds.height * k) / 2 - bounds.y * k
  return { x, y, k }
}

export interface UseGraphViewportOptions {
  containerRef: Readonly<Ref<HTMLElement | undefined | null>>
  worldRef: Readonly<Ref<HTMLElement | undefined | null>>
  bounds: Readonly<Ref<GraphBounds>>
  padding?: number
}

export function useGraphViewport(options: UseGraphViewportOptions) {
  const { containerRef, worldRef, bounds } = options
  const padding = options.padding ?? 40
  const zoomPercent = ref(100)
  const isUserInteracted = ref(false)

  let behavior: ZoomBehavior<HTMLElement, unknown> | null = null
  let initialFit: ZoomState | null = null

  function setupZoom() {
    const container = containerRef.value
    const world = worldRef.value
    if (!container || !world || behavior) return

    behavior = zoom<HTMLElement, unknown>()
      .scaleExtent([0.25, 2.5])
      .on('start', (event) => {
        if (event.sourceEvent) isUserInteracted.value = true
      })
      .on('zoom', (event) => {
        const t = event.transform
        world.style.transform = `translate(${t.x}px, ${t.y}px) scale(${t.k})`
        world.style.transformOrigin = '0 0'
        zoomPercent.value = Math.round(t.k * 100)
      })
      .filter((event) => {
        if (event.type === 'wheel') return true
        const target = event.target as HTMLElement
        if (target?.closest?.('[data-node-id]')) return false
        return true
      })

    select(container).call(behavior)
  }

  function getVpSize() {
    const el = containerRef.value
    return el ? { w: el.clientWidth, h: el.clientHeight } : { w: 0, h: 0 }
  }

  function fit(customBounds?: GraphBounds) {
    const b = customBounds ?? bounds.value
    const vp = getVpSize()
    const state = calcFitTransform(b, vp.w, vp.h, padding)
    initialFit = state
    isUserInteracted.value = false
    if (behavior && containerRef.value) {
      const t = zoomIdentity.translate(state.x, state.y).scale(state.k)
      select(containerRef.value).call(behavior.transform, t)
    }
  }

  function zoomIn() {
    if (behavior && containerRef.value) {
      select(containerRef.value).call(behavior.scaleBy, 1.3)
    }
  }

  function zoomOut() {
    if (behavior && containerRef.value) {
      select(containerRef.value).call(behavior.scaleBy, 1 / 1.3)
    }
  }

  function actualSize() {
    if (behavior && containerRef.value) {
      select(containerRef.value).call(behavior.scaleTo, 1)
    }
  }

  function reset() {
    if (initialFit) {
      isUserInteracted.value = false
      if (behavior && containerRef.value) {
        const t = zoomIdentity.translate(initialFit.x, initialFit.y).scale(initialFit.k)
        select(containerRef.value).call(behavior.transform, t)
      }
    }
  }

  function centerOnNode(x: number, y: number) {
    if (!behavior || !containerRef.value) return
    const vp = getVpSize()
    let k = 1
    const el = worldRef.value
    if (el) {
      const match = el.style.transform.match(/scale\(([^)]+)\)/)
      if (match) k = parseFloat(match[1])
    }
    const tx = vp.w / 2 - x * k
    const ty = vp.h / 2 - y * k
    const t = zoomIdentity.translate(tx, ty).scale(k)
    select(containerRef.value).call(behavior.transform, t)
  }

  onMounted(() => {
    setupZoom()
    fit()
  })

  onUnmounted(() => {
    if (behavior && containerRef.value) {
      select(containerRef.value).on('.zoom', null)
    }
    behavior = null
  })

  watch(bounds, () => {
    if (!isUserInteracted.value) {
      fit()
    }
  }, { deep: true })

  return {
    zoomIn,
    zoomOut,
    fit,
    actualSize,
    centerOnNode,
    reset,
    zoomPercent,
    isUserInteracted,
  }
}
