import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from './client'
import { getExpression, getExpressionEdges, getMappingGraph, splitExpression } from './expressions'

vi.mock('./client', () => ({ default: { get: vi.fn(), post: vi.fn() } }))

describe('expressions API', () => {
  beforeEach(() => vi.mocked(api.get).mockResolvedValue({ data: { data: { items: [] } } }))

  it('encodes IDs and unwraps the API envelope', async () => {
    const id = '123456'
    await getExpression(id)
    expect(api.get).toHaveBeenCalledWith(`/expressions/${id}`, { params: { _content_revision: 0 }, signal: undefined })

    await getMappingGraph(id, 2)
    expect(api.get).toHaveBeenLastCalledWith(`/expressions/${id}/graph`, { params: { hops: 2, _content_revision: 0 }, signal: undefined })

    await getExpressionEdges(id, 50, 10)
    expect(api.get).toHaveBeenLastCalledWith(`/expressions/${id}/edges`, { params: { limit: 50, cursor: 10 }, signal: undefined })
  })

  it('submits selected edge IDs to the split endpoint', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: { data: { target_expression_id: '123456' } } })
    await splitExpression('123456', ['01EDGE', '02EDGE'])
    expect(api.post).toHaveBeenCalledWith('/expressions/123456/split', { edge_ids: ['01EDGE', '02EDGE'] }, { signal: undefined })
  })
})
