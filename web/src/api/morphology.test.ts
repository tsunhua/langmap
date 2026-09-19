import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from './client'
import { createFormEdge, getExpressionFormEdges, listMorphologicalFeatures } from './morphology'

vi.mock('./client', () => ({ default: { get: vi.fn(), post: vi.fn() } }))

describe('morphology API', () => {
  beforeEach(() => {
    vi.mocked(api.get).mockResolvedValue({ data: { data: { dimensions: [] } } })
    vi.mocked(api.post).mockResolvedValue({ data: { data: { created: true } } })
  })

  it('unwraps the features registry and form-edge endpoints', async () => {
    await listMorphologicalFeatures({ ui_locale: 'cmn-Hant-TW' })
    expect(api.get).toHaveBeenCalledWith('/morphological-features', {
      params: { ui_locale: 'cmn-Hant-TW' },
      signal: undefined,
    })

    await getExpressionFormEdges({ lang_code: 'spa', text: 'gatas' }, { limit: 50, ui_locale: 'eng-Latn-US' })
    expect(api.get).toHaveBeenLastCalledWith('/expressions/spa/gatas/form-edges', {
      params: { limit: 50, ui_locale: 'eng-Latn-US' },
      signal: undefined,
    })
  })

  it('posts a form edge with optional features', async () => {
    await createFormEdge({ lang_code: 'spa', text: 'gatas' }, { lemma_expression_id: '123', features: ['plural'] })
    expect(api.post).toHaveBeenCalledWith(
      '/expressions/spa/gatas/form-edges',
      { lemma_expression_id: '123', features: ['plural'] },
      { params: {}, signal: undefined },
    )
  })
})
