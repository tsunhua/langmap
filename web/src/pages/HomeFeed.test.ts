import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createMemoryHistory, createRouter } from 'vue-router'
import { createPinia } from 'pinia'
import api from '@/api/client'
import HomeFeed from './HomeFeed.vue'

vi.mock('@/api/client', () => ({ default: { get: vi.fn() } }))

// /feed/new 'mapping' rows anchor on a_id.
const newRow = { id: 'edge-new', type: 'mapping', a_id: 'nan:a-new', a_text: '食', a_lang: 'nan', b_text: 'eat', b_lang: 'eng' }

async function mountPage() {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: HomeFeed },
      { path: '/mapping/:id', component: { template: '<p>Mapping</p>' } },
      { path: '/contribute', component: { template: '<p>Contribute</p>' } },
    ],
  })
  await router.push('/')
  await router.isReady()
  return mount(HomeFeed, { global: { plugins: [router, createPinia()] } })
}

describe('HomeFeed', () => {
  beforeEach(() => vi.clearAllMocks())

  it('shows the latest contributions', async () => {
    vi.mocked(api.get).mockResolvedValueOnce({ data: { data: [newRow] } })
    const wrapper = await mountPage()
    await flushPromises()

    expect(wrapper.find('a[href="/mapping/nan:a-new"]').exists()).toBe(true)
    expect(wrapper.find('section.feed-sec').exists()).toBe(true)
    expect(wrapper.text()).toContain('食')
    expect(wrapper.text()).toContain('eat')
  })

  it('shows one empty state when there is no new contribution', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: { data: [] } })
    const wrapper = await mountPage()
    await flushPromises()

    expect(wrapper.findAll('.empty')).toHaveLength(1)
    expect(wrapper.text()).toContain('No activity yet')
  })

  it('shows the response message when the request fails', async () => {
    vi.mocked(api.get).mockRejectedValue({ response: { data: { message: 'Feed temporarily unavailable' } } })
    const wrapper = await mountPage()
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toBe('Feed temporarily unavailable')
  })
})