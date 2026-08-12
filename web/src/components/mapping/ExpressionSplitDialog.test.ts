import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ExpressionSplitDialog from './ExpressionSplitDialog.vue'

describe('ExpressionSplitDialog', () => {
  it('requires an edge selection and displays the non-copy warning', () => {
    const wrapper = mount(ExpressionSplitDialog, { props: { edges: [], submitting: false } })
    expect(wrapper.text()).toContain('Readings, locale attestations and handbook items will not be copied')
    expect(wrapper.get('[data-action="confirm-split"]').attributes('disabled')).toBeDefined()
  })
})
