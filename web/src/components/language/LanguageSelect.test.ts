import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'
import LanguageSelect from './LanguageSelect.vue'

vi.mock('@/stores/languages', () => ({
  useLanguagesStore: () => ({
    fetchLanguages: vi.fn().mockResolvedValue(undefined),
    getName: (code: string) => code,
  }),
}))

const options = [
  { code: 'jpn', name: 'Japanese', count: 4 },
  { code: 'eng', name: 'English', count: 2 },
]

describe('LanguageSelect', () => {
  it('shows all options when focused without a query and includes counts', async () => {
    const wrapper = mount(LanguageSelect, { props: { modelValue: [], options } })
    await wrapper.get('input').trigger('focus')
    expect(wrapper.findAll('[role="option"]').map((item) => item.text())).toEqual([
      'Japanesejpn4', 'Englisheng2',
    ])
  })

  it('filters locally by name and code and does not hide other options after selection', async () => {
    const wrapper = mount(LanguageSelect, { props: { modelValue: [], options } })
    await wrapper.get('input').trigger('focus')
    await wrapper.get('input').setValue('eng')
    expect(wrapper.findAll('[role="option"]')).toHaveLength(1)
    await wrapper.get('[role="option"]').trigger('mousedown')
    await wrapper.setProps({ modelValue: ['eng'] })
    await wrapper.get('input').setValue('')
    expect(wrapper.findAll('[role="option"]')).toHaveLength(1)
    expect(wrapper.text()).toContain('Japanese')
  })

  it('keeps a URL-selected option visible as a tag even when it is not available', async () => {
    const wrapper = mount(LanguageSelect, { props: { modelValue: ['cmn'], options } })
    expect(wrapper.find('.lang-tag').text()).toContain('cmn')
    await wrapper.get('input').trigger('focus')
    expect(wrapper.findAll('[role="option"]').map((item) => item.text())).toEqual([
      'Japanesejpn4', 'Englisheng2',
    ])
  })

  it('shows every available language instead of capping the graph-derived list', async () => {
    const manyOptions = Array.from({ length: 21 }, (_, index) => ({
      code: `l${index}`,
      name: `Language ${index}`,
      count: 1,
    }))
    const wrapper = mount(LanguageSelect, { props: { modelValue: [], options: manyOptions } })
    await wrapper.get('input').trigger('focus')
    expect(wrapper.findAll('[role="option"]')).toHaveLength(21)
  })
})
