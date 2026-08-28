import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from './client'
import { listUiLocales } from './localization'

vi.mock('./client', () => ({ default: { get: vi.fn() } }))

describe('localization API', () => {
  beforeEach(() => vi.mocked(api.get).mockResolvedValue({ data: { data: [] } }))

  it('uses the current content revision when listing UI locales', async () => {
    await listUiLocales()

    expect(api.get).toHaveBeenCalledWith('/localization/projects/langmap-web/locales', {
      params: { _content_revision: 0 },
    })
  })
})
