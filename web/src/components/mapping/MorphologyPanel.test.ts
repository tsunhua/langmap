import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MorphologyPanel from './MorphologyPanel.vue'
import { useAuthStore } from '@/stores/auth'
import {
  getExpressionFormEdges,
  listMorphologicalFeatures,
} from '@/api/morphology'
import { getMappingGraph } from '@/api/expressions'

vi.mock('@/api/morphology', () => ({
  getExpressionFormEdges: vi.fn(),
  listMorphologicalFeatures: vi.fn(),
  createFormEdge: vi.fn(),
}))
vi.mock('@/api/expressions', () => ({
  getMappingGraph: vi.fn(),
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

function mountPanel() {
  const pinia = createPinia()
  setActivePinia(pinia)
  return mount(MorphologyPanel, {
    props: { expressionId: 'spa:gatas', langCode: 'spa' },
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
    vi.mocked(getMappingGraph).mockResolvedValue({
      root_id: 'spa:gato',
      requested_hops: 1,
      resolved_hops: 1,
      nodes: [
        { expression_id: 'spa:gato', text: 'gato', lang_code: 'spa', language_name: 'Spanish', depth: 0 },
        { expression_id: 'eng:cat', text: 'cat', lang_code: 'eng', language_name: 'English', depth: 1 },
      ],
      edges: [],
      layer_counts: { 0: 1, 1: 1 },
      truncated: false,
      omitted_count: 0,
    })
  })

  it('lists dictionary forms from as_form and keeps lemma mappings in the panel', async () => {
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

    expect(wrapper.text()).toContain('feminine plural ←')
    expect(wrapper.text()).toContain('gato')
    expect(wrapper.text()).toContain('cat')
    expect(wrapper.text()).toContain('Mappings of the dictionary form')
    expect(getExpressionFormEdges).toHaveBeenCalledWith(
      'spa:gatas',
      expect.objectContaining({ limit: 50 }),
      expect.any(AbortSignal),
    )
  })

  it('keeps a load failure inside the panel', async () => {
    vi.mocked(getExpressionFormEdges).mockRejectedValue({
      response: { data: { message: 'form edges down' } },
    })

    const wrapper = mountPanel()
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toBe('form edges down')
    expect(wrapper.text()).toContain('Word forms')
  })

  it('keeps the mark-as-form controls collapsed until opened', async () => {
    vi.mocked(getExpressionFormEdges).mockResolvedValue(formEdges())
    const wrapper = mountPanel()
    await flushPromises()
    expect(wrapper.text()).toContain('Sign in to add a word-form link')
    expect(wrapper.text()).not.toContain('Add a word-form link')
    const auth = useAuthStore()
    auth.token = 'session'
    await wrapper.vm.$nextTick()
    expect(wrapper.text()).toContain('Add a word-form link')
    expect(wrapper.text()).not.toContain('Save form link')
    await wrapper.get('[aria-controls="morph-form"]').trigger('click')
    expect(wrapper.text()).toContain('Save form link')
    expect(wrapper.text()).toContain('Features')
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
    const wrapper = mountPanel()
    await flushPromises()
    const auth = useAuthStore()
    auth.token = 'session'
    await wrapper.vm.$nextTick()
    await wrapper.get('[aria-controls="morph-form"]').trigger('click')
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
    const wrapper = mountPanel()
    await flushPromises()
    const auth = useAuthStore()
    auth.token = 'session'
    await wrapper.vm.$nextTick()
    await wrapper.get('[aria-controls="morph-form"]').trigger('click')
    await wrapper.get('input[value="noun"]').trigger('change')

    const featureInputs = wrapper.findAll('input[type="radio"]').filter((input) => input.attributes('value') === 'feminine' || input.attributes('value') === 'masculine')
    expect(featureInputs).toHaveLength(2)
    expect(featureInputs.every((input) => input.attributes('name') === 'morph-feature-gender')).toBe(true)
  })
})
