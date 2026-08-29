import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MorphologyPanel from './MorphologyPanel.vue'
import {
  getExpressionFormEdges,
  listMorphologicalFeatures,
} from '@/api/morphology'

vi.mock('@/api/morphology', () => ({
  getExpressionFormEdges: vi.fn(),
  listMorphologicalFeatures: vi.fn(),
  createFormEdge: vi.fn(),
}))
vi.mock('@/composables/useExpressions', () => ({
  useExpressions: () => ({ search: vi.fn().mockResolvedValue({ items: [] }) }),
}))

const RouterLinkStub = {
  props: ['to'],
  template: '<a :href="typeof to === \'string\' ? to : to.path"><slot /></a>',
}

function formEdges(overrides: Record<string, unknown> = {}) {
  return {
    as_form: [],
    as_lemma: [],
    as_form_truncated: false,
    as_form_omitted_count: 0,
    as_lemma_truncated: false,
    as_lemma_omitted_count: 0,
    ...overrides,
  }
}

function mountPanel(text = 'gatas', formOpen = false) {
  const pinia = createPinia()
  setActivePinia(pinia)
  return mount(MorphologyPanel, {
    props: { expressionId: 'spa:gatas', langCode: 'spa', text, formOpen },
    global: {
      plugins: [pinia],
      stubs: { RouterLink: RouterLinkStub },
    },
  })
}

