import { flushPromises, mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ExpressionSearchControls from './ExpressionSearchControls.vue'

const mocks = vi.hoisted(() => ({
  rememberSearchLanguage: vi.fn(),
  loadSearchLanguages: vi.fn().mockResolvedValue(undefined),
  groups: {
    recent: [
      { code: 'eng', name: 'English', name_en: 'English', expression_count: 8, locale_count: 1, active_ui_locale_count: 0 },
    ],
    alphabetical: [
      { code: 'spa', name: 'Español', name_en: 'Spanish', expression_count: 5, locale_count: 1, active_ui_locale_count: 0 },
      { code: 'jpn', name: '日本語', name_en: 'Japanese', expression_count: 3, locale_count: 1, active_ui_locale_count: 0 },
      { code: 'empty', name: 'Empty', name_en: 'Empty', expression_count: 0, locale_count: 1, active_ui_locale_count: 0 },
    ],
  },
}))

vi.mock('@/composables/useSearchLanguages', () => ({
  rememberSearchLanguage: mocks.rememberSearchLanguage,
  useSearchLanguages: () => ({
    groups: { value: mocks.groups },
    loading: false,
    loadError: '',
    loadSearchLanguages: mocks.loadSearchLanguages,
  }),
}))

function mountControls(props: Partial<InstanceType<typeof ExpressionSearchControls>['$props']> = {}) {
  return mount(ExpressionSearchControls, {
    props: { query: 'star', language: 'eng', variant: 'compact', ...props },
    global: { plugins: [createPinia()] },
    attachTo: document.body,
  })
}

describe('ExpressionSearchControls', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.loadSearchLanguages.mockResolvedValue(undefined)
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('loads languages only when the language menu is opened', async () => {
    const wrapper = mountControls()
    await flushPromises()

    expect(mocks.loadSearchLanguages).not.toHaveBeenCalled()

    await wrapper.get('[role="combobox"]').trigger('click')
    expect(mocks.loadSearchLanguages).toHaveBeenCalledTimes(1)
  })

  it('searches more languages from the dropdown input', async () => {
    vi.useFakeTimers()
    const wrapper = mountControls()

    await wrapper.get('[role="combobox"]').trigger('click')
    await wrapper.get('.expression-search-language-filter-input').setValue('Mandarin')
    await vi.advanceTimersByTimeAsync(250)

    expect(mocks.loadSearchLanguages).toHaveBeenLastCalledWith(
      expect.any(Object),
      { query: 'Mandarin' },
    )
  })

  it('renders recent and alphabetical groups with names and codes without visible counts', async () => {
    const wrapper = mountControls()
    await flushPromises()

    await wrapper.get('[role="combobox"]').trigger('click')

    expect(wrapper.text()).toContain('Recent languages')
    expect(wrapper.text()).toContain('All languages')
    expect(wrapper.findAll('[role="option"]')).toHaveLength(3)
    expect(wrapper.get('[role="option"]').text()).toContain('English')
    expect(wrapper.text()).toContain('eng')
    expect(wrapper.findAll('.expression-search-option-count')).toHaveLength(0)
    expect(wrapper.get('[role="option"]').attributes('aria-label')).toContain('8 expressions')
    expect(wrapper.text()).not.toContain('Empty')
  })

  it('remembers and emits a selected language immediately', async () => {
    const wrapper = mountControls()
    await wrapper.get('[role="combobox"]').trigger('click')
    await wrapper.findAll('[role="option"]')[1].trigger('mousedown')

    const languageEvents = wrapper.emitted('update:language') ?? []
    expect(languageEvents[languageEvents.length - 1]).toEqual(['spa'])
    expect(mocks.rememberSearchLanguage).toHaveBeenCalledWith('spa')
    expect(wrapper.get('[role="combobox"]').attributes('aria-expanded')).toBe('false')
  })

  it('supports Arrow keys, Enter, Escape, and listbox ARIA state', async () => {
    const wrapper = mountControls()
    const combobox = wrapper.get('[role="combobox"]')

    await combobox.trigger('keydown', { key: 'ArrowDown' })
    expect(combobox.attributes('aria-expanded')).toBe('true')
    expect(combobox.attributes('aria-activedescendant')).toBeTruthy()

    await combobox.trigger('keydown', { key: 'Enter' })
    expect(wrapper.emitted('update:language')).toBeTruthy()

    await combobox.trigger('click')
    await combobox.trigger('keydown', { key: 'Escape' })
    expect(combobox.attributes('aria-expanded')).toBe('false')
  })

  it('emits submit and exposes both focus targets', async () => {
    const wrapper = mountControls()

    await wrapper.get('.expression-search-input').trigger('keydown', { key: 'Enter' })
    expect(wrapper.emitted('submit')).toHaveLength(1)

    const language = wrapper.get('[role="combobox"]').element
    const search = wrapper.get('.expression-search-input').element
    wrapper.vm.focusLanguage()
    expect(document.activeElement).toBe(language)
    wrapper.vm.focusSearch()
    expect(document.activeElement).toBe(search)
  })

  it('renders a visible submit button for the full search form', () => {
    const wrapper = mountControls({ variant: 'page', showSubmit: true })
    const button = wrapper.get('.expression-search-submit')

    expect(button.attributes('type')).toBe('submit')
    expect(button.text()).toBe('Search')
  })

  it('closes the language list when focus or pointer leaves the control', async () => {
    const wrapper = mountControls()
    const combobox = wrapper.get('[role="combobox"]')
    await combobox.trigger('click')
    expect(combobox.attributes('aria-expanded')).toBe('true')

    await combobox.trigger('blur')
    expect(combobox.attributes('aria-expanded')).toBe('false')

    await combobox.trigger('click')
    const outside = document.createElement('button')
    document.body.append(outside)
    outside.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))
    await flushPromises()
    expect(combobox.attributes('aria-expanded')).toBe('false')
    outside.remove()
  })
})
