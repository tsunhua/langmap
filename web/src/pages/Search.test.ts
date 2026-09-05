import { flushPromises, mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from '@/api/client'
import Search from './Search.vue'
import { rememberSearchLanguage, resetRecentSearchLanguages } from '@/composables/useSearchLanguages'

vi.mock('@/api/client', () => ({ default: { get: vi.fn() } }))

let mountedRouter: ReturnType<typeof createRouter> | null = null

function page(items: unknown[], total = items.length) {
  return { data: { data: { items, total, skip: 0, limit: 20, hasMore: items.length < total } } }
}

function contentLanguage(code: string, name: string, expression_count = 1) {
  return { code, name, name_en: name, expression_count, locale_count: 1, active_ui_locale_count: 0 }
}

const defaultLanguages = [
  contentLanguage('eng', 'English', 8),
  contentLanguage('spa', 'Español', 5),
  contentLanguage('jpn', '日本語', 3),
]

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
  await router.push(query ? `/search?${query}` : '/search')
  await router.isReady()
  mountedRouter = router
  return mount(Search, { global: { plugins: [createPinia(), router] } })
}

describe('Search page', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    resetRecentSearchLanguages()
    mountedRouter = null
  })

  it('searches with q/offset and shows the selected language', async () => {
    vi.mocked(api.get).mockImplementation((path: string, config?: { params?: Record<string, unknown> }) => {
      if (path === '/languages') return Promise.resolve(page(defaultLanguages))
      if (path === '/expressions/search') return Promise.resolve(page([expression('eng:first', 'First')]))
      throw new Error(`unexpected ${path} ${JSON.stringify(config)}`)
    })
    const wrapper = await mountPage('q=first&lang=eng')
    await flushPromises()

    expect(wrapper.get('a[href="/mapping/eng:first"]').text()).toContain('eng')
    expect(api.get).toHaveBeenLastCalledWith('/expressions/search', {
      params: { q: 'first', lang_code: 'eng', limit: 20, offset: 0, ui_locale: 'eng-Latn-US' },
    })
  })

  it('keeps the newest query result when an older request finishes last', async () => {
    const pending = new Map<string, (value: unknown) => void>()
    vi.mocked(api.get).mockImplementation((path: string, config?: { params?: Record<string, unknown> }) => {
      if (path === '/languages') return Promise.resolve(page(defaultLanguages))
      return new Promise((resolve) => pending.set(String(config?.params?.q), resolve))
    })
    const wrapper = await mountPage('lang=eng')
    const input = wrapper.get('input[type="search"]')

    await input.setValue('old')
    await input.trigger('keydown', { key: 'Enter' })
    await input.setValue('new')
    await input.trigger('keydown', { key: 'Enter' })
    pending.get('new')?.(page([expression('eng:new', 'New result')]))
    await flushPromises()
    pending.get('old')?.(page([expression('eng:old', 'Old result')]))
    await flushPromises()

    expect(wrapper.text()).toContain('New result')
    expect(wrapper.text()).not.toContain('Old result')
  })

  it('keeps existing results and exposes a load-more failure', async () => {
    vi.mocked(api.get).mockImplementation((path: string, config?: { params?: Record<string, unknown> }) => {
      if (path === '/languages') return Promise.resolve(page(defaultLanguages))
      if (config?.params?.offset === 0) return Promise.resolve(page([expression('eng:first', 'First')], 2))
      return Promise.reject({ response: { data: { message: 'More results unavailable' } } })
    })
    const wrapper = await mountPage('q=first&lang=eng')
    await flushPromises()

    await wrapper.get('.pag button').trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('First')
    expect(wrapper.get('[role="alert"]').text()).toBe('More results unavailable')
  })

  it('forwards form_of onto the result row', async () => {
    vi.mocked(api.get).mockImplementation((path: string) => {
      if (path === '/languages') return Promise.resolve(page(defaultLanguages))
      if (path === '/expressions/search') {
        return Promise.resolve(page([{
          ...expression('spa:gatas', 'gatas'),
          lang_code: 'spa',
          form_of: [{
            lemma: { id: 'spa:gato', text: 'gato', lang_code: 'spa' },
            features: [{ code: 'plural', name: 'plural' }],
          }],
        }]))
      }
      throw new Error(`unexpected ${path}`)
    })
    const wrapper = await mountPage('q=gatas&lang=spa')
    await flushPromises()
    expect(wrapper.get('.ex-form').text()).toBe('plural ← gato')
  })

  it('reuses the last-selected language on the next visit', async () => {
    vi.mocked(api.get).mockImplementation((path: string) => {
      if (path === '/languages') return Promise.resolve(page(defaultLanguages))
      if (path === '/expressions/search') return Promise.resolve(page([expression('eng:first', 'First')]))
      throw new Error(`unexpected ${path}`)
    })

    const first = await mountPage('q=first')
    await flushPromises()
    await first.get('[role="combobox"]').trigger('click')
    const english = first.findAll('[role="option"]').find((option) => option.text().includes('eng'))
    expect(english).toBeTruthy()
    await english!.trigger('mousedown')
    await flushPromises()
    first.unmount()

    const second = await mountPage('q=second')
    await flushPromises()
    expect(api.get).toHaveBeenLastCalledWith('/expressions/search', {
      params: { q: 'second', lang_code: 'eng', limit: 20, offset: 0, ui_locale: 'eng-Latn-US' },
    })
    second.unmount()
  })

  it('shows inline guidance instead of an error block when a language is missing', async () => {
    vi.mocked(api.get).mockImplementation((path: string) => {
      if (path === '/languages') return Promise.resolve(page(defaultLanguages))
      throw new Error(`unexpected ${path}`)
    })

    const wrapper = await mountPage('q=peg')
    await flushPromises()

    expect(wrapper.find('.expression-search-required').exists()).toBe(true)
    expect(api.get).not.toHaveBeenCalledWith('/expressions/search', expect.anything())
    expect(wrapper.find('.md-empty').exists()).toBe(false)
  })

  it('prefers a valid URL language over recent history', async () => {
    rememberSearchLanguage('spa')
    vi.mocked(api.get).mockImplementation((path: string) => {
      if (path === '/languages') return Promise.resolve(page(defaultLanguages))
      if (path === '/expressions/search') return Promise.resolve(page([expression('eng:star', 'star')]))
      throw new Error(`unexpected ${path}`)
    })

    const wrapper = await mountPage('q=star&lang=eng')
    await flushPromises()
    expect(wrapper.get('[role="combobox"]').text()).toContain('English')
    expect(api.get).toHaveBeenLastCalledWith('/expressions/search', expect.objectContaining({
      params: expect.objectContaining({ lang_code: 'eng' }),
    }))
  })

  it('does not search with a URL language that has no expressions', async () => {
    vi.mocked(api.get).mockImplementation((path: string) => {
      if (path === '/languages') {
        return Promise.resolve(page([
          contentLanguage('eng', 'English', 8),
          contentLanguage('zzz', 'Empty', 0),
        ]))
      }
      throw new Error(`unexpected ${path}`)
    })

    const wrapper = await mountPage('q=star&lang=zzz')
    await flushPromises()

    expect(wrapper.find('.expression-search-required').exists()).toBe(true)
    expect(wrapper.get('[role="combobox"]').text()).not.toContain('Empty')
    expect(api.get).not.toHaveBeenCalledWith('/expressions/search', expect.anything())
  })

  it('searches in the language selected from the dropdown and syncs the URL', async () => {
    vi.mocked(api.get).mockImplementation((path: string) => {
      if (path === '/languages') return Promise.resolve(page(defaultLanguages))
      if (path === '/expressions/search') return Promise.resolve(page([expression('spa:cat', 'cat')]))
      throw new Error(`unexpected ${path}`)
    })

    const wrapper = await mountPage('q=cat')
    await flushPromises()
    const combobox = wrapper.get('[role="combobox"]')
    await combobox.trigger('click')
    const spanish = wrapper.findAll('[role="option"]').find((option) => option.text().includes('spa'))
    expect(spanish).toBeTruthy()
    await spanish!.trigger('mousedown')
    await flushPromises()

    expect(api.get).toHaveBeenLastCalledWith('/expressions/search', {
      params: { q: 'cat', lang_code: 'spa', limit: 20, offset: 0, ui_locale: 'eng-Latn-US' },
    })
    expect(mountedRouter?.currentRoute.value.query).toEqual({ q: 'cat', lang: 'spa' })
  })
})
