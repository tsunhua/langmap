import { flushPromises, mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from '@/api/client'
import Search from './Search.vue'

vi.mock('@/api/client', () => ({ default: { get: vi.fn() } }))

function page(items: unknown[], total = items.length) {
  return { data: { data: { items, total, skip: 0, limit: 20, hasMore: items.length < total } } }
}

function expression(id: string, text: string) {
  return { id, text, lang_code: 'eng', mapping_count: 1 }
}

async function mountPage(query = '') {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/search', component: Search },
      { path: '/mapping/:id', component: { template: '<p>Mapping</p>' } },
    ],
  })
  await router.push(query ? `/search?q=${encodeURIComponent(query)}` : '/search')
  await router.isReady()
  return mount(Search, { global: { plugins: [createPinia(), router] } })
}

describe('Search page', () => {
  beforeEach(() => vi.clearAllMocks())

  it('searches, displays current lang_code, and sends the selected sort', async () => {
    vi.mocked(api.get).mockImplementation((path: string, config?: { params?: Record<string, unknown> }) => {
      if (path === '/language-registry/languages') return Promise.resolve(page([]))
      if (path === '/expressions/search') return Promise.resolve(page([expression('eng:first', 'First')]))
      throw new Error(`unexpected ${path} ${JSON.stringify(config)}`)
    })
    const wrapper = await mountPage('first')
    await flushPromises()

    expect(wrapper.get('a[href="/mapping/eng:first"]').text()).toContain('eng')
    await wrapper.get('.se-sort button:nth-child(2)').trigger('click')
    await flushPromises()

    expect(api.get).toHaveBeenLastCalledWith('/expressions/search', {
      params: { q: 'first', lang_code: undefined, sort: 'new', limit: 20, offset: 0 },
    })
  })

  it('keeps the newest query result when an older request finishes last', async () => {
    const pending = new Map<string, (value: unknown) => void>()
    vi.mocked(api.get).mockImplementation((path: string, config?: { params?: Record<string, unknown> }) => {
      if (path === '/language-registry/languages') return Promise.resolve(page([]))
      return new Promise((resolve) => pending.set(String(config?.params?.q), resolve))
    })
    const wrapper = await mountPage()
    const input = wrapper.get('.search-input')

    await input.setValue('old')
    await input.trigger('keydown.enter')
    await input.setValue('new')
    await input.trigger('keydown.enter')
    pending.get('new')?.(page([expression('eng:new', 'New result')]))
    await flushPromises()
    pending.get('old')?.(page([expression('eng:old', 'Old result')]))
    await flushPromises()

    expect(wrapper.text()).toContain('New result')
    expect(wrapper.text()).not.toContain('Old result')
  })

  it('keeps existing results and exposes a load-more failure', async () => {
    vi.mocked(api.get).mockImplementation((path: string, config?: { params?: Record<string, unknown> }) => {
      if (path === '/language-registry/languages') return Promise.resolve(page([]))
      if (config?.params?.offset === 0) return Promise.resolve(page([expression('eng:first', 'First')], 2))
      return Promise.reject({ response: { data: { message: 'More results unavailable' } } })
    })
    const wrapper = await mountPage('first')
    await flushPromises()

    await wrapper.get('.pag button').trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('First')
    expect(wrapper.get('[role="alert"]').text()).toBe('More results unavailable')
  })
})
