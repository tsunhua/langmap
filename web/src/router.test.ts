import { describe, expect, it } from 'vitest'
import router from './router'

describe('router', () => {
  it.each([
    '/',
    '/mapping/nan%3Aexample',
    '/contribute',
    '/translate',
    '/translate/nan-Hant-CN',
    '/handbooks',
    '/handbook/1',
    '/handbook/1/edit',
    '/map/nan%3Aexample',
    '/languages',
    '/language/NAN',
    '/search?q=eat',
    '/auth',
  ])('resolves the public entry %s', (path) => {
    const resolved = router.resolve(path)
    expect(resolved.matched).toHaveLength(1)
    expect(resolved.matched[0].path).not.toBe('/:pathMatch(.*)*')
  })

  it('redirects the legacy map entry to home', () => {
    expect(router.resolve('/map').matched[0].redirect).toBe('/')
  })

  it('resolves unknown paths to the not-found page', () => {
    expect(router.resolve('/definitely-missing').matched[0].path).toBe('/:pathMatch(.*)*')
  })
})
