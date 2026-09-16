import { describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { nextTick } from 'vue'
import { createPinia } from 'pinia'
import TranslationForm from './TranslationForm.vue'
import { countGraphemes, utf8ByteLength } from '@/utils/graphemes'

vi.mock('@/api/languageIdentity', () => ({
  listLanguages: vi.fn().mockResolvedValue({ items: [{ code: 'nan', name_en: 'Min Nan' }], total: 1 }),
  listLanguageLocales: vi.fn().mockResolvedValue({
    items: [{ code: 'nan-Hant-TW', lang_code: 'nan', script_code: 'Hant', region_code: 'TW', name: '臺語', name_en: 'Taiwanese', display_name: '臺灣話' }],
    total: 1,
  }),
  getLanguageLocale: vi.fn().mockResolvedValue({ code: 'nan-Hant-TW', lang_code: 'nan', display_name: '臺灣話' }),
}))

const base = { sourceLangCode: null as string | null, targetLocaleCode: '', text: '' }

function mountForm(overrides: Record<string, unknown> = {}) {
  return mount(TranslationForm, {
    props: { modelValue: { ...base }, ...overrides },
    global: { plugins: [createPinia()] },
    attachTo: document.body,
  })
}

function lastChange(wrapper: ReturnType<typeof mountForm>) {
  const events = wrapper.emitted('update:modelValue')
  return events?.[events.length - 1]?.[0]
}

describe('TranslationForm', () => {
  it('emits updated text when the user types, preserving newlines', async () => {
    const wrapper = mountForm()
    await wrapper.get('textarea').setValue('食飯\n食飽未？')
    expect(lastChange(wrapper)).toMatchObject({ text: '食飯\n食飽未？' })
  })

  it('blocks submit and shows the focusable summary when over 500 graphemes', async () => {
    const long = 'a'.repeat(501)
    const wrapper = mountForm()
    await wrapper.get('textarea').setValue(long)
    await wrapper.setProps({ modelValue: { ...base, targetLocaleCode: 'nan-Hant-TW', text: long } })
    await wrapper.get('form').trigger('submit')
    await nextTick()

    expect(wrapper.get('[data-action="submit"]').attributes('disabled')).toBeDefined()
    const summary = wrapper.get('p[role="alert"]')
    expect(summary.text()).toContain('Check the highlighted fields')
    expect(summary.attributes('tabindex')).toBe('-1')
  })

  it('focuses the error summary on an invalid submit', async () => {
    const wrapper = mountForm()
    await wrapper.get('form').trigger('submit')
    await nextTick()
    expect(document.activeElement).toBe(wrapper.get('p[role="alert"]').element)
  })

  it('blocks submit when UTF-8 bytes exceed the limit even under the grapheme cap', async () => {
    const text = '👨‍👩‍👧‍👦'.repeat(400)
    expect(countGraphemes(text)).toBeLessThanOrEqual(500)
    expect(utf8ByteLength(text)).toBeGreaterThan(8192)

    const wrapper = mountForm({ modelValue: { ...base, targetLocaleCode: 'nan-Hant-TW', text } })
    expect(wrapper.get('[data-action="submit"]').attributes('disabled')).toBeDefined()
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')).toBeUndefined()
  })

  it('ties the target picker error to the control region', async () => {
    const wrapper = mountForm()
    await wrapper.get('form').trigger('submit')
    await nextTick()
    const field = wrapper.get('.target-field')
    expect(field.attributes('aria-invalid')).toBe('true')
    expect(field.attributes('aria-describedby')).toBe('translation-target-error')
    expect(wrapper.get('#translation-target-error').text()).toContain('target language')
  })

  it('blocks submit while the text is empty or the target locale is missing', () => {
    const noTarget = mountForm({ modelValue: { ...base, text: 'hello' } })
    expect(noTarget.get('[data-action="submit"]').attributes('disabled')).toBeDefined()

    const blankText = mountForm({ modelValue: { ...base, targetLocaleCode: 'nan-Hant-TW', text: '   ' } })
    expect(blankText.get('[data-action="submit"]').attributes('disabled')).toBeDefined()
  })

  it('emits submit when the form is valid', async () => {
    const wrapper = mountForm({ modelValue: { ...base, targetLocaleCode: 'nan-Hant-TW', text: '你好' } })
    expect(wrapper.get('[data-action="submit"]').attributes('disabled')).toBeUndefined()
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')).toHaveLength(1)
  })

  it('shows a cancel action that emits while a request is in progress', async () => {
    const wrapper = mountForm({ disabled: true, modelValue: { ...base, targetLocaleCode: 'nan-Hant-TW', text: '你好' } })
    expect(wrapper.find('[data-action="submit"]').exists()).toBe(false)
    await wrapper.get('[data-action="cancel"]').trigger('click')
    expect(wrapper.emitted('cancel')).toHaveLength(1)
  })

  it('lets the source picker set a language code and the auto action clear it', async () => {
    const wrapper = mountForm()
    const sourceInput = wrapper.get('input[placeholder="Search ISO 639-3 languages"]')
    await sourceInput.trigger('focus')
    await sourceInput.setValue('nan')
    await flushPromises()
    await wrapper.get('[role="option"]').trigger('mousedown')
    expect(lastChange(wrapper)).toMatchObject({ sourceLangCode: 'nan' })

    const selected = mountForm({ modelValue: { ...base, sourceLangCode: 'nan' } })
    await selected.get('[data-action="source-auto"]').trigger('click')
    expect(lastChange(selected)).toMatchObject({ sourceLangCode: null })
  })

  it('lets the target locale picker emit the canonical locale code', async () => {
    const wrapper = mountForm()
    const targetInput = wrapper.get('input[placeholder="Search language locales…"]')
    await targetInput.trigger('focus')
    await targetInput.setValue('tai')
    await flushPromises()
    await wrapper.get('[role="option"]').trigger('mousedown')
    expect(lastChange(wrapper)).toMatchObject({ targetLocaleCode: 'nan-Hant-TW' })
  })
})
