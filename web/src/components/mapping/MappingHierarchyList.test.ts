// @ts-nocheck
import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import MappingHierarchyList from './MappingHierarchyList.vue'
import { buildDisplayTree } from './mappingGraphModel'
import type { MappingGraphResponse } from './mappingGraphTypes'

function makeGraph(): MappingGraphResponse {
  return {
    root_id: 1,
    requested_hops: 2,
    resolved_hops: 2,
    nodes: [
      { expression_id: 1, text: 'root', language_profile_code: 'en', language_name: 'English', depth: 0 },
      { expression_id: 2, text: 'alpha', language_profile_code: 'fr', language_name: 'French', depth: 1 },
      { expression_id: 3, text: 'beta', language_profile_code: 'de', language_name: 'German', depth: 1 },
      { expression_id: 4, text: 'gamma', language_profile_code: 'es', language_name: 'Spanish', depth: 2 },
    ],
    edges: [
      { edge_id: 'e1-2', source_id: 1, target_id: 2, score: 5, depth: 1 },
      { edge_id: 'e1-3', source_id: 1, target_id: 3, score: 4, depth: 1 },
      { edge_id: 'e2-4', source_id: 2, target_id: 4, score: 3, depth: 2 },
    ],
    layer_counts: { 0: 1, 1: 2, 2: 1 },
    truncated: false,
    omitted_count: 0,
  }
}

describe('MappingHierarchyList', () => {
  it('renders all visible nodes', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(MappingHierarchyList, {
      props: { tree, graph: g, selectedNodeId: null, collapsedIds: new Set<number>() },
    })
    const rows = wrapper.findAll('.hl-row')
    expect(rows.length).toBe(4)
  })

  it('indents by depth', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(MappingHierarchyList, {
      props: { tree, graph: g, selectedNodeId: null, collapsedIds: new Set<number>() },
    })
    const rows = wrapper.findAll('.hl-row')
    expect(rows.length).toBe(4)
    for (let i = 0; i < rows.length; i++) {
      const el = rows[i].element as HTMLElement
      expect(parseInt(el.style.paddingLeft)).toBeGreaterThanOrEqual(8)
      expect(parseInt(el.style.paddingLeft)).toBeLessThanOrEqual(48)
    }
  })

  it('highlights selected node', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(MappingHierarchyList, {
      props: { tree, graph: g, selectedNodeId: 2, collapsedIds: new Set<number>() },
    })
    const selected = wrapper.findAll('.hl-row.selected')
    expect(selected.length).toBe(1)
    expect(selected[0].attributes('data-node-id')).toBe('2')
  })

  it('emits select on click', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(MappingHierarchyList, {
      props: { tree, graph: g, selectedNodeId: null, collapsedIds: new Set<number>() },
    })
    wrapper.findAll('.hl-row')[1].trigger('click')
    expect(wrapper.emitted('select')?.[0]).toEqual([2])
  })

  it('hides children of collapsed nodes', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(MappingHierarchyList, {
      props: { tree, graph: g, selectedNodeId: null, collapsedIds: new Set([2]) },
    })
    const ids = wrapper.findAll('.hl-row').map(r => r.attributes('data-node-id'))
    expect(ids).toContain('1')
    expect(ids).toContain('2')
    expect(ids).toContain('3')
    expect(ids).not.toContain('4')
  })

  it('emits toggleCollapse on chevron click', () => {
    const g = makeGraph()
    const tree = buildDisplayTree(g)
    const wrapper = mount(MappingHierarchyList, {
      props: { tree, graph: g, selectedNodeId: null, collapsedIds: new Set<number>() },
    })
    const toggle = wrapper.find('.hl-toggle')
    toggle.trigger('click')
    expect(wrapper.emitted('toggleCollapse')?.[0]).toEqual([1])
  })
})
