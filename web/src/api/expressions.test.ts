import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from './client'
import { getExpression, getExpressionEdges, getMappingGraph, splitExpression } from './expressions'

vi.mock('./client', () => ({ default: { get: vi.fn(), post: vi.fn() } }))

describe('expressions API', () => {
  beforeEach(() => vi.mocked(api.get).mockResolvedValue({ data: { data: { items: [] } } }))

  it('builds text-key paths and unwraps the API envelope', async () => {
    const key = { lang_code: 'en', text: 'first' }
    await getExpression(key)
    expect(api.get).toHaveBeenCalledWith('/expressions/en/first', { params: { _content_revision: 0 }, signal: undefined })

    await getMappingGraph({ lang_code: 'en', text: 'first', homograph_index: 2 }, 2)
    expect(api.get).toHaveBeenLastCalledWith('/expressions/en/first~2/graph', { params: { hops: 2, _content_revision: 0 }, signal: undefined })

    await getExpressionEdges(key, 50, 10)
    expect(api.get).toHaveBeenLastCalledWith('/expressions/en/first/edges', { params: { limit: 50, cursor: 10 }, signal: undefined })
  })

  it('still accepts numeric ids for legacy callers', async () => {
    await getExpression('123456')
    expect(api.get).toHaveBeenCalledWith('/expressions/123456', { params: { _content_revision: 0 }, signal: undefined })
  })

  it('round-trips texts containing tilde digits', async () => {
    await getExpression({ lang_code: 'en', text: 'spa~1' })
    expect(api.get).toHaveBeenCalledWith('/expressions/en/spa~1~1', expect.anything())
  })

  it('submits selected edge IDs to the split endpoint and returns the target key', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: { data: { target_expression_id: '123456', target: { lang_code: 'en', text: 'first', homograph_index: 2 } } } })
    const result = await splitExpression({ lang_code: 'en', text: 'first' }, ['01EDGE', '02EDGE'])
    expect(api.post).toHaveBeenCalledWith('/expressions/en/first/split', { edge_ids: ['01EDGE', '02EDGE'] }, { signal: undefined })
    expect(result.target).toEqual({ lang_code: 'en', text: 'first', homograph_index: 2 })
  })
})
