import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import MappingGraph from './MappingGraph.vue'
import type { MappingGraphResponse } from './mappingGraphTypes'

function makeGraph(): MappingGraphResponse {
  return {
    root_id: 1,
    requested_hops: 2,
    resolved_hops: 2,
    nodes: [
      { expression_id: 1, text: 'root', language_code: 'en', language_name: 'English', depth: 0 },
      { expression_id: 2, text: 'alpha', language_code: 'en', language_name: 'English', depth: 1 },
      { expression_id: 3, text: 'beta', language_code: 'fr', language_name: 'French', depth: 1 },
      { expression_id: 4, text: 'gamma', language_code: 'de', language_name: 'German', depth: 2 },
    ],
    edges: [
      { edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 },
      { edge_id: 'e1-3', source_id: 1, target_id: 3, score: 3, depth: 1 },
      { edge_id: 'e2-4', source_id: 2, target_id: 4, score: 2, depth: 2 },
      { edge_id: 'e3-4', source_id: 3, target_id: 4, score: 1, depth: 2 },
    ],
    layer_counts: { 0: 1, 1: 2, 2: 1 },
    truncated: false,
    omitted_count: 0,
  }
}

describe('MappingGraph', () => {
  it('renders each visible node exactly once', () => {
    const wrapper = mount(MappingGraph, {
      props: { graph: makeGraph() },
      global: { stubs: { teleport: true } },
    })
    const nodes = wrapper.findAll('[data-node-id]')
    const ids = nodes.map((n) => Number(n.attributes('data-node-id')))
    expect(ids).toHaveLength(4)
    expect(new Set(ids).size).toBe(4)
  })

  it('marks root node with anchor class and depth 0', () => {
    const wrapper = mount(MappingGraph, {
      props: { graph: makeGraph() },
      global: { stubs: { teleport: true } },
    })
    const root = wrapper.find('[data-node-id="1"]')
    expect(root.classes()).toContain('anchor')
    expect(root.attributes('data-depth')).toBe('0')
  })

  it('renders the correct number of tree edges', () => {
    const wrapper = mount(MappingGraph, {
      props: { graph: makeGraph() },
      global: { stubs: { teleport: true } },
    })
    const treeEdges = wrapper.findAll('[data-tree-edge]')
    expect(treeEdges.length).toBe(3)
  })

  it('does not render cross edges by default', () => {
    const wrapper = mount(MappingGraph, {
      props: { graph: makeGraph() },
      global: { stubs: { teleport: true } },
    })
    const crossEdges = wrapper.findAll('[data-cross-edge]')
    expect(crossEdges.length).toBe(0)
  })

  it('includes text, language and depth in node accessible name', () => {
    const wrapper = mount(MappingGraph, {
      props: { graph: makeGraph() },
      global: { stubs: { teleport: true } },
    })
    const node = wrapper.find('[data-node-id="2"]')
    const label = node.attributes('aria-label') || ''
    expect(label).toContain('alpha')
    expect(label).toContain('en')
    expect(label).toContain('1')
  })

  it('emits select when a node is clicked', async () => {
    const wrapper = mount(MappingGraph, {
      props: { graph: makeGraph() },
      global: { stubs: { teleport: true } },
    })
    const node = wrapper.find('[data-node-id="2"]')
    await node.trigger('click')
    expect(wrapper.emitted('select')?.[0]).toEqual([2])
  })

  it('does not render when graph is empty', () => {
    const wrapper = mount(MappingGraph, {
      props: {
        graph: {
          root_id: 1,
          requested_hops: 1,
          resolved_hops: 0,
          nodes: [],
          edges: [],
          layer_counts: {},
          truncated: false,
          omitted_count: 0,
        },
      },
      global: { stubs: { teleport: true } },
    })
    expect(wrapper.find('[data-node-id]').exists()).toBe(false)
  })
})
