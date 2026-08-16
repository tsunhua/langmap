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

const route = reactive({ params: { id: 'eng:anchor' } })
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
    route.params.id = 'eng:anchor'
    detail.mockResolvedValue({ expression: { id: 'eng:anchor', lang_code: 'eng', text: 'anchor' } })
    mappingGraph.mockResolvedValue({
      root_id: 'eng:anchor',
      requested_hops: 2,
      resolved_hops: 1,
      nodes: [
        { expression_id: 'eng:anchor', text: 'anchor', lang_code: 'eng', language_name: 'English', depth: 0 },
        { expression_id: 'twi:zero', text: 'zero', lang_code: 'twi', language_name: 'Twi', depth: 1 },
      ],
      edges: [{ edge_id: 'edge-1', source_id: 'eng:anchor', target_id: 'twi:zero', score: 3, depth: 1 }],
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
    let resolveOld!: (value: { expression: { id: string; lang_code: string; text: string } }) => void
    const oldDetail = new Promise<{ expression: { id: string; lang_code: string; text: string } }>((resolve) => {
      resolveOld = resolve
    })
    detail.mockImplementation((id: string) => id === 'eng:anchor'
      ? oldDetail
      : Promise.resolve({ expression: { id: 'eng:new', lang_code: 'eng', text: 'Newest anchor' } }))
    mappingGraph.mockImplementation((id: string) => Promise.resolve({
      root_id: id,
      requested_hops: 2,
      resolved_hops: 0,
      nodes: [{ expression_id: id, text: id, lang_code: 'eng', language_name: 'English', depth: 0 }],
      edges: [],
      layer_counts: { 0: 1 },
      truncated: false,
      omitted_count: 0,
    }))

    const wrapper = mount(MapLens, {
      global: { plugins: [createPinia()], stubs: { RouterLink: { props: ['to'], template: '<a><slot /></a>' } } },
    })
    route.params.id = 'eng:new'
    await flushPromises()
    expect(wrapper.text()).toContain('Newest anchor')

    resolveOld({ expression: { id: 'eng:anchor', lang_code: 'eng', text: 'Stale anchor' } })
    await flushPromises()

    expect(wrapper.text()).toContain('Newest anchor')
    expect(wrapper.text()).not.toContain('Stale anchor')
  })
})
