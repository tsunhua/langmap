import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import GraphToolbar from './GraphToolbar.vue'

const baseProps = { zoomPercent: 100, currentHops: 1, maxHops: 1 }

describe('GraphToolbar', () => {
  it('renders zoom percentage', () => {
    const wrapper = mount(GraphToolbar, { props: { ...baseProps, zoomPercent: 75 } })
    expect(wrapper.text()).toContain('75%')
  })

  it('emits zoomIn on click', () => {
    const wrapper = mount(GraphToolbar, { props: baseProps })
    wrapper.find('button[aria-label="放大"]').trigger('click')
    expect(wrapper.emitted('zoomIn')).toHaveLength(1)
  })

  it('emits zoomOut on click', () => {
    const wrapper = mount(GraphToolbar, { props: baseProps })
    wrapper.find('button[aria-label="縮小"]').trigger('click')
    expect(wrapper.emitted('zoomOut')).toHaveLength(1)
  })

  it('emits fit on click', () => {
    const wrapper = mount(GraphToolbar, { props: baseProps })
    wrapper.find('button[aria-label="適應畫面"]').trigger('click')
    expect(wrapper.emitted('fit')).toHaveLength(1)
  })

  it('emits actualSize on click', () => {
    const wrapper = mount(GraphToolbar, { props: baseProps })
    wrapper.find('button[aria-label="實際大小 100%"]').trigger('click')
    expect(wrapper.emitted('actualSize')).toHaveLength(1)
  })

  it('emits reset on click', () => {
    const wrapper = mount(GraphToolbar, { props: baseProps })
    wrapper.find('button[aria-label="重置佈局"]').trigger('click')
    expect(wrapper.emitted('reset')).toHaveLength(1)
  })

  it('all zoom buttons have accessible labels', () => {
    const wrapper = mount(GraphToolbar, { props: baseProps })
    const buttons = wrapper.findAll('button')
    expect(buttons.length).toBe(6)
    for (const btn of buttons) {
      expect(btn.attributes('aria-label')).toBeTruthy()
    }
  })

  it('shows hops segment when maxHops > 1', () => {
    const wrapper = mount(GraphToolbar, { props: { ...baseProps, maxHops: 3 } })
    expect(wrapper.text()).toContain('跳數')
    const hops = wrapper.findAll('.tb-hop')
    expect(hops.length).toBe(3)
  })

  it('highlights current hop', () => {
    const wrapper = mount(GraphToolbar, { props: { ...baseProps, maxHops: 3, currentHops: 2 } })
    const active = wrapper.findAll('.tb-hop.active')
    expect(active.length).toBe(1)
    expect(active[0].text()).toBe('2')
  })

  it('emits changeHops on hop click', () => {
    const wrapper = mount(GraphToolbar, { props: { ...baseProps, maxHops: 3 } })
    wrapper.findAll('.tb-hop')[1].trigger('click')
    expect(wrapper.emitted('changeHops')?.[0]).toEqual([2])
  })
})
