import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import TranslationProgress from './TranslationProgress.vue'

function mountProgress(props: Record<string, unknown>) {
  return mount(TranslationProgress, {
    props: { stage: null, mode: null, isStreaming: false, error: null, ...props },
  })
}

describe('TranslationProgress', () => {
  it('renders the three assisted stages as readable text', () => {
    const wrapper = mountProgress({ stage: 'analyzing', mode: 'assisted', isStreaming: true })
    expect(wrapper.text()).toContain('Analyzing the text')
    expect(wrapper.text()).toContain('Retrieving references')
    expect(wrapper.text()).toContain('Generating the translation')
    expect(wrapper.find('[role="status"]').exists()).toBe(true)
    expect(wrapper.get('[role="status"]').attributes('aria-live')).toBe('polite')
  })

  it('shows only the retrieving stage for the exact lookup fast path', () => {
    const wrapper = mountProgress({ stage: 'retrieving', mode: 'exact_lookup', isStreaming: true })
    expect(wrapper.text()).toContain('Retrieving references')
    expect(wrapper.text()).not.toContain('Analyzing the text')
    expect(wrapper.text()).not.toContain('Generating the translation')
  })

  it('marks completed and active stages without relying on colour alone', () => {
    const wrapper = mountProgress({ stage: 'generating', mode: 'assisted', isStreaming: true })
    const states = wrapper.findAll('.stage').map((stage) => stage.attributes('data-state'))
    expect(states).toEqual(['done', 'done', 'active'])
    expect(wrapper.get('.stage[data-state="active"]').attributes('aria-current')).toBe('step')
  })

  it('renders an alert when the stream fails', () => {
    const wrapper = mountProgress({ error: { message: 'Translation timed out.' } })
    expect(wrapper.find('[role="status"]').exists()).toBe(false)
    const alert = wrapper.get('[role="alert"]')
    expect(alert.text()).toContain('Translation timed out.')
    expect(alert.attributes('aria-live')).toBe('assertive')
  })
})
