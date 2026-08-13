import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import VotePill from './VotePill.vue'

const { post } = vi.hoisted(() => ({ post: vi.fn() }))
vi.mock('@/api/client', () => ({ default: { post } }))

describe('VotePill', () => {
  beforeEach(() => vi.clearAllMocks())

  it('rolls back optimistic state and shows an alert when voting fails', async () => {
    post.mockRejectedValueOnce(new Error('offline'))
    const wrapper = mount(VotePill, {
      props: { targetId: 'edge-1', targetType: 'mapping', score: 4, userVote: null },
    })

    await wrapper.get('button.up').trigger('click')
    await flushPromises()

    expect(wrapper.get('.score').text()).toBe('4')
    expect(wrapper.get('button.up').attributes('aria-pressed')).toBe('false')
    expect(wrapper.get('[role="alert"]').text()).toBeTruthy()
  })

  it('uses the confirmed server score and emits it after a successful vote', async () => {
    post.mockResolvedValueOnce({ data: { data: { score: 8 } } })
    const wrapper = mount(VotePill, {
      props: { targetId: 'handbook-1', targetType: 'handbook', score: 4 },
    })

    await wrapper.get('button.down').trigger('click')
    await flushPromises()

    expect(post).toHaveBeenCalledWith('/handbooks/handbook-1/vote', { direction: 'down' })
    expect(wrapper.get('.score').text()).toBe('8')
    expect(wrapper.emitted('update:score')).toEqual([[8]])
  })
})
