import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import EvidenceList from './EvidenceList.vue'
import type { TranslationEvidence } from '@/api/translation'

const direct: TranslationEvidence = {
  source_text: '食飯',
  target_text: 'eat rice',
  target_locale_code: 'eng-Latn-US',
  path_type: 'direct',
  match_type: 'exact',
  source_markers: ['¹'],
}

const twoHop: TranslationEvidence = {
  source_text: '食飯',
  target_text: 'Essen',
  target_locale_code: 'deu-Latn-DE',
  path_type: 'two_hop',
  pivot_lang_code: 'eng',
  match_type: 'prefix',
  source_markers: ['²', '³'],
}

describe('EvidenceList', () => {
  it('describes direct and two-hop paths with match type and markers', () => {
    const wrapper = mount(EvidenceList, { props: { items: [direct, twoHop] } })

    expect(wrapper.get('summary').text()).toContain('Retrieval references')
    expect(wrapper.get('summary').text()).toContain('2 references')

    expect(wrapper.findAll('.evidence-path-value').map((node) => node.text())).toEqual([
      '食飯 → eat rice',
      '食飯 → (eng) → Essen',
    ])
    expect(wrapper.findAll('.evidence-match').map((node) => node.text())).toEqual(['Exact', 'Prefix'])
    expect(wrapper.findAll('.evidence-markers').map((node) => node.text())).toEqual(['¹', '² · ³'])
    expect(wrapper.find('details').exists()).toBe(true)
  })

  it('uses the singular reference count', () => {
    const wrapper = mount(EvidenceList, { props: { items: [direct] } })
    expect(wrapper.get('summary').text()).toContain('1 reference')
  })

  it('shows the degraded and empty messages', () => {
    const wrapper = mount(EvidenceList, { props: { items: [], degraded: true } })
    expect(wrapper.text()).toContain('References could not be retrieved')
    expect(wrapper.text()).toContain('No references found')
  })

  it('never renders internal integer identifiers', () => {
    const withIds = {
      ...direct,
      id: 4242,
      source_expression_id: 7,
      target_expression_id: 9,
    } as unknown as TranslationEvidence
    const wrapper = mount(EvidenceList, { props: { items: [withIds] } })
    expect(wrapper.text()).not.toContain('4242')
    expect(wrapper.html()).not.toContain('4242')
    expect(wrapper.find('[data-evidence-id]').exists()).toBe(false)
  })
})
