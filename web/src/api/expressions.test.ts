import { beforeEach, describe, expect, it, vi } from 'vitest'
import api from './client'
import { getExpression, getExpressionEdges, getMappingGraph, splitExpression } from './expressions'

vi.mock('./client', () => ({ default: { get: vi.fn(), post: vi.fn() } }))

describe('expressions API', () => {
  beforeEach(() => vi.mocked(api.get).mockResolvedValue({ data: { data: { items: [] } } }))

  it('encodes TEXT IDs and unwraps the API envelope', async () => {
    await getExpression('nan:食/一')
    expect(api.get).toHaveBeenCalledWith('/expressions/nan%3A%E9%A3%9F%2F%E4%B8%80', { signal: undefined })

    await getMappingGraph('nan:食/一', 2)
    expect(api.get).toHaveBeenLastCalledWith('/expressions/nan%3A%E9%A3%9F%2F%E4%B8%80/mappings', { params: { hops: 2 }, signal: undefined })

    await getExpressionEdges('nan:食/一', 50, 10)
    expect(api.get).toHaveBeenLastCalledWith('/expressions/nan%3A%E9%A3%9F%2F%E4%B8%80/edges', { params: { limit: 50, offset: 10 }, signal: undefined })
  })

  it('submits selected edge IDs to the split endpoint', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: { data: { target_expression_id: 'nan:食:2' } } })
    await splitExpression('nan:食:1', ['01EDGE', '02EDGE'])
    expect(api.post).toHaveBeenCalledWith('/expressions/nan%3A%E9%A3%9F%3A1/split', { edge_ids: ['01EDGE', '02EDGE'] }, { signal: undefined })
  })
})
