import { flushPromises, mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'
import api from '@/api/client'
import ExpressionSearchControls from '@/components/search/ExpressionSearchControls.vue'
import HomeView from './HomeView.vue'

vi.mock('@/api/client', () => ({ default: { get: vi.fn() } }))

const TranslationWorkbenchStub = {
  props: ['showSearchAction'],
  template: `<div class="translation-workbench-stub" :data-show-search-action="showSearchAction">Translator</div>`,
}

async function mountHome() {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/', component: HomeView },
      { path: '/search', component: { template: '<p>Search</p>' } },
    ],
  })
  await router.push('/')
  await router.isReady()
  const wrapper = mount(HomeView, {
    global: { plugins: [router, createPinia()], stubs: { TranslationWorkbench: TranslationWorkbenchStub } },
  })
  return { wrapper, router }
}

describe('HomeView', () => {
  it('opens on the search tab and does not request the activity feed', async () => {
    const { wrapper } = await mountHome()

    expect(wrapper.get('h1').text()).toBe('LangMap')
    expect(wrapper.get('h1').classes()).toContain('sr-only')
    expect(wrapper.get('#home-search-tab').attributes('aria-selected')).toBe('true')
    expect(wrapper.find('#home-search-panel').exists()).toBe(true)
    expect(wrapper.find('.translation-workbench-stub').exists()).toBe(false)
    expect(wrapper.find('.feed-sec').exists()).toBe(false)
    expect(api.get).not.toHaveBeenCalled()
  })

  it('sends the trimmed search text to the existing search route', async () => {
    const { wrapper, router } = await mountHome()
    await wrapper.get('.expression-search-input').setValue('  食飯  ')
    wrapper.findComponent(ExpressionSearchControls).vm.$emit('update:language', 'jpn')
    await wrapper.get('.home-search-form').trigger('submit')
    await flushPromises()

    expect(router.currentRoute.value.path).toBe('/search')
    expect(router.currentRoute.value.query).toEqual({ q: '食飯', lang: 'jpn' })
  })

  it('asks for a language before opening search results', async () => {
    const { wrapper, router } = await mountHome()
    await wrapper.get('.expression-search-input').setValue('hello')
    wrapper.findComponent(ExpressionSearchControls).vm.$emit('submit')
    await flushPromises()

    expect(router.currentRoute.value.path).toBe('/')
    expect(wrapper.findComponent(ExpressionSearchControls).props('languageRequired')).toBe(true)
  })

  it('shows the translator in place and hides its extra search action', async () => {
    const { wrapper, router } = await mountHome()
    await wrapper.get('#home-translate-tab').trigger('click')

    expect(wrapper.get('#home-translate-tab').attributes('aria-selected')).toBe('true')
    expect(wrapper.get('#home-search-panel').isVisible()).toBe(false)
    expect(wrapper.get('.translation-workbench-stub').attributes('data-show-search-action')).toBe('false')
    expect(router.currentRoute.value.path).toBe('/')
  })
})
