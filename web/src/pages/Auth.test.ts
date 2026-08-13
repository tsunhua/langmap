import { flushPromises, mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from '@/api/client'
import Auth from './Auth.vue'

vi.mock('@/api/client', () => ({ default: { post: vi.fn(), get: vi.fn() } }))

async function mountPage() {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: { template: '<p>Home</p>' } },
      { path: '/auth', component: Auth },
    ],
  })
  await router.push('/auth')
  await router.isReady()
  const wrapper = mount(Auth, { global: { plugins: [createPinia(), router] } })
  return { wrapper, router }
}

describe('Auth page', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.clearAllMocks()
  })

  it('switches to an accessible registration form with new-password autocomplete', async () => {
    const { wrapper } = await mountPage()

    await wrapper.get('.toggle button').trigger('click')

    expect(wrapper.get('#auth-username').attributes('autocomplete')).toBe('username')
    expect(wrapper.get('#auth-password').attributes('autocomplete')).toBe('new-password')
  })

  it('logs in once while a submission is pending and navigates home after confirmation', async () => {
    let resolveLogin: ((value: unknown) => void) | undefined
    vi.mocked(api.post).mockReturnValueOnce(new Promise((resolve) => { resolveLogin = resolve }))
    const { wrapper, router } = await mountPage()
    await wrapper.get('#auth-email').setValue('alice@example.com')
    await wrapper.get('#auth-password').setValue('secret')

    await wrapper.get('form').trigger('submit')
    await wrapper.get('form').trigger('submit')

    expect(api.post).toHaveBeenCalledTimes(1)
    expect(wrapper.get('button[type="submit"]').attributes('disabled')).toBeDefined()

    resolveLogin?.({ data: { data: { token: 'token', user: { id: 1, username: 'alice', role: 'user' } } } })
    await flushPromises()
    expect(router.currentRoute.value.path).toBe('/')
  })

  it('shows the server message as an alert when authentication fails', async () => {
    vi.mocked(api.post).mockRejectedValueOnce({ response: { data: { error: 'INVALID_CREDENTIALS', message: 'Invalid email or password' } } })
    const { wrapper } = await mountPage()
    await wrapper.get('#auth-email').setValue('alice@example.com')
    await wrapper.get('#auth-password').setValue('wrong')

    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toBe('Invalid email or password')
  })
})
