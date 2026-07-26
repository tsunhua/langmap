import { describe, expect, it } from 'vitest'
import { mount } from '@vue/test-utils'
import GraphToolbar from './GraphToolbar.vue'

describe('GraphToolbar', () => {
  it('renders zoom percentage', () => {
    const wrapper = mount(GraphToolbar, { props: { zoomPercent: 75 } })
    expect(wrapper.text()).toContain('75%')
  })

  it('emits zoomIn on click', () => {
    const wrapper = mount(GraphToolbar, { props: { zoomPercent: 100 } })
    wrapper.find('button[aria-label="放大"]').trigger('click')
    expect(wrapper.emitted('zoomIn')).toHaveLength(1)
  })

  it('emits zoomOut on click', () => {
    const wrapper = mount(GraphToolbar, { props: { zoomPercent: 100 } })
    wrapper.find('button[aria-label="縮小"]').trigger('click')
    expect(wrapper.emitted('zoomOut')).toHaveLength(1)
  })

  it('emits fit on click', () => {
    const wrapper = mount(GraphToolbar, { props: { zoomPercent: 100 } })
    wrapper.find('button[aria-label="適應畫面"]').trigger('click')
    expect(wrapper.emitted('fit')).toHaveLength(1)
  })

  it('emits actualSize on click', () => {
    const wrapper = mount(GraphToolbar, { props: { zoomPercent: 100 } })
    wrapper.find('button[aria-label="實際大小 100%"]').trigger('click')
    expect(wrapper.emitted('actualSize')).toHaveLength(1)
  })

  it('emits reset on click', () => {
    const wrapper = mount(GraphToolbar, { props: { zoomPercent: 100 } })
    wrapper.find('button[aria-label="重置佈局"]').trigger('click')
    expect(wrapper.emitted('reset')).toHaveLength(1)
  })

  it('all buttons have accessible labels', () => {
    const wrapper = mount(GraphToolbar, { props: { zoomPercent: 100 } })
    const buttons = wrapper.findAll('button')
    expect(buttons.length).toBe(5)
    for (const btn of buttons) {
      expect(btn.attributes('aria-label')).toBeTruthy()
    }
  })
})
