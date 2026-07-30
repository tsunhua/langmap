import { describe, expect, it, vi, beforeEach, afterEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import LanguageCreateDialog from './LanguageCreateDialog.vue'

vi.mock('@/api/languages', () => ({
  listRegistryLanguages: vi.fn().mockResolvedValue([]),
  listLanguageSubtags: vi.fn().mockResolvedValue([]),
  searchLanguoids: vi.fn().mockResolvedValue([]),
  previewLanguage: vi.fn().mockResolvedValue(null),
  createLanguage: vi.fn().mockResolvedValue(null),
}))

const GlottologStub = {
  props: ['candidates', 'selectedGlottocode', 'loading'],
  emits: ['select'],
  template: `
    <div data-test="glottolog-match">
      <button data-choice="no-match" @click="$emit('select', null)">no match</button>
    </div>
  `,
}

describe('LanguageCreateDialog', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
    setActivePinia(createPinia())
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('does not render when open is false', () => {
    mount(LanguageCreateDialog, {
      props: { open: false },
    })
    expect(document.body.querySelector('[role="dialog"]')).toBeNull()
  })

  it('renders the dialog when open is true', () => {
    mount(LanguageCreateDialog, {
      props: { open: true },
    })
    const dialog = document.body.querySelector('[role="dialog"]')
    expect(dialog).not.toBeNull()
    expect(dialog!.getAttribute('aria-modal')).toBe('true')
  })

  it('shows step 1 title', () => {
    mount(LanguageCreateDialog, {
      props: { open: true },
    })
    expect(document.body.textContent).toContain('Language tag')
  })

  it('keeps Glottolog matching in step 2', async () => {
    const wrapper = mount(LanguageCreateDialog, {
      props: { open: true },
      global: {
        stubs: {
          LanguageTagBuilder: {
            emits: ['validityChange'],
            template: '<button data-test="valid-tag" @click="$emit(`validityChange`, true)">valid</button>',
          },
          GlottologMatchList: GlottologStub,
        },
      },
    })

    expect(document.body.querySelector('[data-test="glottolog-match"]')).toBeNull()

    const validTag = document.body.querySelector('[data-test="valid-tag"]') as HTMLElement
    validTag.click()
    await wrapper.vm.$nextTick()

    const nextBtn = document.body.querySelector('[data-action="next"]') as HTMLButtonElement
    expect(nextBtn).not.toBeNull()
    expect(nextBtn.disabled).toBe(false)
    nextBtn.click()
    await wrapper.vm.$nextTick()

    expect(document.body.querySelector('[data-test="glottolog-match"]')).not.toBeNull()
    expect((document.body.querySelector('[data-action="next"]') as HTMLButtonElement).disabled).toBe(true)
  })

  it('emits close when Escape is pressed', async () => {
    const wrapper = mount(LanguageCreateDialog, {
      props: { open: true },
    })
    const dialog = document.body.querySelector('[role="dialog"]') as HTMLElement
    expect(dialog).not.toBeNull()
    dialog.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))
    await wrapper.vm.$nextTick()
    expect(wrapper.emitted('close')).toHaveLength(1)
  })

  it('emits close when Cancel button is clicked', async () => {
    const wrapper = mount(LanguageCreateDialog, {
      props: { open: true },
    })
    const cancel = document.body.querySelector('[data-action="cancel"]') as HTMLElement
    expect(cancel).not.toBeNull()
    cancel.click()
    await wrapper.vm.$nextTick()
    expect(wrapper.emitted('close')).toHaveLength(1)
  })

  it('navigates between steps with next/back', async () => {
    const wrapper = mount(LanguageCreateDialog, {
      props: { open: true },
      global: {
        stubs: {
          LanguageTagBuilder: {
            emits: ['validityChange'],
            template: '<button data-test="valid-tag" @click="$emit(`validityChange`, true)">valid</button>',
          },
          GlottologMatchList: GlottologStub,
        },
      },
    })

    // Step 1 -> Step 2
    const validTag = document.body.querySelector('[data-test="valid-tag"]') as HTMLElement
    validTag.click()
    await wrapper.vm.$nextTick()

    const nextBtn = document.body.querySelector('[data-action="next"]') as HTMLElement
    nextBtn.click()
    await wrapper.vm.$nextTick()
    expect(document.body.textContent).toContain('Glottolog')

    const noMatch = document.body.querySelector('[data-choice="no-match"]') as HTMLElement
    noMatch.click()
    await wrapper.vm.$nextTick()

    // Step 2 -> Step 3
    const nextBtn2 = document.body.querySelector('[data-action="next"]') as HTMLElement
    nextBtn2.click()
    await wrapper.vm.$nextTick()
    expect(document.body.textContent).toContain('Metadata')

    // Step 3 back -> Step 2
    const backBtn = document.body.querySelector('[data-action="back"]') as HTMLElement
    backBtn.click()
    await wrapper.vm.$nextTick()
    expect(document.body.textContent).toContain('Glottolog')
  })
})
