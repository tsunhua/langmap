import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import TranslationProgress from './TranslationProgress.vue'

function mountProgress(props: Record<string, unknown> = {}) {
  return mount(TranslationProgress, { props: { stage: null, isStreaming: false, error: null, result: null, ...props } })
}
describe('TranslationProgress', () => {
  it('announces only the current stage in a single polite line', () => {
    const wrapper = mountProgress({ stage: 'analyzing', isStreaming: true })
    expect(wrapper.text()).toBe('Analyzing the text')
    expect(wrapper.findAll('[role="status"]')).toHaveLength(1)
    expect(wrapper.get('[role="status"]').attributes('aria-live')).toBe('polite')
    expect(wrapper.find('details').exists()).toBe(false)
  })
  it('renders an assertive error and no duplicated status', () => {
    const wrapper = mountProgress({ error: { message: 'Translation timed out.' } })
    expect(wrapper.find('[role="status"]').exists()).toBe(false)
    expect(wrapper.get('[role="alert"]').text()).toBe('Translation timed out.')
    expect(wrapper.get('[role="alert"]').attributes('aria-live')).toBe('assertive')
  })
  it('announces a stopped request without claiming it is still generating', () => {
    expect(mountProgress({ stage: 'generating' }).text()).toBe('Stopped')
  })
})
