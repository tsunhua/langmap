import { describe, expect, it } from 'vitest'
import router from './router'
import ExpressionTranslation from './pages/ExpressionTranslation.vue'
import UiTranslationWorkbench from './pages/UiTranslationWorkbench.vue'

async function resolvedComponent(path: string) {
  const factory = router.resolve(path).matched[0].components?.default
  const loaded = await (factory as () => Promise<{ default: unknown }>)()
  return loaded.default
}

describe('router', () => {
  it.each([
    '/',
    '/mapping/nan%3Aexample',
    '/contribute',
    '/translate',
    '/ui-translation',
    '/ui-translation/nan-Hant-CN',
    '/handbooks',
    '/handbooks/1',
    '/handbooks/1/edit',
    '/map/nan%3Aexample',
    '/languages',
    '/languages/NAN',
    '/search?q=eat',
    '/auth',
  ])('resolves the public entry %s', (path) => {
    const resolved = router.resolve(path)
    expect(resolved.matched).toHaveLength(1)
    expect(resolved.matched[0].path).not.toBe('/:pathMatch(.*)*')
  })

  it('retires the legacy /translate/:code workbench alias', () => {
    expect(router.resolve('/translate/nan-Hant-CN').matched[0].path).toBe('/:pathMatch(.*)*')
  })

  it('maps each translation route to its own page component', async () => {
    expect(await resolvedComponent('/translate')).toBe(ExpressionTranslation)
    expect(await resolvedComponent('/ui-translation')).toBe(UiTranslationWorkbench)
    expect(await resolvedComponent('/ui-translation/nan-Hant-CN')).toBe(UiTranslationWorkbench)
  })

  it('redirects the legacy map entry to home', () => {
    expect(router.resolve('/map').matched[0].redirect).toBe('/')
  })

  it('resolves unknown paths to the not-found page', () => {
    expect(router.resolve('/definitely-missing').matched[0].path).toBe('/:pathMatch(.*)*')
  })
})
