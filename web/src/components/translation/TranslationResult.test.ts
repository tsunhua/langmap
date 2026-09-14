import { describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import TranslationResult from './TranslationResult.vue'
import type { TranslationResult as TranslationResultData } from '@/api/translation'

function makeResult(patch: Partial<TranslationResultData> = {}): TranslationResultData {
  return {
    translation: 'Hallo',
    alternatives: [],
    source_lang_code: 'cmn',
    target_locale_code: 'deu-Latn-DE',
    evidence_present: false,
    model_only: false,
    resolution: 'assisted',
    generation_skipped: false,
    ...patch,
  }
}

function mountResult(overrides: Record<string, unknown> = {}) {
  return mount(TranslationResult, {
    props: { translation: 'Hallo', result: null, alternatives: [], isStreaming: false, ...overrides },
  })
}

describe('TranslationResult', () => {
  it('shows the exact match status without an AI-assisted badge', () => {
    const wrapper = mountResult({ result: makeResult({ resolution: 'exact_lookup', generation_skipped: true }) })
    expect(wrapper.text()).toContain('Exact match')
    expect(wrapper.text()).not.toContain('AI-assisted')
    expect(wrapper.text()).not.toContain('Model-generated only')
  })

  it('shows the model-only status', () => {
    const wrapper = mountResult({ result: makeResult({ model_only: true }) })
    expect(wrapper.text()).toContain('Model-generated only')
  })

  it('badges assisted results as AI-assisted', () => {
    const wrapper = mountResult({ result: makeResult({ resolution: 'assisted' }) })
    expect(wrapper.text()).toContain('AI-assisted')
  })

  it('renders at most two reference alternatives', () => {
    const wrapper = mountResult({ alternatives: ['eins', 'zwei', 'drei'], result: makeResult() })
    const items = wrapper.findAll('.alternatives li')
    expect(items).toHaveLength(2)
    expect(items.map((item) => item.text())).toEqual(['eins', 'zwei'])
    expect(wrapper.text()).toContain('Reference translations')
  })

  it('copies the translation and reflects the copied state', async () => {
    const writeText = vi.fn().mockResolvedValue(undefined)
    Object.defineProperty(navigator, 'clipboard', { configurable: true, value: { writeText } })
    const wrapper = mountResult()
    await wrapper.get('[data-action="copy"]').trigger('click')
    await flushPromises()
    expect(writeText).toHaveBeenCalledWith('Hallo')
    expect(wrapper.text()).toContain('Copied')
  })

  it('emits retry and edit, and only sends to contribute with a result', async () => {
    const wrapper = mountResult()
    await wrapper.get('[data-action="retry"]').trigger('click')
    await wrapper.get('[data-action="edit"]').trigger('click')
    await wrapper.get('[data-action="send-to-contribute"]').trigger('click')
    expect(wrapper.emitted('retry')).toHaveLength(1)
    expect(wrapper.emitted('edit')).toHaveLength(1)
    expect(wrapper.emitted('send-to-contribute')).toBeUndefined()

    const withResult = mountResult({ result: makeResult() })
    await withResult.get('[data-action="send-to-contribute"]').trigger('click')
    expect(withResult.emitted('send-to-contribute')).toHaveLength(1)
  })

  it('renders the translation as escaped plain text, never as HTML', () => {
    const wrapper = mountResult({ translation: '<b>bold</b>' })
    expect(wrapper.get('.translation').text()).toBe('<b>bold</b>')
    expect(wrapper.find('.translation b').exists()).toBe(false)
    expect(wrapper.html()).toContain('&lt;b&gt;')
  })
})
