import { flushPromises, mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from '@/api/client'
import { resetRecentSearchLanguages } from '@/composables/useSearchLanguages'
import TopNav from './TopNav.vue'

vi.mock('@/api/client', () => ({ default: { get: vi.fn() } }))

// The interface-language switcher has its own locale API and is not part of
// the search seam covered by this component test.
vi.mock('./LangSwitcher.vue', () => ({
  default: { template: '<button type="button">Language</button>' },
}))

function contentLanguage(code: string, name: string, expression_count = 1) {
  return { code, name, name_en: name, expression_count, locale_count: 1, active_ui_locale_count: 0 }
}

const searchableLanguages = [
  contentLanguage('eng', 'English', 8),
  contentLanguage('jpn', '日本語', 3),
  contentLanguage('spa', 'Español', 5),
]

class MemoryStorage implements Storage {
  private values = new Map<string, string>()

  get length() { return this.values.size }
  clear() { this.values.clear() }
  getItem(key: string) { return this.values.get(key) ?? null }
  key(index: number) { return [...this.values.keys()][index] ?? null }
  removeItem(key: string) { this.values.delete(key) }
  setItem(key: string, value: string) { this.values.set(key, value) }
}

async function mountNav() {
  vi.mocked(api.get).mockImplementation((path: string) => {
    if (path === '/languages') {
      return Promise.resolve({ data: { data: { items: searchableLanguages, total: searchableLanguages.length, skip: 0, limit: 100, hasMore: false } } })
    }
    throw new Error(`unexpected ${path}`)
  })

  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/mapping/:id', component: { template: '<p>Mapping</p>' } },
      { path: '/search', component: { template: '<p>Search</p>' } },
      { path: '/languages', component: { template: '<p>Languages</p>' } },
      { path: '/handbooks', component: { template: '<p>Handbooks</p>' } },
      { path: '/contribute', component: { template: '<p>Contribute</p>' } },
      { path: '/auth', component: { template: '<p>Auth</p>' } },
    ],
  })
  await router.push('/mapping/1')
  await router.isReady()
  const wrapper = mount(TopNav, {
    attachTo: document.body,
    global: { plugins: [createPinia(), router] },
  })
  return { wrapper, router }
}

describe('TopNav', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    if (typeof globalThis.localStorage?.clear !== 'function') vi.stubGlobal('localStorage', new MemoryStorage())
    localStorage.clear()
    resetRecentSearchLanguages()
  })

  it('initializes the shared search with a remembered language and navigates with q and lang', async () => {
    localStorage.setItem('langmap.search.languages', JSON.stringify(['spa']))
    resetRecentSearchLanguages({ reload: true })

    const { wrapper, router } = await mountNav()
    await flushPromises()

    expect(wrapper.get('.search-center [role="combobox"]').text()).toContain('Español')
    await wrapper.get('.search-center input[type="search"]').setValue('  star  ')
    await wrapper.get('.search-center form[role="search"]').trigger('submit')
    await flushPromises()

    expect(router.currentRoute.value.fullPath).toBe('/search?q=star&lang=spa')
  })

  it('keeps the current route, reports a missing language, and focuses the visible control', async () => {
    const { wrapper, router } = await mountNav()
    await flushPromises()

    await wrapper.get('.search-center input[type="search"]').setValue('star')
    await wrapper.get('.search-center form[role="search"]').trigger('submit')
    await flushPromises()

    expect(router.currentRoute.value.path).toBe('/mapping/1')
    expect(document.activeElement).toBe(wrapper.get('.search-center [role="combobox"]').element)
    expect(wrapper.get('.search-center [role="status"]').text()).toContain('Select a language')
  })

  it('uses separate drawer controls and focuses the drawer language when submitting there', async () => {
    const { wrapper, router } = await mountNav()
    await flushPromises()
    await wrapper.get('.menu-toggle').trigger('click')
    await flushPromises()

    const drawer = wrapper.get('.drawer')
    await drawer.get('input[type="search"]').setValue('star')
    await drawer.get('form[role="search"]').trigger('submit')
    await flushPromises()

    expect(router.currentRoute.value.path).toBe('/mapping/1')
    expect(document.activeElement).toBe(drawer.get('[role="combobox"]').element)
  })

  it('focuses search with / without opening the language list, while preserving typing contexts', async () => {
    const { wrapper } = await mountNav()
    await flushPromises()

    const combobox = wrapper.get('.search-center [role="combobox"]')
    const comboboxElement = combobox.element as HTMLElement
    comboboxElement.focus()
    document.dispatchEvent(new KeyboardEvent('keydown', { key: '/', bubbles: true, cancelable: true }))
    expect(document.activeElement).toBe(comboboxElement)
    expect(combobox.attributes('aria-expanded')).toBe('false')

    const editable = document.createElement('div')
    editable.setAttribute('contenteditable', 'true')
    document.body.append(editable)
    editable.focus()
    document.dispatchEvent(new KeyboardEvent('keydown', { key: '/', bubbles: true, cancelable: true }))
    expect(document.activeElement).toBe(editable)
    editable.remove()

    const outside = document.createElement('button')
    document.body.append(outside)
    outside.focus()
    document.dispatchEvent(new KeyboardEvent('keydown', { key: '/', bubbles: true, cancelable: true }))
    expect(document.activeElement).toBe(wrapper.get('.search-center input[type="search"]').element)
    outside.remove()
  })
})
