import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ExpressionRow from './ExpressionRow.vue'

const RouterLinkStub = {
  props: ['to'],
  template: '<a :href="to"><slot /></a>',
}

function mountRow(props: Record<string, unknown> = {}) {
  return mount(ExpressionRow, {
    props: {
      id: 'spa:gatas',
      text: 'gatas',
      lang_code: 'spa',
      language_name: 'Spanish',
      ...props,
    },
    global: {
      stubs: { RouterLink: RouterLinkStub },
    },
  })
}

describe('ExpressionRow', () => {
  it('shows a form-of summary when form_of is present', () => {
    const wrapper = mountRow({
      form_of: [
        {
          lemma: { id: 'spa:gato', text: 'gato', lang_code: 'spa' },
          features: [
            { code: 'feminine', name: 'feminine' },
            { code: 'plural', name: 'plural' },
          ],
        },
      ],
    })
    expect(wrapper.get('.ex-form').text()).toBe('feminine plural ← gato')
    expect(wrapper.get('.ex-form').attributes('aria-label')).toContain('gato')
    expect(wrapper.get('.ex-form').attributes('aria-label')).toContain('feminine')
  })

  it('hides the form-of line when form_of is empty', () => {
    expect(mountRow().find('.ex-forms').exists()).toBe(false)
    expect(mountRow({ form_of: [] }).find('.ex-forms').exists()).toBe(false)
  })

  it('shows an x-image expression as a thumbnail', () => {
    const wrapper = mountRow({
      text: 'https://example.com/image.jpg',
      lang_code: 'x-image',
      source_type: 'x-image',
    })

    expect(wrapper.find('.ex-image').attributes('src')).toBe('https://example.com/image.jpg')
    expect(wrapper.find('.ex-tx').exists()).toBe(false)
  })

  it('keeps invalid image values as text', () => {
    const wrapper = mountRow({ text: 'not-a-url', lang_code: 'x-image', source_type: 'x-image' })

    expect(wrapper.find('.ex-image').exists()).toBe(false)
    expect(wrapper.find('.ex-tx').text()).toBe('not-a-url')
  })

  it.each(['x-image', 'x-emoji'])('hides form-of summaries for %s expressions', (lang_code) => {
    const wrapper = mountRow({
      lang_code,
      form_of: [{
        lemma: { id: 'eng:base', text: 'base', lang_code: 'eng' },
        features: [{ code: 'plural', name: 'plural' }],
      }],
    })

    expect(wrapper.find('.ex-forms').exists()).toBe(false)
  })
})