describe('MorphologyPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setActivePinia(createPinia())
    vi.mocked(listMorphologicalFeatures).mockResolvedValue({ dimensions: [] })
  })

  it('shows dictionary forms as chips labelled with their role and keeps the features', async () => {
    vi.mocked(getExpressionFormEdges).mockResolvedValue(formEdges({
      as_form: [{
        edge_id: 'e1',
        lemma: { id: 'spa:gato', text: 'gato', lang_code: 'spa', language_name: 'Spanish' },
        features: [
          { code: 'feminine', name: 'feminine', dimension_code: 'gender' },
          { code: 'plural', name: 'plural', dimension_code: 'number' },
        ],
      }],
    }))

    const wrapper = mountPanel()
    await flushPromises()

    const chip = wrapper.get('a.morph-form-chip')
    expect(chip.attributes('href')).toBe('/mapping/spa:gato')
    expect(chip.text()).toContain('Dictionary form：gato')
    expect(chip.text()).toContain('feminine plural')
    expect(wrapper.text()).not.toContain('Mappings of the dictionary form')
    expect(wrapper.text()).not.toContain('cat')
    expect(getExpressionFormEdges).toHaveBeenCalledWith(
      'spa:gatas',
      expect.objectContaining({ limit: 50 }),
      expect.any(AbortSignal),
    )
  })

  it('shows inflected forms as flat chips labelled with their features', async () => {
    vi.mocked(getExpressionFormEdges).mockResolvedValue(formEdges({
      as_lemma: [
        {
          edge_id: 'e1',
          form: { id: 'spa:gatas', text: 'gatas', lang_code: 'spa', language_name: 'Spanish' },
          features: [{ code: 'plural', name: 'plural', dimension_code: 'number' }],
        },
        {
          edge_id: 'e2',
          form: { id: 'spa:gata', text: 'gata', lang_code: 'spa', language_name: 'Spanish' },
          features: [{ code: 'feminine', name: 'feminine', dimension_code: 'gender' }],
        },
        {
          edge_id: 'e3',
          form: { id: 'spa:gatito', text: 'gatito', lang_code: 'spa', language_name: 'Spanish' },
          features: [],
        },
      ],
    }))
    vi.mocked(listMorphologicalFeatures).mockResolvedValue({
      dimensions: [
        { code: 'number', name: 'number', name_en: 'number', sort_order: 10, features: [] },
        { code: 'gender', name: 'gender', name_en: 'gender', sort_order: 20, features: [] },
      ],
    })

    const wrapper = mountPanel()
    await flushPromises()

    const chips = wrapper.findAll('a.morph-form-chip')
    expect(chips).toHaveLength(3)
    expect(chips[0].text()).toContain('plural：gatas')
    expect(chips[0].attributes('href')).toBe('/mapping/spa:gatas')
    expect(chips[1].text()).toContain('feminine：gata')
    expect(chips[2].text()).toBe('gatito')
    expect(wrapper.text()).not.toContain('Mappings of the dictionary form')
  })

  it('hides the panel when word forms fail to load', async () => {
    vi.mocked(getExpressionFormEdges).mockRejectedValue({
      response: { data: { message: 'form edges down' } },
    })

    const wrapper = mountPanel()
    await flushPromises()

    expect(wrapper.find('[role="alert"]').exists()).toBe(false)
    expect(wrapper.text()).not.toContain('Word forms')
  })

  it('hides the panel when form edges are not available', async () => {
    vi.mocked(getExpressionFormEdges).mockRejectedValue({
      response: { status: 404, data: { error: 'NOT_FOUND' } },
    })

    const wrapper = mountPanel()
    await flushPromises()

    expect(wrapper.find('[role="alert"]').exists()).toBe(false)
    expect(wrapper.text()).not.toContain('Word forms')
  })

  it('shows the mark-as-form form only when formOpen is set', async () => {
    vi.mocked(getExpressionFormEdges).mockResolvedValue(formEdges())

    const closed = mountPanel()
    await flushPromises()
    expect(closed.text()).not.toContain('Word forms')

    const wrapper = mountPanel('gatas', true)
    await flushPromises()
    expect(wrapper.text()).toContain('Word forms')
    expect(wrapper.text()).toContain('Mark as a form of…')
    expect(wrapper.text()).toContain('Save form link')
  })

  it('hides the whole panel for expressions that are not single words', async () => {
    vi.mocked(getExpressionFormEdges).mockResolvedValue(formEdges())
    const wrapper = mountPanel('+ 添加词句')
    await flushPromises()
    expect(wrapper.text()).not.toContain('Word forms')
    expect(wrapper.text()).not.toContain('Add a word-form link')
    expect(getExpressionFormEdges).not.toHaveBeenCalled()
  })

  it('shows noun features only after a word class is chosen', async () => {
    vi.mocked(getExpressionFormEdges).mockResolvedValue(formEdges())
    vi.mocked(listMorphologicalFeatures).mockResolvedValue({
      dimensions: [
        {
          code: 'gender', name: 'gender', name_en: 'gender', sort_order: 10,
          features: [
            { code: 'feminine', name: 'feminine', name_en: 'feminine', sort_order: 2 },
            { code: 'masculine', name: 'masculine', name_en: 'masculine', sort_order: 1 },
          ],
        },
        {
          code: 'mood', name: 'mood', name_en: 'mood', sort_order: 50,
          features: [
            { code: 'subjunctive', name: 'subjunctive', name_en: 'subjunctive', sort_order: 2 },
          ],
        },
        {
          code: 'construction', name: 'construction', name_en: 'construction', sort_order: 110,
          features: [
            { code: 'te-form', name: 'te-form', name_en: 'te-form', sort_order: 1 },
          ],
        },
      ],
    })
    const wrapper = mountPanel('gatas', true)
    await flushPromises()
    expect(wrapper.text()).toContain('Noun')
    expect(wrapper.text()).not.toContain('feminine')
    await wrapper.get('input[value="noun"]').trigger('change')
    expect(wrapper.text()).toContain('feminine')
    expect(wrapper.text()).not.toContain('subjunctive')
    expect(wrapper.text()).not.toContain('te-form')
  })

  it('allows only one feature per dimension card', async () => {
    vi.mocked(getExpressionFormEdges).mockResolvedValue(formEdges())
    vi.mocked(listMorphologicalFeatures).mockResolvedValue({
      dimensions: [{
        code: 'gender', name: 'gender', name_en: 'gender', sort_order: 10,
        features: [
          { code: 'feminine', name: 'feminine', name_en: 'feminine', sort_order: 2 },
          { code: 'masculine', name: 'masculine', name_en: 'masculine', sort_order: 1 },
        ],
      }],
    })
    const wrapper = mountPanel('gatas', true)
    await flushPromises()
    await wrapper.get('input[value="noun"]').trigger('change')

    const featureInputs = wrapper.findAll('input[type="radio"]').filter((input) => input.attributes('value') === 'feminine' || input.attributes('value') === 'masculine')
    expect(featureInputs).toHaveLength(2)
    expect(featureInputs.every((input) => input.attributes('name') === 'morph-feature-gender')).toBe(true)
  })
})
