import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from './client'
import { listLanguageSubtags } from './languages'

vi.mock('./client', () => ({
  default: {
    get: vi.fn(),
  },
}))

describe('listLanguageSubtags', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('normalizes D1 subtag rows for the UI', async () => {
    vi.mocked(api.get).mockResolvedValue({
      data: {
        data: {
          items: [{
            type: 'language',
            value: 'es',
            descriptions: '["Spanish","Castilian"]',
            prefixes: '[]',
            preferred_value: null,
            suppress_script: 'Latn',
            deprecated: null,
          }],
        },
      },
    })

    await expect(listLanguageSubtags('language', 'es')).resolves.toEqual([{
      type: 'language',
      subtag: 'es',
      descriptions: ['Spanish', 'Castilian'],
      prefixes: [],
      preferred_value: null,
      suppress_script: 'Latn',
      deprecated_at: null,
    }])
  })
})
