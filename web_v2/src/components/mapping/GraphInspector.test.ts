import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import GraphInspector from './GraphInspector.vue'
import { buildDisplayTree } from './mappingGraphModel'
import type { MappingGraphResponse } from './mappingGraphTypes'

function makeGraph(): MappingGraphResponse {
  return {
    root_id: 1,
    requested_hops: 2,
    resolved_hops: 2,
    nodes: [
      { expression_id: 1, text: 'root', language_code: 'en', language_name: 'English', depth: 0 },
      { expression_id: 2, text: 'alpha', language_code: 'fr', language_name: 'French', depth: 1 },
      { expression_id: 3, text: 'beta', language_code: 'de', language_name: 'German', depth: 2 },
    ],
    edges: [
      { edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 },
      { edge_id: 'e2-3', source_id: 2, target_id: 3, score: 3, depth: 2 },
    ],
    layer_counts: { 0: 1, 1: 1, 2: 1 },
    truncated: false,
    omitted_count: 0,
  }
}

describe('GraphInspector', () => {
  it('shows hint and stats when no node selected', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(GraphInspector, {
      props: {
        selectedNodeId: null,
        graph: g,
        displayTree: tree,
        anchorText: 'root',
      },
    })
    expect(wrapper.text()).toContain('Select a node in the graph')
    expect(wrapper.text()).toContain('2 mapped nodes')
    expect(wrapper.text()).toContain('2 relations')
  })

  it('shows selected node text and language', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(GraphInspector, {
      props: {
        selectedNodeId: 2,
        graph: g,
        displayTree: tree,
        anchorText: 'root',
      },
    })
    expect(wrapper.text()).toContain('alpha')
    expect(wrapper.text()).toContain('fr')
    expect(wrapper.text()).toContain('French')
  })

  it('shows path from root to selected node', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(GraphInspector, {
      props: {
        selectedNodeId: 3,
        graph: g,
        displayTree: tree,
        anchorText: 'root',
      },
    })
    expect(wrapper.text()).toContain('root')
    expect(wrapper.text()).toContain('alpha')
    expect(wrapper.text()).toContain('beta')
  })

  it('shows vote pill for primary edge', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(GraphInspector, {
      props: {
        selectedNodeId: 2,
        graph: g,
        displayTree: tree,
        anchorText: 'root',
      },
      global: { stubs: { teleport: true } },
    })
    expect(wrapper.findComponent({ name: 'VotePill' }).exists()).toBe(true)
  })

  it('emits close on close button click', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(GraphInspector, {
      props: {
        selectedNodeId: 2,
        graph: g,
        displayTree: tree,
        anchorText: 'root',
      },
    })
    wrapper.find('.gi-close').trigger('click')
    expect(wrapper.emitted('close')).toHaveLength(1)
  })

  it('emits navigate on detail button click', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(GraphInspector, {
      props: {
        selectedNodeId: 2,
        graph: g,
        displayTree: tree,
        anchorText: 'root',
      },
    })
    wrapper.find('button.btn-primary').trigger('click')
    expect(wrapper.emitted('navigate')?.[0]).toEqual([2])
  })

  it('shows depth in meta', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(GraphInspector, {
      props: {
        selectedNodeId: 3,
        graph: g,
        displayTree: tree,
        anchorText: 'root',
      },
    })
    expect(wrapper.text()).toContain('Depth 2')
  })
})
