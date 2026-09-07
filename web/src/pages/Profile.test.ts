import { flushPromises, mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from '@/api/client'
import Profile from './Profile.vue'

vi.mock('@/api/client', () => ({ default: { get: vi.fn() } }))

function tokenFor(payload: Record<string, unknown>): string {
  const encoded = btoa(JSON.stringify(payload))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
  return `header.${encoded}.signature`
}

async function mountPage() {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: { template: '<p>Home</p>' } },
      { path: '/profile', component: Profile },
    ],
  })
  await router.push('/profile')
  await router.isReady()
  const wrapper = mount(Profile, { global: { plugins: [createPinia(), router] } })
  return { wrapper, router }
}

describe('Profile page', () => {
  beforeEach(() => {
    localStorage.clear()
    localStorage.setItem('token', tokenFor({ id: 1, username: 'alice', role: 'user' }))
    vi.clearAllMocks()
    vi.mocked(api.get).mockResolvedValue({
      data: {
        data: {
          user: {
            id: 1,
            username: 'alice',
            email: 'alice@example.com',
            role: 'user',
            created_at: '2026-01-01T00:00:00.000Z',
          },
        },
      },
    })
  })

  it('renders basic user information when the API has no activity field', async () => {
    const { wrapper } = await mountPage()
    await flushPromises()

    expect(wrapper.get('.profile-name').text()).toBe('alice')
    expect(wrapper.text()).toContain('alice@example.com')
    expect(wrapper.text()).toContain('user')
    expect(wrapper.get('.btn-danger').text()).toContain('Sign out')
    expect(wrapper.find('.profile-activity').exists()).toBe(false)
  })

  it('clears the session and returns home when signing out', async () => {
    const { wrapper, router } = await mountPage()
    await flushPromises()

    await wrapper.get('.btn-danger').trigger('click')
    await flushPromises()

    expect(localStorage.getItem('token')).toBeNull()
    expect(router.currentRoute.value.path).toBe('/')
  })
})
