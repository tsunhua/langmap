import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from './client'
import { getHandbookTranslations } from './handbooks'

vi.mock('./client', () => ({ default: { get: vi.fn() } }))

describe('handbooks API', () => {
  beforeEach(() => vi.mocked(api.get).mockResolvedValue({ data: { data: { target_locale: 'jpn-Jpan-JP', items: [] } } }))

  it('encodes handbook id, sends exact target locale and unwraps the envelope', async () => {
    await getHandbookTranslations('handbook/1', 'jpn-Jpan-JP', { ui_locale: 'eng-Latn-US', secondary_ui_locale: 'cmn-Hant-TW' })

    expect(api.get).toHaveBeenCalledWith('/handbooks/handbook%2F1/translations', {
      params: {
        target_locale: 'jpn-Jpan-JP',
        _content_revision: 0,
        ui_locale: 'eng-Latn-US',
        secondary_ui_locale: 'cmn-Hant-TW',
      },
      signal: undefined,
    })
  })
})
