import { describe, expect, it } from 'vitest'
import { nextTick } from 'vue'
import { mount } from '@vue/test-utils'
import TranslationProgress from './TranslationProgress.vue'

function mountProgress(props: Record<string, unknown>) {
  return mount(TranslationProgress, {
    props: {
      stage: null,
      mode: null,
      isStreaming: false,
      error: null,
      sourceLanguage: null,
      evidence: null,
      targetLocaleCode: '',
      translation: '',
      result: null,
      ...props,
    },
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

  it('shows intermediate results inside a collapsible process panel', async () => {
    const wrapper = mountProgress({
      stage: 'generating',
      mode: 'assisted',
      isStreaming: true,
      sourceLanguage: { code: 'cmn', confidence: 1 },
      targetLocaleCode: 'nan-Hant-TW',
      evidence: {
        items: [{
          source_text: '这个多少钱？',
          target_text: '這个偌濟錢？',
          target_locale_code: 'nan-Hant-TW',
          reference_locale_codes: ['nan-Hant-TW'],
          path_type: 'direct',
          match_type: 'exact',
          source_markers: [],
        }],
        omittedCount: 0,
        degraded: false,
      },
      translation: '這个偌濟錢啊？',
      result: {
        translation: '這个偌濟錢啊？',
        alternatives: [],
        source_lang_code: 'cmn',
        target_locale_code: 'nan-Hant-TW',
        evidence_present: true,
        model_only: false,
        resolution: 'assisted',
        generation_skipped: false,
      },
    })

    const details = wrapper.get('.translation-process')
    expect(details.attributes('open')).toBeDefined()
    expect(wrapper.get('.process-details').text()).toContain('cmn')
    expect(wrapper.get('.process-details').text()).toContain('nan-Hant-TW')
    expect(wrapper.get('.process-details').text()).toContain('Reference locale')
    expect(wrapper.get('.process-preview').text()).toContain('這个偌濟錢啊？')
    expect(wrapper.get('.process-resolution').text()).toContain('Generated with retrieved references')

    const detailsElement = details.element as HTMLDetailsElement
    detailsElement.open = false
    await details.trigger('toggle')
    expect(details.attributes('open')).toBeUndefined()

    await wrapper.setProps({ isStreaming: false })
    await wrapper.setProps({ isStreaming: true })
    await nextTick()
    expect(details.attributes('open')).toBeDefined()
  })
})
