import { describe, expect, it, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import LanguagePicker from './LanguagePicker.vue'
import { createPinia, setActivePinia } from 'pinia'
import { useLanguagesStore } from '@/stores/languages'
import type { Variety } from '@/api/languages'

vi.mock('@/api/languages', () => ({
  listRegistryLanguages: vi.fn().mockResolvedValue([]),
  listLanguageSubtags: vi.fn().mockResolvedValue([]),
  searchLanguoids: vi.fn().mockResolvedValue([]),
  previewVariety: vi.fn().mockResolvedValue(null),
  createVariety: vi.fn().mockResolvedValue(null),
}))

const mockLanguage: Variety = {
  id: '01K1GWHD00NMQC20PMZV031H78',
  code: 'en',
  name: 'English',
  name_en: 'English',
  description: '',
  glottocode: 'engo1234',
  origin: 'seed',
  community_reason: null,
  alternate_names: [],
  references: [],
  parent_languoid_id: null,
  expression_count: 100,
}

describe('LanguagePicker', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    setActivePinia(createPinia())
  })

  it('renders a combobox with the label', () => {
    const wrapper = mount(LanguagePicker, {
      props: { modelValue: '', label: 'Language' },
    })
    const input = wrapper.get('input[role="combobox"]')
    expect(input.attributes('aria-label')).toBe('Language')
  })

  it('shows current selected name from store', async () => {
    const store = useLanguagesStore()
    store.upsertLanguage(mockLanguage)

    const wrapper = mount(LanguagePicker, {
      props: { modelValue: 'en', label: 'Language' },
    })
    expect(wrapper.text()).toContain('English')
    expect(wrapper.text()).toContain('en')
  })

  it('shows create option when allowCreate is true', async () => {
    const wrapper = mount(LanguagePicker, {
      props: { modelValue: '', label: 'Language', allowCreate: true },
    })
    expect(wrapper.find('[data-action="create-language"]').exists()).toBe(true)
  })

  it('hides create option when allowCreate is false', async () => {
    const wrapper = mount(LanguagePicker, {
      props: { modelValue: '', label: 'Language', allowCreate: false },
    })
    expect(wrapper.find('[data-action="create-language"]').exists()).toBe(false)
  })

  it('hides create option when a language is selected', async () => {
    const store = useLanguagesStore()
    store.upsertLanguage(mockLanguage)

    const wrapper = mount(LanguagePicker, {
      props: { modelValue: 'en', label: 'Language', allowCreate: true },
    })
    expect(wrapper.find('[data-action="create-language"]').exists()).toBe(false)
  })

  it('opens the create dialog when create is clicked', async () => {
    const wrapper = mount(LanguagePicker, {
      props: { modelValue: '', label: 'Language', allowCreate: true },
      global: {
        stubs: {
          LanguageCreateDialog: {
            props: ['open'],
            emits: ['close', 'created'],
            template: '<div v-if="open" role="dialog"><button data-action="close-dialog" @click="$emit(\'close\')">close</button></div>',
          },
        },
      },
    })
    await wrapper.get('[data-action="create-language"]').trigger('click')
    expect(wrapper.find('[role="dialog"]').exists()).toBe(true)
  })

  it('restores focus to the picker after closing', async () => {
    const host = document.createElement('div')
    document.body.appendChild(host)
    const wrapper = mount(LanguagePicker, {
      attachTo: host,
      props: {
        modelValue: '',
        label: 'Language',
        allowCreate: true,
      },
      global: {
        stubs: {
          LanguageCreateDialog: {
            props: ['open'],
            emits: ['close'],
            template: '<button v-if="open" data-action="close-dialog" @click="$emit(`close`)">close</button>',
          },
        },
      },
    })
    await wrapper.get('[data-action="create-language"]').trigger('click')
    await wrapper.get('[data-action="close-dialog"]').trigger('click')
    expect(document.activeElement).toBe(wrapper.get('[role="combobox"]').element)
  })

  it('allows clearing when a language is selected', async () => {
    const store = useLanguagesStore()
    store.upsertLanguage(mockLanguage)

    const wrapper = mount(LanguagePicker, {
      props: { modelValue: 'en', label: 'Language' },
    })
    expect(wrapper.find('[data-action="clear"]').exists()).toBe(true)
  })

  it('emits update:modelValue with empty string when cleared', async () => {
    const store = useLanguagesStore()
    store.upsertLanguage(mockLanguage)

    const wrapper = mount(LanguagePicker, {
      props: { modelValue: 'en', label: 'Language' },
    })
    await wrapper.get('[data-action="clear"]').trigger('click')
    expect(wrapper.emitted('update:modelValue')?.[0]).toEqual([''])
  })
})
