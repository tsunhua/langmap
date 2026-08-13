import { flushPromises, mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { describe, expect, it, vi } from 'vitest'
import App from './App.vue'

vi.mock('@/api/client', () => ({
  default: {
    get: vi.fn((path: string) => Promise.resolve({
      data: {
        data: path.endsWith('/messages')
          ? { messages: [{ key: 'nav.skipToContent', text: 'Skip to main content' }] }
          : [],
      },
    })),
    post: vi.fn(),
  },
}))

describe('App shell', () => {
  it('offers keyboard users a skip link to the main content', async () => {
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [{ path: '/', component: { template: '<h1>Activity</h1>' } }],
    })
    await router.push('/')
    await router.isReady()

    const wrapper = mount(App, { global: { plugins: [createPinia(), router] } })
    await flushPromises()

    expect(wrapper.get('a[href="#main-content"]').text()).toBe('Skip to main content')
    expect(wrapper.get('main').attributes('id')).toBe('main-content')
  })
})
