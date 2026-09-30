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
    attachTo: document.body,
    props: { translation: 'Hallo', result: null, alternatives: [], ...overrides },
  })
}

describe('TranslationResult', () => {
  it('shows the exact match status without an AI-assisted badge', () => {
    const wrapper = mountResult({ result: makeResult({ resolution: 'exact_lookup', generation_skipped: true }) })
    expect(wrapper.text()).toContain('Exact match')
    expect(wrapper.text()).not.toContain('AI-assisted')
    expect(wrapper.text()).not.toContain('Model-generated only')
  })

  it('keeps exact and model-only status mutually exclusive', () => {
    const wrapper = mountResult({ result: makeResult({ resolution: 'exact_lookup', model_only: true }) })
    expect(wrapper.text()).toContain('Exact match')
    expect(wrapper.text()).not.toContain('Model-generated only')
    expect(wrapper.text()).not.toContain('AI-assisted')
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
    const wrapper = mountResult({ alternatives: ['eins', 'zwei', 'drei'], result: makeResult({ resolution: 'exact_lookup' }) })
    const items = wrapper.findAll('.alternatives li')
    expect(items).toHaveLength(2)
    expect(items.map((item) => item.text())).toEqual(['eins', 'zwei'])
    expect(wrapper.text()).toContain('Reference translations')
  })

  it('hides assisted snippets as whole-sentence alternatives', () => {
    const wrapper = mountResult({ alternatives: ['word fragment'], result: makeResult() })
    expect(wrapper.find('.alternatives').exists()).toBe(false)
  })

  it('selects the longest real evidence phrase, preserves the sentence, and closes with Escape', async () => {
    const wrapper = mountResult({ translation: '😀 railway station\nstation', result: makeResult(), evidence: [
      { source_text: '車站', target_text: 'railway station', target_locale_code: 'eng-Latn-US', reference_locale_codes: ['eng-Latn-GB'], path_type: 'direct', match_type: 'exact', source_markers: ['dictionary:1'] },
      { source_text: '站', target_text: 'station', target_locale_code: 'eng-Latn-US', path_type: 'direct', match_type: 'exact', source_markers: ['dictionary:2'] },
    ] })
    expect(wrapper.get('.translation').text()).toBe('😀 railway station\nstation')
    expect(wrapper.find('.reference-panel').exists()).toBe(false)
    await wrapper.get('[data-term="railway station"]').trigger('click')
    expect(wrapper.get('.reference-panel').text()).toContain('車站')
    expect(wrapper.get('.reference-panel').text()).not.toContain('dictionary:2')
    expect(wrapper.get('.reference-panel').text()).toContain('eng-Latn-GB')
    await wrapper.get('.translation-result').trigger('keydown', { key: 'Escape' })
    expect(wrapper.find('.reference-panel').exists()).toBe(false)
    expect(document.activeElement).toBe(wrapper.get('[data-term="railway station"]').element)
  })

  it('keeps individual words selectable when exact evidence covers the complete sentence', () => {
    const wrapper = mountResult({
      translation: '最近的火車站在哪裡？',
      result: makeResult({ resolution: 'exact_lookup', translation: '最近的火車站在哪裡？', target_locale_code: 'cmn-Hant-TW' }),
      evidence: [{ source_text: 'Where is the nearest train station?', target_text: '最近的火車站在哪裡？', target_locale_code: 'cmn-Hant-TW', reference_locale_codes: ['cmn-Hant-TW'], path_type: 'direct', match_type: 'exact', source_markers: ['dictionary:1'] }],
    })
    expect(wrapper.find('[data-term="最近的火車站在哪裡？"]').exists()).toBe(false)
    expect(wrapper.find('[data-term="火車站"]').exists()).toBe(true)
    expect(wrapper.get('.translation').text()).toBe('最近的火車站在哪裡？')
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

  it('hides send-to-contribute for exact matches and never emits it', async () => {
    const wrapper = mountResult({ allowContribute: true, result: makeResult({ resolution: 'exact_lookup', generation_skipped: true }) })
    expect(wrapper.find('[data-action="send-to-contribute"]').exists()).toBe(false)
    expect(wrapper.emitted('send-to-contribute')).toBeUndefined()
  })

  it('hides send-to-contribute for an anonymous assisted result', () => {
    const wrapper = mountResult({ result: makeResult({ resolution: 'assisted' }) })
    expect(wrapper.find('[data-action="send-to-contribute"]').exists()).toBe(false)
  })

  it('offers send-to-contribute for assisted results', () => {
    const wrapper = mountResult({ allowContribute: true, result: makeResult({ resolution: 'assisted' }) })
    expect(wrapper.find('[data-action="send-to-contribute"]').exists()).toBe(true)
  })

  it('emits retry and edit, and only sends to contribute with an assisted result', async () => {
    const noResult = mountResult()
    await noResult.get('[data-action="retry"]').trigger('click')
    await noResult.get('[data-action="edit"]').trigger('click')
    expect(noResult.find('[data-action="send-to-contribute"]').exists()).toBe(false)
    expect(noResult.emitted('retry')).toHaveLength(1)
    expect(noResult.emitted('edit')).toHaveLength(1)
    expect(noResult.emitted('send-to-contribute')).toBeUndefined()

    const withResult = mountResult({ allowContribute: true, result: makeResult() })
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
