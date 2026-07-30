import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import LanguageTagBuilder from './LanguageTagBuilder.vue'

describe('LanguageTagBuilder', () => {
  it('shows the Variant field label once', () => {
    const wrapper = mount(LanguageTagBuilder, {
      props: {
        modelValue: {
          language: '',
          script: null,
          region: null,
          variants: [],
          private_use: [],
        },
      },
    })

    expect(wrapper.findAll('.subtag-label').filter(label => label.text().startsWith('Variant'))).toHaveLength(1)
  })
})
