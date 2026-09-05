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
        readings: [
          { id: 'r-tw', expression_id: 'nan:食', language_locale_code: 'nan-Hant-TW', locale_display_name: '臺語', scheme: 'ipa', value: 'tsiaʔ', source_id: null, source_ref: null, created_at: '2026-01-03' },
          { id: 'r-cn', expression_id: 'nan:食', language_locale_code: 'nan-Hant-CN', scheme: 'ipa', value: 'tsiaʔ', source_id: null, source_ref: null, created_at: '2026-01-04' },
        ],
      },
    })
    expect(wrapper.findAll('[data-evidence-code]').map((item) => item.attributes('data-evidence-code')))
      .toEqual(['nan-Hant-CN', 'nan-Hant-TW', 'ipa / tsiaʔ'])
    expect(wrapper.findAll('li')[0].text()).toContain('nan-Hant-CN')
    expect(wrapper.findAll('li')[1].text()).toContain('臺語')
    expect(wrapper.findAll('li')[1].text()).not.toContain('nan-Hant-TW')
    expect(wrapper.findAll('li')[2].text()).toContain('臺語')
    expect(wrapper.findAll('li')[1].find('[title="nan-Hant-TW"]').attributes('title')).toBe('nan-Hant-TW')
    expect(wrapper.findAll('li')[2].text()).toContain('tsiaʔ')
    expect(wrapper.findAll('li')[2].text()).toContain('CN, TW · 臺語')
    expect(wrapper.findAll('li')[2].text()).toContain('(CN, TW · 臺語)')
    expect(wrapper.findAll('li')[2].text()).not.toContain('IPA')
    expect(wrapper.findAll('li')[2].text()).not.toContain('nan-Hant-TW')
  })

  it('keeps scheme labels when readings use multiple schemes', () => {
    const wrapper = mount(ExpressionEvidenceList, {
      props: {
        readings: [
          { language_locale_code: 'nan-Hant-TW', scheme: 'ipa', value: 'tsiaʔ' },
          { language_locale_code: 'nan-Hant-TW', scheme: 'pinyin', value: 'tsia' },
        ],
      },
    })

    expect(wrapper.findAll('.rx-item')).toHaveLength(2)
    expect(wrapper.text()).toContain('IPA · (TW)')
    expect(wrapper.text()).toContain('漢語拼音 · (TW)')
  })

  it('merges readings that differ only by whitespace and keeps the spaced value', () => {
    const wrapper = mount(ExpressionEvidenceList, {
      props: {
        readings: [
          { language_locale_code: 'cmn-Hant-TW', scheme: 'pinyin', value: 'chǎojià' },
          { language_locale_code: 'cmn-Hant-TW', scheme: 'pinyin', value: 'chǎo jià' },
        ],
      },
    })

    expect(wrapper.findAll('.rx-item')).toHaveLength(1)
    expect(wrapper.find('.rx-item').text()).toContain('chǎo jià')
    expect(wrapper.find('.rx-item').text()).not.toContain('chǎojià')
  })

  it('uses the local name for extended locale readings', () => {
    const wrapper = mount(ExpressionEvidenceList, {
      props: {
        readings: [{ language_locale_code: 'hak-Hant-TW_Dapu', locale_display_name: '客語（大埔腔）', scheme: 'hakka-pinyin', value: 'gung33 ngi53' }],
      },
    })
    expect(wrapper.text()).toContain('大埔')
    expect(wrapper.text()).not.toContain('客語（大埔腔）')
    expect(wrapper.text()).not.toContain('hak-Hant-TW_Dapu')
  })
})
