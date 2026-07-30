import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import GlottologMatchList from './GlottologMatchList.vue'

describe('GlottologMatchList', () => {
  it('allows explicitly choosing no match', async () => {
    const wrapper = mount(GlottologMatchList, {
      props: {
        candidates: [],
        selectedGlottocode: null,
        hasSelection: false,
        loading: false,
      },
    })
    const noMatch = wrapper.get<HTMLInputElement>('[data-choice="no-match"]')

    expect(noMatch.element.checked).toBe(false)
    await noMatch.setValue(true)
    expect(wrapper.emitted('select')).toEqual([[null]])
  })
})
