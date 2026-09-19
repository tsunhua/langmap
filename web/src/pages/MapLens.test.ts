import { flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { createPinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MapLens from './MapLens.vue'

const { detail, mappingGraph, getLanguageDetail, marker, remove, fitBounds } = vi.hoisted(() => ({
  detail: vi.fn(),
  mappingGraph: vi.fn(),
  getLanguageDetail: vi.fn(),
  marker: vi.fn(),
  remove: vi.fn(),
  fitBounds: vi.fn(),
}))

vi.mock('@/composables/useExpressions', () => ({
  useExpressions: () => ({ detail, mappingGraph }),
}))

vi.mock('@/api/languageIdentity', () => ({ getLanguageDetail }))

const route = reactive({ params: { lang: 'eng', text: 'anchor' } })
vi.mock('vue-router', () => ({
  useRoute: () => route,
  useRouter: () => ({ push: vi.fn() }),
}))

vi.mock('leaflet', () => {
  const mapInstance = {
    setView: vi.fn().mockReturnThis(),
    fitBounds,
    remove,
  }
  const layer = { addTo: vi.fn().mockReturnThis() }
  marker.mockImplementation(() => ({ bindPopup: vi.fn().mockReturnThis(), addTo: vi.fn().mockReturnThis() }))
  return {
    default: {
      map: vi.fn(() => mapInstance),
      tileLayer: vi.fn(() => layer),
      divIcon: vi.fn((options) => options),
      marker,
      latLngBounds: vi.fn(() => ({ extend: vi.fn() })),
    },
  }
})

describe('MapLens', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    route.params = { lang: 'eng', text: 'anchor' }
    detail.mockResolvedValue({ expression: { id: '1', lang_code: 'eng', text: 'anchor', homograph_index: 1 } })
    mappingGraph.mockResolvedValue({
      root_id: '1',
      requested_hops: 2,
      resolved_hops: 1,
      nodes: [
        { expression_id: '1', text: 'anchor', lang_code: 'eng', language_name: 'English', depth: 0, homograph_index: 1 },
        { expression_id: '2', text: 'zero', lang_code: 'twi', language_name: 'Twi', depth: 1, homograph_index: 1 },
      ],
      edges: [{ edge_id: 'edge-1', source_id: '1', target_id: '2', score: 3, depth: 1 }],
      layer_counts: { 0: 1, 1: 1 },
      truncated: false,
      omitted_count: 0,
    })
    getLanguageDetail.mockImplementation((code: string) => Promise.resolve({
      code,
      locales: code === 'eng'
        ? [{ code: 'eng-Latn-GB', lang_code: 'eng', name: 'England', latitude: 52, longitude: -1 }]
        : [{ code: 'twi-Latn-GH', lang_code: 'twi', name: 'Ghana', latitude: 0, longitude: 0 }],
    }))
  })

  it('renders markers for valid coordinates on the equator and prime meridian', async () => {
    const wrapper = mount(MapLens, {
      global: {
        plugins: [createPinia()],
        stubs: {
          RouterLink: { props: ['to'], template: '<a><slot /></a>' },
        },
      },
    })
    await flushPromises()

    expect(wrapper.text()).toContain('zero')
    expect(marker).toHaveBeenCalledTimes(2)
    expect(marker).toHaveBeenCalledWith([0, 0], expect.any(Object))
  })

  it('caps automatic zoom when map locations overlap', async () => {
    mount(MapLens, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()

    expect(fitBounds).toHaveBeenCalledWith(expect.anything(), expect.objectContaining({ maxZoom: 5 }))
  })

  it('renders region fallback coordinates returned by language details', async () => {
    getLanguageDetail.mockImplementation((code: string) => Promise.resolve({
      code,
      locales: code === 'eng'
        ? [{ code: 'eng-Latn-US', lang_code: 'eng', name: 'United States', latitude: 39.8, longitude: -98.6, coordinate_source: 'region' }]
        : [{ code: 'twi-Latn-GH', lang_code: 'twi', name: 'Ghana', latitude: 0, longitude: 0, coordinate_source: 'region' }],
    }))

    const wrapper = mount(MapLens, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    await flushPromises()

    expect(wrapper.find('.leaflet-map').exists()).toBe(true)
    expect(marker).toHaveBeenCalledWith([0, 0], expect.any(Object))
  })

  it('keeps the newest route result when an older request finishes later', async () => {
    let resolveOld!: (value: { expression: { id: string; lang_code: string; text: string; homograph_index: number } }) => void
    const oldDetail = new Promise<{ expression: { id: string; lang_code: string; text: string; homograph_index: number } }>((resolve) => {
      resolveOld = resolve
    })
    detail.mockImplementation((target: { text?: string }) => target?.text === 'anchor'
      ? oldDetail
      : Promise.resolve({ expression: { id: '9', lang_code: 'eng', text: 'Newest anchor', homograph_index: 1 } }))
    mappingGraph.mockImplementation((target: { text?: string }) => Promise.resolve({
      root_id: '9',
      requested_hops: 2,
      resolved_hops: 0,
      nodes: [{ expression_id: '9', text: target?.text ?? 'anchor', lang_code: 'eng', language_name: 'English', depth: 0, homograph_index: 1 }],
      edges: [],
      layer_counts: { 0: 1 },
      truncated: false,
      omitted_count: 0,
    }))

    const wrapper = mount(MapLens, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    route.params = { lang: 'eng', text: 'new' }
    await flushPromises()
    expect(wrapper.text()).toContain('Newest anchor')

    resolveOld({ expression: { id: '1', lang_code: 'eng', text: 'Stale anchor', homograph_index: 1 } })
    await flushPromises()

    expect(wrapper.text()).toContain('Newest anchor')
    expect(wrapper.text()).not.toContain('Stale anchor')
  })
})
