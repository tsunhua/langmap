import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { createMemoryHistory, createRouter } from 'vue-router'
import { createPinia } from 'pinia'
import api from '@/api/client'
import HomeFeed from './HomeFeed.vue'

vi.mock('@/api/client', () => ({ default: { get: vi.fn() } }))

// /feed/hot rows carry an edge id and both endpoint expression ids (a_id/b_id);
// the card anchors on a_id. /feed/new 'mapping' rows likewise anchor on a_id.
const hotRow = { id: 'edge-hot', a_id: 'nan:a-hot', a_text: '食', a_lang: 'nan', b_text: 'eat', b_lang: 'eng', score: 8 }
const newRow = { id: 'edge-new', type: 'mapping', a_id: 'nan:a-new', left_text: '食', left_lang: 'nan', right_text: 'eat', right_lang: 'eng' }

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

  it('shows stable hot and new content and lets users filter either section', async () => {
    vi.mocked(api.get)
      .mockResolvedValueOnce({ data: { data: [hotRow] } })
      .mockResolvedValueOnce({ data: { data: [newRow] } })
    const wrapper = await mountPage()
    await flushPromises()

    expect(wrapper.find('a[href="/mapping/nan:a-hot"]').exists()).toBe(true)
    expect(wrapper.find('a[href="/mapping/nan:a-new"]').exists()).toBe(true)

    await wrapper.get('button[aria-pressed="false"]:nth-child(2)').trigger('click')
    expect(wrapper.find('a[href="/mapping/nan:a-new"]').exists()).toBe(false)
    expect(wrapper.find('a[href="/mapping/nan:a-hot"]').exists()).toBe(true)
  })

  it('shows one empty state when both feeds are empty', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: { data: [] } })
    const wrapper = await mountPage()
    await flushPromises()

    expect(wrapper.findAll('.empty')).toHaveLength(1)
    expect(wrapper.text()).toContain('No activity yet')
  })

  it('shows the response message when either initial request fails', async () => {
    vi.mocked(api.get)
      .mockRejectedValueOnce({ response: { data: { message: 'Feed temporarily unavailable' } } })
      .mockResolvedValueOnce({ data: { data: [] } })
    const wrapper = await mountPage()
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toBe('Feed temporarily unavailable')
  })
})
