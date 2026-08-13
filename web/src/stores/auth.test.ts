import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from '@/api/client'
import { useAuthStore } from './auth'

vi.mock('@/api/client', () => ({
  default: { post: vi.fn(), get: vi.fn() },
}))

function tokenFor(payload: Record<string, unknown>): string {
  const encoded = btoa(JSON.stringify(payload))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
  return `header.${encoded}.signature`
}

describe('auth store', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('restores a valid base64url JWT into the current user', () => {
    localStorage.setItem('token', tokenFor({ id: 7, username: '> ', role: 'admin', exp: 9_999_999_999 }))

    const auth = useAuthStore()

    expect(auth.isLoggedIn).toBe(true)
    expect(auth.user).toEqual({ id: 7, username: '> ', role: 'admin' })
  })

  it('removes an expired token instead of exposing a stale session', () => {
    localStorage.setItem('token', tokenFor({ id: 7, username: 'old', role: 'user', exp: 1 }))

    const auth = useAuthStore()

    expect(auth.isLoggedIn).toBe(false)
    expect(auth.user).toBeNull()
    expect(localStorage.getItem('token')).toBeNull()
  })

  it('stores login and registration sessions and clears them on logout', async () => {
    vi.mocked(api.post)
      .mockResolvedValueOnce({ data: { data: { token: 'login-token', user: { id: 1, username: 'alice', role: 'user' } } } })
      .mockResolvedValueOnce({ data: { data: { token: 'register-token', user: { id: 2, username: 'bob', role: 'user' } } } })
    const auth = useAuthStore()

    await auth.login('ALICE@example.com', 'secret')
    expect(api.post).toHaveBeenNthCalledWith(1, '/auth/login', { email: 'ALICE@example.com', password: 'secret' })
    expect(localStorage.getItem('token')).toBe('login-token')
    expect(auth.user?.username).toBe('alice')

    await auth.register('bob', 'bob@example.com', 'secret')
    expect(api.post).toHaveBeenNthCalledWith(2, '/auth/register', { username: 'bob', email: 'bob@example.com', password: 'secret' })
    expect(localStorage.getItem('token')).toBe('register-token')

    auth.logout()
    expect(auth.user).toBeNull()
    expect(auth.isLoggedIn).toBe(false)
    expect(localStorage.getItem('token')).toBeNull()
  })
})
