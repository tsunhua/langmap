import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import ExpressionEvidenceList from './ExpressionEvidenceList.vue'

describe('ExpressionEvidenceList', () => {
  it('groups locale attestations before readings in stable order', () => {
    const wrapper = mount(ExpressionEvidenceList, {
      props: {
        attestations: [
          { id: 'b', expression_id: 'nan:食', language_locale_code: 'nan-Hant-TW', locale_display_name: '臺語', source_id: null, source_ref: null, created_at: '2026-01-02' },
          { id: 'a', expression_id: 'nan:食', language_locale_code: 'nan-Hant-CN', source_id: null, source_ref: null, created_at: '2026-01-01' },
        ],
        readings: [{ id: 'r', expression_id: 'nan:食', language_locale_code: 'nan-Hant-TW', locale_display_name: '臺語', scheme: 'ipa', value: 'tsiaʔ', source_id: null, source_ref: null, created_at: '2026-01-03' }],
      },
    })
    expect(wrapper.findAll('[data-evidence-code]').map((item) => item.attributes('data-evidence-code')))
      .toEqual(['nan-Hant-CN', 'nan-Hant-TW', 'nan-Hant-TW / ipa'])
    expect(wrapper.findAll('li')[0].text()).toContain('nan-Hant-CN')
    expect(wrapper.findAll('li')[1].text()).toContain('臺語')
    expect(wrapper.findAll('li')[2].text()).toContain('臺語')
    expect(wrapper.findAll('li')[1].find('[title="臺語"]').attributes('title')).toBe('臺語')
    expect(wrapper.findAll('li')[2].text()).toContain('tsiaʔ')
    expect(wrapper.findAll('li')[2].text()).toContain('TW · 臺語')
    expect(wrapper.findAll('li')[2].text()).toContain('/ ipa')
    expect(wrapper.findAll('li')[2].text()).not.toContain('nan-Hant-TW')
  })
})
